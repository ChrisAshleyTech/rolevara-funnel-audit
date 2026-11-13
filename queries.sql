-- Rolevara learner funnel and tracking audit
-- Database: Rolevara production Postgres (Supabase). Data pulled 2026-11-12.
-- Owner test accounts are excluded from every query. No emails or user IDs are reported.

-- Owner accounts to exclude (testing traffic)
with owner as (
  select id from auth.users
  where email ilike '%<owner-email-1>%' or email ilike '%<owner-domain>%'
)

-- 1. Event-log funnel: distinct learners or visitors per event, owner excluded
select event, count(distinct coalesce(user_id::text, visitor)) as learners
from journey_events
where user_id is null or user_id not in (select id from owner)
group by event
order by learners desc;


-- 2. Per-learner view: sign-up, last sign-in, events, track, onboarding time, voice use
with owner as (
  select id from auth.users
  where email ilike '%<owner-email-1>%' or email ilike '%<owner-domain>%'
),
u as (
  select id, created_at, last_sign_in_at,
         row_number() over (order by created_at) as n
  from auth.users
  where id not in (select id from owner)
)
select 'L' || u.n                                    as learner,
       u.created_at::date                            as signed_up,
       u.last_sign_in_at::date                       as last_sign_in,
       (select string_agg(distinct j.event, ',' order by j.event)
          from journey_events j where j.user_id = u.id) as events,
       (select max(j.path)  from journey_events j where j.user_id = u.id) as path,
       (select max(j.level) from journey_events j where j.user_id = u.id) as level,
       (select count(*) from voice_sessions v where v.user_id = u.id)    as voice_sessions
from u
order by u.n;


-- 3. Saved progress: which steps learners actually reached (keys in progress.data)
with owner as (
  select id from auth.users
  where email ilike '%<owner-email-1>%' or email ilike '%<owner-domain>%'
)
select k as progress_key, count(*) as learners
from progress p, jsonb_object_keys(p.data) as k
where p.user_id not in (select id from owner)
group by k
order by learners desc;


-- 4. Retention: learners who signed in on a later day than they signed up
with owner as (
  select id from auth.users
  where email ilike '%<owner-email-1>%' or email ilike '%<owner-domain>%'
)
select count(*)                                                        as accounts,
       count(*) filter (where last_sign_in_at::date > created_at::date) as returned_later
from auth.users
where id not in (select id from owner);


-- 5. Anonymous activity that never links to an account (DQ-03)
select event, count(*) as events, count(distinct visitor) as visitors
from journey_events
where user_id is null
group by event
order by event;


-- 6. Tracking defect checks
-- DQ-05: completed a first ticket with no started event
with owner as (
  select id from auth.users
  where email ilike '%<owner-email-1>%' or email ilike '%<owner-domain>%'
)
select count(distinct c.user_id) as completed_without_start
from journey_events c
where c.event = 'first_ticket_completed'
  and c.user_id is not null
  and c.user_id not in (select id from owner)
  and not exists (select 1 from journey_events s
                  where s.user_id = c.user_id and s.event = 'first_ticket_started');

-- DQ-06: accounts with no account_created event
with owner as (
  select id from auth.users
  where email ilike '%<owner-email-1>%' or email ilike '%<owner-domain>%'
)
select count(*) as accounts_without_created_event
from auth.users u
where u.id not in (select id from owner)
  and not exists (select 1 from journey_events j
                  where j.user_id = u.id and j.event = 'account_created');

-- DQ-01: the track values the event table will accept
select pg_get_constraintdef(oid) as allowed_paths
from pg_constraint
where conrelid = 'public.journey_events'::regclass
  and pg_get_constraintdef(oid) ilike '%path%';
