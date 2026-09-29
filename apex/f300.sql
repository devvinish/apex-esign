prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
-- ESign Lab: part of ESign Lab, electronic signatures for PDF documents with Oracle APEX 26.1
-- Parsing schema: ESIGN. Install the database objects first (see README.md).
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.0'
,p_default_workspace_id=>6400317681717819
,p_default_application_id=>300
,p_default_id_offset=>0
,p_default_owner=>'ESIGN'
);
end;
/
prompt APPLICATION 300 - ESign Lab
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
,p_name=>nvl(wwv_flow_application_install.get_application_name,'ESign Lab')
,p_alias=>nvl(wwv_flow_application_install.get_application_alias,'ESIGN')
,p_page_view_logging=>'YES'
,p_page_protection_enabled_y_n=>'Y'
,p_checksum_salt=>'9C1F0E7A3B5D48C2A6E1F90B7D3C5A18E4F2B6D09A7C3E5F1B8D2A4C6E0F9B7D'
,p_bookmark_checksum_function=>'SH512'
,p_compatibility_mode=>'26.1'
,p_flow_language=>'en'
,p_flow_language_derived_from=>'FLOW_PRIMARY_LANGUAGE'
,p_date_format=>'DD-MON-YYYY'
,p_timestamp_format=>'DD-MON-YYYY HH24:MI'
,p_timestamp_tz_format=>'DD-MON-YYYY HH24:MI TZR'
,p_flow_image_prefix=>nvl(wwv_flow_application_install.get_image_prefix,'')
,p_authentication_id=>wwv_flow_imp.id(1001)
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
,p_home_url=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:::'
,p_login_url=>'f?p=&APP_ID.:LOGIN:&APP_SESSION.::&DEBUG.:::'
,p_theme_style_by_user_pref=>false
,p_built_with_love=>false
,p_global_page_id=>0
,p_navigation_list_id=>wwv_flow_imp.id(1002)
,p_navigation_list_position=>'SIDE'
,p_navigation_list_template_id=>2469215554099805162
,p_nav_list_template_options=>'#DEFAULT#:js-navCollapsed--hidden:t-TreeNav--styleA'
,p_nav_bar_type=>'LIST'
,p_nav_bar_list_id=>wwv_flow_imp.id(1003)
,p_nav_bar_list_template_id=>2849019392706229583
,p_nav_bar_template_options=>'#DEFAULT#'
,p_error_handling_function=>'esign_pkg.apex_error_handler'
);
end;
/
prompt --application/shared_components/navigation/lists/navigation_menu
begin
wwv_flow_imp_shared.create_list(
p_id=>wwv_flow_imp.id(1002)
,p_name=>'Navigation Menu'
,p_static_id=>'navigation-menu'
);
wwv_flow_imp_shared.create_list_item(
p_id=>wwv_flow_imp.id(1005)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Documents'
,p_static_id=>'documents'
,p_list_item_link_target=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:::'
,p_list_item_icon=>'fa-files-o'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'1'
);
wwv_flow_imp_shared.create_list_item(
p_id=>wwv_flow_imp.id(1006)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'New Document'
,p_static_id=>'new-document'
,p_list_item_link_target=>'f?p=&APP_ID.:2:&APP_SESSION.::&DEBUG.:RP,2::'
,p_list_item_icon=>'fa-file-signature'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'2'
);
wwv_flow_imp_shared.create_list_item(
p_id=>wwv_flow_imp.id(1007)
,p_list_item_display_sequence=>30
,p_list_item_link_text=>'Demo Mailbox'
,p_static_id=>'demo-mailbox'
,p_list_item_link_target=>'f?p=&APP_ID.:5:&APP_SESSION.::&DEBUG.:::'
,p_list_item_icon=>'fa-inbox'
,p_list_item_disp_cond_type=>'EXPRESSION'
,p_list_item_disp_condition=>'esign_pkg.setting(''DEV_MODE'') = ''Y'''
,p_list_item_disp_condition2=>'PLSQL'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'5'
);
wwv_flow_imp_shared.create_list_item(
p_id=>wwv_flow_imp.id(1008)
,p_list_item_display_sequence=>40
,p_list_item_link_text=>'Verify a PDF'
,p_static_id=>'verify-a-pdf'
,p_list_item_link_target=>'f?p=ESIGN-SIGN:VERIFY:0::::'
,p_list_item_icon=>'fa-shield-check'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'-'
);
end;
/
prompt --application/shared_components/navigation/lists/navigation_bar
begin
wwv_flow_imp_shared.create_list(
p_id=>wwv_flow_imp.id(1003)
,p_name=>'Navigation Bar'
,p_static_id=>'navigation-bar'
);
wwv_flow_imp_shared.create_list_item(
p_id=>wwv_flow_imp.id(1009)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'&APP_USER.'
,p_static_id=>'app-user'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-user'
,p_list_item_disp_cond_type=>'USER_IS_NOT_PUBLIC_USER'
,p_list_text_02=>'has-username'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_imp_shared.create_list_item(
p_id=>wwv_flow_imp.id(1010)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Sign Out'
,p_static_id=>'sign-out'
,p_list_item_link_target=>'&LOGOUT_URL.'
,p_list_item_icon=>'fa-sign-out'
,p_list_item_disp_cond_type=>'USER_IS_NOT_PUBLIC_USER'
,p_parent_list_item_id=>wwv_flow_imp.id(1009)
,p_list_item_current_type=>'TARGET_PAGE'
);
end;
/
prompt --application/shared_components/security/authentications/oracle_apex_accounts
begin
wwv_flow_imp_shared.create_authentication(
p_id=>wwv_flow_imp.id(1001)
,p_name=>'Oracle APEX Accounts'
,p_static_id=>'oracle-apex-accounts'
,p_scheme_type=>'NATIVE_APEX_ACCOUNTS'
,p_invalid_session_type=>'LOGIN'
,p_use_secure_cookie_yn=>'N'
,p_ras_mode=>0
);
end;
/
prompt --application/shared_components/user_interface/themes
begin
wwv_flow_imp_shared.create_theme(
    p_id=>wwv_flow_imp.id(1004)
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
prompt --application/pages/page_00001
begin
wwv_flow_imp_page.create_page(
p_id=>1
,p_name=>'Documents'
,p_alias=>'HOME'
,p_step_title=>'Documents'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>4073832297226169690
,p_page_template_options=>'#DEFAULT#'
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
'.esign-mail-link:not([href]), .esign-mail-link[href=""] { display: none; }'))
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1011)
,p_plug_name=>'Documents'
,p_static_id=>'documents'
,p_title=>'Documents'
,p_region_template_options=>'#DEFAULT#:t-HeroRegion--hideIcon'
,p_plug_template=>2675494171183407654
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_01'
,p_plug_item_display_point=>'ABOVE'
,p_plug_source=>'Send PDF documents for electronic signature, follow their progress, and download the digitally sealed copies. Every step is recorded in a tamper-evident audit trail.'
,p_plug_source_type=>'NATIVE_STATIC'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1012)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1011)
,p_button_name=>'NEW'
,p_static_id=>'new'
,p_button_action=>'REDIRECT_URL'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2084305881903810008
,p_button_is_hot=>'Y'
,p_button_image_alt=>'New Document'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:2:&APP_SESSION.::&DEBUG.:RP,2::'
,p_icon_css_classes=>'fa-plus'
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1013)
,p_plug_name=>'Summary'
,p_static_id=>'summary'
,p_title=>''
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4502917002193490937
,p_plug_display_sequence=>20
,p_plug_item_display_point=>'ABOVE'
,p_function_body_language=>'PLSQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'declare',
'    l_html varchar2(4000);',
'begin',
'    for r in (select count(case when status = ''DRAFT'' then 1 end)                    as drafts,',
'                     count(case when status = ''SENT'' then 1 end)                     as waiting,',
'                     count(case when status = ''COMPLETED'' then 1 end)                as completed,',
'                     count(case when status in (''DECLINED'', ''VOIDED'') then 1 end)    as stopped',
'                from esign_documents',
'               where upper(created_by) = upper(:APP_USER))',
'    loop',
'        l_html := ''<div class="esign-metrics">''',
'               || ''<div class="esign-metric"><b>'' || r.drafts    || ''</b><span>Drafts</span></div>''',
'               || ''<div class="esign-metric"><b>'' || r.waiting   || ''</b><span>Waiting for signatures</span></div>''',
'               || ''<div class="esign-metric"><b>'' || r.completed || ''</b><span>Completed</span></div>''',
'               || ''<div class="esign-metric"><b>'' || r.stopped   || ''</b><span>Declined or voided</span></div>''',
'               || ''</div>'';',
'    end loop;',
'    return l_html;',
'end;'))
,p_lazy_loading=>false
,p_plug_source_type=>'NATIVE_DYNAMIC_CONTENT'
);
wwv_flow_imp_page.create_report_region(
p_id=>wwv_flow_imp.id(1014)
,p_name=>'Envelopes'
,p_static_id=>'envelopes'
,p_title=>'Envelopes'
,p_template=>4073835273271169698
,p_display_sequence=>30
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_component_template_options=>'#DEFAULT#:t-Report--stretch:t-Report--staticRowColors:t-Report--rowHighlight:t-Report--inline:t-Report--hideNoPagination'
,p_source_type=>'NATIVE_SQL_REPORT'
,p_query_type=>'SQL'
,p_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select doc_id,',
'       title,',
'       status,',
'       initcap(status) as status_label,',
'       signed || '' of '' || signers as progress,',
'       envelope_id,',
'       created_by,',
'       created_on,',
'       sent_on,',
'       completed_on',
'  from esign_documents_v',
' where upper(created_by) = upper(:APP_USER)',
' order by created_on desc'))
,p_ajax_enabled=>'Y'
,p_lazy_loading=>false
,p_query_row_template=>2540130677583398057
,p_query_num_rows=>25
,p_query_options=>'DERIVED_REPORT_COLUMNS'
,p_query_no_data_found=>'No documents yet. Click New Document to send your first PDF for signature.'
,p_query_num_rows_type=>'ROW_RANGES_WITH_LINKS'
,p_pagination_display_position=>'BOTTOM_RIGHT'
,p_csv_output=>'N'
,p_prn_output=>'N'
,p_sort_null=>'L'
,p_plug_query_strip_html=>'N'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1015)
,p_query_column_id=>1
,p_column_alias=>'DOC_ID'
,p_column_display_sequence=>1
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1016)
,p_query_column_id=>2
,p_column_alias=>'TITLE'
,p_column_display_sequence=>2
,p_column_heading=>'Document'
,p_column_link=>'f?p=&APP_ID.:2:&SESSION.::&DEBUG.:RP,2:P2_DOC_ID:#DOC_ID#'
,p_column_linktext=>'#TITLE#'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1017)
,p_query_column_id=>3
,p_column_alias=>'STATUS'
,p_column_display_sequence=>3
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1018)
,p_query_column_id=>4
,p_column_alias=>'STATUS_LABEL'
,p_column_display_sequence=>4
,p_column_heading=>'Status'
,p_column_html_expression=>'<span class="esign-badge esign-badge--#STATUS#">#STATUS_LABEL#</span>'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1019)
,p_query_column_id=>5
,p_column_alias=>'PROGRESS'
,p_column_display_sequence=>5
,p_column_heading=>'Signed'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1020)
,p_query_column_id=>6
,p_column_alias=>'ENVELOPE_ID'
,p_column_display_sequence=>6
,p_column_heading=>'Envelope ID'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1021)
,p_query_column_id=>7
,p_column_alias=>'CREATED_BY'
,p_column_display_sequence=>7
,p_column_heading=>'Sender'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1022)
,p_query_column_id=>8
,p_column_alias=>'CREATED_ON'
,p_column_display_sequence=>8
,p_column_heading=>'Created'
,p_column_format=>'SINCE'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1023)
,p_query_column_id=>9
,p_column_alias=>'SENT_ON'
,p_column_display_sequence=>9
,p_column_heading=>'Sent'
,p_column_format=>'SINCE'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1024)
,p_query_column_id=>10
,p_column_alias=>'COMPLETED_ON'
,p_column_display_sequence=>10
,p_column_heading=>'Completed'
,p_column_format=>'SINCE'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
end;
/
prompt --application/pages/page_00002
begin
wwv_flow_imp_page.create_page(
p_id=>2
,p_name=>'Document'
,p_alias=>'DOCUMENT'
,p_step_title=>'Document'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>4073832297226169690
,p_page_template_options=>'#DEFAULT#'
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
'.esign-links .t-Form-itemText, .esign-links .display_only { font-family: var(--a-base-font-family-mono, monospace); font-size: 12px; word-break: break-all; }'))
,p_javascript_code_onload=>wwv_flow_string.join(wwv_flow_t_varchar2(
'// Remove signer / new signing link buttons in the Signers report',
'$(document).on(''click'', ''.js-esign-action'', function () {',
'    var request = this.dataset.request, id = this.dataset.id;',
'    var go = function () { apex.page.submit({ request: request, set: { P2_SIGNER_ID: id }, showWait: true }); };',
'    if (request === ''REMOVE_SIGNER'') {',
'        apex.message.confirm(''Remove this signer?'', function (ok) { if (ok) { go(); } });',
'    } else {',
'        apex.message.confirm(''Create a new signing link? The previous link stops working.'', function (ok) { if (ok) { go(); } });',
'    }',
'});'))
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1025)
,p_plug_name=>'Document Header'
,p_static_id=>'document-header'
,p_title=>'&P2_HEADING.'
,p_region_template_options=>'#DEFAULT#:t-HeroRegion--hideIcon'
,p_plug_template=>2675494171183407654
,p_plug_display_sequence=>5
,p_plug_display_point=>'REGION_POSITION_01'
,p_plug_item_display_point=>'ABOVE'
,p_plug_source=>'&P2_SUBHEADING!RAW.'
,p_plug_source_type=>'NATIVE_STATIC'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1026)
,p_plug_name=>'Envelope'
,p_static_id=>'envelope'
,p_title=>'Envelope'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'ABOVE'
,p_plug_source_type=>'NATIVE_STATIC'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1027)
,p_name=>'P2_DOC_ID'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1026)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1028)
,p_name=>'P2_STATUS'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(1026)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1029)
,p_name=>'P2_SIGNER_ID'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(1026)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1030)
,p_name=>'P2_HEADING'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(1026)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1031)
,p_name=>'P2_SUBHEADING'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_imp.id(1026)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1032)
,p_name=>'P2_TITLE'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_imp.id(1026)
,p_prompt=>'Document title'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598484065263269
,p_item_template_options=>'#DEFAULT#'
,p_is_required=>true
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'disabled', 'N',
'submit_when_enter_pressed', 'N',
'subtype', 'TEXT',
'trim_spaces', 'BOTH')).to_clob
,p_cSize=>60
,p_cMaxlength=>200
,p_read_only_when=>':P2_STATUS is not null and :P2_STATUS <> ''DRAFT'''
,p_read_only_when2=>'PLSQL'
,p_read_only_when_type=>'EXPRESSION'
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1033)
,p_name=>'P2_MESSAGE'
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_imp.id(1026)
,p_prompt=>'Message to signers'
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
,p_read_only_when=>':P2_STATUS is not null and :P2_STATUS <> ''DRAFT'''
,p_read_only_when2=>'PLSQL'
,p_read_only_when_type=>'EXPRESSION'
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1034)
,p_name=>'P2_ROUTING'
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_imp.id(1026)
,p_prompt=>'Signing order'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'page_action_on_selection', 'NONE')).to_clob
,p_lov=>'STATIC2:One after another (in signing order);SEQUENTIAL,All at the same time;PARALLEL'
,p_lov_display_null=>'NO'
,p_cHeight=>1
,p_item_default=>'SEQUENTIAL'
,p_lov_display_extra=>'NO'
,p_read_only_when=>':P2_STATUS is not null and :P2_STATUS <> ''DRAFT'''
,p_read_only_when2=>'PLSQL'
,p_read_only_when_type=>'EXPRESSION'
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1035)
,p_name=>'P2_FILE'
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_imp.id(1026)
,p_prompt=>'PDF to sign'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_FILE'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'allow_copy_paste', 'N',
'allow_multiple_files', 'N',
'display_as', 'DROPZONE_BLOCK',
'dropzone_description', 'PDF, up to 20 MB. A new file replaces the current one.',
'file_types', '.pdf,application/pdf',
'max_file_size', '20480',
'purge_file_at', 'REQUEST',
'storage_type', 'APEX_APPLICATION_TEMP_FILES')).to_clob
,p_display_when=>':P2_DOC_ID is null or :P2_STATUS = ''DRAFT'''
,p_display_when2=>'PLSQL'
,p_display_when_type=>'EXPRESSION'
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1036)
,p_name=>'P2_FILE_INFO'
,p_item_sequence=>100
,p_item_plug_id=>wwv_flow_imp.id(1026)
,p_prompt=>'Current file'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'based_on', 'VALUE',
'format', 'HTML',
'send_on_page_submit', 'N',
'show_line_breaks', 'N')).to_clob
,p_display_when=>'P2_DOC_ID'
,p_display_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1037)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1026)
,p_button_name=>'BACK'
,p_static_id=>'back'
,p_button_action=>'REDIRECT_URL'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_image_alt=>'Back'
,p_button_position=>'PREVIOUS'
,p_button_redirect_url=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:::'
,p_button_execute_validations=>'N'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1038)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(1026)
,p_button_name=>'CREATE'
,p_static_id=>'create'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Create and Add Signers'
,p_button_position=>'NEXT'
,p_button_condition=>'P2_DOC_ID'
,p_button_condition_type=>'ITEM_IS_NULL'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1039)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_imp.id(1026)
,p_button_name=>'SAVE'
,p_static_id=>'save'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_image_alt=>'Save'
,p_button_position=>'NEXT'
,p_button_condition=>':P2_DOC_ID is not null and :P2_STATUS = ''DRAFT'''
,p_button_condition2=>'PLSQL'
,p_button_condition_type=>'EXPRESSION'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1040)
,p_button_sequence=>40
,p_button_plug_id=>wwv_flow_imp.id(1026)
,p_button_name=>'SEND'
,p_static_id=>'send'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2084305881903810008
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Send for Signature'
,p_button_position=>'NEXT'
,p_confirm_message=>'Send this document to the signers now? After sending, the document and signers can no longer be changed.'
,p_icon_css_classes=>'fa-send'
,p_button_condition=>':P2_DOC_ID is not null and :P2_STATUS = ''DRAFT'''
,p_button_condition2=>'PLSQL'
,p_button_condition_type=>'EXPRESSION'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1041)
,p_button_sequence=>50
,p_button_plug_id=>wwv_flow_imp.id(1026)
,p_button_name=>'DOWNLOAD_ORIGINAL'
,p_static_id=>'download_original'
,p_button_action=>'REDIRECT_URL'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2084305881903810008
,p_button_image_alt=>'Original PDF'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:3:&APP_SESSION.::&DEBUG.::P3_DOC_ID,P3_WHICH:&P2_DOC_ID.,ORIGINAL'
,p_button_execute_validations=>'N'
,p_icon_css_classes=>'fa-download'
,p_button_condition=>'P2_DOC_ID'
,p_button_condition_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1042)
,p_button_sequence=>60
,p_button_plug_id=>wwv_flow_imp.id(1026)
,p_button_name=>'DOWNLOAD_SIGNED'
,p_static_id=>'download_signed'
,p_button_action=>'REDIRECT_URL'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2084305881903810008
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Signed PDF'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:3:&APP_SESSION.::&DEBUG.::P3_DOC_ID,P3_WHICH:&P2_DOC_ID.,SIGNED'
,p_button_execute_validations=>'N'
,p_icon_css_classes=>'fa-file-pdf-o'
,p_button_condition=>'P2_STATUS'
,p_button_condition2=>'COMPLETED'
,p_button_condition_type=>'VAL_OF_ITEM_IN_COND_EQ_COND2'
);
wwv_flow_imp_page.create_report_region(
p_id=>wwv_flow_imp.id(1043)
,p_name=>'Demo Mailbox'
,p_static_id=>'demo-mailbox'
,p_title=>'Demo Mailbox'
,p_template=>4073835273271169698
,p_display_sequence=>22
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_component_template_options=>'#DEFAULT#:t-Report--stretch:t-Report--staticRowColors:t-Report--rowHighlight:t-Report--inline:t-Report--hideNoPagination'
,p_source_type=>'NATIVE_SQL_REPORT'
,p_query_type=>'SQL'
,p_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select m.mail_id,',
'       to_char(m.created_on at time zone ''UTC'', ''HH24:MI:SS'') as sent_at,',
'       m.to_email,',
'       m.subject,',
'       m.link_url,',
'       case when m.link_url is not null then ''Open signing page'' end as link_label,',
'       m.otp_code,',
'       case when m.has_attachment = ''Y'' then ''signed PDF attached'' end as attachment',
'  from esign_dev_outbox m',
' where m.doc_id = :P2_DOC_ID',
' order by m.mail_id desc'))
,p_ajax_enabled=>'Y'
,p_ajax_items_to_submit=>'P2_DOC_ID'
,p_lazy_loading=>false
,p_query_row_template=>2540130677583398057
,p_query_num_rows=>20
,p_query_options=>'DERIVED_REPORT_COLUMNS'
,p_query_no_data_found=>'No e-mails yet. Send the document to see the invitations here.'
,p_query_num_rows_type=>'ROW_RANGES_WITH_LINKS'
,p_pagination_display_position=>'BOTTOM_RIGHT'
,p_csv_output=>'N'
,p_prn_output=>'N'
,p_sort_null=>'L'
,p_plug_query_strip_html=>'N'
,p_display_condition_type=>'EXPRESSION'
,p_display_when_condition=>':P2_DOC_ID is not null and esign_pkg.setting(''DEV_MODE'') = ''Y'''
,p_display_when_cond2=>'PLSQL'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1044)
,p_query_column_id=>1
,p_column_alias=>'MAIL_ID'
,p_column_display_sequence=>1
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1045)
,p_query_column_id=>2
,p_column_alias=>'SENT_AT'
,p_column_display_sequence=>2
,p_column_heading=>'Time (UTC)'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1046)
,p_query_column_id=>3
,p_column_alias=>'TO_EMAIL'
,p_column_display_sequence=>3
,p_column_heading=>'To'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1047)
,p_query_column_id=>4
,p_column_alias=>'SUBJECT'
,p_column_display_sequence=>4
,p_column_heading=>'Subject'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1048)
,p_query_column_id=>5
,p_column_alias=>'LINK_URL'
,p_column_display_sequence=>5
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1049)
,p_query_column_id=>6
,p_column_alias=>'LINK_LABEL'
,p_column_display_sequence=>6
,p_column_heading=>'Signing link'
,p_column_html_expression=>'<a href="#LINK_URL#" target="_blank" rel="noopener" class="esign-mail-link">#LINK_LABEL#</a>'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1050)
,p_query_column_id=>7
,p_column_alias=>'OTP_CODE'
,p_column_display_sequence=>7
,p_column_heading=>'One-time code'
,p_column_html_expression=>'<span class="esign-code">#OTP_CODE#</span>'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1051)
,p_query_column_id=>8
,p_column_alias=>'ATTACHMENT'
,p_column_display_sequence=>8
,p_column_heading=>'Attachment'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1052)
,p_plug_name=>'Demo Mailbox Help'
,p_static_id=>'demo-mailbox-help'
,p_title=>'Demo Mailbox (development mode)'
,p_region_template_options=>'#DEFAULT#:t-Alert--horizontal:t-Alert--defaultIcons:t-Alert--info'
,p_plug_template=>2042159785845301134
,p_plug_display_sequence=>21
,p_plug_item_display_point=>'ABOVE'
,p_plug_display_condition_type=>'EXPRESSION'
,p_plug_display_when_condition=>':P2_DOC_ID is not null and esign_pkg.setting(''DEV_MODE'') = ''Y'''
,p_plug_display_when_cond2=>'PLSQL'
,p_plug_source=>'E-mail is not set up on this instance, so the e-mails the signers would receive are kept here. Click <b>Open signing page</b> to sign as that person (it opens in a new tab and does not sign you out). When the signer asks for a one-time code, click <b>Refresh</b> to see it here. With a mail server, set DEV_MODE to N in ESIGN_SETTINGS.'
,p_plug_source_type=>'NATIVE_STATIC'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1053)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1043)
,p_button_name=>'REFRESH_MAILBOX'
,p_static_id=>'refresh_mailbox'
,p_button_action=>'REDIRECT_URL'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2084305881903810008
,p_button_image_alt=>'Refresh'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:2:&APP_SESSION.::&DEBUG.::P2_DOC_ID:&P2_DOC_ID.'
,p_button_execute_validations=>'N'
,p_icon_css_classes=>'fa-refresh'
);
wwv_flow_imp_page.create_report_region(
p_id=>wwv_flow_imp.id(1054)
,p_name=>'Signers'
,p_static_id=>'signers'
,p_title=>'Signers'
,p_template=>4073835273271169698
,p_display_sequence=>20
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_component_template_options=>'#DEFAULT#:t-Report--stretch:t-Report--staticRowColors:t-Report--rowHighlight:t-Report--inline:t-Report--hideNoPagination'
,p_source_type=>'NATIVE_SQL_REPORT'
,p_query_type=>'SQL'
,p_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select s.signer_id,',
'       s.sign_order,',
'       s.signer_name,',
'       s.signer_email,',
'       case s.stamp_page',
'           when ''NONE'' then ''Certificate page only''',
'           else initcap(s.stamp_page) || '' page, '' || lower(replace(s.stamp_position, ''_'', '' ''))',
'       end as stamp,',
'       s.status,',
'       initcap(s.status) as status_label,',
'       esign_pkg.utc(s.signed_on) as signed_on,',
'       case',
'           when d.status = ''DRAFT'' then ''REMOVE_SIGNER''',
'           when d.status = ''SENT'' and s.status in (''SENT'', ''VIEWED'') then ''NEW_LINK''',
'       end as action_request,',
'       case',
'           when d.status = ''DRAFT'' then ''Remove''',
'           when d.status = ''SENT'' and s.status in (''SENT'', ''VIEWED'') then ''New link''',
'       end as action_label',
'  from esign_signers s',
'  join esign_documents d on d.doc_id = s.doc_id',
' where s.doc_id = :P2_DOC_ID',
' order by s.sign_order, s.signer_id'))
,p_ajax_enabled=>'Y'
,p_ajax_items_to_submit=>'P2_DOC_ID'
,p_lazy_loading=>false
,p_query_row_template=>2540130677583398057
,p_query_num_rows=>15
,p_query_options=>'DERIVED_REPORT_COLUMNS'
,p_query_no_data_found=>'No signers yet. Add the people who must sign below.'
,p_query_num_rows_type=>'ROW_RANGES_WITH_LINKS'
,p_pagination_display_position=>'BOTTOM_RIGHT'
,p_csv_output=>'N'
,p_prn_output=>'N'
,p_sort_null=>'L'
,p_plug_query_strip_html=>'N'
,p_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_display_when_condition=>'P2_DOC_ID'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1055)
,p_query_column_id=>1
,p_column_alias=>'SIGNER_ID'
,p_column_display_sequence=>1
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1056)
,p_query_column_id=>2
,p_column_alias=>'SIGN_ORDER'
,p_column_display_sequence=>2
,p_column_heading=>'Order'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1057)
,p_query_column_id=>3
,p_column_alias=>'SIGNER_NAME'
,p_column_display_sequence=>3
,p_column_heading=>'Name'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1058)
,p_query_column_id=>4
,p_column_alias=>'SIGNER_EMAIL'
,p_column_display_sequence=>4
,p_column_heading=>'E-mail'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1059)
,p_query_column_id=>5
,p_column_alias=>'STAMP'
,p_column_display_sequence=>5
,p_column_heading=>'Signature placement'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1060)
,p_query_column_id=>6
,p_column_alias=>'STATUS'
,p_column_display_sequence=>6
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1061)
,p_query_column_id=>7
,p_column_alias=>'STATUS_LABEL'
,p_column_display_sequence=>7
,p_column_heading=>'Status'
,p_column_html_expression=>'<span class="esign-badge esign-badge--#STATUS#">#STATUS_LABEL#</span>'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1062)
,p_query_column_id=>8
,p_column_alias=>'SIGNED_ON'
,p_column_display_sequence=>8
,p_column_heading=>'Signed'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1063)
,p_query_column_id=>9
,p_column_alias=>'ACTION_REQUEST'
,p_column_display_sequence=>9
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1064)
,p_query_column_id=>10
,p_column_alias=>'ACTION_LABEL'
,p_column_display_sequence=>10
,p_column_html_expression=>'<button type="button" class="t-Button t-Button--small t-Button--simple js-esign-action" data-request="#ACTION_REQUEST#" data-id="#SIGNER_ID#">#ACTION_LABEL#</button>'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1065)
,p_plug_name=>'Add Signer'
,p_static_id=>'add-signer'
,p_title=>'Add Signer'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>25
,p_plug_item_display_point=>'ABOVE'
,p_plug_source_type=>'NATIVE_STATIC'
,p_plug_display_condition_type=>'EXPRESSION'
,p_plug_display_when_condition=>':P2_DOC_ID is not null and :P2_STATUS = ''DRAFT'''
,p_plug_display_when_cond2=>'PLSQL'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1066)
,p_name=>'P2_SIGNER_NAME'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1065)
,p_prompt=>'Name'
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
,p_cSize=>30
,p_cMaxlength=>200
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1067)
,p_name=>'P2_SIGNER_EMAIL'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(1065)
,p_prompt=>'E-mail'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'disabled', 'N',
'submit_when_enter_pressed', 'N',
'subtype', 'EMAIL',
'trim_spaces', 'BOTH')).to_clob
,p_cSize=>30
,p_cMaxlength=>320
,p_begin_on_new_line=>'N'
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1068)
,p_name=>'P2_SIGNER_ORDER'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(1065)
,p_prompt=>'Order'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_NUMBER_FIELD'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'number_alignment', 'left',
'virtual_keyboard', 'decimal')).to_clob
,p_cSize=>4
,p_cMaxlength=>3
,p_begin_on_new_line=>'N'
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1069)
,p_name=>'P2_STAMP_PAGE'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(1065)
,p_prompt=>'Place signature on'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'page_action_on_selection', 'NONE')).to_clob
,p_lov=>'STATIC2:Last page;LAST,First page;FIRST,Certificate page only;NONE'
,p_lov_display_null=>'NO'
,p_cHeight=>1
,p_item_default=>'LAST'
,p_lov_display_extra=>'NO'
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1070)
,p_name=>'P2_STAMP_POSITION'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_imp.id(1065)
,p_prompt=>'Position'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'page_action_on_selection', 'NONE')).to_clob
,p_lov=>'STATIC2:Bottom right;BOTTOM_RIGHT,Bottom left;BOTTOM_LEFT,Bottom center;BOTTOM_CENTER,Top right;TOP_RIGHT,Top left;TOP_LEFT'
,p_lov_display_null=>'NO'
,p_cHeight=>1
,p_item_default=>'BOTTOM_RIGHT'
,p_lov_display_extra=>'NO'
,p_begin_on_new_line=>'N'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1071)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1065)
,p_button_name=>'ADD_SIGNER'
,p_static_id=>'add_signer'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2084305881903810008
,p_button_image_alt=>'Add Signer'
,p_button_position=>'NEXT'
,p_icon_css_classes=>'fa-user-plus'
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1072)
,p_plug_name=>'Void Envelope'
,p_static_id=>'void-envelope'
,p_title=>'Void Envelope'
,p_region_template_options=>'#DEFAULT#:is-collapsed:t-Region--scrollBody'
,p_plug_template=>2665811232373458102
,p_plug_display_sequence=>40
,p_plug_item_display_point=>'ABOVE'
,p_plug_source_type=>'NATIVE_STATIC'
,p_plug_display_condition_type=>'EXPRESSION'
,p_plug_display_when_condition=>':P2_DOC_ID is not null and :P2_STATUS in (''DRAFT'', ''SENT'')'
,p_plug_display_when_cond2=>'PLSQL'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1073)
,p_name=>'P2_VOID_REASON'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1072)
,p_prompt=>'Reason'
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
,p_cSize=>60
,p_cMaxlength=>4000
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1074)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1072)
,p_button_name=>'VOID'
,p_static_id=>'void'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--danger'
,p_button_template_id=>4073839297780169708
,p_button_image_alt=>'Void Envelope'
,p_button_position=>'NEXT'
,p_confirm_message=>'Void this envelope? Nobody can sign it after this.'
,p_confirm_style=>'danger'
);
wwv_flow_imp_page.create_report_region(
p_id=>wwv_flow_imp.id(1075)
,p_name=>'Audit Trail'
,p_static_id=>'audit-trail'
,p_title=>'Audit Trail'
,p_template=>4073835273271169698
,p_display_sequence=>50
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_component_template_options=>'#DEFAULT#:t-Report--stretch:t-Report--staticRowColors:t-Report--rowHighlight:t-Report--inline:t-Report--hideNoPagination'
,p_source_type=>'NATIVE_SQL_REPORT'
,p_query_type=>'SQL'
,p_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select to_char(event_time, ''YYYY-MM-DD HH24:MI:SS'') || '' UTC'' as event_time,',
'       event_type,',
'       actor,',
'       details,',
'       ip_address',
'  from esign_audit',
' where doc_id = :P2_DOC_ID',
' order by audit_id desc'))
,p_ajax_enabled=>'Y'
,p_ajax_items_to_submit=>'P2_DOC_ID'
,p_lazy_loading=>false
,p_query_row_template=>2540130677583398057
,p_query_num_rows=>50
,p_query_options=>'DERIVED_REPORT_COLUMNS'
,p_query_no_data_found=>'No rows'
,p_query_num_rows_type=>'ROW_RANGES_WITH_LINKS'
,p_pagination_display_position=>'BOTTOM_RIGHT'
,p_csv_output=>'N'
,p_prn_output=>'N'
,p_sort_null=>'L'
,p_plug_query_strip_html=>'N'
,p_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_display_when_condition=>'P2_DOC_ID'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1076)
,p_query_column_id=>1
,p_column_alias=>'EVENT_TIME'
,p_column_display_sequence=>1
,p_column_heading=>'Time'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1077)
,p_query_column_id=>2
,p_column_alias=>'EVENT_TYPE'
,p_column_display_sequence=>2
,p_column_heading=>'Event'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1078)
,p_query_column_id=>3
,p_column_alias=>'ACTOR'
,p_column_display_sequence=>3
,p_column_heading=>'By'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1079)
,p_query_column_id=>4
,p_column_alias=>'DETAILS'
,p_column_display_sequence=>4
,p_column_heading=>'Details'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1080)
,p_query_column_id=>5
,p_column_alias=>'IP_ADDRESS'
,p_column_display_sequence=>5
,p_column_heading=>'IP address'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1081)
,p_name=>'P2_CHAIN'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1075)
,p_prompt=>'Integrity'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_label_alignment=>'RIGHT'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'based_on', 'VALUE',
'format', 'HTML',
'send_on_page_submit', 'N',
'show_line_breaks', 'N')).to_clob
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1082)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Load Document'
,p_static_id=>'load-document'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'declare',
'    l_doc esign_documents%rowtype;',
'begin',
'    if :P2_DOC_ID is null then',
'        :P2_HEADING    := ''New Document'';',
'        :P2_SUBHEADING := ''Upload the PDF, add the signers, and send it for signature.'';',
'        :P2_STATUS     := null;',
'        return;',
'    end if;',
'    -- only envelopes the user sent',
'    select * into l_doc from esign_documents',
'     where doc_id = :P2_DOC_ID and upper(created_by) = upper(:APP_USER);',
'    :P2_STATUS     := l_doc.status;',
'    :P2_TITLE      := l_doc.title;',
'    :P2_MESSAGE    := l_doc.message;',
'    :P2_ROUTING    := l_doc.routing;',
'    :P2_HEADING    := l_doc.title;',
'    :P2_SUBHEADING := initcap(l_doc.status) || '' &middot; Envelope '' || l_doc.envelope_id || '' &middot; sent by ''',
'                   || apex_escape.html(esign_pkg.sender_name(l_doc.created_by));',
'    :P2_FILE_INFO  := apex_escape.html(l_doc.file_name) || '', '' || l_doc.page_count || '' pages''',
'                   || ''<div class="esign-hash">Original SHA-256 '' || l_doc.original_sha256 || ''</div>''',
'                   || case when l_doc.signed_sha256 is not null',
'                           then ''<div class="esign-hash">Signed PDF SHA-256 '' || l_doc.signed_sha256 || ''</div>'' end',
'                   || case when l_doc.void_reason is not null',
'                           then ''<div>Voided: '' || apex_escape.html(l_doc.void_reason) || ''</div>'' end;',
'    :P2_CHAIN      := ''<span class="fa '' || case when esign_pkg.verify_chain(l_doc.doc_id) like ''Intact%''',
'                                                then ''fa-check-circle u-success-text'' else ''fa-warning u-danger-text'' end',
'                   || ''"></span> '' || apex_escape.html(esign_pkg.verify_chain(l_doc.doc_id));',
'    if :P2_SIGNER_ORDER is null or :REQUEST is null then',
'        select nvl(max(sign_order), 0) + 1 into :P2_SIGNER_ORDER from esign_signers where doc_id = l_doc.doc_id;',
'    end if;',
'exception',
'    when no_data_found then',
'        :P2_DOC_ID := null;',
'end;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1083)
,p_process_sequence=>5
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Check Owner'
,p_static_id=>'check-owner'
,p_process_sql_clob=>'esign_pkg.check_owner(:P2_DOC_ID);'
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P2_DOC_ID'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1084)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Create Document'
,p_static_id=>'create-document'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
':P2_DOC_ID := esign_pkg.create_document(',
'    p_title     => :P2_TITLE,',
'    p_message   => :P2_MESSAGE,',
'    p_routing   => :P2_ROUTING,',
'    p_temp_file => :P2_FILE);'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'CREATE'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'Document created. Now add the signers.'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1085)
,p_process_sequence=>20
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Save Document'
,p_static_id=>'save-document'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'esign_pkg.update_document(',
'    p_doc_id    => :P2_DOC_ID,',
'    p_title     => :P2_TITLE,',
'    p_message   => :P2_MESSAGE,',
'    p_routing   => :P2_ROUTING,',
'    p_temp_file => :P2_FILE);'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'SAVE'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'Changes saved.'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1086)
,p_process_sequence=>30
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Add Signer'
,p_static_id=>'add-signer'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'esign_pkg.add_signer(',
'    p_doc_id   => :P2_DOC_ID,',
'    p_name     => :P2_SIGNER_NAME,',
'    p_email    => :P2_SIGNER_EMAIL,',
'    p_order    => :P2_SIGNER_ORDER,',
'    p_page     => :P2_STAMP_PAGE,',
'    p_position => :P2_STAMP_POSITION);',
':P2_SIGNER_NAME  := null;',
':P2_SIGNER_EMAIL := null;',
':P2_SIGNER_ORDER := null;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'ADD_SIGNER'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'Signer added.'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1087)
,p_process_sequence=>40
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Remove Signer'
,p_static_id=>'remove-signer'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'for s in (select signer_id from esign_signers where signer_id = :P2_SIGNER_ID and doc_id = :P2_DOC_ID) loop',
'    esign_pkg.remove_signer(s.signer_id);',
'end loop;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'REMOVE_SIGNER'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'Signer removed.'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1088)
,p_process_sequence=>50
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Send'
,p_static_id=>'send'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'declare',
'    l_links varchar2(32767);',
'begin',
'    l_links := esign_pkg.send_document(p_doc_id => :P2_DOC_ID);',
'end;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'SEND'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'Sent. The signers receive an e-mail with their signing link.'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1089)
,p_process_sequence=>60
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'New Signing Link'
,p_static_id=>'new-signing-link'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'declare',
'    l_link varchar2(4000);',
'begin',
'    for s in (select signer_id from esign_signers where signer_id = :P2_SIGNER_ID and doc_id = :P2_DOC_ID) loop',
'        l_link := esign_pkg.new_signing_link(s.signer_id);',
'    end loop;',
'end;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'NEW_LINK'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'New signing link e-mailed. The previous link no longer works.'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1090)
,p_process_sequence=>70
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Void'
,p_static_id=>'void'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'esign_pkg.void_document(p_doc_id => :P2_DOC_ID, p_reason => :P2_VOID_REASON);',
':P2_VOID_REASON := null;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'VOID'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'Envelope voided.'
);
wwv_flow_imp_page.create_page_branch(
p_id=>wwv_flow_imp.id(1091)
,p_branch_action=>'f?p=&APP_ID.:2:&APP_SESSION.::&DEBUG.::P2_DOC_ID:&P2_DOC_ID.&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_sequence=>10
);
end;
/
prompt --application/pages/page_00003
begin
wwv_flow_imp_page.create_page(
p_id=>3
,p_name=>'Download'
,p_alias=>'DOWNLOAD'
,p_step_title=>'Download'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>4073832297226169690
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'C'
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1092)
,p_plug_name=>'Download'
,p_static_id=>'download'
,p_title=>'Download'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'ABOVE'
,p_plug_source=>'Preparing the download...'
,p_plug_source_type=>'NATIVE_STATIC'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1093)
,p_name=>'P3_DOC_ID'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1092)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1094)
,p_name=>'P3_WHICH'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(1092)
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_HIDDEN'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1095)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Download PDF'
,p_static_id=>'download-pdf'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'esign_pkg.check_owner(:P3_DOC_ID);',
'esign_pkg.download(p_doc_id => :P3_DOC_ID, p_which => :P3_WHICH);',
'apex_application.stop_apex_engine;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
end;
/
prompt --application/pages/page_00005
begin
wwv_flow_imp_page.create_page(
p_id=>5
,p_name=>'Demo Mailbox'
,p_alias=>'MAILBOX'
,p_step_title=>'Demo Mailbox'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>4073832297226169690
,p_page_template_options=>'#DEFAULT#'
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
'.esign-mail-link:not([href]), .esign-mail-link[href=""] { display: none; }'))
);
wwv_flow_imp_page.create_report_region(
p_id=>wwv_flow_imp.id(1096)
,p_name=>'Demo Mailbox'
,p_static_id=>'demo-mailbox'
,p_title=>'Demo Mailbox'
,p_template=>4073835273271169698
,p_display_sequence=>10
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_component_template_options=>'#DEFAULT#:t-Report--stretch:t-Report--staticRowColors:t-Report--rowHighlight:t-Report--inline:t-Report--hideNoPagination'
,p_source_type=>'NATIVE_SQL_REPORT'
,p_query_type=>'SQL'
,p_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select m.mail_id,',
'       to_char(m.created_on at time zone ''UTC'', ''HH24:MI:SS'') as sent_at,',
'       m.to_email,',
'       m.subject,',
'       d.title as document,',
'       m.link_url,',
'       case when m.link_url is not null then ''Open signing page'' end as link_label,',
'       m.otp_code,',
'       case when m.has_attachment = ''Y'' then ''signed PDF attached'' end as attachment',
'  from esign_dev_outbox m',
'  left join esign_documents d on d.doc_id = m.doc_id',
' where upper(d.created_by) = upper(:APP_USER)',
' order by m.mail_id desc'))
,p_ajax_enabled=>'Y'
,p_lazy_loading=>false
,p_query_row_template=>2540130677583398057
,p_query_num_rows=>50
,p_query_options=>'DERIVED_REPORT_COLUMNS'
,p_query_no_data_found=>'The demo mailbox is empty.'
,p_query_num_rows_type=>'ROW_RANGES_WITH_LINKS'
,p_pagination_display_position=>'BOTTOM_RIGHT'
,p_csv_output=>'N'
,p_prn_output=>'N'
,p_sort_null=>'L'
,p_plug_query_strip_html=>'N'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1097)
,p_query_column_id=>1
,p_column_alias=>'MAIL_ID'
,p_column_display_sequence=>1
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1098)
,p_query_column_id=>2
,p_column_alias=>'SENT_AT'
,p_column_display_sequence=>2
,p_column_heading=>'Time (UTC)'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1099)
,p_query_column_id=>3
,p_column_alias=>'TO_EMAIL'
,p_column_display_sequence=>3
,p_column_heading=>'To'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1100)
,p_query_column_id=>4
,p_column_alias=>'SUBJECT'
,p_column_display_sequence=>4
,p_column_heading=>'Subject'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1101)
,p_query_column_id=>5
,p_column_alias=>'DOCUMENT'
,p_column_display_sequence=>5
,p_column_heading=>'Document'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1102)
,p_query_column_id=>6
,p_column_alias=>'LINK_URL'
,p_column_display_sequence=>6
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1103)
,p_query_column_id=>7
,p_column_alias=>'LINK_LABEL'
,p_column_display_sequence=>7
,p_column_heading=>'Signing link'
,p_column_html_expression=>'<a href="#LINK_URL#" target="_blank" rel="noopener" class="esign-mail-link">#LINK_LABEL#</a>'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1104)
,p_query_column_id=>8
,p_column_alias=>'OTP_CODE'
,p_column_display_sequence=>8
,p_column_heading=>'One-time code'
,p_column_html_expression=>'<span class="esign-code">#OTP_CODE#</span>'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_report_columns(
p_id=>wwv_flow_imp.id(1105)
,p_query_column_id=>9
,p_column_alias=>'ATTACHMENT'
,p_column_display_sequence=>9
,p_column_heading=>'Attachment'
,p_heading_alignment=>'LEFT'
,p_disable_sort_column=>'Y'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1106)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1096)
,p_button_name=>'REFRESH'
,p_static_id=>'refresh'
,p_button_action=>'REDIRECT_URL'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2084305881903810008
,p_button_image_alt=>'Refresh'
,p_button_position=>'NEXT'
,p_button_redirect_url=>'f?p=&APP_ID.:5:&APP_SESSION.::&DEBUG.:::'
,p_icon_css_classes=>'fa-refresh'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1107)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_imp.id(1096)
,p_button_name=>'CLEAR'
,p_static_id=>'clear'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconLeft'
,p_button_template_id=>2084305881903810008
,p_button_image_alt=>'Empty Mailbox'
,p_button_position=>'NEXT'
,p_confirm_message=>'Delete all e-mails in the demo mailbox?'
,p_confirm_style=>'danger'
,p_icon_css_classes=>'fa-trash-o'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1108)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Empty Mailbox'
,p_static_id=>'empty-mailbox'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'delete from esign_dev_outbox m',
' where m.doc_id in (select doc_id from esign_documents where upper(created_by) = upper(:APP_USER));'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'CLEAR'
,p_process_when_type=>'REQUEST_EQUALS_CONDITION'
,p_process_success_message=>'The demo mailbox is empty.'
);
wwv_flow_imp_page.create_page_branch(
p_id=>wwv_flow_imp.id(1109)
,p_branch_action=>'f?p=&APP_ID.:5:&APP_SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_sequence=>10
);
end;
/
prompt --application/pages/page_09999
begin
wwv_flow_imp_page.create_page(
p_id=>9999
,p_name=>'Login Page'
,p_alias=>'LOGIN'
,p_step_title=>'ESign Lab - Sign In'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>2102634289808461002
,p_page_template_options=>'#DEFAULT#'
,p_page_is_public_y_n=>'Y'
,p_protection_level=>'C'
);
wwv_flow_imp_page.create_page_plug(
p_id=>wwv_flow_imp.id(1110)
,p_plug_name=>'ESign Lab'
,p_static_id=>'esign-lab'
,p_title=>'ESign Lab'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>2675634334296186762
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'ABOVE'
,p_plug_source_type=>'NATIVE_STATIC'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'expand_shortcuts', 'N',
'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1111)
,p_name=>'P9999_USERNAME'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(1110)
,p_prompt=>'Username'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_label_alignment=>'RIGHT'
,p_field_template=>2042262243893469891
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'disabled', 'N',
'submit_when_enter_pressed', 'N',
'subtype', 'TEXT',
'trim_spaces', 'BOTH')).to_clob
,p_placeholder=>'Username'
,p_cSize=>40
,p_cMaxlength=>100
,p_tag_attributes=>'autocomplete="username"'
,p_item_icon_css_classes=>'fa-user'
,p_is_persistent=>'N'
);
wwv_flow_imp_page.create_page_item(
p_id=>wwv_flow_imp.id(1112)
,p_name=>'P9999_PASSWORD'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(1110)
,p_prompt=>'Password'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_PASSWORD'
,p_label_alignment=>'RIGHT'
,p_field_template=>2042262243893469891
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'submit_when_enter_pressed', 'Y')).to_clob
,p_placeholder=>'Password'
,p_cSize=>40
,p_cMaxlength=>100
,p_tag_attributes=>'autocomplete="current-password"'
,p_item_icon_css_classes=>'fa-key'
,p_is_persistent=>'N'
);
wwv_flow_imp_page.create_page_button(
p_id=>wwv_flow_imp.id(1113)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(1110)
,p_button_name=>'LOGIN'
,p_static_id=>'login'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Sign In'
,p_button_position=>'NEXT'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1114)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Get Username Cookie'
,p_static_id=>'get-username-cookie'
,p_process_sql_clob=>':P9999_USERNAME := apex_authentication.get_login_username_cookie;'
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1115)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Login'
,p_static_id=>'login'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'apex_authentication.send_login_username_cookie(p_username => lower(:P9999_USERNAME));',
'apex_authentication.login(p_username => :P9999_USERNAME, p_password => :P9999_PASSWORD);'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_imp_page.create_page_process(
p_id=>wwv_flow_imp.id(1116)
,p_process_sequence=>30
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_SESSION_STATE'
,p_process_name=>'Clear Page(s) Cache'
,p_static_id=>'clear-page-s-cache'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
'type', 'CLEAR_CACHE_CURRENT_PAGE')).to_clob
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
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
