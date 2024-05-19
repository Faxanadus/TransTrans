; TRANSCRIPTION/TRANSLATION FACILITATION APPLICATION
; DRAWS FROM TRANSCRIPTION APPS AND TRANSLATES THEIR CONTENT IN ANOTHER TRANSLATION APP, WITH SEVERAL DISPLAY OPTIONS FOR THE END OUTPUT
; REPOSITORY AND INSTRUCTIONS: https://github.com/Faxanadus/TransTrans
; TOOLTIPS ON MOUSE HOVER ALSO AVAILABLE
#SingleInstance Force
#NoEnv
SetBatchLines -1
CoordMode, Mouse, Screen
DetectHiddenWindows, On

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
minDelayBeforeNewLine := 4000 ;MILLISECONDS BEFORE A NEW LINE IS FORCED IN TRANSLATION DISPLAY
minDelayBeforeProcessingNewLine := 800 ;MILLISECONDS BEFORE THE SCRIPT WILL TRY TO START GRABBING NEW TEXT, TRANSCRIPTION MAY BE INACCURATE ON A NEW LINE IN THE FIRST SECOND
minLineDisplayTime := 2000 ; MINIMUM NUMBER OF MILLISECONDS A LINE WILL BE DISPLAYED BEFORE THE NEXT QUEUD LINE IS PUSHED TO currentLines DISPLAY
lineTimeout := 20000 ; MILLISECONDS BEFORE A LINE WILL BE REMOVED FROM DISPLAY, 0 = INFINITY
partialTranscriptions := true ; WHETHER PARTIALLY TRANSCRIBED SENTENCES WILL BE PUT IN THE DISPLAY AREA/FILE
partialTranslations := true ; DETERMINES WHETHER TRANSLATION OF TRANSCRIPTED TEXT WILL BE DONE IMMEDIATELY OR BEFORE THE FULL LINE IS DONE
useDisplayFile := true ; DETERMINES WHETHER DISPLAY FILE [AppName]DisplayLog.txt IS CREATED ON STARTUP, INTENDED TO BE USED WITH OTHER TEXT FILE PARSERS
saveSettingsOnClose := true
directory := A_ScriptDir ; DIRECTORY OF LOG FILE / DISPLAY FILE
logFileEnabled := false ; DETERMINES WHETHER A ONGOING TRANSCRIPTION/TRANSLATION LOG FILE WITH TODAYS DATE WILL BE CREATED AND MAINTAINED
logFileTimestamps := true
mainWindowPos := ""
debugWindowPos := ""
debugWindowOpen := false

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
windowElements := [] 
windowElementIDs := []

; MEMBER VARIABLES INTERNALLY AND NOT SAVED TO INI
previousTexts := [] ; PREVIOUS TEXT GRABBED FROM A WINDOW ON PREVIOUS LOOPS, USED TO COMPARE AGAINST newTexts
lastLines := [] ; LAST TRANSLATED LINE THAT WAS INTENDED FOR DISPLAY
transTexts := [] ; TEXT THAT WAS JUST GRABBED FROM THE TRANSLATOR
firstSamples := [] ; WHETHER THIS IS THE FIRST LINE FROM THE PARTICIPANT, PREVENTS VERY LARGE INITIAL INPUT ON THE FIRST LINE
lastControlStates := [] ; WHETHER THE CLICK METHOD (RATHER THAN CTRL-C) WAS USED ON THE LAST TEXT GRAB ATTEMPT OR ANOTHER WINDOW WAS SELECTED
lastLineTimes := []
windowControlTextTests := [] ; STORES RESULTS OF TESTS PERFORMED ON CONTROL AREAS TO DETERMINE IF TEXT CAN BE GRABBED/SET USING THOSE CONTROLS
lastLineIDs := [] ; DETERMINES POSITION OF THE USER'S LAST MESSAGE IN THE currentLines ARRAY SO MESSAGES CAN BE EDITED LATER
lastNetworkIDs := [] ; DETERMINES THE ID TO SENT TO ANOTHER APPLICATION FOR EACH MESSAGE
lastLineCompleted := [] ; WHETHER A FULL LINE WAS PUSHED TO THE DISPLAY AREA ON THE LAST LOOP FOR THIS USER
newLineDelayTimes := []
lastLoopStartTimes := []
newLineDetecteds := [] ; TRUE/FALSE OF WHETHER NEW TEXT HAS APPEARED FOR THE USER SINCE THE LAST COMPLETE LINE
lastLinePushTimes := [] ; THE LAST TIME A COMPLETED LINE FROM A USER WAS PUSHED TO DISPLAY
userLines := [] ; STORES ARRAYS OF CURRENT OF TRANSLATED/TRANSCRIBED TEXT LINES FOR EACH USER
userLineIds := []
currentUserLines :=[] ; ARRAY/QUEUE OF LINES FOR THE USER TO BE DISPLAYED
currentUserLineIds := []
firstWords := [] ; FIRST WORD DETECTED SINCE THE LAST PUSH TO DISPLAY, USED FOR ADDING PUNCTUATION
previousPartialTexts := [] ; PREVIOUS PARTIAL LINES GRABBED FROM A WINDOW ON PREVIOUS LOOPS, USED TO COMPARE AGAINST newPartialText, BY LINE LENGTH INSTEAD OF CONTENT (CONTENT MAY CHANGE SUDENLY BETWEEN LOOPS)
partialLineIndicators := [] ; INDICATES WHICH PARTIAL LINE TO DISPLAY NEXT
userPartialLines := [] ; STORES ARRAYS OF CURRENT OF PARTIALLY TRANSLATEd/TRANSCRIBED TEXT LINES FOR EACH USER
userPartialLinesIds := []
partialLineMaxLengths := []
currentUserPartialLines := [] ; ARRAY/QUEUE OF PARTIALLY TRANSCRIBED LINES FOR THE USER TO BE DISPLAYED
currentUserPartialLineIDs := []
lastLinesPartials := [] ; WHETHER THE LAST LOOP HAD PARTIAL LINES FOR EACH USER

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
lastLineMemberID := 0 ; DETERMINES WHETHER TO DISPLAY THE USERS NAME ON SUBSEQUENT LINES FROM THE SAME USER
currentLines := [] ; LINES OF TEXT THE SCRIPT IS KEEPING TRACK OF FOR FINAL DISPLAY AND/OR LOG FILE INSERTION
currentLinesTimes := [] ; TIME WHEN THE LINE WAS ENTERED IN FOR DISPLAY
currentLineIds := [] ; UNIQUE IDS FOR LINES THAT MAY NEED TO BE UPDATED WHILE BEING DISPLAYED
networkLineIDs := [] ; ADDED TO PARTIAL/FULL LINES/PACKETS WHEN SENT OVER THE NETWORK TO HELP THE RECEIVING APP KNOW IF THERE IS A LINE TO UPDATE

