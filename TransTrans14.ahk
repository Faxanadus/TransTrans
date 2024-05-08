;REPOSITORY AND INSTRUCTIONS: https://github.com/Faxanadus/TransTrans
Hotkey, $~LButton, LMouse, off
Hotkey, $~^C, CopyPause, on
Hotkey, $~^V, PastePause, on
Hotkey, ESC, Escape, off

;SETUP VARIABLES, SAVED TO INI IF ENABLED
maxDisplayLines := 6
minCharactersPerLine := 60 ;NUMBER OF CHARACTERS IN MULTUPLE SENTENCES BEFORE A NEW LINE IN TRANSLATION DISPLAY
maxCharactersPerLine := 82 ;MAXIMUM CHARACTERS BEFORE A NEW LINE IS FORCED IN TRANSLATION DISPLAY
translationDelay := 250 ; HOW LONG TO WAIT BEFORE GRABBING TRANSLATED TEXT AFTER PUSHING TRANSLATE BUTTON
minDelayBetweenTextGrabAttempts := 420 ;MILLISECONDS BETWEEN TRANSCRIPTION WINDOW TEXT GRABBING ATTEMPTS
minDelayBeforeNewLine := 4800 ;MILLISECONDS BEFORE A NEW LINE IS FORCED IN TRANSLATION DISPLAY
minDelayBeforeProcessingNewLine := 1200 ;MILLISECONDS BEFORE THE SCRIPT WILL TRY TO START GRABBING NEW TEXT, TRANSCRIPTION MAY BE INACCURATE ON A NEW LINE IN THE FIRST SECOND
lineTimeout := 30000 ; MILLISECONDS BEFORE A LINE WILL BE REMOVED FROM DISPLAY, 0 = INFINITY
partialTranscriptions := true ; WHETHER PARTIALLY TRANSCRIBED SENTENCES WILL BE PUT IN THE DISPLAY AREA/FILE
partialTranslations := true ; DETERMINES WHETHER TRANSLATION OF TRANSCRIPTED TEXT WILL BE DONE IMMEDIATELY OR BEFORE THE FULL LINE IS DONE
useDisplayFile := true ; DETERMINES WHETHER DISPLAY FILE [AppName]DisplayLog.txt IS CREATED ON STARTUP, INTENDED TO BE USED WITH OTHER TEXT FILE PARSERS
saveSettingsOnClose := true
directory := A_ScriptDir
logFileEnabled := false ; DETERMINES WHETHER A ONGOING TRANSCRIPTION/TRANSLATION LOG FILE WITH TODAYS DATE WILL BE CREATED AND MAINTAINED
logFileTimestamps := true

;NETWORK VARIABLES, SAVED TO INI IF ENABLED
receivingMessages := false ; ENABLES A SERVER FOR RECEIVING STRINGS TO AN IP ADDRESS/PORT FOR TRANSLATION
sendingMessages := false ; ENABLES SENDING THOSE RECEIVED STRINGS TO A DIFFERENT IP ADDRESS/PORT AFTER TRANSLATION
messageAddressEnabled := true
sendMessageAddress := "/AHK/Message" ; THE ADDRESS TO INCLUDE IN A UDP PACKET BEFORE THE MESSAGE, FOR USE WITH OSC PROTOCOL, ETC.
receivedMessageProcessingRate := 500 ; MILLISECONDS DELAY BEFORE A NEW RECEIVED MESSAGE IS TRANSLATED AND SENT
sendingDisplayContent := false ; WHETHER ALL PARTICIPANT CONTENT WILL BE SENT VIA LOCAL IP ADDRESS/PORT, THIS IS THE SAME CONTENT THAT IS SENT TO A DISPLAY WINDOW OR TO DisplayLog.txt
displayIPAddress := "127.0.0.1"
displayPort := 39643
displayMessageAddressEnabled := false
displayMessageAddress := "/AHK/Display" ; ADDRESS TO INCLUDE WHEN SENDING PARTICIPANT TRANSCRIBED/TRANSLATED CONTENT, FOR USE WITH OSC PROTOCOL, ETC.
sendIndividualDisplayLines := false ; IF TRUE, SENDS EACH PARTICIPANT LINE INDIVIDUALLY RATHER THAN SENDING ALL CONTENT EACH TIME IT UPDATES
lineIDType := false ; OPTIONS FOR SENDING A UNIQUE IDENTIFIER FOR EACH LINE TO ANOTHER APPLICATION, AS AN INT (BIG ENDIAN OR LITTLE ENDIAN) OR WITHIN THE STRING AS {ID}


;MEMBER VARIABLES, SAVED TO INI FILE IF ENABLED
memberNames := []
showNames := [] ;WHETHER THIS USER'S NAME WILL BE SHOWN IN THE DISPLAY AREA
memberEnabled := []
translateEnabled := [] ;IF TRANSLATION IS ENABLED FOR THIS MEMBER
windowTitles := []
windowOriginalTitles := []
windowIDs := []
windowMainIDs := []
windowProcessIDs := []
windowControls := []
windowControlPositions := []
windowControlsVerified := []
windowClickPos := []
windowCopyPos := []
windowCopyIDs := []

; MEMBER VARIABLES INTERNALLY AND NOT SAVED TO INI
windowControlTextTests := []
newTexts := []  ; NEW TEXT JUST GRABBED FROM A WINDOW
partialTexts := [] ; TEXT THAT HASN'T BEEN FULLY TRANSCRIBED YET
previousTexts := [] ; PREVIOUS TEXT GRABBED FROM A WINDOW ON THE LAST LOOP
newLines := [] ; NEW LINE TEXT INTENDED FOR DISPLAY
fullLines := [] ; ACCUMULATED newLines THAT MUST REACH minCharactersPerLine OR minDelayBeforeNewLine TO BEING DISPLAYED
lastLines := [] ; LAST TRANSLATED LINE THAT WAS INTENDED FOR DISPLAY
transTexts := [] ; TEXT THAT WAS JUST GRABBED FROM THE TRANSLATOR
firstSamples := [] ; WHETHER THIS IS THE FIRST LINE FROM THE PARTICIPANT, PREVENTS VERY LARGE INITIAL INPUT ON THE FIRST LINE
lastControlStates := [] ; WHETHER THE CLICK METHOD (RATHER THAN CTRL-C) WAS USED ON THE LAST TEXT GRAB ATTEMPT OR ANOTHER WINDOW WAS SELECTED
lastLineTimes := []
lastLineIDs := [] ;DETERMINES POSITION OF THE USER'S LAST MESSAGE IN THE currentLines ARRAY SO MESSAGES CAN BE EDITED LATER
lastNetworkIDs := [] ; DETERMINES THE ID TO SENT TO ANOTHER APPLICATION FOR EACH MESSAGE
lastLineComplete := []
lastLoopStartTime := []
newLineDelayTimes := []

;WINDOW INPUT/OUTPUT VARIABLES SAVED TO INI IF ENABLED
textInputWindow := "QTranslate"
textInputWindowID := ""
textInputControl := "RICHEDIT50W1"
textInputControlPosition := ""
textInputControlVerified := true
textInputClickPos := ""
textInputPastePos := ""
textInputPasteID := ""
translationWindow := "QTranslate"
translationWindowID := ""
translationButton := "Button9"
translationButtonClickPos := ""
translationOutputWindow := "QTranslate"
translationOutputWindowID := ""
translationOutputControl := "RICHEDIT50W2"
translationOutputControlPosition := ""
translationOutputControlVerified := true
translationOutputClickPos := ""
translationOutputCopyPos := ""
translationOutputCopyID := ""
translationDisplayWindow := ""
translationDisplayWindowID := ""
translationDisplayControl := ""
translationDisplayControlPosition := ""
translationDisplayControlVerified := false
translationDisplayClickPos := ""
translationDisplayPastePos := ""
translationDisplayPasteID := ""

; VARIABLES NOT SAVED TO INI, USED INTERALLY
maxMembers := 9
firstTranslation := true
currentLines := [] ; LINES OF TEXT THE SCRIPT IS KEEPING TRACK OF FOR FINAL DISPLAY AND/OR LOG FILE INSERTION
currentLinesTimes := [] ; TIME WHEN THE LINE WAS ENTERED IN FOR DISPLAY
networkLineIDs := [] ; ADDED TO PARTIAL/FULL LINES/PACKETS WHEN SENT OVER THE NETWORK TO HELP THE RECEIVING APP KNOW IF THERE IS A LINE TO UPDATE
running := false
inLoop := false
inLineTimeoutLoop := false
debug :=
appSetupDisplay :=
advancedOptionsDisplay :=
networkDisplay :=
scriptPID := DllCall("GetCurrentProcessId")
; USED TO VERIFY CONTROL AREAS AS WORKING
textInputControlTextTest := ""
translationOutputTextTest := ""
translationDisplayTextTest := ""

; USED TO DECIDE STATE OF WHICH WINDOW THE USER IS CLICKING ON WHEN DETECTION LOOP IS ACTIVE, NOT SAVED TO INI
detectingWindow := false
settingTextOutputWindow := false
settingTextOutputCopyPos := false
settingTextInputWindow := false
settingTextInputPastePos := false
settingTranslationOutputWindow := false
settingTranslationOutputCopyPos := false
settingTranslatedTextDisplay := false
settingTranslatedTextPastePos := false
settingTranslateButton := false

; KEY STATES TO SAVE FOR WHEN THIS SCRIPT NEEDS TO USE THE KEYBOARD
controlDownState := 0
altDownState := 0
shiftDownState := 0
capsDownState := 0
winDownState := 0

previousMessage := "" ; THE LAST MESSAGE RECEIVED BY THE THIS SCRIPT'S SERVER
receivedMessageQueue := [] ; STORES MESSAGES RECEIVED IN A QUEUE FOR TRANSLATION AND SENDING
receivedMessageIDs := [] ; STORES UNIQUE IDS FOR MESSAGES FOR THE RECEIVING APP TO DIFFERENTIATE BETWEEN MESSAGES
receivedMessageLoop := false ; DETERMINES WHETHER RECEIVED MESSAGES ARE CURRENTLY BEING TRANSLATED
translationAppInUse := false ; SET TO TRUE WHEN SOMETHING IN BEING TRANSLATED SO OTHER FUNCTIONS CAN WAIT
sendReceivePaused := false ; USED WHEN MESSAGES ARE TAKING TOO LONG TO TRANSLATE AND THE LOOP NEEDS TO BE RESTARTED
networkLineID := 0 ; CAN BE USED TO DIFFERENTIATE/UPDATE SPECIFIC TRANSCRIBED LINES AFTER THEY ARE SENT OVER THE NETWORK, RANGE: 0-2147483647
sendMessageAddressBuffered := false ; MESSAGE ADDRESSES MUST BE PROPERLY BUFFERED WHEN SENT WITH UTF-8 DECIMAL "0" CHARACTERS
bufferedSendMessageAddress := ""
displayMessageAddressBuffered := false
bufferedDisplayMessageAddress := ""

; Credit to Bentschi for the socket.ahk library, used here to receive and send text via IP address and port: https://www.autohotkey.com/board/topic/94376-socket-class-%C3%BCberarbeitet/
global myUdpIn := new SocketUDP() ; USED TO RECEIVE MESSAGES
global myUdpOut := new SocketUDP() ; USED TO SEND MESSAGES
global mainUdpOut := new SocketUDP() ; USED TO SEND ALL TRANSCRIBED/TRANSLATED CONTENT
scriptName := SubStr(A_ScriptName, 1, StrLen(A_ScriptName) - 4)
displayFile := directory "\" scriptName "-DisplayLog.txt"
	if (useDisplayFile = true) 
	{
		if (FileExist(displayFile))
		{
		 FileDelete, % displayFile
		}
	 FileAppend,, %displayFile%, UTF-8
	}
	
	Loop %maxMembers%
	{
	 participants.Push(A_Index)
	 memberEnabled.Push(0)
	 translateEnabled.Push(0)
	 memberNames.Push("Participant " A_Index)
	 showNames.Push(1)
	 windowTitles.Push("")
	 windowOriginalTitles.Push("")
	 windowControls.Push("")
	 windowControlPositions.Push("")
	 windowControlTextTest.Push("")
	 windowControlsVerified.Push(0)
	 windowProcessIDs.Push("")
	 windowMainIDs.Push("")
	 windowIDs.Push("")
	 windowClickPos.Push("x50 y50")
	 windowCopyPos.Push("x75 y75")
	 windowCopyIDs.Push("")
	 firstSamples.Push(1)
	 lastControlStates.Push(0)
	 newTexts.Push("")
	 previousTexts.Push("")
	 newLines.Push("")
	 fullLines.Push("")
	 lastLines.Push("")
	 transTexts.Push("")
	 lastLineTimes.Push(0)
	 lastLineIDs.Push(0)
	 lastNetworkIDs.Push(0)
	 lastLineComplete.Push(0)
	 newLineDelayTimes.Push(minDelayBeforeProcessingNewLine)
	}
	
memberEnabled[1] := 1
memberNames[1] := "Faxanadus"
currentMember := 1
translateEnabled[1] := 1

Gui,Font, BOLD
Gui, Add, Text,, Participant #
Gui,Font
Gui, Add, Edit, x11 y30 w35 h18 gMemberEdit Limit1 vMemberEdit
Gui, Add, UpDown, gMemberCheck +Wrap Range1-9, 1
MemberEdit_TT := "Current participant number, up to 9 participants with different transcription sources can be enabled."
Gui, Add, CheckBox, x55 y24 gMemberEnabledCheck vMemberEnabledCheck Checked1, Transcribe
MemberEnabledCheck_TT := "If checked, this member's transcribed text can be displayed or logged."
Gui, Add, CheckBox, x55 y42 gTranslateEnabledCheck vTranslateEnabledCheck Checked1, Translate
TranslateEnabledCheck_TT := "If checked, this member's translated text can be displayed or logged."
Gui, Add, Button, x158 y10 w72 h18 gShowAppSetupButton, App Setup >>
Gui, Add, Button, x158 y31 w72 h18 gShowAdvSetupButton, Options  >>
Gui, Add, Button, x158 y52 w72 h18 gNetwork, Network >>

Gui,Font, BOLD
Gui, Add, CheckBox, x10 y60 gShowNameCheck vShowNameCheck Checked1, Name:
ShowNameCheck_TT := "If checked, this member's name will be shown along with displayed text."
Gui,Font
Gui, Add, Edit, r1 gNameCheck vNameEdit w220, Faxanadus

Gui,Font, BOLD
Gui, Add, Text, x10 y106 , Text Output Area for this Participant:
Gui,Font
Gui, Add, Edit, r1 vWindowEdit w220 +ReadOnly, Text output area not set.
Gui, Add, Button, vWindowGetButton gWindowGetButton, Set Participant Output Area
WindowGetButton_TT := "Click on this button to choose where this participant's output text source is located."

Gui,Font, BOLD
Gui, Add, Text,x10 y176, Save Transcription to File:
Gui,Font
Gui, Add, CheckBox, x167 y176 gFileEnabledCheck vFileEnabledCheck Checked0, Enabled
FileEnabledCheck_TT := "If checked, a transcription log text file will be created and updated in the selected directory below.`nThis is separate from TransDisplayLog.txt display file (created in this script's directory on startup)."
Gui, Add, Edit, x10 y194 r1 vFileEdit w220 +ReadOnly, Default Set: Saved in this script's directory.
Gui, Add, Button, x10 y220 w50  vBrowseButton gBrowseButton,  Browse
Gui, Add, CheckBox, x155 y221 gTimestampCheck vTimestampCheck Checked1, Timestamps
TimestampCheck_TT := "If checked, timestamps will be added to the transcription log saved in the above directory`n(separate from TransDisplayLog.txt display file created in this script's directory on startup)."
GUIControl, Hide, TimestampCheck

Gui,Font, BOLD
Gui, Add, Text, x69 y242 w120 vActiveText, Status: Not Active
Gui,Font
Gui, Add, Button, x65 y260 w50 gStartButton, START
Gui, Add, Button, x120 y260 w50 gStopButton, STOP
Gui, Add, Button, x10 y264 gDebug,Debug
Gui, Show, w240 h286, Trans/Trans

; Credit to ismael-miguel for the ahk ini library, used to save settings: https://github.com/ismael-miguel/AHK-ini-parser
scriptName := SubStr(A_ScriptName, 1, StrLen(A_ScriptName) - 4)
iniFileDir := directory "\" scriptName "-Config.ini"
global iniFile := new ini(iniFileDir) 
	if (FileExist(iniFileDir))
	{
	 LoadSettings()
	}
OnMessage(0x200, "WM_MOUSEMOVE") ; USED FOR TOOLTIP MOUSE HOVER DETECTION
return ; END OF STARTUP

ShowAppSetupButton:
{
	if (appSetupDisplay != true) && (appSetupDisplay != false)
	{
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y5 vTransAppText, Translation App Text Input Area:
	 Gui,Font
	 Gui, Add, Edit, r1 vTransInputEdit w220 +ReadOnly, % ((TransInputEdit != "") ? (TransInputEdit) : ("Default Set: QTranslate/RICHEDIT50W1"))
	 Gui, Add, Button, vTransInputGetButton gTransInputGetButton, Set Text Input Area
	 TransInputGetButton_TT := "Click on this button to and (when prompted) click directly on the text input area of a`ntranslation application where you would usually type in words to be translated."

	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y75 vTransOutputText, Translation App Text Output Area:
	 Gui,Font
	 Gui, Add, Edit, r1 vTransOutputEdit w220 +ReadOnly,  % ((TransOutputEdit != "") ? (TransOutputEdit) : ("Default Set: QTranslate/RICHEDIT50W2"))
	 Gui, Add, Button, vTransOutputGetButton gTransOutputGetButton,  Set Translated Text Output Area
	 TransOutputGetButton_TT := "Click on this button to and (when prompted) click directly on the text output area of a`ntranslation application area where translated text would appear."

	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y145 vTransButtonText, Translation App Translate Button:
	 Gui,Font
	 Gui, Add, Edit, r1 vTransButtonEdit w220 +ReadOnly, % ((TransButtonEdit != "") ? (TransButtonEdit) : ("Default Set: QTranslate/Button9"))
	 Gui, Add, Button, vTransButtonGetButton gTransButtonGetButton, Set Translation App Translate Button
	 TransButtonGetButton_TT := "Click on this button to and (when prompted) click directly on the button of the`ntranslation application that you would usually click on to start the translation.`nSome applications may not have this button so this may not be necessary."

	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y215 vTransDisplayText, Translated Text Display Area:
	 Gui,Font
	 Gui, Add, Edit, r1 vTransDisplayEdit w220 +ReadOnly, % ((vTransDisplayEdit != "") ? (vTransDisplayEdit) : ("Display area not set. (Optional)"))
	 Gui, Add, Button, vTransDisplayGetButton gTransDisplayGetButton, Set Translation Display Area
	 TransDisplayGetButton_TT := "Click on this button to and (when prompted) click directly on the the area of an`napplication where you would like the final translated text output to be shown.`nText intended for display is also output to file named`nTransDisplayLog.txt in this script's directory which may be used instead."
	 appSetupDisplay := false
	}
	
	if (appSetupDisplay = true)
	{
	 HideAppSetup()
	 Gui, Show, w240 h286, Trans/Trans
	}
	else if (appSetupDisplay = false)
	{
		if (advancedOptionsDisplay = true)
		{
		 HideAdvanvedSetup()
		}
		if (networkDisplay = true)
		{
		 HideNetwork()
		}
	 ShowAppSetup()
	 Gui, Show, w470 h286, Transcription/Translation
	}
return
}

