-- ESign Lab: installs the database objects into the ESIGN schema.
-- Run as a DBA in SQL*Plus or SQLcl, from the folder of this file, after sql/00_create_schema.sql:
--     @install.sql
-- Then run seal-key.sql (created by seal-key.sh) and import apex/f300.sql and apex/f301.sql.
whenever sqlerror exit failure
set verify off
define schema = ESIGN
alter session set current_schema = &schema;
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
select object_type || ' ' || object_name from all_objects where owner = sys_context('userenv', 'current_schema') and status <> 'VALID';
select 'ERROR ' || name || ' line ' || line || ': ' || text from all_errors where owner = sys_context('userenv', 'current_schema') order by name, sequence;
set heading on feedback on
prompt Done.
