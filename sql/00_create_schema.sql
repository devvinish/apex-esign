-- ESign Lab: creates the ESIGN schema and adds it to an APEX workspace.
-- Run as a DBA (SYS in the PDB, SYSTEM, or ADMIN on Autonomous Database):
--     @sql/00_create_schema.sql
-- ESIGN is a schema-only account: nobody logs in as ESIGN, APEX parses as it.
-- Change the workspace name below if yours is not APEXBOOK.
define workspace = 'APEXBOOK'
set serveroutput on verify off

create user esign no authentication
    default tablespace users
    quota unlimited on users;

grant create table, create view, create sequence, create procedure, create trigger,
      create type, create synonym, create job, create mle to esign;
grant execute on sys.dbms_crypto to esign;     -- SHA-256, random tokens, RSA signature
grant execute on javascript to esign;          -- MLE (JavaScript in the database)
grant execute dynamic mle to esign;
grant db_developer_role to esign;

begin
    apex_instance_admin.add_schema(p_workspace => '&workspace', p_schema => 'ESIGN');
    commit;
    dbms_output.put_line('Schema ESIGN added to workspace &workspace');
end;
/
