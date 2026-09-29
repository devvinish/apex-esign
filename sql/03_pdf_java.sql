-- ESign Lab: the PDF engine for Oracle Database 19c (no MLE), in the database's Java (Java 8 or later).
-- Use it instead of 02_pdf_lib.sql and 03_pdf_mle.sql. It needs no libraries: it uses only core Java,
-- because the database's Java has no AWT, which PDF libraries such as PDFBox need.
-- Run this script connected as your schema (CREATE PROCEDURE covers Java sources).
set define off sqlblanklines on

create or replace and compile java source named "ESignPdf" as
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.Reader;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.sql.Blob;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.DriverManager;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Date;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;
import java.util.TreeMap;
import java.util.zip.Deflater;
import java.util.zip.Inflater;

/*
 * ESign Lab: the PDF engine for databases without MLE (Oracle Database 19c), in the database's Java.
 * It does what the JavaScript module ESIGN_PDF_JS does with pdf-lib: checks an uploaded PDF, stamps the
 * signatures, appends the certificate of completion, and adds an empty signature field that
 * ESIGN_PKG.SEAL_PDF fills with the PKCS#7 seal. It also signs with RSA (DBMS_CRYPTO.SIGN needs 21c).
 *
 * It uses only core Java 8 (no libraries: the database's Java has no AWT, which PDF libraries need), and
 * changes the PDF with an incremental update: the original bytes stay unchanged at the start of the file,
 * and the new and changed objects follow them, as when a PDF reader signs a document.
 */
public class ESignPdf {

    // ------------------------------------------------------------------ entry points (PL/SQL call specs)

    /** {"ok":true,"pages":n} or {"ok":false,"error":"..."} */
    public static String inspect(Blob pdf) {
        try {
            return inspectBytes(read(pdf));
        } catch (Exception e) {
            return "{\"ok\":false,\"error\":" + quote("The file could not be read (" + e + ").") + "}";
        }
    }

    static String inspectBytes(byte[] bytes) {
        try {
            Pdf p = new Pdf(bytes);
            if (p.trailer.containsKey("Encrypt")) {
                return "{\"ok\":false,\"error\":\"The PDF is password-protected or encrypted.\"}";
            }
            return "{\"ok\":true,\"pages\":" + p.pages().size() + "}";
        } catch (Exception e) {
            return "{\"ok\":false,\"error\":" + quote("The file is not a readable PDF (" + e + ").") + "}";
        }
    }

    /** RSA signature with SHA-256 (PKCS#1 v1.5); key = base64 of an unencrypted PKCS#8 private key. */
    public static byte[] signRsa(byte[] data, String keyB64) throws Exception {
        PrivateKey key = KeyFactory.getInstance("RSA")
            .generatePrivate(new PKCS8EncodedKeySpec(Base64.getMimeDecoder().decode(keyB64)));
        Signature s = Signature.getInstance("SHA256withRSA");
        s.initSign(key);
        s.update(data);
        return s.sign();
    }

    /** The stamped PDF with the certificate pages and an empty signature field. */
    public static Blob stamp(Blob pdf, Clob metaJson) throws Exception {
        return toBlob(stamp(read(pdf), readClob(metaJson)));
    }

    static byte[] stamp(byte[] pdf, String metaJson) throws Exception {
        Map<String, Object> meta = (Map<String, Object>) new Json(metaJson).value();
        Pdf p = new Pdf(pdf);
        if (p.trailer.containsKey("Encrypt")) throw new Exception("The PDF is encrypted.");
        new Stamper(p, meta).run();
        return p.save();
    }

    // ================================================================== PDF objects

    static final class Ref {
        final int num, gen;
        Ref(int num, int gen) { this.num = num; this.gen = gen; }
    }

    static final class Name {
        final String name;
        Name(String name) { this.name = name; }
    }

    static final class Str {
        final byte[] bytes;
        Str(byte[] bytes) { this.bytes = bytes; }
    }

    static final class Stream {
        final Map<String, Object> dict;
        byte[] raw;                       // encoded bytes, as stored in the file
        Stream(Map<String, Object> dict, byte[] raw) { this.dict = dict; this.raw = raw; }
    }

    /** Text written as is: the placeholders of the signature dictionary. */
    static final class Raw {
        final String text;
        Raw(String text) { this.text = text; }
    }

    static final Object NULL = new Object();

    static Map<String, Object> dict() { return new LinkedHashMap<>(); }

    static List<Object> arr(Object... items) {
        List<Object> l = new ArrayList<>();
        for (Object o : items) l.add(o);
        return l;
    }

    // ================================================================== reading and writing a PDF

    static final class Pdf {
        final byte[] data;
        final Map<String, Object> trailer = dict();
        final Map<Integer, long[]> xref = new HashMap<>();   // num -> {type, offset or objstm, gen or index}
        final Map<Integer, Object> cache = new HashMap<>();
        final Map<Integer, Object> changed = new TreeMap<>();
        int nextNum;
        long lastXref;
        boolean xrefStream;

        Pdf(byte[] data) throws Exception {
            this.data = data;
            try {
                lastXref = startxref();
                readXref(lastXref, true);
            } catch (Exception e) {
                rebuild();            // damaged cross-reference table: find the objects by scanning
            }
            if (!trailer.containsKey("Root")) throw new Exception("no document catalog");
            Object size = trailer.get("Size");
            nextNum = size instanceof Number ? ((Number) size).intValue() : 0;
            for (int n : xref.keySet()) nextNum = Math.max(nextNum, n + 1);
        }

        // ---------------------------------------------------------- cross-reference data

        private long startxref() throws Exception {
            int i = lastIndexOf("startxref");
            if (i < 0) throw new Exception("startxref not found");
            Lexer lx = new Lexer(data, i + 9);
            return ((Number) lx.object()).longValue();
        }

        private void readXref(long offset, boolean newest) throws Exception {
            Lexer lx = new Lexer(data, (int) offset);
            lx.skipSpace();
            if (lx.startsWith("xref")) {
                lx.pos += 4;
                while (true) {
                    lx.skipSpace();
                    if (lx.startsWith("trailer")) { lx.pos += 7; break; }
                    int start = ((Number) lx.object()).intValue();
                    int count = ((Number) lx.object()).intValue();
                    for (int k = 0; k < count; k++) {
                        long off = ((Number) lx.object()).longValue();
                        int gen = ((Number) lx.object()).intValue();
                        lx.skipSpace();
                        char t = (char) data[lx.pos++];
                        if (!xref.containsKey(start + k)) {
                            xref.put(start + k, t == 'n' ? new long[] {1, off, gen} : new long[] {0, 0, 0});
                        }
                    }
                }
                Map<String, Object> t = (Map<String, Object>) lx.object();
                if (newest) xrefStream = false;
                mergeTrailer(t);
                if (t.get("XRefStm") instanceof Number) readXref(((Number) t.get("XRefStm")).longValue(), false);
                if (t.get("Prev") instanceof Number) readXref(((Number) t.get("Prev")).longValue(), false);
            } else {
                Lexer ol = new Lexer(data, (int) offset);
                Object o = ol.indirect(this);
                if (!(o instanceof Stream)) throw new Exception("no cross-reference data at " + offset);
                Stream s = (Stream) o;
                if (newest) xrefStream = true;
                byte[] d = decode(s);
                List<?> w = (List<?>) s.dict.get("W");
                int w0 = num(w.get(0)), w1 = num(w.get(1)), w2 = num(w.get(2));
                List<?> index = s.dict.get("Index") instanceof List ? (List<?>) s.dict.get("Index")
                                                                    : arr(0, num(s.dict.get("Size")));
                int p = 0;
                for (int k = 0; k + 1 < index.size(); k += 2) {
                    int start = num(index.get(k)), count = num(index.get(k + 1));
                    for (int j = 0; j < count; j++) {
                        long type = w0 == 0 ? 1 : field(d, p, w0);
                        long f2 = field(d, p + w0, w1), f3 = field(d, p + w0 + w1, w2);
                        p += w0 + w1 + w2;
                        if (!xref.containsKey(start + j)) xref.put(start + j, new long[] {type, f2, f3});
                    }
                }
                mergeTrailer(s.dict);
                if (s.dict.get("Prev") instanceof Number) readXref(((Number) s.dict.get("Prev")).longValue(), false);
            }
        }

