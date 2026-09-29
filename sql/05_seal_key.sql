-- ESign Lab: stores the certificate and private key that seal completed PDFs.
--
-- 1. Create a self-signed certificate (valid 10 years) with openssl:
--
--    openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 3650 \
--      -keyout seal-key.pem -out seal-cert.pem \
--      -subj "/CN=ESign Lab Document Seal/O=ESign Lab" \
--      -addext "keyUsage=critical,digitalSignature,nonRepudiation"
--
-- 2. Paste the contents of seal-cert.pem and seal-key.pem below, including the BEGIN and END lines.
-- 3. Run this script in your schema (SQL*Plus, SQLcl, or SQL Workshop), then delete seal-key.pem
--    and do not save this file with the key in it.
--
-- Production: use a document-signing certificate from a CA (ideally on the Adobe Approved Trust List)
-- and keep the private key in a wallet or HSM rather than in a table.
set define off
begin
    esign_pkg.set_seal_key(
        p_label    => 'ESign Lab Document Seal',
        p_cert_pem => q'[
-----BEGIN CERTIFICATE-----
PASTE THE CONTENTS OF seal-cert.pem HERE
-----END CERTIFICATE-----
]',
        p_key_pem  => q'[
-----BEGIN PRIVATE KEY-----
PASTE THE CONTENTS OF seal-key.pem HERE
-----END PRIVATE KEY-----
]');
    commit;
end;
/
