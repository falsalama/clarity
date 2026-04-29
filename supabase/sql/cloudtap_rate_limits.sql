-- Server-side abuse guard for paid Cloud Tap model calls.
-- Run once in the Supabase SQL editor before adding the Edge Function checks.

create table if not exists public.cloudtap_rate_limits (
  user_id uuid not null references auth.users(id) on delete cascade,
  bucket text not null,
  window_start timestamptz not null,
  request_count integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, bucket, window_start)
);

create index if not exists cloudtap_rate_limits_window_start_idx
on public.cloudtap_rate_limits (window_start);

alter table public.cloudtap_rate_limits enable row level security;

create or replace function public.consume_cloudtap_rate_limit(
  p_user_id uuid,
  p_bucket text,
  p_limit integer,
  p_window_seconds integer
)
returns table (
  allowed boolean,
  remaining integer,
  reset_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_window_start timestamptz;
  v_request_count integer;
  v_reset_at timestamptz;
begin
  if p_user_id is null then
    raise exception 'missing_user_id';
  end if;

  if p_bucket is null or length(trim(p_bucket)) = 0 then
    raise exception 'missing_bucket';
  end if;

  if p_limit < 1 or p_window_seconds < 1 then
    raise exception 'invalid_rate_limit_config';
  end if;

  v_window_start := to_timestamp(
    floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds
  );
  v_reset_at := v_window_start + make_interval(secs => p_window_seconds);

  insert into public.cloudtap_rate_limits (
    user_id,
    bucket,
    window_start,
    request_count,
    updated_at
  )
  values (
    p_user_id,
    trim(p_bucket),
    v_window_start,
    1,
    now()
  )
  on conflict (user_id, bucket, window_start)
  do update set
    request_count = public.cloudtap_rate_limits.request_count + 1,
    updated_at = now()
  returning request_count into v_request_count;

  allowed := v_request_count <= p_limit;
  remaining := greatest(p_limit - v_request_count, 0);
  reset_at := v_reset_at;

  return next;
end;
$$;

revoke all on function public.consume_cloudtap_rate_limit(uuid, text, integer, integer) from public;
grant execute on function public.consume_cloudtap_rate_limit(uuid, text, integer, integer) to service_role;

create or replace function public.delete_old_cloudtap_rate_limits()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted integer;
begin
  delete from public.cloudtap_rate_limits
  where window_start < now() - interval '7 days';

  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;

revoke all on function public.delete_old_cloudtap_rate_limits() from public;
grant execute on function public.delete_old_cloudtap_rate_limits() to service_role;
