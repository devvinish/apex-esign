-- ESign Lab: privileges the application's schema needs, in addition to the usual CREATE TABLE,
-- CREATE VIEW, CREATE SEQUENCE, CREATE PROCEDURE and CREATE TRIGGER that an APEX workspace schema has.
-- Run as a DBA (SYS or SYSTEM in the pluggable database, ADMIN on Autonomous Database).
-- Replace MY_SCHEMA with the parsing schema of your APEX workspace.
define schema = 'MY_SCHEMA'

-- All versions: SHA-256 hashes and random tokens (and, from 21c, the RSA signature of the seal)
grant execute on sys.dbms_crypto to &schema;

-- Oracle AI Database 23ai and 26ai only: JavaScript in the database (MLE) for pdf-lib.
-- Skip these three on 19c, which uses the Java engine (sql/03_pdf_java.sql) instead.
grant create mle to &schema;
grant execute on javascript to &schema;
grant execute dynamic mle to &schema;
