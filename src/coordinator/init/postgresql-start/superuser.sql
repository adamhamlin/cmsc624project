-- Everything in this file will be executed by the superuser in database main

\c main

CREATE EXTENSION source_tracking_fdw;
CREATE EXTENSION postgres_fdw;

-- --------------------------------------------------------------------------------------
-- Summary function that will call other functions for a given user query
drop function if exists pay_per_query(text);
create function pay_per_query(query text)
returns setof record
volatile
language plpgsql
as $$
declare
  r record;
  r_cnt int := 0;
  payload_size int := 0;
  src_contributions jsonb := '{}';
  total_contributions int := 0;
  total_accesses int := 0;
  access_cnt int;
  src_reads jsonb := '{}';
  src_payout int;
  src_key text;
  src_val int;
  x numeric;
  y numeric;

  work_coordinator int := 0;
  work_contractor int := 0;

  cost_work_coordinator numeric;
  cost_work_contractor numeric;
  cost_payload_size numeric;
  cost_contribution numeric;
  cost_accesses numeric;
  total_cost numeric := 0;
  payouts jsonb := '{}';
begin
  -- Set cost tuning parameters
  SET cost_params.work_coordinator TO 0.02;
  SET cost_params.work_contractor TO 0.02;
  SET cost_params.payload_size TO 0.005;
  SET cost_params.contribution TO 25;
  SET cost_params.accesses TO 1;

  for r in EXECUTE query loop
    r_cnt := r_cnt + 1;
    payload_size := payload_size + (select octet_length(r::text));
    src_contributions := agg_source_sfunc(src_contributions, r.source);
    return next r;
  end loop;

  -- Loop thru and compute total contributions and accesses
  for src_key, src_val in select * from jsonb_each(src_contributions) loop
    access_cnt := (select accesses(src_key));
    src_reads := src_reads || ('{"' || src_key || '":' || access_cnt || '}')::jsonb;
    payouts := payouts || ('{"' || src_key || '":' || (current_setting('cost_params.accesses')::numeric * access_cnt) || '}')::jsonb;
    total_contributions := total_contributions + src_val;
    total_accesses := total_accesses + access_cnt;
  end loop;

  -- compute the execution cost
  work_coordinator := plan_cost(query);

  raise notice '########### Summary ############';
  raise notice 'Returning % records', r_cnt;
  raise notice 'Returning ~% bytes of data', payload_size;
  raise notice 'Result contribution by source: % ', src_contributions;
  --raise notice 'Total contributions: % ', total_contributions;
  raise notice 'Table access scores by source: % ', src_reads;
  raise notice 'Execution plan cost: % ', work_coordinator;

  -- Loop thru again and compute final publisher payouts
  for src_key, src_val in select * from jsonb_each(src_contributions) loop
    x := (payouts->>src_key)::numeric; -- current payout for this source
    y := (current_setting('cost_params.contribution')::numeric * src_val) / total_contributions;
    payouts := payouts || ('{"' || src_key || '":' || round(x + y, 2) || '}')::jsonb;
  end loop;

  -- Compute weighted costs
  cost_work_coordinator = current_setting('cost_params.work_coordinator')::numeric * work_coordinator;
  cost_work_contractor = current_setting('cost_params.work_contractor')::numeric * work_contractor;
  cost_payload_size = current_setting('cost_params.payload_size')::numeric * payload_size;
  cost_contribution = current_setting('cost_params.contribution')::numeric;
  cost_accesses = current_setting('cost_params.accesses')::numeric * total_accesses;
  total_cost = cost_work_coordinator + cost_work_contractor + cost_payload_size + cost_contribution + cost_accesses;

  raise notice '########### Weighted Costs ############';
  raise notice 'Base cost: % ', cost_contribution;
  raise notice 'Cost of coordinator work: % ', cost_work_coordinator;
  --raise notice 'Cost of contractor work: % ', cost_work_contractor;
  raise notice 'Cost of payload size: % ', cost_payload_size;
  raise notice 'Cost of accesses: % ', cost_accesses;
  raise notice 'Total query cost: % ', total_cost;
  raise notice 'Publisher payouts: % ', payouts;
  raise notice 'Coordinator payout: %', cost_work_coordinator + cost_payload_size;

  return;
end;
$$;
-- --------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------
-- Custom aggregator for json source column
drop aggregate if exists agg_source(jsonb);
drop function if exists agg_source_finalfunc(jsonb);
drop function if exists agg_source_sfunc(jsonb, jsonb);
drop function if exists accesses(text, text);

create function agg_source_sfunc(agg_state jsonb, el jsonb)
returns jsonb
immutable
language plpgsql
as $$
declare
  src text;
  cnt int;
  sum int;
begin
  for src, cnt in select * from jsonb_each_text(el) loop
    if agg_state->>src is null then
      sum := cnt;
    else
      sum := (agg_state->>src)::int + cnt;
    end if;
    agg_state := agg_state || ('{ "' || src || '": ' || sum || ' }')::jsonb;
  end loop;

  return agg_state;
end;
$$;

create function add_sources(a jsonb, b jsonb) -- just aliasing above function
returns jsonb
immutable
strict
language plpgsql
as $$
begin
  return agg_source_sfunc(a, b);
end;
$$;

create function agg_source_finalfunc(agg_state jsonb)
returns jsonb
immutable
strict
language plpgsql
as $$
begin
  return agg_state;
end;
$$;

create aggregate agg_source (jsonb)
(
    sfunc = agg_source_sfunc,
    stype = jsonb,
    finalfunc = agg_source_finalfunc,
    initcond = '{}'
);

-- --------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------
-- Get accesses score for given foreign table
create function accesses(fully_qualified_table_name text)
returns int
language plpgsql
as $$
declare
  returned record;
  seq bigint;
  idx bigint;
  place int;
  cnt int := 0;
  contractor text;
  table_name text;
begin
  contractor := split_part(fully_qualified_table_name, '.', 1);
  table_name := split_part(fully_qualified_table_name, '.', 2);
  EXECUTE format('SELECT seq_scan, idx_scan FROM %s where relname = %s', contractor || '.pg_stat_user_tables', quote_literal(table_name))
    INTO seq, idx;
  place := seq + ceil(cast(idx as double precision)/ 10.0);
  while place >= 10^cnt loop
    cnt := cnt + 1;
  end loop;
  if cnt <= 5 then
    return cnt * 1;
  else
    return cnt * 3;
  end if;
end;
$$;

-- --------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------
-- Get the estimated work that the coordinator will do
create function plan_cost(query text)
returns numeric --double precision
language plpgsql
as $$
declare
  lines record;
  outp text;
  cost text;
  --int_cost text
  num_cost int := 0;
begin
  for lines in select explain(query) loop
    execute format('select substring(%s, ''\.\.(.+) r'')', quote_literal(lines)) into cost;
    num_cost := num_cost + cast(cost as numeric) -100;
  end loop;
  return num_cost; --cast(num_cost as double precision);
end;
$$;  

create function explain(query text)
returns table(src text)
language plpgsql
as $$
begin
  return query execute format('explain %s', query);
end;
$$;  
