-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION source_tracking_fdw" to load this file. \quit

-- CREATE FUNCTION source_tracking_fdw_handler()
-- RETURNS fdw_handler
-- AS 'MODULE_PATHNAME'
-- LANGUAGE C STRICT;

-- CREATE FUNCTION source_tracking_fdw_validator(text[], oid)
-- RETURNS void
-- AS 'MODULE_PATHNAME'
-- LANGUAGE C STRICT;

-- CREATE FOREIGN DATA WRAPPER source_tracking_fdw
--   HANDLER source_tracking_fdw_handler
--   VALIDATOR source_tracking_fdw_validator;

-- Dummy example, for now
CREATE FUNCTION source_tracking_fdw(integer) RETURNS text
AS '$libdir/source_tracking_fdw'
LANGUAGE C IMMUTABLE STRICT;