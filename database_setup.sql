-- Run once in Supabase SQL Editor. Review and test access before using real school data.
create table if not exists public.medium_members (
 id uuid primary key references auth.users(id) on delete cascade,
 role text not null default 'teacher' check (role in ('teacher','leader'))
);
create table if not exists public.medium_plans (
 id text primary key, owner_id uuid not null references auth.users(id),
 updated_at timestamptz not null, body jsonb not null
);
create table if not exists public.medium_reviews (
 plan_id text primary key references public.medium_plans(id) on delete cascade,
 decision text not null check (decision in ('Pending','Approved','Revision Required')),
 feedback text not null default '', reviewer text not null default '', reviewed_at timestamptz
);
create or replace function public.medium_is_leader() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.medium_members where id=auth.uid() and role='leader');
$$;
revoke all on function public.medium_is_leader() from public;
grant execute on function public.medium_is_leader() to authenticated;
alter table public.medium_members enable row level security;
alter table public.medium_plans enable row level security;
alter table public.medium_reviews enable row level security;
create policy "Member reads own" on public.medium_members for select to authenticated using (id=auth.uid());
create policy "Teacher reads own; leader reads all plans" on public.medium_plans for select to authenticated using (owner_id=auth.uid() or public.medium_is_leader());
create policy "Teacher inserts own plans" on public.medium_plans for insert to authenticated with check (owner_id=auth.uid());
create policy "Teacher updates own plans" on public.medium_plans for update to authenticated using (owner_id=auth.uid()) with check (owner_id=auth.uid());
create policy "Teacher sees own reviews; leader sees all" on public.medium_reviews for select to authenticated using (exists(select 1 from public.medium_plans p where p.id=plan_id and (p.owner_id=auth.uid() or public.medium_is_leader())));
create policy "Leader inserts review" on public.medium_reviews for insert to authenticated with check (public.medium_is_leader());
create policy "Leader updates review" on public.medium_reviews for update to authenticated using (public.medium_is_leader()) with check (public.medium_is_leader());
-- Create users in Supabase Authentication > Users first. Then assign roles:
-- insert into public.medium_members(id,role) values ('PASTE-LEADER-AUTH-USER-UUID','leader');
-- insert into public.medium_members(id,role) values ('PASTE-TEACHER-AUTH-USER-UUID','teacher');