HideAppSetup()
{
 global
 appSetupDisplay := false
 GUIControl, Hide, TransAppText
 GUIControl, Hide, TransInputEdit 
 GUIControl, Hide, TransInputGetButton 
 GUIControl, Hide, TransOutputText 
 GUIControl, Hide, TransOutputEdit 
 GUIControl, Hide, TransOutputGetButton 
 GUIControl, Hide, TransButtonText 
 GUIControl, Hide, TransButtonEdit 
 GUIControl, Hide, TransButtonGetButton 
 GUIControl, Hide, TransDisplayText 
 GUIControl, Hide, TransDisplayEdit 
 GUIControl, Hide, TransDisplayGetButton
 return
}

ShowAppSetup()
{
 global
 appSetupDisplay := true
 GUIControl, Show, TransAppText
 GUIControl, Show, TransInputEdit 
 GUIControl, Show, TransInputGetButton 
 GUIControl, Show, TransOutputText 
 GUIControl, Show, TransOutputEdit 
 GUIControl, Show, TransOutputGetButton 
 GUIControl, Show, TransButtonText 
 GUIControl, Show, TransButtonEdit 
 GUIControl, Show, TransButtonGetButton 
 GUIControl, Show, TransDisplayText 
 GUIControl, Show, TransDisplayEdit 
 GUIControl, Show, TransDisplayGetButton
 return
}

ShowAdvSetupButton:
{
	if (advancedOptionsDisplay != true) && (advancedOptionsDisplay != false)
	{
	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y10 gPartialTranscriptionsBox vPartialTranscriptionsCheck Checked%partialTranscriptions%, Partial Transcriptions
	 PartialTranscriptionsCheck_TT := "If checked, ongoing transcriptions will be displayed before a full line or sentence has been completed.`nSome software may display innacurate transcriptions within the firs few seconds before self-correcting."
	 Gui, Add, CheckBox, x240 y31 gPartialTranslationsBox vPartialTranslationsCheck Checked%partialTranslations%, Partial Translations
	 PartialTranslationsCheck_TT := "If checked along with Partial Transcriptions, ongoing translations will also be displayed before a full line or sentence has been completed.`nFull sentences are best for accuracy, though sentence fragments often translate well enough."
	 Gui,Font
	
	 Gui,Font, BOLD 
	 Gui, Add, Text, x240 y55 vTransDelayText, Translation Delay:
	 Gui,Font
	 Gui, Add, Edit, x365 y53 w50 h17 gTransDelayEdit vTransDelay, % translationDelay
	 TransDelay_TT := "The average number of milliseconds that it takes the translation app to translate any given message.`nIncrease this delay if the translation application is slow or there is lag when using Internet based translators."
	
	 Gui,Font, BOLD 
	 Gui, Add, Text, x240 y78 vMinDelayText, Text Sample Delay:
	 Gui,Font
	 Gui, Add, Edit, x365 y76 w50 h17 gMinDelayEdit vMinDelay, % minDelayBetweenTextGrabAttempts
	 MinDelay_TT := "The number of milliseconds between this app's attempts to grab text from a transcription application for one participant.`nIf more than one participant is enabled then this delay is divided by however many are active."
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y101 vNewLineText, Force New Line Delay:
	 Gui,Font
	 Gui, Add, Edit, x365 y99 w50 h17 gMinLineDelayEdit vMinLineDelayEdit, % minDelayBeforeNewLine
	 MinLineDelayEdit_TT := "The number of milliseconds this app will wait before creating a new line`n(rather than adding to the current line) if no new transcribed text is detected from one participant."
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y124 vNextLineText, Line Processing Delay:
	 Gui,Font
	 Gui, Add, Edit, x365 y122 w50 h17 gNextLineEdit vNextLineDelay, % minDelayBeforeProcessingNewLine
	 NextLineDelay_TT := "The number of milliseconds this app will wait to start taking in text for a new line after finishing the previous line.`nThis is to help prevent innacurrate early results if Partial Transcriptions are enabled."
	  
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y150 vTotalLinesText, Total Lines to Display:
	 	 Gui,Font
	 Gui, Add, Edit, x365 y148 w40 h17 gLinesEdit Limit2 vMaxLines
	 MaxLines_TT := "The number lines of text to be shown in the display area`nor DisplayLog.txt display file (created in this script's directory on startup).`nIf both transcription and translation are enabled this counts as two lines (one for each language)."
	 Gui, Add, UpDown, vLinesUpDown gLinesCheck +Wrap Range1-99, % maxDisplayLines
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y177 vLineTimeoutText, Line Display Timeout:
	 Gui,Font
	 Gui, Add, Edit, x365 y175 w50 h17 gTimeoutEdit vTextTimeout, % lineTimeout
	 TextTimeout_TT := "The number milliseconds to wait before removing an old text line from from the display area or`nDisplayLog.txt display file (created in this script's directory on startup).`nSetting this to 0 means lines will not time out."
	 
	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y202 gUseDisplayFileCheck vUseDisplayFileCheck Checked%useDisplayFile%, Use DisplayLog.txt File
	 UseDisplayFileCheck_TT := "If checked, a file with this app's name and then DisplayLog.txt will be created in this script's directory,`nand will be continuously updated with participant's transcription/translations.`nThis can be used to display output in text readers such as an OBS Text (GDI+) source."
	 
	 Gui, Add, CheckBox, x240 y225 gSaveSettingsCheck vSaveSettingsCheck Checked%saveSettingsOnClose%, Save Settings on Close
	 SaveSettingsCheck_TT := "If checked, when this app is closed all settings will be saved to a file named TransTrans.ini in this script's directory."
	 Gui,Font
	 
	 advancedOptionsDisplay := false
	}

	if (advancedOptionsDisplay = true)
	{
	 HideAdvanvedSetup()
	 Gui, Show, w240 h286, Trans/Trans
	}
	else if (advancedOptionsDisplay = false)
	{
		if (appSetupDisplay = true)
		{
		 HideAppSetup()
		}
		if (networkDisplay = true)
		{
		 HideNetwork()
		}
	 ShowAdvanvedSetup()
	 ToggleEditFields(!running)
	 Gui, Show, w425 h286, Transcription/Translation
	}
return
}

SaveSettingsCheck:
{
 gui,submit,nohide ;updates gui variable
 saveSettingsOnClose := SaveSettingsCheck
 return
}

UseDisplayFileCheck:
{
 gui,submit,nohide ;updates gui variable
 useDisplayFile := UseDisplayFileCheck
 return
}

HideAdvanvedSetup()
{
 global
 advancedOptionsDisplay := false
 GUIControl, Hide, PartialTranscriptionsCheck
 GUIControl, Hide, PartialTranslationsCheck
 GUIControl, Hide, TransDelayText
 GUIControl, Hide, TransDelay
 GUIControl, Hide, MinDelayText
 GUIControl, Hide, MinDelay
 GUIControl, Hide, NewLineText
 GUIControl, Hide, MinLineDelayEdit
 GUIControl, Hide, NextLineText
 GUIControl, Hide, NextLineDelay
 GUIControl, Hide, TotalLinesText
 GUIControl, Hide, MaxLines
 GUIControl, Hide, LinesUpDown
 GUIControl, Hide, LineTimeoutText
 GUIControl, Hide, TextTimeout
 GUIControl, Hide, UseDisplayFileCheck
 GUIControl, Hide, SaveSettingsCheck
 return
}

ShowAdvanvedSetup()
{
 global
 advancedOptionsDisplay := true
 GUIControl, Show, PartialTranscriptionsCheck
 GUIControl, Show, PartialTranslationsCheck
 GUIControl, Show, TransDelayText
 GUIControl, Show, TransDelay
 GUIControl, Show, MinDelayText
 GUIControl, Show, MinDelay
 GUIControl, Show, NewLineText
 GUIControl, Show, MinLineDelayEdit
 GUIControl, Show, NextLineText
 GUIControl, Show, NextLineDelay
 GUIControl, Show, TotalLinesText
 GUIControl, Show, MaxLines
 GUIControl, Show, LinesUpDown
 GUIControl, Show, LineTimeoutText
 GUIControl, Show, TextTimeout
 GUIControl, Show, UseDisplayFileCheck
 GUIControl, Show, SaveSettingsCheck
 return
}

Network:
{
	if (networkDisplay != true) && (networkDisplay != false)
	{
	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y10 gReceiveMessages vReceiveMessages Checked%receivingMessages%, Receive Messages
	 ReceiveMessages_TT := "If checked, will receive and then translate messages from the below IP address and port."
	 Gui, Add, Text, x240 y32 vReceiveIPText, IP: 
	 Gui,Font
	 Gui, Add, Edit, x262 y30 w100 h18 gReceiveIPAddress vReceiveIPAddress, % ((ReceiveIPAddress != "") ? (ReceiveIPAddress) : ("127.0.0.1"))
	 Gui,Font, BOLD
	 Gui, Add, Text, x366 y32 vReceivePortText, Port: 
	 Gui,Font
	 Gui, Add, Edit,x396 y30 w40 h18  gReceivePort vReceivePort,  % ((ReceivePort != "") ? (ReceivePort) : (39641))
	 
	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y58 gSendMessages vSendMessages Checked%sendingMessages%, Send Messages
	 SendMessages_TT := "If checked, will send translated received messages to the below IP address and port."
	 Gui, Add, Text, x240 y80 vSendIPText, IP:
	 Gui,Font
	 Gui, Add, Edit, x262 y78 w100 h18 gSendIPAddress vSendIPAddress , % ((SendIPAddress != "") ? (SendIPAddress) : ("127.0.0.1"))
	 Gui,Font, BOLD
	 Gui, Add, Text, x366 y80 vSendPortText, Port: 
	 Gui,Font
	 Gui, Add, Edit, x396 y78 w40 h18 gSendPort vSendPort, % ((SendPort != "") ? (SendPort) : (39642))
	  
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y104 vMessageRateText, Message Processing Delay:
	 Gui,Font	 
	 Gui, Add, Edit, x396 y102 w40 h18 gMessageRate vMessageRate, % receivedMessageProcessingRate 	 
	 MessageRate_TT := "Milliseconds delay between sending each received messages to the translator, and then to the specified Send IP Address/Port if enabled."
	 
	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y124 gIncludeMessageAddress vIncludeMessageAddress Checked%messageAddressEnabled%, Include Message Address:
	 IncludeMessageAddress_TT := "If checked, will include the below address in the same packet before the message, separated by a comma like in this example:`n/AHK/Message, Example Message Here.`nThis can be used to send messages via the OSC protocol."
	 Gui,Font
	 Gui, Add, Edit, x240 y142 w196 h18 gMessageAddress vMessageAddress , % sendMessageAddress

	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y172 gSendDisplayContent vSendDisplayContent Checked%sendingDisplayContent%, Send Participant Display Content
	 SendDisplayContent_TT := "If checked, will continuously send all participant Transcribed/Translated content to the specified IP address/port.`nThis is the same content that would be output to a display area or written to the DisplayLog.txt file."
	 Gui, Add, Text, x240 y194 vDisplayIPText, IP: 
	 Gui,Font
	 Gui, Add, Edit, x262 y192 w100 h18 gDisplayIPAddressEdit vDisplayIPAddressEdit, % displayIPAddress
	 Gui,Font, BOLD
	 Gui, Add, Text, x366 y194 vDisplayPortText, Port: 
	 Gui,Font
	 Gui, Add, Edit,x396 y192 w40 h18  vDisplayPortEdit vDisplayPortEdit, % displayPort
	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y218 gIncludeDisplayMessageAddress vIncludeDisplayMessageAddress Checked%displayMessageAddressEnabled%, Include Display Message Address:
	 IncludeDisplayMessageAddress_TT := "If checked, will include the below address in the same packet before`nthe participant display content text, separated by a comma like in this example:`n/AHK/Display, Participant 2: Hello! こんにちは！`nThis can be used to send all participant content via the OSC protocol."
	 Gui,Font
	 Gui, Add, Edit, x240 y238 w196 h18 gDisplayMessageAddressEdit vDisplayMessageAddressEdit, % displayMessageAddress
	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y264 gSendLines vSendLines Checked%sendIndividualDisplayLines%, Send Lines
	 SendLines_TT := "If checked, will send each transcribed/translated text line rather than sending the entire display content when it updates.`nIf Partial Transcriptions are enabled, a line ID (as an integer) will be included in the packet before the message (string), separated by a comma.`nThis is important for the receiving app to know which line to update."
	 Gui, Add, DDL, gLineIDTypeSelection vLineIDTypeSelection x322 y262 w114 h70 AltSubmit Choose1, LineID as int (BE)|LineID as int (LE)|Line {ID} in string|No LineID
	 LineIDTypeSelection_TT := "This selection box determines how an integer will be sent allows the receiving app to`nidentify which lines are being updated when Partial Transcriptions are enabled.`nLineID as int (BE) : The LineID is sent as a Big Endian integer, before the string in the same packet, separated by a comma.`nLineID as int (LE) he LineID is sent as a Little Endian integer, before the string in the same packet, separated by a comma.`nLine {ID} in string : The LineID is not send as an integer, but at the start of the same string in the line content. Example: {6}Hello, This is the line text!"
	 Gui,Font
	 networkDisplay := false
	}
	
	if (networkDisplay = true)
	{
	 HideNetwork()
	 Gui, Show, w240 h286, Trans/Trans
	}
	else if (networkDisplay = false)
	{
		if (appSetupDisplay = true)
		{
		 HideAppSetup()
		}
		if (advancedOptionsDisplay = true)
		{
		 HideAdvanvedSetup()
		}
	 ShowNetwork()
	 Gui, Show, w444 h286, Transcription/Translation
	}
return
}

HideNetwork()
{
 global
 networkDisplay := false
 GUIControl, Hide, ReceiveMessages
 GUIControl, Hide, ReceiveIPText
 GUIControl, Hide, ReceiveIPAddress
 GUIControl, Hide, ReceivePortText
 GUIControl, Hide, ReceivePort
 GUIControl, Hide, SendMessages
 GUIControl, Hide, SendIPText
 GUIControl, Hide, SendIPAddress
 GUIControl, Hide, SendPortText
 GUIControl, Hide, SendPort
 GUIControl, Hide, IncludeMessageAddress
 GUIControl, Hide, MessageAddress
 GUIControl, Hide, MessageRateText
 GUIControl, Hide, MessageRate
 GUIControl, Hide, SendDisplayContent
 GUIControl, Hide, DisplayIPText
 GUIControl, Hide, DisplayIPAddressEdit
 GUIControl, Hide, DisplayPortText
 GUIControl, Hide, DisplayPortEdit
 GUIControl, Hide, IncludeDisplayMessageAddress
 GUIControl, Hide, DisplayMessageAddressEdit
 GUIControl, Hide, SendLines
 GUIControl, Hide, LineIDTypeSelection
 return
}

ShowNetwork()
{
 global
 networkDisplay := true
 GUIControl, Show, ReceiveMessages
 GUIControl, Show, ReceiveIPText
 GUIControl, Show, ReceiveIPAddress
 GUIControl, Show, ReceivePortText
 GUIControl, Show, ReceivePort
 GUIControl, Show, SendMessages
 GUIControl, Show, SendIPText
 GUIControl, Show, SendIPAddress
 GUIControl, Show, SendPortText
 GUIControl, Show, SendPort
 GUIControl, Show, IncludeMessageAddress
 GUIControl, Show, MessageAddress
 GUIControl, Show, MessageRateText
 GUIControl, Show, MessageRate
 GUIControl, Show, SendDisplayContent
 GUIControl, Show, DisplayIPText
 GUIControl, Show, DisplayIPAddressEdit
 GUIControl, Show, DisplayPortText
 GUIControl, Show, DisplayPortEdit
 GUIControl, Show, IncludeDisplayMessageAddress
 GUIControl, Show, DisplayMessageAddressEdit
 GUIControl, Show, SendLines
 GUIControl, Show, LineIDTypeSelection
 return
}

SendDisplayContent:
{
 gui,submit,nohide ;updates gui variable
 sendingDisplayContent := SendDisplayContent
	if (SendDisplayContent = true)
	{
	 mainUdpOut.connect(displayIPAddress, displayPort) 
	 mainUdpOut.enableBroadcast()
	}
	else
	{
	 mainUdpOut.disconnect()
	}
 return
}

DisplayIPAddressEdit:
{
 gui,submit,nohide ;updates gui variable
 GuiControl,, SendDisplayContent, 0
 displayIPAddress := DisplayIPAddressEdit
 sendingDisplayContent := false
 mainUdpOut.disconnect()
 return
}

DisplayPortEdit:
{
 gui,submit,nohide ;updates gui variable
 GuiControl,, SendDisplayContent, 0
 displayPort := DisplayPortEdit
 sendingDisplayContent := false
 mainUdpOut.disconnect()
 return
}

IncludeDisplayMessageAddress:
{
 gui,submit,nohide ;updates gui variable
 displayMessageAddressEnabled := IncludeDisplayMessageAddress
 return
}

DisplayMessageAddressEdit:
{
 gui,submit,nohide ;updates gui variable
 displayMessageAddress := DisplayMessageAddressEdit
 displayMessageAddressBuffered := false
 return
}

SendLines:
{
 gui,submit,nohide ;updates gui variable
 sendIndividualDisplayLines := SendLines
 return
}

LineIDTypeSelection:
{
 gui,submit,nohide ;updates gui variable
 lineIDType :=  LineIDTypeSelection
 return
}

SendMessages:
{
gui,submit,nohide ;updates gui variable
sendingMessages := SendMessages
	if (SendMessages = true)
	{
	 myUdpOut.connect(SendIPAddress, SendPort) 
	 myUdpOut.enableBroadcast()
	}
	else
	{
	 myUdpOut.disconnect()
	}
return
}
	
SendPort:
{
 gui,submit,nohide ;updates gui variable
 GuiControl,, SendMessages, 0
 sendingMessages := false
 myUdpOut.disconnect()
 return
}

SendIPAddress:
{
 gui,submit,nohide ;updates gui variable
 GuiControl,, SendMessages, 0
 endingMessages := false
 myUdpOut.disconnect()
 return
}

