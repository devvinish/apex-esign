prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
-- ESign Signing: part of ESign Lab, electronic signatures for PDF documents with Oracle APEX 26.1
-- Parsing schema: ESIGN. Install the database objects first (see README.md).
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.0'
,p_default_workspace_id=>6400317681717819
,p_default_application_id=>301
,p_default_id_offset=>0
,p_default_owner=>'ESIGN'
);
end;
/
prompt APPLICATION 301 - ESign Signing
prompt --application/delete_application
begin
wwv_flow_imp.remove_flow(wwv_flow.g_flow_id);
end;
/
prompt --application/create_application
begin
wwv_imp_workspace.create_flow(
p_id=>wwv_flow.g_flow_id
,p_owner=>nvl(wwv_flow_application_install.get_schema,'ESIGN')
,p_name=>nvl(wwv_flow_application_install.get_application_name,'ESign Signing')
,p_alias=>nvl(wwv_flow_application_install.get_application_alias,'ESIGN-SIGN')
,p_page_view_logging=>'YES'
,p_page_protection_enabled_y_n=>'Y'
,p_checksum_salt=>'4E8A1C7F2D9B6035E1A8C4F7B2D9E6A3C0F5B8D1E4A7C2F9B6D3E0A5C8F1B4D7'
,p_bookmark_checksum_function=>'SH512'
,p_compatibility_mode=>'26.1'
,p_flow_language=>'en'
,p_flow_language_derived_from=>'FLOW_PRIMARY_LANGUAGE'
,p_date_format=>'DD-MON-YYYY'
,p_timestamp_format=>'DD-MON-YYYY HH24:MI'
,p_timestamp_tz_format=>'DD-MON-YYYY HH24:MI TZR'
,p_flow_image_prefix=>nvl(wwv_flow_application_install.get_image_prefix,'')
,p_authentication_id=>wwv_flow_imp.id(1117)
,p_application_tab_set=>1
,p_logo_type=>'IT'
,p_logo_text=>'ESign Lab'
,p_proxy_server=>nvl(wwv_flow_application_install.get_proxy,'')
,p_no_proxy_domains=>nvl(wwv_flow_application_install.get_no_proxy_domains,'')
,p_flow_version=>'Release 1.0'
,p_flow_status=>'AVAILABLE_W_EDIT_LINK'
,p_browser_cache=>'N'
,p_browser_frame=>'S'
,p_runtime_api_usage=>'T'
,p_authorize_batch_job=>'N'
,p_rejoin_existing_sessions=>'N'
,p_csv_encoding=>'Y'
,p_file_prefix=>nvl(wwv_flow_application_install.get_static_app_file_prefix,'')
,p_print_server_type=>'NATIVE'
,p_file_storage=>'DB'
,p_is_pwa=>'N'
,p_theme_id=>42
,p_home_url=>'f?p=&APP_ID.:VERIFY:&APP_SESSION.::&DEBUG.:::'
,p_login_url=>'f?p=&APP_ID.:VERIFY:&APP_SESSION.::&DEBUG.:::'
,p_theme_style_by_user_pref=>false
,p_built_with_love=>false
,p_global_page_id=>0
,p_nav_bar_type=>'LIST'
,p_nav_bar_list_id=>wwv_flow_imp.id(1119)
,p_nav_bar_list_template_id=>2849019392706229583
,p_nav_bar_template_options=>'#DEFAULT#'
,p_error_handling_function=>'esign_pkg.apex_error_handler'
);
end;
/
prompt --application/shared_components/navigation/lists/navigation_bar
begin
wwv_flow_imp_shared.create_list(
p_id=>wwv_flow_imp.id(1119)
,p_name=>'Navigation Bar'
,p_static_id=>'navigation-bar'
);
end;
/
prompt --application/shared_components/security/authentications/no_authentication
begin
wwv_flow_imp_shared.create_authentication(
p_id=>wwv_flow_imp.id(1117)
,p_name=>'No Authentication'
,p_static_id=>'no-authentication'
,p_scheme_type=>'NATIVE_DAD'
,p_cookie_name=>'ESIGN_SIGNER'
,p_use_secure_cookie_yn=>'N'
,p_ras_mode=>0
);
end;
/
prompt --application/shared_components/logic/application_items/g_signer_id
begin
wwv_flow_imp_shared.create_flow_item(
p_id=>wwv_flow_imp.id(1121)
,p_name=>'G_SIGNER_ID'
,p_protection_level=>'I'
);
end;
/
prompt --application/shared_components/logic/application_items/g_otp_ok
begin
wwv_flow_imp_shared.create_flow_item(
p_id=>wwv_flow_imp.id(1122)
,p_name=>'G_OTP_OK'
,p_protection_level=>'I'
);
end;
/
prompt --application/shared_components/user_interface/themes
begin
wwv_flow_imp_shared.create_theme(
    p_id=>wwv_flow_imp.id(1120)
    ,p_theme_id=>42
    ,p_static_id=>'universal-theme'
    ,p_theme_name=>'Universal Theme'
    ,p_theme_internal_name=>'UNIVERSAL_THEME'
    ,p_version_identifier=>'26.1'
    ,p_navigation_type=>'L'
    ,p_nav_bar_type=>'LIST'
    ,p_is_locked=>false
    ,p_current_theme_style_id=>2243014446517417
    ,p_default_page_template=>4073832297226169690
    ,p_default_dialog_template=>2101883943284197310
    ,p_error_template=>2102634289808461002
    ,p_printer_friendly_template=>4073832297226169690
    ,p_login_template=>2102634289808461002
    ,p_default_button_template=>4073839297780169708
    ,p_default_region_template=>4073835273271169698
    ,p_default_chart_template=>4073835273271169698
    ,p_default_form_template=>4073835273271169698
    ,p_default_reportr_template=>4073835273271169698
    ,p_default_wizard_template=>4073835273271169698
    ,p_default_menur_template=>2532939663579242476
    ,p_default_listr_template=>4073835273271169698
    ,p_default_irr_template=>2102002977963900996
    ,p_default_report_template=>2540130677583398057
    ,p_default_label_template=>1610598304472262251
    ,p_default_menu_template=>4073839682315169711
    ,p_default_list_template=>4073837480889169704
    ,p_default_top_nav_list_temp=>2528231041045349458
    ,p_default_side_nav_list_temp=>2469215554099805162
    ,p_default_nav_list_position=>'SIDE'
    ,p_default_dialogbtnr_template=>2127905476394690047
    ,p_default_dialogr_template=>4502917002193490937
    ,p_default_option_label=>1610598304472262251
    ,p_default_required_label=>1610598484065263269
    ,p_default_navbar_list_template=>2849019392706229583
    ,p_file_prefix=>nvl(wwv_flow_application_install.get_static_theme_file_prefix(42),'#APEX_FILES#themes/theme_42/26.1/')
    ,p_icon_library=>'FONTAPEX'
    ,p_javascript_file_urls=>wwv_flow_string.join(wwv_flow_t_varchar2(
    '#APEX_FILES#libraries/apex/#MIN_DIRECTORY#widget.stickyWidget#MIN#.js?v=#APEX_VERSION#',
    '#THEME_FILES#js/theme42#MIN#.js?v=#APEX_VERSION#'))
    ,p_css_file_urls=>'#THEME_FILES#css/Core#MIN#.css?v=#APEX_VERSION#'
    ,p_reference_id=>wwv_imp_util.get_subscription_id(4073840274158169736,2000,'universal-theme',8842.261)
    );
