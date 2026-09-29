# ESign Lab: electronic signatures with Oracle APEX

A free, self-contained DocuSign-style signing application for Oracle APEX 26.1 and Oracle AI Database 26ai.
It needs no paid service and no extra server: the PDF work runs inside the database, with
[pdf-lib](https://pdf-lib.js.org) in MLE (JavaScript in the database), and the PKCS#7 digital seal is built in
PL/SQL with DBMS_CRYPTO.

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

- Oracle AI Database 26ai (23ai also works), including the Free edition, with MLE (JavaScript) available.
- Oracle APEX 26.1 or later, and an APEX workspace.
- openssl, to create the seal certificate.

## Install

1. As a DBA, create the ESIGN schema and add it to your workspace. Edit the workspace name at the top first:

   ```sql
   @sql/00_create_schema.sql
   ```

2. As a DBA, from the folder of this README, install the database objects. This loads pdf-lib too:

   ```sql
   @install.sql
   ```

3. Create the seal certificate with openssl, paste it into `sql/05_seal_key.sql` (the commands are in the file),
   and run that script. Then delete the key file.

4. In App Builder, import `apex/f301.sql` (ESign Signing, alias `ESIGN-SIGN`) and `apex/f300.sql`
   (ESign Lab, alias `ESIGN`). Choose ESIGN as the parsing schema and keep the aliases: the sender app and
   the signing links refer to `ESIGN-SIGN`.

5. Sign in to ESign Lab with a user of your workspace.

## Applications

| App | Alias | Who uses it | Pages |
|---|---|---|---|
| ESign Lab | ESIGN | Senders (APEX accounts) | Documents, Document (upload, signers, send, audit trail), Demo Mailbox, Download |
| ESign Signing | ESIGN-SIGN | Signers and anyone verifying (public) | Sign, Document PDF, Verify |

ESign Signing has a session cookie of its own, so a signing link opened in the sender's browser does not end
the sender's session.

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
| `sql/00_create_schema.sql` | The ESIGN schema-only account, its grants, and the workspace assignment |
| `sql/01_tables.sql` | Settings, documents, signers, immutable audit table, seal keys, demo mailbox |
| `sql/02_pdf_lib.sql` | pdf-lib 1.17.1 (MIT licence, text in the file) loaded as the MLE module PDF_LIB |
| `sql/03_pdf_mle.sql` | JavaScript module that stamps the signatures, builds the certificate, and adds the signature placeholder |
| `sql/04_esign_pkg.sql` | Business logic: envelopes, links, one-time codes, audit chain, PKCS#7 seal, verification |
| `sql/05_seal_key.sql` | Stores the seal certificate and private key |
| `install.sql` | Runs 01 to 04 in the ESIGN schema |
| `apex/f300.sql`, `apex/f301.sql` | The two APEX applications |
| `samples/website-development-agreement.pdf` | A sample document to practice with |

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
