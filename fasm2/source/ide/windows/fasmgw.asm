
; flat assembler g IDE for Windows
; Copyright (c) 1999-2024, Tomasz Grysztar.
; All rights reserved.

format PE GUI 4.0 large NX
entry start
stack 20000h

include 'win32ax.inc'
include 'fedit.ash'

include '..\..\version.inc'

PE.Settings.Stamp = +VERSION
%t equ +VERSION

struct EDITITEM
  header      TC_ITEMHEADER
  hwnd	      dd ?
  pszpath     dd ?
ends

FM_NEW		= WM_USER + 0
FM_OPEN 	= WM_USER + 1
FM_SAVE 	= WM_USER + 2
FM_COMPILE	= WM_USER + 3
FM_SELECT	= WM_USER + 4
FM_ASSIGN	= WM_USER + 5
FM_GETSELECTED	= WM_USER + 6
FM_GETASSIGNED	= WM_USER + 7
FM_GETHANDLE	= WM_USER + 8
FM_OPENREADONLY = WM_USER + 11h
FM_SAVEMODIFIED = WM_USER + 12h

struct HH_AKLINK
  cbStruct     dd ?
  fReserved    dd ?
  pszKeywords  dd ?
  pszUrl       dd ?
  pszMsgText   dd ?
  pszMsgTitle  dd ?
  pszWindow    dd ?
  fIndexOnFail dd ?
ends

HH_DISPLAY_TOPIC  = 0
HH_KEYWORD_LOOKUP = 0Dh

CP_ARGUMENTS = 0
CP_DIRECTORY = 1

MAX_ERRORS = 1000

EXPRESSION_MAX_LENGTH = 1000

section '.data' data readable writeable

  HtmlHelp dd 0

  SetGestureConfig dd 0
  GetGestureInfo dd 0
  CloseGestureInfoHandle dd 0

  wheel_scroll_lines dd 3

  _caption db 'flat assembler 2 (g.',VERSION,')',0
  _class db 'FASMGW',0
  _fedit_class db 'FEDIT',0
  _listbox_class db 'LISTBOX',0
  _tabctrl_class db 'SysTabControl32',0
  _htmlhelp_library db 'HHCTRL.OCX',0
  _htmlhelp_api db 'HtmlHelpA',0
  _user_library db 'USER32.DLL',0
  _setgestureconfig_api db 'SetGestureConfig',0
  _getgestureinfo_api db 'GetGestureInfo',0
  _closegestureinfohandle_api db 'CloseGestureInfoHandle',0

  _memory_error db 'Not enough memory to complete this operation.',0
  _loading_error db 'Could not load file %s.',0
  _saving_question db 'File was modified. Save it now?',0
  _not_found db 'Text %s not found.',0
  _not_found_after db 'Text %s not found after current position.',0
  _not_found_before db 'Text %s not found before current position.',0
  _replace_prompt db 'Replace this occurence?',0
  _replaces_made db '%d replaces made.',0
  _untitled db 'Untitled',0
  _font_face db 'Courier New',0
  _row_column db 9,'%d,'
  _value db '%d'
  _null db 0
  _line_number db '%s [%d]',0
  _color db '%d,%d,%d',0
  _modified_status db 9,'Modified',0
  _readonly_status db 9,'Read-only',0
  _pick_help db 'Pick help file',0
  _find db 'Find',0
  _replace db 'Replace',0
  _calm db 'CALM',0

  _asm_extension db 'asm',0

  _section_environment db 'Environment',0
  _key_environment_include db 'Include',0
  _section_compiler db 'Compiler',0
  _key_compiler_header db 'SourceHeader',0
  _key_compiler_priority db 'Priority',0
  _key_compiler_max_passes db 'MaxPasses',0
  _key_compiler_max_recursion db 'MaxRecursion',0
  _section_options db 'Options',0
  _key_options_securesel db 'SecureSelection',0
  _key_options_autobrackets db 'AutoBrackets',0
  _key_options_autoindent db 'AutoIndent',0
  _key_options_smarttabs db 'SmartTabs',0
  _key_options_optimalfill db 'OptimalFill',0
  _key_options_revivedeadkeys db 'ReviveDeadKeys',0
  _key_options_consolecaret db 'ConsoleCaret',0
  _key_options_timescroll db 'TimeScroll',0
  _key_options_oneinstanceonly db 'OneInstanceOnly',0
  _section_colors db 'Colors',0
  _key_color_text db 'Text',0
  _key_color_background db 'Background',0
  _key_color_seltext db 'SelectionText',0
  _key_color_selbackground db 'SelectionBackground',0
  _key_color_symbols db 'Symbols',0
  _key_color_numbers db 'Numbers',0
  _key_color_strings db 'Strings',0
  _key_color_comments db 'Comments',0
  _section_font db 'Font',0
  _key_font_face db 'Face',0
  _key_font_height db 'Height',0
  _key_font_width db 'Width',0
  _key_font_weight db 'Weight',0
  _key_font_italic db 'Italic',0
  _key_font_charset db 'CharSet',0
  _section_window db 'Window',0
  _key_window_top db 'Top',0
  _key_window_left db 'Left',0
  _key_window_right db 'Right',0
  _key_window_bottom db 'Bottom',0
  _key_window_maximized db 'Maximized',0
  _section_help db 'Help',0
  _key_help_path db 'Path',0

  _reg_key_desktop db 'Control Panel\Desktop',0
  _reg_value_wheelscrolllines db 'WheelScrollLines',0

  _appearance_settings db 'Font',0
		       db 'Text color',0
		       db 'Background color',0
		       db 'Selection text color',0
		       db 'Selection background color',0
		       db 'Symbols color',0
		       db 'Numbers color',0
		       db 'Strings color',0
		       db 'Comments color',0
		       db 0
  _priority_settings db 'Idle',0
		     db 'Low',0
		     db 'Normal',0
		     db 'High',0
		     db 'Realtime',0
		     db 0

  fedit_style dd FES_AUTOINDENT+FES_SMARTTABS+FES_CONSOLECARET

  editor_colors rd 4
  asm_syntax_colors dd 0xF03030,0x009000,0x0000B0,0x808080

  preview_text db 0Dh,0Ah
	       db ' org 100h',0Dh,0Ah
	       db 0Dh,0Ah
	       db ' mov ah,09h ',' ; write',0Dh,0Ah
	       db ' mov dx,text',0Dh,0Ah
	       db ' int 21h',0Dh,0Ah
	       db ' int 20h',0Dh,0Ah
	       db 0Dh,0Ah
	       db ' text db "Hello!",24h',0Dh,0Ah
	       db 0
  preview_selection dd 1,5,1,6

  asm_filter db 'Assembly files',0,'*.asm;*.inc;*.ash;*.alm',0
	     db 'All files',0,'*.*',0
	     db 0

  help_filter db 'Help files',0,'*.hlp;*.chm',0
	      db 0

  default_source_header db "include 'fasm2.inc'",0

  calculator_string db 'db string '
  expression_buffer db EXPRESSION_MAX_LENGTH dup ?

  align 4

  hinstance dd ?
  hheap dd ?
  hkey_main dd ?
  hmenu_main dd ?
  hmenu_edit dd ?
  hmenu_tab dd ?
  hacc dd ?
  hfont dd ?
  hwnd_main dd ?
  hwnd_status dd ?
  hwnd_tabctrl dd ?
  hwnd_history dd ?
  hwnd_fedit dd ?
  hwnd_compiler dd ?
  hwnd_progress dd ?
  himl dd ?
  hthread dd ?
  hfile dd ?
  mutex dd ?

  instance_flags dd ?
  command_flags dd ?
  search_settings dd ?
  replaces_count dd ?
  compiler_memory dd ?
  compiler_priority dd ?
  assigned_file dd ?
  program_arguments dd ?

  result_address dd ?
  result_size dd ?
  digits_address dd ?
  digits_size dd ?

  param_buffer rd 10h
  user_colors rd 10h
  name_buffer rb 100h
  search_string rb 1000h
  replace_string rb 1000h
  string_buffer rb 2000h
  help_path rb 1000h
  ini_path rb 1000h
  include_path rb 1000h
  source_header rb 1000h
  executable_path rb 1000h
  path_buffer rb 4000h

  msg MSG
  wc WNDCLASS
  rc RECT
  pt POINT
  ei EDITITEM
  font LOGFONT
  bm BITMAP
  tcht TC_HITTESTINFO
  wp WINDOWPLACEMENT
  fepos FEPOS
  ofn OPENFILENAME
  cf CHOOSEFONT
  cc CHOOSECOLOR
  systime SYSTEMTIME
  sinfo STARTUPINFO
  pinfo PROCESS_INFORMATION
  cp COPYDATASTRUCT

  bytes_count dd ?
  fedit_font dd ?

  tmp_colors rd 8
  tmp_font LOGFONT
  backup_font LOGFONT

  hhkey HH_AKLINK

  upper_case_table rb 100h

  error_pointers rd MAX_ERRORS

section '.text' code readable executable

include 'fedit.inc'

  start:

	invoke	GetModuleHandle,0
	mov	[hinstance],eax
	invoke	GetProcessHeap
	mov	[hheap],eax

	invoke	GetModuleHandle,_user_library
	or	eax,eax
	jz	gesture_api_unavailable
	mov	ebx,eax
	invoke	GetProcAddress,ebx,_setgestureconfig_api
	or	eax,eax
	jz	gesture_api_unavailable
	mov	esi,eax
	invoke	GetProcAddress,ebx,_getgestureinfo_api
	or	eax,eax
	jz	gesture_api_unavailable
	mov	edi,eax
	invoke	GetProcAddress,ebx,_closegestureinfohandle_api
	or	eax,eax
	jz	gesture_api_unavailable
	mov	[CloseGestureInfoHandle],eax
	mov	[SetGestureConfig],esi
	mov	[GetGestureInfo],edi
      gesture_api_unavailable:

	invoke	GetCommandLine
	mov	esi,eax
	mov	edi,ini_path
      find_program_path:
	lodsb
	cmp	al,20h
	je	find_program_path
	cmp	al,22h
	je	quoted_program_path
	cmp	al,0Dh
	je	program_path_ok
	or	al,al
	jnz	get_program_path
	dec	esi
	jmp	program_path_ok
      get_program_path:
	stosb
	lodsb
	cmp	al,20h
	je	program_path_ok
	cmp	al,0Dh
	je	program_path_ok
	or	al,al
	jnz	get_program_path
	dec	esi
	jmp	program_path_ok
      quoted_program_path:
	lodsb
	cmp	al,22h
	je	program_path_ok
	cmp	al,0Dh
	je	program_path_ok
	stosb
	or	al,al
	jnz	quoted_program_path
	dec	esi
      program_path_ok:
	mov	[program_arguments],esi
	mov	ebx,edi
      find_program_extension:
	cmp	ebx,ini_path
	je	make_ini_extension
	dec	ebx
	mov	al,[ebx]
	cmp	al,'\'
	je	make_ini_extension
	cmp	al,'/'
	je	make_ini_extension
	cmp	al,'.'
	jne	find_program_extension
	mov	edi,ebx
	jmp	find_program_extension
      make_ini_extension:
	mov	eax,'.ini'
	stosd
	xor	al,al
	stosb
	invoke	GetFullPathName,ini_path,1000h,ini_path,param_buffer
	mov	esi,ini_path
	mov	ecx,[param_buffer]
	sub	ecx,esi
	mov	edi,include_path
	rep	movsb
	mov	eax,'incl'
	stosd
	mov	eax,'ude'
	stosd
	invoke	GetFileAttributes,ini_path
	cmp	eax,-1
	jne	ini_ok
	invoke	WritePrivateProfileString,_section_environment,_key_environment_include,include_path,ini_path
      ini_ok:

	mov	[instance_flags],0
	stdcall GetIniBit,ini_path,_section_options,_key_options_oneinstanceonly,instance_flags,1
	cmp	[instance_flags],0
	je	create_new_window
	invoke	FindWindow,_class,NULL
	or	eax,eax
	jnz	window_already_exists

      create_new_window:
	invoke	LoadCursor,0,IDC_IBEAM
	mov	[wc.hCursor],eax
	mov	[wc.style],CS_GLOBALCLASS+CS_DBLCLKS
	mov	[wc.lpfnWndProc],FlatEditor
	mov	eax,[hinstance]
	mov	[wc.hInstance],eax
	mov	[wc.cbWndExtra],4
	xor	eax,eax
	mov	[wc.hbrBackground],eax
	mov	[wc.cbClsExtra],eax
	mov	[wc.lpszMenuName],eax
	mov	[wc.lpszClassName],_fedit_class
	invoke	RegisterClass,wc
	or	eax,eax
	jz	end_loop
	invoke	CreateFont,0,0,0,0,0,FALSE,FALSE,FALSE,ANSI_CHARSET,OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,FIXED_PITCH+FF_DONTCARE,NULL
	or	eax,eax
	jz	end_loop
	mov	[fedit_font],eax

	mov	edi,upper_case_table
	xor	ebx,ebx
	mov	esi,100h
      make_case_table:
	invoke	CharUpper,ebx
	stosb
	inc	bl
	dec	esi
	jnz	make_case_table
	mov	edi,characters
	mov	ecx,100h
	xor	al,al
      prepare_characters_table:
	stosb
	inc	al
	loop	prepare_characters_table
	mov	esi,characters+'a'
	mov	edi,characters+'A'
	mov	ecx,26
	rep	movsb
	mov	edi,characters
	mov	esi,syntactical_characters
	mov	ecx,syntactical_characters.count
	xor	eax,eax
      convert_table:
	lodsb
	mov	byte [edi+eax],0
	loop	convert_table

	invoke	LoadIcon,[hinstance],IDI_MAIN
	mov	[wc.hIcon],eax
	invoke	LoadCursor,0,IDC_ARROW
	mov	[wc.hCursor],eax
	mov	[wc.style],0
	mov	[wc.lpfnWndProc],MainWindow
	mov	[wc.cbClsExtra],0
	mov	[wc.cbWndExtra],0
	mov	eax,[hinstance]
	mov	[wc.hInstance],eax
	mov	[wc.hbrBackground],COLOR_BTNFACE+1
	mov	[wc.lpszMenuName],0
	mov	[wc.lpszClassName],_class
	invoke	RegisterClass,wc

	invoke	LoadMenu,[hinstance],IDM_MAIN
	mov	[hmenu_main],eax
	invoke	GetSubMenu,eax,1
	mov	[hmenu_edit],eax
	invoke	LoadMenu,[hinstance],IDM_TAB
	invoke	GetSubMenu,eax,0
	mov	[hmenu_tab],eax
	invoke	LoadAccelerators,[hinstance],IDA_MAIN
	mov	[hacc],eax
	invoke	CreateWindowEx,0,_class,_caption,WS_OVERLAPPEDWINDOW+WS_CLIPCHILDREN+WS_CLIPSIBLINGS,64,64,500,500,NULL,[hmenu_main],[hinstance],NULL
	or	eax,eax
	jz	end_loop
	mov	[hwnd_main],eax
	mov	eax,SW_SHOW
	test	[wp.flags],WPF_RESTORETOMAXIMIZED
	jz	show_main_window
	mov	eax,SW_SHOWMAXIMIZED
      show_main_window:
	invoke	ShowWindow,[hwnd_main],eax
	invoke	UpdateWindow,[hwnd_main]
  msg_loop:
	invoke	GetMessage,msg,NULL,0,0
	or	eax,eax
	jz	end_loop
	invoke	TranslateAccelerator,[hwnd_main],[hacc],msg
	or	eax,eax
	jnz	msg_loop
	cmp	[msg.message],WM_KEYDOWN
	je	msg_dispatch
	invoke	TranslateMessage,msg
      msg_dispatch:
	invoke	DispatchMessage,msg
	jmp	msg_loop

  window_already_exists:
	mov	ebx,eax
	invoke	GetWindowPlacement,ebx,wp
	mov	eax,SW_SHOWNORMAL
	cmp	[wp.showCmd],SW_SHOWMAXIMIZED
	jne	show_existing_window
	mov	eax,SW_SHOWMAXIMIZED
      show_existing_window:
	invoke	ShowWindow,ebx,eax
	invoke	SetForegroundWindow,ebx
	invoke	GetCurrentDirectory,4000h,path_buffer
	inc	eax
	mov	[cp.cbData],eax
	mov	[cp.lpData],path_buffer
	mov	[cp.dwData],CP_DIRECTORY
	invoke	SendMessage,ebx,WM_COPYDATA,NULL,cp
	mov	edi,[program_arguments]
	mov	[cp.lpData],edi
	or	ecx,-1
	xor	al,al
	repne	scasb
	neg	ecx
	mov	[cp.cbData],ecx
	mov	[cp.dwData],CP_ARGUMENTS
	invoke	SendMessage,ebx,WM_COPYDATA,NULL,cp
  end_loop:
	invoke	ExitProcess,[msg.wParam]

