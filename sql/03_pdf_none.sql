-- ESign Lab: ESIGN_PDF for a database with neither MLE nor Java. Use it instead of the PDF engine scripts
-- (02 and 03_pdf_mle.sql, or 03_pdf_java.sql), and make the final PDF with your own PDF tool in
-- ESIGN_RENDER_PDF (sql/06_render_pdf.sql). Completed PDFs are stored without a digital seal and are verified
-- by their SHA-256 fingerprint on the Verify page.
create or replace package esign_pdf authid definer as
    function inspect(p_pdf in blob) return varchar2;
    function stamp(p_pdf in blob, p_meta in clob) return blob;
    function prepare_seal(p_pdf in blob, p_meta in clob) return blob;
    function sign_rsa(p_data in raw, p_key_b64 in varchar2) return raw;
end esign_pdf;
/

create or replace package body esign_pdf as

    -- a PDF (page count unknown), unless it is encrypted
    function inspect(p_pdf in blob) return varchar2 is
    begin
        if dbms_lob.instr(p_pdf, utl_raw.cast_to_raw('/Encrypt')) > 0 then
            return '{"ok":false,"error":"The PDF is password-protected or encrypted."}';
        end if;
        return '{"ok":true,"pages":null}';
    end inspect;

    function stamp(p_pdf in blob, p_meta in clob) return blob is
    begin
        raise_application_error(-20003, 'There is no PDF engine: make the final PDF in ESIGN_RENDER_PDF with your own PDF tool.');
    end stamp;

    -- no signature field: the PDF is stored as it is
    function prepare_seal(p_pdf in blob, p_meta in clob) return blob is
    begin
        return p_pdf;
    end prepare_seal;

    function sign_rsa(p_data in raw, p_key_b64 in varchar2) return raw is
    begin
        raise_application_error(-20003, 'There is no PDF engine to seal PDFs.');
    end sign_rsa;

end esign_pdf;
/
