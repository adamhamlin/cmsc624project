\c main

-- NOTE: Expects variables 'foreign_host' and 'container_num' to be set

CREATE SERVER contractor_server_:container_num
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host :foreign_host, dbname 'main');

ALTER SERVER contractor_server_:container_num
    OPTIONS (ADD updatable 'false');

CREATE USER MAPPING FOR CURRENT_USER
    SERVER contractor_server_:container_num
    OPTIONS (user 'buddy', password 'pw');

CREATE SCHEMA contractor_:container_num;
IMPORT FOREIGN SCHEMA public
  FROM SERVER contractor_server_:container_num
  INTO contractor_:container_num;

-- Give access rights to user 'buddy'
GRANT USAGE ON FOREIGN SERVER contractor_server_:container_num TO buddy;
CREATE USER MAPPING FOR buddy
    SERVER contractor_server_:container_num
    OPTIONS (user 'buddy', password 'pw');
GRANT USAGE ON SCHEMA contractor_:container_num TO buddy;
GRANT SELECT ON ALL TABLES IN SCHEMA contractor_:container_num TO buddy;