proc MainWindow hwnd,wmsg,wparam,lparam
	push	ebx esi edi
	cmp	[wmsg],WM_CREATE
	je	wmcreate
	cmp	[wmsg],WM_COPYDATA
	je	wmcopydata
	cmp	[wmsg],WM_GETMINMAXINFO
	je	wmgetminmaxinfo
	cmp	[wmsg],WM_SIZE
	je	wmsize
	cmp	[wmsg],WM_SETFOCUS
	je	wmsetfocus
	cmp	[wmsg],FM_NEW
	je	fmnew
	cmp	[wmsg],FM_OPEN
	je	fmopen
	cmp	[wmsg],FM_OPENREADONLY
	je	fmopenreadonly
	cmp	[wmsg],FM_SAVE
	je	fmsave
	cmp	[wmsg],FM_SAVEMODIFIED
	je	fmsavemodified
	cmp	[wmsg],FM_COMPILE
	je	fmcompile
	cmp	[wmsg],FM_SELECT
	je	fmselect
	cmp	[wmsg],FM_ASSIGN
	je	fmassign
	cmp	[wmsg],FM_GETSELECTED
	je	fmgetselected
	cmp	[wmsg],FM_GETASSIGNED
	je	fmgetassigned
	cmp	[wmsg],FM_GETHANDLE
	je	fmgethandle
	cmp	[wmsg],WM_INITMENU
	je	wminitmenu
	cmp	[wmsg],WM_COMMAND
	je	wmcommand
	cmp	[wmsg],WM_NOTIFY
	je	wmnotify
	cmp	[wmsg],WM_DROPFILES
	je	wmdropfiles
	cmp	[wmsg],WM_CLOSE
	je	wmclose
	cmp	[wmsg],WM_DESTROY
	je	wmdestroy
	invoke	DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
	jmp	finish
  wmcreate:
	xor	eax,eax
	mov	[search_settings],eax
	mov	[search_string],al
	mov	[replace_string],al
	mov	[compiler_memory],65536
	mov	[compiler_priority],THREAD_PRIORITY_NORMAL
	mov	[assigned_file],-1
	mov	[help_path],0
	mov	[ofn.lStructSize],sizeof.OPENFILENAME
	mov	eax,[hwnd]
	mov	[ofn.hwndOwner],eax
	mov	eax,[hinstance]
	mov	[ofn.hInstance],eax
	mov	[ofn.lpstrCustomFilter],NULL
	mov	[ofn.nFilterIndex],1
	mov	[ofn.nMaxFile],1000h
	mov	[ofn.lpstrFileTitle],name_buffer
	mov	[ofn.nMaxFileTitle],100h
	mov	[ofn.lpstrInitialDir],NULL
	mov	[ofn.lpstrDefExt],_asm_extension
	mov	[font.lfHeight],16
	mov	[font.lfWidth],0
	mov	[font.lfEscapement],0
	mov	[font.lfOrientation],0
	mov	[font.lfWeight],0
	mov	[font.lfItalic],FALSE
	mov	[font.lfUnderline],FALSE
	mov	[font.lfStrikeOut],FALSE
	mov	[font.lfCharSet],DEFAULT_CHARSET
	mov	[font.lfOutPrecision],OUT_RASTER_PRECIS
	mov	[font.lfClipPrecision],CLIP_DEFAULT_PRECIS
	mov	[font.lfQuality],DEFAULT_QUALITY
	mov	[font.lfPitchAndFamily],FIXED_PITCH+FF_DONTCARE
	mov	edi,font.lfFaceName
	mov	esi,_font_face
      copy_font_face:
	lodsb
	stosb
	or	al,al
	jnz	copy_font_face
	invoke	GetSysColor,COLOR_WINDOWTEXT
	mov	[editor_colors],eax
	invoke	GetSysColor,COLOR_WINDOW
	mov	[editor_colors+4],eax
	invoke	GetSysColor,COLOR_HIGHLIGHTTEXT
	mov	[editor_colors+8],eax
	invoke	GetSysColor,COLOR_HIGHLIGHT
	mov	[editor_colors+12],eax
	mov	esi,editor_colors
	mov	edi,user_colors
	mov	ecx,8
	rep	movsd
	mov	[wp.length],sizeof.WINDOWPLACEMENT
	invoke	GetWindowPlacement,[hwnd],wp
	invoke	RegOpenKeyEx,HKEY_CURRENT_USER,_reg_key_desktop,0,KEY_READ,param_buffer
	test	eax,eax
	jnz	wheel_setting_ok
	mov	[bytes_count],100h
	invoke	RegQueryValueEx,[param_buffer],_reg_value_wheelscrolllines,0,param_buffer+4,string_buffer,bytes_count
	test	eax,eax
	jnz	no_valid_wheel_setting
	cmp	[param_buffer+4],REG_SZ
	jne	no_valid_wheel_setting
	mov	esi,string_buffer
	cmp	byte [esi],0
	je	no_valid_wheel_setting
	call	atoi
	jc	no_valid_wheel_setting
	mov	[wheel_scroll_lines],eax
      no_valid_wheel_setting:
	invoke	RegCloseKey,[param_buffer]
      wheel_setting_ok:
	invoke	GetPrivateProfileString,_section_compiler,_key_compiler_header,default_source_header,source_header,1000h,ini_path
	stdcall GetIniInteger,ini_path,_section_compiler,_key_compiler_priority,compiler_priority
	mov	eax,100
	mov	[maximum_number_of_passes],eax
	mov	[param_buffer],eax
	stdcall GetIniInteger,ini_path,_section_compiler,_key_compiler_max_passes,param_buffer
	mov	eax,[param_buffer]
	test	eax,eax
	jz	passes_limit_ok
	mov	[maximum_number_of_passes],eax
      passes_limit_ok:
	mov	eax,10000
	mov	[maximum_depth_of_stack],eax
	mov	[param_buffer],eax
	stdcall GetIniInteger,ini_path,_section_compiler,_key_compiler_max_recursion,param_buffer
	mov	eax,[param_buffer]
	test	eax,eax
	jz	recursion_limit_ok
	mov	[maximum_depth_of_stack],eax
      recursion_limit_ok:
	stdcall GetIniBit,ini_path,_section_options,_key_options_securesel,fedit_style,FES_SECURESEL
	stdcall GetIniBit,ini_path,_section_options,_key_options_autobrackets,fedit_style,FES_AUTOBRACKETS
	stdcall GetIniBit,ini_path,_section_options,_key_options_autoindent,fedit_style,FES_AUTOINDENT
	stdcall GetIniBit,ini_path,_section_options,_key_options_smarttabs,fedit_style,FES_SMARTTABS
	stdcall GetIniBit,ini_path,_section_options,_key_options_optimalfill,fedit_style,FES_OPTIMALFILL
	stdcall GetIniBit,ini_path,_section_options,_key_options_revivedeadkeys,fedit_style,FES_REVIVEDEADKEYS
	stdcall GetIniBit,ini_path,_section_options,_key_options_consolecaret,fedit_style,FES_CONSOLECARET
	stdcall GetIniBit,ini_path,_section_options,_key_options_timescroll,fedit_style,FES_TIMESCROLL
	stdcall GetIniColor,ini_path,_section_colors,_key_color_text,editor_colors
	stdcall GetIniColor,ini_path,_section_colors,_key_color_background,editor_colors+4
	stdcall GetIniColor,ini_path,_section_colors,_key_color_seltext,editor_colors+8
	stdcall GetIniColor,ini_path,_section_colors,_key_color_selbackground,editor_colors+12
	stdcall GetIniColor,ini_path,_section_colors,_key_color_symbols,asm_syntax_colors
	stdcall GetIniColor,ini_path,_section_colors,_key_color_numbers,asm_syntax_colors+4
	stdcall GetIniColor,ini_path,_section_colors,_key_color_strings,asm_syntax_colors+8
	stdcall GetIniColor,ini_path,_section_colors,_key_color_comments,asm_syntax_colors+12
	invoke	GetPrivateProfileString,_section_font,_key_font_face,font.lfFaceName,font.lfFaceName,32,ini_path
	stdcall GetIniInteger,ini_path,_section_font,_key_font_height,font.lfHeight
	stdcall GetIniInteger,ini_path,_section_font,_key_font_width,font.lfWidth
	stdcall GetIniInteger,ini_path,_section_font,_key_font_weight,font.lfWeight
	stdcall GetIniBit,ini_path,_section_font,_key_font_italic,font.lfItalic,1
	stdcall GetIniByte,ini_path,_section_font,_key_font_charset,font.lfCharSet
	stdcall GetIniInteger,ini_path,_section_window,_key_window_top,wp.rcNormalPosition.top
	stdcall GetIniInteger,ini_path,_section_window,_key_window_left,wp.rcNormalPosition.left
	stdcall GetIniInteger,ini_path,_section_window,_key_window_right,wp.rcNormalPosition.right
	stdcall GetIniInteger,ini_path,_section_window,_key_window_bottom,wp.rcNormalPosition.bottom
	stdcall GetIniBit,ini_path,_section_window,_key_window_maximized,wp.flags,WPF_RESTORETOMAXIMIZED
	invoke	GetPrivateProfileString,_section_help,_key_help_path,help_path,help_path,1000h,ini_path
	mov	[wp.showCmd],SW_HIDE
	invoke	SetWindowPlacement,[hwnd],wp
	invoke	CreateFontIndirect,font
	mov	[hfont],eax
	invoke	CreateStatusWindow,WS_CHILD+WS_VISIBLE+SBS_SIZEGRIP,NULL,[hwnd],0
	or	eax,eax
	jz	failed
	mov	[hwnd_status],eax
	mov	[param_buffer],48h
	mov	[param_buffer+4],90h
	mov	[param_buffer+8],-1
	invoke	SendMessage,eax,SB_SETPARTS,3,param_buffer
	invoke	CreateWindowEx,0,_listbox_class,NULL,WS_CHILD+LBS_HASSTRINGS,0,0,0,0,[hwnd],NULL,[hinstance],NULL
	or	eax,eax
	jz	failed
	mov	[hwnd_history],eax
	invoke	CreateWindowEx,0,_tabctrl_class,NULL,WS_VISIBLE+WS_CHILD+TCS_FOCUSNEVER+TCS_BOTTOM,0,0,0,0,[hwnd],NULL,[hinstance],NULL
	or	eax,eax
	jz	failed
	mov	[hwnd_tabctrl],eax
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETITEMEXTRA,sizeof.EDITITEM-sizeof.TC_ITEMHEADER,0
	invoke	SendMessage,[hwnd_status],WM_GETFONT,0,0
	invoke	SendMessage,[hwnd_tabctrl],WM_SETFONT,eax,FALSE
	invoke	LoadBitmap,[hinstance],IDB_ASSIGN
	mov	ebx,eax
	invoke	GetObject,ebx,sizeof.BITMAP,bm
	invoke	ImageList_Create,[bm.bmWidth],[bm.bmHeight],ILC_COLOR4,1,0
	or	eax,eax
	jz	failed
	mov	[himl],eax
	invoke	ImageList_Add,[himl],ebx,NULL
	invoke	DeleteObject,ebx
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETIMAGELIST,0,[himl]
	invoke	SendMessage,[hwnd],FM_NEW,_untitled,0
	cmp	eax,-1
	je	failed
	invoke	DragAcceptFiles,[hwnd],TRUE
	mov	esi,[program_arguments]
      process_arguments:
	xor	ebx,ebx
	ARG_ASSIGN	= 1
	ARG_READONLY	= 2
      find_argument:
	lodsb
	cmp	al,20h
	je	find_argument
	cmp	al,'+'
	je	argument_assign
	cmp	al,'-'
	je	argument_readonly
	xor	ecx,ecx
	cmp	al,22h
	je	quoted_argument
	cmp	al,0Dh
	je	command_line_ok
	or	al,al
	jz	command_line_ok
	lea	edx,[esi-1]
      find_argument_end:
	inc	ecx
	lodsb
	cmp	al,20h
	je	argument_end
	cmp	al,0Dh
	je	argument_end
	or	al,al
	jz	argument_end
	jmp	find_argument_end
      argument_assign:
	or	bl,ARG_ASSIGN
	jmp	find_argument
      argument_readonly:
	or	bl,ARG_READONLY
	jmp	find_argument
      quoted_argument:
	mov	edx,esi
      find_quoted_argument_end:
	lodsb
	cmp	al,22h
	je	quoted_argument_end
	cmp	al,0Dh
	je	quoted_argument_end
	or	al,al
	jz	quoted_argument_end
	inc	ecx
	jmp	find_quoted_argument_end
      argument_end:
	dec	esi
      quoted_argument_end:
	push	eax edx esi
	mov	esi,edx
	mov	edi,path_buffer
	cmp	ecx,1000h-1
	jae	process_next_argument
	rep	movsb
	xor	al,al
	stosb
	mov	ecx,path_buffer+4000h
	sub	ecx,edi
	invoke	GetFullPathName,path_buffer,ecx,edi,param_buffer
	invoke	GetFileTitle,edi,name_buffer,100h
	mov	eax,FM_OPEN
	test	bl,ARG_READONLY
	jz	load_from_argument
	mov	eax,FM_OPENREADONLY
     load_from_argument:
	invoke	SendMessage,[hwnd],eax,name_buffer,edi
	cmp	eax,-1
	je	loading_error
	test	bl,ARG_ASSIGN
	jz	process_next_argument
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	invoke	SendMessage,[hwnd],FM_ASSIGN,eax,0
	jmp	process_next_argument
      loading_error:
	cinvoke wsprintf,string_buffer,_loading_error,path_buffer
	invoke	MessageBox,[hwnd],string_buffer,_caption,MB_ICONERROR+MB_OK
      process_next_argument:
	pop	esi edx eax
	jmp	process_arguments
      command_line_ok:
	xor	eax,eax
	jmp	finish
  wmcopydata:
	mov	ebx,[lparam]
	virtual at ebx
	cmd	COPYDATASTRUCT
	end	virtual
	mov	eax,[cmd.dwData]
	cmp	eax,CP_ARGUMENTS
	je	copy_arguments
	cmp	eax,CP_DIRECTORY
	jne	failed
	invoke	SetCurrentDirectory,[cmd.lpData]
	jmp	finish
      copy_arguments:
	mov	esi,[cmd.lpData]
	jmp	process_arguments
  wmgetminmaxinfo:
	mov	ebx,[lparam]
	virtual at ebx
	mmi	MINMAXINFO
	end	virtual
	mov	[mmi.ptMinTrackSize.x],240
	mov	[mmi.ptMinTrackSize.y],160
	jmp	finish
  wmsize:
	invoke	SendMessage,[hwnd_status],WM_SIZE,0,0
	xor	eax,eax
	mov	[rc.left],eax
	mov	[rc.top],eax
	mov	[rc.right],eax
	mov	[rc.bottom],eax
	invoke	SendMessage,[hwnd_tabctrl],TCM_ADJUSTRECT,TRUE,rc
	mov	esi,[rc.bottom]
	sub	esi,[rc.top]
	invoke	GetWindowRect,[hwnd_status],rc
	mov	ebx,[rc.bottom]
	sub	ebx,[rc.top]
	invoke	GetClientRect,[hwnd],rc
	sub	[rc.bottom],ebx
	sub	[rc.bottom],esi
	invoke	SetWindowPos,[hwnd_tabctrl],[hwnd_fedit],0,[rc.bottom],[rc.right],esi,0
	invoke	GetSystemMetrics,SM_CYFIXEDFRAME
	shl	eax,1
	add	[rc.bottom],eax
	invoke	MoveWindow,[hwnd_fedit],0,0,[rc.right],[rc.bottom],TRUE
	jmp	finish
  wmsetfocus:
	invoke	SetFocus,[hwnd_fedit]
	jmp	finish
  fmnew:
	invoke	CreateWindowEx,WS_EX_STATICEDGE,_fedit_class,NULL,WS_CHILD+WS_HSCROLL+WS_VSCROLL+ES_NOHIDESEL,0,0,0,0,[hwnd],NULL,[hinstance],NULL
	or	eax,eax
	jz	failed
	mov	[ei.header.mask],TCIF_TEXT+TCIF_PARAM
	mov	[ei.hwnd],eax
	mov	eax,[wparam]
	mov	[ei.header.pszText],eax
	and	[ei.pszpath],0
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEMCOUNT,0,0
	invoke	SendMessage,[hwnd_tabctrl],TCM_INSERTITEM,eax,ei
	mov	ebx,eax
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETCURSEL,eax,0
	invoke	SendMessage,[hwnd],FM_SELECT,ebx,0
	invoke	SetFocus,[hwnd]
	mov	eax,ebx
	jmp	finish
  fmopen:
	and	[command_flags],0
      allocate_path_buffer:
	invoke	VirtualAlloc,0,1000h,MEM_COMMIT,PAGE_READWRITE
	or	eax,eax
	jz	failed
	mov	edi,eax
	mov	esi,[lparam]
	mov	[lparam],edi
      copy_path_for_fedit:
	lodsb
	stosb
	or	al,al
	jnz	copy_path_for_fedit
	xor	ebx,ebx
      check_if_already_loaded:
	mov	[ei.header.mask],TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,ebx,ei
	or	eax,eax
	jz	load_file
	invoke	lstrcmpi,[ei.pszpath],[lparam]
	or	eax,eax
	jz	show_already_loaded
	inc	ebx
	jmp	check_if_already_loaded
      show_already_loaded:
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETCURSEL,ebx,0
	invoke	SendMessage,[hwnd],FM_SELECT,ebx,0
	jmp	update_fedit_mode
      load_file:
	invoke	CreateFile,[lparam],GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,0,0
	cmp	eax,-1
	je	open_failed
	mov	ebx,eax
	invoke	GetFileSize,ebx,NULL
	inc	eax
	push	eax
	invoke	VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or	eax,eax
	pop	ecx
	jz	load_out_of_memory
	dec	ecx
	push	MEM_RELEASE
	push	0
	push	eax
	mov	byte [eax+ecx],0
	invoke	ReadFile,ebx,eax,ecx,param_buffer,0
	invoke	CloseHandle,ebx
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEMCOUNT,0,0
	cmp	eax,1
	jne	new_fedit
	mov	[ei.header.mask],TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,0,ei
	cmp	[ei.pszpath],0
	jne	new_fedit
	invoke	SendMessage,[ei.hwnd],FEM_ISUNMODIFIED,0,0
	or	eax,eax
	jz	new_fedit
	mov	[ei.header.mask],TCIF_TEXT+TCIF_PARAM
	mov	eax,[wparam]
	mov	[ei.header.pszText],eax
	mov	eax,[lparam]
	mov	[ei.pszpath],eax
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETITEM,0,ei
	xor	ebx,ebx
	jmp	set_fedit_text
      new_fedit:
	invoke	SendMessage,[hwnd],FM_NEW,[wparam],0
	cmp	eax,-1
	jne	set_path
	add	esp,12
	jmp	open_failed
      set_path:
	mov	ebx,eax
	mov	[ei.header.mask],TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,ebx,ei
	mov	eax,[lparam]
	mov	[ei.pszpath],eax
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETITEM,ebx,ei
      set_fedit_text:
	invoke	SendMessage,[hwnd_fedit],WM_SETTEXT,0,dword [esp]
	call	[VirtualFree]
      update_fedit_mode:
	invoke	SendMessage,[hwnd_fedit],FEM_GETMODE,0,0
	and	eax,not FEMODE_READONLY
	test	[command_flags],1
	jz	set_fedit_mode
	or	eax,FEMODE_READONLY
      set_fedit_mode:
	invoke	SendMessage,[hwnd_fedit],FEM_SETMODE,eax,0
	jmp	update_status_bar
      load_out_of_memory:
	invoke	CloseHandle,ebx
      open_failed:
	invoke	VirtualFree,[lparam],0,MEM_RELEASE
	jmp	failed
  fmopenreadonly:
	or	[command_flags],1
	jmp	allocate_path_buffer
  fmsavemodified:
	or	ebx,-1
	jmp	save_single_file
  fmsave:
	xor	ebx,ebx
      save_single_file:
	mov	[ei.header.mask],TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,[wparam],ei
	or	eax,eax
	jz	failed
	cmp	[ei.pszpath],0
	je	failed
	invoke	SendMessage,[ei.hwnd],FEM_GETMODE,0,0
	test	eax,FEMODE_READONLY
	jnz	ok
	invoke	SendMessage,[ei.hwnd],FEM_ISUNMODIFIED,0,0
	and	eax,ebx
	jnz	ok
	invoke	SendMessage,[ei.hwnd],WM_GETTEXTLENGTH,0,0
	inc	eax
	mov	[wparam],eax
	invoke	VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or	eax,eax
	jz	failed
	mov	[lparam],eax
	invoke	CreateFile,[ei.pszpath],GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
	cmp	eax,-1
	je	save_failed
	mov	ebx,eax
	invoke	SendMessage,[ei.hwnd],WM_GETTEXT,[wparam],[lparam]
	invoke	WriteFile,ebx,[lparam],eax,param_buffer,0
	test	eax,eax
	jz	save_failed
	invoke	CloseHandle,ebx
	invoke	VirtualFree,[lparam],0,MEM_RELEASE
	invoke	SendMessage,[ei.hwnd],FEM_MARKUNMODIFIED,0,0
	xor	ebx,ebx
	mov	eax,[ei.hwnd]
	cmp	eax,[hwnd_fedit]
	je	update_status_bar
	xor	eax,eax
	jmp	finish
      save_failed:
	invoke	VirtualFree,[lparam],0,MEM_RELEASE
	jmp	failed
  fmcompile:
	mov	eax,[assigned_file]
	push	eax
	cmp	eax,-1
	jne	assigned_ok
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	mov	[assigned_file],eax
      assigned_ok:
	invoke	SendMessage,[hwnd_main],FM_SAVEMODIFIED,eax,0
	xor	ebx,ebx
	or	eax,eax
	jz	save_all
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETCURSEL,[assigned_file],0
	invoke	SendMessage,[hwnd_main],FM_SELECT,[assigned_file],0
	invoke	SendMessage,[hwnd_main],WM_COMMAND,IDM_SAVEAS,0
	or	eax,eax
	jz	save_all
	or	eax,-1
	jmp	compile_done
      save_all:
	mov	[ei.header.mask],TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,ebx,ei
	or	eax,eax
	jz	do_compile
	invoke	SendMessage,[hwnd_main],FM_SAVEMODIFIED,ebx,0
	inc	ebx
	jmp	save_all
      do_compile:
	mov	eax,[wparam]
	mov	[output_path],eax
	invoke	DialogBoxParam,[hinstance],IDD_COMPILE,[hwnd],CompileDialog,[assigned_file]
	cmp	eax,-1
	je	compile_done
	push	eax
	cmp	eax,2
	je	error_details
	or	eax,eax
	jnz	show_summary
	cmp	[lparam],FALSE
	jne	show_summary
	jmp	summary_shown
      show_summary:
	invoke	DialogBoxParam,[hinstance],IDD_SUMMARY,[hwnd],SummaryDialog,eax
	jmp	summary_shown
      error_details:
	invoke	DialogBoxParam,[hinstance],IDD_ERRORSUMMARY,[hwnd],SummaryDialog,eax
      summary_shown:
	invoke	HeapFree,[hheap],0,[stdout]
	invoke	HeapFree,[hheap],0,[stderr]
	pop	eax
      compile_done:
	pop	edx
	cmp	edx,-1
	jne	finish
	or	[assigned_file],-1
	jmp	finish
  fmselect:
	mov	[ei.header.mask],TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,[wparam],ei
	invoke	GetWindowLong,[hwnd_fedit],GWL_STYLE
	and	eax,not WS_VISIBLE
	invoke	SetWindowLong,[hwnd_fedit],GWL_STYLE,eax
	mov	ebx,[ei.hwnd]
	mov	[hwnd_fedit],ebx
	mov	eax,WS_CHILD+WS_HSCROLL+WS_VSCROLL+ES_NOHIDESEL
	or	eax,[fedit_style]
	invoke	SetWindowLong,ebx,GWL_STYLE,eax
	invoke	SendMessage,ebx,WM_SETFONT,[hfont],0
	invoke	SendMessage,ebx,FEM_SETTEXTCOLOR,[editor_colors],[editor_colors+4]
	invoke	SendMessage,ebx,FEM_SETSELCOLOR,[editor_colors+8],[editor_colors+12]
	invoke	SendMessage,ebx,FEM_SETSYNTAXHIGHLIGHT,asm_syntax_colors,fasm_syntax
	invoke	SendMessage,ebx,FEM_SETRIGHTCLICKMENU,[hmenu_edit],[hwnd]
	invoke	SendMessage,[hwnd],WM_SIZE,0,0
	invoke	ShowWindow,ebx,SW_SHOW
	invoke	UpdateWindow,ebx
	invoke	SetFocus,[hwnd]
	jmp	finish
  fmassign:
	mov	eax,[wparam]
	cmp	[assigned_file],-1
	je	new_assign
	push	eax
	mov	[ei.header.mask],TCIF_IMAGE
	mov	[ei.header.iImage],-1
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETITEM,[assigned_file],ei
	pop	eax
      new_assign:
	mov	[assigned_file],eax
	mov	[ei.header.mask],TCIF_IMAGE
	mov	[ei.header.iImage],0
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETITEM,eax,ei
	or	eax,eax
	jnz	fmgetassigned
	or	eax,-1
	mov	[assigned_file],eax
	jmp	finish
  fmgetassigned:
	mov	eax,[assigned_file]
	jmp	finish
  fmgetselected:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	jmp	finish
  fmgethandle:
	mov	[ei.header.mask],TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,[wparam],ei
	or	eax,eax
	jz	finish
	mov	eax,[ei.hwnd]
	jmp	finish
  wminitmenu:
	mov	esi,[hwnd_fedit]
	invoke	SendMessage,esi,EM_CANUNDO,0,0
	or	eax,eax
	setz	bl
	neg	bl
	and	ebx,MF_GRAYED
	or	ebx,MF_BYCOMMAND
	invoke	EnableMenuItem,[wparam],IDM_UNDO,ebx
	invoke	SendMessage,esi,FEM_CANREDO,0,0
	or	eax,eax
	setz	bl
	neg	bl
	and	ebx,MF_GRAYED
	or	ebx,MF_BYCOMMAND
	invoke	EnableMenuItem,[wparam],IDM_REDO,ebx
	invoke	SendMessage,esi,FEM_GETPOS,fepos,0
	mov	eax,[fepos.selectionLine]
	cmp	eax,[fepos.caretLine]
	sete	bh
	mov	eax,[fepos.selectionPosition]
	cmp	eax,[fepos.caretPosition]
	sete	bl
	and	bl,bh
	neg	bl
	and	ebx,MF_GRAYED
	or	ebx,MF_BYCOMMAND
	invoke	EnableMenuItem,[wparam],IDM_CUT,ebx
	invoke	EnableMenuItem,[wparam],IDM_COPY,ebx
	invoke	EnableMenuItem,[wparam],IDM_DELETE,ebx
	invoke	IsClipboardFormatAvailable,CF_TEXT
	neg	al
	not	al
	and	eax,MF_GRAYED
	or	eax,MF_BYCOMMAND
	invoke	EnableMenuItem,[wparam],IDM_PASTE,eax
	invoke	SendMessage,esi,FEM_GETMODE,0,0
	mov	ebx,eax
	test	eax,FEMODE_VERTICALSEL
	setnz	al
	neg	al
	and	eax,MF_CHECKED
	or	eax,MF_BYCOMMAND
	invoke	CheckMenuItem,[wparam],IDM_VERTICAL,eax
	test	ebx,FEMODE_READONLY
	setnz	bl
	and	ebx,MF_GRAYED
	or	ebx,MF_BYCOMMAND
	invoke	EnableMenuItem,[wparam],IDM_CUT,ebx
	invoke	EnableMenuItem,[wparam],IDM_PASTE,ebx
	invoke	EnableMenuItem,[wparam],IDM_DELETE,ebx
	invoke	EnableMenuItem,[wparam],IDM_REPLACE,ebx
	invoke	SendMessage,esi,FEM_CANFINDNEXT,0,0
	or	eax,eax
	setz	al
	neg	al
	and	eax,MF_GRAYED
	or	eax,MF_BYCOMMAND
	invoke	EnableMenuItem,[wparam],IDM_FINDNEXT,eax
	test	[fedit_style],FES_SECURESEL
	setnz	al
	neg	al
	and	eax,MF_CHECKED
	or	eax,MF_BYCOMMAND
	invoke	CheckMenuItem,[wparam],IDM_SECURESEL,eax
	test	[fedit_style],FES_AUTOBRACKETS
	setnz	al
	neg	al
	and	eax,MF_CHECKED
	or	eax,MF_BYCOMMAND
	invoke	CheckMenuItem,[wparam],IDM_AUTOBRACKETS,eax
	test	[fedit_style],FES_AUTOINDENT
	setnz	al
	neg	al
	and	eax,MF_CHECKED
	or	eax,MF_BYCOMMAND
	invoke	CheckMenuItem,[wparam],IDM_AUTOINDENT,eax
	test	[fedit_style],FES_SMARTTABS
	setnz	al
	neg	al
	and	eax,MF_CHECKED
	or	eax,MF_BYCOMMAND
	invoke	CheckMenuItem,[wparam],IDM_SMARTTABS,eax
	test	[fedit_style],FES_OPTIMALFILL
	setnz	al
	neg	al
	and	eax,MF_CHECKED
	or	eax,MF_BYCOMMAND
	invoke	CheckMenuItem,[wparam],IDM_OPTIMALFILL,eax
	test	[fedit_style],FES_REVIVEDEADKEYS
	setnz	al
	neg	al
	and	eax,MF_CHECKED
	or	eax,MF_BYCOMMAND
	invoke	CheckMenuItem,[wparam],IDM_REVIVEDEADKEYS,eax
	test	[fedit_style],FES_TIMESCROLL
	setnz	al
	neg	al
	and	eax,MF_CHECKED
	or	eax,MF_BYCOMMAND
	invoke	CheckMenuItem,[wparam],IDM_TIMESCROLL,eax
	mov	eax,[instance_flags]
	neg	al
	and	eax,MF_CHECKED
	or	eax,MF_BYCOMMAND
	invoke	CheckMenuItem,[wparam],IDM_ONEINSTANCEONLY,eax
	cmp	[help_path],0
	sete	bl
	neg	bl
	and	ebx,MF_GRAYED
	or	ebx,MF_BYCOMMAND
	invoke	EnableMenuItem,[wparam],IDM_CONTENTS,ebx
	invoke	EnableMenuItem,[wparam],IDM_KEYWORD,ebx
	jmp	finish
  wmcommand:
	mov	eax,[wparam]
	mov	ebx,[lparam]
	or	ebx,ebx
	jz	menu_command
	cmp	ebx,[hwnd_fedit]
	jne	finish
	xor	ebx,ebx
	shr	eax,16
	cmp	eax,FEN_SETFOCUS
	je	update_status_bar
	cmp	eax,FEN_TEXTCHANGE
	je	update_status_bar
	cmp	eax,FEN_POSCHANGE
	je	update_status_bar
	cmp	eax,FEN_OUTOFMEMORY
	je	not_enough_mem
	jmp	finish
      update_status_bar:
	invoke	SendMessage,[hwnd_fedit],FEM_GETPOS,fepos,0
	cinvoke wsprintf,string_buffer,_row_column,[fepos.caretLine],[fepos.caretPosition]
	invoke	SendMessage,[hwnd_status],SB_SETTEXT,0,string_buffer
	mov	esi,_null
	invoke	SendMessage,[hwnd_fedit],FEM_GETMODE,0,0
	test	eax,FEMODE_READONLY
	jnz	readonly_status
	invoke	SendMessage,[hwnd_fedit],FEM_ISUNMODIFIED,0,0
	or	eax,eax
	jnz	modified_status_ok
	mov	esi,_modified_status
	jmp	modified_status_ok
      readonly_status:
	mov	esi,_readonly_status
      modified_status_ok:
	invoke	SendMessage,[hwnd_status],SB_SETTEXT,1,esi
	mov	eax,ebx
	jmp	finish
      not_enough_mem:
	invoke	SendMessage,[hwnd_fedit],FEM_RELEASESEARCH,0,0
	invoke	MessageBox,[hwnd],_memory_error,_caption,MB_ICONERROR+MB_OK
	mov	eax,ebx
	jmp	finish
  menu_command:
	and	eax,0FFFFh
	mov	ebx,[hwnd_fedit]
	cmp	eax,IDM_NEW
	je	new_file
	cmp	eax,IDM_OPEN
	je	open_file
	cmp	eax,IDM_SAVE
	je	save_file
	cmp	eax,IDM_SAVEAS
	je	save_file_as
	cmp	eax,IDM_NEXT
	je	next_file
	cmp	eax,IDM_PREVIOUS
	je	previous_file
	cmp	eax,IDM_OPENFOLDER
	je	open_folder
	cmp	eax,IDM_CLOSE
	je	close_file
	cmp	eax,IDM_EXIT
	je	exit
	cmp	eax,IDM_UNDO
	je	undo
	cmp	eax,IDM_REDO
	je	redo
	cmp	eax,IDM_DISCARD_UNDO
	je	discard_undo
	cmp	eax,IDM_CUT
	je	cut
	cmp	eax,IDM_COPY
	je	copy
	cmp	eax,IDM_PASTE
	je	paste
	cmp	eax,IDM_DELETE
	je	delete
	cmp	eax,IDM_SELECTALL
	je	select_all
	cmp	eax,IDM_VERTICAL
	je	vertical
	cmp	eax,IDM_READONLY
	je	read_only
	cmp	eax,IDM_POSITION
	je	position
	cmp	eax,IDM_FIND
	je	find
	cmp	eax,IDM_FINDNEXT
	je	findnext
	cmp	eax,IDM_REPLACE
	je	replace
	cmp	eax,IDM_RUN
	je	run
	cmp	eax,IDM_COMPILE
	je	compile
	cmp	eax,IDM_ASSIGN
	je	assign
	cmp	eax,IDM_APPEARANCE
	je	appearance
	cmp	eax,IDM_COMPILERSETUP
	je	compiler_setup
	cmp	eax,IDM_SECURESEL
	je	option_securesel
	cmp	eax,IDM_AUTOBRACKETS
	je	option_autobrackets
	cmp	eax,IDM_AUTOINDENT
	je	option_autoindent
	cmp	eax,IDM_SMARTTABS
	je	option_smarttabs
	cmp	eax,IDM_OPTIMALFILL
	je	option_optimalfill
	cmp	eax,IDM_REVIVEDEADKEYS
	je	option_revivedeadkeys
	cmp	eax,IDM_TIMESCROLL
	je	option_timescroll
	cmp	eax,IDM_ONEINSTANCEONLY
	je	option_oneinstanceonly
	cmp	eax,IDM_CALCULATOR
	je	calculator
	cmp	eax,IDM_CONTENTS
	je	contents
	cmp	eax,IDM_KEYWORD
	je	keyword
	cmp	eax,IDM_PICKHELP
	je	pick_help
	cmp	eax,IDM_ABOUT
	je	about
	sub	eax,IDM_SELECTFILE
	jc	finish
	cmp	eax,9
	ja	finish
	mov	ebx,eax
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEMCOUNT,0,0
	cmp	ebx,eax
	ja	finish
	dec	ebx
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETCURSEL,ebx,0
	invoke	SendMessage,[hwnd],FM_SELECT,ebx,0
	jmp	finish
  new_file:
	invoke	SendMessage,[hwnd],FM_NEW,_untitled,0
	jmp	finish
  open_file:
	mov	[ofn.lpstrFile],path_buffer
	mov	[path_buffer],0
	mov	[ofn.lpstrFilter],asm_filter
	mov	[ofn.Flags],OFN_EXPLORER+OFN_ALLOWMULTISELECT+OFN_FILEMUSTEXIST
	mov	[ofn.lpstrFileTitle],name_buffer
	mov	[ofn.lpstrTitle],NULL
	invoke	GetOpenFileName,ofn
	or	eax,eax
	jz	finish
	mov	ebx,FM_OPEN
	test	[ofn.Flags],OFN_READONLY
	jz	open_chosen_files
	mov	ebx,FM_OPENREADONLY
      open_chosen_files:
	test	[ofn.Flags],OFN_ALLOWMULTISELECT
	jz	open_single_file
	mov	esi,path_buffer
	movzx	eax,[ofn.nFileOffset]
	add	esi,eax
	mov	byte [esi-1],'\'
	mov	edi,esi
      open_multiple_files:
	cmp	byte [esi],0
	je	finish
	push	edi
      move_file_name:
	lodsb
	stosb
	or	al,al
	jnz	move_file_name
	pop	edi
	invoke	GetFileTitle,path_buffer,name_buffer,100h
	invoke	SendMessage,[hwnd],ebx,name_buffer,path_buffer
	cmp	eax,-1
	jne	open_multiple_files
	invoke	wvsprintf,string_buffer,_loading_error,ofn.lpstrFile
	invoke	MessageBox,[hwnd],string_buffer,_caption,MB_ICONERROR+MB_OK
	jmp	open_multiple_files
      open_single_file:
	invoke	SendMessage,[hwnd],ebx,name_buffer,path_buffer
	cmp	eax,-1
	jne	finish
	invoke	wvsprintf,string_buffer,_loading_error,ofn.lpstrFile
	invoke	MessageBox,[hwnd],string_buffer,_caption,MB_ICONERROR+MB_OK
	jmp	finish
  save_file:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	invoke	SendMessage,[hwnd],FM_SAVE,eax,0
	or	eax,eax
	jnz	save_file_as
	jmp	finish
  save_file_as:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	mov	ebx,eax
	mov	[ei.header.mask],TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,ebx,ei
	mov	eax,[ei.pszpath]
	or	eax,eax
	jnz	alloc_ok
	invoke	VirtualAlloc,0,1000h,MEM_COMMIT,PAGE_READWRITE
	mov	[ei.pszpath],eax
	and	byte [eax],0
      alloc_ok:
	mov	[lparam],eax
	mov	[ofn.lpstrFile],eax
	mov	[ofn.lpstrFilter],asm_filter
	mov	[ofn.Flags],OFN_EXPLORER+OFN_HIDEREADONLY+OFN_OVERWRITEPROMPT
	mov	[ofn.lpstrTitle],NULL
	invoke	GetSaveFileName,ofn
	or	eax,eax
	jz	save_cancelled
	mov	eax,[ei.pszpath]
	mov	[ei.header.pszText],name_buffer
	mov	[ei.header.mask],TCIF_TEXT+TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETITEM,ebx,ei
	invoke	SendMessage,[hwnd],FM_SAVE,ebx,0
	xor	esi,esi
      check_if_overwritten:
	cmp	esi,ebx
	je	not_overwritten
	mov	[ei.header.mask],TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,esi,ei
	or	eax,eax
	jz	save_ok
	invoke	lstrcmpi,[ei.pszpath],[lparam]
	or	eax,eax
	jz	remove_overwritten
      not_overwritten:
	inc	esi
	jmp	check_if_overwritten
      remove_overwritten:
	invoke	VirtualFree,[ei.pszpath],0,MEM_RELEASE
	invoke	SendMessage,[hwnd_tabctrl],TCM_DELETEITEM,esi,0
	cmp	[assigned_file],-1
	je	save_ok
	cmp	esi,[assigned_file]
	ja	save_ok
	je	assigned_overwritten
	dec	[assigned_file]
	jmp	save_ok
      assigned_overwritten:
	mov	[assigned_file],-1
      save_ok:
	xor	eax,eax
	jmp	finish
      save_cancelled:
	mov	eax,[ei.pszpath]
	cmp	byte [eax],0
	jne	preserve_save_path
	invoke	VirtualFree,[ei.pszpath],0,MEM_RELEASE
	and	[ei.pszpath],0
      preserve_save_path:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETITEM,eax,ei
	jmp	finish
  next_file:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEMCOUNT,0,0
	mov	ebx,eax
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	inc	eax
	cmp	eax,ebx
	jb	select_file
	xor	eax,eax
      select_file:
	push	eax
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETCURSEL,eax,0
	pop	eax
	invoke	SendMessage,[hwnd],FM_SELECT,eax,0
	jmp	finish
  previous_file:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	sub	eax,1
	jnc	select_file
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEMCOUNT,0,0
	dec	eax
	call	select_file
	jmp	select_file
  open_folder:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,eax,ei
	or	eax,eax
	jz	finish
	mov	eax,[ei.pszpath]
	or	eax,eax
	jz	finish
	invoke	GetFullPathName,eax,1000h,path_buffer,param_buffer
	mov	edi,[param_buffer]
	xor	al,al
	stosb
	invoke	ShellExecute,HWND_DESKTOP,NULL,path_buffer,NULL,NULL,SW_SHOWNORMAL
	jmp	finish
  close_file:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEMCOUNT,0,0
	cmp	eax,1
	jbe	close_window
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	mov	ebx,eax
	mov	[ei.header.mask],TCIF_PARAM+TCIF_TEXT
	mov	[ei.header.pszText],name_buffer
	mov	[ei.header.cchTextMax],100h
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,ebx,ei
	mov	eax,[ei.hwnd]
	mov	[wparam],eax
	invoke	SendMessage,eax,FEM_ISUNMODIFIED,0,0
	or	eax,eax
	jz	close_modified
	cmp	[ei.pszpath],0
	jne	do_close
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEMCOUNT,0,0
	cmp	eax,1
	jne	do_close
	jmp	failed
      close_modified:
	mov	eax,MB_ICONQUESTION+MB_YESNOCANCEL
	or	eax,[lparam]
	invoke	MessageBox,[hwnd],_saving_question,[ei.header.pszText],eax
	cmp	eax,IDCANCEL
	je	failed
	cmp	eax,IDNO
	je	do_close
	invoke	SendMessage,[hwnd],WM_COMMAND,IDM_SAVE,0
	or	eax,eax
	jnz	failed
      do_close:
	cmp	[ei.pszpath],0
	je	delete_tab
	invoke	VirtualFree,[ei.pszpath],0,MEM_RELEASE
      delete_tab:
	invoke	SendMessage,[hwnd_tabctrl],TCM_DELETEITEM,ebx,0
	cmp	ebx,[assigned_file]
	jg	tab_deleted
	je	assigned_deleted
	dec	[assigned_file]
	jmp	tab_deleted
      assigned_deleted:
	mov	[assigned_file],-1
      tab_deleted:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEMCOUNT,0,0
	dec	eax
	cmp	eax,ebx
	jge	select_next
	sub	ebx,1
	jnc	select_next
	invoke	SendMessage,[hwnd],FM_NEW,_untitled,0
	jmp	destroy_fedit
      select_next:
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETCURSEL,ebx,0
	invoke	SendMessage,[hwnd],FM_SELECT,ebx,0
      destroy_fedit:
	invoke	DestroyWindow,[wparam]
	xor	eax,eax
	jmp	finish
  exit:
	mov	[lparam],0
	jmp	close_window
  undo:
	invoke	SendMessage,ebx,WM_UNDO,0,0
	jmp	finish
  redo:
	invoke	SendMessage,ebx,FEM_REDO,0,0
	jmp	finish
  cut:
	invoke	SendMessage,ebx,WM_CUT,0,0
	jmp	finish
  copy:
	invoke	SendMessage,ebx,WM_COPY,0,0
	jmp	finish
  paste:
	invoke	SendMessage,ebx,WM_PASTE,0,0
	jmp	finish
  delete:
	invoke	SendMessage,ebx,WM_CLEAR,0,0
	jmp	finish
  discard_undo:
	invoke	SendMessage,ebx,EM_EMPTYUNDOBUFFER,0,0
	jmp	finish
  select_all:
	mov	[fepos.selectionLine],1
	mov	[fepos.selectionPosition],1
	mov	[fepos.caretLine],-1
	mov	[fepos.caretPosition],1
	invoke	SendMessage,ebx,FEM_SETPOS,fepos,0
	invoke	SendMessage,ebx,FEM_GETPOS,fepos,0
	invoke	SendMessage,ebx,FEM_GETLINELENGTH,[fepos.caretLine],0
	inc	eax
	mov	[fepos.caretPosition],eax
	invoke	SendMessage,ebx,FEM_SETPOS,fepos,0
	jmp	finish
  vertical:
	invoke	SendMessage,ebx,FEM_GETMODE,0,0
	xor	eax,FEMODE_VERTICALSEL
	invoke	SendMessage,ebx,FEM_SETMODE,eax,0
	jmp	finish
  read_only:
	invoke	SendMessage,ebx,FEM_GETMODE,0,0
	xor	eax,FEMODE_READONLY
	invoke	SendMessage,ebx,FEM_SETMODE,eax,0
	xor	ebx,ebx
	jmp	update_status_bar
  position:
	invoke	DialogBoxParam,[hinstance],IDD_POSITION,[hwnd],PositionDialog,0
	jmp	finish
  find:
	invoke	DialogBoxParam,[hinstance],IDD_FIND,[hwnd],FindDialog,0
	or	eax,eax
	jz	finish
	invoke	SendMessage,ebx,FEM_FINDFIRST,[search_settings],search_string
	or	eax,eax
	jnz	finish
      not_found:
	mov	[param_buffer],1000h
	invoke	SendMessage,[hwnd_fedit],FEM_GETSEARCHTEXT,search_string,param_buffer
	invoke	SendMessage,[hwnd_fedit],FEM_GETSEARCHFLAGS,0,0
	mov	esi,_not_found
	test	eax,FEFIND_INWHOLETEXT
	jnz	make_not_found_message
	mov	esi,_not_found_after
	test	eax,FEFIND_BACKWARD
	jz	make_not_found_message
	mov	esi,_not_found_before
      make_not_found_message:
	cinvoke wsprintf,string_buffer,esi,search_string
	invoke	SendMessage,[hwnd_fedit],FEM_RELEASESEARCH,0,0
	invoke	MessageBox,[hwnd],string_buffer,_find,MB_ICONINFORMATION+MB_OK
	jmp	finish
  findnext:
	invoke	SendMessage,ebx,FEM_FINDNEXT,0,0
	or	eax,eax
	jz	not_found
	jmp	finish
  replace:
	invoke	DialogBoxParam,[hinstance],IDD_REPLACE,[hwnd],ReplaceDialog,0
	or	eax,eax
	jz	finish
	mov	[replaces_count],0
	invoke	SendMessage,ebx,FEM_BEGINOPERATION,0,0
	test	[command_flags],1
	jz	.start_replacing
	invoke	SendMessage,ebx,FEM_ENDOPERATION,0,0
      .start_replacing:
	invoke	SendMessage,ebx,FEM_FINDFIRST,[search_settings],search_string
	or	eax,eax
	jz	.not_found
	invoke	SendMessage,ebx,FEM_GETMODE,0,0
	push	eax
	and	eax,not (FEMODE_VERTICALSEL + FEMODE_OVERWRITE)
	invoke	SendMessage,ebx,FEM_SETMODE,eax,0
      .confirm_replace:
	test	[command_flags],1
	jz	.replace
	invoke	UpdateWindow,edi
	invoke	MessageBox,[hwnd],_replace_prompt,_replace,MB_ICONQUESTION+MB_YESNOCANCEL
	cmp	eax,IDCANCEL
	je	.replace_finish
	cmp	eax,IDNO
	je	.replace_next
      .replace:
	push	ebx edi
	invoke	SendMessage,ebx,EM_REPLACESEL,FALSE,replace_string
	pop	edi ebx
	inc	[replaces_count]
      .replace_next:
	invoke	SendMessage,ebx,FEM_FINDNEXT,0,0
	or	eax,eax
	jnz	.confirm_replace
      .replace_finish:
	pop	eax
	invoke	SendMessage,ebx,FEM_SETMODE,eax,0
	test	[command_flags],1
	jnz	.replace_summary
	invoke	SendMessage,ebx,FEM_ENDOPERATION,0,0
      .replace_summary:
	invoke	SendMessage,[hwnd_fedit],FEM_RELEASESEARCH,0,0
	cinvoke wsprintf,string_buffer,_replaces_made,[replaces_count]
	invoke	MessageBox,[hwnd],string_buffer,_find,MB_ICONINFORMATION+MB_OK
	jmp	finish
      .not_found:
	invoke	SendMessage,ebx,FEM_ENDOPERATION,0,0
	jmp	not_found
  run:
	and	[command_flags],0
	invoke	SendMessage,[hwnd],FM_COMPILE,0,FALSE
	or	eax,eax
	jnz	finish
	mov	[sinfo.cb],sizeof.STARTUPINFO
	mov	[sinfo.dwFlags],0
	invoke	GetFullPathName,executable_path,1000h,path_buffer,param_buffer
	mov	edx,[param_buffer]
	mov	byte [edx-1],0
	invoke	CreateProcess,executable_path,NULL,NULL,NULL,FALSE,NORMAL_PRIORITY_CLASS,NULL,path_buffer,sinfo,pinfo
	invoke	CloseHandle,[pinfo.hThread]
	invoke	CloseHandle,[pinfo.hProcess]
	jmp	finish
  compile:
	invoke	SendMessage,[hwnd],FM_COMPILE,0,TRUE
	jmp	finish
  assign:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	cmp	eax,[assigned_file]
	jne	do_assign
	or	eax,-1
      do_assign:
	invoke	SendMessage,[hwnd],FM_ASSIGN,eax,0
	jmp	finish
  appearance:
	invoke	DialogBoxParam,[hinstance],IDD_APPEARANCE,[hwnd],AppearanceSetup,0
	or	eax,eax
	jnz	update
	jmp	finish
  compiler_setup:
	invoke	DialogBoxParam,[hinstance],IDD_COMPILERSETUP,[hwnd],CompilerSetup,0
	jmp	finish
  option_securesel:
	xor	[fedit_style],FES_SECURESEL
	jmp	update
  option_autobrackets:
	xor	[fedit_style],FES_AUTOBRACKETS
	jmp	update
  option_autoindent:
	xor	[fedit_style],FES_AUTOINDENT
	jmp	update
  option_smarttabs:
	xor	[fedit_style],FES_SMARTTABS
	jmp	update
  option_optimalfill:
	xor	[fedit_style],FES_OPTIMALFILL
	jmp	update
  option_revivedeadkeys:
	xor	[fedit_style],FES_REVIVEDEADKEYS
	jmp	update
  option_timescroll:
	xor	[fedit_style],FES_TIMESCROLL
	jmp	update
  option_oneinstanceonly:
	xor	[instance_flags],1
	stdcall WriteIniBit,ini_path,_section_options,_key_options_oneinstanceonly,[instance_flags],1
	jmp	finish
  calculator:
	invoke	DialogBoxParam,[hinstance],IDD_CALCULATOR,[hwnd],CalculatorDialog,0
	jmp	finish
  contents:
	call	get_help_file_extension
	cmp	eax,'.hlp'
	je	winhelp_contents
	call	check_htmlhelp
	jc	winhelp_contents
	invoke	HtmlHelp,[hwnd],help_path,HH_DISPLAY_TOPIC,0
	jmp	finish
      winhelp_contents:
	invoke	WinHelp,[hwnd],help_path,HELP_FINDER,0
	jmp	finish
      get_help_file_extension:
	mov	esi,help_path
      skip_help_path:
	lodsb
	or	al,al
	jnz	skip_help_path
	mov	ebx,characters
	dec	esi
	mov	ecx,4
      convert_extension:
	dec	esi
	shl	eax,8
	mov	al,[esi]
	xlatb
	loop	convert_extension
	retn
      check_htmlhelp:
	cmp	[HtmlHelp],0
	jne	htmlhelp_ok
	invoke	LoadLibrary,_htmlhelp_library
	or	eax,eax
	jz	htmlhelp_unavailable
	invoke	GetProcAddress,eax,_htmlhelp_api
	or	eax,eax
	jz	htmlhelp_unavailable
	mov	[HtmlHelp],eax
      htmlhelp_ok:
	clc
	retn
      htmlhelp_unavailable:
	stc
	retn
  keyword:
	invoke	SendMessage,[hwnd_fedit],FEM_GETWORDATCARET,1000h,string_buffer
	call	get_help_file_extension
	cmp	eax,'.hlp'
	je	winhelp_keyword
	call	check_htmlhelp
	jc	winhelp_keyword
	mov	[hhkey.cbStruct],sizeof.HH_AKLINK
	mov	[hhkey.pszKeywords],string_buffer
	mov	[hhkey.pszUrl],0
	mov	[hhkey.fIndexOnFail],TRUE
	invoke	HtmlHelp,[hwnd],help_path,HH_DISPLAY_TOPIC,0
	invoke	HtmlHelp,[hwnd],help_path,HH_KEYWORD_LOOKUP,hhkey
	jmp	finish
      winhelp_keyword:
	invoke	WinHelp,[hwnd],help_path,HELP_KEY,string_buffer
	jmp	finish
  pick_help:
	mov	[ofn.lpstrFile],help_path
	mov	[ofn.lpstrFilter],help_filter
	mov	[ofn.Flags],OFN_EXPLORER+OFN_FILEMUSTEXIST+OFN_HIDEREADONLY
	mov	[ofn.lpstrTitle],_pick_help
	invoke	GetOpenFileName,ofn
	jmp	finish
  about:
	invoke	DialogBoxParam,[hinstance],IDD_ABOUT,[hwnd],AboutDialog,0
	jmp	finish
  failed:
	or	eax,-1
	jmp	finish
  wmnotify:
	mov	ebx,[lparam]
	virtual at ebx
	nmh	NMHDR
	end	virtual
	cmp	[nmh.code],NM_RCLICK
	je	rclick
	cmp	[nmh.code],TCN_SELCHANGING
	je	selchanging
	cmp	[nmh.code],TCN_SELCHANGE
	jne	finish
      update:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	invoke	SendMessage,[hwnd],FM_SELECT,eax,0
	jmp	finish
      selchanging:
	xor	eax,eax
	jmp	finish
      rclick:
	invoke	GetCursorPos,pt
	invoke	GetWindowRect,[hwnd_tabctrl],rc
	mov	eax,[pt.x]
	sub	eax,[rc.left]
	mov	[tcht.pt.x],eax
	mov	eax,[pt.y]
	sub	eax,[rc.top]
	mov	[tcht.pt.y],eax
	invoke	SendMessage,[hwnd_tabctrl],TCM_HITTEST,0,tcht
	cmp	eax,-1
	je	finish
	mov	ebx,eax
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETCURSEL,ebx,0
	invoke	SendMessage,[hwnd],FM_SELECT,ebx,0
	cmp	ebx,[assigned_file]
	sete	al
	neg	al
	and	eax,MF_CHECKED
	or	eax,MF_BYCOMMAND
	invoke	CheckMenuItem,[hmenu_tab],IDM_ASSIGN,eax
	invoke	SendMessage,[hwnd_fedit],FEM_GETMODE,0,0
	test	eax,FEMODE_READONLY
	setnz	al
	neg	al
	and	eax,MF_CHECKED
	or	eax,MF_BYCOMMAND
	invoke	CheckMenuItem,[hmenu_tab],IDM_READONLY,eax
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,ebx,ei
	invoke	SendMessage,[hwnd_fedit],FEM_ISUNMODIFIED,0,0
	test	eax,eax
	setz	al
	cmp	[ei.pszpath],0
	setz	ah
	or	al,ah
	neg	al
	and	eax,MF_GRAYED
	or	eax,MF_BYCOMMAND
	invoke	EnableMenuItem,[hmenu_tab],IDM_READONLY,eax
	invoke	TrackPopupMenu,[hmenu_tab],TPM_RIGHTBUTTON,[pt.x],[pt.y],0,[hwnd],0
	jmp	finish
  wmdropfiles:
	invoke	DragQueryFile,[wparam],-1,NULL,0
	xor	ebx,ebx
      drop_files:
	cmp	ebx,eax
	je	drag_finish
	push	eax
	invoke	DragQueryFile,[wparam],ebx,path_buffer,1000h
	push	ebx
	invoke	GetFileTitle,path_buffer,name_buffer,100h
	invoke	SendMessage,[hwnd],FM_OPEN,name_buffer,path_buffer
	cmp	eax,-1
	jne	drop_ok
	cinvoke wsprintf,string_buffer,_loading_error,path_buffer
	invoke	MessageBox,[hwnd],string_buffer,_caption,MB_ICONERROR+MB_OK
      drop_ok:
	pop	ebx eax
	inc	ebx
	jmp	drop_files
      drag_finish:
	invoke	DragFinish,[wparam]
	xor	eax,eax
	jmp	finish
  wmclose:
	mov	[lparam],MB_DEFBUTTON2
      close_window:
	mov	[wparam],0
      check_before_exiting:
	mov	[ei.header.mask],TCIF_PARAM+TCIF_TEXT
	mov	[ei.header.pszText],name_buffer
	mov	[ei.header.cchTextMax],100h
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,[wparam],ei
	or	eax,eax
	jz	check_done
	mov	esi,[ei.pszpath]
	invoke	SendMessage,[ei.hwnd],FEM_ISUNMODIFIED,0,0
	or	eax,eax
	jnz	check_next
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETCURSEL,[wparam],0
	invoke	SendMessage,[hwnd],FM_SELECT,[wparam],0
	mov	eax,MB_ICONQUESTION+MB_YESNOCANCEL
	or	eax,[lparam]
	invoke	MessageBox,[hwnd],_saving_question,[ei.header.pszText],eax
	cmp	eax,IDCANCEL
	je	finish
	cmp	eax,IDNO
	je	check_next
	invoke	SendMessage,[hwnd],WM_COMMAND,IDM_SAVE,0
	or	eax,eax
	jnz	finish
      check_next:
	inc	[wparam]
	jmp	check_before_exiting
      check_done:
	mov	[wparam],0
      release_paths:
	mov	[ei.header.mask],TCIF_PARAM+TCIF_TEXT
	mov	[ei.header.pszText],name_buffer
	mov	[ei.header.cchTextMax],100h
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,[wparam],ei
	or	eax,eax
	jz	quit
	mov	esi,[ei.pszpath]
	or	esi,esi
	jz	release_next_path
	invoke	VirtualFree,esi,0,MEM_RELEASE
      release_next_path:
	inc	[wparam]
	jmp	release_paths
      quit:
	invoke	WritePrivateProfileString,_section_compiler,_key_compiler_header,source_header,ini_path
	stdcall WriteIniInteger,ini_path,_section_compiler,_key_compiler_max_passes,[maximum_number_of_passes]
	stdcall WriteIniInteger,ini_path,_section_compiler,_key_compiler_max_recursion,[maximum_depth_of_stack]
	stdcall WriteIniInteger,ini_path,_section_compiler,_key_compiler_priority,[compiler_priority]
	stdcall WriteIniBit,ini_path,_section_options,_key_options_securesel,[fedit_style],FES_SECURESEL
	stdcall WriteIniBit,ini_path,_section_options,_key_options_autobrackets,[fedit_style],FES_AUTOBRACKETS
	stdcall WriteIniBit,ini_path,_section_options,_key_options_autoindent,[fedit_style],FES_AUTOINDENT
	stdcall WriteIniBit,ini_path,_section_options,_key_options_smarttabs,[fedit_style],FES_SMARTTABS
	stdcall WriteIniBit,ini_path,_section_options,_key_options_optimalfill,[fedit_style],FES_OPTIMALFILL
	stdcall WriteIniBit,ini_path,_section_options,_key_options_revivedeadkeys,[fedit_style],FES_REVIVEDEADKEYS
	stdcall WriteIniBit,ini_path,_section_options,_key_options_consolecaret,[fedit_style],FES_CONSOLECARET
	stdcall WriteIniBit,ini_path,_section_options,_key_options_timescroll,[fedit_style],FES_TIMESCROLL
	stdcall WriteIniColor,ini_path,_section_colors,_key_color_text,[editor_colors]
	stdcall WriteIniColor,ini_path,_section_colors,_key_color_background,[editor_colors+4]
	stdcall WriteIniColor,ini_path,_section_colors,_key_color_seltext,[editor_colors+8]
	stdcall WriteIniColor,ini_path,_section_colors,_key_color_selbackground,[editor_colors+12]
	stdcall WriteIniColor,ini_path,_section_colors,_key_color_symbols,[asm_syntax_colors]
	stdcall WriteIniColor,ini_path,_section_colors,_key_color_numbers,[asm_syntax_colors+4]
	stdcall WriteIniColor,ini_path,_section_colors,_key_color_strings,[asm_syntax_colors+8]
	stdcall WriteIniColor,ini_path,_section_colors,_key_color_comments,[asm_syntax_colors+12]
	invoke	WritePrivateProfileString,_section_font,_key_font_face,font.lfFaceName,ini_path
	stdcall WriteIniInteger,ini_path,_section_font,_key_font_height,[font.lfHeight]
	stdcall WriteIniInteger,ini_path,_section_font,_key_font_width,[font.lfWidth]
	stdcall WriteIniInteger,ini_path,_section_font,_key_font_weight,[font.lfWeight]
	stdcall WriteIniBit,ini_path,_section_font,_key_font_italic,dword [font.lfItalic],1
	movzx	eax,[font.lfCharSet]
	stdcall WriteIniInteger,ini_path,_section_font,_key_font_charset,eax
	invoke	GetWindowPlacement,[hwnd],wp
	stdcall WriteIniInteger,ini_path,_section_window,_key_window_top,[wp.rcNormalPosition.top]
	stdcall WriteIniInteger,ini_path,_section_window,_key_window_left,[wp.rcNormalPosition.left]
	stdcall WriteIniInteger,ini_path,_section_window,_key_window_right,[wp.rcNormalPosition.right]
	stdcall WriteIniInteger,ini_path,_section_window,_key_window_bottom,[wp.rcNormalPosition.bottom]
	cmp	[wp.showCmd],SW_SHOWMAXIMIZED
	sete	al
	stdcall WriteIniBit,ini_path,_section_window,_key_window_maximized,eax,1
	invoke	WritePrivateProfileString,_section_help,_key_help_path,help_path,ini_path
	invoke	DestroyWindow,[hwnd]
	jmp	finish
  wmdestroy:
	invoke	WinHelp,[hwnd],0,HELP_QUIT,0
	invoke	ImageList_Destroy,[himl]
	invoke	PostQuitMessage,0
  ok:
	xor	eax,eax
  finish:
	pop	edi esi ebx
	ret