global UIA := UIA_Interface() ; UIA is used as an alternate method for grabbing text, Credit to Descolada @ https://github.com/Descolada/UIAutomation
running := false
inLoop := false
inLineTimeoutLoop := false
debug :=
appSetupDisplay :=
advancedOptionsDisplay :=
networkDisplay :=
scriptPID := DllCall("GetCurrentProcessId")
textInputControlTextTest := "" ; USED TO VERIFY CONTROL AREAS AS WORKING
translationOutputTextTest := ""
translationDisplayTextTest := ""
debugWindowID := ""

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
currentLineID := 0 ; USED TO IDENIFY UNIQUE USER LINES
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
currentLanguage := GetOSLanguage()

	Loop %maxMembers%
	{
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
	 windowElements.Push("")
	 windowElementIDs.Push("")
	 firstSamples.Push(1)
	 lastControlStates.Push(0)
	 previousTexts.Push("")
	 lastLines.Push("")
	 transTexts.Push("")
	 lastLineTimes.Push(0)
	 lastLineIDs.Push(0)
	 lastNetworkIDs.Push(0)
	 lastLineCompleted.Push(0)
	 newLineDelayTimes.Push(minDelayBeforeProcessingNewLine)
	 newLineDetecteds.Push(0)
	 lastLoopStartTimes.Push(0)
	 lastLinePushTimes.Push(0)
	 userLines.Push(currentUserLines)
	 firstWords.Push("")
	 previousPartialTexts.Push("")
	 partialLineIndicators.Push(1)
	 userPartialLines.Push(currentUserPartialLines)
	 userLineIds.Push(currentUserLineIds)
	 userPartialLinesIds.Push(currentUserPartialLineIDs) 
	 lastLinesPartials.Push(0)
	 partialLineMaxLengths.Push(maxCharactersPerLine)
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
MemberEdit_TTEs := "Número de participante actual, se pueden habilitar hasta 9 participantes con diferentes fuentes de transcripción."

Gui, Add, CheckBox, x55 y24 gMemberEnabledCheck vMemberEnabledCheck Checked1, Transcribe
MemberEnabledCheck_TT := "If checked, this member's transcribed text can be displayed or logged."
MemberEnabledCheck_TTEs := "Si está marcado, el texto transcrito de este miembro se puede mostrar o registrar."

Gui, Add, CheckBox, x55 y42 gTranslateEnabledCheck vTranslateEnabledCheck Checked1, Translate
TranslateEnabledCheck_TT := "If checked, this member's translated text can be displayed or logged."
TranslateEnabledCheck_TTEs := "Si está marcado, el texto traducido de este miembro se puede mostrar o registrar."

Gui, Add, Button, x158 y10 w72 h18 gShowAppSetupButton, App Setup >>
Gui, Add, Button, x158 y31 w72 h18 gShowAdvSetupButton, Options  >>
Gui, Add, Button, x158 y52 w72 h18 gNetwork, Network >>

Gui,Font, BOLD
Gui, Add, CheckBox, x10 y60 gShowNameCheck vShowNameCheck Checked1, Name:
ShowNameCheck_TT := "If checked, this member's name will be shown along with displayed text."
ShowNameCheck_TTEs := "Si está marcado, el nombre de este miembro se mostrará junto con el texto mostrado."

Gui,Font
Gui, Add, Edit, r1 gNameCheck vNameEdit w220, Faxanadus

Gui,Font, BOLD
Gui, Add, Text, x10 y106 , Text Output Area for this Participant:
Gui,Font
Gui, Add, Edit, r1 vWindowEdit w220 +ReadOnly, Text output area not set.
Gui, Add, Button, vWindowGetButton gWindowGetButton, Set Participant Output Area
WindowGetButton_TT := "Click on this button to choose where this participant's output text source is located."
WindowGetButton_TTEs := "Haga clic en este botón para elegir dónde se encuentra la fuente del texto de salida de este participante."

Gui,Font, BOLD
Gui, Add, Text,x10 y176, Save Transcription to File:
Gui,Font
Gui, Add, CheckBox, x167 y176 gFileEnabledCheck vFileEnabledCheck Checked0, Enabled
FileEnabledCheck_TT := "If checked, a transcription log text file will be created and updated in the selected directory below.`nThis is separate from TransDisplayLog.txt display file (created in this script's directory on startup)."
FileEnabledCheck_TTEs := "Si está marcada, se creará y actualizará un archivo de texto de registro de transcripción en el directorio seleccionado a continuación.`nEsto es independiente del archivo de visualización TransDisplayLog.txt (creado en el directorio de este script al inicio)."

Gui, Add, Edit, x10 y194 r1 vFileEdit w220 +ReadOnly, Default Set: Saved in this script's directory.
Gui, Add, Button, x10 y220 w50  vBrowseButton gBrowseButton,  Browse
Gui, Add, CheckBox, x155 y221 gTimestampCheck vTimestampCheck Checked1, Timestamps
TimestampCheck_TT := "If checked, timestamps will be added to the transcription log saved in the above directory`n(separate from TransDisplayLog.txt display file created in this script's directory on startup)."
TimestampCheck_TTEs := "Si está marcada, las marcas de tiempo se agregarán al registro de transcripción guardado en el directorio anterior`n(separado del archivo de visualización TransDisplayLog.txt creado en el directorio de este script al inicio)."
GUIControl, Hide, TimestampCheck

Gui,Font, BOLD
Gui, Add, Text, x69 y242 w120 vActiveText, Status: Not Active
Gui,Font
Gui, Add, Button, x65 y260 w50 gStartButton, START
Gui, Add, Button, x120 y260 w50 gStopButton, STOP
Gui, Add, Button, x10 y264 gDebug,Debug

; Credit to ismael-miguel for the ahk ini library, used to save settings: https://github.com/ismael-miguel/AHK-ini-parser
scriptName := SubStr(A_ScriptName, 1, StrLen(A_ScriptName) - 4)
iniFileDir := directory "\" scriptName "-Config.ini"
global iniFile := new ini(iniFileDir) 
	if (FileExist(iniFileDir))
	{
	 LoadSettings()
	}
Gui, Show, %mainWindowPos% w240 h286, Trans/Trans
displayFile := directory "\" scriptName "-DisplayLog.txt"
	if (useDisplayFile = true) 
	{
		if (FileExist(displayFile))
		{
		 FileDelete, % displayFile
		}
	 FileAppend,, %displayFile%, UTF-8
	}
OnMessage(0x200, "WM_MOUSEMOVE") ; USED FOR TOOLTIP MOUSE HOVER DETECTION
	if (debugWindowOpen = true)
	{
	 Goto, Debug
	}
return ; END OF STARTUP

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
 previousTransText := "" ; LAST LINE THE APP GRABBED FROM THE TRANSLATOR
 previousClipboard := "" ; THE APPS'S CLIPBOARD
 previousMessageID := "" ; USED TO IDENTIFY UNIQUE MESSAGES WHEN SENDING/RECEIVING STRINGS OVER NETWORK
 SetTimer, LineTimeoutLoop, Off
 inLineTimeoutLoop := false
 
 ; MAIN LOOP START-------------------------------------------------------------------------------------------------------------------------------------------------
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
	 lastLoopStartTimes[loopMember] := A_TickCount
	 delay := minDelayBetweenTextGrabAttempts / activeMembers
	 Sleep, % delay
		if (running = false)
		{
		 return
		}
	 inLoop := true
	 LineTimeoutCheck()
	 memberID := loopMember
	 memberName := memberNames[loopMember]
	 lastLine := lastLines[loopMember]
	 lastLineTime := lastLineTimes[loopMember]
	 firstSample := firstSamples[loopMember]
	 currentTitle := windowTitles[loopMember]
	 currentID := windowIDs[loopMember]
	 currentPID := windowProcessIDs[loopMember]
	 currentMainID := windowMainIDs[loopMember]
	 clickPos := windowClickPos[loopMember]
	 copyPos := windowCopyPos[loopMember]
	 copyID := windowCopyIDs[loopMember]
	 previousText := previousTexts[loopMember]
	 transText := transTexts[loopMember]
	 lastControlState := lastControlStates[loopMember]
	 lastLineID := lastLineIds[loopMember]
	 lastNetworkID := lastNetworkIDs[loopMember]
	 lastLineComplete := lastLineCompleted[loopMember]
	 newLineDelayTime := newLineDelayTimes[loopMember]
	 loopStartTime := lastLoopStartTimes[loopMember]
	 newLineDetected := newLineDetecteds[loopMember]
	 windowControl := windowControls[loopMember]
	 windowControlPosition := windowControlPositions[loopMember]
	 windowControlVerified := windowControlsVerified[loopMember]
	 windowControlTestText := windowControlTextTests[loopMember]
	 windowElement := windowElements[loopMember]
	 lastLinePushTime := lastLinePushTimes[loopMember]
	 currentUserLines := userLines[loopMember]
	 firstWord := firstWords[loopMember]
	 previousPartialText := previousPartialTexts[loopMember]
	 partialLineIndicator := partialLineIndicators[loopMember]
	 currentUserPartialLines := userPartialLines[loopMember]
	 currentUserLineIds := userLineIds[loopMember]
	 currentUserPartialLineIDs := userPartialLinesIds[loopMember]
	 lastLinesPartial := lastLinesPartials[loopMember]
	 partialLineMaxLength := partialLineMaxLengths[loopMember]
	 
		if (debug)
		{
		 GuiControl, debugWindow:, CurentLoopText, Member Loop: %loopMember%  Last Line ID: %lastLineID%
		}
	 newText := GrabText(windowElement, windowControl, windowControlPosition, currentTitle, currentID, windowControlVerified, windowControlTestText, loopMember, clickPos, copyPos, copyID, false, false, false)		 		
		if (running = false)
		{
		 return
		}	 
			 
		if (previousText = savedClipboard)
		{ ; RESET EVERYTHING
		 firstSample := true
		 previousText := ""
		 transText := ""
		 lastControlState := true
		 lastLineTime := A_TickCount
		 Goto, EndLoop
		}
		else if (newText = savedClipboard)
		{
		 lastControlState := true
		 lastLineTime := A_TickCount
		 Goto, EndLoop
		}
		
	 newTextTest := RegexReplace(newText, "^\s+") ;trim beginning whitespace
		if (newTextTest = "")
		{ ;DON'T BOTHER PROCESSING TEXT THAT'S JUST A SPACE OR IS NOTHING
		 lastControlState := true
		 lastLineTime := A_TickCount
		 Goto, EndLoop
		}
			
	 currentNameLength := 0
		if (showNames[loopMember] = true) && ((lastLineMemberID != memberID) || ((lastLineID) > 0 && (InStr(lastLine, memberName))))
		{ ; INCLUDES THE ': ' AFTER THE USER'S NAME
		 currentNameLength := StrLen(memberName) + 2
		 partialLineMaxLength := maxCharactersPerLine - currentNameLength
		}
	 maxLength := maxCharactersPerLine - currentNameLength	
	 newLine := ""
	 newPartialText := ""
	 thisUserLine := ""
	 thisUserLineID := 0
	 currentLinesPartial := false
	 	if (debug)
		{
		 GuiControl, debugWindow:, NewTextEdit, % newText
		}
	 FoundPos := InStr(newText, "    >>")
		if (FoundPos > 0)
		{ ;DISREGARD "     >>" IN CAPTION PREVIEW, AS IT JUST INDICATES THE BARRIER BETWEEN FINISHED TEXT AND TEXT IN PROCESS
			if (partialTranscriptions = true)
			{
			 newPartialText := SubStr(newText, FoundPos + 6, StrLen(newText))
			 newPartialText := RegexReplace(newPartialText, "\s+$") ;trim ending whitespace
			}
		 newText := SubStr(newText, 1, FoundPos)
		 newText := RegexReplace(newText, "\s+$") ;trim ending whitespace
		}

	
		if (StrLen(newText) > 2)
		{ ; BEGIN COMPARING PREVIOUS RECEIVED TEXT TO THE NEW TEXT
		 FoundPos := InStr(newText, previousText)
			if (FoundPos > 0)
			{
			 startPos := FoundPos + StrLen(previousText)
			 endPos := StrLen(newText)
			 newLine := SubStr(newText, startPos, endPos)
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
			}

			if (firstSample = true)
			{ ;PREVENTS THE FIRST FOUND TEXT FROM BEING A GIGANTIC WALL OF TEXT
			 previousText := newText
			 firstSample = false
				if (debug)
				{
				 GuiControl, debugWindow:, PrevTextEdit, % previousText
				}	 
				if (translationOutputControl != "") && (translationOutputWindow != "")
				{ ; CLEARS THE TRANSLATION OUTPUT THE FIRST TIME TO PREVENT GRABBING EXISTING CONTENT
				 ControlSetText, %translationOutputControl%,, %translationOutputWindow%
				}
			 Goto, EndLoop
			}
			else if (newLineDetected = true) && (newLineDelayTime > 0)
			{
			 deltaTime := A_TickCount - loopStartTime
			 newLineDelayTime -= deltaTime
				if (debug)
				{
				 GuiControl, debugWindow:, NewLineDebugText, % "New Line: (Delay:" newLineDelayTime "ms)"
				}
				if (newLineDelayTime > 0)
				{
				 Goto, EndLoop
				}
			}
			else if (((StrLen(newLine) > maxCharactersPerLine) && (A_TickCount - lastLineTime < minDelayBeforeProcessingNewLine)))
			{ ; PREVENTS TEXT SPAM FROM BAD GRAB OR COMPARISON ATTEMPTS
			 Goto, EndLoop
			}
		}
		
		if (StrLen(newLine) > 2)
		{
		 lastLineLength := 0
		 firstRetrievedLineMaxLength := 0
			if (lastLineComplete = false)
			{
			 lastLineLength := StrLen(currentUserLines[currentUserLines.MaxIndex()])
			 firstRetrievedLineMaxLength := maxLength - lastLineLength
			}
		 newLines := SplitString(newLine, maxLength, firstRetrievedLineMaxLength)
		 previousUserPartialLines := SplitString(previousPartialText, maxLength, firstRetrievedLineMaxLength)
		 partialTextUpdated := false
			if (previousUserPartialLines.MaxIndex() > 0) && (previousUserPartialLines[1] != "")
			{ ; NEW TEXT TAKES PRECEDENCE OVER PARTIAL TEXT
			 lineDifference := 0
			 maxNewLines := Floor(newLines.MaxIndex())
			 maxPrevLines := Floor(previousUserPartialLines.MaxIndex())
			 
				if (maxNewLines = maxPrevLines) && (lastLineID > 0)
				{ ; ALWAYS UPDATE THE LAST LINE FROM PARTIAL TEXT
				  lineDifference := maxNewLines - 1
					Loop, % lineDifference
					{ ; REMOVE LINES THAT HAVE ALREADY BEEN DISPLAYED BY PARTIAL TEXT
					 newLines.RemoveAt(1)
					}
				}
				else
				{
				 lineDifference := maxNewLines - maxPrevLines
					Loop, % maxNewLines - lineDifference
					{ ; REMOVE LINES THAT HAVE ALREADY BEEN DISPLAYED BY PARTIAL TEXT
					 newLines.RemoveAt(1)
					}
					if (lastLineID > 0)
					{
					 newLines[newLines.MaxIndex()] := previousUserPartialLines[previousUserPartialLines.MaxIndex()] . " " . newLines[newLines.MaxIndex()]
					 partialTextUpdated := true
					}
					else
					{
					 lastLinesPartial := false
					}
				}

				if (SubStr(lastLine, StrLen(lastLine)) = ".") || ((SubStr(lastLine, StrLen(lastLine)) != ".") && (SubStr(newLines[1], StrLen(newLines[1])) = "."))
				{ ; CAPITALIZE FIRST LETTER
				 newLines[1] := RegExReplace(newLines[1], "^(\s*)(.)", "$1$u2")
				}
			 previousPartialText := ""
			 partialLineMaxLength := maxCharactersPerLine
			}		 
			if (partialTextUpdated = false) && (currentUserLines.MaxIndex() > 0) && (currentUserLines[1] != "") && (lastLineLength + StrLen(newLines[1]) < maxLength)
			{ ; UPDATE CURRENT LINE
			 currentUserLines[currentUserLines.MaxIndex()] := currentUserLines[currentUserLines.MaxIndex()] . newLines[1]
			 newLines.RemoveAt(1)
			}
			Loop, % newLines.MaxIndex()
			{ ; ADD NEW LINES
			 currentUserLines.Push(newLines[A_Index])
			}
		 partialLineIndicator := 1
		 currentUserPartialLineIDs := []
		 currentUserPartialLines := []
		 previousText := newText
			if (debug) && (currentUserLines.MaxIndex() > 0)
			{
			 GuiControl, debugWindow:, PrevTextEdit, % previousText
			 newLineText := ""
				Loop, % currentUserLines.MaxIndex()
				{
				 newLineText := newLineText . currentUserLines[A_Index] . "`n"
				}
				if (newLineText != "")
				{
				 GuiControl, debugWindow:, NewLineEdit, % newLineText
				}
			}
		}
		
		if (currentUserLines.MaxIndex() > 0)
		{
			if (currentUserLines[1] = "")
			{
			 currentUserLines.RemoveAt(1)
			}
		 thisUserLine := currentUserLines[1]
		 thisUserLineID := currentUserLineIDs[1]
		}
		if (partialTranscriptions = true) && (currentUserLines.MaxIndex() <= 0) && (newPartialText != "")
		{
		 currentLinesPartial := true ; PARTIAL TEXT IS REPLACED BY NEW TEXT, AND WILL ONLY BE DISPLAYED WHEN ALL NEW TEXT HAS BEEN DISPLAYED FOR minLineDisplayTime		
		 currentUserPartialLines := SplitString(newPartialText, partialLineMaxLength, 0)
		 thisUserLine := currentUserPartialLines[partialLineIndicator]
		 thisUserLineID := currentUserPartialLineIDs[partialLineIndicator]
			if (debug)
			{
			 GuiControl, debugWindow:, PartialTextEdit, % thisUserLine
			}
		}

		if ((lastLineID > 0) || (currentLines.MaxIndex() < maxDisplayLines) || (A_TickCount - lastLinePushTime > minLineDisplayTime))
		{ ;PASTE THE NEW LINE OF TEXT IN THE TRANSLATOR OR OUTPUT AREA
			if ((StrLen(thisUserLine) > 2)
			&& ((currentLinesPartial = false) && ((StrLen(thisUserLine) > maxLength - 10) || (InStr(thisUserLine, ".")) || (A_Tickcount - lastLineTime > minDelayBeforeNewLine)))
			|| ((currentUserPartialLines.MaxIndex() > 1) && (partialLineIndicator < currentUserPartialLines.MaxIndex())))
			{ ; FINALIZE THE LINE
			 thisUserLine := RegexReplace(thisUserLine, "^\s+") ;trim beginning whitespace
				if (currentLinesPartial = false)
				{
					if (lastLinesPartial = false)
					{
					 thisUserLine := RegExReplace(thisUserLine, "^\w|(?:\.|:)\s+\K\w", "$U0") ; AUTO CAPITALIZE FIRST LETTER AFTER PUNCTUATION
					 thisUserLine := AddPunctuation(thisUserLine, firstWord) ; ADDS QUESTION MARKS OR PERIODS WHEN NEEDED
					 firstWord := ""
					}
					if (SubStr(lastLine, StrLen(lastLine)) = ".") || ((SubStr(lastLine, StrLen(lastLine)) != ".") && (SubStr(thisUserLine, StrLen(thisUserLine)) = "."))
					{
					 thisUserLine := RegExReplace(thisUserLine, "^(\s*)(.)", "$1$u2")
					 wordSplit := StrSplit(thisUserLine, [",", A_Space],, 1)
					 firstWord :=  wordSplit[1]
					}
					else
					{
					 firstWord := ""
					}
				 currentUserLines.RemoveAt(1)
				}
				else
				{
					if (partialLineIndicator = 1) || (InStr(lastLine, "."))
					{
					 wordSplit := StrSplit(thisUserLine, [",", A_Space],, 1)
					 firstWord :=  wordSplit[1]
					 thisUserLine := RegExReplace(thisUserLine, "^\w|(?:\.|:)\s+\K\w", "$U0") ; AUTO CAPITALIZE FIRST LETTER AFTER PUNCTUATION
					}
				 partialLineIndicator += 1
				}
			 lineComplete := true
			}
			else if (newLineDetected = false) && (newLineDelayTime > 0)
			{
			 newLineDetected := true
			 	if (debug)
				{
				 GuiControl, debugWindow:, NewLineDebugText, % "New Line: (Delay:" newLineDelayTime "ms)"
				}
			 Goto, EndLoop
			} 		
			else if (currentLinesPartial && partialLineIndicator = 1)
			{ ; CAPITALIZE FIRST LETTER
			 thisUserLine := RegExReplace(thisUserLine, "^(\s*)(.)", "$1$u2")
			}
			
			if (debug)
			{
			 GuiControl, debugWindow:, DisplayLineEdit, % thisUserLine
			}	 
				
			if (StrLen(thisUserLine) > 2) || (lineComplete = true)
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
				 SetText(textInputControl, textInputControlPosition, textInputWindow, textInputWindowID, textInputControlVerified, 1, thisUserLine, textInputClickPos, textInputPastePos, textInputPasteID, true, false, true)
				 PushButton:
				 PushTranslateButton()
					if ((translationOutputControl != "") || (translationOutputControlPosition != "")) && ((translationOutputWindow != "") || (translationOutputWindowID != ""))
					{
					 Sleep, %translationDelay%
					 transText := GrabText("", translationOutputControl, translationOutputControlPosition, translationOutputWindow, translationOutputWindowId, translationOutputControlVerified, translationOutputTextTest, 10, translationOutputClickPos, translationOutputCopyPos, translationOutputCopyID, true, false, true)
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
				 transText := RemoveExtraInformation(thisUserLine, transText)
				}
				
				if (firstTranslation = true) && (transText != "")
				{
				 firstTranslation := false
				}
				
				if (memberEnabled[loopMember] = true) && (translateEnabled[loopMember] = true)
				{
				 finalText := thisUserLine "`n" transText
				}
				else if (translateEnabled[loopMember] = true) && (transText != "")
				{
				 finalText := transText
				}
				else
				{
				 finalText := thisUserLine
				}
				
				if (showNames[loopMember] = true) && ((lastLineMemberID != memberID) || ((lastLineID) > 0 && (InStr(lastLine, memberName))))
				{
				 finalText := memberName ": " finalText
				}
					
				if (currentLinesPartial)
				{
				 previousPartialText := newPartialText
				 lastLinesPartial := true
				 	if (debug)
					{
					 GuiControl, debugWindow:, PreviousPartialTextEdit, % previousPartialText
					}	 
				}
				else
				{
				 lastLinesPartial := false
				}
				
				if (lastLineID > 0)
				{ ;MODIFY THE CURRENT LINE FOR THE USER IF IT EXISTS
				 currentLines[lastLineID] := finalText
				 currentLinesTimes[lastLineID] := A_TickCount
				}
				else 
				{ ; ADD THE A NEW LINE TO THE ARRAY
				 currentLines.Push(finalText)
				 currentLineIds.Push(thisUserLineID)
				 currentLinesTimes.Push(A_TickCount)
				 lastLineID := currentLines.MaxIndex()
				 lastLineMemberID := memberID
				 lastLinePushTime := A_TickCount + (minLineDisplayTime * (StrLen(thisUserLine) / maxCharactersPerLine))
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
			 lastLine := finalText
			 lastLineComplete := false
				if (lineComplete = true)
				{ ; REMOVE THE LAST LINE FROM THE CURRENT LINES ARRAY, LAST LINE IS THE FIRST INDEX DUE TO HOW MESSAGES ARE DISPLAYED IN ORDER
				 lastLineComplete := true
				 lineComplete := false
				 lastLineID := 0
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
						 currentLineIds.RemoveAt(1)
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
				 lastLineTime := A_TickCount
				 newLineDetected := false
					if (currentLinesPartial = false)
					{
					 newLineDelayTime := minDelayBeforeProcessingNewLine
					}
				}
			 UpdateDisplay() ; WRITES ALL THE LINES TO THE DisplayLog.txt FILE (CREATED ON STARTUP IN THE SCRIPT'S DIRECTORY) FOR USE IN DISPLAY IN TEXT READER APPLICATIONS, SUCH AS AN OBS Text (GDI+) SOURCE
			}
		}
	 EndLoop:
	 previousTexts[loopMember] := previousText
	 lastLines[loopMember] := lastLine
	 transTexts[loopMember] := transText
	 firstSamples[loopMember] := firstSample
	 lastControlStates[loopMember] := lastControlState
	 lastLineTimes[loopMember] := lastLineTime
	 lastLineIDs[loopMember] := lastLineID
	 lastNetworkIDs[loopMember] := lastNetworkID
	 lastLineCompleted[loopMember] := lastLineComplete
	 newLineDelayTimes[loopMember] := newLineDelayTime
	 lastLoopStartTimes[loopMember] := loopStartTime
	 newLineDetecteds[loopMember] := newLineDetected
	 windowControlsVerified[loopMember] := windowControlVerified
	 windowControlTextTests[loopMember] := windowControlTestText
	 userLinesPartial[loopMember] := currentUserLinesPartial 
	 lastLinePushTimes[loopMember] := lastLinePushTime 
	 userLines[loopMember]:= currentUserLines
	 firstWords[loopMember] := firstWord
	 lastLinesPartials[loopMember] := lastLinesPartial
	 partialLineMaxLengths[loopMember] := partialLineMaxLength
		if (partialTranscriptions = true)
		{
		 previousPartialTexts[loopMember] := previousPartialText
		 partialLineIndicators[loopMember] := partialLineIndicator 
		 userPartialLines[loopMember] := currentUserPartialLines
		 userLineIds[loopMember] := currentUserLineIds
		 userPartialLinesIds[loopMember] := currentUserPartialLineIDs
		}
		else
		{
		 previousPartialTexts[loopMember] := ""
		 partialLineIndicators[loopMember] := "" 
		 userPartialLines[loopMember] := ""
		 userLineIds[loopMember] := ""
		 userPartialLinesIds[loopMember] := ""
		}
	 inLoop := false
		if (running = false)
		{
		 return
		}
	}
inLoop := false
return
}

