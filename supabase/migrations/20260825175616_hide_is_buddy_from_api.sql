-- is_buddy() is an internal helper for RLS policies, but anything in `public`
-- is published by PostgREST as /rest/v1/rpc/... . It leaked nothing (it answers
-- only about auth.uid(), the caller), but it is not API and should not look
-- like it. Move it out of the exposed schema.
--
-- ALTER ... SET SCHEMA keeps the OID, and policies reference the function by
-- OID, so the existing policies keep working untouched.

create schema if not exists private;

alter function public.is_buddy(uuid) set schema private;

-- Policy expressions are evaluated as the querying role, so `authenticated`
-- still needs to be able to resolve and execute it — just not over HTTP.
grant usage on schema private to authenticated;
revoke execute on function private.is_buddy(uuid) from public, anon;
grant execute on function private.is_buddy(uuid) to authenticated;