endp

proc WriteIniInteger ini,sec,key,val
	cinvoke wsprintf,string_buffer,_value,[val]
	invoke	WritePrivateProfileString,[sec],[key],string_buffer,[ini]
	ret
endp

proc WriteIniColor ini,sec,key,color
	movzx	eax,byte [color]
	movzx	ebx,byte [color+1]
	movzx	ecx,byte [color+2]
	cinvoke wsprintf,string_buffer,_color,eax,ebx,ecx
	invoke	WritePrivateProfileString,[sec],[key],string_buffer,[ini]
	ret
endp

proc WriteIniBit ini,sec,key,val,mask
	mov	eax,[val]
	test	eax,[mask]
	setnz	al
	movzx	eax,al
	cinvoke wsprintf,string_buffer,_value,eax
	invoke	WritePrivateProfileString,[sec],[key],string_buffer,[ini]
	ret
endp

proc GetIniInteger ini,sec,key,lpval
	mov	[string_buffer],0
	invoke	GetPrivateProfileString,[sec],[key],string_buffer,string_buffer,1000h,[ini]
	mov	esi,string_buffer
	cmp	byte [esi],0
	je	.done
	call	atoi
	jc	.done
	mov	ebx,[lpval]
	mov	[ebx],eax
      .done:
	ret