ResetAll()
{
 global
 lastLineMemberID := 0
 currentUserLines := []
 currentUserPartialLines := []
 currentUserLineIds := []
 currentUserPartialLineIDs := []
 
	Loop, %maxMembers%
	{ ; RESET MEMBER VARIABLES
	 firstSamples[A_Index] := 1
	 lastControlStates[A_Index] := 0
	 previousTexts[A_Index] := ""
	 lastLines[A_Index] := ""
	 transTexts[A_Index] := ""
	 lastLineTimes[A_Index] := 0
	 lastLineCompleted[A_Index] := 0
	 lastLineIDs[A_Index] := 0 
	 lastNetworkIDs[A_Index] := 0
	 newLineDelayTimes[A_Index] := minDelayBeforeProcessingNewLine
	 lastLoopStartTimes[loopMember] := 0
	 newLineDetected[A_Index] := 0
	 userLinesPartial[A_Index] := 0
	 lastLinePushTimes[A_Index] := 0
	 previousPartialTexts[A_Index] := ""
	 partialLineIndicators[A_Index] := 1
	 userLines[A_Index] := currentUserLines
	 userLineIds[A_Index] := currentUserLineIds
	 userPartialLines[A_Index] := currentUserPartialLines
	 userPartialLinesIds[A_Index] := currentUserPartialLineIDs
	 firstWords[loopMember] := ""
	 lastLinesPartials[loopMember] := 0
	 partialLineMaxLengths[loopMember] := maxCharactersPerLine
	}
 return
}

StopButton:
{
Critical, On
running := false
GuiControl, Move, ActiveText, x69 y242 w120 
GuiControl, Text, ActiveText, Status: Not Active
Hotkey, $~LButton, off
Hotkey, ESC, off
ResetCurrentCursor()
ToggleEditFields(true)
OnMessage(0x200, "WM_MOUSEMOVE") ; RE-ENABLE TOOLTIPS
	if (inLineTimeoutLoop = false)
	{
	 SetTimer, LineTimeoutLoop, 1000
	}
 Critical, Off
return
}

