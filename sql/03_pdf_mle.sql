-- ESign Lab: PDF work in the database with pdf-lib 1.17.1 (MIT licence) running in MLE (JavaScript).
-- Needs the MLE module PDF_LIB, created from pdf-lib.esm.min.js by install.sh.
set define off sqlblanklines on

create or replace mle module esign_pdf_js language javascript as
import { PDFDocument, StandardFonts, rgb, PDFName, PDFNumber, PDFHexString, PDFString } from 'pdf-lib';

const INK = rgb(0.13, 0.16, 0.22);
const MUTED = rgb(0.42, 0.45, 0.5);
const LINE = rgb(0.82, 0.85, 0.9);
const ACCENT = rgb(0.11, 0.35, 0.72);
const SIG_BYTES = 8192;                       // room for the PKCS#7 signature
const NO_TICKS = { objectsPerTick: Infinity };  // MLE has no setTimeout: never pause between objects

// fallback in case a pdf-lib code path still asks for a timer
if (typeof globalThis.setTimeout !== 'function') {
    globalThis.setTimeout = (fn) => { Promise.resolve().then(fn); return 0; };
}

function readBlob(b) { return b.read(b.length(), 1); }
function toBlob(bytes) { const out = OracleBlob.createTemporary(false); out.write(1, bytes); return out; }
function b64ToBytes(b64) {
    const bin = atob(String(b64).replace(/[^A-Za-z0-9+/=]/g, ''));
    const out = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
}

// Standard fonts only know WinAnsi characters: replace the others, so no name breaks the PDF.
function safeText(font, s) {
    const allowed = new Set(font.getCharacterSet());
    return Array.from(String(s == null ? '' : s)).map(c => allowed.has(c.codePointAt(0)) ? c : '?').join('');
}
function fit(font, size, s, width) {
    let t = safeText(font, s);
    if (font.widthOfTextAtSize(t, size) <= width) return t;
    while (t.length > 1 && font.widthOfTextAtSize(t + '...', size) > width) t = t.slice(0, -1);
    return t + '...';
}
function wrap(font, size, s, width) {
    // words wider than the line (hashes, URLs) are split into pieces that fit
    const words = [];
    for (const w of safeText(font, s).split(/\s+/)) {
        let rest = w;
        while (rest.length > 1 && font.widthOfTextAtSize(rest, size) > width) {
            let n = rest.length - 1;
            while (n > 1 && font.widthOfTextAtSize(rest.slice(0, n), size) > width) n--;
            words.push(rest.slice(0, n));
            rest = rest.slice(n);
        }
        words.push(rest);
    }
    const lines = [];
    let line = '';
    for (const w of words) {
        const next = line ? line + ' ' + w : w;
        if (font.widthOfTextAtSize(next, size) > width && line) { lines.push(line); line = w; } else { line = next; }
    }
    if (line) lines.push(line);
    return lines;
}

// Page count and encryption of an uploaded PDF: {"ok":true,"pages":3} or {"ok":false,"error":"..."}
export async function inspect(pdfBlob) {
    try {
        const doc = await PDFDocument.load(readBlob(pdfBlob), { ...NO_TICKS, ignoreEncryption: true, updateMetadata: false });
        if (doc.isEncrypted) return JSON.stringify({ ok: false, error: 'The PDF is password-protected or encrypted.' });
        return JSON.stringify({ ok: true, pages: doc.getPageCount() });
    } catch (e) {
        return JSON.stringify({ ok: false, error: 'The file is not a readable PDF (' + e.message + ').' });
    }
}