endp

proc atoi
	lodsb
	cmp	al,20h
	je	atoi
	cmp	al,9
	je	atoi
	mov	bl,al
	xor	eax,eax
	xor	edx,edx
	cmp	bl,'-'
	je	atoi_digit
	cmp	bl,'+'
	je	atoi_digit
	dec	esi
      atoi_digit:
	mov	dl,[esi]
	sub	dl,30h
	jc	atoi_done
	cmp	dl,9
	ja	atoi_done
	mov	ecx,eax
	shl	ecx,1
	jc	atoi_overflow
	shl	ecx,1
	jc	atoi_overflow
	add	eax,ecx
	shl	eax,1
	jc	atoi_overflow
	js	atoi_overflow
	add	eax,edx
	jc	atoi_overflow
	inc	esi
	jmp	atoi_digit
      atoi_overflow:
	stc
	ret
      atoi_done:
	cmp	bl,'-'
	jne	atoi_sign_ok
	neg	eax
      atoi_sign_ok:
	clc
	ret
endp

proc GetIniColor ini,sec,key,lpcolor
	mov	[string_buffer],0
	invoke	GetPrivateProfileString,[sec],[key],string_buffer,string_buffer,1000h,[ini]
	mov	esi,string_buffer
	cmp	byte [esi],0
	je	.done
	call	atoi
	jc	.done
	cmp	eax,0FFh
	ja	.done
	mov	edi,eax
	call	.find
	jne	.done
	call	atoi
	jc	.done
	cmp	eax,0FFh
	ja	.done
	shl	eax,8
	or	edi,eax
	call	.find
	jne	.done
	call	atoi
	jc	.done
	cmp	eax,0FFh
	ja	.done
	shl	eax,16
	or	edi,eax
	mov	ebx,[lpcolor]
	mov	[ebx],edi
      .done:
	ret
      .find:
	lodsb
	cmp	al,20h
	je	.find
	cmp	al,9
	je	.find
	cmp	al,','
	retn