SplitString(newContent, maxLength, firstLineMaxLength)
{
 splitContent := []
	if (StrLen(newContent) > maxLength)
	{ ; SPLIT THE NEW CONTENT UP INTO LINES, PUSH TO USER ARRAYS 
	 halfMaxLength := Floor(maxLength / 2)
	 contentLength := StrLen(newContent)
	 breakPoints := FindPunctuation(newContent)
	 longestSection := 0
		Loop, % breakPoints.MaxIndex() - 1
		{
		 sectionLength := breakPoints[A_Index + 1] - breakPoints[A_Index]
			if (sectionLength > longestSection)
			{
			 longestSection := sectionLength
			}
		}
		if (longestSection > halfMaxLength) || ((firstLineMaxLength > 0) && (longestSection > firstLineMaxLength))
		{
			Loop, % contentLength
			{ ; IF SPLIT BASED ON DELIMITERS FAILED, ATTEMPT SPLIT BY CHARACTER DECIMAL VALUE DIFFERENCE
			 pos := A_Index
			 char := SubStr(newContent, pos, 1)
			 charNext := SubStr(newContent, pos + 1, 1)
			 charRange1 := GetCharRange(char)
			 charRange2 := GetCharRange(charNext)
				if ((charRange1 != 4) && (charRange2 = 4)) ; NOT KANJI -> KANJI
				|| ((charRange2 != 4) && (charRange1 != 4) && (charRange1 != charRange2)) ; NOT KANJI -> DIFFERENT ALPHABET
				{ ; LOOK FOR SIGNIFICANTLY DIFFERENT CHARACTERS, OR FROM SEPARATE ALPHABETS
				 insertionPoint := 1
					Loop, % breakPoints.MaxIndex() - 1
					{
					 bp := breakPoints[A_Index]
					 bp2 := breakPoints[A_Index + 1]
						if (bp = bp2)
						{
						 break
						}
						else if (pos > bp) && (pos < bp2)
						{
						 insertionPoint := A_Index + 1
						 breakPoints.InsertAt(insertionPoint, pos)
						 break
						}
					}
				}
			}
		}
		while (StrLen(newContent) > 0)
		{
		 currentMaxLength := maxLength
			if (firstLineMaxLength > 0)
			{
			 currentMaxLength := firstLineMaxLength
			 firstLineMaxLength := 0
			}
			
			if (StrLen(newContent) > currentMaxLength)
			{
				if (breakPoints.MaxIndex() > 0)
				{
					Loop, % breakPoints.MaxIndex()
					{
					 b := A_Index
						if (breakPoints[b] > maxLength)
						{ ; COULD NOT FIND A GOOD STRING ENDPOINT, ARBRITRARILY ASSIGN ONE BASED ON maxLength
						 splitString := SubStr(newContent, 1, maxLength)
						 splitContent.Push(splitString)
						 newContent := SubStr(newContent, maxLength + 1)
						 pos := 0
							Loop, % breakPoints.MaxIndex()
							{
							 pos += 1
							 breakPoints[pos] -= maxLength
							 	if (breakPoints[pos] < halfMaxLength)
								{
								 breakPoints.RemoveAt(pos)
								 pos -= 1
								}
							} 
						 break
						}
						else if (breakPoints[b] > halfMaxLength) || ((currentMaxLength < halfMaxLength) && (breakPoints[b] < currentMaxLength))
						{ ; USE A FOUND BREAK POINT FOR A BETTER SPLIT
						 breakPoint := breakPoints[b]
							Loop, % breakPoints.MaxIndex()
							{
								if (breakPoints[A_Index] > breakPoint)
								{ ; FIND THE BREAK POINT CLOSEST TO maxLength
									if (breakPoints[A_Index] > currentMaxLength) 
									{
									 break
									}
								 breakPoint := breakPoints[A_Index]
								}
							}
						 splitString := SubStr(newContent, 1, breakPoint)
						 splitContent.Push(splitString)
						 newContent := SubStr(newContent, breakPoint + 1)
						 pos := 0
							Loop, % breakPoints.MaxIndex()
							{
							 pos += 1
							 breakPoints[pos] -= breakPoint
								if ((breakPoints[pos] < halfMaxLength) && (currentMaxLength >= halfMaxLength)) || ((currentMaxLength < halfMaxLength) && (breakPoints[pos] < currentMaxLength))
								{
								 breakPoints.RemoveAt(pos)
								 pos -= 1
								}
							} 	
						 break
						}
						else
						{
						 breakPoints.RemoveAt(b)
						 b -= 1
						}
					}
				}
				else
				{
				 splitString := SubStr(newContent, 1, maxLength)
				 splitContent.Push(splitString)
				 newContent := SubStr(newContent, maxLength + 1)
				}
			}
			else
			{
			 splitContent.Push(newContent)
			 newContent := ""
			}
		}
	}
	else
	{
	 splitContent.Push(newContent)
	}
 return splitContent
}

FindPunctuation(str)
{
 charPositions := []
 punctuation := [A_Space, A_Tab, "。", ",", "、", "!", "！", "?", "？", "(", "（", "[", "「", "`n", ":", "：", "|", "｜", ";", "；", "<", "＜"]
	Loop, % StrLen(str)
	{
	 pos := A_Index
	 char := SubStr(str, pos, 1)
		Loop, % punctuation.MaxIndex()
		{
		 punc := punctuation[A_Index]
			if (char = punc)
			{
			 charPositions.Push(pos)
			 break
			}
		}
	}
 return charPositions
}

