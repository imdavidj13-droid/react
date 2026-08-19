create table if not exists public.react_friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.player_profiles(id) on delete cascade,
  addressee_id uuid not null references public.player_profiles(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  updated_at timestamptz not null default now(),
  check (requester_id <> addressee_id)
);

create unique index if not exists react_friendships_unique_pair
  on public.react_friendships (
    least(requester_id, addressee_id),
    greatest(requester_id, addressee_id)
  );

create index if not exists react_friendships_requester_status_idx
  on public.react_friendships (requester_id, status);

create index if not exists react_friendships_addressee_status_idx
  on public.react_friendships (addressee_id, status);

alter table public.react_friendships enable row level security;

revoke all on table public.react_friendships from public, anon, authenticated;
grant select on table public.react_friendships to authenticated;

drop policy if exists react_friendships_select_own on public.react_friendships;
create policy react_friendships_select_own
on public.react_friendships
for select
to authenticated
using (
  requester_id = (select auth.uid())
  or addressee_id = (select auth.uid())
);

create or replace function public.find_react_player_by_code(p_player_code text)
returns table (
  player_id uuid,
  player_code text,
  display_name text,
  avatar_path text,
  relationship_id uuid,
  relationship_status text,
  relationship_direction text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current uuid := auth.uid();
  v_target uuid;
begin
  if v_current is null then
    raise exception 'authentication_required';
  end if;

  select p.id
  into v_target
  from public.player_profiles p
  where upper(p.player_code) = upper(trim(p_player_code))
  limit 1;

  if v_target is null then
    return;
  end if;

  return query
  select
    p.id,
    p.player_code,
    p.display_name,
    p.avatar_path,
    f.id,
    f.status,
    case
      when p.id = v_current then 'self'
      when f.id is null then 'none'
      when f.status = 'accepted' then 'friend'
      when f.requester_id = v_current then 'outgoing'
      else 'incoming'
    end
  from public.player_profiles p
  left join public.react_friendships f
    on (
      (f.requester_id = v_current and f.addressee_id = p.id)
      or (f.addressee_id = v_current and f.requester_id = p.id)
    )
  where p.id = v_target;
end;
$$;

create or replace function public.send_react_friend_request(p_player_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current uuid := auth.uid();
  v_target uuid;
  v_existing public.react_friendships%rowtype;
  v_id uuid;
begin
  if v_current is null then
    raise exception 'authentication_required';
  end if;

  select id into v_target
  from public.player_profiles
  where upper(player_code) = upper(trim(p_player_code))
  limit 1;

  if v_target is null then
    raise exception 'player_not_found';
  end if;

  if v_target = v_current then
    raise exception 'cannot_friend_self';
  end if;

  select * into v_existing
  from public.react_friendships
  where least(requester_id, addressee_id) = least(v_current, v_target)
    and greatest(requester_id, addressee_id) = greatest(v_current, v_target)
  limit 1;

  if found then
    if v_existing.status = 'accepted' then
      raise exception 'already_friends';
    elsif v_existing.requester_id = v_current then
      raise exception 'friend_request_already_sent';
    else
      raise exception 'friend_request_already_received';
    end if;
  end if;

  insert into public.react_friendships (requester_id, addressee_id)
  values (v_current, v_target)
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.accept_react_friend_request(p_relationship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.react_friendships
  set status = 'accepted',
      responded_at = now(),
      updated_at = now()
  where id = p_relationship_id
    and addressee_id = auth.uid()
    and status = 'pending';

  if not found then
    raise exception 'friend_request_not_found';
  end if;
end;
$$;

create or replace function public.decline_react_friend_request(p_relationship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.react_friendships
  where id = p_relationship_id
    and addressee_id = auth.uid()
    and status = 'pending';

  if not found then
    raise exception 'friend_request_not_found';
  end if;
end;
$$;

create or replace function public.cancel_react_friend_request(p_relationship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.react_friendships
  where id = p_relationship_id
    and requester_id = auth.uid()
    and status = 'pending';

  if not found then
    raise exception 'friend_request_not_found';
  end if;
end;
$$;

create or replace function public.remove_react_friend(p_relationship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.react_friendships
  where id = p_relationship_id
    and status = 'accepted'
    and (requester_id = auth.uid() or addressee_id = auth.uid());

  if not found then
    raise exception 'friendship_not_found';
  end if;
end;
$$;

create or replace function public.get_react_friend_connections()
returns table (
  relationship_id uuid,
  relationship_status text,
  relationship_direction text,
  player_id uuid,
  player_code text,
  display_name text,
  avatar_path text,
  created_at timestamptz
)
language sql
security definer
set search_path = public
stable
as $$
  select
    f.id,
    f.status,
    case
      when f.status = 'accepted' then 'friend'
      when f.requester_id = auth.uid() then 'outgoing'
      else 'incoming'
    end,
    p.id,
    p.player_code,
    p.display_name,
    p.avatar_path,
    f.created_at
  from public.react_friendships f
  join public.player_profiles p
    on p.id = case
      when f.requester_id = auth.uid() then f.addressee_id
      else f.requester_id
    end
  where auth.uid() is not null
    and (f.requester_id = auth.uid() or f.addressee_id = auth.uid())
  order by
    case
      when f.status = 'pending' and f.addressee_id = auth.uid() then 0
      when f.status = 'pending' then 1
      else 2
    end,
    f.created_at desc;
$$;

revoke all on function public.find_react_player_by_code(text) from public, anon;
revoke all on function public.send_react_friend_request(text) from public, anon;
revoke all on function public.accept_react_friend_request(uuid) from public, anon;
revoke all on function public.decline_react_friend_request(uuid) from public, anon;
revoke all on function public.cancel_react_friend_request(uuid) from public, anon;
revoke all on function public.remove_react_friend(uuid) from public, anon;
revoke all on function public.get_react_friend_connections() from public, anon;

grant execute on function public.find_react_player_by_code(text) to authenticated;
grant execute on function public.send_react_friend_request(text) to authenticated;
grant execute on function public.accept_react_friend_request(uuid) to authenticated;
grant execute on function public.decline_react_friend_request(uuid) to authenticated;
grant execute on function public.cancel_react_friend_request(uuid) to authenticated;
grant execute on function public.remove_react_friend(uuid) to authenticated;
grant execute on function public.get_react_friend_connections() to authenticated;