endp

proc GetIniByte ini,sec,key,lpval
	mov	[string_buffer],0
	invoke	GetPrivateProfileString,[sec],[key],string_buffer,string_buffer,1000h,[ini]
	mov	esi,string_buffer
	cmp	byte [esi],0
	je	.done
	call	atoi
	jc	.done
	cmp	eax,100h
	jae	.done
	mov	ebx,[lpval]
	mov	[ebx],al
      .done:
	ret
endp

proc GetIniBit ini,sec,key,lpval,mask
	mov	[string_buffer],0
	invoke	GetPrivateProfileString,[sec],[key],string_buffer,string_buffer,1000h,[ini]
	mov	esi,string_buffer
	xor	eax,eax
      .find:
	lodsb
	cmp	al,20h
	je	.find
	cmp	al,9
	je	.find
	sub	al,30h
	jc	.done
	cmp	al,1
	ja	.done
	neg	eax
	mov	ebx,[lpval]
	mov	edx,[mask]
	not	edx
	and	[ebx],edx
	and	eax,[mask]
	or	[ebx],eax
      .done:
	ret
endp

proc fasm_syntax lpLine,uChars,lpColors
	push	ebx esi edi
	mov	esi,[lpLine]
	mov	edi,[lpColors]
	mov	ebx,characters
	mov	ecx,[uChars]
	xor	edx,edx
  .scan_syntax:
	lodsb
  .check_character:
	cmp	al,20h
	je	.syntax_space
	cmp	al,3Bh
	je	.syntax_comment
	mov	ah,al
	xlatb
	or	al,al
	jz	.syntax_symbol
	or	edx,edx
	jnz	.syntax_neutral
	cmp	ah,27h
	je	.syntax_string
	cmp	ah,22h
	je	.syntax_string
	cmp	ah,24h
	je	.syntax_pascal_hex
	cmp	ah,39h
	ja	.syntax_neutral
	cmp	ah,30h
	jae	.syntax_number
  .syntax_neutral:
	or	edx,-1
	inc	edi
	loop	.scan_syntax
	jmp	.done
  .syntax_space:
	xor	edx,edx
	inc	edi
	loop	.scan_syntax
	jmp	.done
  .syntax_symbol:
	mov	al,1
	stosb
	xor	edx,edx
	loop	.scan_syntax
	jmp	.done
  .syntax_pascal_hex:
	cmp	ecx,1
	je	.syntax_neutral
	mov	al,[esi]
	mov	ah,al
	xlatb
	or	al,al
	jz	.syntax_neutral
	cmp	ah,24h
	jne	.syntax_number
	cmp	ecx,2
	je	.syntax_neutral
	mov	al,[esi+1]
	xlatb
	or	al,al
	jz	.syntax_neutral
  .syntax_number:
	mov	al,2
	stosb
	loop	.number_character
	jmp	.done
  .number_character:
	lodsb
	mov	ah,al
	xlatb
	xchg	al,ah
	or	ah,ah
	jz	.check_character
	cmp	al,20h
	je	.check_character
	cmp	al,3Bh
	je	.check_character
	mov	al,2
	stosb
	loop	.number_character
	jmp	.done
  .syntax_string:
	mov	al,3
	stosb
	dec	ecx
	jz	.done
	lodsb
	cmp	al,ah
	jne	.syntax_string
	mov	al,3
	stosb
	dec	ecx
	jz	.done
	lodsb
	cmp	al,ah
	je	.syntax_string
	xor	edx,edx
	jmp	.check_character
  .process_comment:
	lodsb
	cmp	al,20h
	jne	.syntax_comment
	inc	edi
	loop	.process_comment
	jmp	.done
  .syntax_comment:
	mov	al,4
	stosb
	loop	.process_comment
  .done:
	pop	edi esi ebx
	ret
endp

proc PositionDialog hwnd_dlg,msg,wparam,lparam
	push	ebx esi edi
	cmp	[msg],WM_INITDIALOG
	je	.initdialog
	cmp	[msg],WM_COMMAND
	je	.command
	cmp	[msg],WM_CLOSE
	je	.close
	xor	eax,eax
	jmp	.finish
  .initdialog:
	invoke	SendMessage,[hwnd_fedit],FEM_GETPOS,fepos,0
	cinvoke wsprintf,string_buffer,_value,[fepos.caretLine]
	invoke	SetDlgItemText,[hwnd_dlg],ID_ROW,string_buffer
	cinvoke wsprintf,string_buffer,_value,[fepos.caretPosition]
	invoke	SetDlgItemText,[hwnd_dlg],ID_COLUMN,string_buffer
	jmp	.processed
  .command:
	cmp	[wparam],IDCANCEL
	je	.close
	cmp	[wparam],IDOK
	jne	.processed
	invoke	GetDlgItemInt,[hwnd_dlg],ID_ROW,param_buffer,FALSE
	mov	[fepos.caretLine],eax
	mov	[fepos.selectionLine],eax
	invoke	GetDlgItemInt,[hwnd_dlg],ID_COLUMN,param_buffer,FALSE
	mov	[fepos.caretPosition],eax
	mov	[fepos.selectionPosition],eax
	invoke	IsDlgButtonChecked,[hwnd_dlg],ID_SELECT
	or	eax,eax
	jz	.position
	mov	[fepos.selectionLine],0
	mov	[fepos.selectionPosition],0
  .position:
	invoke	SendMessage,[hwnd_fedit],FEM_SETPOS,fepos,0
	invoke	EndDialog,[hwnd_dlg],TRUE
	jmp	.processed
  .close:
	invoke	EndDialog,[hwnd_dlg],FALSE
  .processed:
	mov	eax,1
  .finish:
	pop	edi esi ebx
	ret
endp

proc GetStringsFromHistory hwnd_combobox
	push	ebx esi
	invoke	SendMessage,[hwnd_history],LB_GETCOUNT,0,0
	mov	esi,eax
	xor	ebx,ebx
  .get_string:
	cmp	ebx,esi
	je	.finish
	invoke	SendMessage,[hwnd_history],LB_GETTEXT,ebx,string_buffer
	invoke	SendMessage,[hwnd_combobox],CB_ADDSTRING,0,string_buffer
	inc	ebx
	jmp	.get_string
  .finish:
	pop	esi ebx
	ret
endp

proc AddStringToHistory lpstr
	mov	eax,[lpstr]
	cmp	byte [eax],0
	je	.finish
	invoke	SendMessage,[hwnd_history],LB_FINDSTRINGEXACT,-1,[lpstr]
	cmp	eax,LB_ERR
	je	.insert
	invoke	SendMessage,[hwnd_history],LB_DELETESTRING,eax,0
  .insert:
	invoke	SendMessage,[hwnd_history],LB_INSERTSTRING,0,[lpstr]
	cmp	eax,LB_ERRSPACE
	jne	.finish
	invoke	SendMessage,[hwnd_history],LB_GETCOUNT,0,0
	sub	eax,1
	jc	.finish
	invoke	SendMessage,[hwnd_history],LB_DELETESTRING,eax,0
	jmp	.insert
  .finish:
	ret
endp

proc FindDialog hwnd_dlg,msg,wparam,lparam
	push	ebx esi edi
	cmp	[msg],WM_INITDIALOG
	je	.initdialog
	cmp	[msg],WM_COMMAND
	je	.command
	cmp	[msg],WM_CLOSE
	je	.close
	xor	eax,eax
	jmp	.finish
  .initdialog:
	invoke	SendMessage,[hwnd_fedit],FEM_GETWORDATCARET,1000h,search_string
	invoke	SetDlgItemText,[hwnd_dlg],ID_TEXT,search_string
	invoke	GetDlgItem,[hwnd_dlg],ID_TEXT
	stdcall GetStringsFromHistory,eax
	xor	eax,eax
	test	[search_settings],FEFIND_CASESENSITIVE
	setnz	al
	invoke	CheckDlgButton,[hwnd_dlg],ID_CASESENSITIVE,eax
	xor	eax,eax
	test	[search_settings],FEFIND_WHOLEWORDS
	setnz	al
	invoke	CheckDlgButton,[hwnd_dlg],ID_WHOLEWORDS,eax
	xor	eax,eax
	test	[search_settings],FEFIND_BACKWARD
	setnz	al
	invoke	CheckDlgButton,[hwnd_dlg],ID_BACKWARD,eax
	xor	eax,eax
	test	[search_settings],FEFIND_INWHOLETEXT
	setnz	al
	invoke	CheckDlgButton,[hwnd_dlg],ID_INWHOLETEXT,eax
	jmp	.update
  .command:
	cmp	[wparam],ID_TEXT + CBN_EDITCHANGE shl 16
	je	.update
	cmp	[wparam],ID_TEXT + CBN_SELCHANGE shl 16
	je	.selchange
	cmp	[wparam],IDCANCEL
	je	.close
	cmp	[wparam],IDOK
	jne	.processed
	xor	ebx,ebx
	invoke	IsDlgButtonChecked,[hwnd_dlg],ID_CASESENSITIVE
	or	eax,eax
	jz	.casesensitive_ok
	or	ebx,FEFIND_CASESENSITIVE
  .casesensitive_ok:
	invoke	IsDlgButtonChecked,[hwnd_dlg],ID_WHOLEWORDS
	or	eax,eax
	jz	.wholewords_ok
	or	ebx,FEFIND_WHOLEWORDS
  .wholewords_ok:
	invoke	IsDlgButtonChecked,[hwnd_dlg],ID_BACKWARD
	or	eax,eax
	jz	.backward_ok
	or	ebx,FEFIND_BACKWARD
  .backward_ok:
	invoke	IsDlgButtonChecked,[hwnd_dlg],ID_INWHOLETEXT
	or	eax,eax
	jz	.inwholetext_ok
	or	ebx,FEFIND_INWHOLETEXT
  .inwholetext_ok:
	mov	[search_settings],ebx
	stdcall AddStringToHistory,search_string
	invoke	EndDialog,[hwnd_dlg],TRUE
	jmp	.processed
  .selchange:
	invoke	PostMessage,[hwnd_dlg],WM_COMMAND,ID_TEXT + CBN_EDITCHANGE shl 16,0
	jmp	.processed
  .update:
	invoke	GetDlgItemText,[hwnd_dlg],ID_TEXT,search_string,1000h
	xor	ebx,ebx
	cmp	[search_string],0
	setnz	bl
	invoke	GetDlgItem,[hwnd_dlg],IDOK
	invoke	EnableWindow,eax,ebx
	jmp	.processed
  .close:
	invoke	EndDialog,[hwnd_dlg],FALSE
  .processed:
	mov	eax,1
  .finish:
	pop	edi esi ebx
	ret
endp

proc ReplaceDialog hwnd_dlg,msg,wparam,lparam
	push	ebx esi edi
	cmp	[msg],WM_INITDIALOG
	je	.initdialog
	cmp	[msg],WM_COMMAND
	je	.command
	jmp	.finish
  .initdialog:
	invoke	SetDlgItemText,[hwnd_dlg],ID_NEWTEXT,replace_string
	invoke	GetDlgItem,[hwnd_dlg],ID_NEWTEXT
	stdcall GetStringsFromHistory,eax
	xor	eax,eax
	test	[command_flags],1
	setnz	al
	invoke	CheckDlgButton,[hwnd_dlg],ID_PROMPT,eax
	jmp	.finish
  .command:
	cmp	[wparam],IDOK
	jne	.finish
	invoke	GetDlgItemText,[hwnd_dlg],ID_NEWTEXT,replace_string,1000h
	xor	ebx,ebx
	invoke	IsDlgButtonChecked,[hwnd_dlg],ID_PROMPT
	or	eax,eax
	jz	.prompt_ok
	or	ebx,1
  .prompt_ok:
	mov	[command_flags],ebx
	stdcall AddStringToHistory,replace_string
  .finish:
	stdcall FindDialog,[hwnd_dlg],[msg],[wparam],[lparam]
	pop	edi esi ebx
	ret
endp

proc CompileDialog hwnd_dlg,msg,wparam,lparam
	push	ebx esi edi
	cmp	[msg],WM_INITDIALOG
	je	.initdialog
	cmp	[msg],WM_COMMAND
	je	.command
	cmp	[msg],WM_CLOSE
	je	.close
	xor	eax,eax
	jmp	.finish
  .initdialog:
	mov	eax,[hwnd_dlg]
	mov	[hwnd_compiler],eax
	invoke	GetDlgItem,[hwnd_dlg],ID_PROGRESS
	mov	[hwnd_progress],eax
	mov	[ei.header.mask],TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,[lparam],ei
	invoke	CreateMutex,NULL,FALSE,NULL
	mov	[mutex],eax
	invoke	HeapAlloc,[hheap],HEAP_ZERO_MEMORY,4
	mov	[stdout],eax
	invoke	HeapAlloc,[hheap],HEAP_ZERO_MEMORY,4
	mov	[stderr],eax
	call	system_init
	invoke	GetFullPathName,[ei.pszpath],1000h,path_buffer,param_buffer
	invoke	CreateThread,NULL,10000h,flat_assembler,path_buffer,0,param_buffer
	mov	[hthread],eax
	jmp	.processed
  .command:
	cmp	[wparam],IDCANCEL
	je	.close
	cmp	[wparam],IDOK
	jne	.finish
  .get_exit_code:
	invoke	WaitForSingleObject,[hthread],-1
	invoke	GetExitCodeThread,[hthread],param_buffer
	invoke	CloseHandle,[hthread]
	invoke	CloseHandle,[mutex]
	call	system_shutdown
	invoke	EndDialog,[hwnd_dlg],[param_buffer]
	jmp	.processed
  .close:
	invoke	WaitForSingleObject,[mutex],-1
	cmp	eax,WAIT_ABANDONED
	je	.processed
	invoke	TerminateThread,[hthread],-1
	test	eax,eax
	jz	.processed
	invoke	ReleaseMutex,[mutex]
	invoke	CloseHandle,[hthread]
	invoke	CloseHandle,[mutex]
	call	system_shutdown
	invoke	HeapFree,[hheap],0,[stdout]
	invoke	HeapFree,[hheap],0,[stderr]
  .cancel:
	invoke	EndDialog,[hwnd_dlg],-1
  .processed:
	mov	eax,1
  .finish:
	pop	edi esi ebx
	ret
endp

