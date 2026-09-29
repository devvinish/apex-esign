-- ESign Lab: business logic
set define off sqlblanklines on

create or replace package esign_pkg authid definer as

    c_consent constant varchar2(1000) :=
        'I agree to use electronic records and signatures for this document, and I intend my electronic '
        || 'signature to have the same legal effect as my handwritten signature.';

    function setting(p_name in varchar2) return varchar2;
    function sha256_hex(p_blob in blob) return varchar2;
    function sha256_hex(p_text in varchar2) return varchar2;
    -- 'YYYY-MM-DD HH24:MI:SS UTC'
    function utc(p_ts in timestamp with time zone) return varchar2;
    -- first and last name of an APEX workspace user, or the user name
    function sender_name(p_user_name in varchar2) return varchar2;

    procedure log_event(
        p_doc_id    in number,
        p_event     in varchar2,
        p_details   in varchar2 default null,
        p_signer_id in number   default null,
        p_actor     in varchar2 default null);
    -- 'Intact: n events' or 'BROKEN at event n'
    function verify_chain(p_doc_id in number) return varchar2;

    ----------------------------------------------------------------- sender side
    -- p_temp_file: NAME of the upload in APEX_APPLICATION_TEMP_FILES
    function create_document(
        p_title     in varchar2,
        p_message   in varchar2,
        p_routing   in varchar2,
        p_temp_file in varchar2) return number;
    procedure update_document(
        p_doc_id    in number,
        p_title     in varchar2,
        p_message   in varchar2,
        p_routing   in varchar2,
        p_temp_file in varchar2 default null);
    procedure add_signer(
        p_doc_id    in number,
        p_name      in varchar2,
        p_email     in varchar2,
        p_order     in number,
        p_page      in varchar2 default 'LAST',
        p_position  in varchar2 default 'BOTTOM_RIGHT');
    procedure remove_signer(p_signer_id in number);
    -- Sends the envelope; returns the signing links (one line per signer) when DEV_MODE = Y
    function send_document(p_doc_id in number, p_expires_days in number default null) return varchar2;
    -- A new signing link for a signer (the previous link stops working)
    function new_signing_link(p_signer_id in number) return varchar2;
    procedure void_document(p_doc_id in number, p_reason in varchar2);
    -- raises an error unless the current APEX user sent the envelope
    procedure check_owner(p_doc_id in number);
    -- Completes an envelope: gets the final PDF from the function ESIGN_RENDER_PDF (sql/06_render_pdf.sql),
    -- adds a signature field if the PDF has none, seals it, stores it, and e-mails it to everyone
    procedure finalize(p_doc_id in number);
    -- All the evidence of an envelope as JSON: envelope, signers (with their signature images as base64 PNG),
    -- and the audit trail. Any PDF tool can build the signed PDF or a certificate from it.
    function evidence_json(p_doc_id in number) return clob;
    procedure download(p_doc_id in number, p_which in varchar2, p_inline in boolean default false);

    ----------------------------------------------------------------- signer side
    -- signer of a signing token, or an error
    function signer_for_token(p_token in varchar2) return number;
    -- sends a one-time code; returns the code when DEV_MODE = Y
    function send_otp(p_signer_id in number) return varchar2;
    procedure verify_otp(p_signer_id in number, p_code in varchar2);
    procedure mark_viewed(p_signer_id in number);
    procedure sign(
        p_signer_id      in number,
        p_signature_png  in clob,        -- data:image/png;base64,...
        p_method         in varchar2,    -- DRAWN or TYPED
        p_consent        in varchar2);   -- Y
    procedure decline(p_signer_id in number, p_reason in varchar2);
    procedure view_pdf(p_signer_id in number);

    ----------------------------------------------------------------- APEX
    -- Error Handling Function of the application: shows the text of ESign errors without "ORA-20001:"
    function apex_error_handler(p_error in apex_error.t_error) return apex_error.t_error_result;

    ----------------------------------------------------------------- verification
    -- HTML result for the SHA-256 of a PDF (computed in the browser on the Verify page)
    function verify_hash(p_sha256 in varchar2, p_file_name in varchar2 default null) return varchar2;
    -- PKCS#7 seal of a prepared PDF (placeholders from esign_pdf.stamp)
    function seal_pdf(p_pdf in blob) return blob;
    -- Stores the seal certificate and its private key (PEM text from openssl) and makes them active
    procedure set_seal_key(p_label in varchar2, p_cert_pem in clob, p_key_pem in clob);

end esign_pkg;
/