        private void mergeTrailer(Map<String, Object> t) {
            for (String k : new String[] {"Root", "Info", "ID", "Size", "Encrypt"}) {
                if (t.containsKey(k) && !trailer.containsKey(k)) trailer.put(k, t.get(k));
            }
        }

        private void rebuild() throws Exception {
            xref.clear();
            trailer.clear();
            lastXref = -1;
            for (int i = 0; i < data.length - 4; i++) {
                if (data[i] == 'o' && data[i + 1] == 'b' && data[i + 2] == 'j' && (i == 0 || isSpace(data[i - 1]))) {
                    int j = i - 1;
                    while (j > 0 && isSpace(data[j])) j--;
                    int ge = j;
                    while (j > 0 && isDigit(data[j])) j--;
                    int gs = j + 1;
                    while (j > 0 && isSpace(data[j])) j--;
                    int ne = j;
                    while (j >= 0 && isDigit(data[j])) j--;
                    int ns = j + 1;
                    if (gs > ge || ns > ne) continue;
                    int num = Integer.parseInt(new String(data, ns, ne - ns + 1, "ISO-8859-1"));
                    int gen = Integer.parseInt(new String(data, gs, ge - gs + 1, "ISO-8859-1"));
                    xref.put(num, new long[] {1, ns, gen});
                }
            }
            for (int num : xref.keySet()) {
                try {
                    Object o = get(new Ref(num, 0));
                    if (o instanceof Map && isName(((Map<?, ?>) o).get("Type"), "Catalog")) trailer.put("Root", new Ref(num, 0));
                } catch (Exception e) { /* skip damaged objects */ }
            }
            xrefStream = false;
        }

        // ---------------------------------------------------------- objects

        Object get(Ref r) throws Exception {
            if (changed.containsKey(r.num)) return changed.get(r.num);
            if (cache.containsKey(r.num)) return cache.get(r.num);
            long[] e = xref.get(r.num);
            Object o = NULL;
            if (e != null && e[0] == 1) {
                o = new Lexer(data, (int) e[1]).indirect(this);
            } else if (e != null && e[0] == 2) {
                Stream os = (Stream) get(new Ref((int) e[1], 0));
                byte[] d = decode(os);
                int n = num(os.dict.get("N")), first = num(os.dict.get("First"));
                Lexer hl = new Lexer(d, 0);
                for (int k = 0; k < n; k++) {
                    int on = ((Number) hl.object()).intValue();
                    int off = ((Number) hl.object()).intValue();
                    if (on == r.num) { o = new Lexer(d, first + off).object(); break; }
                }
            }
            cache.put(r.num, o);
            return o;
        }

        Object resolve(Object o) throws Exception { return o instanceof Ref ? get((Ref) o) : o; }

        Map<String, Object> dictOf(Object o) throws Exception {
            Object v = resolve(o);
            return v instanceof Map ? (Map<String, Object>) v : v instanceof Stream ? ((Stream) v).dict : null;
        }

        Ref add(Object o) { Ref r = new Ref(nextNum++, 0); changed.put(r.num, o); return r; }

        void update(Ref r, Object o) { changed.put(r.num, o); }

        /** Page references in document order, with their inherited attributes. */
        List<Page> pages() throws Exception {
            List<Page> out = new ArrayList<>();
            Map<String, Object> root = dictOf(trailer.get("Root"));
            walk(root.get("Pages"), new HashMap<String, Object>(), out, 0);
            return out;
        }

        private void walk(Object node, Map<String, Object> inherited, List<Page> out, int depth) throws Exception {
            if (depth > 64) throw new Exception("page tree too deep");
            Map<String, Object> d = dictOf(node);
            if (d == null) return;
            Map<String, Object> inh = new HashMap<>(inherited);
            for (String k : new String[] {"Resources", "MediaBox", "CropBox", "Rotate"}) if (d.containsKey(k)) inh.put(k, d.get(k));
            if (isName(d.get("Type"), "Pages") || d.containsKey("Kids")) {
                for (Object kid : (List<?>) resolve(d.get("Kids"))) walk(kid, inh, out, depth + 1);
            } else {
                out.add(new Page((Ref) node, d, inh));
            }
        }

        // ---------------------------------------------------------- saving (incremental update)

        byte[] save() throws Exception {
            ByteArrayOutputStream out = new ByteArrayOutputStream(data.length + 65536);
            out.write(data);
            if (data[data.length - 1] != '\n') out.write('\n');
            Map<Integer, Long> offsets = new TreeMap<>();
            for (Map.Entry<Integer, Object> e : changed.entrySet()) {
                long[] x = xref.get(e.getKey());
                int gen = x != null && x[0] == 1 ? (int) x[2] : 0;
                offsets.put(e.getKey(), (long) out.size());
                write(out, e.getKey() + " " + gen + " obj\n");
                writeObject(out, e.getValue());
                write(out, "\nendobj\n");
            }
            Map<String, Object> t = dict();
            t.put("Size", nextNum);
            t.put("Root", trailer.get("Root"));
            if (trailer.containsKey("Info")) t.put("Info", trailer.get("Info"));
            if (trailer.containsKey("ID")) t.put("ID", trailer.get("ID"));
            if (lastXref >= 0) t.put("Prev", lastXref);
            long xrefAt;
            if (xrefStream) {
                // cross-reference stream, as the original uses them: /W [1 4 2], not compressed
                int self = nextNum++;
                t.put("Size", nextNum);
                xrefAt = out.size();
                offsets.put(self, xrefAt);
                ByteArrayOutputStream d = new ByteArrayOutputStream();
                List<Object> index = new ArrayList<>();
                for (Map.Entry<Integer, Long> e : offsets.entrySet()) {
                    index.add(e.getKey());
                    index.add(1);
                    long[] x = xref.get(e.getKey());
                    int gen = x != null && x[0] == 1 ? (int) x[2] : 0;
                    d.write(1);
                    long off = e.getValue();
                    d.write((int) (off >>> 24)); d.write((int) (off >>> 16)); d.write((int) (off >>> 8)); d.write((int) off);
                    d.write(gen >>> 8); d.write(gen);
                }
                t.put("Type", new Name("XRef"));
                t.put("W", arr(1, 4, 2));
                t.put("Index", index);
                write(out, self + " 0 obj\n");
                writeObject(out, new Stream(t, d.toByteArray()));
                write(out, "\nendobj\n");
            } else {
                xrefAt = out.size();
                write(out, "xref\n");
                for (Map.Entry<Integer, Long> e : offsets.entrySet()) {
                    long[] x = xref.get(e.getKey());
                    int gen = x != null && x[0] == 1 ? (int) x[2] : 0;
                    write(out, e.getKey() + " 1\n");
                    write(out, String.format("%010d %05d n\r\n", e.getValue(), gen));
                }
                write(out, "trailer\n");
                writeObject(out, t);
                write(out, "\n");
            }
            write(out, "startxref\n" + xrefAt + "\n%%EOF\n");
            return out.toByteArray();
        }