proc ShowLine pszPath,nLine
	mov	[ei.header.mask],TCIF_PARAM
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETCURSEL,0,0
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,eax,ei
	invoke	lstrcmpi,[ei.pszpath],[pszPath]
	or	eax,eax
	jz	current_file_ok
	xor	ebx,ebx
      find_file_window:
	invoke	SendMessage,[hwnd_tabctrl],TCM_GETITEM,ebx,ei
	or	eax,eax
	jz	load_for_show
	invoke	lstrcmpi,[ei.pszpath],[pszPath]
	or	eax,eax
	jz	show_file
	inc	ebx
	jmp	find_file_window
      load_for_show:
	mov	esi,[pszPath]
	mov	edi,path_buffer
      copy_path_for_show:
	lodsb
	stosb
	or	al,al
	jnz	copy_path_for_show
	invoke	GetFileTitle,path_buffer,name_buffer,100h
	invoke	SendMessage,[hwnd_main],FM_OPEN,name_buffer,path_buffer
	cmp	eax,-1
	je	show_failed
	jmp	current_file_ok
      show_file:
	invoke	SendMessage,[hwnd_tabctrl],TCM_SETCURSEL,ebx,0
	invoke	SendMessage,[hwnd_main],FM_SELECT,ebx,0
      current_file_ok:
	mov	eax,[nLine]
	mov	[fepos.selectionLine],eax
	mov	[fepos.caretLine],eax
      get_lines_to_show:
	invoke	SendMessage,[hwnd_fedit],FEM_GETLINELENGTH,[nLine],0
	mov	esi,string_buffer
	cmp	eax,1000h
	jb	get_line_data
	mov	edi,eax
	invoke	VirtualAlloc,0,edi,MEM_COMMIT,PAGE_READWRITE
	or	eax,eax
	jz	show_lines
	mov	esi,eax
      get_line_data:
	invoke	SendMessage,[hwnd_fedit],FEM_GETLINE,[nLine],esi
	cmp	esi,string_buffer
	je	show_lines
	invoke	VirtualFree,esi,edi,MEM_DECOMMIT
      show_lines:
	mov	[fepos.selectionPosition],1
	inc	[fepos.caretLine]
	mov	[fepos.caretPosition],1
	invoke	SendMessage,[hwnd_fedit],FEM_GETLINELENGTH,[fepos.caretLine],0
	cmp	eax,-1
	jne	show_ok
	dec	[fepos.caretLine]
	invoke	SendMessage,[hwnd_fedit],FEM_GETLINELENGTH,[fepos.caretLine],0
	inc	eax
	mov	[fepos.caretPosition],eax
      show_ok:
	invoke	SendMessage,[hwnd_fedit],FEM_SETPOS,fepos,0
	invoke	SendMessage,[hwnd_fedit],FEM_GETMODE,0,0
	and	eax,not FEMODE_VERTICALSEL
	invoke	SendMessage,[hwnd_fedit],FEM_SETMODE,eax,0
	mov	eax,[fepos.selectionLine]
	xchg	eax,[fepos.caretLine]
	mov	[fepos.selectionLine],eax
	mov	eax,[fepos.selectionPosition]
	xchg	eax,[fepos.caretPosition]
	mov	[fepos.selectionPosition],eax
	invoke	SendMessage,[hwnd_fedit],FEM_SETPOS,fepos,0
	xor	eax,eax
	ret
      show_failed:
	or	eax,-1
	ret
endp

proc SummaryDialog hwnd_dlg,msg,wparam,lparam
	push	ebx esi edi
	cmp	[msg],WM_INITDIALOG
	je	.initdialog
	cmp	[msg],WM_COMMAND
	je	.command
	cmp	[msg],WM_CLOSE
	je	.close
	xor	eax,eax
	jmp	.finish
  .initdialog:
	invoke	GetDlgItem,[hwnd_dlg],ID_DISPLAY
	invoke	SendMessage,eax,WM_SETFONT,[hfont],FALSE
	mov	eax,[stdout]
	add	eax,4
	invoke	SetDlgItemText,[hwnd_dlg],ID_DISPLAY,eax
	mov	edi,[stderr]
	add	edi,4
	invoke	SetDlgItemText,[hwnd_dlg],ID_MESSAGE,edi
	cmp	[lparam],0
	je	.processed
	invoke	LoadIcon,0,IDI_HAND
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_ICON,STM_SETICON,eax,0
	cmp	[lparam],2
	jne	.processed
	invoke	GetDlgItem,[hwnd_dlg],ID_INSTRUCTION
	invoke	SendMessage,eax,WM_SETFONT,[hfont],FALSE
	mov	ebx,error_pointers
    .list_errors:
	mov	edx,edi
	xor	al,al
	or	ecx,-1
	repne	scasb
	repne	scasb
	inc	edi
	mov	eax,[edi]
	add	edi,4
	mov	[ebx],edx
	add	ebx,4
	mov	[param_buffer],edi
	mov	[param_buffer+4],eax
	test	eax,eax
	jz	.add_error
	invoke	GetFullPathName,edi,1000h,path_buffer,param_buffer
     .add_error:
	invoke	wvsprintf,string_buffer,_line_number,param_buffer
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_ERRORS,LB_ADDSTRING,0,string_buffer
     .next_error:
	xor	al,al
	or	ecx,-1
	repne	scasb
	mov	esi,[stderr]
	lodsd
	add	eax,esi
	cmp	edi,eax
	jb	.list_errors
	cmp	esi,[error_pointers]
	jne	.processed
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_ERRORS,LB_SETCURSEL,0,0
   .show_error:
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_ERRORS,LB_GETCURSEL,0,0
	cmp	eax,LB_ERR
	je	.processed
	mov	edi,[error_pointers+eax*4]
	invoke	SetDlgItemText,[hwnd_dlg],ID_MESSAGE,edi
	xor	al,al
	or	ecx,-1
	repne	scasb
	invoke	SetDlgItemText,[hwnd_dlg],ID_INSTRUCTION,edi
	mov	edx,edi
	xor	al,al
	or	ecx,-1
	repne	scasb
	mov	ebx,TRUE
	cmp	byte [edi],SOURCE_CALM
	jne	.instruction_ok
	cmp	byte [edx],0
	jne	.instruction_ok
      .instruction_calm:
	invoke	SetDlgItemText,[hwnd_dlg],ID_INSTRUCTION,_calm
	mov	ebx,FALSE
	jmp	.instruction_ok
      .instruction_ok:
	invoke	GetDlgItem,[hwnd_dlg],ID_INSTRUCTION
	invoke	EnableWindow,eax,ebx
	add	edi,1+4
	cmp	byte [edi],0
	je	.processed
	invoke	GetFullPathName,edi,1000h,path_buffer,param_buffer
	stdcall ShowLine,path_buffer,dword [edi-4]
	jmp	.processed
  .command:
	cmp	[wparam],ID_ERRORS + LBN_SELCHANGE shl 16
	je	.show_error
	cmp	[wparam],IDCANCEL
	je	.close
	cmp	[wparam],IDOK
	jne	.finish
  .close:
	invoke	EndDialog,[hwnd_dlg],0
  .processed:
	mov	eax,1
  .finish:
	pop	edi esi ebx
	ret
endp

proc AddStrings hwnd_combobox,lpstrings
	push	ebx esi
	mov	esi,[lpstrings]
  .add_string:
	cmp	byte [esi],0
	je	.finish
	invoke	SendMessage,[hwnd_combobox],CB_ADDSTRING,0,esi
  .next_string:
	lodsb
	or	al,al
	jnz	.next_string
	jmp	.add_string
  .finish:
	pop	esi ebx
	ret
endp

proc AppearanceSetup hwnd_dlg,msg,wparam,lparam
	push	ebx esi edi
	cmp	[msg],WM_INITDIALOG
	je	.initdialog
	cmp	[msg],WM_DESTROY
	je	.destroy
	cmp	[msg],WM_COMMAND
	je	.command
	cmp	[msg],WM_CLOSE
	je	.close
  .notprocessed:
	xor	eax,eax
	jmp	.finish
  .initdialog:
	xor	eax,eax
	test	[fedit_style],FES_CONSOLECARET
	setnz	al
	invoke	CheckDlgButton,[hwnd_dlg],ID_CONSOLECARET,eax
	mov	[cf.lStructSize],sizeof.CHOOSEFONT
	mov	eax,[hwnd_dlg]
	mov	[cf.hwndOwner],eax
	mov	[cf.Flags],CF_FIXEDPITCHONLY+CF_SCREENFONTS+CF_FORCEFONTEXIST+CF_INITTOLOGFONTSTRUCT
	mov	[cf.lpLogFont],tmp_font
	mov	[cc.lStructSize],sizeof.CHOOSECOLOR
	mov	eax,[hinstance]
	mov	[cc.hInstance],eax
	mov	eax,[hwnd_dlg]
	mov	[cc.hwndOwner],eax
	mov	[cc.lpCustColors],user_colors
	mov	[cc.Flags],CC_RGBINIT
	mov	esi,font
	mov	edi,tmp_font
	mov	ecx,sizeof.LOGFONT shr 2
	rep	movsd
	mov	esi,editor_colors
	mov	edi,tmp_colors
	mov	ecx,8
	rep	movsd
	mov	esi,editor_colors
	mov	edi,user_colors+20h
	mov	ecx,8
	rep	movsd
	invoke	GetDlgItem,[hwnd_dlg],ID_SETTING
	stdcall AddStrings,eax,_appearance_settings
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_SETTING,CB_SETCURSEL,0,0
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_PREVIEW,WM_SETTEXT,0,preview_text
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_PREVIEW,FEM_SETPOS,preview_selection,0
	invoke	CreateFontIndirect,[cf.lpLogFont]
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_PREVIEW,WM_SETFONT,eax,0
  .update_colors:
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_PREVIEW,FEM_SETTEXTCOLOR,[tmp_colors],[tmp_colors+4]
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_PREVIEW,FEM_SETSELCOLOR,[tmp_colors+8],[tmp_colors+12]
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_PREVIEW,FEM_SETSYNTAXHIGHLIGHT,tmp_colors+16,fasm_syntax
	jmp	.processed
  .destroy:
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_PREVIEW,WM_GETFONT,0,0
	invoke	DeleteObject,eax
	jmp	.finish
  .command:
	cmp	[wparam],IDCANCEL
	je	.close
	cmp	[wparam],IDOK
	je	.ok
	cmp	[wparam],ID_CHANGE
	jne	.processed
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_SETTING,CB_GETCURSEL,0,0
	or	eax,eax
	jz	.change_font
	cmp	eax,8
	ja	.processed
	lea	ebx,[tmp_colors+(eax-1)*4]
	mov	eax,[ebx]
	mov	[cc.rgbResult],eax
	invoke	ChooseColor,cc
	or	eax,eax
	jz	.processed
	mov	eax,[cc.rgbResult]
	mov	[ebx],eax
	jmp	.update_colors
  .change_font:
	mov	esi,tmp_font
	mov	edi,backup_font
	mov	ecx,sizeof.LOGFONT shr 2
	rep	movsd
	invoke	ChooseFont,cf
	or	eax,eax
	jz	.change_font_cancelled
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_PREVIEW,WM_GETFONT,0,0
	mov	ebx,eax
	invoke	CreateFontIndirect,[cf.lpLogFont]
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_PREVIEW,WM_SETFONT,eax,0
	invoke	DeleteObject,ebx
	jmp	.processed
  .change_font_cancelled:
	mov	esi,backup_font
	mov	edi,tmp_font
	mov	ecx,sizeof.LOGFONT shr 2
	rep	movsd
	jmp	.processed
  .ok:
	mov	esi,tmp_colors
	mov	edi,editor_colors
	mov	ecx,8
	rep	movsd
	mov	esi,tmp_font
	mov	edi,font
	mov	ecx,sizeof.LOGFONT shr 2
	rep	movsd
	invoke	CreateFontIndirect,font
	xchg	eax,[hfont]
	invoke	DeleteObject,eax
	invoke	IsDlgButtonChecked,[hwnd_dlg],ID_CONSOLECARET
	or	eax,eax
	setnz	al
	neg	eax
	and	eax,FES_CONSOLECARET
	and	[fedit_style],not FES_CONSOLECARET
	or	[fedit_style],eax
	invoke	EndDialog,[hwnd_dlg],TRUE
	jmp	.finish
  .close:
	invoke	EndDialog,[hwnd_dlg],FALSE
  .processed:
	mov	eax,1
  .finish:
	pop	edi esi ebx
	ret
endp

proc CompilerSetup hwnd_dlg,msg,wparam,lparam
	push	ebx esi edi
	cmp	[msg],WM_INITDIALOG
	je	.initdialog
	cmp	[msg],WM_COMMAND
	je	.command
	cmp	[msg],WM_CLOSE
	je	.close
  .notprocessed:
	xor	eax,eax
	jmp	.finish
  .initdialog:
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_INCLUDEPATH,CB_ADDSTRING,0,include_path
	mov	[string_buffer],0
	invoke	GetEnvironmentVariable,_key_environment_include,string_buffer,1000h
	invoke	GetPrivateProfileString,_section_environment,_key_environment_include,string_buffer,path_buffer,4000h,ini_path
	invoke	SetDlgItemText,[hwnd_dlg],ID_INCLUDEPATH,path_buffer
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_SOURCEHEADER,CB_ADDSTRING,0,default_source_header
	invoke	SetDlgItemText,[hwnd_dlg],ID_SOURCEHEADER,source_header
	invoke	GetDlgItem,[hwnd_dlg],ID_PRIORITY
	stdcall AddStrings,eax,_priority_settings
	invoke	SetDlgItemInt,[hwnd_dlg],ID_PASSES,[maximum_number_of_passes],FALSE
	invoke	SetDlgItemInt,[hwnd_dlg],ID_RECURSION,[maximum_depth_of_stack],FALSE
	mov	eax,[compiler_priority]
	cmp	eax,2
	jg	.realtime
	cmp	eax,-2
	jl	.idle
	jmp	.priority_ok
  .idle:
	mov	eax,-4
	jmp	.priority_ok
  .realtime:
	mov	eax,4
  .priority_ok:
	sar	eax,1
	add	eax,2
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_PRIORITY,CB_SETCURSEL,eax,0
	jmp	.processed
  .command:
	cmp	[wparam],IDCANCEL
	je	.close
	cmp	[wparam],IDOK
	jne	.finish
	invoke	GetDlgItemInt,[hwnd_dlg],ID_PASSES,param_buffer,FALSE
	mov	[maximum_number_of_passes],eax
	invoke	GetDlgItemInt,[hwnd_dlg],ID_RECURSION,param_buffer,FALSE
	mov	[maximum_depth_of_stack],eax
	invoke	SendDlgItemMessage,[hwnd_dlg],ID_PRIORITY,CB_GETCURSEL,0,0
	sub	eax,2
	sal	eax,1
	cmp	eax,4
	je	.set_realtime
	cmp	eax,-4
	je	.set_idle
	jmp	.set_priority
  .set_idle:
	mov	eax,-15
	jmp	.set_priority
  .set_realtime:
	mov	eax,15
  .set_priority:
	mov	[compiler_priority],eax
	invoke	GetDlgItemText,[hwnd_dlg],ID_INCLUDEPATH,path_buffer,4000h
	invoke	GetDlgItemText,[hwnd_dlg],ID_SOURCEHEADER,source_header,1000h
	invoke	WritePrivateProfileString,_section_environment,_key_environment_include,path_buffer,ini_path
	invoke	EndDialog,[hwnd_dlg],TRUE
	jmp	.finish
  .close:
	invoke	EndDialog,[hwnd_dlg],FALSE
  .processed:
	mov	eax,1
  .finish:
	pop	edi esi ebx
	ret
endp

proc CalculatorDialog hwnd,msg,wparam,lparam
	push	ebx esi edi
	cmp	[msg],WM_INITDIALOG
	je	.init
	cmp	[msg],WM_COMMAND
	je	.command
	cmp	[msg],WM_CLOSE
	je	.close
	xor	eax,eax
	jmp	.finish
  .init:
	invoke	SendDlgItemMessage,[hwnd],ID_EXPRESSION,EM_SETLIMITTEXT,EXPRESSION_MAX_LENGTH-1,0
	invoke	CheckDlgButton,[hwnd],ID_DECSELECT,BST_CHECKED
	mov	[maximum_number_of_errors],1
	call	system_init
	xor	al,al
	call	assembly_init
	jmp	.processed
  .command:
	cmp	[wparam],IDCANCEL
	je	.close
	cmp	[wparam],IDOK
	je	.evaluate
	cmp	[wparam],ID_EXPRESSION + EN_CHANGE shl 16
	jne	.processed
	invoke	GetDlgItemText,[hwnd],ID_EXPRESSION,expression_buffer,EXPRESSION_MAX_LENGTH
	call	discard_errors
	mov	esi,calculator_string
	xor	edx,edx
	call	assembly_pass
	jnc	.calculation_failed
	cmp	[first_error],0
	jne	.calculation_failed
	call	get_output_length
	test	edx,edx
	jnz	.calculation_failed
	mov	[result_size],eax
	lea	ecx,[eax*8+12]
	mov	[digits_size],ecx
	add	eax,ecx
	invoke	VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	test	eax,eax
	jz	.calculation_failed
	mov	[result_address],eax
	mov	ecx,[result_size]
	jecxz	.result_zero
	mov	edi,eax
	mov	[value_length],ecx
	xor	eax,eax
	mov	dword [file_offset],eax
	mov	dword [file_offset+4],eax
	call	read_from_output
	jmp	.result_ready
     .result_zero:
	inc	[result_size]
	dec	[digits_size]
	mov	byte [eax],0
     .result_ready:
	mov	esi,[result_address]
	mov	edx,[result_size]
	lea	edi,[esi+edx]
	mov	al,[edi-1]
	sar	al,7
	mov	[edi],al
	mov	[digits_address],edi
	add	edi,[digits_size]
	sub	edi,2
	mov	word [edi],'b'
	xor	cl,cl
      .to_bin:
	mov	al,[esi]
	shr	al,cl
	and	al,1
	add	al,'0'
	dec	edi
	mov	[edi],al
	inc	cl
	and	cl,111b
	jnz	.to_bin
	inc	esi
	dec	edx
	jnz	.to_bin
	test	byte [esi-1],80h
	jz	.bin_ok
	dec	edi
	mov	ecx,3
	mov	al,'.'
	std
	rep	stosb
	cld
	inc	edi
      .bin_ok:
	invoke	SetDlgItemText,[hwnd],ID_BINRESULT,edi
	mov	esi,[result_address]
	mov	ecx,[result_size]
	mov	edi,[digits_address]
	add	edi,[digits_size]
	sub	edi,2
	mov	word [edi],'h'
      .to_hex:
	mov	al,[esi]
	and	al,0Fh
	cmp	al,10
	sbb	al,69h
	das
	dec	edi
	mov	[edi],al
	lodsb
	shr	al,4
	cmp	al,10
	sbb	al,69h
	das
	dec	edi
	mov	[edi],al
	loop	.to_hex
	test	byte [esi-1],80h
	jz	.hex_ok
	dec	edi
	mov	ecx,3
	mov	al,'.'
	std
	rep	stosb
	cld
	inc	edi
      .hex_ok:
	invoke	SetDlgItemText,[hwnd],ID_HEXRESULT,edi
	mov	esi,[result_address]
	mov	edx,[result_size]
	mov	edi,[digits_address]
	add	edi,[digits_size]
	sub	edi,2
	mov	word [edi],'o'
	xor	cl,cl
      .to_oct:
	mov	ax,[esi]
	shr	ax,cl
	and	al,7
	add	al,'0'
	dec	edi
	mov	[edi],al
	add	cl,3
	cmp	cl,8
	jb	.to_oct
	sub	cl,8
	inc	esi
	dec	edx
	jnz	.to_oct
	test	byte [esi-1],80h
	jz	.oct_ok
	dec	edi
	mov	ecx,3
	mov	al,'.'
	std
	rep	stosb
	cld
	inc	edi
      .oct_ok:
	invoke	SetDlgItemText,[hwnd],ID_OCTRESULT,edi
	mov	esi,[result_address]
	mov	ecx,[result_size]
	mov	edi,[digits_address]
	rep	movsb
	test	byte [esi-1],80h
	jnz	.negative
	xor	eax,eax
	stosd
	jmp	.to_dec
      .negative:
	or	eax,-1
	stosd
	mov	esi,[digits_address]
	mov	ecx,edi
	sub	ecx,esi
	stc
      .negate:
	not	byte [esi]
	adc	byte [esi],0
	inc	esi
	loop	.negate
      .to_dec:
	mov	edi,[digits_address]
	add	edi,[digits_size]
	dec	edi
	and	byte [edi],0
	mov	esi,[digits_address]
	mov	ecx,[result_size]
	dec	ecx
	and	ecx,not 11b
      .obtain_digit:
	xor	edx,edx
      .divide_highest_dwords:
	mov	eax,[esi+ecx]
	call	div10
	test	eax,eax
	jnz	.more_digits_to_come
	sub	ecx,4
	jnc	.divide_highest_dwords
      .store_final_digit:
	add	dl,'0'
	dec	edi
	mov	[edi],dl
	mov	esi,[result_address]
	add	esi,[result_size]
	test	byte [esi-1],80h
	jz	.dec_ok
	dec	edi
	mov	byte [edi],'-'
	jmp	.dec_ok
      .more_digits_to_come:
	mov	ebx,ecx
      .divide_remaining_dwords:
	mov	[esi+ebx],eax
	sub	ebx,4
	jc	.store_digit
	mov	eax,[esi+ebx]
	call	div10
	jmp	.divide_remaining_dwords
      .store_digit:
	add	dl,'0'
	dec	edi
	mov	[edi],dl
	jmp	.obtain_digit
      .dec_ok:
	invoke	SetDlgItemText,[hwnd],ID_DECRESULT,edi
	invoke	VirtualFree,[result_address],0,MEM_RELEASE
	jmp	.processed
  .calculation_failed:
	invoke	SetDlgItemText,[hwnd],ID_BINRESULT,_null
	invoke	SetDlgItemText,[hwnd],ID_DECRESULT,_null
	invoke	SetDlgItemText,[hwnd],ID_HEXRESULT,_null
	invoke	SetDlgItemText,[hwnd],ID_OCTRESULT,_null
	jmp	.processed
  .evaluate:
	mov	ebx,ID_BINRESULT
	invoke	IsDlgButtonChecked,[hwnd],ID_BINSELECT
	cmp	eax,BST_CHECKED
	je	.get_result
	mov	ebx,ID_HEXRESULT
	invoke	IsDlgButtonChecked,[hwnd],ID_HEXSELECT
	cmp	eax,BST_CHECKED
	je	.get_result
	mov	ebx,ID_OCTRESULT
	invoke	IsDlgButtonChecked,[hwnd],ID_OCTSELECT
	cmp	eax,BST_CHECKED
	je	.get_result
	mov	ebx,ID_DECRESULT
      .get_result:
	invoke	GetDlgItemText,[hwnd],ebx,expression_buffer,EXPRESSION_MAX_LENGTH
	invoke	SetDlgItemText,[hwnd],ID_EXPRESSION,expression_buffer
	invoke	GetDlgItem,[hwnd],ID_EXPRESSION
	invoke	SendMessage,[hwnd],WM_NEXTDLGCTL,eax,TRUE
	jmp	.processed
  .close:
	call	assembly_shutdown
	call	system_shutdown
	invoke	EndDialog,[hwnd],0
  .processed:
	mov	eax,1
  .finish:
	pop	edi esi ebx
	ret