end;
/
prompt --application/pages/page_00000
begin
wwv_flow_imp_page.create_page(
p_id=>0
,p_name=>'Global Page'
,p_step_title=>'Global Page'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>4073832297226169690
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'D'
);
end;
/
prompt --application/pages/page_00100
begin
wwv_flow_imp_page.create_page(
p_id=>100
,p_name=>'Sign'
,p_alias=>'SIGN'
,p_step_title=>'Sign Document'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>2980551703278319811
,p_page_template_options=>'#DEFAULT#'
,p_page_is_public_y_n=>'Y'
,p_protection_level=>'N'
,p_inline_css=>wwv_flow_string.join(wwv_flow_t_varchar2(
'.esign-badge { display: inline-block; padding: 2px 9px; border-radius: 999px; font-size: 11px; font-weight: 600; letter-spacing: .02em; background: #eef1f5; color: #4b5563; }',
'.esign-badge--SENT, .esign-badge--VIEWED { background: #e3edfb; color: #1c59b8; }',
'.esign-badge--SIGNED, .esign-badge--COMPLETED { background: #e2f4e8; color: #16713a; }',
'.esign-badge--DECLINED, .esign-badge--VOIDED { background: #fbe6e6; color: #b42318; }',
'.esign-badge--PENDING { background: #fdf3dc; color: #8a5a00; }',
'.js-esign-action[data-request=""] { display: none; }',
'.esign-hash { font-family: var(--a-base-font-family-mono, monospace); font-size: 11px; word-break: break-all; color: #6b7280; }',
'.esign-metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 12px; }',
'.esign-metric { border: 1px solid rgba(0,0,0,.08); border-radius: 8px; padding: 14px 16px; background: var(--ut-component-background-color, #fff); }',
'.esign-metric b { display: block; font-size: 26px; line-height: 1.1; }',
'.esign-metric span { color: #6b7280; font-size: 12px; }',
'.esign-code { font-family: var(--a-base-font-family-mono, monospace); font-size: 16px; letter-spacing: 3px; font-weight: 700; }',
'.esign-mail-link:not([href]), .esign-mail-link[href=""] { display: none; }',
'.esign-doc { max-width: 980px; margin: 0 auto; }',
'.esign-card h2 { margin: 0 0 4px; font-size: 22px; }',
'.esign-card p { margin: 4px 0; }',
'.esign-card .esign-note { border-left: 3px solid #cbd5e1; padding: 4px 10px; margin: 10px 0; color: #374151; white-space: pre-wrap; }',
'.esign-viewer { width: 100%; height: 72vh; min-height: 420px; border: 1px solid rgba(0,0,0,.12); border-radius: 6px; background: #f3f4f6; }',
'.esign-tabs { display: flex; gap: 6px; margin-bottom: 8px; }',
'.esign-tab { border: 1px solid rgba(0,0,0,.15); background: transparent; border-radius: 999px; padding: 4px 14px; cursor: pointer; font: inherit; }',
'.esign-tab.is-active { background: #1c59b8; border-color: #1c59b8; color: #fff; }',
'#esign-pad { position: relative; max-width: 620px; border: 1px dashed #94a3b8; border-radius: 8px; background: #fff; }',
'#esign-canvas { display: block; width: 100%; aspect-ratio: 620 / 190; touch-action: none; cursor: crosshair; }',
'#esign-pad.is-typed #esign-canvas { cursor: default; }',
'#esign-pad::after { content: ''Sign here''; position: absolute; left: 18px; bottom: 30px; color: #94a3b8; font-size: 13px; pointer-events: none; }',
'#esign-pad.is-inked::after, #esign-pad.is-typed::after { content: ''''; }',
'#esign-pad .esign-line { position: absolute; left: 16px; right: 16px; bottom: 26px; border-bottom: 1px solid #cbd5e1; pointer-events: none; }',
'.esign-pad-actions { display: flex; gap: 8px; margin-top: 12px; align-items: center; flex-wrap: wrap; }',
'.esign-done { text-align: center; padding: 24px 8px; }',
'.esign-done .fa { font-size: 48px; }',
'.esign-code { font-size: 22px; letter-spacing: 4px; font-weight: 700; }'))
,p_javascript_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'var esign = (function () {',
'    var canvas, ctx, drawing = false, last = null, inked = false, mode = ''DRAW'';',
'    var FONT = ''italic 58px "Segoe Script", "Brush Script MT", "Snell Roundhand", "URW Chancery L", cursive'';',
'',
'    function pos(e) {',
'        var r = canvas.getBoundingClientRect();',
'        return { x: (e.clientX - r.left) * canvas.width / r.width, y: (e.clientY - r.top) * canvas.height / r.height };',
'    }',
'    function clear() {',
'        ctx.clearRect(0, 0, canvas.width, canvas.height);',
'        inked = false;',
'        $(''#esign-pad'').removeClass(''is-inked'');',
'    }',
'    function drawTyped() {',
'        clear();',
'        var name = ($v(''P100_TYPED_NAME'') || '''').trim();',
'        if (!name) { return; }',
'        var size = 58;',
'        ctx.fillStyle = ''#14306e'';',
'        do { ctx.font = FONT.replace(''58px'', size + ''px''); size -= 2; }',
'        while (ctx.measureText(name).width > canvas.width - 40 && size > 18);',
'        ctx.textBaseline = ''middle'';',
'        ctx.fillText(name, 20, canvas.height / 2);',
'        inked = true;',
'        $(''#esign-pad'').addClass(''is-inked'');',
'    }',
'    function setMode(m) {',
'        mode = m;',
'        $(''.esign-tab'').removeClass(''is-active'').filter(''[data-mode="'' + m + ''"]'').addClass(''is-active'');',
'        $(''#P100_TYPED_NAME_CONTAINER'').toggle(m === ''TYPE'');',
'        $(''#esign-pad'').toggleClass(''is-typed'', m === ''TYPE'');',
'        if (m === ''TYPE'') { drawTyped(); apex.item(''P100_TYPED_NAME'').setFocus(); } else { clear(); }',
'    }',
'    // PNG of the inked area only, so the stamp is not mostly empty space',
'    function cropped() {',
'        var w = canvas.width, h = canvas.height, data = ctx.getImageData(0, 0, w, h).data;',
'        var x0 = w, y0 = h, x1 = 0, y1 = 0;',
'        for (var y = 0; y < h; y++) {',
'            for (var x = 0; x < w; x++) {',
'                if (data[(y * w + x) * 4 + 3] > 10) {',
'                    if (x < x0) { x0 = x; } if (x > x1) { x1 = x; } if (y < y0) { y0 = y; } if (y > y1) { y1 = y; }',
'                }',
'            }',
'        }',
'        var pad = 8; x0 = Math.max(0, x0 - pad); y0 = Math.max(0, y0 - pad);',
'        x1 = Math.min(w - 1, x1 + pad); y1 = Math.min(h - 1, y1 + pad);',
'        var out = document.createElement(''canvas'');',
'        out.width = x1 - x0 + 1; out.height = y1 - y0 + 1;',
'        out.getContext(''2d'').drawImage(canvas, x0, y0, out.width, out.height, 0, 0, out.width, out.height);',
'        return out.toDataURL(''image/png'');',
'    }',
'    function submit() {',
'        var errors = [];',
'        if ($v(''P100_CONSENT'') !== ''Y'') {',
'            errors.push({ type: ''error'', location: [''inline'', ''page''], pageItem: ''P100_CONSENT'',',
'                          message: ''Accept the electronic signature disclosure.'', unsafe: false });',
'        }',
'        if (!inked) {',
'            errors.push({ type: ''error'', location: ''page'', message: mode === ''TYPE'' ? ''Type your name.'' : ''Draw your signature in the box.'', unsafe: false });',
'        }',
'        apex.message.clearErrors();',
'        if (errors.length) { apex.message.showErrors(errors); return; }',
'        $s(''P100_SIGNATURE'', cropped());',
'        $s(''P100_METHOD'', mode === ''TYPE'' ? ''TYPED'' : ''DRAWN'');',
'        apex.page.submit({ request: ''SIGN'', showWait: true });',
'    }',
'    function init() {',
'        canvas = document.getElementById(''esign-canvas'');',
'        if (!canvas) { return; }',
'        ctx = canvas.getContext(''2d'');',
'        canvas.addEventListener(''pointerdown'', function (e) {',
'            if (mode !== ''DRAW'') { return; }',
'            drawing = true; last = pos(e);',
'            canvas.setPointerCapture(e.pointerId);',
'            e.preventDefault();',
'        });',
'        canvas.addEventListener(''pointermove'', function (e) {',
'            if (!drawing) { return; }',
'            var p = pos(e);',
'            ctx.strokeStyle = ''#14306e''; ctx.lineWidth = 3.4; ctx.lineCap = ''round''; ctx.lineJoin = ''round'';',
'            ctx.beginPath(); ctx.moveTo(last.x, last.y); ctx.lineTo(p.x, p.y); ctx.stroke();',
'            last = p; inked = true;',
'            $(''#esign-pad'').addClass(''is-inked'');',
'            e.preventDefault();',
'        });',
'        [''pointerup'', ''pointercancel'', ''pointerleave''].forEach(function (t) {',
'            canvas.addEventListener(t, function () { drawing = false; });',
'        });',
'        $(''.esign-tab'').on(''click'', function () { setMode(this.dataset.mode); });',
'        $(''#esign-clear'').on(''click'', function () { if (mode === ''TYPE'') { $s(''P100_TYPED_NAME'', ''''); } clear(); });',
'        $(''#P100_TYPED_NAME'').on(''input'', drawTyped);',
'        $(''#esign-sign'').on(''click'', submit);',
'        $(''#P100_TYPED_NAME_CONTAINER'').hide();',
'    }',
'    return { init: init };',
'})();'))
,p_javascript_code_onload=>'esign.init();'
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1123)
,p_plug_name=>'Envelope'
,p_static_id=>'envelope'
,p_title=>''
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody:t-Region--hideHeader js-addHiddenHeadingRoleDesc'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'ABOVE'
,p_function_body_language=>'PLSQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'declare',
'    l_html varchar2(32767);',
'begin',
'    if :P100_STEP = ''ERROR'' then',
'        return ''<div class="esign-card"><h2>This link can''''t be used</h2><p>'' || apex_escape.html(:P100_ERROR)',
'            || ''</p><p>Ask the sender for a new signing link.</p></div>'';',
'    end if;',
'    for r in (select d.title, d.message, d.created_by, d.envelope_id, d.status, s.signer_name',
'                from esign_signers s join esign_documents d on d.doc_id = s.doc_id',
'               where s.signer_id = :G_SIGNER_ID)',
'    loop',
'        l_html := ''<div class="esign-card"><p class="u-color-text-secondary">''',
'               || apex_escape.html(esign_pkg.setting(''ORG_NAME'')) || '' &middot; Envelope '' || r.envelope_id || ''</p>''',
'               || ''<h2>'' || apex_escape.html(r.title) || ''</h2>''',
'               || ''<p>'' || apex_escape.html(esign_pkg.sender_name(r.created_by)) || '' asks <b>'' || apex_escape.html(r.signer_name)',
'               || ''</b> to review and sign this document.</p>''',
'               || case when r.message is not null',
'                       then ''<div class="esign-note">'' || apex_escape.html(r.message) || ''</div>'' end',
'               || ''</div>'';',
'    end loop;',
'    return l_html;',
'end;'))
,p_lazy_loading=>false
,p_plug_source_type=>'NATIVE_DYNAMIC_CONTENT'
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1124)
,p_name=>'P100_TOKEN'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1123)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1125)
,p_name=>'P100_TOKEN_OK'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(1123)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1126)
,p_name=>'P100_STEP'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(1123)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1127)
,p_name=>'P100_ERROR'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(1123)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1128)
,p_name=>'P100_EMAIL_HINT'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_imp.id(1123)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1129)
,p_name=>'P100_PDF_URL'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_imp.id(1123)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1130)
,p_name=>'P100_SIGNATURE'
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_imp.id(1123)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1131)
,p_name=>'P100_METHOD'
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_imp.id(1123)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1132)
,p_plug_name=>'Verify Your Identity'
,p_static_id=>'verify-your-identity'
,p_title=>'Verify Your Identity'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>20
,p_plug_item_display_point=>'BELOW'
,p_plug_source=>'To protect this document, click <b>E-mail Me a Code</b>. We send a 6-digit code to <b>&P100_EMAIL_HINT.</b>; enter it below and click <b>Verify</b> to open the document.'
,p_plug_source_type=>'NATIVE_STATIC'
,p_plug_display_condition_type=>'VAL_OF_ITEM_IN_COND_EQ_COND2'
,p_plug_display_when_condition=>'P100_STEP'
,p_plug_display_when_cond2=>'VERIFY'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1133)
,p_plug_name=>'Development Code'
,p_static_id=>'development-code'
,p_title=>'Development mode'
,p_parent_plug_id=>wwv_flow_imp.id(1132)
,p_region_template_options=>'#DEFAULT#:t-Alert--horizontal:t-Alert--defaultIcons:t-Alert--warning'
,p_plug_template=>2042159785845301134
,p_plug_display_sequence=>5
,p_plug_item_display_point=>'ABOVE'
,p_plug_source=>'E-mail is not set up, so the code is shown here: <span class="esign-code">&P100_DEV_CODE.</span>'
,p_plug_source_type=>'NATIVE_STATIC'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P100_DEV_CODE'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1134)
,p_name=>'P100_DEV_CODE'
,p_item_sequence=>5
,p_item_plug_id=>wwv_flow_imp.id(1132)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1135)
,p_name=>'P100_CODE'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1132)
,p_prompt=>'One-time code'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'disabled', 'N',
'submit_when_enter_pressed', 'Y',
'subtype', 'TEXT',
'trim_spaces', 'BOTH')).to_clob
,p_cSize=>8
,p_cMaxlength=>6
,p_tag_attributes=>'autocomplete="one-time-code" inputmode="numeric"'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1136)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1132)
,p_button_name=>'SEND_CODE'
,p_static_id=>'send_code'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2084305881903810008
,p_button_image_alt=>'E-mail Me a Code'
,p_button_position=>'NEXT'
,p_button_execute_validations=>'N'
,p_icon_css_classes=>'fa-envelope-o'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1137)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(1132)
,p_button_name=>'VERIFY'
,p_static_id=>'verify'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Verify'
,p_button_position=>'NEXT'
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1138)
,p_plug_name=>'Review the Document'
,p_static_id=>'review-the-document'
,p_title=>'Review the Document'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>30
,p_plug_item_display_point=>'ABOVE'
,p_plug_source=>'<iframe class="esign-viewer" src="&P100_PDF_URL." title="Document to sign"></iframe><p><a href="&P100_PDF_URL." target="_blank" rel="noopener">Open the PDF in a new tab</a></p>'
,p_plug_source_type=>'NATIVE_STATIC'
,p_plug_display_condition_type=>'EXPRESSION'
,p_plug_display_when_condition=>':P100_STEP in (''SIGN'', ''DONE'')'
,p_plug_display_when_cond2=>'PLSQL'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1139)
,p_plug_name=>'Sign'
,p_static_id=>'sign'
,p_title=>'Adopt Your Signature'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>40
,p_plug_item_display_point=>'BELOW'
,p_plug_source=>'<div class="esign-tabs" role="tablist"><button type="button" class="esign-tab is-active" data-mode="DRAW">Draw</button><button type="button" class="esign-tab" data-mode="TYPE">Type</button></div><div id="esign-pad"><canvas id="esign-canvas" width="620" height="190" aria-label="Signature pad"></canvas><div class="esign-line"></div></div>'
,p_plug_source_type=>'NATIVE_STATIC'
,p_plug_display_condition_type=>'VAL_OF_ITEM_IN_COND_EQ_COND2'
,p_plug_display_when_condition=>'P100_STEP'
,p_plug_display_when_cond2=>'SIGN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1140)
,p_name=>'P100_TYPED_NAME'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1139)
,p_prompt=>'Type your full name'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'disabled', 'N',
'submit_when_enter_pressed', 'N',
'subtype', 'TEXT',
'trim_spaces', 'BOTH')).to_clob
,p_cSize=>40
,p_cMaxlength=>100
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1141)
,p_name=>'P100_CONSENT'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(1139)
,p_prompt=>'I agree to use electronic records and signatures for this document, and I intend my electronic signature to have the same legal effect as my handwritten signature.'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_SINGLE_CHECKBOX'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'use_defaults', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1142)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1139)
,p_button_name=>'CLEAR'
,p_static_id=>'clear'
,p_button_static_id=>'esign-clear'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_image_alt=>'Clear'
,p_button_position=>'PREVIOUS'
,p_button_execute_validations=>'N'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1143)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(1139)
,p_button_name=>'SIGN'
,p_static_id=>'sign'
,p_button_static_id=>'esign-sign'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2084305881903810008
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Adopt and Sign'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-pencil'
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1144)
,p_plug_name=>'Decline to Sign'
,p_static_id=>'decline-to-sign'
,p_title=>'Decline to Sign'
,p_region_template_options=>'#DEFAULT#:is-collapsed:t-Region--scrollBody'
,p_plug_template=>2665811232373458102
,p_plug_display_sequence=>50
,p_plug_item_display_point=>'ABOVE'
,p_plug_source_type=>'NATIVE_STATIC'
,p_plug_display_condition_type=>'VAL_OF_ITEM_IN_COND_EQ_COND2'
,p_plug_display_when_condition=>'P100_STEP'
,p_plug_display_when_cond2=>'SIGN'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1145)
,p_name=>'P100_DECLINE_REASON'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1144)
,p_prompt=>'Reason'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_TEXTAREA'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'auto_height', 'N',
'character_counter', 'N',
'resizable', 'Y',
'trim_spaces', 'BOTH')).to_clob
,p_cSize=>60
,p_cMaxlength=>4000
,p_cHeight=>3
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1146)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1144)
,p_button_name=>'DECLINE'
,p_static_id=>'decline'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--danger'
,p_button_template_id=>4073839297780169708
,p_button_image_alt=>'Decline'
,p_button_position=>'NEXT'
,p_button_execute_validations=>'N'
,p_confirm_message=>'Decline to sign? The sender is notified and the document is closed.'
,p_confirm_style=>'danger'
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1147)
,p_plug_name=>'Result'
,p_static_id=>'result'
,p_title=>''
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody:t-Region--hideHeader js-addHiddenHeadingRoleDesc'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>60
,p_plug_item_display_point=>'ABOVE'
,p_function_body_language=>'PLSQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'declare',
'    l_doc_status esign_documents.status%type;',
'    l_signed     esign_signers.signed_on%type;',
'begin',
'    select d.status, s.signed_on into l_doc_status, l_signed',
'      from esign_signers s join esign_documents d on d.doc_id = s.doc_id',
'     where s.signer_id = :G_SIGNER_ID;',
'    return case :P100_STEP',
'        when ''DONE'' then ''<div class="esign-done"><span class="fa fa-check-circle u-success-text"></span><h2>You signed this document</h2><p>''',
'                      || esign_pkg.utc(l_signed) || ''</p><p>''',
'                      || case when l_doc_status = ''COMPLETED''',
'                              then ''All parties have signed. The completed PDF above is digitally sealed; a copy was e-mailed to you.''',
'                              else ''We will e-mail you the completed PDF when everyone has signed.'' end || ''</p></div>''',
'        when ''DECLINED'' then ''<div class="esign-done"><span class="fa fa-times-circle u-danger-text"></span><h2>This document was declined</h2><p>The sender has been notified.</p></div>''',
'        when ''VOIDED'' then ''<div class="esign-done"><span class="fa fa-ban u-danger-text"></span><h2>The sender voided this document</h2><p>It can no longer be signed.</p></div>''',
'        when ''WAIT'' then ''<div class="esign-done"><span class="fa fa-clock-o"></span><h2>Not your turn yet</h2><p>We will e-mail you when the earlier signers are done.</p></div>''',
'    end;',
'exception when no_data_found then',
'    return null;',
'end;'))
,p_lazy_loading=>false
,p_plug_source_type=>'NATIVE_DYNAMIC_CONTENT'
,p_plug_display_condition_type=>'EXPRESSION'
,p_plug_display_when_condition=>':P100_STEP in (''DONE'', ''DECLINED'', ''VOIDED'', ''WAIT'')'
,p_plug_display_when_cond2=>'PLSQL'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1148)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Prepare'
,p_static_id=>'prepare'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'declare',
'    l_signer_status esign_signers.status%type;',
'    l_doc_status    esign_documents.status%type;',
'    l_email         esign_signers.signer_email%type;',
'begin',
'    :P100_ERROR := null;',
'    -- a new token in the URL: find its signer',
'    if :P100_TOKEN is not null and (:P100_TOKEN_OK is null or :P100_TOKEN_OK <> :P100_TOKEN) then',
'        begin',
'            :G_SIGNER_ID   := esign_pkg.signer_for_token(:P100_TOKEN);',
'            :P100_TOKEN_OK := :P100_TOKEN;',
'            :G_OTP_OK      := null;',
'            :P100_DEV_CODE := null;',
'        exception when others then',
'            :G_SIGNER_ID   := null;',
'            :P100_TOKEN_OK := null;',
'            :P100_ERROR    := regexp_replace(sqlerrm, ''^ORA-\d+: '');',
'        end;',
'    end if;',
'    if :G_SIGNER_ID is null then',
'        :P100_STEP  := ''ERROR'';',
'        :P100_ERROR := nvl(:P100_ERROR, ''Open the signing link from your e-mail.'');',
'        return;',
'    end if;',
'    select s.status, d.status, s.signer_email',
'      into l_signer_status, l_doc_status, l_email',
'      from esign_signers s join esign_documents d on d.doc_id = s.doc_id',
'     where s.signer_id = :G_SIGNER_ID;',
'    :P100_EMAIL_HINT := substr(l_email, 1, 2) || ''***'' || substr(l_email, instr(l_email, ''@''));',
'    :P100_PDF_URL    := apex_page.get_url(p_page => 101);',
'    :P100_STEP := case',
'                      when l_signer_status = ''SIGNED''                              then ''DONE''',
'                      when l_signer_status = ''DECLINED'' or l_doc_status = ''DECLINED'' then ''DECLINED''',
'                      when l_doc_status = ''VOIDED''                                   then ''VOIDED''',
'                      when l_signer_status = ''PENDING''                               then ''WAIT''',
'                      when :G_OTP_OK = to_char(:G_SIGNER_ID)                         then ''SIGN''',
'                      else ''VERIFY''',
'                  end;',
'end;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1149)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Send Code'
,p_static_id=>'send-code'
,p_process_sql_clob=>':P100_DEV_CODE := esign_pkg.send_otp(:G_SIGNER_ID);'
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'SEND_CODE'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'We sent a 6-digit code to &P100_EMAIL_HINT.'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1150)
,p_process_sequence=>20
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Verify Code'
,p_static_id=>'verify-code'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'esign_pkg.verify_otp(:G_SIGNER_ID, :P100_CODE);',
':G_OTP_OK      := :G_SIGNER_ID;',
':P100_DEV_CODE := null;',
':P100_CODE     := null;',
'esign_pkg.mark_viewed(:G_SIGNER_ID);'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'VERIFY'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'Thank you. Review the document and sign below.'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1151)
,p_process_sequence=>30
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Sign'
,p_static_id=>'sign'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'if :G_SIGNER_ID is null or nvl(:G_OTP_OK, ''-'') <> to_char(:G_SIGNER_ID) then',
'    raise_application_error(-20001, ''Verify your identity with a one-time code first.'');',
'end if;',
'esign_pkg.sign(',
'    p_signer_id     => :G_SIGNER_ID,',
'    p_signature_png => :P100_SIGNATURE,',
'    p_method        => :P100_METHOD,',
'    p_consent       => :P100_CONSENT);',
':P100_SIGNATURE := null;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'SIGN'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'Your signature was recorded.'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1152)
,p_process_sequence=>40
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Decline'
,p_static_id=>'decline'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'if :G_SIGNER_ID is null or nvl(:G_OTP_OK, ''-'') <> to_char(:G_SIGNER_ID) then',
'    raise_application_error(-20001, ''Verify your identity with a one-time code first.'');',
'end if;',
'esign_pkg.decline(:G_SIGNER_ID, :P100_DECLINE_REASON);'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'DECLINE'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'You declined to sign. The sender has been notified.'
);
wwv_flow_imp_page.create_page_branch(
p_id=>wwv_flow_imp.id(1153)
,p_branch_action=>'f?p=&APP_ID.:100:&APP_SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_sequence=>10
);
end;
/
prompt --application/pages/page_00101
begin
wwv_flow_imp_page.create_page(
p_id=>101
,p_name=>'Document PDF'
,p_alias=>'PDF'
,p_step_title=>'Document PDF'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>2980551703278319811
,p_page_template_options=>'#DEFAULT#'
,p_page_is_public_y_n=>'Y'
,p_protection_level=>'U'
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1154)
,p_plug_name=>'PDF'
,p_static_id=>'pdf'
,p_title=>'PDF'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'ABOVE'
,p_plug_source=>'The document can only be opened after verifying your identity.'
,p_plug_source_type=>'NATIVE_STATIC'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1155)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Show PDF'
,p_static_id=>'show-pdf'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'if :G_SIGNER_ID is not null and :G_OTP_OK = to_char(:G_SIGNER_ID) then',
'    esign_pkg.view_pdf(:G_SIGNER_ID);',
'    apex_application.stop_apex_engine;',
'end if;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
end;
/
prompt --application/pages/page_00110
begin
wwv_flow_imp_page.create_page(
p_id=>110
,p_name=>'Verify a PDF'
,p_alias=>'VERIFY'
,p_step_title=>'Verify a PDF'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>2980551703278319811
,p_page_template_options=>'#DEFAULT#'
,p_page_is_public_y_n=>'Y'
,p_protection_level=>'C'
,p_inline_css=>wwv_flow_string.join(wwv_flow_t_varchar2(
'.esign-badge { display: inline-block; padding: 2px 9px; border-radius: 999px; font-size: 11px; font-weight: 600; letter-spacing: .02em; background: #eef1f5; color: #4b5563; }',
'.esign-badge--SENT, .esign-badge--VIEWED { background: #e3edfb; color: #1c59b8; }',
'.esign-badge--SIGNED, .esign-badge--COMPLETED { background: #e2f4e8; color: #16713a; }',
'.esign-badge--DECLINED, .esign-badge--VOIDED { background: #fbe6e6; color: #b42318; }',
'.esign-badge--PENDING { background: #fdf3dc; color: #8a5a00; }',
'.js-esign-action[data-request=""] { display: none; }',
'.esign-hash { font-family: var(--a-base-font-family-mono, monospace); font-size: 11px; word-break: break-all; color: #6b7280; }',
'.esign-metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 12px; }',
'.esign-metric { border: 1px solid rgba(0,0,0,.08); border-radius: 8px; padding: 14px 16px; background: var(--ut-component-background-color, #fff); }',
'.esign-metric b { display: block; font-size: 26px; line-height: 1.1; }',
'.esign-metric span { color: #6b7280; font-size: 12px; }',
'.esign-code { font-family: var(--a-base-font-family-mono, monospace); font-size: 16px; letter-spacing: 3px; font-weight: 700; }',
'.esign-mail-link:not([href]), .esign-mail-link[href=""] { display: none; }',
'.esign-verify { display: flex; gap: 14px; align-items: flex-start; padding: 16px; border-radius: 8px; border: 1px solid; }',
'.esign-verify > .fa { font-size: 32px; }',
'.esign-verify h3 { margin: 0 0 6px; }',
'.esign-verify--ok { border-color: #9bd3ae; background: #f0faf3; } .esign-verify--ok > .fa { color: #16713a; }',
'.esign-verify--info { border-color: #a9c4ee; background: #f1f6fd; } .esign-verify--info > .fa { color: #1c59b8; }',
'.esign-verify--bad { border-color: #f0a8a3; background: #fdf2f1; } .esign-verify--bad > .fa { color: #b42318; }'))
,p_javascript_code_onload=>wwv_flow_string.join(wwv_flow_t_varchar2(
'// SHA-256 of the chosen PDF, computed in the browser (Web Crypto)',
'$(''#esign-verify'').on(''click'', async function () {',
'    var file = document.getElementById(''esign-verify-file'').files[0];',
'    apex.message.clearErrors();',
'    if (!file) {',
'        apex.message.showErrors([{ type: ''error'', location: ''page'', message: ''Choose the PDF to verify.'', unsafe: false }]);',
'        return;',
'    }',
'    var digest = await crypto.subtle.digest(''SHA-256'', await file.arrayBuffer());',
'    var hex = Array.from(new Uint8Array(digest)).map(function (b) { return b.toString(16).padStart(2, ''0''); }).join('''');',
'    $s(''P110_SHA256'', hex);',
'    $s(''P110_FILE_NAME'', file.name);',
'    apex.page.submit({ request: ''VERIFY'', showWait: true });',
'});'))
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1156)
,p_plug_name=>'Verify a Signed PDF'
,p_static_id=>'verify-a-signed-pdf'
,p_title=>'Verify a Signed PDF'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'BELOW'
,p_plug_source=>'<p>Choose a PDF to check whether it is a document completed and sealed by this system, and that not a single byte has changed since. The file stays on your computer: only its SHA-256 fingerprint is sent.</p><input type="file" id="esign-verify-file" accept=".pdf,application/pdf" class="apex-item-text"><p id="esign-verify-name" class="esign-hash"></p>'
,p_plug_source_type=>'NATIVE_STATIC'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1157)
,p_name=>'P110_SHA256'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1156)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1158)
,p_name=>'P110_FILE_NAME'
,p_item_sequence=>15
,p_item_plug_id=>wwv_flow_imp.id(1156)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1159)
,p_name=>'P110_RESULT'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(1156)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'based_on', 'VALUE',
'format', 'HTML',
'send_on_page_submit', 'N',
'show_line_breaks', 'N')).to_clob
,p_display_when=>'P110_RESULT'
,p_display_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1160)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1156)
,p_button_name=>'VERIFY'
,p_static_id=>'verify'
,p_button_static_id=>'esign-verify'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2084305881903810008
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Verify'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-shield-check'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1161)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Verify File'
,p_static_id=>'verify-file'
,p_process_sql_clob=>':P110_RESULT := esign_pkg.verify_hash(:P110_SHA256, :P110_FILE_NAME);'
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'VERIFY'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
);
wwv_flow_imp_page.create_page_branch(
p_id=>wwv_flow_imp.id(1162)
,p_branch_action=>'f?p=&APP_ID.:110:&APP_SESSION.::&DEBUG.:::'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_sequence=>10
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
