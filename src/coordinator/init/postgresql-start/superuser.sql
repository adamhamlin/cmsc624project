-- Everything in this file will be executed by the superuser in database main

\c main

CREATE EXTENSION source_tracking_fdw;
CREATE EXTENSION postgres_fdw;

-- Custom aggregator for json source column
drop aggregate if exists agg_source(jsonb);
drop function if exists agg_source_finalfunc(jsonb);
drop function if exists agg_source_sfunc(jsonb, jsonb);

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