GetCharRange(char)
{ ; WORKS SPECIFICALLY FOR JAPANESE RIGHT NOW, TO SEPARATE BLOCKS OF TEXT INTO LINES WHEN THERE ARE NO SPACE OR PUNCTUATION
 value := Format("{:i}", "0x" (format("{:x}", ord(char))))
	if (value >= 12352) && (value <= 12447) ; HIRAGANA
		return 1
	else if (value >= 12448) && (value <= 12543) ; KATAKANA
		return 2
	else if (value >= 65280) && (value <= 65519) ; FULL ROMAN.HALF WIDTH KATAKANA
		return 3
	else if ((value >= 13312) && (value <= 19903)) || ((value >= 19968) && (value <= 40879)) ; KANJI
		return 4
	else
		return 0
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
		 transMessage := GrabText("", translationOutputControl, translationOutputControlPosition, translationOutputWindow, translationOutputWindowId, translationOutputControlVerified, translationOutputTextTest, 10, translationOutputClickPos, translationOutputCopyPos, translationOutputCopyID, true, false, true)
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

GrabText(UIAEl, control, controlPosition, window, windowID, controlVerified, controlVerificationText, controlVerificationTextID, thisClickPos, thisCopyPos, thisCopyID, skipMouseMethod, skipKeyboardMethod, forceClickOnce)
{
 global
 grabbedText := ""
 forceAlternateMethod := false
 
	if (UIAEl != "") && (IsObject(UIAEl))
	{
	 grabbedText := UIAEl.GetCurrentPropertyValue(UIA_ValueValuePropertyId := 30045)
	}
 
	if (control != "") && (grabbedText = "")
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
	
	if ((control = "") || (controlVerified = false)) && (grabbedText = "")
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
			 Sleep, 1000
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
			 Sleep, 1000
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
 GuiControl, Enable%toggle%, TransDelayEdit
 GuiControl, Enable%toggle%, MinDelay
 GuiControl, Enable%toggle%, MinLineDelayEdit
 GuiControl, Enable%toggle%, NextLineDelay
 GuiControl, Enable%toggle%, TextTimeout
 GuiControl, Enable%toggle%, MaxLines
 GuiControl, Enable%toggle%, MaxCharsEdit
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

AddPunctuation(testLine, firstWord)
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
			if ((firstWord = "") && (FoundPos > 0) && (FoundPos < 3)) || ((firstWord != "") && (s = sentences.MaxIndex()))
			{
			 sentences[s] := RegexReplace(sentences[s], "\s+$") ;trim ending whitespace
			 sentences[s] := sentences[s] "?"
			 
			 break
			}
		}
		Loop, % questionChars.MaxIndex()
		{
		 FoundPos := InStr(currentSentence, questionChars[A_Index])
			if (FoundPos >= StrLen(currentSentence) - 2) && (!InStr(currentSentence, "?"))
			{
			 sentences[s] := RegexReplace(sentences[s], "\s+$") ;trim ending whitespace
			 sentences[s] := sentences[s] "?"
			 break
			}
		}
		if (!InStr(sentences[s], "?"))
		{
		 sentences[s] := RegexReplace(sentences[s], "\s+$") ;trim ending whitespace
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
	 TransInputGetButton_TTEs := "Haga clic en este botón y (cuando se le solicite) haga clic directamente en el área de entrada de texto de una aplicación de`ntraducción donde normalmente escribiría las palabras que desea traducir."

	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y75 vTransOutputText, Translation App Text Output Area:
	 Gui,Font
	 Gui, Add, Edit, r1 vTransOutputEdit w220 +ReadOnly,  % ((TransOutputEdit != "") ? (TransOutputEdit) : ("Default Set: QTranslate/RICHEDIT50W2"))
	 Gui, Add, Button, vTransOutputGetButton gTransOutputGetButton,  Set Translated Text Output Area
	 TransOutputGetButton_TT := "Click on this button to and (when prompted) click directly on the text output area of a`ntranslation application area where translated text would appear."
	 TransOutputGetButton_TTEs := "Haga clic en este botón y (cuando se le solicite) haga clic directamente en el área de salida de`ntexto de un área de aplicación de traducción donde aparecería el texto traducido."

	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y145 vTransButtonText, Translation App Translate Button:
	 Gui,Font
	 Gui, Add, Edit, r1 vTransButtonEdit w220 +ReadOnly, % ((TransButtonEdit != "") ? (TransButtonEdit) : ("Default Set: QTranslate/Button9"))
	 Gui, Add, Button, vTransButtonGetButton gTransButtonGetButton, Set Translation App Translate Button
	 TransButtonGetButton_TT := "Click on this button to and (when prompted) click directly on the button of the`ntranslation application that you would usually click on to start the translation.`nSome applications may not have this button so this may not be necessary."
	 TransButtonGetButton_TTEs := "Haga clic en este botón y (cuando se le solicite) haga clic directamente en el botón de la aplicación de traducción en el que normalmente haría clic para iniciar la traducción.`nEs posible que algunas aplicaciones no tengan este botón, por lo que puede que no sea necesario."

	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y215 vTransDisplayText, Translated Text Display Area:
	 Gui,Font
	 Gui, Add, Edit, r1 vTransDisplayEdit w220 +ReadOnly, % ((vTransDisplayEdit != "") ? (vTransDisplayEdit) : ("Display area not set. (Optional)"))
	 Gui, Add, Button, vTransDisplayGetButton gTransDisplayGetButton, Set Translation Display Area
	 TransDisplayGetButton_TT := "Click on this button to and (when prompted) click directly on the the area of an`napplication where you would like the final translated text output to be shown.`nText intended for display is also output to a file named`nTransDisplayLog.txt in this script's directory which may be used instead."
	 TransDisplayGetButton_TTEs := "Haga clic en este botón y (cuando se le solicite) haga clic directamente en el área de una aplicación donde desea que se muestre el texto traducido final.`nEl texto destinado a mostrarse también se envía a un archivo llamado`nTransDisplayLog.txt en el directorio de este script que se puede utilizar en su lugar."
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
	 ToggleEditFields(!running)
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
	 PartialTranscriptionsCheck_TT := "If checked, ongoing transcriptions will be displayed before a full line or sentence has been completed.`nSome software may display inaccurate  transcriptions within the first few seconds before self-correcting."
	 PartialTranscriptionsCheck_TTEs := "Si está marcada, las transcripciones en curso se mostrarán antes de que se haya completado una línea u oración completa.`nAlgunos programas pueden mostrar transcripciones inexactas en los primeros segundos antes de autocorregirse."
	 
	 Gui, Add, CheckBox, x240 y31 gPartialTranslationsBox vPartialTranslationsCheck Checked%partialTranslations%, Partial Translations
	 PartialTranslationsCheck_TT := "If checked along with Partial Transcriptions, ongoing translations will also be displayed before a full line or sentence has been completed.`nFull sentences are best for accuracy, though sentence fragments often translate well enough."
	 PartialTranslationsCheck_TTEs := "Si se marca junto con Transcripciones parciales, las traducciones en curso también se mostrarán antes de que se haya completado una línea u oración completa.`nLas oraciones completas son mejores para mayor precisión, aunque los fragmentos de oraciones a menudo se traducen bastante bien."
	 Gui,Font
	
	 Gui,Font, BOLD 
	 Gui, Add, Text, x240 y55 vTransDelayText, Translation Delay:
	 Gui,Font
	 Gui, Add, Edit, x376 y53 w42 h17 gTransDelayEdit vTransDelayEdit, % translationDelay
	 TransDelayEdit_TT := "The average number of milliseconds that it takes the translation app to translate any given message.`nIncrease this delay if the translation application is slow or there is lag when using Internet based translators."
	TransDelayEdit_TTEs := "La cantidad promedio de milisegundos que le toma a la aplicación de traducción traducir un mensaje determinado.`nAumente este retraso si la aplicación de traducción es lenta o hay retrasos al utilizar traductores basados en Internet."
	
	 Gui,Font, BOLD 
	 Gui, Add, Text, x240 y78 vMinDelayText, Text Sample Delay:
	 Gui,Font
	 Gui, Add, Edit, x376 y76 w42 h17 gMinDelayEdit vMinDelay, % minDelayBetweenTextGrabAttempts
	 MinDelay_TT := "The number of milliseconds between this app's attempts to grab text from a transcription application for one participant.`nIf more than one participant is enabled then this delay is divided by however many are active."
	 MinDelay_TTEs := "La cantidad de milisegundos entre los intentos de esta aplicación de capturar texto de una aplicación de transcripción para un participante.`nSi hay más de un participante habilitado, este retraso se divide por la cantidad de participantes que estén activos."
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y101 w250 vNewLineText, Force New Line Delay:
	 Gui,Font
	 Gui, Add, Edit, x376 y99 w42 h17 gMinLineDelayEdit vMinLineDelayEdit, % minDelayBeforeNewLine
	 MinLineDelayEdit_TT := "The number of milliseconds this app will wait before creating a new line`n(rather than adding to the current line) if no new transcribed text is detected from one participant."
	 MinLineDelayEdit_TTEs := "La cantidad de milisegundos que esta aplicación esperará antes de crear una nueva línea`n(en lugar de agregarla a la línea actual) si no se detecta ningún texto nuevo transcrito de un participante."
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y124 vNextLineText, Line Processing Delay:
	 Gui,Font
	 Gui, Add, Edit, x376 y122 w42 h17 gNextLineEdit vNextLineDelay, % minDelayBeforeProcessingNewLine
	 NextLineDelay_TT := "The number of milliseconds this app will wait to start taking in text for a new line after finishing the previous line.`nThis is to help prevent innacurrate early results if Partial Transcriptions are enabled."
	 NextLineDelay_TTEs := "La cantidad de milisegundos que esta aplicación esperará para comenzar a recibir texto para una nueva línea después de terminar la línea anterior.`nEsto es para ayudar a evitar resultados tempranos inexactos si las transcripciones parciales están habilitadas."
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y150 vTotalLinesText, Total Lines to Display:
	 Gui,Font
	 Gui, Add, Edit, x376 y148 w42 h17 gLinesEdit Limit2 vMaxLines
	 MaxLines_TT := "The number lines of text to be shown in the display area`nor TransDisplayLog.txt display file (created in this script's directory on startup).`nIf both transcription and translation are enabled this counts as two lines (one for each language)."
	 MaxLines_TTEs := "Las líneas numéricas de texto que se mostrarán en el área de visualización o en el archivo de visualización`nTransDisplayLog.txt (creado en el directorio de este script al inicio).`nSi tanto la transcripción como la traducción están habilitadas, esto cuenta como dos líneas (una para cada idioma)."
	 
	 Gui, Add, UpDown, vLinesUpDown gLinesCheck +Wrap Range1-99, % maxDisplayLines
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y173 vLineTimeoutText, Line Display Timeout:
	 Gui,Font
	 Gui, Add, Edit, x376 y172 w42 h17 gTimeoutEdit vTextTimeout, % lineTimeout
	 TextTimeout_TT := "The number milliseconds to wait before removing an old text line from from the display area or`nDisplayLog.txt display file (created in this script's directory on startup).`nSetting this to 0 means lines will not time out."
	 TextTimeout_TTEs := "El número de milisegundos que se deben esperar antes de eliminar una línea de texto antigua del área de`nvisualización o del archivo de visualización DisplayLog.txt (creado en el directorio de este script al inicio).`nEstablecer esto en 0 significa que las líneas no expirarán."
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y197 vMaxCharsText, Max Characters Per Line:
	 Gui,Font
	 Gui, Add, Edit, x376 y195 w42 h17 gMaxCharsEdit vMaxCharsEdit, % maxCharactersPerLine
	 MaxCharsEdit_TT := "The maximum number of characters per display line before another line is created.`nThis includes the participants's name if it is displayed."
	 MaxCharsEdit_TTEs := "El número máximo de caracteres por línea de visualización antes de que se cree otra línea.`nEsto incluye el nombre de los participantes si se muestra."
	 
	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y222 gUseDisplayFileCheck vUseDisplayFileCheck Checked%useDisplayFile%, Use DisplayLog.txt File
	 UseDisplayFileCheck_TT := "If checked, a file with this app's name and then DisplayLog.txt will be created in this script's directory,`nand will be continuously updated with participant's transcription/translations.`nThis can be used to display output in text readers such as an OBS Text (GDI+) source."
	 UseDisplayFileCheck_TTEs := "Si está marcada, se creará un archivo con el nombre de esta aplicación y luego DisplayLog.txt en el directorio`nde este script y se actualizará continuamente con las transcripciones/traducciones de los participantes.`nEsto se puede utilizar para mostrar la salida en lectores de texto como una fuente de texto OBS (GDI+)."
	 
	 Gui, Add, CheckBox, x240 y245 gSaveSettingsCheck vSaveSettingsCheck Checked%saveSettingsOnClose%, Save Settings on Close
	 SaveSettingsCheck_TT := "If checked, when this app is closed all settings will be saved to a file named TransTrans.ini in this script's directory."
	 SaveSettingsCheck_TTEs := "Si está marcada, cuando se cierre esta aplicación, todas las configuraciones se guardarán en un archivo llamado TransTrans.ini en el directorio de este script."
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
	 Gui, Show, w427 h286, Transcription/Translation
	 ToggleEditFields(!running)
	}
return
}

MaxCharsEdit:
{
 gui,submit,nohide ;updates gui variable
	if (MaxCharsEdit is digit) && (MaxCharsEdit != "") && (MaxCharsEdit > 12)
	{
	 maxCharactersPerLine := MaxCharsEdit
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
	if (useDisplayFile = false) && (FileExist(displayFile))
	{
	  FileDelete, % displayFile
	}
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
 GUIControl, Hide, MaxCharsEdit
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
 GUIControl, Show, MaxCharsEdit
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
	 ReceiveMessages_TTEs := "Si está marcado, recibirá y luego traducirá mensajes desde la siguiente dirección IP y puerto."
	 
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
	 SendMessages_TTEs := "Si está marcado, enviará los mensajes recibidos traducidos a la siguiente dirección IP y puerto."
	 
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
	 MessageRate_TTEs := "Retraso de milisegundos entre el envío de cada mensaje recibido al traductor y luego a la dirección IP/puerto de envío especificado, si está habilitado."
	 
	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y124 gIncludeMessageAddress vIncludeMessageAddress Checked%messageAddressEnabled%, Include Message Address:
	 IncludeMessageAddress_TT := "If checked, will include the below address in the same packet before the message, separated by a comma like in this example:`n/AHK/Message, Example Message Here.`nThis can be used to send messages via the OSC protocol."
	 IncludeMessageAddress_TTEs := "Si está marcado, incluirá la siguiente dirección en el mismo paquete antes del mensaje, separada por una coma como en este ejemplo:`n/AHK/Message, Mensaje de ejemplo aquí.`nEsto se puede utilizar para enviar mensajes a través del protocolo OSC."
	 
	 Gui,Font
	 Gui, Add, Edit, x240 y142 w196 h18 gMessageAddress vMessageAddress , % sendMessageAddress

	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y172 gSendDisplayContent vSendDisplayContent Checked%sendingDisplayContent%, Send Participant Display Content
	 SendDisplayContent_TT := "If checked, will continuously send all participant Transcribed/Translated content to the specified IP address/port.`nThis is the same content that would be output to a display area or written to the DisplayLog.txt file."
	 SendDisplayContent_TTEs := "Si está marcado, enviará continuamente todo el contenido transcrito/traducido de los participantes a la dirección IP/puerto especificado.`nEste es el mismo contenido que se mostraría en un área de visualización o se escribiría en el archivo DisplayLog.txt."
	
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
	 IncludeDisplayMessageAddress_TTEs := "Si está marcado, incluirá la siguiente dirección en el mismo paquete antes de que el participante muestre el texto del contenido, separada por una coma como en este ejemplo:`n/AHK/Display, Participante 2: ¡Hola! こんにちは！`nEsto se puede utilizar para enviar todo el contenido de los participantes a través del protocolo OSC."
	 
	 Gui,Font
	 Gui, Add, Edit, x240 y238 w196 h18 gDisplayMessageAddressEdit vDisplayMessageAddressEdit, % displayMessageAddress
	 Gui,Font, BOLD
	 Gui, Add, CheckBox, x240 y264 gSendLines vSendLines Checked%sendIndividualDisplayLines%, Send Lines
	 SendLines_TT := "If checked, will send each transcribed/translated text line rather than sending the entire display content when it updates.`nIf Partial Transcriptions are enabled, a line ID (as an integer) will be included in the packet before the message (string), separated by a comma.`nThis is important for the receiving app to know which line to update."
	 SendLines_TTEs := "Si está marcado, enviará cada línea de texto transcrita/traducida en lugar de enviar todo el contenido de la pantalla cuando se actualice.`nSi las transcripciones parciales están habilitadas, se incluirá una ID de línea (como un número entero)`nen el paquete antes del mensaje (cadena), separada por una coma.`nEsto es importante para que la aplicación receptora sepa qué línea actualizar."
	 
	 Gui, Add, DDL, gLineIDTypeSelection vLineIDTypeSelection x322 y262 w114 h70 AltSubmit Choose1, LineID as int (BE)|LineID as int (LE)|Line {ID} in string|No LineID
	 LineIDTypeSelection_TT := "This selection box determines how an integer will be sent allows the receiving app to`nidentify which lines are being updated when Partial Transcriptions are enabled.`nLineID as int (BE) : The LineID is sent as a Big Endian integer, before the string in the same packet, separated by a comma.`nLineID as int (LE) the LineID is sent as a Little Endian integer, before the string in the same packet, separated by a comma.`nLine {ID} in string : The LineID is not send as an integer, but at the start of the same string in the line content. Example: {6}Hello, This is the line text!"
	 LineIDTypeSelection_TTEs := "Este cuadro de selección determina cómo se enviará un número entero y permite a la aplicación receptora identificar`nqué líneas se actualizan cuando las transcripciones parciales están habilitadas.`nLineID as int (BE): El LineID se envía como un entero Big Endian, antes de la cadena en el mismo paquete, separado por una coma.`nLineID as int (LE) el LineID se envía como un entero Little Endian, antes de la cadena en el mismo paquete, separado por una coma.`nLínea {ID} en cadena: el LineID no se envía como un número entero, sino al comienzo de la misma cadena en el contenido de la línea.`nEjemplo: {6}Hola, ¡esta es la línea de texto!"
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
	 ToggleEditFields(!running)
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
	 Gui, debugWindow:Add, Text, x180 y5 w300 vCurentLoopText, Member Loop: 0
	 Gui, debugWindow:Add, Edit, vPrevTextEdit x10 w400 h180 +ReadOnly
	 Gui, debugWindow:Font, BOLD
	 Gui, debugWindow:Add, Text,, New Text:
	 Gui, debugWindow:Font
	 Gui, debugWindow:Add, Edit, vNewTextEdit w400 h180 +ReadOnly
	 Gui, debugWindow:Font, BOLD
	 Gui, debugWindow:Add, Text, vPreviousPartialTextText w400, Previous Partial Text:
	 Gui, debugWindow:Font
	 Gui, debugWindow:Add, Edit, vPreviousPartialTextEdit w400 h60 +ReadOnly
	 Gui, debugWindow:Font, BOLD
	 Gui, debugWindow:Add, Text, vPartialTextText w400, Partial Text:
	 Gui, debugWindow:Font
	 Gui, debugWindow:Add, Edit, vPartialTextEdit w400 h60 +ReadOnly
	 Gui, debugWindow:Font, BOLD
	 Gui, debugWindow:Add, Text, vNewLineDebugText w400, New Line:
	 Gui, debugWindow:Font
	 Gui, debugWindow:Add, Edit, vNewLineEdit w400 h45 +ReadOnly
	 Gui, debugWindow:Font, BOLD
	 Gui, debugWindow:Add, Text, vDisplayLineText w400, Display Line:
	 Gui, debugWindow:Font
	 Gui, debugWindow:Add, Edit, vDisplayLineEdit w400 h45 +ReadOnly
	 Gui, debugWindow:Show, %debugWindowPos% w420 h725,Debug
	 Gui, debugWindow: +HwnddebugWindowID
	 debug := true
	}
	else if (debug = false)
	{
	 Gui, debugWindow:Show, %debugWindowPos% w430 h725,Debug
	 Gui, debugWindow: +HwnddebugWindowID
	 debug := true
	}
	else
	{
	 debug := false
	 WinGetPos, X, Y,,, ahk_id %debugWindowID%
	 debugWindowPos :=  % "x"X " y"Y " "
	 Gui, debugWindow:Hide
	}
 return
}