        private int lastIndexOf(String s) {
            byte[] b = s.getBytes();
            outer:
            for (int i = data.length - b.length; i >= 0; i--) {
                for (int j = 0; j < b.length; j++) if (data[i + j] != b[j]) continue outer;
                return i;
            }
            return -1;
        }
    }

    static final class Page {
        final Ref ref;
        final Map<String, Object> dict;
        final Map<String, Object> inherited;
        Page(Ref ref, Map<String, Object> dict, Map<String, Object> inherited) { this.ref = ref; this.dict = dict; this.inherited = inherited; }
    }

    // ------------------------------------------------------------------ lexer and parser

    static final class Lexer {
        final byte[] d;
        int pos;
        Lexer(byte[] d, int pos) { this.d = d; this.pos = pos; }

        boolean startsWith(String s) {
            if (pos + s.length() > d.length) return false;
            for (int i = 0; i < s.length(); i++) if (d[pos + i] != s.charAt(i)) return false;
            return true;
        }

        void skipSpace() {
            while (pos < d.length) {
                if (isSpace(d[pos])) pos++;
                else if (d[pos] == '%') { while (pos < d.length && d[pos] != '\n' && d[pos] != '\r') pos++; }
                else break;
            }
        }

        /** "n g obj ... endobj" at the current position, with its stream if it has one. */
        Object indirect(Pdf pdf) throws Exception {
            object(); object();
            skipSpace();
            if (!startsWith("obj")) throw new Exception("obj expected at " + pos);
            pos += 3;
            Object o = object();
            skipSpace();
            if (o instanceof Map && startsWith("stream")) {
                pos += 6;
                if (d[pos] == '\r') pos++;
                if (d[pos] == '\n') pos++;
                Map<String, Object> sd = (Map<String, Object>) o;
                int len = -1;
                try { len = num(pdf == null ? sd.get("Length") : pdf.resolve(sd.get("Length"))); } catch (Exception e) { len = -1; }
                if (len < 0 || pos + len > d.length || !endstreamAt(pos + len)) {
                    int e = indexOf("endstream", pos);
                    len = e - pos;
                    while (len > 0 && (d[pos + len - 1] == '\n' || d[pos + len - 1] == '\r')) len--;
                }
                byte[] raw = new byte[len];
                System.arraycopy(d, pos, raw, 0, len);
                return new Stream(sd, raw);
            }
            return o;
        }

        private boolean endstreamAt(int p) {
            Lexer l = new Lexer(d, p);
            l.skipSpace();
            return l.startsWith("endstream");
        }

        private int indexOf(String s, int from) {
            outer:
            for (int i = from; i <= d.length - s.length(); i++) {
                for (int j = 0; j < s.length(); j++) if (d[i + j] != s.charAt(j)) continue outer;
                return i;
            }
            return d.length;
        }

        Object object() throws Exception {
            skipSpace();
            byte c = d[pos];
            if (c == '<' && d[pos + 1] == '<') {
                pos += 2;
                Map<String, Object> m = dict();
                while (true) {
                    skipSpace();
                    if (d[pos] == '>' && d[pos + 1] == '>') { pos += 2; return m; }
                    Object k = object();
                    Object v = object();
                    if (k instanceof Name) m.put(((Name) k).name, v);
                }
            }
            if (c == '[') {
                pos++;
                List<Object> l = new ArrayList<>();
                while (true) {
                    skipSpace();
                    if (d[pos] == ']') { pos++; return l; }
                    l.add(object());
                }
            }
            if (c == '/') {
                pos++;
                StringBuilder b = new StringBuilder();
                while (pos < d.length && !isSpace(d[pos]) && !isDelimiter(d[pos])) {
                    if (d[pos] == '#' && pos + 2 < d.length) {
                        b.append((char) Integer.parseInt(new String(d, pos + 1, 2, "ISO-8859-1"), 16));
                        pos += 3;
                    } else b.append((char) (d[pos++] & 0xff));
                }
                return new Name(b.toString());
            }
            if (c == '(') {
                pos++;
                ByteArrayOutputStream b = new ByteArrayOutputStream();
                int depth = 1;
                while (true) {
                    byte ch = d[pos++];
                    if (ch == '\\') {
                        byte e = d[pos++];
                        switch (e) {
                            case 'n': b.write('\n'); break;
                            case 'r': b.write('\r'); break;
                            case 't': b.write('\t'); break;
                            case 'b': b.write('\b'); break;
                            case 'f': b.write('\f'); break;
                            case '\r': if (d[pos] == '\n') pos++; break;
                            case '\n': break;
                            default:
                                if (e >= '0' && e <= '7') {
                                    int v = e - '0';
                                    for (int k = 0; k < 2 && d[pos] >= '0' && d[pos] <= '7'; k++) v = v * 8 + (d[pos++] - '0');
                                    b.write(v);
                                } else b.write(e);
                        }
                    } else if (ch == '(') { depth++; b.write(ch); }
                    else if (ch == ')') { if (--depth == 0) break; b.write(ch); }
                    else b.write(ch);
                }
                return new Str(b.toByteArray());
            }
            if (c == '<') {
                pos++;
                StringBuilder h = new StringBuilder();
                while (d[pos] != '>') { if (!isSpace(d[pos])) h.append((char) d[pos]); pos++; }
                pos++;
                if (h.length() % 2 == 1) h.append('0');
                byte[] b = new byte[h.length() / 2];
                for (int i = 0; i < b.length; i++) b[i] = (byte) Integer.parseInt(h.substring(2 * i, 2 * i + 2), 16);
                return new Str(b);
            }
            if (c == '+' || c == '-' || c == '.' || isDigit(c)) {
                int start = pos;
                while (pos < d.length && (isDigit(d[pos]) || d[pos] == '.' || d[pos] == '-' || d[pos] == '+')) pos++;
                String n = new String(d, start, pos - start, "ISO-8859-1");
                if (n.indexOf('.') < 0) {
                    // "n g R" is a reference
                    int save = pos;
                    Lexer l = new Lexer(d, pos);
                    l.skipSpace();
                    if (l.pos < d.length && isDigit(d[l.pos])) {
                        int gs = l.pos;
                        while (l.pos < d.length && isDigit(d[l.pos])) l.pos++;
                        int ge = l.pos;
                        l.skipSpace();
                        if (l.pos < d.length && d[l.pos] == 'R' && (l.pos + 1 >= d.length || isSpace(d[l.pos + 1]) || isDelimiter(d[l.pos + 1]))) {
                            pos = l.pos + 1;
                            return new Ref(Integer.parseInt(n), Integer.parseInt(new String(d, gs, ge - gs, "ISO-8859-1")));
                        }
                    }
                    pos = save;
                    try { return Long.parseLong(n); } catch (NumberFormatException e) { return 0L; }
                }
                try { return Double.parseDouble(n); } catch (NumberFormatException e) { return 0.0; }
            }
            if (startsWith("true")) { pos += 4; return Boolean.TRUE; }
            if (startsWith("false")) { pos += 5; return Boolean.FALSE; }
            if (startsWith("null")) { pos += 4; return NULL; }
            throw new Exception("unexpected byte " + (char) c + " at " + pos);
        }
    }

