-- ESign Lab: the function that makes the final PDF of a completed envelope. ESIGN_PKG.FINALIZE calls it,
-- then seals whatever PDF it returns. This is the only place where a PDF tool is used: replace the body with
-- your own tool (PL/PDF, AOP, Jasper, BI Publisher, VinAura, ...) if you like.
--
-- The data for the PDF:
--   esign_documents.original_pdf        the uploaded PDF (BLOB)
--   esign_signers.signature_png         each signer's signature image (BLOB, PNG)
--   esign_pkg.evidence_json(p_doc_id)   everything as JSON (CLOB): envelope, signers, audit trail
create or replace function esign_render_pdf(p_doc_id in number) return blob
    authid definer
is
    l_original blob;
begin
    select original_pdf into l_original from esign_documents where doc_id = p_doc_id;

    -- The built-in PDF engine: stamps the signatures on the original and appends the certificate of completion
    return esign_pdf.stamp(l_original, esign_pkg.evidence_json(p_doc_id));

    -- Or your own tool, for example:
    --   return my_pdf_tool.render(p_doc_id);
    -- Or no PDF tool at all: the original, unchanged, is sealed as it is:
    --   return l_original;
end esign_render_pdf;
/