ReceiveMessages:
{
gui,submit,nohide ;updates gui variable
receivingMessages := ReceiveMessages
	if (ReceiveMessages = true)
	{
	 myUdpIn.bind(ReceiveIPAddress, ReceivePort)
	 myUdpIn.onRecv := Func("ReceiveMessageCallback")
	}
	else
	{
	 myUdpIn.disconnect()
	}
return
}

ReceiveIPAddress:
{
 gui,submit,nohide ;updates gui variable
 GuiControl,, ReceiveMessages, 0
 receivingMessages := false
 myUdpIn.disconnect()
 return
}

ReceivePort:
{
 gui,submit,nohide ;updates gui variable
 GuiControl,, ReceiveMessages, 0
 receivingMessages := false
 myUdpIn.disconnect()
 return
}

MessageRate:
{
 gui,submit,nohide ;updates gui variable
	if (MessageRate is digit) && (MessageRate != "") && (MessageRate > 0)
	{
	 receivedMessageProcessingRate := MessageRate
	}
 return
}

IncludeMessageAddress:
{
 gui,submit,nohide ;updates gui variable
 messageAddressEnabled := IncludeMessageAddress
 return
}

MessageAddress:
{
 gui,submit,nohide ;updates gui variable
 sendMessageAddress := MessageAddress
 sendMessageAddressBuffered := false
 return
}

Debug:
{
	IfWinNotExist, ahk_id %debugWindowID%
	{
		if (debug = true)
		{
		 debug := False
		}
	}
	if (debug != false) && (debug != true)
	{
	 Gui, debugWindow:Font, BOLD
	 Gui, debugWindow:Add, Text,, Previous Text:
	 Gui, debugWindow:Font
	 Gui, debugWindow:Add, Text, x220 y5 vCurentLoopText, Member Loop: 0
	 Gui, debugWindow:Add, Edit, vPrevTextEdit x10 w300 h130 +ReadOnly, 
	 Gui, debugWindow:Font, BOLD
	 Gui, debugWindow:Add, Text,, New Text:
	 Gui, debugWindow:Font
	 Gui, debugWindow:Add, Edit, vNewTextEdit w300 h130 +ReadOnly, 
	 Gui, debugWindow:Font, BOLD
	 Gui, debugWindow:Add, Text,, Partial Text:
	 Gui, debugWindow:Font
	 Gui, debugWindow:Add, Edit, vPartialTextEdit w300 h55 +ReadOnly, 
	 Gui, debugWindow:Font, BOLD
	 Gui, debugWindow:Add, Text,, New Line:
	 Gui, debugWindow:Font
	 Gui, debugWindow:Add, Edit, vNewLineEdit w300 h76 +ReadOnly, 
	 Gui, debugWindow:Font, BOLD
	 Gui, debugWindow:Add, Text,, Full Line:
	 Gui, debugWindow:Font
	 Gui, debugWindow:Add, Edit, vFullLineEdit w300 h76 +ReadOnly
	 Gui, debugWindow:Show, w320 h600,Debug
	 Gui, debugWindow: +HwnddebugWindowID
	 debug := true
	}
	else if (debug = false)
	{
	 Gui, debugWindow:Show, w320 h600,Debug
	 Gui, debugWindow: +HwnddebugWindowID
	 debug := true
	}
	else
	{
	 debug := false
	 Gui, debugWindow:Hide
	}
 return
}

TimeoutEdit:
{
gui,submit,nohide ;updates gui variable
	if (TextTimeout is digit) && (TextTimeout != "") && (TextTimeout >= 0)
	{
	 lineTimeout := TextTimeout
	}
return
}

LinesEdit:
{
gui,submit,nohide ;updates gui variable
	if (MaxLines is digit) && (MaxLines != "") && (MaxLines > 0) && (MaxLines <= 99)
	{
	 maxDisplayLines := MaxLines
	}
}
return

LinesCheck:
{
gui,submit,nohide ;updates gui variable
maxDisplayLines := MaxLines
}
return

PartialTranscriptionsBox:
{
gui,submit,nohide ;updates gui variable
partialTranscriptions := PartialTranscriptionsCheck
return
}

PartialTranslationsBox:
{
gui,submit,nohide ;updates gui variable
partialTranslations := PartialTranslationsCheck
return
}

TransDelayEdit:
{
gui,submit,nohide ;updates gui variable
	if (TransDelay is digit) && (TransDelay != "") && (TransDelay > 0) 
	{
	 translationDelay := TransDelay
	}
return
}

MinDelayEdit:
{
gui,submit,nohide ;updates gui variable
	if (MinDelay is digit) && (MinDelay != "") && (MinDelay > 0) 
	{
	 minDelayBetweenTextGrabAttempts := MinDelay
	}
return
}

MinLineDelayEdit:
{
gui,submit,nohide ;updates gui variable
	if (MinLineDelayEdit is digit) && (MinLineDelayEdit != "") && (MinLineDelayEdit > 0) 
	{
	 minDelayBeforeNewLine := MinLineDelayEdit
	}
return
}

NextLineEdit:
{
gui,submit,nohide ;updates gui variable
	if (NextLineDelay is digit) && (NextLineDelay != "") && (NextLineDelay > 0) 
	{
	 minDelayBeforeProcessingNewLine := NextLineDelay
	}
return
}

StartButton:
{
	if (running)
	{
	 return
	}
PreStartCheck:
inLoop := false
running := false
enabledCount := 0
titleSet := 0
windowsFound := 0
	Loop, %maxMembers%
	{ ; CHECK IF AT LEAST ONE MEMBER IS ENABLED AND HAS A WINDOW TITLE SET
		if (memberEnabled[A_Index] = true) || (translateEnabled[A_Index] = true)
		{
		 enabledCount += 1
		}
		if (windowTitles[A_Index] != "") || (windowIds[A_Index] != "")
		{
		 titleSet += 1
		}
		if ((windowTitles[A_Index] != "") && WinExist(windowTitles[A_Index]))
		|| ((windowIds[A_Index] != "") && WinExist("ahk_id" windowTitles[A_Index]))
		{
		 windowsFound += 1
		}
	}

	if (enabledCount = 0) || (titleSet = 0) || (windowsFound = 0)
	{
		if (enabledCount = 0)
		{
		 GuiControl, Move, ActiveText, x26 y242 w220
		 GuiControl, Text, ActiveText, Status: All participants are disabled
		}
		else if (titleSet = 0)
		{
		 GuiControl, Move, ActiveText, x12 y242 w222
		 GuiControl,, ActiveText, Status: No participant output windows set
		}
		else
		{
		 GuiControl, Move, ActiveText, x8 y242 w240
		 GuiControl,, ActiveText, Status: No participant output window found
		}
	 return
	}

 GuiControl, Move, ActiveText, x76 y242 w100
 GuiControl, Text, ActiveText, Status: ACTIVE
 running := true
 ResetAll()
 OnMessage(0x200, "") ; DISABLE TOOLTIPS WHILE RUNNING, TOOLTIP TIMERS MAY INTERFERE WITH THE MAIN LOOP
 ToggleEditFields(false)
 SetStoreCapsLockMode, Off
 savedClipboard := Clipboard
 savedClipboardAll := ClipboardAll ;THE USER's CLIPBOARD
 previousTransText := "" ;LAST LINE THE APP GRABBED FROM THE TRANSLATOR
 previousClipboard := "" ;THE APPS'S CLIPBOARD
 previousMessageID := "" ; USED TO IDENTIFY UNIQUE MESSAGES WHEN SENDING/RECEIVING STRINGS OVER NETWORK
 SetTimer, LineTimeoutLoop, Off
 inLineTimeoutLoop := false
 
	Loop
	{
	 	if (running = false)
		{
		 return
		}
		else if (sendReceivePaused = true)
		{
		 receivedMessageLoop := true
		 SetTimer, ReceiveSendLoop, %receivedMessageProcessingRate%
		 sendReceivePaused := false
		}
	 activeMembers := 0
	 lastActiveMember := 0
	 activeMemberList := []
		Loop, %maxMembers%
		{ 
			if (memberEnabled[A_Index] = true) || (translateEnabled[A_Index] = true)
			{
			 activeMembers += 1
			 activeMemberList.Push(A_Index)
			}
		}
		if (activeMembers = 0)
		{
		 Goto, PreStartCheck
		}
	 activeMemberCount := activeMemberList.MaxIndex()
	 lastActiveMember := activeMemberList[activeMemberCount]
		if (loopMember = lastActiveMember)
		{
		 loopMember := 0
		}
		for key, value in activeMemberList
		{
			if (value > loopMember) || (value = lastActiveMember)
			{
			 loopMember = % value
			 break
			}
		}
	 lastLoopStartTime[loopMember] := A_TickCount
	 delay := minDelayBetweenTextGrabAttempts / activeMembers
	 Sleep, % delay
		if (running = false)
		{
		 return
		}
		if (debug)
		{
		 GuiControl, debugWindow:, CurentLoopText, Member Loop: %loopMember%
		}
	 inLoop := true
	 LineTimeoutCheck()
	 memberName := memberNames[loopMember]
	 lastLineTime := lastLineTimes[loopMember]
	 firstSample := firstSamples[loopMember]
	 currentTitle := windowTitles[loopMember]
	 currentID := windowIDs[loopMember]
	 currentPID := windowProcessIDs[loopMember]
	 currentMainID := windowMainIDs[loopMember]
	 clickPos := windowClickPos[loopMember]
	 copyPos := windowCopyPos[loopMember]
	 copyID := windowCopyIDs[loopMember]
	 newText := newTexts[loopMember]
	 previousText := previousTexts[loopMember]
	 newString := newStrings[loopMember]
	 newLine := newLines[loopMember]
	 fullLine := fullLines[loopMember]
	 lastLine :=  lastLines[loopMember]
	 transText := transTexts[loopMember]
	 lastControlState := lastControlStates[loopMember]
	 lastLineID := lastLineIds[loopMember]
	 lastNetworkID := lastNetworkIDs[loopMember]
	 lineComplete := lastLineComplete[loopMember]
	 newLineDelayTime := newLineDelayTime[loopMember]
	 loopStartTime := lastLoopStartTime[loopMember]
	 partialText := partialTexts[loopMember]
	 windowControl := windowControls[loopMember]
	 windowControlPosition := windowControlPositions[loopMember]
	 windowControlVerified := windowControlsVerified[loopMember]
	 windowControlTestText := windowControlTextTests[loopMember]
	 
	 newText := GrabText(windowControl, windowControlPosition, currentTitle, currentID, windowControlVerified, windowControlTestText, loopMember, clickPos, copyPos, copyID, false, false, false)		 
		if (running = false)
		{
		 return
		}	 
			 
		if (previousText = savedClipboard)
		{ ; RESET EVERYTHING
		 firstSample := true
		 newText := ""
		 previousText := ""
		 newStrings := ""
		 newLine := ""
		 fullLine := ""
		 lastLine := ""
		 transText := ""
		 partialText := ""
		 lastControlState := true
		 lastLineTime := A_TickCount
		 Goto, EndLoop
		}
		else if (newText = savedClipboard)
		{
		 newText := ""
		 newLine := ""
		 lastControlState := true
		 lastLineTime := A_TickCount
		 Goto, EndLoop
		}
		
	 newTextTest := RegexReplace(newText, "^\s+") ;trim beginning whitespace
		if (newTextTest = "")
		{ ;DON'T BOTHER PROCESSING TEXT THAT'S JUST A SPACE OR IS NOTHING
		 newText := ""
		 newLine := ""
		 lastControlState := true
		 lastLineTime := A_TickCount
		 Goto, EndLoop
		}
	
	 	if (debug)
		{
		 GuiControl, debugWindow:, NewTextEdit, % newText
		}
		
	 partialText := ""
	 FoundPos := InStr(newText, "     >>")
		if (FoundPos > 0)
		{ ;DISREGARD "     >>" IN CAPTION PREVIEW, AS IT JUST INDICATES THE BARRIER BETWEEN FINISHED TEXT AND TEXT IN PROCESS
		 partialText := SubStr(newText, FoundPos + 7, StrLen(newText))
		 newText := SubStr(newText, 1, FoundPos)
		 newText := RegexReplace(newText, "\s+$") ;trim ending whitespace
		 partialText := RegexReplace(partialText, "\s+$") ;trim ending whitespace
		}
		
		if (debug)
		{
		 GuiControl, debugWindow:, PartialTextEdit, % partialText
		}	
	
		if (StrLen(newText) > 2)
		{ ; BEGIN COMPARING PREVIOUS RECEIVED TEXT TO THE NEW TEXT
		 FoundPos := InStr(newText, previousText)
			if (FoundPos > 0)
			{
			 startPos := FoundPos + StrLen(previousText)
			 endPos := StrLen(newText)
			 newLine := SubStr(newText, startPos, endPos)
			 	if (debug)
				{
				 GuiControl, debugWindow:, NewLineEdit, % newLine
				}	
			}
			else
			{
				Loop
				{
				 testString := SubStr(previousText, A_Index, StrLen(previousText))
				 FoundPos := InStr(newText, testString)
					if (FoundPos > 0)
					{
					 newLine := SubStr(newText, StrLen(testString) + 1, StrLen(newText))
					 break
					}
				}
				if (debug)
				{
				 GuiControl, debugWindow:, NewLineEdit, % newLine
				}
			}

			if (firstSample = true)
			{ ;PREVENTS THE FIRST FOUND TEXT FROM BEING A GIGANTIC WALL OF TEXT
			 previousText := newText
			 firstSample = false
				if (translationOutputControl != "") && (translationOutputWindow != "")
				{ ; CLEARS THE TRANSLATION OUTPUT THE FIRST TIME TO PREVENT GRABBING EXISTING CONTENT
				 ControlSetText, %translationOutputControl%,, %translationOutputWindow%
				}
			 Goto, EndLoop
			}
			else if (newLineDelayTime > 0)
			{
			 deltaTime := A_TickCount - loopStartTime
			 newLineDelayTime -= deltaTime
			 Goto, EndLoop
			}
			else if (((StrLen(newText) > maxCharactersPerLine) && (A_TickCount - lastLineTime < minDelayBeforeProcessingNewLine)))
			{ ; PREVENTS TEXT SPAM FROM BAD GRAB OR COMPARISON ATTEMPTS
			 newText := ""
			 newLine := ""
			 Goto, EndLoop
			}
		}
		
		if (StrLen(newLine) > 2) || ((partialTranscriptions = true) && (StrLen(partialText) > 2))
		{ ;PASTE THE NEW LINE OF TEXT IN THE TRANSLATOR OR OUTPUT AREA
			if ((A_Tickcount - lastLineTime) > (minDelayBeforeNewLine))
			|| ((StrLen(fullLine)) + (StrLen(newLine)) > minCharactersPerLine)
			|| ((InStr(newLine, ".")) && (StrLen(newLine) > 2))
			{ ; FINALIZE THE LINE
			 partialText := ""
			 previousText := newText
			 fullLine := fullLine . newLine
			 	if (debug)
				{
				 GuiControl, debugWindow:, PrevTextEdit, % previousText
				}	 
			 fullLine := RegexReplace(fullLine, "^\s+") ;trim beginning whitespace
			 fullLine := RegExReplace(fullLine, "^\w|(?:\.|:)\s+\K\w", "$U0") ; AUTO CAPITALIZE FIRST LETTER AFTER PUNCTUATION
			 fullLineWithPunctuation := AddPunctuation(fullLine) ; ADDS QUESTION MARKS OR EXTRA PERIODS WHEN NEEDED
			 lastLine := fullLine
			 fullLine := fullLineWithPunctuation
			 lineComplete := true
			}
		 fullPartialLine := fullLine . partialText
		 fullPartialLine := RegexReplace(fullPartialLine, "^\s+") ;trim beginning whitespace
		 		if (debug)
				{
				 GuiControl, debugWindow:, FullLineEdit, % fullPartialLine
				}	 
				
			if (StrLen(fullPartialLine) > 2)
			{
				if ((translateEnabled[loopMember] = true) && ((lineComplete = true) || (partialTranslations = true)) && (((textInputControl != "") || (textInputControlPosition != "")) && ((textInputWindow != "") || (textInputWindowID != ""))))
				{
				 currentWaitTime := A_TickCount
				 	while (translationAppInUse = true)
					{ ; ONLY WAIT ABOUT A SECOND AND A HALF FOR THE TRANSLATOR TO BECOME AVAILABLE
					 Sleep, 50
						if (A_TickCount - currentWaitTime > 1500)
						{
						 SetTimer, ReceiveSendLoop, Off ; TEMPORARILY STOPS MESSAGE TRANSLATION
						 sendReceivePaused := true
						 receivedMessageLoop := false
						 translationAppInUse := false
						}
					}
				 grabAttempts := 0
				 translationAppInUse := true
					if (firstTranslation = true)
					{
					 ClearSetArea(textInputControl, textInputControlPosition, textInputWindow, textInputClickPos)
					 ClearGrabArea(translationOutputControl, translationOutputControlPosition, translationOutputWindow, translationOutputClickPos)
					}				 
				 SetText(textInputControl, textInputControlPosition, textInputWindow, textInputWindowID, textInputControlVerified, 1, fullPartialLine, textInputClickPos, textInputPastePos, textInputPasteID, true, false, true)
				 PushButton:
				 PushTranslateButton()
					if ((translationOutputControl != "") || (translationOutputControlPosition != "")) && ((translationOutputWindow != "") || (translationOutputWindowID != ""))
					{
					 Sleep, %translationDelay%
					 transText := GrabText(translationOutputControl, translationOutputControlPosition, translationOutputWindow, translationOutputWindowId, translationOutputControlVerified, translationOutputTextTest, 10, translationOutputClickPos, translationOutputCopyPos, translationOutputCopyID, true, false, true)
						if (transText = previousTransText) || (transText = "") || (transText = "Cannot detect language. Please choose it manually.")
						{
							if (grabAttempts < 2)
							{
							 grabAttempts += 1
							 Goto, PushButton
							}
						}
					}
				 translationAppInUse := false
				 previousTransText := transText
				 transText := RemoveExtraInformation(fullPartialLine, transText)
				}
				
				if (firstTranslation = true) && (transText != "")
				{
				 firstTranslation := false
				}
				
				if (memberEnabled[loopMember] = true) && (translateEnabled[loopMember] = true)
				{
				 finalText := fullPartialLine "`n" transText
				}
				else if (translateEnabled[loopMember] = true) && (transText != "")
				{
				 finalText := transText
				}
				else
				{
				 finalText := fullPartialLine
				}
				
				if (showNames[loopMember] = true)
				{
				 finalText :=  memberName ": " finalText
				}
						
				if (lastLineID > 0)
				{ ;MODIFY THE CURRENT LINE FOR THE USER IF IT EXISTS
				 currentLines[lastLineID] := finalText
				 currentLinesTimes[lastLineID] := A_TickCount
				}
				else 
				{ ; ADD THE A NEW LINE TO THE ARRAY
				 currentLines.Push(finalText)
				 currentLinesTimes.Push(A_TickCount)
				 lastLineID := currentLines.MaxIndex()
				 networkLineID += 1
					if (networkLineID > 2147483647)
					{
					 networkLineID := 0
					}
				 lastNetworkID := networkLineID
				}

				if (sendingDisplayContent = true) && (sendIndividualDisplayLines = true)
				{ ; SEND THIS LINE TO THE SPECIFIED IP/PORT FOR DISPLAY
				 SendDisplayLine(finalText, lastNetworkID)
				}
						
				if (FileEnabledCheck = true) && (lineComplete = true) 
				{ ;WRITE TEXT TO LOG FILE
				 FormatTime, CurrentDateTime,, MM-dd-yy
				 directoryString := directory "\" CurrentDateTime " Transcript.txt"
					if (TimestampCheck = true)
					{
					 FormatTime, TimeString, A_Now, [hh:mm:ss tt] 
					 finalText := % TimeString " " finalText
					}
				 FileAppend, %finalText%`n, %directoryString%, UTF-8
				}

				if (lineComplete = true)
				{ ; REMOVE THE LAST LINE FROM THE CURRENT LINES ARRAY, LAST LINE IS THE FIRST INDEX DUE TO HOW MESSAGES ARE DISPLAYED IN ORDER
				 lastLineID := 0
				 lineComplete := false
				 lineCount := 0
					for key, value in currentLines
					{ 
					 lineCount += 1
						if InStr(value, "`n")
						{
						 lineCount += 1
						}
					}
					if (lineCount > maxDisplayLines)
					{
					 linesOver := lineCount - maxDisplayLines
						Loop, %linesOver%
						{
						 lastLineText := currentLines[1]
						 linesOver -= 1
							if InStr(lastLineText, "`n")
							{
							 linesOver -= 1
							}
						 currentLines.RemoveAt(1)
						 currentLinesTimes.RemoveAt(1)
							Loop %maxMembers%
							{
								if (lastLineIds[A_Index] > 0)
								{
								 lastLineIDs[A_Index] -= 1
								}
							}
							if (linesOver <= 0)
							{
							 break
							}
						}
					}
				 fullLine := ""
				 lastLineTime := A_TickCount
				 newLineDelayTime := minDelayBeforeProcessingNewLine
				}		
			 UpdateDisplay() ; WRITES ALL THE LINES TO THE DisplayLog.txt FILE (CREATED ON STARTUP IN THE SCRIPT'S DIRECTORY) FOR USE IN DISPLAY IN TEXT READER APPLICATIONS, SUCH AS AN OBS Text (GDI+) SOURCE
			}
		}
	 EndLoop:
	 newTexts[loopMember] := newText 
	 previousTexts[loopMember] := previousText
	 newLines[loopMember] := newLine
	 fullLines[loopMember] := fullLine
	 lastLines[loopMember] := lastLine
	 transTexts[loopMember] := transText
	 firstSamples[loopMember] := firstSample
	 lastControlStates[loopMember] := lastControlState
	 lastLineTimes[loopMember] := lastLineTime
	 lastLineIDs[loopMember] := lastLineID
	 lastNetworkIDs[loopMember] := lastNetworkID
	 lastLineComplete[loopMember] := lineComplete
	 newLineDelayTimes[loopMember] := newLineDelayTime
	 lastLoopStartTime[loopMember] := loopStartTime
	 partialText[loopMember] := partialText
	 windowControlsVerified[loopMember] := windowControlVerified
	 windowControlTextTests[loopMember] := windowControlTestText
	 inLoop := false
		if (running = false)
		{
		 return
		}
	}
inLoop := false
return
}