endp

proc AboutDialog hwnd,msg,wparam,lparam
	push	ebx esi edi
	cmp	[msg],WM_COMMAND
	je	.close
	cmp	[msg],WM_CLOSE
	je	.close
	xor	eax,eax
	jmp	.finish
  .close:
	invoke	EndDialog,[hwnd],0
  .processed:
	mov	eax,1
  .finish:
	pop	edi esi ebx
	ret
endp

include 'fasmg.inc'

section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
	  advapi,'ADVAPI32.DLL',\
	  user,'USER32.DLL',\
	  gdi,'GDI32.DLL',\
	  comctl,'COMCTL32.DLL',\
	  comdlg,'COMDLG32.DLL',\
	  shell,'SHELL32.DLL'

  import kernel,\
	 GetModuleHandle,'GetModuleHandleA',\
	 LoadLibrary,'LoadLibraryA',\
	 GetProcAddress,'GetProcAddress',\
	 GetCommandLine,'GetCommandLineA',\
	 GetFileAttributes,'GetFileAttributesA',\
	 GetFullPathName,'GetFullPathNameA',\
	 GetCurrentDirectory,'GetCurrentDirectoryA',\
	 SetCurrentDirectory,'SetCurrentDirectoryA',\
	 CreateFile,'CreateFileA',\
	 GetFileSize,'GetFileSize',\
	 ReadFile,'ReadFile',\
	 WriteFile,'WriteFile',\
	 SetFilePointer,'SetFilePointer',\
	 CloseHandle,'CloseHandle',\
	 lstrcmpi,'lstrcmpiA',\
	 GlobalAlloc,'GlobalAlloc',\
	 GlobalReAlloc,'GlobalReAlloc',\
	 GlobalLock,'GlobalLock',\
	 GlobalUnlock,'GlobalUnlock',\
	 GlobalFree,'GlobalFree',\
	 GetProcessHeap,'GetProcessHeap',\
	 HeapCreate,'HeapCreate',\
	 HeapSize,'HeapSize',\
	 HeapDestroy,'HeapDestroy',\
	 HeapAlloc,'HeapAlloc',\
	 HeapReAlloc,'HeapReAlloc',\
	 HeapFree,'HeapFree',\
	 VirtualAlloc,'VirtualAlloc',\
	 VirtualFree,'VirtualFree',\
	 CreateThread,'CreateThread',\
	 SetThreadPriority,'SetThreadPriority',\
	 TerminateThread,'TerminateThread',\
	 ExitThread,'ExitThread',\
	 GetExitCodeThread,'GetExitCodeThread',\
	 WaitForSingleObject,'WaitForSingleObject',\
	 CreateMutex,'CreateMutexA',\
	 ReleaseMutex,'ReleaseMutex',\
	 CreateProcess,'CreateProcessA',\
	 AllocConsole,'AllocConsole',\
	 SetConsoleTitle,'SetConsoleTitleA',\
	 FreeConsole,'FreeConsole',\
	 GetEnvironmentVariable,'GetEnvironmentVariableA',\
	 GetSystemTime,'GetSystemTime',\
	SystemTimeToFileTime,'SystemTimeToFileTime',\
	 GetTickCount,'GetTickCount',\
	 GetPrivateProfileString,'GetPrivateProfileStringA',\
	 WritePrivateProfileString,'WritePrivateProfileStringA',\
	 GetLastError,'GetLastError',\
	 ExitProcess,'ExitProcess'

  import advapi,\
	 RegOpenKeyEx,'RegOpenKeyExA',\
	 RegQueryValueEx,'RegQueryValueExA',\
	 RegCloseKey,'RegCloseKey'

  import user,\
	 RegisterClass,'RegisterClassA',\
	 CreateCaret,'CreateCaret',\
	 ShowCaret,'ShowCaret',\
	 HideCaret,'HideCaret',\
	 SetCaretPos,'SetCaretPos',\
	 DestroyCaret,'DestroyCaret',\
	 BeginPaint,'BeginPaint',\
	 EndPaint,'EndPaint',\
	 GetDC,'GetDC',\
	 GetUpdateRect,'GetUpdateRect',\
	 ReleaseDC,'ReleaseDC',\
	 DrawText,'DrawTextA',\
	 FillRect,'FillRect',\
	 InvalidateRect,'InvalidateRect',\
	 GetKeyboardState,'GetKeyboardState',\
	 ToAscii,'ToAscii',\
	 GetScrollInfo,'GetScrollInfo',\
	 SetScrollInfo,'SetScrollInfo',\
	 SetCapture,'SetCapture',\
	 ReleaseCapture,'ReleaseCapture',\
	 GetCursorPos,'GetCursorPos',\
	 ClientToScreen,'ClientToScreen',\
	 OpenClipboard,'OpenClipboard',\
	 CloseClipboard,'CloseClipboard',\
	 EmptyClipboard,'EmptyClipboard',\
	 GetClipboardData,'GetClipboardData',\
	 SetClipboardData,'SetClipboardData',\
	 LoadCursor,'LoadCursorA',\
	 LoadIcon,'LoadIconA',\
	 LoadBitmap,'LoadBitmapA',\
	 LoadMenu,'LoadMenuA',\
	 EnableMenuItem,'EnableMenuItem',\
	 CheckMenuItem,'CheckMenuItem',\
	 GetSubMenu,'GetSubMenu',\
	 TrackPopupMenu,'TrackPopupMenu',\
	 LoadAccelerators,'LoadAcceleratorsA',\
	 IsClipboardFormatAvailable,'IsClipboardFormatAvailable',\
	 CharLower,'CharLowerA',\
	 CharUpper,'CharUpperA',\
	 wsprintf,'wsprintfA',\
	 wvsprintf,'wvsprintfA',\
	 MessageBox,'MessageBoxA',\
	 WinHelp,'WinHelpA',\
	 DialogBoxParam,'DialogBoxParamA',\
	 GetDlgItem,'GetDlgItem',\
	 GetDlgItemInt,'GetDlgItemInt',\
	 SetDlgItemInt,'SetDlgItemInt',\
	 GetDlgItemText,'GetDlgItemTextA',\
	 SetDlgItemText,'SetDlgItemTextA',\
	 CheckDlgButton,'CheckDlgButton',\
	 IsDlgButtonChecked,'IsDlgButtonChecked',\
	 SendDlgItemMessage,'SendDlgItemMessageA',\
	 EndDialog,'EndDialog',\
	 FindWindow,'FindWindowA',\
	 SetForegroundWindow,'SetForegroundWindow',\
	 CreateWindowEx,'CreateWindowExA',\
	 DestroyWindow,'DestroyWindow',\
	 GetWindowLong,'GetWindowLongA',\
	 SetWindowLong,'SetWindowLongA',\
	 DefWindowProc,'DefWindowProcA',\
	 GetClientRect,'GetClientRect',\
	 GetWindowRect,'GetWindowRect',\
	 MoveWindow,'MoveWindow',\
	 SetWindowPos,'SetWindowPos',\
	 GetWindowPlacement,'GetWindowPlacement',\
	 SetWindowPlacement,'SetWindowPlacement',\
	 ShowWindow,'ShowWindow',\
	 EnableWindow,'EnableWindow',\
	 UpdateWindow,'UpdateWindow',\
	 IsZoomed,'IsZoomed',\
	 SetFocus,'SetFocus',\
	 GetSystemMetrics,'GetSystemMetrics',\
	 GetSysColor,'GetSysColor',\
	 SendMessage,'SendMessageA',\
	 GetMessage,'GetMessageA',\
	 TranslateAccelerator,'TranslateAccelerator',\
	 TranslateMessage,'TranslateMessage',\
	 DispatchMessage,'DispatchMessageA',\
	 PostMessage,'PostMessageA',\
	 PostQuitMessage,'PostQuitMessage'

  import gdi,\
	 SetBkColor,'SetBkColor',\
	 SetTextColor,'SetTextColor',\
	 CreateSolidBrush,'CreateSolidBrush',\
	 CreateFont,'CreateFontA',\
	 CreateFontIndirect,'CreateFontIndirectA',\
	 GetTextMetrics,'GetTextMetricsA',\
	 GetTextExtentPoint32,'GetTextExtentPoint32A',\
	 CreateCompatibleDC,'CreateCompatibleDC',\
	 DeleteDC,'DeleteDC',\
	 CreateBitmap,'CreateBitmap',\
	 SelectObject,'SelectObject',\
	 GetObject,'GetObjectA',\
	 DeleteObject,'DeleteObject'

  import comctl,\
	 CreateStatusWindow,'CreateStatusWindowA',\
	 ImageList_Create,'ImageList_Create',\
	 ImageList_Add,'ImageList_Add',\
	 ImageList_Destroy,'ImageList_Destroy'

  import comdlg,\
	 GetOpenFileName,'GetOpenFileNameA',\
	 GetSaveFileName,'GetSaveFileNameA',\
	 GetFileTitle,'GetFileTitleA',\
	 ChooseFont,'ChooseFontA',\
	 ChooseColor,'ChooseColorA'

  import shell,\
	 DragAcceptFiles,'DragAcceptFiles',\
	 DragQueryFile,'DragQueryFile',\
	 DragFinish,'DragFinish',\
	 ShellExecute,'ShellExecuteA'