    // ------------------------------------------------------------------ serializer

    static void writeObject(ByteArrayOutputStream out, Object o) throws Exception {
        if (o instanceof Stream) {
            Stream s = (Stream) o;
            s.dict.put("Length", s.raw.length);
            writeObject(out, s.dict);
            write(out, "\nstream\n");
            out.write(s.raw);
            write(out, "\nendstream");
        } else if (o instanceof Map) {
            write(out, "<<");
            for (Map.Entry<?, ?> e : ((Map<?, ?>) o).entrySet()) {
                write(out, "/" + nameText((String) e.getKey()) + " ");
                writeObject(out, e.getValue());
                write(out, " ");
            }
            write(out, ">>");
        } else if (o instanceof List) {
            write(out, "[");
            boolean first = true;
            for (Object x : (List<?>) o) { if (!first) write(out, " "); writeObject(out, x); first = false; }
            write(out, "]");
        } else if (o instanceof Name) {
            write(out, "/" + nameText(((Name) o).name));
        } else if (o instanceof Str) {
            StringBuilder b = new StringBuilder("<");
            for (byte x : ((Str) o).bytes) b.append(String.format("%02X", x & 0xff));
            write(out, b.append('>').toString());
        } else if (o instanceof Ref) {
            write(out, ((Ref) o).num + " " + ((Ref) o).gen + " R");
        } else if (o instanceof Raw) {
            write(out, ((Raw) o).text);
        } else if (o instanceof Boolean) {
            write(out, o.toString());
        } else if (o instanceof Double || o instanceof Float) {
            write(out, fmt(((Number) o).doubleValue()));
        } else if (o instanceof Number) {
            write(out, String.valueOf(((Number) o).longValue()));
        } else {
            write(out, "null");
        }
    }

    static String nameText(String n) {
        StringBuilder b = new StringBuilder();
        for (char c : n.toCharArray()) {
            if (c < 0x21 || c > 0x7e || c == '#' || isDelimiter((byte) c)) b.append(String.format("#%02X", (int) c & 0xff));
            else b.append(c);
        }
        return b.toString();
    }

    // ================================================================== stamps and certificate

    static final double[] INK = {0.13, 0.16, 0.22};
    static final double[] MUTED = {0.42, 0.45, 0.5};
    static final double[] LINE = {0.82, 0.85, 0.9};
    static final double[] ACCENT = {0.11, 0.35, 0.72};
    static final int SIG_BYTES = 8192;           // room for the PKCS#7 signature

    static final class Stamper {
        final Pdf pdf;
        final Map<String, Object> meta;
        final Ref helv, helvBold;
        final Map<String, Img> images = new HashMap<>();
        final List<Ref> newPages = new ArrayList<>();
        Content cs;
        Map<String, Object> curXObjects;
        double y;
        static final double W = 612, H = 792, L = 50, R = W - 50;

        Stamper(Pdf pdf, Map<String, Object> meta) {
            this.pdf = pdf;
            this.meta = meta;
            helv = pdf.add(font("Helvetica"));
            helvBold = pdf.add(font("Helvetica-Bold"));
        }

        private static Map<String, Object> font(String base) {
            Map<String, Object> f = dict();
            f.put("Type", new Name("Font"));
            f.put("Subtype", new Name("Type1"));
            f.put("BaseFont", new Name(base));
            f.put("Encoding", new Name("WinAnsiEncoding"));
            return f;
        }

        void run() throws Exception {
            String org = str(meta.get("org"));
            String envelope = str(meta.get("envelopeId"));
            List<Page> pages = pdf.pages();
            List<Object> signers = list(meta.get("signers"));
            for (Object o : signers) {
                Map<String, Object> s = map(o);
                if (s.get("png") != null) {
                    images.put(str(s.get("signerId")), Img.fromPng(pdf, Base64.getMimeDecoder().decode(str(s.get("png")))));
                }
            }

            // 1. envelope ID on every page, 2. signature stamps where the sender asked for them
            Map<String, Integer> slots = new HashMap<>();
            for (int pi = 0; pi < pages.size(); pi++) {
                Page page = pages.get(pi);
                double[] box = box(page);
                Content c = new Content();
                Map<String, Object> xobj = dict();
                c.text(false, 7, MUTED, box[0] + 18, box[3] - 14, org + " Envelope ID: " + envelope);
                for (Object o : signers) {
                    Map<String, Object> s = map(o);
                    Img img = images.get(str(s.get("signerId")));
                    String stampPage = str(s.get("stampPage")), pos = str(s.get("stampPosition"));
                    int index = "FIRST".equals(stampPage) ? 0 : pages.size() - 1;
                    if ("NONE".equals(stampPage) || img == null || index != pi) continue;
                    double w = 180, h = 64, m = 30;
                    String key = index + pos;
                    int n = slots.containsKey(key) ? slots.get(key) + 1 : 1;   // two signers in one slot: stack them
                    slots.put(key, n);
                    boolean top = pos.startsWith("TOP");
                    double x = box[0] + m;
                    if (pos.endsWith("RIGHT")) x = box[2] - w - m;
                    if (pos.endsWith("CENTER")) x = box[0] + (box[2] - box[0] - w) / 2;
                    double yy = top ? box[3] - m - 12 - n * (h + 8) : box[1] + m + (n - 1) * (h + 8);
                    c.fillRect(x, yy, w, h, new double[] {1, 1, 1});
                    c.strokeRect(x, yy, w, h, ACCENT, 0.8);
                    c.text(true, 6.5, ACCENT, x + 6, yy + h - 11, "Signed by:");
                    double scale = Math.min((w - 12) / img.w, 30.0 / img.h);
                    String nm = "ESImg" + str(s.get("signerId"));
                    xobj.put(nm, img.ref);
                    c.image(nm, x + 6, yy + 17, img.w * scale, img.h * scale);
                    c.text(false, 6.5, INK, x + 6, yy + 9, fit(false, 6.5, str(s.get("name")), w - 12));
                    c.text(false, 5.5, MUTED, x + 6, yy + 2.5, fit(false, 5.5, str(s.get("signedOn")) + "  " + str(s.get("signatureId")), w - 12));
                }
                appendContent(page, c, xobj);
            }

            // 3. certificate of completion
            newPage();
            cs.text(true, 20, INK, L, y, "Certificate of Completion");
            y -= 18;
            cs.text(false, 10, MUTED, L, y, org + " electronic signature record");
            y -= 26;
            row("Document", str(meta.get("title")));
            row("Envelope ID", envelope);
            row("File", str(meta.get("fileName")));
            row("Pages", str(meta.get("pages")) + " + certificate");
            row("Sent by", str(meta.get("sender")));
            row("Sent", str(meta.get("sentOn")));
            row("Completed", str(meta.get("completedOn")));
            row("Routing", "SEQUENTIAL".equals(str(meta.get("routing"))) ? "Sequential (in signing order)" : "Parallel");
            row("Original SHA-256", str(meta.get("originalSha256")));
            y -= 8; rule(); y -= 22;

            cs.text(true, 13, INK, L, y, "Signers");
            y -= 20;
            for (Object o : signers) {
                Map<String, Object> s = map(o);
                need(120);
                double top = y;
                cs.text(true, 10.5, INK, L, y, fit(true, 10.5, str(s.get("name")), 260));
                y -= 13;
                cs.text(false, 9, MUTED, L, y, fit(false, 9, str(s.get("email")), 260));
                y -= 16;
                String[][] facts = {
                    {"Status", str(s.get("status"))},
                    {"Signed", or(s.get("signedOn"))},
                    {"Signature ID", or(s.get("signatureId"))},
                    {"Signature", "TYPED".equals(str(s.get("method"))) ? "Typed and adopted" : "Drawn"},
                    {"Authentication", "E-mail link + one-time code (" + or(s.get("otpVerifiedOn")) + ")"},
                    {"Consent", s.get("consentOn") != null ? "Accepted " + str(s.get("consentOn")) : "-"},
                    {"IP address", or(s.get("ip"))},
                    {"Document SHA-256", or(s.get("docSha256"))}};
                for (String[] f : facts) {
                    cs.text(false, 7.5, MUTED, L, y, f[0]);
                    cs.text(false, 7.5, INK, L + 72, y, fit(false, 7.5, f[1], 225));
                    y -= 10.5;
                }
                Img img = images.get(str(s.get("signerId")));
                if (img != null) {
                    double scale = Math.min(200.0 / img.w, 60.0 / img.h);
                    cs.strokeRect(350, top - 70, 212, 72, LINE, 0.8);
                    String nm = "ESImg" + str(s.get("signerId"));
                    curXObjects.put(nm, img.ref);
                    cs.image(nm, 356, top - 64, img.w * scale, img.h * scale);
                }
                if (s.get("declineReason") != null) {
                    cs.text(false, 8, new double[] {0.7, 0.1, 0.1}, L, y, fit(false, 8, "Declined: " + str(s.get("declineReason")), R - L));
                    y -= 11;
                }
                y -= 10; rule(); y -= 18;
            }

            need(60);
            cs.text(true, 13, INK, L, y, "Audit trail");
            y -= 18;
            for (Object o : list(meta.get("audit"))) {
                Map<String, Object> a = map(o);
                List<String> lines = wrap(false, 7.5, str(a.get("details")), R - (L + 312));
                need(10 * Math.max(1, lines.size()) + 4);
                cs.text(false, 7.5, MUTED, L, y, str(a.get("time")));
                cs.text(true, 7.5, INK, L + 118, y, fit(true, 7.5, str(a.get("event")), 95));
                cs.text(false, 7.5, INK, L + 218, y, fit(false, 7.5, str(a.get("actor")), 90));
                for (int i = 0; i < lines.size(); i++) cs.text(false, 7.5, INK, L + 312, y - i * 10, lines.get(i));
                y -= 10 * Math.max(1, lines.size()) + 3;
            }
            y -= 10;
            need(60);
            rule(); y -= 16;
            for (String l : wrap(false, 8, "This PDF is sealed with a digital signature (" + str(meta.get("sealName")) + "). "
                    + "Any change to the file after sealing invalidates the seal. Check it in a PDF reader's signature panel, "
                    + "or upload the file on the Verify page of " + org + ".", R - L)) {
                cs.text(false, 8, MUTED, L, y, l);
                y -= 11;
            }
            finishPage();
            addPagesAndSignature(pages);
        }

