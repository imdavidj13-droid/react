alter table public.player_profiles
  add column if not exists player_code text,
  add column if not exists avatar_path text;

update public.player_profiles
set player_code = 'RX-' || upper(substr(replace(id::text, '-', ''), 1, 10))
where player_code is null or trim(player_code) = '';

alter table public.player_profiles
  alter column player_code set not null;

create unique index if not exists player_profiles_player_code_unique
  on public.player_profiles (player_code);

create or replace function public.ensure_react_player_code()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.player_code is null or trim(new.player_code) = '' then
    new.player_code := 'RX-' || upper(substr(replace(new.id::text, '-', ''), 1, 10));
  end if;
  return new;
end;
$$;

drop trigger if exists ensure_react_player_code_on_profile on public.player_profiles;
create trigger ensure_react_player_code_on_profile
before insert or update of player_code on public.player_profiles
for each row execute function public.ensure_react_player_code();

create or replace function public.handle_new_react_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.player_profiles (id, player_code, display_name)
  values (
    new.id,
    'RX-' || upper(substr(replace(new.id::text, '-', ''), 1, 10)),
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      'PLAYER-' || upper(substr(replace(new.id::text, '-', ''), 1, 6))
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.ensure_react_player_code() from public, anon, authenticated;

grant select on table public.player_profiles to anon, authenticated;
grant update (display_name, avatar_path) on table public.player_profiles to authenticated;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'player-avatars',
  'player-avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists react_avatar_insert_own on storage.objects;
create policy react_avatar_insert_own
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'player-avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists react_avatar_update_own on storage.objects;
create policy react_avatar_update_own
on storage.objects
for update
to authenticated
using (
  bucket_id = 'player-avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'player-avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists react_avatar_delete_own on storage.objects;
create policy react_avatar_delete_own
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'player-avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
