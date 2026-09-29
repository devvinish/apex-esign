-- ESign Lab: privileges the application's schema needs, in addition to the usual CREATE TABLE,
-- CREATE VIEW, CREATE SEQUENCE and CREATE PROCEDURE that an APEX workspace schema already has.
-- Run as a DBA (SYS or SYSTEM in the pluggable database, ADMIN on Autonomous Database).
-- Replace MY_SCHEMA with the parsing schema of your APEX workspace.
define schema = 'MY_SCHEMA'

-- JavaScript in the database (MLE): modules, environments, and running them
grant create mle to &schema;
grant execute on javascript to &schema;
grant execute dynamic mle to &schema;

-- SHA-256 hashes, random tokens, and the RSA signature of the seal
grant execute on sys.dbms_crypto to &schema;