        // ---------------------------------------------------------- page building

        private final List<Object[]> certPages = new ArrayList<>();   // {Content, xobjects}

        private void newPage() {
            if (cs != null) finishPage();
            cs = new Content();
            curXObjects = dict();
            cs.fillRect(0, H - 6, W, 6, ACCENT);
            String org = str(meta.get("org"));
            cs.text(false, 7, MUTED, L, 24, org + " Envelope ID: " + str(meta.get("envelopeId")));
            cs.text(false, 7, MUTED, R - width(false, 7, "Certificate of Completion"), 24, "Certificate of Completion");
            y = H - 50;
        }

        private void finishPage() { certPages.add(new Object[] {cs, curXObjects}); cs = null; }

        private void need(double h) { if (y - h < 50) newPage(); }

        private void rule() { cs.line(L, y, R, y, LINE, 0.6); }

        private void row(String label, String value) {
            List<String> lines = wrap(false, 9, value, R - L - 130);
            need(12 * lines.size() + 2);
            cs.text(true, 9, MUTED, L, y, label);
            for (int i = 0; i < lines.size(); i++) cs.text(false, 9, INK, L + 130, y - i * 12, lines.get(i));
            y -= 12 * lines.size() + 2;
        }

        private Map<String, Object> resources(Map<String, Object> xobjects) {
            Map<String, Object> fonts = dict();
            fonts.put("ESF1", helv);
            fonts.put("ESF2", helvBold);
            Map<String, Object> res = dict();
            res.put("Font", fonts);
            if (!xobjects.isEmpty()) res.put("XObject", xobjects);
            return res;
        }

        /** Adds a content stream to an existing page; the original content is wrapped in q ... Q. */
        private void appendContent(Page page, Content c, Map<String, Object> xobjects) throws Exception {
            Map<String, Object> pd = new LinkedHashMap<>(page.dict);
            Ref before = pdf.add(new Stream(dict(), "q\n".getBytes("ISO-8859-1")));
            Ref after = pdf.add(c.stream("Q\n"));
            List<Object> contents = new ArrayList<>();
            contents.add(before);
            Object old = pd.get("Contents");
            Object oldResolved = pdf.resolve(old);
            if (oldResolved instanceof List) contents.addAll((List<?>) oldResolved);
            else if (old != null) contents.add(old);
            contents.add(after);
            pd.put("Contents", contents);
            // resources: the page's own or inherited ones, plus the fonts and images of the stamp
            Map<String, Object> res = new LinkedHashMap<>();
            Map<String, Object> orig = pdf.dictOf(page.inherited.get("Resources"));
            if (orig != null) res.putAll(orig);
            for (Map.Entry<String, Object> e : resources(xobjects).entrySet()) {
                Map<String, Object> merged = new LinkedHashMap<>();
                Map<String, Object> o = pdf.dictOf(res.get(e.getKey()));
                if (o != null) merged.putAll(o);
                Map<String, Object> add = (Map<String, Object>) e.getValue();
                merged.putAll(add);
                res.put(e.getKey(), merged);
            }
            pd.put("Resources", res);
            for (String k : new String[] {"MediaBox", "CropBox", "Rotate"}) {
                if (!pd.containsKey(k) && page.inherited.containsKey(k)) pd.put(k, page.inherited.get(k));
            }
            pdf.update(page.ref, pd);
        }

