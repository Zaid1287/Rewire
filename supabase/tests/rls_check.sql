-- The one runnable check for stage B2.
--
-- Reading policies tells you what you wrote; running this tells you what the
-- database actually enforces. It caught a real hole once already: 0001 enabled
-- RLS and wrote every policy, but granted no table privileges, so `authenticated`
-- was denied outright — invisible from the schema, obvious the moment it ran.
--
-- Self-cleaning: it ends by raising, which rolls the whole transaction back, so
-- it is safe against the live project and leaves no test users behind. A PASS
-- and a FAIL both arrive as an "ERROR:" — read the message, not the severity.
--
-- Run: paste into the Supabase SQL Editor, or
--   psql "$DATABASE_URL" -f supabase/tests/rls_check.sql
do $$
declare
    u1 uuid := gen_random_uuid();   -- our user
    u2 uuid := gen_random_uuid();   -- their buddy
    u3 uuid := gen_random_uuid();   -- a stranger, with an outstanding invite
    visible int; leaked int; pending_visible int;
    buddy_yes boolean; buddy_no boolean;
    profiles_visible int; forged int;
    results text;
begin
    -- Setup runs as the superuser, which bypasses RLS on purpose.
    insert into auth.users (id, instance_id, aud, role, email)
    values (u1, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'u1@test.invalid'),
           (u2, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'u2@test.invalid'),
           (u3, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'u3@test.invalid');
    insert into public.profiles (id, handle) values (u1,'user_one'), (u2,'user_two'), (u3,'stranger');
    insert into public.shared_streak_state (user_id, streak_days) values (u1, 5), (u2, 12), (u3, 99);
    insert into public.buddy_pairs (requester_id, addressee_id, status, accepted_at) values (u1, u2, 'accepted', now());
    insert into public.buddy_pairs (requester_id, invite_code) values (u3, 'SECRET99');

    -- Become u1: an ordinary signed-in user, exactly as PostgREST would.
    perform set_config('request.jwt.claims', json_build_object('sub', u1, 'role','authenticated')::text, true);
    perform set_config('role', 'authenticated', true);

    select count(*) into visible          from public.shared_streak_state;
    select count(*) into leaked           from public.shared_streak_state where user_id = u3;
    select count(*) into profiles_visible from public.profiles;
    select count(*) into pending_visible  from public.buddy_pairs where status = 'pending';
    select private.is_buddy(u2) into buddy_yes;
    select private.is_buddy(u3) into buddy_no;

    -- u1 tries to overwrite a stranger's streak.
    update public.shared_streak_state set streak_days = 0 where user_id = u3;
    get diagnostics forged = row_count;

    perform set_config('role', 'postgres', true);

    results := format('streak rows visible=%s(want 2) | u3 leaked=%s(want 0) | profiles visible=%s(want 2) | pending invites visible=%s(want 0) | is_buddy(u2)=%s(want t) | is_buddy(u3)=%s(want f) | rows u1 forged on u3=%s(want 0)',
        visible, leaked, profiles_visible, pending_visible, buddy_yes, buddy_no, forged);

    if visible <> 2 or leaked <> 0 or profiles_visible <> 2 or pending_visible <> 0
       or buddy_yes is not true or buddy_no is not false or forged <> 0 then
        raise exception 'RLS CHECK FAILED -- %', results;
    end if;

    raise exception 'RLS CHECK PASSED (rolled back, no test rows survive) -- %', results;
end $$;
