# ESign Lab: electronic signatures with Oracle APEX

A free, self-contained DocuSign-style signing application for Oracle APEX 26.1 and Oracle AI Database 26ai.
It needs no paid service and no extra server: the PDF work runs inside the database, with
[pdf-lib](https://pdf-lib.js.org) in MLE (JavaScript in the database) on 23ai and 26ai, or with a small Java
engine in the database's Java on 19c. The PKCS#7 digital seal is built in PL/SQL.

Step-by-step guide with screenshots: on [vinish.dev](https://vinish.dev).

## Features

- Upload a PDF, add signers, and send in sequential or parallel order.
- Signing links with a random 256-bit token (only its SHA-256 is stored), which expire and can be replaced.
- Identity check with an e-mailed 6-digit one-time code, bound to the signer's APEX session.
- The signer reviews the PDF, accepts the e-signature disclosure, then draws or types a signature, or declines.
- Signatures are stamped on the PDF, the envelope ID is added to every page, and a Certificate of Completion is appended.
- The completed PDF is sealed with a PKCS#7 digital signature (adbe.pkcs7.detached, RSA 2048, SHA-256).
  PDF readers show it in their signature panel, and any change to the file breaks it.
- The audit trail is an immutable table, with each row chained to the previous one by SHA-256.
- A public Verify page fingerprints a PDF in the browser (the file is not uploaded) and reports whether it is
  an authentic signed document, an original, or unknown.
- A demo mailbox for instances without a mail server: e-mails are kept in the app, with their links and codes.

## Requirements

- Oracle AI Database 26ai or 23ai with MLE (JavaScript) available, including the Free edition, or Oracle
  Database 19c with the database's Java (the component JServer JAVA Virtual Machine).
- Oracle APEX 26.1 or later, and an APEX workspace.
- openssl, to create the seal certificate.

## Install into your schema

1. Ask a DBA to run `sql/00_grants.sql` with your schema name. On 19c, skip its three MLE grants.

2. Connect as your schema (the parsing schema of your APEX workspace) and, from the folder of this README, run
   the installer for your database:

   ```sql
   @install.sql        -- 23ai and 26ai: pdf-lib in MLE
   @install_19c.sql    -- 19c: the Java engine
   ```

   Both create the tables, the PDF engine (package ESIGN_PDF), and the package ESIGN_PKG.

3. Create the seal certificate with openssl, paste it into `sql/05_seal_key.sql` (the commands are in the file),
   and run that script in your schema. Then delete the key file.

4. In App Builder, import `apex/f301.sql` (ESign Signing, alias `ESIGN-SIGN`) and `apex/f300.sql`
   (ESign Lab, alias `ESIGN`) with your schema as the parsing schema. Keep the aliases: the sender app and the
   signing links refer to `ESIGN-SIGN` (or change the setting SIGN_APP).

5. Run ESign Lab and sign in with a user of your workspace.

## Applications

| App | Alias | Who uses it | Pages |
|---|---|---|---|
| ESign Lab | ESIGN | Senders (APEX accounts) | Documents, Document (upload, signers, send, audit trail), Demo Mailbox, Download |
| ESign Signing | ESIGN-SIGN | Signers and anyone verifying (public) | Sign, Document PDF, Verify |

ESign Signing has a session cookie of its own, so a signing link opened in the sender's browser does not end
the sender's session.

## Use your own PDF tool

The e-signature part only produces data: the original PDF and the signature images (BLOBs), and all the
evidence as JSON (`esign_pkg.evidence_json(p_doc_id)`, a CLOB). The final PDF of a completed envelope comes
from one function in your schema, `ESIGN_RENDER_PDF(p_doc_id) return blob` (`sql/06_render_pdf.sql`). It uses
the built-in engine by default; replace its return statement with a call to PL/PDF, AOP, Jasper Reports,
BI Publisher, VinAura, or any other tool. FINALIZE seals whatever PDF it returns when a PDF engine (MLE or Java)
is installed. With `sql/03_pdf_none.sql` (no engine), the PDF is stored as returned, without a seal, and verified
by its SHA-256 fingerprint.

## Settings (table ESIGN_SETTINGS)

| Name | Default | Meaning |
|---|---|---|
| DEV_MODE | Y | Y keeps e-mails in the demo mailbox and shows one-time codes on screen. Set N when APEX can send mail. |
| ORG_NAME | ESign Lab | Shown in e-mails and on the certificate page |
| FROM_EMAIL | no-reply@example.com | Sender address of the e-mails |
| LINK_TTL_DAYS | 14 | Days a signing link stays valid |
| OTP_TTL_MINUTES | 10 | Minutes a one-time code stays valid |
| OTP_MAX_ATTEMPTS | 5 | Wrong codes allowed before a new code is needed |
| MAX_PDF_MB | 20 | Largest PDF accepted |
| SIGN_APP | ESIGN-SIGN | Alias of the signing application |

## Files

| File | Contents |
|---|---|
| `sql/00_grants.sql` | The privileges your schema needs (run by a DBA) |
| `sql/01_tables.sql` | Settings, documents, signers, the audit table (immutable from 19.11), seal keys, demo mailbox |
| `sql/02_pdf_lib.sql` | 23ai/26ai: pdf-lib 1.17.1 (MIT licence, text in the file) loaded as the MLE module PDF_LIB |
| `sql/03_pdf_mle.sql` | 23ai/26ai: the JavaScript module that stamps the PDF, and the package ESIGN_PDF |
| `sql/03_pdf_java.sql` | 19c: the same package ESIGN_PDF in Java (core Java 8 only, no libraries to load) |
| `sql/04_esign_pkg.sql` | Business logic: envelopes, links, one-time codes, audit chain, PKCS#7 seal, verification |
| `sql/03_pdf_none.sql` | ESIGN_PDF without a PDF engine, for databases with neither MLE nor Java |
| `sql/05_seal_key.sql` | Stores the seal certificate and private key |
| `sql/06_render_pdf.sql` | ESIGN_RENDER_PDF: makes the final PDF; change it to use your own PDF tool |
| `install.sql`, `install_19c.sql` | Run the scripts of your database version in your schema |
| `apex/f300.sql`, `apex/f301.sql` | The two APEX applications |
| `samples/website-development-agreement.pdf` | A sample document to practice with |

The Java engine changes the PDF with an incremental update, so the original PDF's bytes stay unchanged at the
start of the signed file. It does not use a PDF library such as Apache PDFBox, because those need AWT, which the
database's Java does not include.

## Before production

- Seal certificate: PDF readers show a self-signed seal as "validity unknown", although they still confirm that
  the document was not changed. Use a document-signing certificate from a CA on the Adobe Approved Trust List,
  and keep the private key in a wallet or HSM rather than in a table.
- Timestamp: add an RFC 3161 timestamp so the seal stays verifiable after the certificate expires.
- E-mail: configure SMTP for APEX (with SPF and DKIM for the sender domain) and set DEV_MODE to N.
- Legal: an electronic signature with this audit trail suits most business documents (ESIGN Act and UETA in the
  US, simple electronic signatures under eIDAS in the EU, the IT Act 2000 in India). Wills, powers of attorney,
  property deeds, and negotiable instruments need other methods, such as Aadhaar eSign or a DSC in India.
  This is not legal advice.

By [Vinish Kapoor](https://vinish.dev).
