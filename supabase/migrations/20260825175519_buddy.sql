-- Backend stage B2 — accountability buddy.
--
-- THE RULE THIS SCHEMA EXISTS TO ENFORCE: only minimal, non-sensitive fields
-- ever reach a Rewire-operated server. A streak count, a check-in date, a
-- pseudonymous handle, a pairing. Never slip reasons, never P/M/O flags, never
-- motivations, never photos, never quiz answers — those live in the user's own
-- iCloud (CloudKit private DB, stage B1) where we cannot read them.
--
-- If a future migration adds a free-text or health-data column to any table in
-- here, that rule is broken. Add it to CloudKit instead.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- profiles: pseudonymous identity. One row per auth user.
-- ---------------------------------------------------------------------------
create table public.profiles (
    id          uuid primary key references auth.users (id) on delete cascade,
    handle      text not null unique,
    created_at  timestamptz not null default now(),
    -- Handle is the ONLY user-authored text in this database. The check keeps
    -- it a handle and not a free-text field someone confesses into, or an
    -- email address that turns a pseudonymous row into a PII row.
    constraint handle_is_a_handle check (handle ~ '^[a-z0-9_]{3,20}$')
);

-- ---------------------------------------------------------------------------
-- shared_streak_state: the entire payload a buddy is allowed to see.
-- ---------------------------------------------------------------------------
create table public.shared_streak_state (
    user_id         uuid primary key references auth.users (id) on delete cascade,
    streak_days     integer not null default 0 check (streak_days >= 0),
    last_check_in   date,
    updated_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- buddy_pairs: who may read whose streak.
-- ---------------------------------------------------------------------------
create type public.buddy_status as enum ('pending', 'accepted');

create table public.buddy_pairs (
    id            uuid primary key default gen_random_uuid(),
    requester_id  uuid not null references auth.users (id) on delete cascade,
    addressee_id  uuid references auth.users (id) on delete cascade,
    invite_code   text unique,
    status        public.buddy_status not null default 'pending',
    created_at    timestamptz not null default now(),
    accepted_at   timestamptz,
    constraint no_self_buddy check (addressee_id is distinct from requester_id),
    constraint accepted_has_addressee
        check (status = 'pending' or addressee_id is not null)
);

-- One accepted pair per unordered couple, regardless of who invited whom.
create unique index buddy_pairs_unique_accepted
    on public.buddy_pairs (least(requester_id, addressee_id), greatest(requester_id, addressee_id))
    where status = 'accepted';

create index buddy_pairs_requester on public.buddy_pairs (requester_id);
create index buddy_pairs_addressee on public.buddy_pairs (addressee_id);

-- ---------------------------------------------------------------------------
-- is_buddy(): the single source of truth for "may A see B".
--
-- SECURITY DEFINER on purpose. The policies on profiles and shared_streak_state
-- need to read buddy_pairs; if that read went through buddy_pairs' own RLS,
-- Postgres would recurse. definer + a pinned search_path is the standard escape.
-- ---------------------------------------------------------------------------
create function public.is_buddy(other uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1 from public.buddy_pairs
        where status = 'accepted'
          and (   (requester_id = auth.uid() and addressee_id = other)
               or (addressee_id = auth.uid() and requester_id = other))
    );
$$;

-- ---------------------------------------------------------------------------
-- redeem_buddy_invite(): accept an invite by code.
--
-- Also SECURITY DEFINER, for a different reason: the redeemer cannot be allowed
-- to SELECT pending rows (that would make every outstanding invite code
-- enumerable). So they never read the row — they hand the code to this function,
-- which does the lookup on their behalf and returns only the buddy's id.
-- ---------------------------------------------------------------------------
create function public.redeem_buddy_invite(code text)
returns uuid
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
    pair public.buddy_pairs;
begin
    if auth.uid() is null then
        raise exception 'not authenticated';
    end if;

    select * into pair from public.buddy_pairs
        where invite_code = code and status = 'pending'
        for update;

    if not found then
        raise exception 'invite not found or already used';
    end if;

    if pair.requester_id = auth.uid() then
        raise exception 'cannot buddy yourself';
    end if;

    update public.buddy_pairs
        set addressee_id = auth.uid(),
            status       = 'accepted',
            accepted_at  = now(),
            -- Burn the code so it is single-use.
            invite_code  = null
        where id = pair.id;

    return pair.requester_id;
end;
$$;

revoke execute on function public.redeem_buddy_invite(text) from public, anon;
grant execute on function public.redeem_buddy_invite(text) to authenticated;

-- ---------------------------------------------------------------------------
-- updated_at is stamped by the server, not claimed by the client.
-- ---------------------------------------------------------------------------
create function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger shared_streak_state_touch
    before update on public.shared_streak_state
    for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Row-Level Security. Default deny; every policy below is an explicit grant.
-- ---------------------------------------------------------------------------
alter table public.profiles            enable row level security;
alter table public.shared_streak_state enable row level security;
alter table public.buddy_pairs         enable row level security;

-- profiles ------------------------------------------------------------------
create policy profiles_select_self_or_buddy on public.profiles
    for select to authenticated
    using (id = auth.uid() or public.is_buddy(id));

create policy profiles_insert_self on public.profiles
    for insert to authenticated
    with check (id = auth.uid());

create policy profiles_update_self on public.profiles
    for update to authenticated
    using (id = auth.uid()) with check (id = auth.uid());

create policy profiles_delete_self on public.profiles
    for delete to authenticated
    using (id = auth.uid());

-- shared_streak_state -------------------------------------------------------
create policy streak_select_self_or_buddy on public.shared_streak_state
    for select to authenticated
    using (user_id = auth.uid() or public.is_buddy(user_id));

create policy streak_insert_self on public.shared_streak_state
    for insert to authenticated
    with check (user_id = auth.uid());

create policy streak_update_self on public.shared_streak_state
    for update to authenticated
    using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy streak_delete_self on public.shared_streak_state
    for delete to authenticated
    using (user_id = auth.uid());

-- buddy_pairs ---------------------------------------------------------------
-- Deliberately no SELECT on pending rows for anyone but their creator: an
-- invite code is a bearer token, and a readable pending table is an enumerable
-- one. Redemption goes through redeem_buddy_invite() instead.
create policy pairs_select_own on public.buddy_pairs
    for select to authenticated
    using (requester_id = auth.uid() or addressee_id = auth.uid());

create policy pairs_insert_as_requester on public.buddy_pairs
    for insert to authenticated
    with check (requester_id = auth.uid() and addressee_id is null and status = 'pending');

-- Either side can walk away; there is no "update" path, because the only state
-- transition (pending -> accepted) belongs to redeem_buddy_invite().
create policy pairs_delete_own on public.buddy_pairs
    for delete to authenticated
    using (requester_id = auth.uid() or addressee_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Realtime: a buddy's streak card updates live. RLS still applies to the
-- stream, so a non-buddy receives nothing.
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table public.shared_streak_state;