StopButton:
{
running := false
GuiControl, Move, ActiveText, x69 y242 w120 
GuiControl, Text, ActiveText, Status: Not Active
Hotkey, $~LButton, off
Hotkey, ESC, off
ResetCurrentCursor()
ResetAll()
ToggleEditFields(true)
OnMessage(0x200, "WM_MOUSEMOVE") ; RE-ENABLE TOOLTIPS
	if (inLineTimeoutLoop = false)
	{
	 SetTimer, LineTimeoutLoop, 1000
	}
return
}

SendDisplayLine(thisLine, lineID)
{ ; SEND THE LINE TO ANOTHER APP VIA IP/PORT
global
 thisMessageAddress := ""
	if (lineIDType >= 3)
	{   ; INSERT THE LINE ID IN THE STRING
		if (partialTranscriptions = true) && (lineIDType = 3)
		{ ; PREPEND THE NETWORK LINE ID TO THE STRING IF PARTIAL TRANSCRIPTIONS ARE ENABLED, ELSE DO NOT USE A LINE ID AND ONLY SEND THE STRING
		 thisLine := "{" . lineID . "}" . thisLine
		}
	}

	if (displayMessageAddressEnabled = true)
	{
		if (displayMessageAddressBuffered = false)
		{
		 bufferedDisplayMessageAddress := BufferMessageAddress(displayMessageAddress) 
		 displayMessageAddressBuffered := true
		} 
	 thisMessageAddress := bufferedDisplayMessageAddress
	}

	if (lineIDType = 1)
	{
	 mainUdpOut.sendIntText(lineID, thisLine, thisMessageAddress, true)
	}
	else if (lineIDType = 2)
	{
	 mainUdpOut.sendIntText(lineID, thisLine, thisMessageAddress, false)
	}
	else
	{
	 mainUdpOut.sendText(thisLine, thisMessageAddress)
	}
 return
}

BufferMessageAddress(thisMessageAddress)
{ ; OSC MESSAGE PARTS ALL MUST BE DIVISIBLE BY 4, NON-DIVISIBLE STRINGS MUST BE BUFFERED, INCLUDING THE SEPARATING COMMA,  IS USED AS A BUFFER CHARACTER AND CONVERTED TO UTF-8 DECIMAL "0" CHARACTER ON SEND
 messageAddressLength := StrLen(thisMessageAddress)
 remainder := 4 - Mod(messageAddressLength, 4)
	Loop, %remainder%
	{ ; ADD CHARACTERS TO CREATE A PROPER LENGTH BUFFER FOR THE ADDRESS
	 thisMessageAddress := thisMessageAddress . ""
	}
return thisMessageAddress
}

ReceiveMessageCallback(receiver)
{ ; RECEIVE THE MESSAGE VIA UDP OVER LOCAL NETWORK
 fullMessage := receiver.recvText()
	if (SubStr(fullMessage, 1, 1) = "{")
	{
	 FoundEndBracket := InStr(fullMessage, "}")
		if (FoundEndBracket > 0)
		{
		 message := SubStr(fullMessage, FoundEndBracket + 1, StrLen(fullMessage))
		 messageID := SubStr(fullMessage, 2, FoundEndBracket - 2)
		 AddReceivedMessageToQueue(message, messageID)
		 return
		}
	}
 AddReceivedMessageToQueue(message, "")
 return
}

AddReceivedMessageToQueue(receivedMessage, messageID)
{
 global
 receivedMessage := RegexReplace(receivedMessage, "\s+$") ; TRIM ENDING WHITE SPACE
	if (receivedMessage != "")
	{
	 receivedMessageQueue.Push(receivedMessage)
		if (messageID != "")
		{
		 receivedMessageIDs.Push(messageID)
		}
		else
		{
		 receivedMessageIDs.Push("")
		}
		if (receivedMessageLoop != true)
		{
		 receivedMessageLoop := true
		 SetTimer, ReceiveSendLoop, %receivedMessageProcessingRate%
		}
	}
 return
}

ReceiveSendLoop()
{ ; TRANSLATE MESSAGES ONE BY ONE, STARTING FROM THE FIRST ELEMENT IN receivedMessageQueue
 global
	if (receivedMessageQueue.MaxIndex() < 1)
	{ ; ALL MESSAGES TRANSLATED, STOP LOOP
	 SetTimer, ReceiveSendLoop, Off
	 receivedMessageLoop := false
	}
 currentMessage := receivedMessageQueue[1]
 currentMessageID := receivedMessageIDs[1]
	if (currentMessage = "") || ((previousMessageID !=) "" && (currentMessageID = previousMessageID))
	{ ; CHECK FOR INVALID MESSAGES AND REMOVE THEM
	 receivedMessageQueue.RemoveAt(1)
	 receivedMessageIDs.RemoveAt(1)
		if (receivedMessageQueue.MaxIndex() < 1)
		{ ; ALL MESSAGES TRANSLATED, STOP LOOP
		 SetTimer, ReceiveSendLoop, Off
		 receivedMessageLoop := false
		 return
		}
	}
 
	if (((textInputControl != "") || (textInputControlPosition != "")) && ((textInputWindow != "") || (textInputWindowID != "")))
	{
	 currentMessageWaitTime := A_TickCount
		while (translationAppInUse = true)
		{ ; ONLY WAIT ABOUT FIVE SECONDS FOR THE TRANSLATOR TO BECOME AVAILABLE, PREVENTS POSSIBLE INFINITE LOOPS
		 Sleep, 50
			if (A_TickCount - currentMessageWaitTime > 5000)
			{
			 SetTimer, ReceiveSendLoop, Off ; TEMPORARILY STOPS MESSAGE TRANSLATION
			 sendReceivePaused := true
			 receivedMessageLoop := false
			 return
			}
		}
	 grabAttempts := 0
	 translationAppInUse := true
		if (firstTranslation = true)
		{
		 ClearSetArea(textInputControl, textInputControlPosition, textInputWindow, textInputClickPos)
		 ClearGrabArea(translationOutputControl, translationOutputControlPosition, translationOutputWindow, translationOutputClickPos)
		}
	 SetText(textInputControl, textInputControlPosition, textInputWindow, textInputWindowID, textInputControlVerified, 1, currentMessage, textInputClickPos, textInputPastePos, textInputPasteID, true, false, true)
	 PushButton2:
		if (receivedMessageLoop = false)
		{
		 return
		}
	 PushTranslateButton()
		if ((translationOutputControl != "") || (translationOutputControlPosition != "")) && ((translationOutputWindow != "") || (translationOutputWindowID != ""))
		{
		 Sleep, %translationDelay%
		 transMessage := GrabText(translationOutputControl, translationOutputControlPosition, translationOutputWindow, translationOutputWindowId, translationOutputControlVerified, translationOutputTextTest, 10, translationOutputClickPos, translationOutputCopyPos, translationOutputCopyID, true, false, true)
			 if ((previousTransText = transMessage) && (previousMessage != currentMessage)) || (transMessage = "") || (transMessage = "Cannot detect language. Please choose it manually.")
			{
				if (grabAttempts < 3)
				{
				 grabAttempts += 1
				 Goto, PushButton2
				}
				else
				{
				 transMessage := ""
				}
			}
		}
	 
		if (transMessage != "")
		{
		 previousTransText := transMessage
		 previousMessage := currentMessage
		 firstTranslation := false
		}
	 previousMessageID := currentMessageID
	 translationAppInUse := false
	 sendMessage := RemoveExtraInformation(currentMessage, transMessage)
		if (SendMessages = true)
		{
			if (currentMessageID != "")
			{
			 sendMessage := "{" . currentMessageID . "}" . sendMessage
			}
			
			if (IncludeMessageAddress = true) && (sendMessageAddress != "")
			{ ; OSC MESSAGE PARTS ALL MUST BE DIVISIBLE BY 4, NON-DIVISIBLE STRINGS MUST BE BUFFERED, INCLUDING THE SEPARATING COMMA,  IS USED AS A BUFFER CHARACTER AND CONVERTED TO UTF-8 DECIMAL "0" CHARACTER ON SEND
				if (sendMessageAddressBuffered = false)
				{
				 bufferedSendMessageAddress := BufferMessageAddress(sendMessageAddress) 
				 sendMessageAddressBuffered := true
				} 
			 myUDPOut.sendText(sendMessage, bufferedSendMessageAddress)
			}
			else
			{
			 myUDPOut.sendText(sendMessage, "")
			}
		} 
	 receivedMessageQueue.RemoveAt(1)
	 receivedMessageIDs.RemoveAt(1)
		if (receivedMessageQueue.MaxIndex() < 1)
		{ ; ALL MESSAGES TRANSLATED, STOP LOOP
		 SetTimer, ReceiveSendLoop, Off
		 receivedMessageLoop := false
		}
	}
 return
}

RemoveExtraInformation(originalText, translatedText)
{
 match = `n ; COUNT THE NUMBER OF LINE BREAKS IN THE ORIGINAL LINE AND TRANSLATED OUTPUT TO DETECT EXTRA ADDED INFORMATION
 RegexReplace(originalText, "(" match ")", match, newLineBreakCount)
 RegexReplace(translatedText, "(" match ")", match, transBreakCount)
 foundBreak := InStr(translatedText, "`n",,,newLineBreakCount + 1)
	if (transBreakCount > newLineBreakCount)
	{ ;REMOVE THE EXTRA INFORMATION
	 translatedText := SubStr(translatedText, 1, foundBreak - 2)
	}
 return translatedText
}

ClearSetArea(control, window, windowID, thisClickPos)
{
	if (windowID != "")
	{
	 ControlSetText, %control%, "", ahk_id %windowID%
	}
	else 
	{
	 ControlSetText, %control%, "", %window%
	}
 return
}

ClearGrabArea(control, window, windowID, thisClickPos)
{
	if (windowID != "")
	{
	 ControlSetText, %control%, "", ahk_id %windowID%
	}
	else 
	{
	 ControlSetText, %control%, "", %window%
	}
 return
}

GrabText(control, controlPosition, window, windowID, controlVerified, controlVerificationText, controlVerificationTextID, thisClickPos, thisCopyPos, thisCopyID, skipMouseMethod, skipKeyboardMethod, forceClickOnce)
{
 global
 grabbedText := ""
 forceAlternateMethod := false
	if (control != "")
	{ ; GRAB THE TEXT DIRECTLY FROM APP MEMORY USING A CONTORL AREA IF POSSIBLE
		if (windowID != "") && WinExist("ahk_id" windowID)
		{
		 ControlGetText, grabbedText, %control%, ahk_id %windowID%
		}
		else
		{
		 ControlGetText, grabbedText, %control%, %window%
		}
		if (grabbedText != "")
		{	
			if (controlVerified = false)
			{
				if (controlVerificationText = "")
				{ ;IF THE SCRIPT CAN GRAB DIFFERENT TEXT FROM THE TEXT CONTROL AREA ON DIFFERENT GRAB PASSES, THEN IT CAN BE VERIFIED AS A WORKING CONTROL
					if (controlVerificationTextID < 9)
					{
					 windowControlTestText := grabbedText
					}
					else 
					{
					 translationOutputTextTest := grabbedText
					}
				 controlVerificationText := grabbedText
				}
				else if (grabbedText != controlVerificationText)
				{
					if (controlVerificationTextID < 9)
					{
					 windowControlVerified := true
					}
					else
					{
					 translationOutputControlVerified := true
					}
				 controlVerified := true
				} 
			}
		}
	}
	
	if (control = "") || ((grabbedText = "") && (controlVerified = false))
	{ ; GRAB TEXT DIRECTLY USING KEYBOARD OR MOUSE METHOD
		if (skipMouseMethod)
		{
		 Goto, KeyboardMethod
		}
	 MouseMethod:
	 WinGet, processID, PID, A
	 WinGet, active_id, ID, A
		if (skipKeyboardMethod) || GetKeyState("Control") || GetKeyState("Alt") || GetKeyState("Shift") || GetKeyState("CapsLock") || GetKeyState("Win")
		|| ((processID = currentPID) && (active_id != windowID))
		{ ; USES THE MOUSE CLICK METHOD TO GRAB THE TEXT IF CONTROL IS BEING USED OR THE WINDOW DOES NOT HAVE FOCUS
		 waitIterations := 0
			while (((processID = currentPID) || (processID = scriptPID)) && (GetKeyState("LButton"))) 
			|| ((processID = currentPID) && (active_id != windowID) && (active_id != currentMainID))
			{ ; IF THE USER IS DRAGGING THE ACTIVE WINDOW, WAIT BEFORE CLICKING DURING THIS PERIOD WILL CAUSE THE WHOLE WINDOW TO SHIFT IN A REALLY ANNOYING MANNER
				if (running = false)
				{
				 return
				}
			 Sleep, 100
			 WinGet, processID, PID, A
			 WinGet, active_id, ID, A
				if ((processID = currentPID) && (active_id != windowID))
				{
				 lastControlState := true
				}
			 waitIterations += 1
				if (forceAlternateMethod = false) && (waitIterations >= 5)
				{
				 forceAlternateMethod := true
				 Goto, KeyboardMethod
				}
			}
			
			if (windowID != "") && WinExist("ahk_id" windowID)
			{
			 ControlClick, %thisClickPos%, ahk_id %windowID%,, Left, 3
			 ControlClick, %thisClickPos%, ahk_id %windowID%,, Right, 1
			 savedClipboard := Clipboard
			 savedClipboardAll := ClipboardAll
			ControlClick, %thisCopyPos%, ahk_id %windowID%,, Left, 1
				if (Clipboard = "") || (Clipboard = previousClipboard)
				{ ; TRY AGAIN
				 ControlClick, %thisClickPos%, ahk_id %windowID%,, Left, 3
				 ControlClick, %thisClickPos%, ahk_id %windowID%,, Right, 1
				 ControlClick, %thisCopyPos%, ahk_id %windowID%,, Left, 1
				}
			}
			else
			{
			 ControlClick, %thisClickPos%, %window%,, Left, 3
			 ControlClick, %thisClickPos%, %window%,, Right, 1
			 savedClipboard := Clipboard
			 savedClipboardAll := ClipboardAll
			 ControlClick, %thisCopyPos%, %window%,, Left, 1
				if (Clipboard = "") || (Clipboard = previousClipboard)
				{ ; TRY AGAIN
				 ControlClick, %thisClickPos%, %window%,, Left, 3
				 ControlClick, %thisClickPos%, %window%,, Right, 1
				 ControlClick, %thisCopyPos%, %window%,, Left, 1
				}
			}
		 grabbedText := Clipboard
		 Clipboard := savedClipboardAll
			if ((forceAlternateMethod = false) && ((grabbedtext = "" || grabbedText = previousClipboard)))
			{
			 forceAlternateMethod := true
			 Goto, KeyboardMethod
			}
		}
	 KeyboardMethod:
		if (((grabbedText = "") || (grabbedText = previousClipboard)) && ((control = "") || (controlVerified = false)))
		{
			if ((forceAlternateMethod = false) && (GetKeyState("Control") || GetKeyState("Alt") || GetKeyState("Shift") || GetKeyState("CapsLock") || GetKeyState("Win")))
			{
			 Goto, MouseMethod
			}
		 waitIterations := 0
			while ((GetKeyState("Control") || GetKeyState("Alt") || GetKeyState("Shift") || GetKeyState("CapsLock") || GetKeyState("Win")))
			{
			 	if (running = false)
				{
				 return
				}
			 Sleep, 100
			 waitIterations += 1
				if (waitIterations >= 5)
				{
					if (forceAlternateMethod = false)
					{
					 forceAlternateMethod := true
					 Goto, MouseMethod
					}
					else
					{
					 Goto, CopyEnd
					}
				}
			}
		 
			if ((lastControlState = true) || (forceClickOnce = true))
			{ ; CLEARS THE RIGHT CLICK MENU IF THE LAST GRAB ATTEMPT USED THE MOUSE OR CLICKS ON THE WINDOW TO REGAIN FOCUS
			 lastControlState := false
			 	if (control != "")
				{ ; CLICK THE RELATIVE POSITION WITHIN THE CONTROL AREA
				 ControlClick, %control%, ahk_id %windowID%,, Left, 1, %controlPosition%
				}
				if (windowID != "") && WinExist("ahk_id" windowID)
				{
				 ControlClick, %thisClickPos%, ahk_id %windowID%,, Left, 1
				}
				else 
				{
				 ControlClick, %thisClickPos%, %window%,, Left, 1
				}
			}
		 savedClipboard := Clipboard
		 savedClipboardAll := ClipboardAll
		 SaveKeyDownStates()
			if (!controlDownState)
			{
				if (windowID != "") && WinExist("ahk_id" windowID)
				{
					if (control != "")
					{
					 ControlSend, %control%, {RControl down}ac{RControl up}, ahk_id %windowID%
					}
					else
					{
					 ControlSend,, {RControl down}ac{RControl up}, ahk_id %windowID%
					}
				}
				else 
				{
				 ControlSend,, {RControl down}ac{RControl up}, %window%
				}
			}
			else
			{		
				if (windowID != "") && WinExist("ahk_id" windowID)
				{
					if (control != "")
					{
					 ControlSend, %control%, ac, ahk_id %windowID%
					}
					else
					{
					 ControlSend,, ac, ahk_id %windowID%
					}
				}
				else 
				{
				 ControlSend,, ac, %window%
				}
			}
		 RecallKeyDownStates()
		 grabbedText := Clipboard
		 Clipboard := savedClipboardAll
			if ((forceAlternateMethod = false) && ((grabbedtext = "" || grabbedText = previousClipboard)))
			{
			 forceAlternateMethod := true
			 Goto, MouseMethod
			}
		}
	 CopyEnd:
		if (grabbedText != "")
		{
		 previousClipboard := grabbedText
		}
	}
 return grabbedText
}

