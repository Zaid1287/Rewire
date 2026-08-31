-- RLS and GRANTs are two separate gates and both must be open. 0001 enabled RLS
-- and wrote the policies but never granted the underlying table privileges, so
-- `authenticated` was denied before any policy was even evaluated — the app
-- could not read its own rows. Caught by running the RLS test in
-- `tests/rls_check.sql`, not by reading the schema.
--
-- `anon` is deliberately granted nothing: there is no signed-out surface here.
-- Social requires an account, and RLS on its own would happily let an anonymous
-- caller run a query that simply returns no rows; not granting is clearer.

grant select, insert, update, delete on public.profiles            to authenticated;
grant select, insert, update, delete on public.shared_streak_state to authenticated;
grant select, insert,         delete on public.buddy_pairs         to authenticated;
-- No UPDATE on buddy_pairs on purpose: the only state transition
-- (pending -> accepted) belongs to redeem_buddy_invite(), and there is no
-- UPDATE policy either. Two locks, same door.

grant usage on schema public to authenticated;
