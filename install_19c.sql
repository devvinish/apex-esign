-- ESign Lab: installs the database objects into your schema on Oracle Database 19c, which has no
-- JavaScript in the database: the Java engine (sql/03_pdf_java.sql) replaces pdf-lib and the MLE module.
-- Connect as the parsing schema of your APEX workspace (after sql/00_grants.sql) and run,
-- in SQL*Plus or SQLcl, from the folder of this file:
--     @install_19c.sql
-- Then store the seal certificate with sql/05_seal_key.sql and create or import the applications.
whenever sqlerror exit failure
set define off sqlblanklines on serveroutput on verify off

prompt == Tables
@sql/01_tables.sql
prompt == PDF engine in Java (Java source ESignPdf, package ESIGN_PDF)
@sql/03_pdf_java.sql
prompt == Package ESIGN_PKG
@sql/04_esign_pkg.sql
prompt == Function ESIGN_RENDER_PDF (the final PDF)
@sql/06_render_pdf.sql

prompt == Invalid objects (none expected)
set heading off feedback off
select object_type || ' ' || object_name from user_objects where status <> 'VALID';
select 'ERROR ' || name || ' line ' || line || ': ' || text from user_errors where attribute = 'ERROR' order by name, sequence;
set heading on feedback on
prompt Done.