SetText(control, controlPosition, window, windowID, controlVerified, controlVerifiedID, textToSet, thisClickPos, thisPastePos, thisPasteID, skipMouseMethod, skipKeyboardMethod, forceClickOnce)
{
 global
 forceAlternateMethod := false
 lastPasteControlState := false
 mouseMethodFinished := false
	if (control != "")
	{ ; SET THE TEXT DIRECTLY INTO THE APP IF POSSIBLE
		if (windowID != "") && WinExist("ahk_id" windowID)
		{
		 ControlSetText, %control%, %textToSet%, ahk_id %windowID%
		}
		else 
		{
		 ControlSetText, %control%, %textToSet%, %window%
		}
		if (controlVerified = false)
		{
		 testText := ""
			if (windowID != "") && WinExist("ahk_id" windowID)
			{
			 ControlGetText, testText, %control%, ahk_id %windowID%
			}
			else 
			{
			 ControlGetText, testText, %control%, %window%
			}
			if (textToSet != "") && (testText = textToSet) 
			{ ;IF THE SCRIPT CAN SET AND THEN GRAB THE SAME TEXT FROM THE CONTROL AREA, THEN IT CAN BE VERIFIED AS A WORKING CONTROL
			 controlVerified := true
				if (controlVerifiedID = 1)
				{
				 textInputControlVerified := true
				}
				else 
				{
				 translationDisplayControlVerified := true
				}
			}
		}
	}

	if (control = "") || ((control != "") && (controlVerified = false))
	{ ; PASTE TEXT DIRECTLY USING KEYBOARD OR MOUSE METHOD
		if (skipMouseMethod)
		{
		 Goto, PasteKeyboardMethod
		}
	 PasteMouseMethod:
		if (forceAlternateMethod = true) || (skipKeyboardMethod = true) || GetKeyState("Control") || GetKeyState("Alt") || GetKeyState("Shift") || GetKeyState("CapsLock") || GetKeyState("Win")
		{ ; USES THE MOUSE CLICK METHOD TO SET THE TEXT IF CONTROL BUTTON IS BEING USED OR THE WINDOW DOES NOT HAVE FOCUS
		 WinGet, processID, PID, A
		 WinGet, active_id, ID, A
		 waitIterations := 0
		 
			while (((processID = currentPID) || (processID = scriptPID)) && (GetKeyState("LButton"))) 
			|| ((processID = currentPID) && (active_id != windowID) && (active_id != currentMainID))
			{ ; IF THE USER IS DRAGGING THE ACTIVE WINDOW, WAIT BEFORE CLICKING DURING THIS PERIOD OR MIGHT CAUSE THE WINDOW TO SHIFT IN A REALLY ANNOYING MANNER
				if (running = false)
				{
				 return
				}
			 Sleep, 100
			 WinGet, processID, PID, A
			 WinGet, active_id, ID, A
			 waitIterations += 1
			 lastPasteControlState := true 
				if (forceAlternateMethod = false) && (waitIterations >= 5)
				{
				 forceAlternateMethod := true
				 Goto, PasteKeyboardMethod
				}
			}
		 lastPasteControlState := true 
			if (windowID != "") && WinExist("ahk_id" windowID)
			{
			 ControlClick, %thisClickPos%, ahk_id %windowID%,, Left, 3
			 ControlClick, %thisClickPos%, ahk_id %windowID%,, Right, 1
			 savedClipboardAll := ClipboardAll
			 ClipBoard := textToSet
			 ControlClick, %thisPastePos%, ahk_id %windowID%,, Left, 1
			}
			else 
			{
			 ControlClick, %thisClickPos%, %window%,, Left, 3
			 ControlClick, %thisClickPos%, %window%,, Right, 1
			 savedClipboardAll := ClipboardAll
			 ClipBoard := textToSet
			 ControlClick, %thisPastePos%, %window%,, Left, 1
			}
		 Clipboard := savedClipboardAll
		 mouseMethodFinished := true
		}
	 PasteKeyboardMethod:
		if (mouseMethodFinished = false) && ((forceAlternateMethod = true) || (!GetKeyState("Control") && !GetKeyState("Alt") && !GetKeyState("Shift") && !GetKeyState("CapsLock") && !GetKeyState("Win")))
		{	 
		 waitIterations := 0
			while ((GetKeyState("Control") || GetKeyState("Alt") || GetKeyState("Shift") || GetKeyState("CapsLock") || GetKeyState("Win")))
			{
			 	if (running = false)
				{
				 return
				}
			 Sleep, 100
			 waitIterations += 1
				if (waitIterations >= 5)
				{
					if (forceAlternateMethod = false)
					{
					 forceAlternateMethod := true
					 Goto, PasteMouseMethod
					}
					else
					{
					 Goto, PasteEnd
					}
				}
			}
			if ((lastPasteControlState = true) || (forceClickOnce = true))
			{ ; CLEARS THE RIGHT CLICK MENU IF THE LAST GRAB ATTEMPT USED THE MOUSE OR CLICKS ON THE WINDOW TO REGAIN FOCUS
			 lastPasteControlState := false
			 	if (windowID != "") && WinExist("ahk_id" windowID)
				{
					if (control != "")
					{ ; CLICK THE RELATIVE POSITION WITHIN THE CONTROL AREA
					 ControlClick, %control%, ahk_id %windowID%,, Left, 1, %controlPosition%
					}
					else
					{
					 ControlClick, %thisClickPos%, ahk_id %windowID%,, Left, 1
					}
				}
				else 
				{
				 ControlClick, %thisClickPos%, %window%,, Left, 1
				}
			}
		 savedClipboardAll := ClipboardAll
		 SaveKeyDownStates()
		 ClipBoard := textToSet
			if (!controlDownState)
			{
				if (windowID != "") && WinExist("ahk_id" windowID)
				{
					if (control != "")
					{
					 ControlSend, %control%, {RControl down}av{RControl up}, ahk_id %windowID%
					}
					else
					{
					 ControlSend,, {RControl down}av{RControl up}, ahk_id %windowID%
					}
				}
				else 
				{
				 ControlSend,, {RControl down}av{RControl up}, %window%
				}
			}
			else
			{		
				if (windowID != "") && WinExist("ahk_id" windowID)
				{
					if (control != "")
					{
					 ControlSend, %control%, av, ahk_id %windowID%
					}
					else
					{
					 ControlSend,, av, ahk_id %windowID%
					}
				}
				else 
				{
				 ControlSend,, av, %window%
				}
			}
		 RecallKeyDownStates()
		 Clipboard := savedClipboardAll
		}
	 PasteEnd:
	}
 return
}

PushTranslateButton()
{
global
if ((translationButton != "") || (translationButtonClickPos != "")) && ((translationWindow != "") || (translationWindowID != ""))
	{ ; PRESS THE TRANSLATE BUTTON
		if ((translationButton = "") || GetKeyState("Control") || GetKeyState("Alt") || GetKeyState("Shift") || GetKeyState("CapsLock") || GetKeyState("Win"))
		{
			if (translationButton != "")
			{
				if (translationWindowID != "") && WinExist("ahk_id" translationWindowID)
				{
				 ControlClick, %translationButton%, ahk_id %translationWindowID%,, Left, 1
				}
				else
				{
				 ControlClick, %translationButton%, %translationWindow%,, Left, 1
				}
			}
			else if (translationButtonClickPos != "")
			{
				if (translationWindowID != "") && WinExist("ahk_id" translationWindowID)
				{
				 ControlClick, %translationButtonClickPos%, ahk_id %translationWindowID%,, Left, 1
				}
				else
				{
				 ControlClick, %translationButtonClickPos%, %translationWindow%,, Left, 1
				}
			}
		}
		else if (translationButton != "")
		{
			if (translationWindowID != "") && WinExist("ahk_id" translationWindowID)
			{
			 ControlSend, %translationButton%, {Space}, ahk_id %translationWindowID%
			}
			else 
			{
			 ControlSend, %translationButton%, {Space}, %translationWindow%
			}
		}
	}
 return
}


ToggleEditFields(toggle)
{ ; TURNS OFF EDIT FIELDS BECAUSE THESE WILL BUG OUT IF THE LOOP IS ACTIVE
 GuiControl, Enable%toggle%, NameEdit
 GuiControl, Enable%toggle%, MinDelay
 GuiControl, Enable%toggle%, MinLineDelayEdit
 GuiControl, Enable%toggle%, NextLineDelay
 GuiControl, Enable%toggle%, TextTimeout
 GuiControl, Enable%toggle%, MaxLines
 GuiControl, Enable%toggle%, ReceiveIPAddress
 GuiControl, Enable%toggle%, ReceivePort
 GuiControl, Enable%toggle%, SendIPAddress
 GuiControl, Enable%toggle%, SendPort
 GuiControl, Enable%toggle%, MessageAddress
 GuiControl, Enable%toggle%, MessageRate
 GuiControl, Enable%toggle%, DisplayIPAddressEdit
 GuiControl, Enable%toggle%, DisplayPortEdit
 GuiControl, Enable%toggle%, DisplayMessageAddressEdit
 return
}

AddPunctuation(testLine)
{
 sentences := StrSplit(testLine, [".", "。"])		 
	Loop, % sentences.MaxIndex()
	{
		if (sentences[A_Index] = "") || (sentences[sentences[A_Index]] = " ")
		{
		 sentences.RemoveAt(A_Index)
		}
	}
 fullLineWithPunctuation := ""
 periodChar := "."
	if (InStr(testLine, "。"))	
	{
	 periodChar := "。"
	}
 sentences := StrSplit(testLine, [".", "。"])
	if (sentences[sentences.MaxIndex()] = "") || (sentences[sentences.MaxIndex()] = " ")
	{
	 sentences.Pop()
	}
 questionWords := ["is", "who", "what", "when", "where", "why", "how"]
 questionChars := ["か","カ"]
	Loop, % sentences.MaxIndex()
	{
	 s := A_Index
	 currentSentence := sentences[s]
		Loop, % questionWords.MaxIndex()
		{
		 FoundPos := InStr(currentSentence, questionWords[A_Index])
			if (FoundPos > 0) && (FoundPos < 3)
			{
			 sentences[s] := sentences[s] "?"
			 break
			}
		}
		Loop, % questionChars.MaxIndex()
		{
		 FoundPos := InStr(currentSentence, questionChars[A_Index])
			if (FoundPos >= StrLen(currentSentence) - 2) && (!InStr(currentSentence, "?"))
			{
			 sentences[s] := sentences[s] "?"
			 break
			}
		}
		if (!InStr(sentences[s], "?"))
		{
		 sentences[s] := sentences[s] . periodChar
		}	
	 fullLineWithPunctuation := fullLineWithPunctuation . sentences[s]
	}
 return fullLineWithPunctuation
}

LineTimeoutLoop:
{
 inLineTimeoutLoop := true
 LineTimeoutCheck()
 return
}

LineTimeoutCheck()
{
 global
	if (currentLines.MaxIndex() > 0) && (lineTimeout > 0)
	{
	 lineNumber := 0
		Loop, % currentLines.MaxIndex()
		{
		 lineNumber += 1
			if (A_TickCount > currentLinesTimes[lineNumber] + lineTimeout)
			{
			 currentLines.RemoveAt(lineNumber)
			 networkLineID.RemoveAt(lineNumber)
			 currentLinesTimes.RemoveAt(lineNumber)
			 lineNumber -= 1
			 UpdateDisplay()
				Loop %maxMembers%
				{
					if (lastLineIds[A_Index] > 0)
					{
					 lastLineIDs[A_Index] -= 1
					}
				}
			}
		 
		}
	}
	if ((inLineTimeoutLoop = true) && ((currentLines.MaxIndex() <= 0) || (lineTimeout <= 0)))
	{
	 SetTimer, LineTimeoutLoop, Off
	 inLineTimeoutLoop := false
	}
 return
}


UpdateDisplay()
{
global
 allLines := ""
	for key, value in currentLines
	{
	 allLines := allLines . value "`n"
	}
	
	if (useDisplayFile = true)
	{
		if FileExist(displayFile)
		{ ; REFORM THE DISPLAY FILE TO SHOW THE NEW CONTENT
		 FileDelete, % displayFile
		}
	 FileAppend, %allLines%, %displayFile%, UTF-8		
	}
	
	if ((translationDisplayWindow != "") || (translationDisplayWindowID != ""))
	{ ; PUT THE TEXT IN THE FINAL DISPLAY AREA, IF NEEDED
	 SetText(translationDisplayControl, translationDisplayControlPosition, translationDisplayWindow, translationDisplayWindowID,translationDisplayControlVerified, 2, allLines, translationDisplayClickPos, translationDisplayPastePos, translationDisplayPasteID, true, false, false)
	}
	
	if (sendingDisplayContent = true) && (sendIndividualDisplayLines = false)
	{ ; SEND ALL MESSAGES TO THE SPECIFIED IP/PORT FOR DISPLAY
		if (displayMessageAddressEnabled = true)
		{ ; OSC MESSAGE PARTS ALL MUST BE DIVISIBLE BY 4, NON-DIVISIBLE STRINGS MUST BE BUFFERED, INCLUDING THE SEPARATING COMMA,  IS USED AS A BUFFER CHARACTER AND CONVERTED TO UTF-8 DECIMAL "0" CHARACTER ON SEND
			if (displayMessageAddressBuffered = false)
			{
			 bufferedDisplayMessageAddress := BufferMessageAddress(displayMessageAddress) 
			 displayMessageAddressBuffered := true
			} 
		 mainUdpOut.sendText(allLines, bufferedDisplayMessageAddress)
		}
		else
		{
		 mainUdpOut.sendText(allLines, "")
		}
	}	
 return
}

ResetAll()
{
 global
	Loop, %maxMembers%
	{ ; RESET MEMBER VARIABLES
	 firstSamples[A_Index] := 1
	 lastControlStates[A_Index] := 0
	 newTexts[A_Index] := ""
	 partialText[A_Index] := ""
	 previousTexts[A_Index] := ""
	 newStrings[A_Index] := ""
	 newLines[A_Index] := ""
	 fullLines[A_Index] := ""
	 lastLines[A_Index] := ""
	 transTexts[A_Index] := ""
	 partialText[A_Index] := ""
	 lastLineTimes[A_Index] := 0
	 lastLineIDs[A_Index] := 0 
	 lastNetworkID[A_Index] := 0
	 lastLineComplete[A_Index] := 0
	 newLineDelayTime[A_Index] := minDelayBeforeProcessingNewLine
	}
 return
}

SaveKeyDownStates()
{
 global
 controlDownState := GetKeyState("Control")
 altDownState := GetKeyState("Alt")
 shiftDownState := GetKeyState("Shift")
 capsDownState := GetKeyState("CapsLock")
 winDownState := GetKeyState("Win")
 return
}

RecallKeyDownStates()
{
 global
	if (controlDownState) 
	{
	 SendInput {Ctrl down}
	}
	if (altDownState)
	{
	 SendInput {Alt down}
	}
	if (shiftDownState)
	{
	 SendInput {Shift down}
	}
	if (capsDownState)
	{
	 SendInput {CapsLock down}
	}
	if (winDownState)
	{
	 SendInput {Win down}
	}
 return
}


MemberEdit:
gui,submit,nohide ;updates gui variable
	if (MemberEdit is digit) && (MemberEdit != "") && (MemberEdit > 0) && (MemberEdit <= maxMembers)
	{
	 currentMember := MemberEdit
	 GuiControl,, MemberEnabledCheck, % memberEnabled[currentMember]
	 GuiControl,, TranslateEnabledCheck, % translateEnabled[currentMember]
	 GuiControl,, NameEdit, % memberNames[currentMember]
		if (windowTitles[currentMember] != "")
		{
		 GuiControl,, WindowEdit, % windowTitles[currentMember]
		}
		else
		{
		 GuiControl,, WindowEdit, Text output area not set.
		}
	 GuiControl,, ShowNameCheck, % showNames[currentMember]
	}
return

MemberCheck:
gui,submit,nohide ;updates gui variable
currentMember := MemberEdit
GuiControl,, MemberEnabledCheck, % memberEnabled[currentMember]
GuiControl,, TranslateEnabledCheck, % translateEnabled[currentMember]
GuiControl,, NameEdit, % memberNames[currentMember]
		if (windowTitles[currentMember] != "")
		{
		 GuiControl,, WindowEdit, % windowTitles[currentMember]
		}
		else
		{
		 GuiControl,, WindowEdit, Text output area not set.
		}
GuiControl,, ShowNameCheck, % showNames[currentMember]
return

MemberEnabledCheck:
gui,submit,nohide ;updates gui variable
memberEnabled[currentMember] := MemberEnabledCheck
return