create or replace package body esign_pkg as

    -- the start of the empty /Contents of a signature field
    c_placeholder constant varchar2(41) := '<0000000000000000000000000000000000000000';

    ------------------------------------------------------------------ helpers
    function setting(p_name in varchar2) return varchar2 is
        l_value esign_settings.value%type;
    begin
        select value into l_value from esign_settings where name = p_name;
        return l_value;
    exception when no_data_found then
        return null;
    end setting;

    function dev_mode return boolean is
    begin
        return setting('DEV_MODE') = 'Y';
    end dev_mode;

    function sha256_hex(p_blob in blob) return varchar2 is
    begin
        return lower(rawtohex(dbms_crypto.hash(p_blob, dbms_crypto.hash_sh256)));
    end sha256_hex;

    function sha256_hex(p_text in varchar2) return varchar2 is
    begin
        return lower(rawtohex(dbms_crypto.hash(utl_raw.cast_to_raw(p_text), dbms_crypto.hash_sh256)));
    end sha256_hex;

    function utc(p_ts in timestamp with time zone) return varchar2 is
    begin
        return case when p_ts is not null
                    then to_char(p_ts at time zone 'UTC', 'YYYY-MM-DD HH24:MI:SS') || ' UTC' end;
    end utc;

    function sender_name(p_user_name in varchar2) return varchar2 is
        l_name varchar2(400);
    begin
        select nullif(trim(first_name || ' ' || last_name), '')
          into l_name
          from apex_workspace_apex_users
         where upper(user_name) = upper(p_user_name)
         fetch first row only;
        return coalesce(l_name, p_user_name);
    exception when others then
        return p_user_name;
    end sender_name;

    function cgi(p_name in varchar2) return varchar2 is
    begin
        return owa_util.get_cgi_env(p_name);
    exception when others then
        return null;
    end cgi;

    function client_ip return varchar2 is
    begin
        return substr(trim(regexp_substr(coalesce(cgi('HTTP_X_FORWARDED_FOR'), cgi('REMOTE_ADDR')), '[^,]+')), 1, 64);
    end client_ip;

    function current_user_name return varchar2 is
        l_user varchar2(255) := coalesce(sys_context('APEX$SESSION', 'APP_USER'), user);
    begin
        -- actions on the public signing pages that are not the signer's own (next invitation, completion)
        return case when upper(l_user) in ('APEX_PUBLIC_USER', 'ORDS_PUBLIC_USER', 'NOBODY') then 'system' else l_user end;
    end current_user_name;

    procedure fail(p_message in varchar2) is
    begin
        raise_application_error(-20001, p_message);
    end fail;

    function random_hex(p_bytes in pls_integer) return varchar2 is
    begin
        return lower(rawtohex(dbms_crypto.randombytes(p_bytes)));
    end random_hex;

    function new_envelope_id return varchar2 is
        l_hex varchar2(32) := upper(random_hex(16));
    begin
        return substr(l_hex, 1, 8) || '-' || substr(l_hex, 9, 4) || '-' || substr(l_hex, 13, 4)
            || '-' || substr(l_hex, 17, 4) || '-' || substr(l_hex, 21);
    end new_envelope_id;

    function doc_row(p_doc_id in number, p_lock in boolean default false) return esign_documents%rowtype is
        l_doc esign_documents%rowtype;
    begin
        if p_lock then
            select * into l_doc from esign_documents where doc_id = p_doc_id for update;
        else
            select * into l_doc from esign_documents where doc_id = p_doc_id;
        end if;
        return l_doc;
    exception when no_data_found then
        fail('Document ' || p_doc_id || ' does not exist.');
    end doc_row;

    function signer_row(p_signer_id in number, p_lock in boolean default false) return esign_signers%rowtype is
        l_signer esign_signers%rowtype;
    begin
        if p_lock then
            select * into l_signer from esign_signers where signer_id = p_signer_id for update;
        else
            select * into l_signer from esign_signers where signer_id = p_signer_id;
        end if;
        return l_signer;
    exception when no_data_found then
        fail('Signer ' || p_signer_id || ' does not exist.');
    end signer_row;

    procedure send_mail(
        p_to          in varchar2,
        p_subject     in varchar2,
        p_body_html   in varchar2,
        p_doc_id      in number,
        p_signer_id   in number   default null,
        p_attach      in blob     default null,
        p_attach_name in varchar2 default null,
        p_link        in varchar2 default null,
        p_code        in varchar2 default null)
    is
        l_mail_id number;
        l_html    varchar2(32767);
    begin
        l_html := '<div style="font-family:Arial,Helvetica,sans-serif;font-size:14px;color:#1f2937;max-width:560px">'
               || '<div style="border-top:4px solid #1c59b8;padding:16px 0 4px;font-weight:bold;font-size:16px">'
               || apex_escape.html(setting('ORG_NAME')) || '</div>' || p_body_html
               || '<p style="color:#6b7280;font-size:12px;margin-top:24px">Do not share this e-mail. '
               || 'Its link lets anyone who has it act on the document.</p></div>';
        if dev_mode then
            -- no mail server in development: keep the e-mail in the demo mailbox
            insert into esign_dev_outbox (doc_id, signer_id, to_email, subject, body_html, link_url, otp_code, has_attachment)
            values (p_doc_id, p_signer_id, p_to, p_subject, l_html, p_link, p_code,
                    case when p_attach is not null then 'Y' else 'N' end);
            log_event(p_doc_id, 'EMAIL_QUEUED', p_subject || ' -> ' || p_to || ' (demo mailbox)', p_signer_id);
            return;
        end if;
        l_mail_id := apex_mail.send(
            p_to        => p_to,
            p_from      => setting('FROM_EMAIL'),
            p_subj      => p_subject,
            p_body      => regexp_replace(l_html, '<[^>]+>', ' '),
            p_body_html => l_html);
        if p_attach is not null then
            apex_mail.add_attachment(
                p_mail_id    => l_mail_id,
                p_attachment => p_attach,
                p_filename   => p_attach_name,
                p_mime_type  => 'application/pdf');
        end if;
        log_event(p_doc_id, 'EMAIL_QUEUED', p_subject || ' -> ' || p_to, p_signer_id);
    exception when others then
        -- a missing mail setup must not stop the signing flow
        log_event(p_doc_id, 'EMAIL_FAILED', substr(p_subject || ' -> ' || p_to || ': ' || sqlerrm, 1, 4000), p_signer_id);
    end send_mail;

    function signing_url(p_token in varchar2) return varchar2 is
        l_url varchar2(4000);
    begin
        l_url := apex_page.get_url(
                     p_application  => setting('SIGN_APP'),
                     p_page         => 'sign',
                     p_session      => 0,
                     p_items        => 'P100_TOKEN',
                     p_values       => p_token,
                     p_absolute_url => true);
        -- the link starts a new session of its own
        return regexp_replace(regexp_replace(l_url, '([?&])session=[^&]*&?', '\1'), '[?&]$', '');
    end signing_url;

    ------------------------------------------------------------------ audit trail
    procedure log_event(
        p_doc_id    in number,
        p_event     in varchar2,
        p_details   in varchar2 default null,
        p_signer_id in number   default null,
        p_actor     in varchar2 default null)
    is
        l_id    number := esign_audit_seq.nextval;
        l_time  timestamp := sys_extract_utc(systimestamp);
        l_prev  esign_audit.prev_hash%type;
        l_actor esign_audit.actor%type := substr(coalesce(p_actor, current_user_name), 1, 320);
        l_ip    esign_audit.ip_address%type := client_ip;
        l_ua    esign_audit.user_agent%type := substr(cgi('HTTP_USER_AGENT'), 1, 1000);
        l_det   esign_audit.details%type := substr(p_details, 1, 4000);
        l_dummy number;
    begin
        -- one writer per envelope at a time, so the chain has no forks
        select doc_id into l_dummy from esign_documents where doc_id = p_doc_id for update;
        select max(row_hash) keep (dense_rank last order by audit_id)
          into l_prev
          from esign_audit
         where doc_id = p_doc_id;
        insert into esign_audit (audit_id, doc_id, signer_id, event_type, details, actor,
                                 ip_address, user_agent, event_time, prev_hash, row_hash)
        values (l_id, p_doc_id, p_signer_id, p_event, l_det, l_actor, l_ip, l_ua, l_time, l_prev,
                sha256_hex(l_id || '|' || p_doc_id || '|' || p_signer_id || '|' || p_event || '|' || l_det
                           || '|' || l_actor || '|' || l_ip || '|'
                           || to_char(l_time, 'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"')
                           || '|' || l_prev));
    end log_event;

    function verify_chain(p_doc_id in number) return varchar2 is
        l_prev  esign_audit.prev_hash%type;
        l_count pls_integer := 0;
    begin
        for a in (select * from esign_audit where doc_id = p_doc_id order by audit_id) loop
            l_count := l_count + 1;
            if nvl(a.prev_hash, '-') <> nvl(l_prev, '-')
               or a.row_hash <> sha256_hex(a.audit_id || '|' || a.doc_id || '|' || a.signer_id || '|' || a.event_type
                                           || '|' || a.details || '|' || a.actor || '|' || a.ip_address || '|'
                                           || to_char(a.event_time, 'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"')
                                           || '|' || a.prev_hash)
            then
                return 'BROKEN at event ' || l_count;
            end if;
            l_prev := a.row_hash;
        end loop;
        return 'Intact: ' || l_count || ' events, each chained to the previous one by SHA-256';
    end verify_chain;

    ------------------------------------------------------------------ sender side
    procedure load_file(p_doc_id in number, p_temp_file in varchar2) is
        l_blob  blob;
        l_name  varchar2(400);
        l_check varchar2(4000);
    begin
        select blob_content, filename
          into l_blob, l_name
          from apex_application_temp_files
         where name = p_temp_file;
        if dbms_lob.getlength(l_blob) > to_number(setting('MAX_PDF_MB')) * 1024 * 1024 then
            fail('The PDF is larger than ' || setting('MAX_PDF_MB') || ' MB.');
        end if;
        if dbms_lob.substr(l_blob, 5, 1) <> utl_raw.cast_to_raw('%PDF-') then
            fail('Upload a PDF file.');
        end if;
        l_check := esign_pdf.inspect(l_blob);
        if json_value(l_check, '$.ok') <> 'true' then
            fail(json_value(l_check, '$.error'));
        end if;
        update esign_documents
           set original_pdf    = l_blob,
               file_name       = l_name,
               original_sha256 = sha256_hex(l_blob),
               page_count      = json_value(l_check, '$.pages' returning number)
         where doc_id = p_doc_id;
        log_event(p_doc_id, 'FILE_UPLOADED',
                  l_name || ', ' || json_value(l_check, '$.pages') || ' pages, SHA-256 ' || sha256_hex(l_blob));
    exception when no_data_found then
        fail('The uploaded file was not found. Upload it again.');
    end load_file;

    function create_document(
        p_title     in varchar2,
        p_message   in varchar2,
        p_routing   in varchar2,
        p_temp_file in varchar2) return number
    is
        l_doc_id number;
        l_user   varchar2(255) := current_user_name;
        l_env    varchar2(36)  := new_envelope_id;
    begin
        if p_temp_file is null then
            fail('Choose the PDF to be signed.');
        end if;
        insert into esign_documents (envelope_id, title, message, routing, created_by)
        values (l_env, p_title, p_message, nvl(p_routing, 'SEQUENTIAL'), l_user)
        returning doc_id into l_doc_id;
        log_event(l_doc_id, 'CREATED', 'Envelope created: ' || p_title);
        load_file(l_doc_id, p_temp_file);
        return l_doc_id;
    end create_document;

    procedure update_document(
        p_doc_id    in number,
        p_title     in varchar2,
        p_message   in varchar2,
        p_routing   in varchar2,
        p_temp_file in varchar2 default null)
    is
        l_doc esign_documents%rowtype := doc_row(p_doc_id, p_lock => true);
    begin
        if l_doc.status <> 'DRAFT' then
            fail('Only a draft can be changed.');
        end if;
        update esign_documents
           set title = p_title, message = p_message, routing = nvl(p_routing, routing)
         where doc_id = p_doc_id;
        if p_temp_file is not null then
            load_file(p_doc_id, p_temp_file);
        end if;
    end update_document;

    procedure add_signer(
        p_doc_id    in number,
        p_name      in varchar2,
        p_email     in varchar2,
        p_order     in number,
        p_page      in varchar2 default 'LAST',
        p_position  in varchar2 default 'BOTTOM_RIGHT')
    is
        l_doc esign_documents%rowtype := doc_row(p_doc_id, p_lock => true);
    begin
        if l_doc.status <> 'DRAFT' then
            fail('Signers can only be added to a draft.');
        end if;
        if trim(p_name) is null or not regexp_like(trim(p_email), '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$') then
            fail('Enter the signer''s name and a valid e-mail address.');
        end if;
        insert into esign_signers (doc_id, sign_order, signer_name, signer_email, stamp_page, stamp_position)
        values (p_doc_id, nvl(p_order, 1), trim(p_name), lower(trim(p_email)), nvl(p_page, 'LAST'), nvl(p_position, 'BOTTOM_RIGHT'));
        log_event(p_doc_id, 'SIGNER_ADDED', trim(p_name) || ' <' || lower(trim(p_email)) || '>, order ' || nvl(p_order, 1));
    exception when dup_val_on_index then
        fail(lower(trim(p_email)) || ' is already a signer of this document.');
    end add_signer;

    procedure remove_signer(p_signer_id in number) is
        l_signer esign_signers%rowtype := signer_row(p_signer_id);
        l_doc    esign_documents%rowtype := doc_row(l_signer.doc_id, p_lock => true);
    begin
        if l_doc.status <> 'DRAFT' then
            fail('Signers can only be removed from a draft.');
        end if;
        delete from esign_signers where signer_id = p_signer_id;
        log_event(l_doc.doc_id, 'SIGNER_REMOVED', l_signer.signer_name || ' <' || l_signer.signer_email || '>');
    end remove_signer;

    -- new token for a signer: stores its hash, returns the link
    function issue_link(p_signer_id in number) return varchar2 is
        l_token varchar2(64) := random_hex(32);
    begin
        update esign_signers
           set token_hash    = sha256_hex(l_token),
               token_expires = coalesce((select expires_on from esign_documents d where d.doc_id = esign_signers.doc_id),
                                        systimestamp + numtodsinterval(to_number(setting('LINK_TTL_DAYS')), 'DAY')),
               otp_hash = null, otp_expires = null, otp_attempts = 0, otp_verified_on = null
         where signer_id = p_signer_id;
        return signing_url(l_token);
    end issue_link;

    -- invites the signers whose turn it is; returns "name: link" lines
    function invite_next(p_doc_id in number) return varchar2 is
        l_doc   esign_documents%rowtype := doc_row(p_doc_id);
        l_turn  number;
        l_link  varchar2(4000);
        l_links varchar2(32767);
    begin
        select min(sign_order) into l_turn
          from esign_signers
         where doc_id = p_doc_id and status <> 'SIGNED';
        for s in (select *
                    from esign_signers
                   where doc_id = p_doc_id
                     and status = 'PENDING'
                     and (l_doc.routing = 'PARALLEL' or sign_order = l_turn)
                   order by sign_order, signer_id)
        loop
            l_link := issue_link(s.signer_id);
            update esign_signers set status = 'SENT' where signer_id = s.signer_id;
            log_event(p_doc_id, 'INVITED', s.signer_name || ' <' || s.signer_email || '> was asked to sign', s.signer_id);
            send_mail(
                p_to        => s.signer_email,
                p_subject   => 'Please sign: ' || l_doc.title,
                p_body_html => '<p>Hello ' || apex_escape.html(s.signer_name) || ',</p><p>'
                            || apex_escape.html(sender_name(l_doc.created_by)) || ' sent you <b>' || apex_escape.html(l_doc.title)
                            || '</b> to sign.</p>'
                            || case when l_doc.message is not null
                                    then '<p style="border-left:3px solid #d1d5db;padding-left:10px">'
                                         || apex_escape.html(l_doc.message) || '</p>' end
                            || '<p><a href="' || l_link || '" style="background:#1c59b8;color:#fff;padding:10px 18px;'
                            || 'border-radius:4px;text-decoration:none;display:inline-block">Review and sign</a></p>',
                p_doc_id    => p_doc_id,
                p_signer_id => s.signer_id,
                p_link      => l_link);
            l_links := l_links || s.signer_name || ' <' || s.signer_email || '>' || chr(10) || l_link || chr(10) || chr(10);
        end loop;
        return rtrim(l_links, chr(10));
    end invite_next;

    function send_document(p_doc_id in number, p_expires_days in number default null) return varchar2 is
        l_doc   esign_documents%rowtype := doc_row(p_doc_id, p_lock => true);
        l_count pls_integer;
        l_links varchar2(32767);
    begin
        if l_doc.status <> 'DRAFT' then
            fail('This document has already been sent.');
        end if;
        if l_doc.original_pdf is null then
            fail('Upload the PDF first.');
        end if;
        select count(*) into l_count from esign_signers where doc_id = p_doc_id;
        if l_count = 0 then
            fail('Add at least one signer.');
        end if;
        if sha256_hex(l_doc.original_pdf) <> l_doc.original_sha256 then
            fail('The stored PDF does not match its fingerprint.');
        end if;
        update esign_documents
           set status     = 'SENT',
               sent_on    = systimestamp,
               expires_on = systimestamp + numtodsinterval(nvl(p_expires_days, to_number(setting('LINK_TTL_DAYS'))), 'DAY')
         where doc_id = p_doc_id;
        log_event(p_doc_id, 'SENT', 'Sent to ' || l_count || ' signer(s), ' || lower(l_doc.routing) || ' routing');
        l_links := invite_next(p_doc_id);
        return case when dev_mode then l_links end;
    end send_document;

    function new_signing_link(p_signer_id in number) return varchar2 is
        l_signer esign_signers%rowtype := signer_row(p_signer_id, p_lock => true);
        l_doc    esign_documents%rowtype := doc_row(l_signer.doc_id);
        l_link   varchar2(4000);
    begin
        if l_doc.status <> 'SENT' or l_signer.status not in ('SENT', 'VIEWED') then
            fail('A signing link can only be created for a signer who is waiting to sign.');
        end if;
        l_link := issue_link(p_signer_id);
        log_event(l_doc.doc_id, 'LINK_REISSUED', 'New signing link for ' || l_signer.signer_email
                  || '; the previous link no longer works', p_signer_id);
        send_mail(
            p_to        => l_signer.signer_email,
            p_subject   => 'New signing link: ' || l_doc.title,
            p_body_html => '<p>Hello ' || apex_escape.html(l_signer.signer_name) || ',</p><p>Here is a new link to sign <b>'
                        || apex_escape.html(l_doc.title) || '</b>. Earlier links no longer work.</p>'
                        || '<p><a href="' || l_link || '">Review and sign</a></p>',
            p_doc_id    => l_doc.doc_id,
            p_signer_id => p_signer_id,
            p_link      => l_link);
        return l_link;
    end new_signing_link;

    procedure void_document(p_doc_id in number, p_reason in varchar2) is
        l_doc esign_documents%rowtype := doc_row(p_doc_id, p_lock => true);
    begin
        if l_doc.status not in ('DRAFT', 'SENT') then
            fail('Only a draft or a sent document can be voided.');
        end if;
        if trim(p_reason) is null then
            fail('Enter the reason for voiding the document.');
        end if;
        update esign_documents set status = 'VOIDED', void_reason = p_reason where doc_id = p_doc_id;
        update esign_signers
           set status = 'VOIDED', otp_hash = null
         where doc_id = p_doc_id and status in ('PENDING', 'SENT', 'VIEWED');
        log_event(p_doc_id, 'VOIDED', p_reason);
    end void_document;

    procedure check_owner(p_doc_id in number) is
        l_owner esign_documents.created_by%type;
    begin
        select created_by into l_owner from esign_documents where doc_id = p_doc_id;
        if upper(l_owner) <> upper(current_user_name) then
            fail('You can only open envelopes that you sent.');
        end if;
    exception when no_data_found then
        fail('Document ' || p_doc_id || ' does not exist.');
    end check_owner;

    ------------------------------------------------------------------ PKCS#7 seal
    function der_len(p_len in pls_integer) return raw is
    begin
        return case
                   when p_len < 128   then hextoraw(to_char(p_len, 'FM0X'))
                   when p_len < 256   then hextoraw('81' || to_char(p_len, 'FM0X'))
                   else                    hextoraw('82' || to_char(p_len, 'FM000X'))
               end;
    end der_len;

    function tlv(p_tag in varchar2, p_value in raw) return raw is
    begin
        return utl_raw.concat(hextoraw(p_tag), der_len(nvl(utl_raw.length(p_value), 0)), p_value);
    end tlv;

    -- header length and content length of the DER element that starts at p_pos
    procedure der_element(p_der in raw, p_pos in pls_integer, p_hdr out pls_integer, p_len out pls_integer) is
        l_first pls_integer := to_number(rawtohex(utl_raw.substr(p_der, p_pos + 1, 1)), 'XX');
    begin
        if l_first < 128 then
            p_hdr := 2;
            p_len := l_first;
        else
            p_hdr := 2 + (l_first - 128);
            p_len := to_number(rawtohex(utl_raw.substr(p_der, p_pos + 2, l_first - 128)), 'XXXXXXXX');
        end if;
    end der_element;

    function seal_pdf(p_pdf in blob) return blob is
        c_data        constant raw(20) := hextoraw('2A864886F70D010701');
        c_signed_data constant raw(20) := hextoraw('2A864886F70D010702');
        c_ct          constant raw(20) := hextoraw('2A864886F70D010903');
        c_md          constant raw(20) := hextoraw('2A864886F70D010904');
        c_st          constant raw(20) := hextoraw('2A864886F70D010905');
        c_alg_sha256  constant raw(20) := hextoraw('300D06096086480165030402010500');
        c_alg_rsa     constant raw(20) := hextoraw('300D06092A864886F70D0101010500');
        l_pdf       blob;
        l_part      blob;
        l_key       esign_seal_keys%rowtype;
        l_cert      raw(32767);
        l_pos       pls_integer;
        l_hdr       pls_integer;
        l_len       pls_integer;
        l_serial    raw(200);
        l_issuer    raw(2000);
        l_br_start  pls_integer;
        l_br_end    pls_integer;
        l_lt        pls_integer;
        l_gt        pls_integer;
        l_total     pls_integer;
        l_range     varchar2(200);
        l_digest    raw(32);
        l_attrs     raw(2000);
        l_signature raw(2000);
        l_cms       raw(32767);
        l_hex       varchar2(32767);
    begin
        select * into l_key
          from esign_seal_keys
         where is_active = 'Y'
         order by seal_id desc
         fetch first row only;
        l_cert := dbms_lob.substr(l_key.cert_der, 32767, 1);

        -- issuer and serial number from the certificate (tbsCertificate)
        der_element(l_cert, 1, l_hdr, l_len);                 -- Certificate
        l_pos := 1 + l_hdr;
        der_element(l_cert, l_pos, l_hdr, l_len);             -- tbsCertificate
        l_pos := l_pos + l_hdr;
        if utl_raw.substr(l_cert, l_pos, 1) = hextoraw('A0') then   -- [0] version
            der_element(l_cert, l_pos, l_hdr, l_len);
            l_pos := l_pos + l_hdr + l_len;
        end if;
        der_element(l_cert, l_pos, l_hdr, l_len);             -- serialNumber
        l_serial := utl_raw.substr(l_cert, l_pos, l_hdr + l_len);
        l_pos := l_pos + l_hdr + l_len;
        der_element(l_cert, l_pos, l_hdr, l_len);             -- signature algorithm
        l_pos := l_pos + l_hdr + l_len;
        der_element(l_cert, l_pos, l_hdr, l_len);             -- issuer
        l_issuer := utl_raw.substr(l_cert, l_pos, l_hdr + l_len);

        -- placeholders written by esign_pdf.stamp: /Contents of zeros, and a /ByteRange that is either
        -- blank (pdf-lib in MLE: filled here) or already filled (PDFBox in Java: checked here)
        dbms_lob.createtemporary(l_pdf, true);
        dbms_lob.copy(l_pdf, p_pdf, dbms_lob.getlength(p_pdf));
        l_total    := dbms_lob.getlength(l_pdf);
        l_lt       := dbms_lob.instr(l_pdf, utl_raw.cast_to_raw(c_placeholder));
        if l_lt = 0 then
            fail('The PDF has no signature placeholder.');
        end if;
        l_gt     := dbms_lob.instr(l_pdf, utl_raw.cast_to_raw('>'), l_lt);
        l_range  := '[0 ' || (l_lt - 1) || ' ' || l_gt || ' ' || (l_total - l_gt) || ']';
        l_br_start := dbms_lob.instr(l_pdf, utl_raw.cast_to_raw('[ 0 /********** /********** /********** ]'));
        if l_br_start > 0 then
            -- /ByteRange: everything except the <...> of /Contents
            l_br_end := l_br_start + length('[ 0 /********** /********** /********** ]') - 1;
            if length(l_range) > l_br_end - l_br_start + 1 then
                fail('The PDF is too large for the signature placeholder.');
            end if;
            dbms_lob.write(l_pdf, l_br_end - l_br_start + 1, l_br_start,
                           utl_raw.cast_to_raw(rpad(l_range, l_br_end - l_br_start + 1)));
        else
            -- the /ByteRange nearest to the placeholder must cover everything except the <...>
            l_pos := 0;
            loop
                l_hdr := dbms_lob.instr(l_pdf, utl_raw.cast_to_raw('/ByteRange'), l_pos + 1);
                exit when l_hdr = 0 or l_hdr > l_gt + 200;
                l_pos := l_hdr;
            end loop;
            if l_pos = 0 or regexp_replace(utl_raw.cast_to_varchar2(dbms_lob.substr(l_pdf, 80, l_pos)),
                                           '^/ByteRange\s*\[\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*\].*$', '[\1 \2 \3 \4]', 1, 1, 'n')
                            <> l_range then
                fail('The signature placeholder does not cover the whole PDF.');
            end if;
        end if;

        dbms_lob.createtemporary(l_part, true);
        dbms_lob.copy(l_part, l_pdf, l_lt - 1, 1, 1);
        dbms_lob.copy(l_part, l_pdf, l_total - l_gt, l_lt, l_gt + 1);
        l_digest := dbms_crypto.hash(l_part, dbms_crypto.hash_sh256);
        dbms_lob.freetemporary(l_part);

        -- signed attributes, in DER order: contentType, signingTime, messageDigest
        l_attrs := utl_raw.concat(
            tlv('30', utl_raw.concat(tlv('06', c_ct), tlv('31', tlv('06', c_data)))),
            tlv('30', utl_raw.concat(tlv('06', c_st), tlv('31', tlv('17', utl_raw.cast_to_raw(
                to_char(sys_extract_utc(systimestamp), 'YYMMDDHH24MISS') || 'Z'))))),
            tlv('30', utl_raw.concat(tlv('06', c_md), tlv('31', tlv('04', l_digest)))));
        l_signature := esign_pdf.sign_rsa(
            p_data    => tlv('31', l_attrs),
            p_key_b64 => replace(replace(dbms_lob.substr(l_key.private_key_b64, 32767, 1), chr(10)), chr(13)));

        l_cms := tlv('30', utl_raw.concat(
                    tlv('06', c_signed_data),
                    tlv('A0', tlv('30', utl_raw.concat(
                        hextoraw('020101'),
                        tlv('31', c_alg_sha256),
                        tlv('30', tlv('06', c_data)),
                        tlv('A0', l_cert),
                        tlv('31', tlv('30', utl_raw.concat(
                            hextoraw('020101'),
                            tlv('30', utl_raw.concat(l_issuer, l_serial)),
                            c_alg_sha256,
                            tlv('A0', l_attrs),
                            c_alg_rsa,
                            tlv('04', l_signature)))))))));
        l_hex := rawtohex(l_cms);
        if length(l_hex) > l_gt - l_lt - 1 then
            fail('The signature does not fit the placeholder.');
        end if;
        dbms_lob.write(l_pdf, length(l_hex), l_lt + 1, utl_raw.cast_to_raw(l_hex));
        return l_pdf;
    exception when no_data_found then
        fail('No active seal key. Run the seal key setup.');
    end seal_pdf;

    procedure set_seal_key(p_label in varchar2, p_cert_pem in clob, p_key_pem in clob) is
        l_cert  blob;
        l_key   varchar2(32767);
        l_test  raw(2000);
    begin
        if dbms_lob.instr(p_key_pem, 'BEGIN PRIVATE KEY') = 0 then
            fail('Paste an unencrypted PKCS#8 key: the text between -----BEGIN PRIVATE KEY----- and -----END PRIVATE KEY-----.');
        end if;
        if dbms_lob.instr(p_cert_pem, 'BEGIN CERTIFICATE') = 0 then
            fail('Paste the certificate: the text between -----BEGIN CERTIFICATE----- and -----END CERTIFICATE-----.');
        end if;
        l_cert := apex_web_service.clobbase642blob(regexp_replace(p_cert_pem, '-----[^-]+-----|\s', ''));
        l_key  := regexp_replace(dbms_lob.substr(p_key_pem, 32767, 1), '-----[^-]+-----|\s', '');
        -- the key must be able to sign
        l_test := esign_pdf.sign_rsa(utl_raw.cast_to_raw('test'), l_key);
        update esign_seal_keys set is_active = 'N';
        insert into esign_seal_keys (label, subject, cert_der, private_key_b64, valid_from, is_active)
        values (p_label, p_label, l_cert, l_key, trunc(sysdate), 'Y');
    end set_seal_key;

    ------------------------------------------------------------------ completion
    function evidence_json(p_doc_id in number) return clob is
        l_doc  esign_documents%rowtype := doc_row(p_doc_id);
        l_meta clob;
        l_seal varchar2(400);
    begin
        select nvl(max(label), 'Document seal')
          into l_seal
          from esign_seal_keys where is_active = 'Y';

        select json_object(
                   'org'            value setting('ORG_NAME'),
                   'envelopeId'     value l_doc.envelope_id,
                   'title'          value l_doc.title,
                   'fileName'       value l_doc.file_name,
                   'pages'          value l_doc.page_count,
                   'sender'         value sender_name(l_doc.created_by) || ' (' || l_doc.created_by || ')',
                   'sentOn'         value utc(l_doc.sent_on),
                   'completedOn'    value utc(nvl(l_doc.completed_on, systimestamp)),
                   'routing'        value l_doc.routing,
                   'originalSha256' value l_doc.original_sha256,
                   'sealName'       value l_seal,
                   'signers'        value (
                       select json_arrayagg(json_object(
                                  'signerId'      value s.signer_id,
                                  'name'          value s.signer_name,
                                  'email'         value s.signer_email,
                                  'status'        value initcap(s.status),
                                  'signedOn'      value utc(s.signed_on),
                                  'signatureId'   value upper(substr(sha256_hex(s.signer_id || '|' || l_doc.envelope_id
                                                                   || '|' || s.doc_sha256_at_signing), 1, 16)),
                                  'method'        value s.signature_method,
                                  'otpVerifiedOn' value utc(s.otp_verified_on),
                                  'consentOn'     value utc(s.consent_on),
                                  'ip'            value s.signed_ip,
                                  'docSha256'     value s.doc_sha256_at_signing,
                                  'stampPage'     value s.stamp_page,
                                  'stampPosition' value s.stamp_position,
                                  'png'           value apex_web_service.blob2clobbase64(s.signature_png, 'N', 'Y')
                                  returning clob)
                              order by s.sign_order, s.signer_id returning clob)
                         from esign_signers s where s.doc_id = p_doc_id),
                   'audit'          value (
                       select json_arrayagg(json_object(
                                  'time'    value to_char(a.event_time, 'YYYY-MM-DD HH24:MI:SS') || ' UTC',
                                  'event'   value a.event_type,
                                  'actor'   value a.actor,
                                  'details' value a.details || case when a.ip_address is not null
                                                                    then ' (IP ' || a.ip_address || ')' end)
                              order by a.audit_id returning clob)
                         from esign_audit a
                        where a.doc_id = p_doc_id
                          and a.event_type not in ('EMAIL_QUEUED', 'EMAIL_FAILED'))
                   returning clob)
          into l_meta
          from dual;

        return l_meta;
    end evidence_json;

    -- the final PDF from the application's function ESIGN_RENDER_PDF (called dynamically, so that the
    -- package compiles before the function exists)
    function render_pdf(p_doc_id in number) return blob is
        l_pdf blob;
    begin
        execute immediate 'begin :pdf := esign_render_pdf(:doc_id); end;' using out l_pdf, in p_doc_id;
        if l_pdf is null or dbms_lob.getlength(l_pdf) < 8 or dbms_lob.substr(l_pdf, 5, 1) <> utl_raw.cast_to_raw('%PDF-') then
            fail('ESIGN_RENDER_PDF did not return a PDF.');
        end if;
        return l_pdf;
    end render_pdf;

    procedure finalize(p_doc_id in number) is
        l_doc    esign_documents%rowtype := doc_row(p_doc_id, p_lock => true);
        l_pdf    blob;
        l_open   pls_integer;
    begin
        if l_doc.status <> 'SENT' then
            fail('Only a sent document can be completed.');
        end if;
        select count(*) into l_open from esign_signers where doc_id = p_doc_id and status <> 'SIGNED';
        if l_open > 0 then
            fail(l_open || ' signer(s) have not signed yet.');
        end if;
        if sha256_hex(l_doc.original_pdf) <> l_doc.original_sha256 then
            fail('The stored PDF does not match its fingerprint; it was changed after it was sent.');
        end if;

        l_pdf := render_pdf(p_doc_id);
        -- a PDF from another tool has no signature field yet: the PDF engine adds one
        if dbms_lob.instr(l_pdf, utl_raw.cast_to_raw(c_placeholder)) = 0 then
            l_pdf := esign_pdf.prepare_seal(l_pdf, evidence_json(p_doc_id));
        end if;
        -- sealed when there is a signature field (without a PDF engine, the PDF is stored as it is)
        if dbms_lob.instr(l_pdf, utl_raw.cast_to_raw(c_placeholder)) > 0 then
            l_pdf := seal_pdf(l_pdf);
        else
            log_event(p_doc_id, 'NOT_SEALED', 'No PDF engine to add a digital seal; the PDF is verified by its SHA-256 only',
                      p_actor => 'system');
        end if;

        update esign_documents
           set signed_pdf    = l_pdf,
               signed_sha256 = sha256_hex(l_pdf),
               status        = 'COMPLETED',
               completed_on  = systimestamp
         where doc_id = p_doc_id;
        log_event(p_doc_id, 'COMPLETED', 'All signers signed. '
                  || case when dbms_lob.instr(l_pdf, utl_raw.cast_to_raw('/adbe.pkcs7.detached')) > 0 then 'Sealed' else 'Final' end
                  || ' PDF SHA-256 ' || sha256_hex(l_pdf), p_actor => 'system');

        for r in (select signer_name as name, signer_email as email from esign_signers where doc_id = p_doc_id
                  union
                  select u.first_name || ' ' || u.last_name, u.email
                    from apex_workspace_apex_users u
                   where upper(u.user_name) = upper(l_doc.created_by) and u.email is not null)
        loop
            send_mail(
                p_to          => r.email,
                p_subject     => 'Completed: ' || l_doc.title,
                p_body_html   => '<p>Hello ' || apex_escape.html(r.name) || ',</p><p>All parties have signed <b>'
                              || apex_escape.html(l_doc.title) || '</b>. The completed, digitally sealed PDF is attached.</p>',
                p_doc_id      => p_doc_id,
                p_attach      => l_pdf,
                p_attach_name => regexp_replace(nvl(l_doc.file_name, 'document.pdf'), '\.pdf$', '', 1, 1, 'i') || ' - signed.pdf');
        end loop;
    end finalize;

    procedure download(p_doc_id in number, p_which in varchar2, p_inline in boolean default false) is
        l_doc esign_documents%rowtype := doc_row(p_doc_id);
        l_pdf blob;
    begin
        if p_which = 'SIGNED' and l_doc.signed_pdf is null then
            fail('The document is not completed yet.');
        end if;
        l_pdf := case p_which when 'SIGNED' then l_doc.signed_pdf else l_doc.original_pdf end;
        apex_http.download(
            p_blob         => l_pdf,
            p_content_type => 'application/pdf',
            p_filename     => case p_which
                                  when 'SIGNED' then regexp_replace(nvl(l_doc.file_name, 'document.pdf'), '\.pdf$', '', 1, 1, 'i') || ' - signed.pdf'
                                  else nvl(l_doc.file_name, 'document.pdf')
                              end,
            p_is_inline    => p_inline);
    end download;

    ------------------------------------------------------------------ signer side
    function signer_for_token(p_token in varchar2) return number is
        l_signer esign_signers%rowtype;
        l_doc    esign_documents%rowtype;
    begin
        if p_token is null or not regexp_like(p_token, '^[0-9a-f]{64}$') then
            fail('This signing link is not valid.');
        end if;
        begin
            select * into l_signer from esign_signers where token_hash = sha256_hex(p_token);
        exception when no_data_found then
            fail('This signing link is not valid, or a newer link has replaced it.');
        end;
        l_doc := doc_row(l_signer.doc_id);
        if l_doc.status = 'VOIDED' then
            fail('The sender voided this document.');
        elsif l_doc.status = 'DECLINED' then
            fail('This document was declined and can no longer be signed.');
        elsif l_signer.token_expires < systimestamp then
            fail('This signing link has expired. Ask the sender for a new one.');
        end if;
        return l_signer.signer_id;
    end signer_for_token;

    function send_otp(p_signer_id in number) return varchar2 is
        l_signer esign_signers%rowtype := signer_row(p_signer_id, p_lock => true);
        l_doc    esign_documents%rowtype := doc_row(l_signer.doc_id);
        l_code   varchar2(6);
    begin
        if l_signer.status not in ('SENT', 'VIEWED') or l_doc.status <> 'SENT' then
            fail('This document is not waiting for your signature.');
        end if;
        if l_signer.otp_expires > systimestamp + numtodsinterval(to_number(setting('OTP_TTL_MINUTES')) * 60 - 30, 'SECOND') then
            fail('A code was sent less than 30 seconds ago. Check your e-mail.');
        end if;
        l_code := to_char(mod(to_number(rawtohex(dbms_crypto.randombytes(4)), 'XXXXXXXX'), 1000000), 'FM000000');
        update esign_signers
           set otp_hash     = sha256_hex(p_signer_id || ':' || l_code),
               otp_expires  = systimestamp + numtodsinterval(to_number(setting('OTP_TTL_MINUTES')), 'MINUTE'),
               otp_attempts = 0
         where signer_id = p_signer_id;
        log_event(l_doc.doc_id, 'CODE_SENT', 'One-time code sent to ' || l_signer.signer_email, p_signer_id, l_signer.signer_email);
        send_mail(
            p_to        => l_signer.signer_email,
            p_subject   => 'Your code to sign "' || l_doc.title || '"',
            p_body_html => '<p>Your one-time code is</p><p style="font-size:28px;letter-spacing:6px;font-weight:bold">'
                        || l_code || '</p><p>It is valid for ' || setting('OTP_TTL_MINUTES') || ' minutes.</p>',
            p_doc_id    => l_doc.doc_id,
            p_signer_id => p_signer_id,
            p_code      => l_code);
        return case when dev_mode then l_code end;
    end send_otp;

    procedure verify_otp(p_signer_id in number, p_code in varchar2) is
        pragma autonomous_transaction;   -- a wrong attempt must be counted even when the page shows an error
        l_signer esign_signers%rowtype;
        l_max    pls_integer := to_number(setting('OTP_MAX_ATTEMPTS'));
    begin
        -- locked in the body: the declaration section still runs in the caller's transaction
        l_signer := signer_row(p_signer_id, p_lock => true);
        if l_signer.otp_hash is null or l_signer.otp_expires < systimestamp then
            rollback;
            fail('The code has expired. Request a new code.');
        end if;
        if l_signer.otp_attempts >= l_max then
            rollback;
            fail('Too many wrong codes. Request a new code.');
        end if;
        if sha256_hex(p_signer_id || ':' || trim(p_code)) <> l_signer.otp_hash then
            update esign_signers set otp_attempts = otp_attempts + 1 where signer_id = p_signer_id;
            log_event(l_signer.doc_id, 'CODE_REJECTED', 'Wrong one-time code (attempt ' || (l_signer.otp_attempts + 1) || ' of ' || l_max || ')',
                      p_signer_id, l_signer.signer_email);
            commit;
            fail('The code is not correct.');
        end if;
        update esign_signers
           set otp_verified_on = systimestamp, otp_hash = null
         where signer_id = p_signer_id;
        log_event(l_signer.doc_id, 'IDENTITY_VERIFIED', l_signer.signer_email || ' entered the correct one-time code',
                  p_signer_id, l_signer.signer_email);
        commit;
    end verify_otp;

    procedure mark_viewed(p_signer_id in number) is
        l_signer esign_signers%rowtype := signer_row(p_signer_id, p_lock => true);
    begin
        if l_signer.otp_verified_on is not null and l_signer.status = 'SENT' then
            update esign_signers set status = 'VIEWED', viewed_on = systimestamp where signer_id = p_signer_id;
            log_event(l_signer.doc_id, 'VIEWED', l_signer.signer_email || ' opened the document', p_signer_id, l_signer.signer_email);
        end if;
    end mark_viewed;

    procedure check_can_sign(p_signer in esign_signers%rowtype, p_doc in esign_documents%rowtype) is
        l_before pls_integer;
    begin
        if p_doc.status <> 'SENT' or p_signer.status not in ('SENT', 'VIEWED') then
            fail('This document is not waiting for your signature.');
        end if;
        if p_signer.otp_verified_on is null or p_signer.otp_verified_on < systimestamp - interval '60' minute then
            fail('Verify your identity with a one-time code first.');
        end if;
        if p_signer.token_expires < systimestamp or p_doc.expires_on < systimestamp then
            fail('This signing request has expired.');
        end if;
        if p_doc.routing = 'SEQUENTIAL' then
            select count(*) into l_before
              from esign_signers
             where doc_id = p_doc.doc_id and sign_order < p_signer.sign_order and status <> 'SIGNED';
            if l_before > 0 then
                fail('Other signers must sign before you.');
            end if;
        end if;
    end check_can_sign;

    procedure view_pdf(p_signer_id in number) is
        l_signer esign_signers%rowtype := signer_row(p_signer_id);
        l_doc    esign_documents%rowtype := doc_row(l_signer.doc_id);
        l_pdf    blob;
    begin
        if l_signer.otp_verified_on is null then
            fail('Verify your identity first.');
        end if;
        l_pdf := case when l_doc.status = 'COMPLETED' then l_doc.signed_pdf else l_doc.original_pdf end;
        apex_http.download(
            p_blob         => l_pdf,
            p_content_type => 'application/pdf',
            p_filename     => nvl(l_doc.file_name, 'document.pdf'),
            p_is_inline    => true);
    end view_pdf;

    procedure sign(
        p_signer_id      in number,
        p_signature_png  in clob,
        p_method         in varchar2,
        p_consent        in varchar2)
    is
        l_signer esign_signers%rowtype := signer_row(p_signer_id, p_lock => true);
        l_doc    esign_documents%rowtype := doc_row(l_signer.doc_id, p_lock => true);
        l_png    blob;
        l_hash   varchar2(64);
        l_open   pls_integer;
        l_links  varchar2(32767);
        l_ip     varchar2(64)   := client_ip;
        l_ua     varchar2(1000) := substr(cgi('HTTP_USER_AGENT'), 1, 1000);
    begin
        check_can_sign(l_signer, l_doc);
        if nvl(p_consent, 'N') <> 'Y' then
            fail('Accept the electronic signature disclosure to sign.');
        end if;
        if p_signature_png is null or dbms_lob.substr(p_signature_png, 22, 1) <> 'data:image/png;base64,' then
            fail('Draw or type your signature.');
        end if;
        l_png := apex_web_service.clobbase642blob(substr(p_signature_png, 23));
        if dbms_lob.getlength(l_png) > 200000 or dbms_lob.substr(l_png, 8, 1) <> hextoraw('89504E470D0A1A0A') then
            fail('The signature image is not valid.');
        end if;
        -- the document the signer saw is the one that was sent
        l_hash := sha256_hex(l_doc.original_pdf);
        if l_hash <> l_doc.original_sha256 then
            fail('The document was changed after it was sent and can''t be signed.');
        end if;

        update esign_signers
           set status                = 'SIGNED',
               signature_png         = l_png,
               signature_method      = case when p_method = 'TYPED' then 'TYPED' else 'DRAWN' end,
               consent_text          = c_consent,
               consent_on            = systimestamp,
               signed_on             = systimestamp,
               signed_ip             = l_ip,
               signed_user_agent     = l_ua,
               doc_sha256_at_signing = l_hash
         where signer_id = p_signer_id;
        log_event(l_doc.doc_id, 'CONSENT_ACCEPTED', c_consent, p_signer_id, l_signer.signer_email);
        log_event(l_doc.doc_id, 'SIGNED',
                  l_signer.signer_name || ' signed (' || lower(case when p_method = 'TYPED' then 'typed' else 'drawn' end)
                  || ' signature); document SHA-256 ' || l_hash, p_signer_id, l_signer.signer_email);

        select count(*) into l_open from esign_signers where doc_id = l_doc.doc_id and status <> 'SIGNED';
        if l_open = 0 then
            finalize(l_doc.doc_id);
        else
            l_links := invite_next(l_doc.doc_id);
        end if;
    end sign;

    procedure decline(p_signer_id in number, p_reason in varchar2) is
        l_signer esign_signers%rowtype := signer_row(p_signer_id, p_lock => true);
        l_doc    esign_documents%rowtype := doc_row(l_signer.doc_id, p_lock => true);
    begin
        check_can_sign(l_signer, l_doc);
        if trim(p_reason) is null then
            fail('Tell the sender why you decline.');
        end if;
        update esign_signers
           set status = 'DECLINED', decline_reason = p_reason
         where signer_id = p_signer_id;
        update esign_documents set status = 'DECLINED' where doc_id = l_doc.doc_id;
        log_event(l_doc.doc_id, 'DECLINED', l_signer.signer_name || ': ' || p_reason, p_signer_id, l_signer.signer_email);
        for u in (select email from apex_workspace_apex_users
                   where upper(user_name) = upper(l_doc.created_by) and email is not null)
        loop
            send_mail(u.email, 'Declined: ' || l_doc.title,
                      '<p>' || apex_escape.html(l_signer.signer_name) || ' declined to sign <b>' || apex_escape.html(l_doc.title)
                      || '</b>.</p><p>Reason: ' || apex_escape.html(p_reason) || '</p>', l_doc.doc_id, p_signer_id);
        end loop;
    end decline;

    ------------------------------------------------------------------ APEX
    function apex_error_handler(p_error in apex_error.t_error) return apex_error.t_error_result is
        l_result apex_error.t_error_result := apex_error.init_error_result(p_error => p_error);
    begin
        if p_error.ora_sqlcode between -20999 and -20000 then
            l_result.message         := apex_error.get_first_ora_error_text(p_error => p_error);
            l_result.additional_info := null;
        end if;
        return l_result;
    end apex_error_handler;

    ------------------------------------------------------------------ verification
    function verify_hash(p_sha256 in varchar2, p_file_name in varchar2 default null) return varchar2 is
        l_hash varchar2(64) := lower(trim(p_sha256));
        l_html varchar2(32767);
    begin
        if l_hash is null or not regexp_like(l_hash, '^[0-9a-f]{64}$') then
            fail('Choose the PDF to verify.');
        end if;
        for d in (select * from esign_documents where signed_sha256 = l_hash) loop
            l_html := '<div class="esign-verify esign-verify--ok"><span class="fa fa-check-circle"></span><div>'
                   || '<h3>Authentic signed document</h3><p><b>' || apex_escape.html(d.title) || '</b><br>'
                   || 'Envelope ' || d.envelope_id || ', completed ' || utc(d.completed_on) || '.</p><p>Signed by:<br>';
            for s in (select signer_name, signed_on from esign_signers where doc_id = d.doc_id order by sign_order, signer_id) loop
                l_html := l_html || apex_escape.html(s.signer_name) || ' (' || utc(s.signed_on) || ')<br>';
            end loop;
            return l_html || '</p><p class="esign-hash">SHA-256 ' || l_hash || '</p></div></div>';
        end loop;
        for d in (select * from esign_documents where original_sha256 = l_hash) loop
            return '<div class="esign-verify esign-verify--info"><span class="fa fa-info-circle"></span><div>'
                || '<h3>Original, unsigned document</h3><p>This file is the original of envelope ' || d.envelope_id
                || ' (' || apex_escape.html(d.title) || '), status ' || lower(d.status) || '. It carries no signatures.</p>'
                || '<p class="esign-hash">SHA-256 ' || l_hash || '</p></div></div>';
        end loop;
        return '<div class="esign-verify esign-verify--bad"><span class="fa fa-times-circle"></span><div>'
            || '<h3>Not recognized</h3><p>' || nvl(apex_escape.html(p_file_name), 'This file') || ' was not issued by '
            || apex_escape.html(setting('ORG_NAME')) || ', or it was changed after it was sealed. '
            || 'Even a one-byte change gives a different fingerprint.</p>'
            || '<p class="esign-hash">SHA-256 ' || l_hash || '</p></div></div>';
    end verify_hash;

end esign_pkg;
/