        /** Adds the certificate pages to the page tree, and the signature field to the last one. */
        private void addPagesAndSignature(List<Page> pages) throws Exception {
            Map<String, Object> root = new LinkedHashMap<>(pdf.dictOf(pdf.trailer.get("Root")));
            Ref pagesRef = (Ref) root.get("Pages");
            Map<String, Object> tree = new LinkedHashMap<>(pdf.dictOf(pagesRef));
            List<Object> kids = new ArrayList<>((List<?>) pdf.resolve(tree.get("Kids")));
            Ref last = null;
            for (Object[] cp : certPages) {
                Content c = (Content) cp[0];
                Map<String, Object> xo = (Map<String, Object>) cp[1];
                Map<String, Object> pg = dict();
                pg.put("Type", new Name("Page"));
                pg.put("Parent", pagesRef);
                pg.put("MediaBox", arr(0, 0, W, H));
                pg.put("Resources", resources(xo));
                pg.put("Contents", pdf.add(c.stream("")));
                last = pdf.add(pg);
                kids.add(last);
                newPages.add(last);
            }
            tree.put("Kids", kids);
            tree.put("Count", pages.size() + certPages.size());
            pdf.update(pagesRef, tree);

            // the signature: placeholders for /ByteRange and /Contents, filled by ESIGN_PKG.SEAL_PDF
            Map<String, Object> sig = dict();
            sig.put("Type", new Name("Sig"));
            sig.put("Filter", new Name("Adobe.PPKLite"));
            sig.put("SubFilter", new Name("adbe.pkcs7.detached"));
            sig.put("ByteRange", new Raw("[ 0 /********** /********** /********** ]"));
            sig.put("Contents", new Raw("<" + repeat('0', SIG_BYTES * 2) + ">"));
            sig.put("Reason", new Str(winAnsi("Completed envelope " + str(meta.get("envelopeId")))));
            sig.put("Name", new Str(winAnsi(str(meta.get("sealName")))));
            sig.put("Location", new Str(winAnsi(str(meta.get("org")))));
            SimpleDateFormat f = new SimpleDateFormat("yyyyMMddHHmmss");
            f.setTimeZone(TimeZone.getTimeZone("UTC"));
            sig.put("M", new Str(("D:" + f.format(new Date()) + "Z").getBytes("ISO-8859-1")));
            Ref sigRef = pdf.add(sig);
            Map<String, Object> widget = dict();
            widget.put("Type", new Name("Annot"));
            widget.put("Subtype", new Name("Widget"));
            widget.put("FT", new Name("Sig"));
            widget.put("Rect", arr(0, 0, 0, 0));
            widget.put("F", 132);
            widget.put("T", new Str("ESignSeal".getBytes("ISO-8859-1")));
            widget.put("V", sigRef);
            widget.put("P", last);
            Ref widgetRef = pdf.add(widget);
            Map<String, Object> lastPage = (Map<String, Object>) pdf.get(last);
            lastPage.put("Annots", arr(widgetRef));
            Map<String, Object> form = dict();
            Map<String, Object> oldForm = pdf.dictOf(root.get("AcroForm"));
            if (oldForm != null) form.putAll(oldForm);
            List<Object> fields = new ArrayList<>();
            if (form.get("Fields") != null) fields.addAll((List<?>) pdf.resolve(form.get("Fields")));
            fields.add(widgetRef);
            form.put("Fields", fields);
            form.put("SigFields", 3);
            root.put("AcroForm", form);
            pdf.update((Ref) pdf.trailer.get("Root"), root);
        }

        private double[] box(Page page) throws Exception {
            Object b = page.dict.containsKey("CropBox") ? page.dict.get("CropBox")
                     : page.inherited.containsKey("CropBox") ? page.inherited.get("CropBox")
                     : page.inherited.get("MediaBox");
            List<?> l = (List<?>) pdf.resolve(b);
            double[] r = new double[4];
            for (int i = 0; i < 4; i++) r[i] = ((Number) pdf.resolve(l.get(i))).doubleValue();
            return new double[] {Math.min(r[0], r[2]), Math.min(r[1], r[3]), Math.max(r[0], r[2]), Math.max(r[1], r[3])};
        }
    }

    // ------------------------------------------------------------------ content streams

    static final class Content {
        final StringBuilder b = new StringBuilder();

        void text(boolean bold, double size, double[] color, double x, double y, String s) {
            b.append("BT /").append(bold ? "ESF2 " : "ESF1 ").append(fmt(size)).append(" Tf ")
             .append(rgb(color)).append(" rg ").append(fmt(x)).append(' ').append(fmt(y)).append(" Td <");
            for (byte c : winAnsi(s)) b.append(String.format("%02X", c & 0xff));
            b.append("> Tj ET\n");
        }

        void fillRect(double x, double y, double w, double h, double[] color) {
            b.append(rgb(color)).append(" rg ").append(fmt(x)).append(' ').append(fmt(y)).append(' ')
             .append(fmt(w)).append(' ').append(fmt(h)).append(" re f\n");
        }

        void strokeRect(double x, double y, double w, double h, double[] color, double lw) {
            b.append(rgb(color)).append(" RG ").append(fmt(lw)).append(" w ").append(fmt(x)).append(' ').append(fmt(y))
             .append(' ').append(fmt(w)).append(' ').append(fmt(h)).append(" re S\n");
        }

        void line(double x1, double y1, double x2, double y2, double[] color, double lw) {
            b.append(rgb(color)).append(" RG ").append(fmt(lw)).append(" w ").append(fmt(x1)).append(' ').append(fmt(y1))
             .append(" m ").append(fmt(x2)).append(' ').append(fmt(y2)).append(" l S\n");
        }

        void image(String name, double x, double y, double w, double h) {
            b.append("q ").append(fmt(w)).append(" 0 0 ").append(fmt(h)).append(' ').append(fmt(x)).append(' ')
             .append(fmt(y)).append(" cm /").append(name).append(" Do Q\n");
        }

        Stream stream(String prefix) throws Exception {
            byte[] raw = deflate((prefix + b).getBytes("ISO-8859-1"));
            Map<String, Object> d = dict();
            d.put("Filter", new Name("FlateDecode"));
            return new Stream(d, raw);
        }

        private static String rgb(double[] c) { return fmt(c[0]) + " " + fmt(c[1]) + " " + fmt(c[2]); }
    }

    // ------------------------------------------------------------------ images (PNG from the signature pad)

    static final class Img {
        Ref ref;
        int w, h;

        /** An 8-bit PNG (RGB or RGBA, gray or gray+alpha) as an image XObject, alpha as a soft mask. */
        static Img fromPng(Pdf pdf, byte[] png) throws Exception {
            if ((png[0] & 0xff) != 0x89 || png[1] != 'P') throw new Exception("not a PNG");
            int pos = 8, width = 0, height = 0, depth = 0, type = 0, interlace = 0;
            ByteArrayOutputStream idat = new ByteArrayOutputStream();
            while (pos + 8 <= png.length) {
                int len = (int) field(png, pos, 4);
                String t = new String(png, pos + 4, 4, "ISO-8859-1");
                if (t.equals("IHDR")) {
                    width = (int) field(png, pos + 8, 4);
                    height = (int) field(png, pos + 12, 4);
                    depth = png[pos + 16] & 0xff;
                    type = png[pos + 17] & 0xff;
                    interlace = png[pos + 20] & 0xff;
                } else if (t.equals("IDAT")) {
                    idat.write(png, pos + 8, len);
                } else if (t.equals("IEND")) break;
                pos += 12 + len;
            }
            if (depth != 8 || interlace != 0 || (type != 0 && type != 2 && type != 4 && type != 6)) {
                throw new Exception("unsupported PNG (depth " + depth + ", type " + type + ")");
            }
            int channels = type == 6 ? 4 : type == 2 ? 3 : type == 4 ? 2 : 1;
            byte[] raw = inflate(idat.toByteArray());
            byte[] pix = unfilter(raw, width, height, channels);
            int colors = channels >= 3 ? 3 : 1;
            boolean alpha = channels == 2 || channels == 4;
            byte[] color = new byte[width * height * colors];
            byte[] mask = alpha ? new byte[width * height] : null;
            for (int i = 0, c = 0; i < width * height; i++) {
                for (int k = 0; k < colors; k++) color[c++] = pix[i * channels + k];
                if (alpha) mask[i] = pix[i * channels + channels - 1];
            }
            Map<String, Object> d = imageDict(width, height, colors == 3 ? "DeviceRGB" : "DeviceGray");
            if (alpha) d.put("SMask", pdf.add(new Stream(imageDict(width, height, "DeviceGray"), deflate(mask))));
            Img img = new Img();
            img.ref = pdf.add(new Stream(d, deflate(color)));
            img.w = width;
            img.h = height;
            return img;
        }