TranslateEnabledCheck:
gui,submit,nohide ;updates gui variable
translateEnabled[currentMember] := TranslateEnabledCheck
return

NameCheck:
gui,submit,nohide ;updates gui variable
memberName := NameEdit
memberName := StrReplace(memberName, ",", " ") ; REMOVES COMMAS FROM MEMBER NAMES SO THIS DOESN'T INTERFERE WITH COMMAS AS A DELIMITER
memberNames[currentMember] := memberName
return

ShowNameCheck:
gui,submit,nohide ;updates gui variable
showNames[currentMember] := ShowNameCheck
return


FileEnabledCheck:
gui,submit,nohide ;updates gui variable
	if (FileEnabledCheck = true)
	{
	 GUIControl, Show, TimestampCheck
	}
	else
	{
	 GUIControl, Hide, TimestampCheck
	}
logFileEnabled := FileEnabledCheck
return

BrowseButton:
FileSelectFolder, newDirectory, % "*"directory
	if (newDirectory = "")
	{
	 return
	}
	if (newDirectory != directory)
	{
		if FileExist(displayFile)
		{
		 newDisplayFile := newDirectory "\" scriptName . "DisplayLog.txt"
		 FileCopy, displayFile, newDisplayFile
		 FileDelete, % displayFile
		 displayFile := newDisplayFile
		}
	 FileAppend,, %displayFile%, UTF-8
	 directory := newDirectory
	 GuiControl,, FileEdit, %directory%
	}
	
	if (FileEnabledCheck = true) && (lineComplete = true) 
	{ ;WRITE TEXT TO LOG FILE
	 FormatTime, CurrentDateTime,, MM-dd-yy
	 directoryString := directory "\" CurrentDateTime " Transcript.txt"
		if (TimestampCheck = true)
		{
		 FormatTime, TimeString, A_Now, [hh:mm:ss tt] 
		 finalText := % TimeString " " finalText
		}
	 FileAppend, %finalText%`n, %directoryString%, UTF-8
	}
return

TimestampCheck:
gui,submit,nohide ;updates gui variable
logFileTimestamps := TimestampCheck
return

WindowGetButton:
Hotkey, $~LButton, on
Hotkey, ESC, on
DisableWatchCursor()
settingTextOutputWindow := true
SetTimer, WatchCursor, 25
return

TransInputGetButton:
Hotkey, $~LButton, on
Hotkey, ESC, on
DisableWatchCursor()
settingTextInputWindow := true
SetTimer, WatchCursor, 25
return

TransOutputGetButton:
Hotkey, $~LButton, on
Hotkey, ESC, on
DisableWatchCursor()
settingTranslationOutputWindow := true
SetTimer, WatchCursor, 25
return

TransDisplayGetButton:
Hotkey, $~LButton, on
Hotkey, ESC, on
DisableWatchCursor()
settingTranslatedTextDisplay := true
SetTimer, WatchCursor, 25
return

TransButtonGetButton:
Hotkey, $~LButton, on
Hotkey, ESC, on
DisableWatchCursor()
settingTranslateButton := true
SetTimer, WatchCursor, 25
return

ResetCurrentCursor()
{
global
settingTextOutputWindow := false
settingTextOutputCopyPos := false
settingTextInputWindow := false
settingTextInputPastePos := false
settingTranslationOutputWindow := false
settingTranslationOutputCopyPos := false
settingTranslatedTextDisplay := false
settingTranslatedTextPastePos := false
settingTranslateButton := false
return
}

DisableWatchCursor()
{
 SetTimer, WatchCursor, Off
 ToolTip
 detectingWindow := false
 RangeTip()
 ResetCurrentCursor()
}

WatchCursor:
{
 detectingWindow := true
 MouseGetPos, , , id, control
 MouseGetPos, xpos, ypos 
 WinGetTitle, title, ahk_id %id%
 rectangleGuideColor := "Blue"
	if (settingTextOutputWindow = true)
	{
	 ToolTip, Click on the text output area for the participant.`nGetting Text Output Window Title and Control Area [ESC to Cancel]`n(Under Mouse position at X:%xpos% Y:%ypos%):`n%title%`n%control%
	}
	else if (settingTextInputWindow = true)
	{
	 ToolTip, Click on the area where text can be input for translation.`nGetting Text Input Window Title and Control Area [ESC to Cancel]`n(Under Mouse position at X:%xpos% Y:%ypos%):`n%title%`n%control%
	}
	else if (settingTranslationOutputWindow = true)
	{
	 ToolTip, Click on the area where translated text appears.`nGetting Translation Output Window Title and Control Area [ESC to Cancel]`n(Under Mouse position at X:%xpos% Y:%ypos%):`n%title%`n%control%
	}
	else if (settingTranslatedTextDisplay = true)
	{
	 ToolTip, Click on the text input area you want the translated text to be displayed.`nGetting Translated Text Window Title and Control Area [ESC to Cancel]`n(Under Mouse position at X:%xpos% Y:%ypos%):`n%title%`n%control%
	}
	else if (settingTranslateButton = true)
	{
	 ToolTip, Click on the translation app translate button.`nGetting Translate Button and Control Area [ESC to Cancel]`n(Under Mouse position at X:%xpos% Y:%ypos%):`n%title%`n%control%
	}
	else if (settingTextOutputCopyPos = true)
	{
	 ToolTip, **Now click on the COPY button.** [ESC to Cancel] X:%xpos% Y:%ypos%
	 rectangleGuideColor := "Red"
	}
	else if (settingTextInputPastePos = true)
	{
	 ToolTip, **Now click on the PASTE button.** [ESC to Cancel] X:%xpos% Y:%ypos%
	 rectangleGuideColor := "Red"
	}
	else if (settingTranslationOutputCopyPos = true)
	{
	 ToolTip, **Now click the COPY button.** [ESC to Cancel] X:%xpos% Y:%ypos%
	 rectangleGuideColor := "Red"
	}
	else if (settingTranslatedTextPastePos = true)
	{
	 ToolTip, **Now click on the PASTE button.** [ESC to Cancel] X:%xpos% Y:%ypos%
	 rectangleGuideColor := "Red"
	}
 WinGetPos, wX, wY, wW, Wh, ahk_id %id%
 ControlGetPos, cX, cY, cW, cH, %control%, ahk_id %id%
 RangeTip(wX + cX, wY + cY, cW, cH, rectangleGuideColor, 4) ; DRAWS A COLORED RECTANGLE OVER THE CONTROL AREA/WINDOW
return
}

Escape:
{
 DisableWatchCursor()
 Hotkey, $~LButton, off
 Hotkey, ESC, off
 	if (running = false)
	{
	 OnMessage(0x200, "WM_MOUSEMOVE")
	}
 return
}

CopyPause:
{ ; Pauses the script when copy/paste operations are happening to prevent overlap
 Pause, On, 1
 Sleep, 100
 Pause, Off, 1
 return
}

PastePause:
{
 Pause, On, 1
 Sleep, 100
 Pause, Off, 1
 return
}

LMouse:
{
SetTimer, WatchCursor, Off
RangeTip()
detectingWindow := false
Hotkey, $~LButton, off
Hotkey, ESC, off
	if (running = false)
	{
	 OnMessage(0x200, "WM_MOUSEMOVE")
	}
ToolTip
WinGetTitle, title, A
MouseGetPos, xpos, ypos , id, control
posString := "x"xpos " y"ypos
copyXpos = xpos + 25
copyYpos = ypos + 25
copyPosString := "x"copyYpos " y"copyYpos
pasteXpos = copyYpos
pasteYpos = copyYpos + 20
pastePosString := "x"pasteXpos " y"pasteYpos
controlXPos := ""
controlYPos := ""
	if (control != "")
	{
	 ControlGetPos, cX, cY, cW, cH, %control%, ahk_id %id%
	 controlXPos := xPos - cX
	 controlYPos := yPos - cY
	}
WinGet, processID, PID, A
WinGet, lastID, IDLast,  ahk_pid %processID%
WinGet, active_id, ID, A
	if (title = "Transcription Translation")
	{
	 return
	}
	if (settingTextOutputWindow = true)
	{
	 settingTextOutputWindow := false
	 name := memberNames[currentMember]
	 name := "[" . name . "] "
	 windowClickPos[currentMember] := posString
	 windowCopyPos[currentMember] := copyPosString
	 windowProcessIDs[currentMember] := processID
	 windowMainIDs[currentMember] := lastID
	 windowIDs[currentMember] := active_id
	 windowControls[currentMember] := control
	 windowControlsVerified[currentMember] := false
	 setTitle := ""
		if (InStr(title, "] "))
		{ ; REMOVE PREVIOUS NAME FROM WINDOW TITLE, IF PRESENT
		 titleArray := StrSplit(title, "] ")
		 titleArray.RemoveAt(1)
			Loop, % titleArray.MaxIndex()
			{
			 setTitle := setTitle . titleArray[A_Index]
			}
		}
		else
		{
		 setTitle := title
		}
	 setTitle := name . setTitle
	 windowTitles[currentMember] := setTitle
	 WinSetTitle, ahk_id %active_id%,, %setTitle%
		if (control != "")
		{
		 windowString :=  setTitle " / " control
		 windowControlPositions[currentMember] := "x"controlXPos " y"controlYPos
		}
		else
		{
		 windowString := setTitle " / " posString
		}
	 settingTextOutputCopyPos := true
	 Send, {RButton}
	 Hotkey, ESC, on
	 Hotkey, $~LButton, LMouse, on		 
	 SetTimer, WatchCursor, On
	 GuiControl,, WindowEdit, %windowString%
	}
	else if (settingTextInputWindow = true)
	{
	 settingTextInputWindow := false
	 textInputWindow := title
	 textInputControl := control
	 textInputControlVerified := false
	 textInputClickPos  := posString
	 textInputWindowID := active_id
	 textInputPastePos := pastePosString
	 	if (control != "")
		{
		 windowString :=  title " / " control
		 textInputControlPosition := % "x"controlXPos " y"controlYPos
		}
		else
		{
		 windowString := title " / " posString
		}
	 settingTextInputPastePos := true
	 Send, {RButton}
	 Hotkey, ESC, on
	 Hotkey, $~LButton, LMouse, on
	 SetTimer, WatchCursor, On
	 GuiControl,, TransInputEdit, %windowString%
	}
	else if (settingTranslationOutputWindow = true)
	{
	 settingTranslationOutputWindow := false
	 translationOutputWindow := title
	 translationOutputControl := control
	 translationOutputControlVerified := false
	 translationOutputClickPos := posString
	 translationOutputCopyPos := copyPosString
	 translationOutputWindowID := active_id
	 	if (control != "")
		{
		 windowString :=  title " / " control
		 translationOutputControlPosition := % "x"controlXPos " y"controlYPos
		}
		else
		{
		 windowString := title " / " posString
		}
	 settingTranslationOutputCopyPos := true
	 Send, {RButton}
	 Hotkey, ESC, on
	 Hotkey, $~LButton, LMouse, on
	 SetTimer, WatchCursor, On
	 GuiControl,, TransOutputEdit, %windowString%
	}
	else if (settingTranslatedTextDisplay = true)
	{
	 settingTranslatedTextDisplay := false
	 translationDisplayWindow := title
	 translationDisplayControl := control
	 translationDisplayControlVerified := false
	 translationDisplayClickPos := posString
	 translationDisplayWindowID := active_id
	 translationDisplayPastePos := pastePosString	 
	 	if (control != "")
		{
		 windowString :=  title " / " control
		 translationDisplayControlPosition := % "x"controlXPos " y"controlYPos
		}
		else
		{
		 windowString := title " / " posString
		}
	 settingTranslatedTextPastePos := true
	 Send, {RButton}
	 Hotkey, ESC, on
	 Hotkey, $~LButton, LMouse, on
	 SetTimer, WatchCursor, On
	 GuiControl,, TransDisplayEdit, %windowString%
	}
	else if (settingTranslateButton = true)
	{
	 settingTranslateButton := false
	 translationWindow := title	
	 translationButton := control
	 	if (control != "")
		{
		 windowString :=  title " / " control
		}
		else
		{
		 windowString := title " / " posString
		}
	 GuiControl,, TransButtonEdit, %windowString%
	 translationButtonClickPos := posString
	 translationWindowID := active_id
	}
	else if (settingTextOutputCopyPos)
	{
	 settingTextOutputCopyPos := false
	 windowCopyPos[currentMember] := posString
	 windowCopyIDs[currentMember] := active_id
	 GuiControlGet, windowString,, WindowEdit
	 windowString := windowString . " Copy: " . posString
	 GuiControl,, WindowEdit, %windowString%
	}
	else if (settingTextInputPastePos)
	{
	 settingTextInputPastePos := false
	 textInputPastePos := posString
	 textInputPasteID := active_id
	 GuiControlGet, windowString,, TransInputEdit
	 windowString := windowString . " Paste: " . posString
	 GuiControl,, TransInputEdit, %windowString%
	}
	else if (settingTranslationOutputCopyPos)
	{
	 settingTranslationOutputCopyPos := false
	 translationOutputCopyPos := posString
	 translationOutputCopyID := active_id
	 GuiControlGet, windowString,, TransOutputEdit
	 windowString := windowString . " Copy: " . posString
	 GuiControl,, TransOutputEdit, %windowString%
	}
	else if (settingTranslatedTextPastePos)
	{
	 settingTranslatedTextPastePos := false
	 translationDisplayPastePos := posString
	 translationDisplayPasteID := active_id
	 GuiControlGet, windowString,, TransDisplayEdit
	 windowString := windowString . " Paste: " . posString
	 GuiControl,, TransDisplayEdit, %windowString%
	}
gui,submit,nohide ;updates gui variable
return
}

WM_MOUSEMOVE()
{
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    if (CurrControl = "")
	{
	 SetTimer, RemoveToolTip, 500
	}
	else If (CurrControl != PrevControl and not InStr(CurrControl, " ")) and not InStr(CurrControl, ">")
    {
	 currentTip := %CurrControl%_TT
		if (StrLen(currentTip) < 3)
		{
		 return
		}
	 ToolTip  ; Turn off any previous tooltip.
	 SetTimer, RemoveToolTip, off
	 SetTimer, DisplayToolTip, 500
		if (CurrControl != "") 
		{
		 PrevControl := CurrControl
		}
    }
	return
    
    DisplayToolTip:
		if InStr(CurrControl, ">")
		{
		 return
		}
	 currentTip := %CurrControl%_TT
		if (StrLen(currentTip) < 3)
		{
		 return
		}
    SetTimer, DisplayToolTip, Off
    ToolTip % %CurrControl%_TT  ; The leading percent sign tell it to use an expression.
    return

    RemoveToolTip:
	SetTimer, DisplayToolTip, off
    SetTimer, RemoveToolTip, Off
	PrevControl := ""
    ToolTip
 return
}

RangeTip(x:="", y:="", w:="", h:="", color:="Red", d:=2) ; Credit to Feiyue from the FindText library
{
  static id:=0
  if (x="")
  {
    id:=0
    Loop 4
      Gui, Range_%A_Index%: Destroy
    return
  }
  if (!id)
  {
    Loop 4
      Gui, Range_%A_Index%: +Hwndid +AlwaysOnTop -Caption +ToolWindow
        -DPIScale +E0x08000000
  }
  x:=Floor(x), y:=Floor(y), w:=Floor(w), h:=Floor(h), d:=Floor(d)
  Loop 4
  {
    i:=A_Index
    , x1:=(i=2 ? x+w : x-d)
    , y1:=(i=3 ? y+h : y-d)
    , w1:=(i=1 or i=3 ? w+2*d : d)
    , h1:=(i=2 or i=4 ? h+2*d : d)
    Gui, Range_%i%: Color, %color%
    Gui, Range_%i%: Show, NA x%x1% y%y1% w%w1% h%h1%
  }
}

class Socket
{ ; Credit to Bentschi for the socket.ahk library: https://www.autohotkey.com/board/topic/94376-socket-class-%C3%BCberarbeitet/
  static __eventMsg := 0x9987
  
  __New(s=-1)
  {
    static init
    if (!init)
    {
      DllCall("LoadLibrary", "str", "ws2_32", "ptr")
      VarSetCapacity(wsadata, 394+A_PtrSize)
      DllCall("ws2_32\WSAStartup", "ushort", 0x0000, "ptr", &wsadata)
      DllCall("ws2_32\WSAStartup", "ushort", NumGet(wsadata, 2, "ushort"), "ptr", &wsadata)
      OnMessage(Socket.__eventMsg, "SocketEventProc")
      init := 1
    }
    this.socket := s
  }
  
  __Delete()
  {
    this.disconnect()
  }
  
  __Get(k, v)
  {
    if (k="size")
      return this.msgSize()
  }
  
  connect(host, port)
  {
    if ((this.socket!=-1) || (!(faddr := next := this.__getAddrInfo(host, port))))
      return 0
	while (next)
    {
      sockaddrlen := NumGet(next+0, 16, "uint")
      sockaddr := NumGet(next+0, 16+(2*A_PtrSize), "ptr")
      if ((this.socket := DllCall("ws2_32\socket", "int", NumGet(next+0, 4, "int"), "int", this.__socketType, "int", this.__protocolId, "ptr"))!=-1)
      {
        if ((r := DllCall("ws2_32\WSAConnect", "ptr", this.socket, "ptr", sockaddr, "uint", sockaddrlen, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "int"))=0)
        {
          DllCall("ws2_32\freeaddrinfo", "ptr", faddr)
          return Socket.__eventProcRegister(this, 0x21)
        }
        this.disconnect()
      }
      next := NumGet(next+0, 16+(3*A_PtrSize), "ptr")
    }
    this.lastError := DllCall("ws2_32\WSAGetLastError")
    return 0
  }
  
  bind(host, port)
  {
    if ((this.socket!=-1) || (!(faddr := next := this.__getAddrInfo(host, port))))
      return 0
    while (next)
    {
      sockaddrlen := NumGet(next+0, 16, "uint")
      sockaddr := NumGet(next+0, 16+(2*A_PtrSize), "ptr")
      if ((this.socket := DllCall("ws2_32\socket", "int", NumGet(next+0, 4, "int"), "int", this.__socketType, "int", this.__protocolId, "ptr"))!=-1)
      {
        if (DllCall("ws2_32\bind", "ptr", this.socket, "ptr", sockaddr, "uint", sockaddrlen, "int")=0)
        {
          DllCall("ws2_32\freeaddrinfo", "ptr", faddr)
          return Socket.__eventProcRegister(this, 0x29)
        }
        this.disconnect()
      }
      next := NumGet(next+0, 16+(3*A_PtrSize), "ptr")
    }
    this.lastError := DllCall("ws2_32\WSAGetLastError")
    return 0
  }
  
  listen(backlog=32)
  {
    return (DllCall("ws2_32\listen", "ptr", this.socket, "int", backlog)=0) ? 1 : 0
  }
  
  accept()
  {
    if ((s := DllCall("ws2_32\accept", "ptr", this.socket, "ptr", 0, "int", 0, "ptr"))!=-1)
    {
      newsock := new Socket(s)
      newsock.__protocolId := this.__protocolId
      newsock.__socketType := this.__socketType
      Socket.__eventProcRegister(newsock, 0x21)
      return newsock
    }
    return 0
  }
  
  disconnect()
  {
    Socket.__eventProcUnregister(this)
    DllCall("ws2_32\closesocket", "ptr", this.socket, "int")
    this.socket := -1
    return 1
  }
  
  msgSize()
  {
    VarSetCapacity(argp, 4, 0)
    if (DllCall("ws2_32\ioctlsocket", "ptr", this.socket, "uint", 0x4004667F, "ptr", &argp)!=0)
      return 0
    return NumGet(argp, 0, "int")
  }
  
  send(addr, length)
  {
    if ((r := DllCall("ws2_32\send", "ptr", this.socket, "ptr", addr, "int", length, "int", 0, "int"))<=0)
      return 0
    return r
  }
  
 sendText(msg, msgAdr, encoding="UTF-8")
  { ; JAPANESE CHARACTERS USE 3 PLACES IN THE BUFFER RATHER THAN 1, OSC MESSAGE BUFFER TOTAL SIZE MUST BE DIVISIBLE BY 4 
	if (msgAdr != "")
	{
	 msg := msgAdr . ",s" . msg
	}
	capacity := VarSetCapacity(buffer, length := StrPut(msg, encoding))
	originalCapacity = capacity
	;MsgBox % originalCapacity " " length " " msg
	remainder := 4 - Mod(capacity, 4)
		if (remainder < 4) && (remainder > 0)
		{
		 capacity += remainder
		 VarSetCapacity(buffer, capacity)
		}
    StrPut(msg, &buffer, encoding)
	P := &buffer
		Loop %capacity%
		{ ; HACK TO CONVERT UTF-8  character (7 in decimal) TO SEND AS A NULL CHARACTER SINCE AHK WILL OMIT NULL CHARACTRS FROM ENCODING WHEN USING StrPut()
		 number := NumGet(&buffer, A_Index, "Char")
			if (number = 7)
			{
			 NumPut(0, &buffer, A_Index, "Char")
			}
		}
	;MsgBox % remainder " " length " " capacity " " originalCapacity
    return this.send(&buffer, capacity)
  }
  
  
sendIntText(num, msg, msgAdr, reverseBytes, encoding="UTF-8")
{ ; JAPANESE CHARACTERS USE 3 PLACES IN THE BUFFER RATHER THAN 1, OSC MESSAGE BUFFER TOTAL SIZE MUST BE DIVISIBLE BY 4 
	if (msgAdr != "")
	{ ; PREPEND THE NEWORK LINE ID IN THE NETWORK PACKET, SEPARATED BY A BUFFERED COMMA FROM THE LINE.  HERE, LINE IDS ARE SENT EVEN IF PARTIAL TRANSCRIPTIONS ARE NOT ENABLED FOR NETWORK PACKET CONSISTENCY
	 msg := msgAdr . ",is" . "" . msg ; ",is0" = integer string null,  char used to signify starting position for integer NumPut
	}
	else
	{
	 msg := "" . "," .  msg
	}
 capacity := VarSetCapacity(buffer, length := StrPut(msg, encoding))
 originalCapacity = capacity
 remainder := 4 - Mod(capacity, 4)
	if (remainder < 4) && (remainder > 0)
	{
	 capacity += remainder
	 VarSetCapacity(buffer, capacity)
	}
 StrPut(msg, &buffer, encoding)
 P := &buffer
	Loop %capacity%
	{ 
	 number := NumGet(&buffer, A_Index, "Char")
		if (number = 7)
		{ ; HACK TO CONVERT UTF-8  character (7 in decimal) TO SEND AS A NULL CHARACTER SINCE AHK WILL OMIT NULL CHARACTRS FROM ENCODING WHEN USING StrPut()
		 NumPut(0, &buffer, A_Index, "Char")
		}
	}
	Loop %capacity%
	{ 
	 number := NumGet(&buffer, A_Index, "Char")
		if (number = 6)
		{ ; HACK TO INSERT A (POSSIBLY BYTE SWAPPED) INTEGER AT THE CORRECT POSITION IN THE BYTE ARRAY, WHERE  INDICATES THE POSITION
			if (reverseBytes = true)
			{ ; SOME APPS PREFER TO RECEIVE INTS AS BIG ENDIAN
			 num := this.ReverseByteOrder(num)
			}
		 NumPut(num, &buffer, A_Index, "uint")
		 break
		}
	}
 return this.send(&buffer, capacity)
}
  
ReverseByteOrder(value)
{ ; REVERSES THE BYTE ORDER IF THE RECEIVING APP RECEIVES INTEGER VALUES AS BIG ENDIAN
 VarSetCapacity(bytes, 4) ;CONVERT INT TO BYTE ARRAY
 NumPut(value, &bytes, 0, "UInt")
 VarSetCapacity(reversedBytes, 4) ; REVERSE BYTES
    Loop 4
	{
     NumPut(NumGet(&bytes, A_Index - 1, "UChar"), &reversedBytes, 4 - A_Index, "UChar")
	} 
 return NumGet(&reversedBytes, 0, "UInt") ; SEND BACK NEW INT
}
  
  recv(byref buffer, wait=1)
  {
    while ((wait) && ((length := this.msgSize())=0))
      sleep, 100
    if (length)
    {
      VarSetCapacity(buffer, length)
      if ((r := DllCall("ws2_32\recv", "ptr", this.socket, "ptr", &buffer, "int", length, "int", 0))<=0)
        return 0
      return r
    }
    return 0
  }
  
  recvText(wait=1, encoding="UTF-8")
  {
    if (length := this.recv(buffer, wait))
      return StrGet(&buffer, length, encoding)
    return
  }
  
  __getAddrInfo(host, port)
  {
    a := ["127.0.0.1", "0.0.0.0", "255.255.255.255", "::1", "::", "FF00::"]
    conv := {localhost:a[1], addr_loopback:a[1], inaddr_loopback:a[1], addr_any:a[2], inaddr_any:a[2], addr_broadcast:a[3]
    , inaddr_broadcast:a[3], addr_none:a[3], inaddr_none:a[3], localhost6:a[4], addr_loopback6:a[4], inaddr_loopback6:a[4]
    , addr_any6:a[5], inaddr_any:a[5], addr_broadcast6:a[6], inaddr_broadcast6:a[6], addr_none6:a[6], inaddr_none6:a[6]}
    if (conv[host])
      host := conv[host]
    VarSetCapacity(hints, 16+(4*A_PtrSize), 0)
    NumPut(this.__socketType, hints, 8, "int")
    NumPut(this.__protocolId, hints, 12, "int")
    if ((r := DllCall("ws2_32\getaddrinfo", "astr", host, "astr", port, "ptr", &hints, "ptr*", next))!=0)
    {
      this.lastError := DllCall("ws2_32\WSAGetLastError")
      return 0
    }
    return next
  }
  
  __eventProcRegister(obj, msg)
  {
    a := SocketEventProc(0, 0, "register", 0)
    a[obj.socket] := obj
    return (DllCall("ws2_32\WSAAsyncSelect", "ptr", obj.socket, "ptr", A_ScriptHwnd, "uint", Socket.__eventMsg, "uint", msg)=0) ? 1 : 0
  }
  
  __eventProcUnregister(obj)
  {
    a := SocketEventProc(0, 0, "register", 0)
    a.remove(obj.socket)
    return (DllCall("ws2_32\WSAAsyncSelect", "ptr", obj.socket, "ptr", A_ScriptHwnd, "uint", 0, "uint", 0)=0) ? 1 : 0
  }
}

SocketEventProc(wParam, lParam, msg, hwnd)
{
  global Socket
  static a := []
  ;Critical COMMENTED OUT BECAUSE THIS PREVENTS OTHER PARTS OF THE SCRIPT FROM RUNNING
  if (msg="register")
    return a
  if (msg=Socket.__eventMsg)
  {
    if (!isobject(a[wParam]))
      return 0
    if ((lParam & 0xFFFF) = 1)
      return a[wParam].onRecv(a[wParam])
    else if ((lParam & 0xFFFF) = 8)
      return a[wParam].onAccept(a[wParam])
    else if ((lParam & 0xFFFF) = 32)
    {
      a[wParam].socket := -1
      return a[wParam].onDisconnect(a[wParam])
    }
    return 0
  }
  return 0
}

class SocketTCP extends Socket
{
  static __protocolId := 6 ;IPPROTO_TCP
  static __socketType := 1 ;SOCK_STREAM
}

class SocketUDP extends Socket
{
  static __protocolId := 17 ;IPPROTO_UDP
  static __socketType := 2 ;SOCK_DGRAM

  enableBroadcast()
  {
    VarSetCapacity(optval, 4, 0)
    NumPut(1, optval, 0, "uint")
    if (DllCall("ws2_32\setsockopt", "ptr", this.socket, "int", 0xFFFF, "int", 0x0020, "ptr", &optval, "int", 4)=0)
      return 1
    return 0
  }
  disableBroadcast()
  {
    VarSetCapacity(optval, 4, 0)
    if (DllCall("ws2_32\setsockopt", "ptr", this.socket, "int", 0xFFFF, "int", 0x0020, "ptr", &optval, "int", 4)=0)
      return 1
    return 0
  }
}

Class ini ; Credit to ismael-miguel for the ahk ini library: https://github.com/ismael-miguel/AHK-ini-parser
{
	ini_file := ""
	ini_data := {}

	__New(ini_file = "")
	{
		ini_file := Trim(ini_file)
		
		if ini_file
		{
			this.ini_file := ini_file

			Try
			{
				FileGetAttrib, attrs, %ini_file%
			}
			catch e
			{}

			If (attrs) and (!InStr(attrs, "D"))
			{
				this.ini_data := new Ini.IniData(ini_file)
			}
			else if attrs
			{
				Throw, "Please specify a file name, not a directory"
			}
			else
			{
				this.ini_data := new Ini.IniData()
			}
		}
		else
		{
			this.ini_data := new Ini.IniData()
		}
	}

	IniFile()
	{
		return this.ini_file
	}

	LoadString(ini_text)
	{
		data := InI.IniParser.ParseFromString(ini_text)
		this.ini_data.LoadData(data)
	}
	
	Save()
	{
		if this.ini_file
		{
			return InI.IniWriter.Write(this.ini_file, this.ini_data)
		}
		else
		{
			Throw, "Please use SaveFile(ini_file) instead"
		}
	}

	SaveFile(ini_file)
	{
		ini_file := Trim(ini_file)
		
		if ini_file
		{
			return InI.IniWriter.Write(ini_file, this.ini_data)
		}
		else
		{
			return this.Save()
		}
	}
	
	Get(value_name, section_name = "", default_value = "")
	{
		value_name := Trim(value_name)
		section_name := Trim(section_name)
		default_value := Trim(default_value)
		
		if !value_name
		{
			Throw, "Value name can't be empty."
		}

		if (this.ini_data.HasValue(value_name, section_name))
		{
			return this.ini_data.GetValue(value_name, section_name)
		}
		else
		{
			return default_value
		}
	}
	
	GetComment(value_name, section_name = "")
	{
		value_name := Trim(value_name)
		section_name := Trim(section_name)
		default_value := Trim(default_value)
		
		if !value_name
		{
			Throw, "Value name can't be empty."
		}

		if (!this.ini_data.HasValue(value_name, section_name))
		{
			return ""
		}
		
		return this.ini_data.GetCommentValue(value_name, section_name)
	}
	
	Set(value_name, section_name, value, comment = "")
	{
		value_name := Trim(value_name)
		section_name := Trim(section_name)
		value := Trim(value)
		comment := Trim(comment)
		
		if (!value_name)
		{
			Throw, "Value name can't be empty."
		}

		this.ini_data.SetValue(value_name, value, section_name)
		
		if (comment)
		{
			this.ini_data.SetCommentValue(value_name, section_name, comment)
		}
	}
	
	SetComment(value_name, section_name, comment)
	{
		value_name := Trim(value_name)
		section_name := Trim(section_name)
		comment := Trim(comment)
		
		if (!value_name)
		{
			Throw, "Value name can't be empty."
		}
		
		if (comment)
		{
			this.ini_data.SetCommentValue(value_name, section_name, comment)
		}
	}
	
	Delete(value_name, section_name)
	{
		value_name := Trim(value_name)
		section_name := Trim(section_name)
		
		if (value_name)
		{
			this.ini_data.DeleteValue(value_name, section_name)
		}
		else
		{
			this.DeleteSection(section_name)
		}
	}
	
	DeleteComment(value_name, section_name)
	{
		value_name := Trim(value_name)
		section_name := Trim(section_name)
		
		if !value_name
		{
			Throw, "Value name can't be empty."
		}
		
		this.ini_data.SetCommentValue(value_name, section_name, "")
	}

	DeleteSection(section_name)
	{
		section_name := Trim(section_name)
		
		this.ini_data.DeleteSection(section_name)
	}

	Exists(value_name, section_name)
	{
		value_name := Trim(value_name)
		section_name := Trim(section_name)
		
		return this.ini_data.HasValue(value_name, section_name)
	}

	ExistsSection(section_name)
	{
		section_name := Trim(section_name)
		
		return this.ini_data.HasSection(section_name)
	}

	Sections()
	{
		return this.ini_data.ListSections()
	}


	class IniData {
		data := {}

		__New(ini_file = "")
		{
			if(ini_file)
			{
				this.LoadData(Ini.IniParser.Parse(ini_file))
			}
		}

		LoadData(data)
		{
			this.data := data
		}


		ListSections()
		{
			sections := []

			for key, value in this.data
			{
				sections.Push(key)
			}

			return sections
		}

		HasSection(section_name)
		{
			return this.data.HasKey(section_name)
		}

		CreateSection(section_name)
		{
			if !this.HasSection(section_name)
			{
				this.data[section_name] := {}
			}
		}

		GetSection(section_name)
		{
			if !this.HasSection(section_name)
			{
				return []
			}

			return this.data[section_name]
		}

		DeleteSection(section_name)
		{
			if this.HasSection(section_name)
			{
				this.data[section_name].Remove()
			}
		}



		ListValues(section_name)
		{
			values := []

			for key, value in this.GetSection(section_name)
			{
				values.Push(key)
			}

			return values
		}

		HasValue(value_name, section_name)
		{
			return ((this.HasSection(section_name)) and (this.data[section_name].HasKey(value_name)))
		}

		SetValue(value_name, value, section_name)
		{
			if (!this.HasSection(section_name))
			{
				this.CreateSection(section_name)
			}
			
			if (!this.data[section_name].HasKey(value_name))
			{
				this.data[section_name][value_name] := {"value": value, "comment": ""}
			}
			else
			{
				this.data[section_name][value_name].value := value
			}
		}

		GetValue(value_name, section_name)
		{
			return this.GetValueObj(value_name, section_name).value
		}

		GetValueObj(value_name, section_name)
		{
			if !this.HasValue(value_name, section_name)
			{
				this.SetValue(value_name, "", section_name)
			}

			return this.data[section_name][value_name]
		}

		DeleteValue(value_name, section_name)
		{
			if this.HasValue(value_name, section_name)
			{
				this.data[section_name][value_name].Remove()
			}
		}
		
		
		HasCommentValue(value_name, section_name)
		{
			if !this.HasValue(value_name, section_name)
			{
				return False
			}
			
			return this.data[section_name][value_name].comment != ""
		}
		
		GetCommentValue(value_name, section_name)
		{
			if !this.HasValue(value_name, section_name)
			{
				return ""
			}
			
			return this.data[section_name][value_name].comment
		}
		
		SetCommentValue(value_name, section_name, comment)
		{
			if !this.HasValue(value_name, section_name)
			{
				return False
			}
			
			this.data[section_name][value_name].comment := comment
		}
	}

	class IniParser {
		Parse(ini_file)
		{
			data := {}
			section_name := ""

			Loop, read, %ini_file%
			{
				; lines can be nothing but whitespace
				; we clean them up before processing any further
				line := Trim(A_LoopReadLine)
				
				if !line ; empty line - must ignore
				{
					Continue
				}

				parsed_line := InI.IniParser.ParseLine(line, section_name)

				if !parsed_line
				{
					continue
				}

				section_name := parsed_line.section

				if !data[section_name]
				{
					data[section_name] := {}
				}
				
				data[section_name] := InI.IniParser.ParsedLineIntoData(parsed_line, data[section_name])
			}

			return data
		}

		ParseFromString(ini_text)
		{
			data := {}
			section_name := ""

			Loop, parse, ini_text, `n, `r
			{
				; read Parse(ini_file)
				line := Trim(A_LoopField)
				
				if !line ; empty line - must ignore
				{
					Continue
				}

				parsed_line := InI.IniParser.ParseLine(line, section_name)

				if !parsed_line
				{
					continue
				}

				section_name := parsed_line.section

				if !data[section_name]
				{
					data[section_name] := {}
				}
				
				data[section_name] := InI.IniParser.ParsedLineIntoData(parsed_line, data[section_name])
			}

			return data
		}

		ParsedLineIntoData(parsed_line, data)
		{
			if !parsed_line.name
			{
				return {}
			}
			
			data[parsed_line.name] := {"value": parsed_line.value, "comment": parsed_line.comment}
			return data
		}

		ParseLine(ini_line, current_section_name)
		{
			char := SubStr(ini_line, 1, 1) ; WHAT THE FUCK? START INDEX AT 1?????
			
			; section identified - needs () because fuck you, that's why
			if (char == "[")
			{
				return InI.IniParser.ParseSection(ini_line)
			}
			; comment identified - handle adding it to the section or next value
			else if (char == "`;")
			{
				; TODO: implement proper comment handling
				return InI.IniParser.ParseComment(ini_line)
			}
			; otherwise, must be a value
			else
			{
				value_data := InI.IniParser.ParseValue(ini_line)
				
				if (value_data)
				{
					value_data.section := current_section_name
				}
				
				return value_data
			}
		}

		ParseSection(line)
		{
			section_data := {"section": "", "name": "", "value": "", "comment": ""}
			
			; ... you need to escape the ; because it will parse as a comment otherwise
			line_data := StrSplit(line, "`;", " `t", 2)
			
			; goal - trim the [] from the line
			section_data.section := Trim(line_data[1], " `t[]")
			
			; if a comment exists, add it to the data
			if (line_data[2])
			{
				comment := InI.IniParser.ParseComment(line_data[2])
				if (comment.comment)
				{
					section_data.comment := comment.comment
				}
			}
			
			return section_data
		}

		ParseValue(line)
		{
			value_data := {"section": "", "name": "", "value": "", "comment": ""}
			
			line_data := StrSplit(line, "`;", " `t", 2)
			
			; only want to split once, to preserve any values
			values := StrSplit(line_data[1], "=", " `t", 2)
			value_data.name := values[1]
			value_data.value := values[2]
			
			; if a comment exists, add it to the data
			if (line_data[2])
			{
				value_data.comment := Trim(line_data[2], " `t")
			}
			
			
			return value_data
		}

		ParseComment(line)
		{
			return {"section": "", "name": "", "value": "", "comment": LTrim(line, "; `t")}
		}
	}

	class IniWriter {
		Write(ini_file, ini_data)
		{
			Try
			{
				file := FileOpen(ini_file, "w")

				; everything without a section is to be stored at the top
				if ini_data.HasSection("")
				{
					file.Write(InI.IniWriter.MakeValues(ini_data.GetSection("")) . "`r`n")
				}

				for key, section_name in ini_data.ListSections()
				{
					; skips the "" section, since it was added before
					if !section_name
					{
						continue
					}

					section_data := ini_data.GetSection(section_name)
					if section_data
					{
						line := "[" . section_name . "]`r`n" . InI.IniWriter.MakeValues(section_data) . "`r`n"
						
						file.Write(line)
					}
				}

				file.Close()

				return True
			}
			catch e
			{
				return False
			}
		}

		MakeValues(data)
		{
			ini_text := ""

			for key, value in data
			{
				line := key . " = "  . (value.value)
				
				if (value.comment)
				{
					line .= " `; " . value.comment
				}
				
				ini_text .= line . "`r`n"
			}

			return ini_text
		}
	}
}

