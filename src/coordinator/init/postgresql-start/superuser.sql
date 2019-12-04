-- Everything in this file will be executed by the superuser in database main

\c main

CREATE EXTENSION source_tracking_fdw;
CREATE EXTENSION postgres_fdw;

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

create function accesses(table_name text, contractor text)
returns numeric
language plpgsql
as $$
declare
  returned record;
  seq bigint;
  idx bigint;
  place int;
  cnt int := 0;
begin
  --with tot as
  --(select reltuples::bigint from pg_class where relname= table_name)
  EXECUTE format('SELECT seq_scan, idx_scan FROM %s where relname = %s', contractor||'.pg_stat_user_tables', quote_literal(table_name))
  INTO seq, idx;
  place := seq + ceil(cast(idx as double precision)/ 10.0);
  while place >= 10^cnt loop
    cnt := cnt + 1;
  end loop;
  if cnt <= 5 then
    return cnt * 1;
  else
    return cnt * 15;
  end if;  
end;
$$;

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