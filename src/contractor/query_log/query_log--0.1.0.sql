CREATE FUNCTION query_log(OUT query TEXT, pid OUT TEXT)
RETURNS SETOF RECORD
AS 'MODULE_PATHNAME', 'query_log'
LANGUAGE C STRICT VOLATILE;