SaveSettings()
{
 global
	Loop %maxMembers%
	{
	 memberNamesVar .= memberNames[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 showNamesVar .= showNames[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 memberEnabledVar .= memberEnabled[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 translateEnabledVar .= translateEnabled[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 windowTitlesVar .= windowTitles[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 windowOriginalTitlesVar .= windowOriginalTitles[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 windowIDsVar .= windowIDs[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 windowMainIDsVar .= windowMainIDs[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 windowProcessIDsVar .= windowProcessIDs[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 windowControlsVar .= windowControls[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 windowControlPositionsVar .= windowControlPositions[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 windowControlsVerifiedVar .= windowControlsVerified[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 windowClickPosVar .= windowClickPos[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 windowCopyPosVar .= windowCopyPos[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	 windowCopyIDsVar .= windowCopyIDs[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	}

 iniFile.Set("memberNames", "Participant Windows", memberNamesVar)
 iniFile.Set("showNames", "Participant Windows", showNamesVar)
 iniFile.Set("memberEnabled", "Participant Windows", memberEnabledVar)
 iniFile.Set("translateEnabled", "Participant Windows", translateEnabledVar)
 iniFile.Set("windowTitles", "Participant Windows", windowTitlesVar)
 iniFile.Set("windowOriginalTitles", "Participant Windows", windowOriginalTitlesVar)
 iniFile.Set("windowIDs", "Participant Windows", windowIDsVar)
 iniFile.Set("windowMainIDs", "Participant Windows", windowMainIDsVar)
 iniFile.Set("windowProcessIDs", "Participant Windows", memberNamesVar)
 iniFile.Set("windowControls", "Participant Windows", windowControlsVar)
 iniFile.Set("windowControlPositions", "Participant Windows", windowControlPositionsVar)
 iniFile.Set("windowControlsVerified", "Participant Windows", windowControlsVerifiedVar)
 iniFile.Set("windowClickPos", "Participant Windows", windowClickPosVar)
 iniFile.Set("windowCopyPos", "Participant Windows", windowCopyPosVar)
 iniFile.Set("windowCopyIDs", "Participant Windows", windowCopyIDsVar)
 
 iniFile.Set("logFileTimestamps", "Options", logFileTimestamps)
 iniFile.Set("logFileEnabled", "Options", logFileEnabled)
 iniFile.Set("directory", "Options", directory)
 
 iniFile.Set("textInputWindow", "Options", textInputWindow)
 iniFile.Set("textInputWindowID", "Options", textInputWindowID)
 iniFile.Set("textInputControl", "Options", textInputControl)
 iniFile.Set("textInputControlPosition", "Options", textInputControlPosition)
 iniFile.Set("textInputControlVerified", "Options", textInputControlVerified)
 iniFile.Set("textInputClickPos", "Options", textInputClickPos)
 iniFile.Set("textInputPastePos", "Options", textInputPastePos)
 iniFile.Set("textInputPasteID", "Options", textInputPasteID)
 iniFile.Set("translationWindow", "Options", translationWindow)
 iniFile.Set("translationWindowID", "Options", translationWindowID)
 iniFile.Set("translationButton", "Options", translationButton)
 iniFile.Set("translationButtonClickPos", "Options", translationButtonClickPos)
 iniFile.Set("translationOutputWindow", "Options", translationOutputWindow)
 iniFile.Set("translationOutputWindowID", "Options", translationOutputWindowID)
 iniFile.Set("translationOutputControl", "Options", translationOutputControl)
 iniFile.Set("translationOutputControlPosition", "Options", translationOutputControlPosition)
 iniFile.Set("translationOutputControlVerified", "Options", translationOutputControlVerified)
 iniFile.Set("translationOutputClickPos", "Options", translationOutputClickPos)
 iniFile.Set("translationOutputCopyPos", "Options", translationOutputCopyPos)
 iniFile.Set("translationOutputCopyID", "Options", translationOutputCopyID)
 iniFile.Set("translationDisplayWindow", "Options", translationDisplayWindow)
 iniFile.Set("translationDisplayWindowID", "Options", translationDisplayWindowID)
 iniFile.Set("translationDisplayControl", "Options", translationDisplayControl)
 iniFile.Set("translationDisplayControlPosition", "Options", translationDisplayControlPosition)
 iniFile.Set("translationDisplayControlVerified", "Options", translationDisplayControlVerified)
 iniFile.Set("translationDisplayClickPos", "Options", translationDisplayClickPos)
 iniFile.Set("translationDisplayPastePos", "Options", translationDisplayPastePos)
 iniFile.Set("translationDisplayPasteID", "Options", translationDisplayPasteID)
 iniFile.Set("maxDisplayLines", "Options", maxDisplayLines)
 ;iniFile.Set("minCharactersPerLine", "Options", minCharactersPerLine)  NOT IN ACTIVE USE YET
 ;iniFile.Set("maxCharactersPerLine", "Options", maxCharactersPerLine)  NOT IN ACTIVE USE YET
 iniFile.Set("translationDelay", "Options", translationDelay)
 iniFile.Set("minDelayBetweenTextGrabAttempts", "Options", minDelayBetweenTextGrabAttempts)
 iniFile.Set("minDelayBeforeNewLine", "Options", minDelayBeforeNewLine)
 iniFile.Set("minDelayBeforeProcessingNewLine", "Options", minDelayBeforeProcessingNewLine)
 iniFile.Set("lineTimeout", "Options", lineTimeout)
 iniFile.Set("partialTranscriptions", "Options", partialTranscriptions)
 iniFile.Set("partialTranslations", "Options", partialTranslations)

 iniFile.Set("useDisplayFile", "Options", useDisplayFile)
 iniFile.Set("saveSettingsOnClose", "Options", saveSettingsOnClose)
 
 iniFile.Set("TransInputEdit", "Options", TransInputEdit)
 iniFile.Set("TransOutputEdit", "Options", TransOutputEdit)
 iniFile.Set("TransButtonEdit", "Options", TransButtonEdit)
 iniFile.Set("TransDisplayEdit", "Options", TransDisplayEdit)
 
 iniFile.Set("receivingMessages", "Network", receivingMessages)
 iniFile.Set("ReceiveIPAddress", "Network", ReceiveIPAddress)
 iniFile.Set("ReceivePort", "Network", ReceivePort)
 iniFile.Set("sendingMessages", "Network", sendingMessages)
 iniFile.Set("TransDisplayEdit", "Network", TransDisplayEdit)
 iniFile.Set("SendIPAddress", "Network", SendIPAddress)
 iniFile.Set("SendPort", "Network", SendPort)
 iniFile.Set("messageAddressEnabled", "Network", messageAddressEnabled)
 iniFile.Set("sendMessageAddress", "Network", sendMessageAddress)
 iniFile.Set("MessageAddress", "Network", MessageAddress)
 iniFile.Set("receivedMessageProcessingRate", "Network", receivedMessageProcessingRate)
 
 iniFile.Set("sendingDisplayContent", "Network", sendingDisplayContent)
 iniFile.Set("displayIPAddress", "Network", displayIPAddress)
 iniFile.Set("displayMessageAddressEnabled", "Network", displayMessageAddressEnabled)
 iniFile.Set("displayMessageAddress", "Network", displayMessageAddress)
 iniFile.Set("displayPort", "Network", displayPort)
 iniFile.Set("sendIndividualDisplayLines", "Network", sendIndividualDisplayLines)
 iniFile.Set("lineIDType", "Network", lineIDType)
 iniFile.Save()
 return
}

LoadSettings()
{
global
 showNames := StrSplit(iniFile.Get("showNames", "Participant Windows"), ",")
 memberEnabled := StrSplit(iniFile.Get("memberEnabled", "Participant Windows"), ",")
 translateEnabled := StrSplit(iniFile.Get("translateEnabled", "Participant Windows"), ",")
 windowTitles := StrSplit(iniFile.Get("windowTitles", "Participant Windows"), ",")
 windowOriginalTitles := StrSplit(iniFile.Get("windowOriginalTitles", "Participant Windows"), ",")
 windowIDs := StrSplit(iniFile.Get("windowIDs", "Participant Windows"), ",")
 windowMainIDs := StrSplit(iniFile.Get("windowMainIDs", "Participant Windows"), ",")
 memberNames := StrSplit(iniFile.Get("windowProcessIDs", "Participant Windows"), ",")
 windowControls := StrSplit(iniFile.Get("windowControls", "Participant Windows"), ",")
 windowControlPositions := StrSplit(iniFile.Get("windowControlPositions", "Participant Windows"), ",")
 windowControlsVerified := StrSplit(iniFile.Get("windowControlsVerified", "Participant Windows"), ",")
 windowClickPos := StrSplit(iniFile.Get("windowClickPos", "Participant Windows"), ",")
 windowCopyPos := StrSplit(iniFile.Get("windowCopyPos", "Participant Windows"), ",")
 windowCopyIDs := StrSplit(iniFile.Get("windowCopyIDs", "Participant Windows"), ",")
 
 GuiControl,, ShowNameCheck, % showNames[currentMember]
 GuiControl,, MemberEnabledCheck, % memberEnabled[currentMember]
 GuiControl,, TranslateEnabledCheck, % translateEnabled[currentMember]
 GuiControl,, NameEdit, % memberNames[currentMember]
 
 directory := iniFile.Get("directory", "Options", default_value = directory)
 logFileEnabled := iniFile.Get("logFileEnabled", "Options", default_value = logFileEnabled)
 logFileTimestamps := iniFile.Get("logFileTimestamps", "Options", default_value = logFileTimestamps)
 
 GuiControl,, FileEdit, % directory
 GuiControl,, FileEnabledCheck, % logFileEnabled
 GuiControl,, TimestampCheck, % logFileTimestamps

 textInputWindow := iniFile.Get("textInputWindow", "Options",  default_value = textInputWindow)
 textInputWindowID := iniFile.Get("textInputWindowID", "Options", default_value = textInputWindowID)
 textInputControl := iniFile.Get("textInputControl", "Options", default_value = textInputControl)
 textInputControlPosition := iniFile.Get("textInputControlPosition", "Options", default_value = textInputControlPosition)
 textInputControlVerified := iniFile.Get("textInputControlVerified", "Options", default_value = textInputControlVerified)
 textInputClickPos := iniFile.Get("textInputClickPos", "Options", default_value = textInputClickPos)
 textInputPastePos := iniFile.Get("textInputPastePos", "Options", default_value = textInputPastePos)
 textInputPasteID := iniFile.Get("textInputPasteID", "Options", default_value = textInputPasteID)
 translationWindow := iniFile.Get("translationWindow", "Options", default_value = translationWindow)
 translationWindowID := iniFile.Get("translationWindowID", "Options", default_value = translationWindowID)
 translationButton := iniFile.Get("translationButton", "Options", default_value = translationButton)
 translationButtonClickPos := iniFile.Get("translationButtonClickPos", "Options", default_value = ranslationButtonClickPos)
 translationOutputWindow := iniFile.Get("translationOutputWindow", "Options", default_value = translationOutputWindow)
 translationOutputWindowID := iniFile.Get("translationOutputWindowID", "Options", default_value = translationOutputWindowID)
 translationOutputControl := iniFile.Get("translationOutputControl", "Options", default_value = translationOutputControl)
 translationOutputControlPosition := iniFile.Get("translationOutputControlPosition", "Options", default_value = translationOutputControlPosition)
 translationOutputControlVerified := iniFile.Get("translationOutputControlVerified", "Options", default_value = translationOutputControlVerified)
 translationOutputClickPos := iniFile.Get("translationOutputClickPos", "Options", default_value = translationOutputClickPos)
 translationOutputCopyPos := iniFile.Get("translationOutputCopyPos", "Options", default_value = translationOutputCopyPos)
 translationOutputCopyID := iniFile.Get("translationOutputCopyID", "Options", default_value = translationOutputCopyID)
 translationDisplayWindow := iniFile.Get("translationDisplayWindow", "Options", default_value = translationDisplayWindow)
 translationDisplayWindowID := iniFile.Get("translationDisplayWindowID", "Options", default_value = translationDisplayWindowID)
 translationDisplayControl := iniFile.Get("translationDisplayControl", "Options", default_value = translationDisplayControl)
 translationDisplayControlPosition := iniFile.Get("translationDisplayControlPosition", "Options", default_value = translationDisplayControlPosition)
 translationDisplayControlVerified := iniFile.Get("translationDisplayControlVerified", "Options", default_value = translationDisplayControlVerified)
 translationDisplayClickPos := iniFile.Get("translationDisplayClickPos", "Options", default_value = translationDisplayClickPos)
 translationDisplayPastePos := iniFile.Get("translationDisplayPastePos", "Options", default_value = translationDisplayPastePos)
 translationDisplayPasteID := iniFile.Get("translationDisplayPasteID", "Options", default_value = translationDisplayPasteID)
 maxDisplayLines := iniFile.Get("maxDisplayLines", "Options", default_value = maxDisplayLines)
 ;minCharactersPerLine := iniFile.Get("minCharactersPerLine", "Options", minCharactersPerLine)  NOT IN ACTIVE USE YET
 ;maxCharactersPerLine := iniFile.Get("maxCharactersPerLine", "Options", maxCharactersPerLine)  NOT IN ACTIVE USE YET
 translationDelay := iniFile.Get("translationDelay", "Options", default_value = translationDelay)
 minDelayBetweenTextGrabAttempts := iniFile.Get("minDelayBetweenTextGrabAttempts", "Options", default_value = minDelayBetweenTextGrabAttempts)
 minDelayBeforeNewLine := iniFile.Get("minDelayBeforeNewLine", "Options", default_value = minDelayBeforeNewLine)
 minDelayBeforeProcessingNewLine := iniFile.Get("minDelayBeforeProcessingNewLine", "Options", default_value = minDelayBeforeProcessingNewLine)
 lineTimeout := iniFile.Get("lineTimeout", "Options", default_value = lineTimeout)
 partialTranscriptions := iniFile.Get("partialTranscriptions", "Options", default_value = partialTranscriptions)
 partialTranslations := iniFile.Get("partialTranslations", "Options", default_value = partialTranslations)
 sendMessageAddress := iniFile.Get("sendMessageAddress", "Options", default_value = default_value = sendMessageAddress)
 receivedMessageProcessingRate := iniFile.Get("receivedMessageProcessingRate", "Options", default_value = receivedMessageProcessingRate)
 useDisplayFile := iniFile.Get("useDisplayFile", "Options", default_value = useDisplayFile)
 saveSettingsOnClose := iniFile.Get("saveSettingsOnClose", "Options", default_value = saveSettingsOnClose)
 
 TransInputEdit := iniFile.Get("TransInputEdit", "Options", TransInputEdit)
 TransOutputEdit := iniFile.Get("TransOutputEdit", "Options", TransOutputEdit)
 TransButtonEdit := iniFile.Get("TransButtonEdit", "Options", TransButtonEdit)
 TransDisplayEdit := iniFile.Get("TransDisplayEdit", "Options", TransDisplayEdit)
 
 receivingMessages := iniFile.Get("receivingMessages", "Network", receivingMessages)
 ReceiveIPAddress := iniFile.Get("ReceiveIPAddress", "Network", ReceiveIPAddress)
 ReceivePort := iniFile.Get("ReceivePort", "Network", ReceivePort)
 sendingMessages := iniFile.Get("sendingMessages", "Network", sendingMessages)
 TransDisplayEdit := iniFile.Get("TransDisplayEdit", "Network", TransDisplayEdit)
 SendIPAddress := iniFile.Get("SendIPAddress", "Network", SendIPAddress)
 SendPort := iniFile.Get("SendPort", "Network", SendPort)
 messageAddressEnabled := iniFile.Get("messageAddressEnabled", "Network", messageAddressEnabled)
 sendMessageAddress:= iniFile.Get("sendMessageAddress", "Network", sendMessageAddress)
 receivedMessageProcessingRate := iniFile.Get("receivedMessageProcessingRate", "Network", receivedMessageProcessingRate)
 sendingDisplayContent := iniFile.Get("sendingDisplayContent", "Network", sendingDisplayContent)
 displayIPAddress := iniFile.Get("displayIPAddress", "Network", displayIPAddress)
 displayPort := iniFile.Get("displayPort", "Network", displayPort) 
 displayMessageAddressEnabled := iniFile.Get("displayMessageAddressEnabled", "Network", displayMessageAddressEnabled)
 displayMessageAddress := iniFile.Get("displayMessageAddress", "Network", displayMessageAddress)
 sendIndividualDisplayLines := iniFile.Get("sendIndividualDisplayLines", "Network", sendIndividualDisplayLines)
 lineIDType := iniFile.Get("lineIDType", "Network", lineIDType)
	if (receivingMessages = true)
	{
	 myUdpIn.bind(ReceiveIPAddress, ReceivePort)
	 myUdpIn.onRecv := Func("ReceiveMessageCallback")
	}
	if (sendingMessages = true)
	{
	 myUdpOut.connect(SendIPAddress, SendPort) 
	 myUdpOut.enableBroadcast()
	}
	if (sendingDisplayContent = true)
	{
	 mainUdpOut.connect(displayIPAddress, displayPort) 
	 mainUdpOut.enableBroadcast()
	}
 gui,submit,nohide ;updates gui variable
return
}

GuiClose:
{
 myUdpIn.disconnect()
 myUdpOut.disconnect()
 mainUdpOut.disconnect()
	if (saveSettingsOnClose = true)
	{
	 SaveSettings()
	}
	else if (FileExist(iniFileDir))
	{
	 iniFile.Set("saveSettingsOnClose", "Options", saveSettingsOnClose)
	 iniFile.Save()
	}
 ExitApp
return
}