section '.rsrc' resource data readable

  directory RT_MENU,menus,\
	    RT_ACCELERATOR,accelerators,\
	    RT_DIALOG,dialogs,\
	    RT_GROUP_ICON,group_icons,\
	    RT_ICON,icons,\
	    RT_BITMAP,bitmaps,\
	    RT_VERSION,versions

  resource menus,\
	   IDM_MAIN,LANG_ENGLISH+SUBLANG_DEFAULT,main_menu,\
	   IDM_TAB,LANG_ENGLISH+SUBLANG_DEFAULT,popup_menu

  resource accelerators,\
	   IDA_MAIN,LANG_ENGLISH+SUBLANG_DEFAULT,main_keys

  resource dialogs,\
	   IDD_POSITION,LANG_ENGLISH+SUBLANG_DEFAULT,position_dialog,\
	   IDD_FIND,LANG_ENGLISH+SUBLANG_DEFAULT,find_dialog,\
	   IDD_REPLACE,LANG_ENGLISH+SUBLANG_DEFAULT,replace_dialog,\
	   IDD_COMPILE,LANG_ENGLISH+SUBLANG_DEFAULT,compile_dialog,\
	   IDD_SUMMARY,LANG_ENGLISH+SUBLANG_DEFAULT,summary_dialog,\
	   IDD_ERRORSUMMARY,LANG_ENGLISH+SUBLANG_DEFAULT,error_summary_dialog,\
	   IDD_APPEARANCE,LANG_ENGLISH+SUBLANG_DEFAULT,appearance_dialog,\
	   IDD_COMPILERSETUP,LANG_ENGLISH+SUBLANG_DEFAULT,compiler_setup_dialog,\
	   IDD_CALCULATOR,LANG_ENGLISH+SUBLANG_DEFAULT,calculator_dialog,\
	   IDD_ABOUT,LANG_ENGLISH+SUBLANG_DEFAULT,about_dialog

  resource group_icons,\
	   IDI_MAIN,LANG_NEUTRAL,main_icon

  resource icons,\
	   1,LANG_NEUTRAL,main_icon_data

  resource bitmaps,\
	   IDB_ASSIGN,LANG_NEUTRAL,assign_bitmap

  resource versions,\
	   1,LANG_NEUTRAL,version

  IDM_MAIN	    = 101
  IDM_TAB	    = 102
  IDA_MAIN	    = 201
  IDD_POSITION	    = 301
  IDD_FIND	    = 302
  IDD_REPLACE	    = 303
  IDD_COMPILE	    = 304
  IDD_SUMMARY	    = 305
  IDD_ERRORSUMMARY  = 306
  IDD_APPEARANCE    = 307
  IDD_COMPILERSETUP = 308
  IDD_ABOUT	    = 309
  IDD_CALCULATOR    = 310
  IDI_MAIN	    = 401
  IDB_ASSIGN	    = 501

  IDM_NEW	      = 1101
  IDM_OPEN	      = 1102
  IDM_SAVE	      = 1103
  IDM_SAVEAS	      = 1104
  IDM_NEXT	      = 1105
  IDM_PREVIOUS	      = 1106
  IDM_OPENFOLDER      = 1107
  IDM_CLOSE	      = 1108
  IDM_EXIT	      = 1109
  IDM_SELECTFILE      = 1110
  IDM_UNDO	      = 1201
  IDM_REDO	      = 1202
  IDM_CUT	      = 1203
  IDM_COPY	      = 1204
  IDM_PASTE	      = 1205
  IDM_DELETE	      = 1206
  IDM_SELECTALL       = 1207
  IDM_VERTICAL	      = 1208
  IDM_DISCARD_UNDO    = 1209
  IDM_READONLY	      = 1210
  IDM_POSITION	      = 1301
  IDM_FIND	      = 1302
  IDM_FINDNEXT	      = 1303
  IDM_REPLACE	      = 1304
  IDM_RUN	      = 1401
  IDM_COMPILE	      = 1402
  IDM_DEBUG	      = 1403
  IDM_ASSIGN	      = 1409
  IDM_APPEARANCE      = 1501
  IDM_COMPILERSETUP   = 1502
  IDM_SECURESEL       = 1505
  IDM_AUTOBRACKETS    = 1506
  IDM_AUTOINDENT      = 1507
  IDM_SMARTTABS       = 1508
  IDM_OPTIMALFILL     = 1509
  IDM_REVIVEDEADKEYS  = 1510
  IDM_TIMESCROLL      = 1511
  IDM_ONEINSTANCEONLY = 1512
  IDM_CONTENTS	      = 1901
  IDM_KEYWORD	      = 1902
  IDM_PICKHELP	      = 1903
  IDM_CALCULATOR      = 1904
  IDM_ABOUT	      = 1909

  ID_CHANGE	   = 2001
  ID_SELECT	   = 2101
  ID_CASESENSITIVE = 2102
  ID_WHOLEWORDS    = 2103
  ID_BACKWARD	   = 2104
  ID_INWHOLETEXT   = 2105
  ID_PROMPT	   = 2106
  ID_CONSOLECARET  = 2107
  ID_ROW	   = 2201
  ID_COLUMN	   = 2202
  ID_DISPLAY	   = 2203
  ID_INSTRUCTION   = 2204
  ID_EXPRESSION    = 2205
  ID_DECRESULT	   = 2206
  ID_HEXRESULT	   = 2207
  ID_BINRESULT	   = 2208
  ID_OCTRESULT	   = 2209
  ID_TEXT	   = 2301
  ID_NEWTEXT	   = 2302
  ID_SETTING	   = 2401
  ID_PREVIEW	   = 2402
  ID_PRIORITY	   = 2505
  ID_PASSES	   = 2506
  ID_RECURSION	   = 2507
  ID_INCLUDEPATH   = 2508
  ID_SOURCEHEADER  = 2509
  ID_DECSELECT	   = 2601
  ID_HEXSELECT	   = 2602
  ID_BINSELECT	   = 2603
  ID_OCTSELECT	   = 2604
  ID_PROGRESS	   = 2801
  ID_ICON	   = 2901
  ID_MESSAGE	   = 2902
  ID_ERRORS	   = 2903

  _ equ ,09h,

  menu main_menu
       menuitem '&File',0,MFR_POPUP
		menuitem '&New' _ 'Ctrl+N',IDM_NEW
		menuitem '&Open...' _ 'Ctrl+O',IDM_OPEN
		menuitem '&Save' _ 'Ctrl+S',IDM_SAVE
		menuitem 'Save &as...',IDM_SAVEAS
		menuseparator
		menuitem 'E&xit' _ 'Alt+X',IDM_EXIT,MFR_END
       menuitem '&Edit',0,MFR_POPUP
		menuitem '&Undo' _ 'Ctrl+Z',IDM_UNDO
		menuitem '&Redo' _ 'Ctrl+Shift+Z',IDM_REDO
		menuseparator
		menuitem 'Cu&t' _ 'Ctrl+X',IDM_CUT
		menuitem '&Copy' _ 'Ctrl+C',IDM_COPY
		menuitem '&Paste' _ 'Ctrl+V',IDM_PASTE
		menuitem '&Delete',IDM_DELETE
		menuseparator
		menuitem 'Select &all' _ 'Ctrl+A',IDM_SELECTALL
		menuseparator
		menuitem '&Vertical selection' _ 'Alt+Ins',IDM_VERTICAL,MFR_END
       menuitem '&Search',0,MFR_POPUP
		menuitem '&Position...' _ 'Ctrl+G',IDM_POSITION
		menuseparator
		menuitem '&Find...' _ 'Ctrl+F',IDM_FIND
		menuitem 'Find &next' _ 'F3',IDM_FINDNEXT
		menuitem '&Replace...' _ 'Ctrl+H',IDM_REPLACE,MFR_END
       menuitem '&Run',0,MFR_POPUP
		menuitem '&Run' _ 'F9',IDM_RUN
		menuitem '&Compile' _ 'Ctrl+F9',IDM_COMPILE,MFR_END
       menuitem '&Options',0,MFR_POPUP
		menuitem '&Appearance...',IDM_APPEARANCE
		menuitem '&Compiler setup...',IDM_COMPILERSETUP
		menuseparator
		menuitem '&Secure selection',IDM_SECURESEL
		menuitem 'Automatic &brackets',IDM_AUTOBRACKETS
		menuitem 'Automatic &indents',IDM_AUTOINDENT
		menuitem 'Smart &tabulation',IDM_SMARTTABS
		menuitem '&Optimal fill on saving',IDM_OPTIMALFILL
		menuitem '&Revive dead keys',IDM_REVIVEDEADKEYS
		menuitem 'Ti&me scrolling',IDM_TIMESCROLL
		menuitem 'O&ne instance only',IDM_ONEINSTANCEONLY,MFR_END
       menuitem '&Help',0,MFR_POPUP + MFR_END
		menuitem '&Contents' _ 'Alt+F1',IDM_CONTENTS
		menuitem '&Keyword search' _ 'F1',IDM_KEYWORD
		menuseparator
		menuitem '&Pick help file...',IDM_PICKHELP
		menuseparator
		menuitem 'Ca&lculator...' _ 'Ctrl+F6',IDM_CALCULATOR
		menuseparator
		menuitem '&About...',IDM_ABOUT,MFR_END

  menu popup_menu
       menuitem '',0,MFR_POPUP+MFR_END
		menuitem '&Assign to compiler' _ 'Shift+F9',IDM_ASSIGN
		menuitem 'Open &folder',IDM_OPENFOLDER
		menuitem '&Read-only mode' _ 'Shift+F6',IDM_READONLY
		menuseparator
		menuitem '&Close' _ 'Esc',IDM_CLOSE,MFR_END

  accelerator main_keys,\
	      FVIRTKEY+FNOINVERT+FCONTROL,'N',IDM_NEW,\
	      FVIRTKEY+FNOINVERT+FCONTROL,'O',IDM_OPEN,\
	      FVIRTKEY+FNOINVERT+FCONTROL,'S',IDM_SAVE,\
	      FVIRTKEY+FNOINVERT+FCONTROL,'Z',IDM_UNDO,\
	      FVIRTKEY+FNOINVERT+FCONTROL+FSHIFT,'Z',IDM_REDO,\
	      FVIRTKEY+FNOINVERT+FCONTROL,'X',IDM_CUT,\
	      FVIRTKEY+FNOINVERT+FCONTROL,'C',IDM_COPY,\
	      FVIRTKEY+FNOINVERT+FCONTROL,'V',IDM_PASTE,\
	      FVIRTKEY+FNOINVERT+FCONTROL,'A',IDM_SELECTALL,\
	      FVIRTKEY+FNOINVERT+FCONTROL,'G',IDM_POSITION,\
	      FVIRTKEY+FNOINVERT+FCONTROL,'F',IDM_FIND,\
	      FVIRTKEY+FNOINVERT+FCONTROL,'H',IDM_REPLACE,\
	      FVIRTKEY+FNOINVERT+FCONTROL,VK_TAB,IDM_NEXT,\
	      FVIRTKEY+FNOINVERT+FCONTROL+FSHIFT,VK_TAB,IDM_PREVIOUS,\
	      FVIRTKEY+FNOINVERT,VK_F1,IDM_KEYWORD,\
	      FVIRTKEY+FNOINVERT+FALT,VK_F1,IDM_CONTENTS,\
	      FVIRTKEY+FNOINVERT,VK_F2,IDM_SAVE,\
	      FVIRTKEY+FNOINVERT+FSHIFT,VK_F2,IDM_SAVEAS,\
	      FVIRTKEY+FNOINVERT,VK_F4,IDM_OPEN,\
	      FVIRTKEY+FNOINVERT,VK_F3,IDM_FINDNEXT,\
	      FVIRTKEY+FNOINVERT,VK_F5,IDM_POSITION,\
	      FVIRTKEY+FNOINVERT+FSHIFT,VK_F6,IDM_READONLY,\
	      FVIRTKEY+FNOINVERT,VK_F7,IDM_FIND,\
	      FVIRTKEY+FNOINVERT+FSHIFT,VK_F7,IDM_FINDNEXT,\
	      FVIRTKEY+FNOINVERT+FCONTROL,VK_F7,IDM_REPLACE,\
	      FVIRTKEY+FNOINVERT,VK_F9,IDM_RUN,\
	      FVIRTKEY+FNOINVERT+FCONTROL,VK_F9,IDM_COMPILE,\
	      FVIRTKEY+FNOINVERT,VK_F8,IDM_DEBUG,\
	      FVIRTKEY+FNOINVERT+FSHIFT,VK_F9,IDM_ASSIGN,\
	      FVIRTKEY+FNOINVERT+FCONTROL,VK_F6,IDM_CALCULATOR,\
	      FVIRTKEY+FNOINVERT,VK_ESCAPE,IDM_CLOSE,\
	      FVIRTKEY+FNOINVERT+FALT,VK_DELETE,IDM_DISCARD_UNDO,\
	      FVIRTKEY+FNOINVERT+FALT,'X',IDM_EXIT,\
	      FVIRTKEY+FNOINVERT+FALT,'1',IDM_SELECTFILE+1,\
	      FVIRTKEY+FNOINVERT+FALT,'2',IDM_SELECTFILE+2,\
	      FVIRTKEY+FNOINVERT+FALT,'3',IDM_SELECTFILE+3,\
	      FVIRTKEY+FNOINVERT+FALT,'4',IDM_SELECTFILE+4,\
	      FVIRTKEY+FNOINVERT+FALT,'5',IDM_SELECTFILE+5,\
	      FVIRTKEY+FNOINVERT+FALT,'6',IDM_SELECTFILE+6,\
	      FVIRTKEY+FNOINVERT+FALT,'7',IDM_SELECTFILE+7,\
	      FVIRTKEY+FNOINVERT+FALT,'8',IDM_SELECTFILE+8,\
	      FVIRTKEY+FNOINVERT+FALT,'9',IDM_SELECTFILE+9

  dialog position_dialog,'Position',40,40,126,54,WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'STATIC','&Row:',-1,4,8,28,8,WS_VISIBLE+SS_RIGHT
    dialogitem 'EDIT','',ID_ROW,36,6,34,12,WS_VISIBLE+WS_BORDER+WS_TABSTOP+ES_NUMBER
    dialogitem 'STATIC','&Column:',-1,4,26,28,8,WS_VISIBLE+SS_RIGHT
    dialogitem 'EDIT','',ID_COLUMN,36,24,34,12,WS_VISIBLE+WS_BORDER+WS_TABSTOP+ES_NUMBER
    dialogitem 'BUTTON','&Select',ID_SELECT,36,42,48,8,WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
    dialogitem 'BUTTON','OK',IDOK,78,6,42,14,WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
    dialogitem 'BUTTON','C&ancel',IDCANCEL,78,22,42,14,WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
  enddialog

  dialog find_dialog,'Find',60,60,254,54,WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'STATIC','&Text to find:',-1,4,8,40,8,WS_VISIBLE+SS_RIGHT
    dialogitem 'COMBOBOX','',ID_TEXT,48,6,150,64,WS_VISIBLE+WS_BORDER+WS_TABSTOP+CBS_DROPDOWN+CBS_AUTOHSCROLL+WS_VSCROLL
    dialogitem 'BUTTON','&Case sensitive',ID_CASESENSITIVE,48,24,70,8,WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
    dialogitem 'BUTTON','&Whole words',ID_WHOLEWORDS,48,38,70,8,WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
    dialogitem 'BUTTON','&Backward',ID_BACKWARD,124,24,70,8,WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
    dialogitem 'BUTTON','&In whole text',ID_INWHOLETEXT,124,38,70,8,WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
    dialogitem 'BUTTON','&Find first',IDOK,206,6,42,14,WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
    dialogitem 'BUTTON','C&ancel',IDCANCEL,206,22,42,14,WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
  enddialog

  dialog replace_dialog,'Replace',60,60,254,86,WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'STATIC','&Text to find:',-1,4,8,40,8,WS_VISIBLE+SS_RIGHT
    dialogitem 'COMBOBOX','',ID_TEXT,48,6,150,64,WS_VISIBLE+WS_BORDER+WS_TABSTOP+CBS_DROPDOWN+CBS_AUTOHSCROLL+WS_VSCROLL
    dialogitem 'STATIC','&New text:',-1,4,26,40,8,WS_VISIBLE+SS_RIGHT
    dialogitem 'COMBOBOX','',ID_NEWTEXT,48,24,150,64,WS_VISIBLE+WS_BORDER+WS_TABSTOP+CBS_DROPDOWN+CBS_AUTOHSCROLL+WS_VSCROLL
    dialogitem 'BUTTON','&Case sensitive',ID_CASESENSITIVE,48,42,70,8,WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
    dialogitem 'BUTTON','&Whole words',ID_WHOLEWORDS,48,56,70,8,WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
    dialogitem 'BUTTON','&Backward',ID_BACKWARD,124,42,70,8,WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
    dialogitem 'BUTTON','&In whole text',ID_INWHOLETEXT,124,56,70,8,WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
    dialogitem 'BUTTON','&Prompt on replace',ID_PROMPT,48,70,70,8,WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
    dialogitem 'BUTTON','&Replace',IDOK,206,6,42,14,WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
    dialogitem 'BUTTON','C&ancel',IDCANCEL,206,22,42,14,WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
  enddialog

  dialog compile_dialog,'Compile',64,64,192,42,WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'msctls_progress32','',ID_PROGRESS,8,6,176,12,WS_VISIBLE
    dialogitem 'BUTTON','C&ancel',IDCANCEL,75,24,42,14,WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
  enddialog

  dialog summary_dialog,'Compile',50,50,244,140,WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'BUTTON','OK',IDCANCEL,194,120,42,14,WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
    dialogitem 'STATIC',IDI_ASTERISK,ID_ICON,8,4,0,0,WS_VISIBLE+SS_ICON
    dialogitem 'STATIC','',ID_MESSAGE,36,10,200,8,WS_VISIBLE
    dialogitem 'STATIC','&Display:',-1,8,28,220,8,WS_VISIBLE
    dialogitem 'EDIT','',ID_DISPLAY,8,40,228,74,WS_VISIBLE+WS_BORDER+WS_TABSTOP+ES_MULTILINE+ES_READONLY+ES_AUTOHSCROLL+ES_AUTOVSCROLL+WS_VSCROLL
  enddialog

  dialog error_summary_dialog,'Compile',50,50,248,186,WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'STATIC','&Errors:',-1,8,116,176,8,WS_VISIBLE
    dialogitem 'LISTBOX','',ID_ERRORS,8,128,160,54,WS_VISIBLE+WS_BORDER+WS_TABSTOP+WS_VSCROLL+LBS_NOTIFY
    dialogitem 'BUTTON','OK',IDCANCEL,194,164,42,14,WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
    dialogitem 'STATIC',IDI_HAND,ID_ICON,8,4,0,0,WS_VISIBLE+SS_ICON
    dialogitem 'STATIC','',ID_MESSAGE,36,10,200,28,WS_VISIBLE
    dialogitem 'STATIC','&Display:',-1,8,28,24,8,WS_VISIBLE
    dialogitem 'EDIT','',ID_DISPLAY,8,40,228,44,WS_VISIBLE+WS_BORDER+WS_TABSTOP+ES_MULTILINE+ES_READONLY+ES_AUTOHSCROLL+ES_AUTOVSCROLL+WS_VSCROLL
    dialogitem 'STATIC','Effective &instruction:',-1,8,88,220,8,WS_VISIBLE
    dialogitem 'EDIT','',ID_INSTRUCTION,8,100,228,12,WS_VISIBLE+WS_BORDER+WS_TABSTOP+ES_READONLY+ES_AUTOHSCROLL
  enddialog

  dialog appearance_dialog,'Appearance',50,20,186,166,WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'COMBOBOX','',ID_SETTING,8,6,120,140,WS_VISIBLE+WS_TABSTOP+CBS_DROPDOWNLIST+WS_VSCROLL
    dialogitem 'BUTTON','C&hange...',ID_CHANGE,134,6,42,13,WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
    dialogitem 'FEDIT','',ID_PREVIEW,8,24,168,120,WS_VISIBLE+WS_BORDER+WS_DISABLED+ES_NOHIDESEL
    dialogitem 'BUTTON','&Console caret',ID_CONSOLECARET,8,151,80,8,WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
    dialogitem 'BUTTON','OK',IDOK,88,148,42,14,WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
    dialogitem 'BUTTON','C&ancel',IDCANCEL,134,148,42,14,WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
  enddialog

  dialog compiler_setup_dialog,'Compiler setup',54,28,200,108,WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'STATIC','&Include path(s):',-1,8,4,184,8,WS_VISIBLE+SS_LEFT
    dialogitem 'COMBOBOX','',ID_INCLUDEPATH,8,14,184,48,WS_VISIBLE+WS_BORDER+WS_TABSTOP+CBS_DROPDOWN+WS_VSCROLL+CBS_AUTOHSCROLL
    dialogitem 'STATIC','Source &header:',-1,8,30,184,8,WS_VISIBLE+SS_LEFT
    dialogitem 'COMBOBOX','',ID_SOURCEHEADER,8,40,184,48,WS_VISIBLE+WS_BORDER+WS_TABSTOP+CBS_DROPDOWN+WS_VSCROLL+CBS_AUTOHSCROLL
    dialogitem 'STATIC','&Passes limit:',-1,8,56,60,8,WS_VISIBLE+SS_LEFT
    dialogitem 'EDIT','',ID_PASSES,8,66,54,12,WS_VISIBLE+WS_BORDER+WS_TABSTOP+ES_NUMBER
    dialogitem 'STATIC','&Recursion limit:',-1,72,56,60,8,WS_VISIBLE+SS_LEFT
    dialogitem 'EDIT','',ID_RECURSION,72,66,54,12,WS_VISIBLE+WS_BORDER+WS_TABSTOP+ES_NUMBER
    dialogitem 'STATIC','&Thread priority:',-1,136,56,60,8,WS_VISIBLE+SS_LEFT
    dialogitem 'COMBOBOX','',ID_PRIORITY,136,66,56,96,WS_VISIBLE+WS_TABSTOP+CBS_DROPDOWNLIST+WS_VSCROLL
    dialogitem 'BUTTON','OK',IDOK,104,90,42,14,WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
    dialogitem 'BUTTON','C&ancel',IDCANCEL,150,90,42,14,WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
  enddialog

  dialog calculator_dialog,'Calculator',48,32,380,80,WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'STATIC','&Expression:',-1,4,8,44,8,WS_VISIBLE+SS_RIGHT
    dialogitem 'EDIT','',ID_EXPRESSION,52,6,274,12,WS_VISIBLE+WS_BORDER+WS_TABSTOP+ES_AUTOHSCROLL
    dialogitem 'BUTTON','&Decimal:',ID_DECSELECT,4,20,56,12,WS_VISIBLE+WS_TABSTOP+BS_AUTORADIOBUTTON+BS_RIGHT+BS_LEFTTEXT
    dialogitem 'EDIT','',ID_DECRESULT,62,22,264,10,WS_VISIBLE+ES_READONLY+ES_AUTOHSCROLL
    dialogitem 'BUTTON','&Hexadecimal:',ID_HEXSELECT,4,34,56,12,WS_VISIBLE+WS_TABSTOP+BS_AUTORADIOBUTTON+BS_RIGHT+BS_LEFTTEXT
    dialogitem 'EDIT','',ID_HEXRESULT,62,36,264,10,WS_VISIBLE+ES_READONLY+ES_AUTOHSCROLL
    dialogitem 'BUTTON','&Binary:',ID_BINSELECT,4,48,56,12,WS_VISIBLE+WS_TABSTOP+BS_AUTORADIOBUTTON+BS_RIGHT+BS_LEFTTEXT
    dialogitem 'EDIT','',ID_BINRESULT,62,50,264,10,WS_VISIBLE+ES_READONLY+ES_AUTOHSCROLL
    dialogitem 'BUTTON','&Octal:',ID_OCTSELECT,4,62,56,12,WS_VISIBLE+WS_TABSTOP+BS_AUTORADIOBUTTON+BS_RIGHT+BS_LEFTTEXT
    dialogitem 'EDIT','',ID_OCTRESULT,62,64,264,10,WS_VISIBLE+ES_READONLY+ES_AUTOHSCROLL
    dialogitem 'BUTTON','E&valuate',IDOK,332,6,42,14,WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
    dialogitem 'BUTTON','&Close',IDCANCEL,332,22,42,14,WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
  enddialog

  dialog about_dialog,'About',40,40,172,60,WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'STATIC',<'flat assembler IDE for Windows',0Dh,0Ah,'Copyright ',0A9h,' 1999-2024 Tomasz Grysztar.'>,-1,27,10,144,40,WS_VISIBLE+SS_CENTER
    dialogitem 'STATIC',IDI_MAIN,-1,8,8,32,32,WS_VISIBLE+SS_ICON
    dialogitem 'STATIC','',-1,4,34,164,11,WS_VISIBLE+SS_ETCHEDHORZ
    dialogitem 'STATIC',<'flat assembler g.',VERSION>,-1,4,38,100,20,WS_VISIBLE+SS_LEFT
    dialogitem 'STATIC',<'flat editor ',FEDIT_VERSION_STRING>,-1,4,48,100,20,WS_VISIBLE+SS_LEFT
    dialogitem 'BUTTON','OK',IDOK,124,40,42,14,WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
  enddialog

  icon main_icon,main_icon_data,'resource\fasmgw.ico'

  bitmap assign_bitmap,'resource\assign.bmp'

  versioninfo version,VOS__WINDOWS32,VFT_APP,VFT2_UNKNOWN,LANG_ENGLISH+SUBLANG_DEFAULT,0,\
	      'FileDescription','flat assembler 2',\
	      'LegalCopyright',<'Copyright ',0A9h,' 1999-2024 Tomasz Grysztar.'>,\
	      'FileVersion','2',\
	      'ProductVersion',VERSION,\
	      'OriginalFilename','FASMGW.EXE'