        private static Map<String, Object> imageDict(int w, int h, String cs) {
            Map<String, Object> d = dict();
            d.put("Type", new Name("XObject"));
            d.put("Subtype", new Name("Image"));
            d.put("Width", w);
            d.put("Height", h);
            d.put("ColorSpace", new Name(cs));
            d.put("BitsPerComponent", 8);
            d.put("Filter", new Name("FlateDecode"));
            return d;
        }
    }

    /** PNG row filters: None, Sub, Up, Average, Paeth. */
    static byte[] unfilter(byte[] raw, int width, int height, int bpp) throws Exception {
        int stride = width * bpp;
        byte[] out = new byte[stride * height];
        for (int row = 0; row < height; row++) {
            int f = raw[row * (stride + 1)] & 0xff;
            int in = row * (stride + 1) + 1, o = row * stride;
            for (int i = 0; i < stride; i++) {
                int x = raw[in + i] & 0xff;
                int a = i >= bpp ? out[o + i - bpp] & 0xff : 0;
                int b = row > 0 ? out[o - stride + i] & 0xff : 0;
                int c = row > 0 && i >= bpp ? out[o - stride + i - bpp] & 0xff : 0;
                int v;
                switch (f) {
                    case 0: v = x; break;
                    case 1: v = x + a; break;
                    case 2: v = x + b; break;
                    case 3: v = x + ((a + b) >> 1); break;
                    case 4: {
                        int p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
                        v = x + (pa <= pb && pa <= pc ? a : pb <= pc ? b : c);
                        break;
                    }
                    default: throw new Exception("bad PNG filter " + f);
                }
                out[o + i] = (byte) v;
            }
        }
        return out;
    }

    // ------------------------------------------------------------------ streams

    static byte[] decode(Stream s) throws Exception {
        Object f = s.dict.get("Filter");
        if (f instanceof List) f = ((List<?>) f).isEmpty() ? null : ((List<?>) f).get(0);
        byte[] d = s.raw;
        if (f instanceof Name && ((Name) f).name.equals("FlateDecode")) d = inflate(d);
        else if (f != null) throw new Exception("unsupported filter " + ((Name) f).name);
        Object dp = s.dict.get("DecodeParms");
        if (dp instanceof List) dp = ((List<?>) dp).isEmpty() ? null : ((List<?>) dp).get(0);
        if (dp instanceof Map) {
            Map<?, ?> p = (Map<?, ?>) dp;
            int predictor = p.get("Predictor") instanceof Number ? num(p.get("Predictor")) : 1;
            if (predictor >= 10) {
                int cols = p.get("Columns") instanceof Number ? num(p.get("Columns")) : 1;
                d = unfilter(d, cols, d.length / (cols + 1), 1);
            }
        }
        return d;
    }

    static byte[] inflate(byte[] in) throws Exception {
        Inflater inf = new Inflater();
        inf.setInput(in);
        ByteArrayOutputStream out = new ByteArrayOutputStream(in.length * 4);
        byte[] buf = new byte[65536];
        while (!inf.finished()) {
            int n = inf.inflate(buf);
            if (n == 0 && (inf.needsInput() || inf.needsDictionary())) break;
            out.write(buf, 0, n);
        }
        inf.end();
        return out.toByteArray();
    }

    static byte[] deflate(byte[] in) {
        Deflater def = new Deflater(Deflater.BEST_COMPRESSION);
        def.setInput(in);
        def.finish();
        ByteArrayOutputStream out = new ByteArrayOutputStream(in.length / 2 + 64);
        byte[] buf = new byte[65536];
        while (!def.finished()) out.write(buf, 0, def.deflate(buf));
        def.end();
        return out.toByteArray();
    }

    // ------------------------------------------------------------------ text: WinAnsi encoding and Helvetica widths

    private static final String CP1252_80 = "€�‚ƒ„…†‡ˆ‰Š‹Œ�Ž�"
                                           + "�‘’“”•–—˜™š›œ�žŸ";

