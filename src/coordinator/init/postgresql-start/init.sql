\c main

-- NOTE: Expects variables 'foreign_host' and 'container_num' to be set

CREATE SERVER contractor_server_:container_num
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host :foreign_host, dbname 'main');

ALTER SERVER contractor_server_:container_num
    OPTIONS (ADD updatable 'false', ADD use_remote_estimate 'true');

CREATE USER MAPPING FOR CURRENT_USER
    SERVER contractor_server_:container_num
    OPTIONS (user 'buddy', password 'pw');

CREATE SCHEMA raw_contractor_:container_num;

IMPORT FOREIGN SCHEMA public
  FROM SERVER contractor_server_:container_num
  INTO raw_contractor_:container_num;

IMPORT FOREIGN SCHEMA pg_catalog
  LIMIT TO (pg_stat_user_tables)
  FROM SERVER contractor_server_:container_num
  INTO raw_contractor_:container_num;

-- Give access rights to user 'buddy' to "contractor_X" schema
CREATE SCHEMA contractor_:container_num;
GRANT USAGE ON SCHEMA contractor_:container_num TO buddy;
GRANT SELECT ON ALL TABLES IN SCHEMA contractor_:container_num TO buddy;

-- Create views for every foreign table with source column initialized
SET myvars.container_num TO :'container_num';
DO $$
DECLARE
    tbl text;
    schema_str text;
    raw_fqname text;
    fqname text;
BEGIN
   schema_str := 'contractor_' || current_setting('myvars.container_num');
   FOR tbl IN
      SELECT foreign_table_name
      FROM   information_schema.foreign_tables
      WHERE  foreign_table_schema = 'raw_' || schema_str
   LOOP
      fqname := schema_str || '.' || tbl;
      raw_fqname := 'raw_' || fqname;
      raise notice 'Creating view %', fqname;
      EXECUTE 'CREATE VIEW ' || fqname
        || ' AS SELECT a.*, ''{ "' || fqname || '": 1 }''::jsonb AS source FROM ' || raw_fqname || ' a';
      EXECUTE 'GRANT SELECT ON ' || fqname || ' TO buddy';
   END LOOP;
END $$;