// Stamps the signatures on the original, adds the certificate pages, and prepares an empty
// signature field (/ByteRange and /Contents placeholders) that PL/SQL fills with the PKCS#7 seal.
export async function stamp(pdfBlob, metaJson) {
    const meta = JSON.parse(metaJson);
    const doc = await PDFDocument.load(readBlob(pdfBlob), { ...NO_TICKS, updateMetadata: false });
    const font = await doc.embedFont(StandardFonts.Helvetica);
    const bold = await doc.embedFont(StandardFonts.HelveticaBold);
    const pages = doc.getPages();

    // 1. Envelope ID on every page of the original
    for (const p of pages) {
        const box = p.getCropBox();
        p.drawText(safeText(font, meta.org + ' Envelope ID: ' + meta.envelopeId), {
            x: box.x + 18, y: box.y + box.height - 14, size: 7, font, color: MUTED });
    }

    // 2. Signature stamps where the sender asked for them
    const images = {};
    for (const s of meta.signers) {
        if (s.png) images[s.signerId] = await doc.embedPng(b64ToBytes(s.png));
    }
    const slots = {};
    for (const s of meta.signers) {
        if (s.stampPage === 'NONE' || !images[s.signerId]) continue;
        const page = s.stampPage === 'FIRST' ? pages[0] : pages[pages.length - 1];
        const box = page.getCropBox();
        const w = 180, h = 64, m = 30;
        const key = (s.stampPage === 'FIRST' ? 0 : pages.length - 1) + s.stampPosition;
        const n = slots[key] = (slots[key] || 0) + 1;          // two signers in one slot: stack them
        const top = s.stampPosition.startsWith('TOP');
        let x = box.x + m;
        if (s.stampPosition.endsWith('RIGHT')) x = box.x + box.width - w - m;
        if (s.stampPosition.endsWith('CENTER')) x = box.x + (box.width - w) / 2;
        const y = top ? box.y + box.height - m - 12 - n * (h + 8) : box.y + m + (n - 1) * (h + 8);
        page.drawRectangle({ x, y, width: w, height: h, borderColor: ACCENT, borderWidth: 0.8, color: rgb(1, 1, 1), opacity: 0.92 });
        page.drawText(safeText(bold, 'Signed by:'), { x: x + 6, y: y + h - 11, size: 6.5, font: bold, color: ACCENT });
        const img = images[s.signerId];
        const scale = Math.min((w - 12) / img.width, 30 / img.height);
        page.drawImage(img, { x: x + 6, y: y + 17, width: img.width * scale, height: img.height * scale });
        page.drawText(fit(font, 6.5, s.name, w - 12), { x: x + 6, y: y + 9, size: 6.5, font, color: INK });
        page.drawText(fit(font, 5.5, s.signedOn + '  ' + s.signatureId, w - 12), { x: x + 6, y: y + 2.5, size: 5.5, font, color: MUTED });
    }

    // 3. Certificate of completion
    const W = 612, H = 792, L = 50, R = W - 50;
    let page, y;
    const newPage = () => {
        page = doc.addPage([W, H]);
        page.drawRectangle({ x: 0, y: H - 6, width: W, height: 6, color: ACCENT });
        page.drawText(safeText(font, meta.org + ' Envelope ID: ' + meta.envelopeId), { x: L, y: 24, size: 7, font, color: MUTED });
        page.drawText('Certificate of Completion', { x: R - font.widthOfTextAtSize('Certificate of Completion', 7), y: 24, size: 7, font, color: MUTED });
        y = H - 50;
    };
    const need = (hgt) => { if (y - hgt < 50) newPage(); };
    const text = (s, x, size, f = font, color = INK) => page.drawText(s, { x, y, size, font: f, color });
    const rule = () => { page.drawLine({ start: { x: L, y }, end: { x: R, y }, thickness: 0.6, color: LINE }); };
    const row = (label, value) => {
        const lines = wrap(font, 9, value, R - L - 130);
        need(12 * lines.length + 2);
        text(safeText(bold, label), L, 9, bold, MUTED);
        lines.forEach((l, i) => page.drawText(l, { x: L + 130, y: y - i * 12, size: 9, font, color: INK }));
        y -= 12 * lines.length + 2;
    };

    newPage();
    text('Certificate of Completion', L, 20, bold);
    y -= 18;
    text(safeText(font, meta.org + ' electronic signature record'), L, 10, font, MUTED);
    y -= 26;
    row('Document', meta.title);
    row('Envelope ID', meta.envelopeId);
    row('File', meta.fileName);
    row('Pages', String(meta.pages) + ' + certificate');
    row('Sent by', meta.sender);
    row('Sent', meta.sentOn);
    row('Completed', meta.completedOn);
    row('Routing', meta.routing === 'SEQUENTIAL' ? 'Sequential (in signing order)' : 'Parallel');
    row('Original SHA-256', meta.originalSha256);
    y -= 8; rule(); y -= 22;

    text('Signers', L, 13, bold);
    y -= 20;
    for (const s of meta.signers) {
        need(120);
        const top = y;
        text(fit(bold, 10.5, s.name, 260), L, 10.5, bold);
        y -= 13;
        text(fit(font, 9, s.email, 260), L, 9, font, MUTED);
        y -= 16;
        const facts = [
            ['Status', s.status],
            ['Signed', s.signedOn || '-'],
            ['Signature ID', s.signatureId || '-'],
            ['Signature', s.method === 'TYPED' ? 'Typed and adopted' : 'Drawn'],
            ['Authentication', 'E-mail link + one-time code (' + (s.otpVerifiedOn || '-') + ')'],
            ['Consent', s.consentOn ? 'Accepted ' + s.consentOn : '-'],
            ['IP address', s.ip || '-'],
            ['Document SHA-256', s.docSha256 || '-']
        ];
        for (const [k, v] of facts) {
            page.drawText(safeText(font, k), { x: L, y, size: 7.5, font, color: MUTED });
            page.drawText(fit(font, 7.5, v, 225), { x: L + 72, y, size: 7.5, font, color: INK });
            y -= 10.5;
        }
        if (images[s.signerId]) {
            const img = images[s.signerId];
            const scale = Math.min(200 / img.width, 60 / img.height);
            page.drawRectangle({ x: 350, y: top - 70, width: 212, height: 72, borderColor: LINE, borderWidth: 0.8 });
            page.drawImage(img, { x: 356, y: top - 64, width: img.width * scale, height: img.height * scale });
        }
        if (s.declineReason) {
            page.drawText(fit(font, 8, 'Declined: ' + s.declineReason, R - L), { x: L, y, size: 8, font, color: rgb(0.7, 0.1, 0.1) });
            y -= 11;
        }
        y -= 10; rule(); y -= 18;
    }

    need(60);
    text('Audit trail', L, 13, bold);
    y -= 18;
    for (const a of meta.audit) {
        const lines = wrap(font, 7.5, a.details || '', R - (L + 312));
        need(10 * Math.max(1, lines.length) + 4);
        page.drawText(safeText(font, a.time), { x: L, y, size: 7.5, font, color: MUTED });
        page.drawText(fit(bold, 7.5, a.event, 95), { x: L + 118, y, size: 7.5, font: bold, color: INK });
        page.drawText(fit(font, 7.5, a.actor || '', 90), { x: L + 218, y, size: 7.5, font, color: INK });
        lines.forEach((l, i) => page.drawText(l, { x: L + 312, y: y - i * 10, size: 7.5, font, color: INK }));
        y -= 10 * Math.max(1, lines.length) + 3;
    }
    y -= 10;
    need(60);
    rule(); y -= 16;
    for (const l of wrap(font, 8, 'This PDF is sealed with a digital signature (' + meta.sealName + '). ' +
        'Any change to the file after sealing invalidates the seal. Check it in a PDF reader\'s signature panel, ' +
        'or upload the file on the Verify page of ' + meta.org + '.', R - L)) {
        text(l, L, 8, font, MUTED); y -= 11;
    }

    // 4. Invisible signature field whose value is the seal
    const sigDict = doc.context.obj({
        Type: 'Sig',
        Filter: 'Adobe.PPKLite',
        SubFilter: 'adbe.pkcs7.detached',
        ByteRange: [PDFNumber.of(0), PDFName.of('**********'), PDFName.of('**********'), PDFName.of('**********')],
        Contents: PDFHexString.of('0'.repeat(SIG_BYTES * 2)),
        Reason: PDFString.of(safeText(font, 'Completed envelope ' + meta.envelopeId)),
        Name: PDFString.of(safeText(font, meta.sealName)),
        Location: PDFString.of(safeText(font, meta.org)),
        M: PDFString.fromDate(new Date())
    });
    const sigRef = doc.context.register(sigDict);
    const widget = doc.context.obj({
        Type: 'Annot', Subtype: 'Widget', FT: 'Sig', Rect: [0, 0, 0, 0], F: 132,
        T: PDFString.of('ESignSeal'), V: sigRef, P: page.ref
    });
    const widgetRef = doc.context.register(widget);
    page.node.set(PDFName.of('Annots'), doc.context.obj([widgetRef]));
    doc.catalog.set(PDFName.of('AcroForm'), doc.context.obj({ SigFields: 3, Fields: [widgetRef] }));

    doc.setTitle(safeText(font, meta.title));
    doc.setProducer(safeText(font, meta.org + ' (Oracle APEX + pdf-lib)'));
    doc.setModificationDate(new Date());
    const bytes = await doc.save({ ...NO_TICKS, useObjectStreams: false });
    return toBlob(bytes);
}
/

create or replace package esign_pdf authid definer as
    -- {"ok":true,"pages":n} or {"ok":false,"error":"..."}
    function inspect(p_pdf in blob) return varchar2
        as mle module esign_pdf_js env esign_pdf_env signature 'inspect(OracleBlob)';
    -- stamped PDF with certificate pages and an empty signature field
    function stamp(p_pdf in blob, p_meta in clob) return blob
        as mle module esign_pdf_js env esign_pdf_env signature 'stamp(OracleBlob, string)';
    -- RSA signature with SHA-256 of p_data; p_key_b64 = base64 of an unencrypted PKCS#8 private key
    function sign_rsa(p_data in raw, p_key_b64 in varchar2) return raw;
end esign_pdf;
/

create or replace package body esign_pdf as
    function sign_rsa(p_data in raw, p_key_b64 in varchar2) return raw is
    begin
        return dbms_crypto.sign(
            src        => p_data,
            prv_key    => utl_raw.cast_to_raw(p_key_b64),
            pubkey_alg => dbms_crypto.key_type_rsa,
            sign_alg   => dbms_crypto.sign_sha256_rsa);
    end sign_rsa;
end esign_pdf;
/