    /** The standard fonts know only WinAnsi characters: others become '?', so no name breaks the PDF. */
    static byte[] winAnsi(String s) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        if (s == null) return new byte[0];
        for (int i = 0; i < s.length(); ) {
            int cp = s.codePointAt(i);
            i += Character.charCount(cp);
            if ((cp >= 0x20 && cp < 0x7f) || (cp >= 0xa0 && cp <= 0xff)) out.write(cp);
            else {
                int k = cp > 0xff ? CP1252_80.indexOf((char) cp) : -1;
                out.write(k >= 0 && cp != 0xFFFD ? 0x80 + k : '?');
            }
        }
        return out.toByteArray();
    }

    static String display(String s) {
        byte[] b = winAnsi(s);
        StringBuilder r = new StringBuilder();
        for (byte x : b) { int c = x & 0xff; r.append(c >= 0x80 && c < 0xa0 ? CP1252_80.charAt(c - 0x80) : (char) c); }
        return r.toString();
    }

    static double width(boolean bold, double size, String s) {
        int[] w = bold ? HELV_BOLD : HELV;
        double t = 0;
        for (byte c : winAnsi(s)) t += w[c & 0xff];
        return t / 1000.0 * size;
    }

    static String fit(boolean bold, double size, String s, double max) {
        String t = display(s);
        if (width(bold, size, t) <= max) return t;
        while (t.length() > 1 && width(bold, size, t + "...") > max) t = t.substring(0, t.length() - 1);
        return t + "...";
    }

    /** Word wrap; words wider than the line (hashes, URLs) are split into pieces that fit. */
    static List<String> wrap(boolean bold, double size, String s, double max) {
        List<String> words = new ArrayList<>();
        for (String w : display(s).split("\\s+")) {
            String rest = w;
            while (rest.length() > 1 && width(bold, size, rest) > max) {
                int n = rest.length() - 1;
                while (n > 1 && width(bold, size, rest.substring(0, n)) > max) n--;
                words.add(rest.substring(0, n));
                rest = rest.substring(n);
            }
            words.add(rest);
        }
        List<String> lines = new ArrayList<>();
        String line = "";
        for (String w : words) {
            String next = line.isEmpty() ? w : line + " " + w;
            if (width(bold, size, next) > max && !line.isEmpty()) { lines.add(line); line = w; } else line = next;
        }
        if (!line.isEmpty()) lines.add(line);
        return lines;
    }

    // Helvetica and Helvetica-Bold widths of the WinAnsi codes 0 to 255 (from the Adobe font metrics)
    static final int[] HELV = {250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,278,278,355,556,556,889,667,191,333,333,389,584,278,333,278,278,556,556,556,556,556,556,556,556,556,556,278,278,584,584,584,556,1015,667,667,722,722,667,611,778,722,278,500,667,556,833,722,778,667,778,722,667,611,722,667,944,667,667,611,278,278,278,469,556,333,556,556,500,556,556,278,556,556,222,222,500,222,833,556,556,556,556,333,500,278,556,500,722,500,500,500,334,260,334,584,350,556,350,222,556,333,1000,556,556,333,1000,667,333,1000,350,611,350,350,222,222,333,333,350,556,1000,333,1000,500,333,944,350,500,667,278,333,556,556,556,556,260,556,333,737,370,556,584,333,737,333,400,584,333,333,333,556,537,278,333,333,365,556,834,834,834,611,667,667,667,667,667,667,1000,722,667,667,667,667,278,278,278,278,722,722,778,778,778,778,778,584,778,722,722,722,722,667,667,611,556,556,556,556,556,556,889,500,556,556,556,556,278,278,278,278,556,556,556,556,556,556,556,584,611,556,556,556,556,500,556,500};
    static final int[] HELV_BOLD = {250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,278,333,474,556,556,889,722,238,333,333,389,584,278,333,278,278,556,556,556,556,556,556,556,556,556,556,333,333,584,584,584,611,975,722,722,722,722,667,611,778,722,278,556,722,611,833,722,778,667,778,722,667,611,722,667,944,667,667,611,333,278,333,584,556,333,556,611,556,611,556,333,611,611,278,278,556,278,889,611,611,611,611,389,556,333,611,556,778,556,556,500,389,280,389,584,350,556,350,278,556,500,1000,556,556,333,1000,667,333,1000,350,611,350,350,278,278,500,500,350,556,1000,333,1000,556,333,944,350,500,667,278,333,556,556,556,556,280,556,333,737,370,556,584,333,737,333,400,584,333,333,333,611,556,278,333,333,365,556,834,834,834,611,722,722,722,722,722,722,1000,722,667,667,667,667,278,278,278,278,722,722,778,778,778,778,778,584,778,722,722,722,722,667,667,611,556,556,556,556,556,556,889,556,556,556,556,556,278,278,278,278,611,611,611,611,611,611,611,584,611,611,611,611,611,556,611,556};

    // ------------------------------------------------------------------ small helpers

    static boolean isSpace(byte b) { return b == ' ' || b == '\n' || b == '\r' || b == '\t' || b == '\f' || b == 0; }
    static boolean isDigit(byte b) { return b >= '0' && b <= '9'; }
    static boolean isDelimiter(byte b) { return "()<>[]{}/%".indexOf(b) >= 0; }
    static boolean isName(Object o, String n) { return o instanceof Name && ((Name) o).name.equals(n); }
    static int num(Object o) { return ((Number) o).intValue(); }

    static long field(byte[] d, int p, int n) {
        long v = 0;
        for (int i = 0; i < n; i++) v = (v << 8) | (d[p + i] & 0xff);
        return v;
    }

    static String fmt(double v) {
        if (v == Math.rint(v)) return String.valueOf((long) v);
        String s = String.format(java.util.Locale.ROOT, "%.4f", v);
        return s.replaceAll("0+$", "").replaceAll("\\.$", "");
    }

    static String repeat(char c, int n) {
        char[] a = new char[n];
        java.util.Arrays.fill(a, c);
        return new String(a);
    }

    static void write(ByteArrayOutputStream out, String s) throws Exception { out.write(s.getBytes("ISO-8859-1")); }

    static byte[] read(Blob b) throws Exception {
        try (InputStream in = b.getBinaryStream()) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buf = new byte[65536];
            for (int n; (n = in.read(buf)) > 0; ) out.write(buf, 0, n);
            return out.toByteArray();
        }
    }

    static String readClob(Clob c) throws Exception {
        try (Reader r = c.getCharacterStream()) {
            StringBuilder b = new StringBuilder();
            char[] buf = new char[65536];
            for (int n; (n = r.read(buf)) > 0; ) b.append(buf, 0, n);
            return b.toString();
        }
    }

    static Blob toBlob(byte[] bytes) throws Exception {
        Connection conn = DriverManager.getConnection("jdbc:default:connection:");
        Blob b = conn.createBlob();
        b.setBytes(1, bytes);
        return b;
    }

    static String str(Object o) {
        if (o == null || o == NULL) return "";
        if (o instanceof Double && ((Double) o) % 1 == 0) return String.valueOf(((Double) o).longValue());
        return o.toString();
    }

    static String or(Object o) { return o == null || o == NULL ? "-" : str(o); }
    static Map<String, Object> map(Object o) { return (Map<String, Object>) o; }
    static List<Object> list(Object o) { return o instanceof List ? (List<Object>) o : new ArrayList<Object>(); }

    static String quote(String s) {
        StringBuilder b = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            if (c == '"' || c == '\\') b.append('\\').append(c);
            else if (c < 0x20) b.append(String.format("\\u%04x", (int) c));
            else b.append(c);
        }
        return b.append('"').toString();
    }

    // ------------------------------------------------------------------ JSON reader for the envelope data

    static final class Json {
        private final String s;
        private int i;
        Json(String s) { this.s = s; }
        Object value() {
            ws();
            char c = s.charAt(i);
            if (c == '{') {
                Map<String, Object> m = new LinkedHashMap<>();
                i++; ws();
                if (s.charAt(i) == '}') { i++; return m; }
                while (true) {
                    ws(); String k = (String) value(); ws(); i++;           // ':'
                    m.put(k, value()); ws();
                    if (s.charAt(i++) == '}') return m;                    // ',' or '}'
                }
            }
            if (c == '[') {
                List<Object> l = new ArrayList<>();
                i++; ws();
                if (s.charAt(i) == ']') { i++; return l; }
                while (true) {
                    l.add(value()); ws();
                    if (s.charAt(i++) == ']') return l;
                }
            }
            if (c == '"') {
                StringBuilder b = new StringBuilder();
                i++;
                while (true) {
                    char ch = s.charAt(i++);
                    if (ch == '"') return b.toString();
                    if (ch == '\\') {
                        char e = s.charAt(i++);
                        switch (e) {
                            case 'n': b.append('\n'); break;
                            case 't': b.append('\t'); break;
                            case 'r': b.append('\r'); break;
                            case 'b': b.append('\b'); break;
                            case 'f': b.append('\f'); break;
                            case 'u': b.append((char) Integer.parseInt(s.substring(i, i + 4), 16)); i += 4; break;
                            default: b.append(e);
                        }
                    } else b.append(ch);
                }
            }
            if (s.startsWith("true", i)) { i += 4; return Boolean.TRUE; }
            if (s.startsWith("false", i)) { i += 5; return Boolean.FALSE; }
            if (s.startsWith("null", i)) { i += 4; return null; }
            int start = i;
            while (i < s.length() && "+-0123456789.eE".indexOf(s.charAt(i)) >= 0) i++;
            return Double.valueOf(s.substring(start, i));
        }
        private void ws() { while (i < s.length() && Character.isWhitespace(s.charAt(i))) i++; }
    }
}
/

create or replace package esign_pdf authid definer as
    -- {"ok":true,"pages":n} or {"ok":false,"error":"..."}
    function inspect(p_pdf in blob) return varchar2
        as language java name 'ESignPdf.inspect(java.sql.Blob) return java.lang.String';
    -- stamped PDF with certificate pages and an empty signature field
    function stamp(p_pdf in blob, p_meta in clob) return blob
        as language java name 'ESignPdf.stamp(java.sql.Blob, java.sql.Clob) return java.sql.Blob';
    -- RSA signature with SHA-256 of p_data; p_key_b64 = base64 of an unencrypted PKCS#8 private key
    function sign_rsa(p_data in raw, p_key_b64 in varchar2) return raw
        as language java name 'ESignPdf.signRsa(byte[], java.lang.String) return byte[]';
end esign_pdf;
/
