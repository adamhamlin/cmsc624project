\c main

-- NOTE: Expects variable 'new_search_path' to be set

ALTER DATABASE main SET search_path=:new_search_path;