debugWindowGuiClose:
{
 WinGetPos, X, Y,,, ahk_id %debugWindowID%
 debugWindowPos :=  % "x"X " y"Y " "
 Gui, debugWindow:Hide
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
	if (TransDelayEdit is digit) && (TransDelayEdit != "") && (TransDelayEdit > 0) 
	{
	 translationDelay := TransDelayEdit
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
	 FormatTime, CurrentDateTime,, MM-dd-yy
	 logFile := directory "\" CurrentDateTime " Transcript.txt"
		if FileExist(logFile)
		{
		 newLogFile := newDirectory "\" CurrentDateTime " Transcript.txt"
		 FileCopy, logFile, newLogFile
		 FileDelete, % logFile
		 logFile := newLogFile
		}	
	 directory := newDirectory
	 GuiControl,, FileEdit, %directory%
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
 MouseGetPos, mX, mY, id, mCtrl
 WinGetTitle, title, ahk_id %id%
 rectangleGuideColor := "Blue"
	if (settingTextOutputWindow = true)
	 ToolTip, Click on the text output area for the participant.`nGetting Text Output Window Title and Control Area [ESC to Cancel]`n(Under Mouse position at X:%mX% Y:%mY%):`n%title%`n%mCtrl%
	else if (settingTextInputWindow = true)
	 ToolTip, Click on the area where text can be input for translation.`nGetting Text Input Window Title and Control Area [ESC to Cancel]`n(Under Mouse position at X:%mX% Y:%mY%):`n%title%`n%mCtrl%
	else if (settingTranslationOutputWindow = true)
	 ToolTip, Click on the area where translated text appears.`nGetting Translation Output Window Title and Control Area [ESC to Cancel]`n(Under Mouse position at X:%mX% Y:%mY%):`n%title%`n%mCtrl%
	else if (settingTranslatedTextDisplay = true)
	 ToolTip, Click on the text input area you want the translated text to be displayed.`nGetting Translated Text Window Title and Control Area [ESC to Cancel]`n(Under Mouse position at X:%mX% Y:%mY%):`n%title%`n%mCtrl%
	else if (settingTranslateButton = true)
	 ToolTip, Click on the translation app translate button.`nGetting Translate Button and Control Area [ESC to Cancel]`n(Under Mouse position at X:%mX% Y:%mY%):`n%title%`n%mCtrl%
	else if (settingTextOutputCopyPos = true)
	{
	 ToolTip, **Now click on the COPY button.** [ESC to Cancel] X:%mX% Y:%mY%
	 rectangleGuideColor := "Red"
	}
	else if (settingTextInputPastePos = true)
	{
	 ToolTip, **Now click on the PASTE button.** [ESC to Cancel] X:%mX% Y:%mY%
	 rectangleGuideColor := "Red"
	}
	else if (settingTranslationOutputCopyPos = true)
	{
	 ToolTip, **Now click the COPY button.** [ESC to Cancel] X:%mX% Y:%mY%
	 rectangleGuideColor := "Red"
	}
	else if (settingTranslatedTextPastePos = true)
	{
	 ToolTip, **Now click on the PASTE button.** [ESC to Cancel] X:%mX% Y:%mY%
	 rectangleGuideColor := "Red"
	}
	
	if (settingTextOutputWindow = true)
	{
	 mEl := UIA.SmallestElementFromPoint(mX, mY, true, id) ; UIA Deep search enabled by default
		if (IsObject(mEl))
		{
		 windowElements[currentMember] := mEl
		 mElPos := mEl.CurrentBoundingRectangle
		 windowElementIDs[currentMember] := mEl.CurrentAutomationId
		 RangeTip(mElPos.l, mElPos.t, mElPos.r-mElPos.l, mElPos.b-mElPos.t, rectangleGuideColor, 4)
		 return
		}
	}
 WinGetPos, wX, wY, wW, Wh, ahk_id %id%
 ControlGetPos, cX, cY, cW, cH, %mCtrl%, ahk_id %id%
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
 global
 static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
 CurrControl := A_GuiControl
 ttLang := ""
	if (currentLanguage = "Español")
	 ttLang := "ES"
	;else if (currentLanguage = "日本語") - implementing Japanese ToolTips along with the entire UI translation.
	; ttLang := "JA"

    if (CurrControl = "")
	{
	 SetTimer, RemoveToolTip, 500
	}
	else If (CurrControl != PrevControl and not InStr(CurrControl, " ")) and not InStr(CurrControl, ">")
    {
	 currentTip := %CurrControl%_TT%ttLang%
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
	 currentTip := %CurrControl%_TT%ttLang%
		if (StrLen(currentTip) < 3)
		{
		 return
		}
    SetTimer, DisplayToolTip, Off
    ToolTip % %CurrControl%_TT%ttLang%  ; The leading percent sign tell it to use an expression.
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
	 windowElementIDsVar .= windowElementIDs[A_Index] . ((A_Index < maxMembers) ? (",") : (""))
	}


 iniFile.Set("memberNames", "Participant Windows", memberNamesVar)
 iniFile.Set("showNames", "Participant Windows", showNamesVar)
 iniFile.Set("memberEnabled", "Participant Windows", memberEnabledVar)
 iniFile.Set("translateEnabled", "Participant Windows", translateEnabledVar)
 iniFile.Set("windowTitles", "Participant Windows", windowTitlesVar)
 iniFile.Set("windowOriginalTitles", "Participant Windows", windowOriginalTitlesVar)
 iniFile.Set("windowIDs", "Participant Windows", windowIDsVar)
 iniFile.Set("windowMainIDs", "Participant Windows", windowMainIDsVar)
 iniFile.Set("windowProcessIDs", "Participant Windows", windowProcessIDsVar)
 iniFile.Set("windowControls", "Participant Windows", windowControlsVar)
 iniFile.Set("windowControlPositions", "Participant Windows", windowControlPositionsVar)
 iniFile.Set("windowControlsVerified", "Participant Windows", windowControlsVerifiedVar)
 iniFile.Set("windowClickPos", "Participant Windows", windowClickPosVar)
 iniFile.Set("windowCopyPos", "Participant Windows", windowCopyPosVar)
 iniFile.Set("windowCopyIDs", "Participant Windows", windowCopyIDsVar)
 iniFile.Set("windowElementIDs", "Participant Windows", windowElementIDsVar)
 
 scriptPID :=  DllCall("GetCurrentProcessId")
 WinGetPos, X, Y,,, ahk_pid %scriptPID%
 mainWindowPos := % "x"X " y"Y " "
 debugWin := WinExist(ahk_pid %scriptPID% "Debug")
	if (debugWin != "0x0")
	{
	 debugWindowOpen := true
	 WinGetPos, X, Y,,, ahk_id %debugWindowID%
	 debugWindowPos :=  % "x"X " y"Y " "
	}
	else
	{
	 debugWindowOpen := false
	}
 iniFile.Set("mainWindowPos", "Participant Windows", mainWindowPos)
 iniFile.Set("debugWindowPos", "Participant Windows", debugWindowPos)
  iniFile.Set("debugWindowOpen", "Participant Windows", debugWindowOpen)
  
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
 iniFile.Set("maxCharactersPerLine", "Options", maxCharactersPerLine)
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
 memberNames := StrSplit(iniFile.Get("memberNames", "Participant Windows"), ",")
 memberEnabled := StrSplit(iniFile.Get("memberEnabled", "Participant Windows"), ",")
 translateEnabled := StrSplit(iniFile.Get("translateEnabled", "Participant Windows"), ",")
 windowTitles := StrSplit(iniFile.Get("windowTitles", "Participant Windows"), ",")
 windowOriginalTitles := StrSplit(iniFile.Get("windowOriginalTitles", "Participant Windows"), ",")
 windowIDs := StrSplit(iniFile.Get("windowIDs", "Participant Windows"), ",")
 windowMainIDs := StrSplit(iniFile.Get("windowMainIDs", "Participant Windows"), ",")
 windowControls := StrSplit(iniFile.Get("windowControls", "Participant Windows"), ",")
 windowControlPositions := StrSplit(iniFile.Get("windowControlPositions", "Participant Windows"), ",")
 windowControlsVerified := StrSplit(iniFile.Get("windowControlsVerified", "Participant Windows"), ",")
 windowClickPos := StrSplit(iniFile.Get("windowClickPos", "Participant Windows"), ",")
 windowCopyPos := StrSplit(iniFile.Get("windowCopyPos", "Participant Windows"), ",")
 windowCopyIDs := StrSplit(iniFile.Get("windowCopyIDs", "Participant Windows"), ",")
 windowElementIDs := StrSplit(iniFile.Get("windowElementIDs", "Participant Windows"), ",")
 
 	Loop, % maxMembers
	{ ; RESTORES PREVIOUSLY FOUND IUIAutomation WINDOW
	 prevWindowID := windowIDs[A_Index]
		if (prevWindowID != "") && WinExist("ahk_id" prevWindowID) && (windowElementIDs[A_Index] != "") 
		{ 
		 me3 := UIA.ElementFromHandle(windowIDs[A_Index], true) ; GETS THE MAIN WINDOW ELEMENT FROM THE LAST SESSION
		 windowElements[A_Index] := GetPreviousElement(me3, windowElementIDs[A_Index]) ; FINDS AND RETURNS THE EXACT ELEMENT USED IN THE LAST SESSION
		}
	}
 
 mainWindowPos := iniFile.Get("mainWindowPos", "Participant Windows", mainWindowPos)
 debugWindowPos := iniFile.Get("debugWindowPos", "Participant Windows", debugWindowPos)
 debugWindowOpen := iniFile.Get("debugWindowOpen", "Participant Windows", debugWindowOpen)
 
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
 maxCharactersPerLine := iniFile.Get("maxCharactersPerLine", "Options", maxCharactersPerLine)
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


GetPreviousElement(el, automationId) 
{ ; FINDS AND RESTORES THE PREVIOUS UIA ELEMENT IF THIS APP IS CLOSED AND RE-OPENED
	if !IsObject(el)
		return
	try {
		if !(children := el.FindAll(UIA.TrueCondition, 0x2))
			return
		for k, v in children
		{
			if (v.CurrentAutomationId = automationId)
			{
			 return v
			}
		 GetPreviousElement(v, automationId)
		}
	}
}

class UIA_Base 
{ ; Base class for all UIA objects (UIA_Interface, UIA_Element etc), that is used to fetch properties from __Properties, and get constants and enumerations from UIA_Enum.
	__New(p="", flag=0, version="") {
		ObjInsert(this,"__Type","IUIAutomation" SubStr(this.__Class,5))
		,ObjInsert(this,"__Value",p)
		,ObjInsert(this,"__Flag",flag)
		,ObjInsert(this,"__Version",version)
	}
	__Get(member) {
		if member not in base,__UIA,TreeWalkerTrue,TrueCondition ; base & __UIA should act as normal
		{
			if raw:=SubStr(member,0)="*" ; return raw data - user should know what they are doing
				member:=SubStr(member,1,-1)
			if RegExMatch(this.__properties, "im)^" member ",(\d+),(\w+)", m) { ; if the member is in the properties. if not - give error message
				if (m2="VARIANT")	; return VARIANT data - DllCall output param different
					return UIA_Hr(DllCall(this.__Vt(m1), "ptr",this.__Value, "ptr",UIA_Variant(out)))? (raw?out:UIA_VariantData(out)):
				else if (m2="RECT") ; return RECT struct - DllCall output param different
					return UIA_Hr(DllCall(this.__Vt(m1), "ptr",this.__Value, "ptr",&(rect,VarSetCapacity(rect,16))))? (raw?out:UIA_RectToObject(rect)):
				else if (m2="double")
					return UIA_Hr(DllCall(this.__Vt(m1), "ptr",this.__Value, "Double*",out))?out:
				else if UIA_Hr(DllCall(this.__Vt(m1), "ptr",this.__Value, "ptr*",out))
					return raw?out:m2="BSTR"?StrGet(out) (DllCall("oleaut32\SysFreeString", "ptr", out)?"":""):RegExMatch(m2,"i)IUIAutomation\K\w+",n)?(IsFunc(n)?UIA_%n%(out):new UIA_%n%(out)):out ; Bool, int, DWORD, HWND, CONTROLTYPEID, OrientationType? if IUIAutomation___ is a function, that will be called first, if not then an object is created with the name
			} else if ObjHasKey(UIA_Enum, member) {
				return UIA_Enum[member]
			} else if RegexMatch(member, "i)PatternId|EventId|PropertyId|AttributeId|ControlTypeId|AnnotationType|StyleId|LandmarkTypeId|HeadingLevel|ChangeId|MetadataId", match) {
				return UIA_Enum["UIA_" match](member)
			} else throw Exception("Property not supported by the " this.__Class " Class.",-1,member)
		}
	}

	__Vt(n) {
		return NumGet(NumGet(this.__Value+0,"ptr")+n*A_PtrSize,"ptr")
	}
}	

class UIA_Interface extends UIA_Base 
{
	static __IID := "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}"
		,  __properties := "ControlViewWalker,14,IUIAutomationTreeWalker`r`nContentViewWalker,15,IUIAutomationTreeWalker`r`nRawViewWalker,16,IUIAutomationTreeWalker`r`nRawViewCondition,17,IUIAutomationCondition`r`nControlViewCondition,18,IUIAutomationCondition`r`nContentViewCondition,19,IUIAutomationCondition`r`nProxyFactoryMapping,48,IUIAutomationProxyFactoryMapping`r`nReservedNotSupportedValue,54,IUnknown`r`nReservedMixedAttributeValue,55,IUnknown"
		
	; Compares two UI Automation elements to determine whether they represent the same underlying UI element.
	CompareElements(e1,e2) { 
		return UIA_Hr(DllCall(this.__Vt(3), "ptr",this.__Value, "ptr",e1.__Value, "ptr",e2.__Value, "int*",out))? out:
	}
	; Compares two integer arrays containing run-time identifiers (IDs) to determine whether their content is the same and they belong to the same UI element. r1 and r2 need to be RuntimeId arrays (returned by GetRuntimeId()), where array.base.__Value contains the corresponding safearray.
	CompareRuntimeIds(r1,r2) { 
		return UIA_Hr(DllCall(this.__Vt(4), "ptr",this.__Value, "ptr",ComObjValue(r1.__Value), "ptr",ComObjValue(r2.__Value), "int*",out))? out:
	}
	
	; Retrieves a UI Automation element for the specified window. Additionally activateChromiumAccessibility flag can be set to True to send the WM_GETOBJECT message to Chromium-based apps to activate accessibility if it isn't activated.
	ElementFromHandle(hwnd, activateChromiumAccessibility=False) { 
		static activatedHwnds := {}
		try retEl := UIA_Hr(DllCall(this.__Vt(6), "ptr",this.__Value, "ptr",hwnd, "ptr*",out))? UIA_Element(out):
		if (retEl && activateChromiumAccessibility && !activatedHwnds[hwnd]) { ; In some setups Chromium-based renderers don't react to UIA calls by enabling accessibility, so we need to send the WM_GETOBJECT message to the first renderer control for the application to enable accessibility. Thanks to users malcev and rommmcek for this tip. Explanation why this works: https://www.chromium.org/developers/design-documents/accessibility/#TOC-How-Chrome-detects-the-presence-of-Assistive-Technology 
			WinGet, cList, ControlList, ahk_id %hwnd%
			if InStr(cList, "Chrome_RenderWidgetHostHWND1") {
				SendMessage, WM_GETOBJECT := 0x003D, 0, 1, Chrome_RenderWidgetHostHWND1, ahk_id %hwnd%
				try rendererEl := retEl.FindFirstBy("ClassName=Chrome_RenderWidgetHostHWND"), startTime := A_TickCount
				rendererEl := rendererEl ? rendererEl : retEl
				if rendererEl {
					rendererEl.CurrentName ; it doesn't work without calling CurrentName (at least in Skype)
					while (!rendererEl.CurrentValue && (A_TickCount-startTime < 500))
						Sleep, 40
				}
			}
			activatedHwnds[hwnd] := 1
		}
		return UIA_Hr(DllCall(this.__Vt(6), "ptr",this.__Value, "ptr",hwnd, "ptr*",out))? UIA_Element(out):
	}
	; Retrieves the UI Automation element at the specified point on the desktop. Additionally activateChromiumAccessibility flag can be set to True to send the WM_GETOBJECT message to Chromium-based apps to activate accessibility if it isn't activated.
	ElementFromPoint(x="", y="", activateChromiumAccessibility=False) { 
		static activatedHwnds := {}
		if (x==""||y=="") {
			VarSetCapacity(pt, 8, 0), NumPut(8, pt, "Int"), DllCall("user32.dll\GetCursorPos","UInt",&pt), x :=  NumGet(pt,0,"Int"), y := NumGet(pt,4,"Int")
		}
		if (activateChromiumAccessibility && (hwnd := DllCall("GetAncestor", "UInt", DllCall("user32.dll\WindowFromPoint", "int64",  y << 32 | x), "UInt", GA_ROOT := 2)) && !activatedHwnds[hwnd]) { ; hwnd from point by SKAN
			WinGet, cList, ControlList, ahk_id %hwnd%
			if InStr(cList, "Chrome_RenderWidgetHostHWND1") 
				try this.ElementFromHandle(hwnd, False)
			activatedHwnds[hwnd] := 1
		}
		return UIA_Hr(DllCall(this.__Vt(7), "ptr",this.__Value, "UInt64",x==""||y==""?pt:x&0xFFFFFFFF|(y&0xFFFFFFFF)<<32, "ptr*",out))? UIA_Element(out):
	}	
	
	; Retrieves a UIA_TreeWalker object that can be used to traverse the Microsoft UI Automation tree.
	CreateTreeWalker(condition) { 
		return UIA_Hr(DllCall(this.__Vt(13), "ptr",this.__Value, "ptr",Condition.__Value, "ptr*",out))? new UIA_TreeWalker(out):
	}
	
	; Creates a condition that is always true.
	CreateTrueCondition() { 
		return UIA_Hr(DllCall(this.__Vt(21), "ptr",this.__Value, "ptr*",out))? new UIA_BoolCondition(out):
	}
	; Creates a condition that is always false.
	CreateFalseCondition() { 
		return UIA_Hr(DllCall(this.__Vt(22), "ptr",this.__Value, "ptr*",out))? new UIA_BoolCondition(out):
	}

	; Gets ElementFromPoint and filters out the smallest subelement that is under the specified point. If windowEl (window under the point) is provided, then a deep search is performed for the smallest element (this might be very slow in large trees).
	SmallestElementFromPoint(x="", y="", activateChromiumAccessibility=False, windowEl="") 
	{  ;ToolTip, % "starting" IsObject(winEl)
		if IsObject(windowEl) 
		{ 
		 element := this.ElementFromPoint(x, y, activateChromiumAccessibility)
		 bound := element.CurrentBoundingRectangle, elementSize := (bound.r-bound.l)*(bound.b-bound.t), prevElementSize := 0, stack := [windowEl]
			if ((x >= bound.l) && (x <= bound.r) && (y >= bound.t) && (y <= bound.b)) 
			{ ; If parent is not in bounds, then children arent either
				if ((newSize := (bound.r-bound.l)*(bound.b-bound.t)) < elementSize)
					element := stack[1], elementSize := newSize
				for _, childEl in stack[1].GetChildren() 
				{
				 bound := childEl.CurrentBoundingRectangle
				 type := childEl.CurrentControlType
					if (type = "50004") ; EDIT FIELD
					{
					 element := childEl
					 return element
					}
				}
			}
		 return element
		} 
		else 
		{
		 element := this.ElementFromPoint(x, y, activateChromiumAccessibility)
		 bound := element.CurrentBoundingRectangle, elementSize := (bound.r-bound.l)*(bound.b-bound.t), prevElementSize := 0
			for k, v in element.FindAll(this.__UIA.TrueCondition) 
			{
			 type := v.CurrentControlType
				if (type = "50004") ; EDIT FIELD
				{
				 element := childEl
				 return element
				}
			}
		 return element
		}
	}
}

class UIA_Element extends UIA_Base 
{ ;~ http://msdn.microsoft.com/en-us/library/windows/desktop/ee671425(v=vs.85).aspx
 static __IID := "{d22108aa-8ac5-49a5-837b-37bbb3d7591e}", __properties := "CurrentProcessId,20,int`r`nCurrentControlType,21,CONTROLTYPEID`r`nCurrentLocalizedControlType,22,BSTR`r`nCurrentName,23,BSTR`r`nCurrentAcceleratorKey,24,BSTR`r`nCurrentAccessKey,25,BSTR`r`nCurrentHasKeyboardFocus,26,BOOL`r`nCurrentIsKeyboardFocusable,27,BOOL`r`nCurrentIsEnabled,28,BOOL`r`nCurrentAutomationId,29,BSTR`r`nCurrentClassName,30,BSTR`r`nCurrentHelpText,31,BSTR`r`nCurrentCulture,32,int`r`nCurrentIsControlElement,33,BOOL`r`nCurrentIsContentElement,34,BOOL`r`nCurrentIsPassword,35,BOOL`r`nCurrentNativeWindowHandle,36,UIA_HWND`r`nCurrentItemType,37,BSTR`r`nCurrentIsOffscreen,38,BOOL`r`nCurrentOrientation,39,OrientationType`r`nCurrentFrameworkId,40,BSTR`r`nCurrentIsRequiredForForm,41,BOOL`r`nCurrentItemStatus,42,BSTR`r`nCurrentBoundingRectangle,43,RECT`r`nCurrentLabeledBy,44,IUIAutomationElement`r`nCurrentAriaRole,45,BSTR`r`nCurrentAriaProperties,46,BSTR`r`nCurrentIsDataValidForForm,47,BOOL`r`nCurrentControllerFor,48,IUIAutomationElementArray`r`nCurrentDescribedBy,49,IUIAutomationElementArray`r`nCurrentFlowsTo,50,IUIAutomationElementArray`r`nCurrentProviderDescription,51,BSTR`r`nCachedProcessId,52,int`r`nCachedControlType,53,CONTROLTYPEID`r`nCachedLocalizedControlType,54,BSTR`r`nCachedName,55,BSTR`r`nCachedAcceleratorKey,56,BSTR`r`nCachedAccessKey,57,BSTR`r`nCachedHasKeyboardFocus,58,BOOL`r`nCachedIsKeyboardFocusable,59,BOOL`r`nCachedIsEnabled,60,BOOL`r`nCachedAutomationId,61,BSTR`r`nCachedClassName,62,BSTR`r`nCachedHelpText,63,BSTR`r`nCachedCulture,64,int`r`nCachedIsControlElement,65,BOOL`r`nCachedIsContentElement,66,BOOL`r`nCachedIsPassword,67,BOOL`r`nCachedNativeWindowHandle,68,UIA_HWND`r`nCachedItemType,69,BSTR`r`nCachedIsOffscreen,70,BOOL`r`nCachedOrientation,71,OrientationType`r`nCachedFrameworkId,72,BSTR`r`nCachedIsRequiredForForm,73,BOOL`r`nCachedItemStatus,74,BSTR`r`nCachedBoundingRectangle,75,RECT`r`nCachedLabeledBy,76,IUIAutomationElement`r`nCachedAriaRole,77,BSTR`r`nCachedAriaProperties,78,BSTR`r`nCachedIsDataValidForForm,79,BOOL`r`nCachedControllerFor,80,IUIAutomationElementArray`r`nCachedDescribedBy,81,IUIAutomationElementArray`r`nCachedFlowsTo,82,IUIAutomationElementArray`r`nCachedProviderDescription,83,BSTR"
		
	FindAll(c="", scope=0x4) {  ; Returns all UI Automation elements that satisfy the specified condition. scope must be one of TreeScope enums (default is TreeScope_Descendants := 0x4).
		return UIA_Hr(DllCall(this.__Vt(6), "ptr",this.__Value, "uint",scope, "ptr",(c=""?this.TrueCondition:c).__Value, "ptr*",out))&&out? UIA_ElementArray(out):
	}
	
	GetCurrentPropertyValue(propertyId, ByRef out="") { ; Retrieves the current value of a property for this element. "out" will be set to the raw variant (generally not used).
		if propertyId is not integer
			propertyId := UIA_Enum.UIA_PropertyId(propertyId)
		return UIA_Hr(DllCall(this.__Vt(10), "ptr",this.__Value, "uint", propertyId, "ptr",UIA_Variant(out)))? UIA_VariantData(out):
	}
}

class UIA_ElementArray extends UIA_Base {
	static __IID := "{14314595-b4bc-4055-95f2-58f2e42c9855}"
		,  __properties := "Length,3,int"
	
	GetElement(i) {
		return UIA_Hr(DllCall(this.__Vt(4), "ptr",this.__Value, "int",i, "ptr*",out))? UIA_Element(out):
	}
}

class UIA_Condition extends UIA_Base { ;~ http://msdn.microsoft.com/en-us/library/windows/desktop/ee671420(v=vs.85).aspx
	static __IID := "{352ffba8-0973-437c-a61f-f64cafd81df9}"
		,  __properties := ""
}

class UIA_BoolCondition extends UIA_Condition {
	static __IID := "{1B4E1F2E-75EB-4D0B-8952-5A69988E2307}"
		,  __properties := "BooleanValue,3,boolVal"
}

UIA_Interface(maxVersion="") {
	static uia
	if (IsObject(uia) && (maxVersion == ""))
		return uia
	max := (maxVersion?maxVersion:UIA_Enum.UIA_MaxVersion_Interface)+1
	while (--max) 
	{
		if (!IsObject(UIA_Interface%max%) || (max == 1))
			continue

		try {
			if uia:=ComObjCreate("{e22ad333-b25f-460c-83d0-0581107395c9}",UIA_Interface%max%.__IID) {
				uia:=new UIA_Interface%max%(uia, 1, max), uiaBase := uia.base
				Loop, %max%
					uiaBase := uiaBase.base
				uiaBase.__UIA:=uia, uiaBase.TrueCondition:=uia.CreateTrueCondition(), uiaBase.TreeWalkerTrue := uia.CreateTreeWalker(uiaBase.TrueCondition)
				return uia
			}
		}
	}

	if uia:=ComObjCreate("{ff48dba4-60ef-4201-aa87-54103eef594e}","{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}")
	{
	 return uia:=new UIA_Interface(uia, 1, 1), uia.base.base.__UIA:=uia, uia.base.base.CurrentVersion:=1, uia.base.base.TrueCondition:=uia.CreateTrueCondition(), uia.base.base.TreeWalkerTrue := uia.CreateTreeWalker(uia.base.base.TrueCondition)
	}
return
}

UIA_Hr(hr) { ; Converts an error code to the corresponding error message ;~ http://blogs.msdn.com/b/eldar/archive/2007/04/03/a-lot-of-hresult-codes.aspx
	static err:={0x8000FFFF:"Catastrophic failure.",0x80004001:"Not implemented.",0x8007000E:"Out of memory.",0x80070057:"One or more arguments are not valid.",0x80004002:"Interface not supported.",0x80004003:"Pointer not valid.",0x80070006:"Handle not valid.",0x80004004:"Operation aborted.",0x80004005:"Unspecified error.",0x80070005:"General access denied.",0x800401E5:"The object identified by this moniker could not be found.",0x80040201:"UIA_E_ELEMENTNOTAVAILABLE",0x80040200:"UIA_E_ELEMENTNOTENABLED",0x80131509:"UIA_E_INVALIDOPERATION",0x80040202:"UIA_E_NOCLICKABLEPOINT",0x80040204:"UIA_E_NOTSUPPORTED",0x80040203:"UIA_E_PROXYASSEMBLYNOTLOADED"} ; //not completed
	if hr&&(hr&=0xFFFFFFFF) {
		RegExMatch(Exception("",-2).what,"(\w+).(\w+)",i)
		throw Exception(UIA_Hex(hr) " - " err[hr], -2, i2 "  (" i1 ")")
	}
	return !hr
}

UIA_Element(e,flag=1) { ; Used by UIA methods to create new UIA_Element objects of the highest available version. The highest version to try can be changed by modifying UIA_Enum.UIA_CurrentVersion_Element value.
	static v, previousVersion
	if !e
		return
	if (previousVersion != UIA_Enum.UIA_CurrentVersion_Element) ; Check if the user wants an element with a different version
		v := ""
	else if v
		return (v==1)?new UIA_Element(e,flag,1):new UIA_Element%v%(e,flag,v)
	max := UIA_Enum.UIA_CurrentVersion_Element+1
	While (--max) {
		if UIA_GUID(riid, UIA_Element%max%.__IID)
			return new UIA_Element%max%(e,flag,v:=max)
	}
	return new UIA_Element(e,flag,v:=1)
}

UIA_Enum(e) { ; Used to fetch constants and enumerations from the UIA_Enum class. The "UIA_" part of a variable name can be left out (eg UIA_Enum("ButtonControlTypeId") will return 50000).
	if ObjHasKey(UIA_Enum, e)
		return UIA_Enum[e]
	else if ObjHasKey(UIA_Enum, "UIA_" e)
		return UIA_Enum["UIA_" e]
}

UIA_ElementArray(p, uia="",flag=1) { ; Should AHK Object be 0 or 1 based? Currently 1 based.
	if !p
		return 
	a:=new UIA_ElementArray(p,flag),out:=[]
	Loop % a.Length
		out[A_Index]:=a.GetElement(A_Index-1)
	return out, out.base:={UIA_ElementArray:a}
}

UIA_RectToObject(ByRef r) { ; rect.__Value work with DllCalls?
	static b:={__Class:"object",__Type:"RECT",Struct:Func("UIA_RectStructure")}
	return {l:NumGet(r,0,"Int"),t:NumGet(r,4,"Int"),r:NumGet(r,8,"Int"),b:NumGet(r,12,"Int"),base:b}
}

UIA_Hex(p) {
	setting:=A_FormatInteger
	SetFormat,IntegerFast,H
	out:=p+0 ""
	SetFormat,IntegerFast,%setting%
	return out
}

UIA_GUID(ByRef GUID, sGUID) { ;~ Converts a string to a binary GUID and returns its address.
	if !sGUID
		return
	VarSetCapacity(GUID,16,0)
	return DllCall("ole32\CLSIDFromString", "wstr",sGUID, "ptr",&GUID)>=0?&GUID:""
}

UIA_Variant(ByRef var,type=0,val=0) {
	; https://www.autohotkey.com/boards/viewtopic.php?t=6979
	static SIZEOF_VARIANT := 8 + (2 * A_PtrSize)
	VarSetCapacity(var, SIZEOF_VARIANT), ComObject(0x400C, &var)[] := type&&(type!=8)?ComObject(type,type=0xB?(!val?0:-1):val):val
	return &var ; The variant probably doesn't need clearing, because it is passed to UIA and UIA should take care of releasing it.
}

UIA_IsVariant(ByRef vt, ByRef type="", offset=0) {
	size:=VarSetCapacity(vt),type:=NumGet(vt,offset,"UShort")
	return size>=16&&size<=24&&type>=0&&(type<=23||type|0x2000)
}

UIA_VariantData(ByRef p, flag=1, offset=0) {
	var := !UIA_IsVariant(p,vt, offset)?"Invalid Variant":ComObject(0x400C, &p)[] ; https://www.autohotkey.com/boards/viewtopic.php?t=6979
	;UIA_VariantClear(&p) ; Clears variant, except if it contains a pointer to an object (eg IDispatch). BSTR is automatically freed.
	return vt=11?-var:var ; Negate value if VT_BOOL (-1=True, 0=False)	
}

GetOSLanguage()
{
 spanish := ["000A", "2C0A", "400A", "340A", "240A", "140A", "5C0A", "1C0A", "300A", "440A", "100A", "480A", "580A", "080A", "4C0A", "180A", "3C0A", "280A", "500A", "0C0A", "040A", "540A", "380A", "200A"]
 japanese := ["0011", "0411"]
 RegRead, system_locale,HKEY_CURRENT_USER,Control Panel\International, Locale ; GET OS LANGUAGE FROM REGISTRY
 system_locale := SubStr(system_locale, 5, 4)
	Loop, % spanish.MaxIndex()
	{
	 if (A_Language = spanish[A_Index]) || (system_locale = spanish[A_Index])
		return "Español"
	}
	Loop, % japanese.MaxIndex()
	{
	 if (A_Language = japanese[A_Index]) || (system_locale = japanese[A_Index])
		return "日本語"
	}
 return "English"
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

	if FileExist(displayFile)
	{ ; REFORM THE DISPLAY FILE TO SHOW THE NEW CONTENT
	 FileDelete, % displayFile
		if (useDisplayFile = true)
		{
		 FileAppend, "", %displayFile%, UTF-8	
		}
	}
 ExitApp
}