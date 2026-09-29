-- ESign Lab: installs the database objects into your schema.
-- Connect as the parsing schema of your APEX workspace (after sql/00_grants.sql) and run,
-- in SQL*Plus or SQLcl, from the folder of this file:
--     @install.sql
-- Then store the seal certificate with sql/05_seal_key.sql and create or import the applications.
whenever sqlerror exit failure
set define off sqlblanklines on serveroutput on verify off

prompt == Tables
@sql/01_tables.sql
prompt == pdf-lib (MLE module PDF_LIB)
@sql/02_pdf_lib.sql
prompt == PDF module (MLE module ESIGN_PDF_JS, package ESIGN_PDF)
@sql/03_pdf_mle.sql
prompt == Package ESIGN_PKG
@sql/04_esign_pkg.sql

prompt == Invalid objects (none expected)
set heading off feedback off
select object_type || ' ' || object_name from user_objects where status <> 'VALID';
select 'ERROR ' || name || ' line ' || line || ': ' || text from user_errors order by name, sequence;
set heading on feedback on
prompt Done.
