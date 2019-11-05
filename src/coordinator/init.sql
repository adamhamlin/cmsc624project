\c main

CREATE EXTENSION postgres_fdw;

CREATE SERVER contractor_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'contractor', dbname 'main');

ALTER SERVER contractor_server
    OPTIONS (ADD updatable 'false');

CREATE USER MAPPING FOR CURRENT_USER
    SERVER contractor_server
    OPTIONS (user 'buddy', password 'pw');

CREATE SCHEMA contractor;
IMPORT FOREIGN SCHEMA public
  FROM SERVER contractor_server
  INTO contractor;

-- Give access rights to user 'buddy'
GRANT USAGE ON FOREIGN SERVER contractor_server TO buddy;
CREATE USER MAPPING FOR buddy
    SERVER contractor_server
    OPTIONS (user 'buddy', password 'pw');
GRANT USAGE ON SCHEMA contractor TO buddy;
GRANT SELECT ON ALL TABLES IN SCHEMA contractor TO buddy;