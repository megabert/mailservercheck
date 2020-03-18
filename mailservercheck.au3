#include <GUIConstants.au3>
#include <String.au3>
#include <StaticConstants.au3>

Func _Foreach($aArray, ByRef $iIndex, ByRef $sValue)
  If IsArray($aArray) Then
	  Local $iLen = UBound($aArray, 1)

	  If $iIndex = $iLen Then
		 Return 0
	  Else
		 $sValue = $aArray[$iIndex]
		 $iIndex = $iIndex + 1
		 Return 1
	  EndIf
   Else
	  SetError(1)
	  Return 0
   EndIf
 EndFunc

Global $leds=['led_red_32.ico', 'led_green_32.ico', 'led_grey_32.ico']
Global $led_red=$leds[0]
Global $led_green=$leds[1]
Global $led_grey=$leds[2]

func setup_files()

   FileInstall("led_grey_32.ico",@ScriptDir & "\" & "led_grey_32.ico")
   FileInstall("led_red_32.ico",@ScriptDir & "\" & "led_red_32.ico")
   FileInstall("led_green_32.ico",@ScriptDir & "\" & "led_green_32.ico")

EndFunc

func build_gui()

   $form = GUICreate("E-Mail Portstatus",300,460,100,350)
   Global $server_fqdn = GUICtrlCreateInput("smtp.gmx.net",10,10,200,20)
   Global $check_button = GUICtrlCreateButton("Check",220,8,50,24)

   GuiCtrlCreateLabel("IP-Adresse:",10,55,200,15)
   Global $lbl_ip_address = GuiCtrlCreateLabel("noch nicht aufgelöst",70,55,200,15)

   GuiCtrlCreateLabel("Port 587, SMTP(empfohlen für Versand)",10,85,200,15)
   GuiCtrlCreateLabel("Port offen",10,115,100,15)
   GuiCtrlCreateLabel("Server antwortet",10,145,100,15)
   Global $LED_587_PORT = GUICtrlCreateIcon($led_grey,'',130,113,20,20)
   Global $LED_587_PROTO= GUICtrlCreateIcon($led_grey,'',130,143,20,20)

   GuiCtrlCreateLabel("Port 25, SMTP(Alternative für Versand)",10,175,200,15)
   GuiCtrlCreateLabel("Port offen",10,205,100,15)
   GuiCtrlCreateLabel("Server antwortet",10,235,100,15)
   Global $LED_25_PORT = GUICtrlCreateIcon($led_grey,'',130,203,20,20)
   Global $LED_25_PROTO= GUICtrlCreateIcon($led_grey,'',130,233,20,20)

   GuiCtrlCreateLabel("Port 143, IMAP(Empfohlen für Empfang)",10,265,200,15)
   GuiCtrlCreateLabel("Port offen",10,295,100,15)
   GuiCtrlCreateLabel("Server antwortet",10,325,100,15)
   Global $LED_143_PORT = GUICtrlCreateIcon($led_grey,'',130,293,20,20)
   Global $LED_143_PROTO= GUICtrlCreateIcon($led_grey,'',130,323,20,20)

   GuiCtrlCreateLabel("Port 110, POP3(Alternative für Empfang)",10,355,200,15)
   GuiCtrlCreateLabel("Port offen",10,385,100,15)
   GuiCtrlCreateLabel("Server antwortet",10,415,100,15)
   Global $LED_110_PORT = GUICtrlCreateIcon($led_grey,'',130,383,20,20)
   Global $LED_110_PROTO= GUICtrlCreateIcon($led_grey,'',130,413,20,20)

   Global $used_leds=[$LED_587_PORT,$LED_587_PROTO,$LED_25_PORT,$LED_25_PROTO,$LED_110_PORT,$LED_110_PROTO,$LED_143_PORT,$LED_143_PROTO]
EndFunc

func check_server($dnsname)

   $ip=TCPNameToIP($dnsname)
   if($ip = "") Then
	  GUICtrlSetData ($lbl_ip_address, "hostname ungültig")
	  return
   Else
	  GUICtrlSetData ($lbl_ip_address, $ip)
   endif

   $res_587 = set_led(check_smtp_server($ip,587), $LED_587_PORT, $LED_587_PROTO)
   $res_25  = set_led(check_smtp_server($ip,25),  $LED_25_PORT,  $LED_25_PROTO)
   $res_143 = set_led(check_imap_server($ip,143), $LED_143_PORT, $LED_143_PROTO)
   $res_110 = set_led(check_pop3_server($ip,110), $LED_110_PORT, $LED_110_PROTO)

EndFunc

func reset_leds($led)
   Dim $key, $value
   While _Foreach($used_leds, $key, $value)
	  GUICtrlSetImage($value,$led)
   WEnd
EndFunc

func open_socket($ip,$port)
   $socket = TCPConnect($ip,$port)
   ; try up to 20 times to open the port
   for $i = 1 to 20
	  if not $socket = -1 then
		 exitloop
	  Endif
   next
   return $socket
EndFunc

func check_proto($ip,$port,$regex)

   ; try up to 20 times to get perfect result
   for $i = 1 to 20
	  ;ConsoleWrite($ip & "/" & $port & "/" & $regex &"try " &$i &"..."&@CRLF)
	  $socket = open_socket($ip,$port)
	  if $socket = -1 Then
		 return 0
	  endif
	  $text=TCPRecv($socket,10000000)
	  if StringRegExp($text,$regex) then
		 return 2 ; 2 => Server responds with ready
	  Endif
	  ; reinitiate tcp if we got no perfect result
	  tcpshutdown()
	  tcpstartup()
   next
   ; if we are here the port is open but the server did not respond with the desired answer
   ; so we return 1 => Port open, Server does not respond correctly
   return 1
EndFunc

func check_smtp_server($ip,$port)
   return check_proto($ip,$port,"^2[0-9][0-9]")
EndFunc

func check_imap_server($ip,$port)
   return check_proto($ip,$port,"^\* OK")
EndFunc

func check_pop3_server($ip,$port)
   return check_proto($ip,$port,"^\+OK")
EndFunc


func set_led($state,$led_port, $led_proto)
   ;ConsoleWrite("setled, got state value: "& $state & @CRLF)
   if($state = 1) Then
	  GUICtrlSetImage($led_port,$led_green)
	  GUICtrlSetImage($led_proto,$led_red)
   EndIf
   if($state = 2) Then
	  GUICtrlSetImage($led_port,$led_green)
	  GUICtrlSetImage($led_proto,$led_green)
   EndIf
   if($state = 0) Then
	  GUICtrlSetImage($led_port,$led_red)
	  GUICtrlSetImage($led_proto,$led_red)
   EndIf
EndFunc

Func delete_files($files)
   Dim $key, $value
   While _Foreach($files, $key, $value)
	  FileDelete($value);
   WEnd
EndFunc

func exit_cleanup()
   delete_files($leds)
   TCPShutdown()
EndFunc

Func main()
   OnAutoItExitRegister("exit_cleanup")
   setup_files()
   TCPStartup()
   build_gui()
   GUISetState()
   reset_leds($led_grey)
   $server_scanned=0

   while 1

	  $msg = GUIGetMsg()
	  Select
	  case $msg = $GUI_EVENT_CLOSE
			exit
		 case $msg = $check_button
			$server_scanned=0
	  endselect

	  if($server_scanned = 0) then
		 reset_leds($led_grey)
		 sleep(200)
		 ConsoleWrite("Checking server "&GUICtrlRead($server_fqdn)&@CRLF)
		 check_server(GUICtrlRead($server_fqdn))
		 $server_scanned=1
	  EndIf
	  sleep(10)
   WEnd
EndFunc

; program starts here

main()

