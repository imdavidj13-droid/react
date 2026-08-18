create or replace function public.set_player_display_name(p_display_name text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_display_name text := regexp_replace(trim(coalesce(p_display_name, '')), '\s+', ' ', 'g');
begin
  if v_player_id is null then
    raise exception 'Authentication required';
  end if;

  if char_length(v_display_name) < 3 or char_length(v_display_name) > 20 then
    raise exception 'display_name_length';
  end if;

  if v_display_name !~ '^[A-Za-z0-9 _-]+$' then
    raise exception 'display_name_characters';
  end if;

  begin
    insert into public.player_profiles (id, display_name, updated_at)
    values (v_player_id, v_display_name, now())
    on conflict (id) do update
      set display_name = excluded.display_name,
          updated_at = now();
  exception
    when unique_violation then
      raise exception 'display_name_taken' using errcode = '23505';
  end;

  return v_display_name;
end;
$$;

revoke all on function public.set_player_display_name(text) from public, anon;
grant execute on function public.set_player_display_name(text) to authenticated;
