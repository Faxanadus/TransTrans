;REPOSITORY AND INSTRUCTIONS: https://github.com/Faxanadus/TransTrans

Hotkey, $~LButton, LMouse, off
Hotkey, $~^C, CopyPause, on
Hotkey, $~^V, PastePause, on
Hotkey, ESC, Escape, off

maxMembers := 9
maxDisplayLines := 6
minCharactersPerLine := 60 ;NUMBER OF CHARACTERS IN MULTUPLE SENTENCES BEFORE A NEW LINE IN TRANSLATION DISPLAY
maxCharactersPerLine := 82 ;MAXIMUM CHARACTERS BEFORE A NEW LINE IS FORCED IN TRANSLATION DISPLAY
translationDelay := 100 ; HOW LONG TO WAIT BEFORE GRABBING TRANSLATED TEXT AFTER PUSHING TRANSLATE BUTTON
minDelayBetweenTextGrabAttempts := 420 ;MILLISECONDS BETWEEN TRANSCRIPTION WINDOW TEXT GRABBING ATTEMPTS
minDelayBeforeNewLine := 4800 ;MILLISECONDS BEFORE A NEW LINE IS FORCED IN TRANSLATION DISPLAY
minDelayBeforeProcessingNewLine := 1200 ;MILLISECONDS BEFORE THE SCRIPT WILL TRY TO START GRABBING NEW TEXT, TRANSCRIPTION MAY BE INACCURATE ON A NEW LINE IN THE FIRST SECOND
lineTimeout := 30000 ; MILLISECONDS BEFORE A LINE WILL BE REMOVED FROM DISPLAY, 0 = INFINITY
partialTranscriptions := true ; WHETHER PARTIALLY TRANSCRIBED SENTENCES WILL BE PUT IN THE DISPLAY AREA/FILE
partialTranslations := true ; DETERMINES WHETHER TRANSLATION OF TRANSCRIPTED TEXT WILL BE DONE IMMEDIATELY OR BEFORE THE FULL LINE IS DONE
currentLines := [] ; LINES OF TEXT THE SCRIPT IS KEEPING TRACK OF FOR FINAL DISPLAY AND/OR LOG FILE INSERTION
currentLinesTimes := [] ; TIME WHEN THE LINE WAS ENTERED IN FOR DISPLAY

;Gui, +AlwaysOnTop
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
windowControlTextTests := []
windowControlsVerified := []
windowClickPos := []
windowCopyPos := []
windowCopyID := []
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
lastLineComplete := []
lastLoopStartTime := []
newLineDelayTimes := []

textInputWindow := "QTranslate"
textInputWindowID := ""
textInputControl := "RICHEDIT50W1"
textInputControlPosition := ""
textInputControlTextTest := ""
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
translationOutputTextTest := ""
translationOutputControlVerified := true
translationOutputClickPos := ""
translationOutputCopyPos := ""
translationOutputCopyID := ""
translationDisplayWindow := ""
translationDisplayWindowID := ""
translationDisplayControl := ""
translationDisplayControlPosition := ""
translationDisplayTextTest := ""
translationDisplayControlVerified := false
translationDisplayClickPos := ""
translationDisplayPastePos := ""
translationDisplayPasteID := ""

running := false
inLoop := false
inLineTimeoutLoop := false
debug :=
appSetupDisplay :=
advancedOptionsDisplay :=
scriptPID := DllCall("GetCurrentProcessId")

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

directory := A_ScriptDir
displayFile := directory "\--TransDisplayLog--.txt"
	if FileExist(displayFile)
	{
	 FileDelete, % displayFile
	}
FileAppend,, %displayFile%, UTF-8

	Loop %maxMembers%
	{
	 participants.Push(A_Index)
	 memberEnabled.Push(0)
	 translateEnabled.Push(0)
	 memberNames.Push("Participant " A_Index)
	 showNames.Push(1)
	 windowTitles.Push("Text output area not set.")
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
	 windowCopyID.Push("")
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
Gui, Add, Edit, w34 h17 gMemberEdit Limit1 vMemberEdit
Gui, Add, UpDown, gMemberCheck +Wrap Range1-9, 1
MemberEdit_TT := "Current participant number, up to 9 participants with different transcription sources can be enabled."
Gui, Add, CheckBox, x55 y24 gMemberEnabledCheck vMemberEnabledCheck Checked1, Transcribe
MemberEnabledCheck_TT := "If checked, this member's transcribed text can be displayed or logged."
Gui, Add, CheckBox, x55 y42 gTranslateEnabledCheck vTranslateEnabledCheck Checked1, Translate
TranslateEnabledCheck_TT := "If checked, this member's translated text can be displayed or logged."
Gui, Add, Button, x158 y10 gShowAppSetupButton, App Setup >>
Gui, Add, Button, x158 y40 w70 gShowAdvSetupButton, Options  >>

Gui,Font, BOLD
Gui, Add, Text, x10 y50, Name:
Gui,Font
Gui, Add, Edit, r1 gNameCheck vNameEdit w170, Faxanadus
Gui, Add, CheckBox, x185 y66 gShowNameCheck vShowNameCheck Checked1, Show`nName
ShowNameCheck_TT := "If checked, this member's name will be shown along with displayed text."

Gui,Font, BOLD
Gui, Add, Text, x10 y96 , Text Output Area for this Participant:
Gui,Font
Gui, Add, Edit, r1 vWindowEdit w220 +ReadOnly, Text output area not set.
Gui, Add, Button, vWindowGetButton gWindowGetButton, Set Participant Output Area
WindowGetButton_TT := "Click on this button to choose where this participant's output text source is located."

Gui,Font, BOLD
Gui, Add, Text,x10 y170, Save Transcription to File:
Gui,Font
Gui, Add, CheckBox, x167 y170 gFileEnabledCheck vFileEnabledCheck Checked0, Enabled
FileEnabledCheck_TT := "If checked, a transcription log text file will be created and updated in the selected directory below.`nThis is separate from --TransDisplayLog--.txt display file (created in this script's directory on startup)."
Gui, Add, Edit, x10 y190 r1 vFileEdit w220 +ReadOnly, Default Set: Saved in this script's directory.
Gui, Add, Button, x10 y214 w50  vBrowseButton gBrowseButton,  Browse
Gui, Add, CheckBox, x155 y216 gTimestampCheck vTimestampCheck Checked1, Timestamps
TimestampCheck_TT := "If checked, timestamps will be added to the transcription log saved in the above directory`n(separate from --TransDisplayLog--.txt display file created in this script's directory on startup)."
GUIControl, Hide, TimestampCheck

Gui,Font, BOLD
Gui, Add, Text, x69 y240 w120 vActiveText, Status: Not Active
Gui,Font
Gui, Add, Button, x65 y260 w50 gStartButton, START
Gui, Add, Button, x120 y260 w50 gStopButton, STOP
Gui, Add, Button, x10 y259 gDebug,Debug
Gui, Show, w240 h286, Trans/Trans
OnMessage(0x200, "WM_MOUSEMOVE")
return

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

ShowAppSetupButton:
{
	if (appSetupDisplay != true) && (appSetupDisplay != false)
	{
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y5 vTransAppText, Translation App Text Input Area:
	 Gui,Font
	 Gui, Add, Edit, r1 vTransInputEdit w220 +ReadOnly, Default Set: QTranslate/RICHEDIT50W1
	 Gui, Add, Button, vTransInputGetButton gTransInputGetButton, Set Text Input Area
	 TransInputGetButton_TT := "Click on this button to and (when prompted) click directly on the text input area of a`ntranslation application where you would usually type in words to be translated."

	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y75 vTransOutputText, Translation App Text Output Area:
	 Gui,Font
	 Gui, Add, Edit, r1 vTransOutputEdit w220 +ReadOnly, Default Set: QTranslate/RICHEDIT50W2
	 Gui, Add, Button, vTransOutputGetButton gTransOutputGetButton,  Set Translated Text Output Area
	 TransOutputGetButton_TT := "Click on this button to and (when prompted) click directly on the text output area of a`ntranslation application area where translated text would appear."

	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y145 vTransButtonText, Translation App Translate Button:
	 Gui,Font
	 Gui, Add, Edit, r1 vTransButtonEdit w220 +ReadOnly, Default Set: QTranslate/Button9
	 Gui, Add, Button, vTransButtonGetButton gTransButtonGetButton, Set Translation App Translate Button
	 TransButtonGetButton_TT := "Click on this button to and (when prompted) click directly on the button of the`ntranslation application that you would usually click on to start the translation.`nSome applications may not have this button so this may not be necessary."

	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y215 vTransDisplayText, Translated Text Display Area:
	 Gui,Font
	 Gui, Add, Edit, r1 vTransDisplayEdit w220 +ReadOnly, Display area not set. (Optional)
	 Gui, Add, Button, vTransDisplayGetButton gTransDisplayGetButton, Set Translation Display Area
	 TransDisplayGetButton_TT := "Click on this button to and (when prompted) click directly on the the area of an`napplication where you would like the final translated text output to be shown.`nText intended for display is also output to file named`n--TransDisplayLog--.txt in this script's directory which may be used instead."
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
	 Gui, Add, CheckBox, x240 y15 gPartialTranscriptionsBox vPartialTranscriptionsCheck Checked1, Partial Transcriptions
	 PartialTranscriptionsCheck_TT := "If checked, ongoing transcriptions will be displayed before a full line or sentence has been completed.`nSome software may display innacurate transcriptions within the firs few seconds before self-correcting."
	 Gui, Add, CheckBox, x240 y35 gPartialTranslationsBox vPartialTranslationsCheck Checked1, Partial Translations
	 PartialTranslationsCheck_TT := "If checked along with Partial Transcriptions, ongoing translations will also be displayed before a full line or sentence has been completed.`nFull sentences are best for accuracy, though sentence fragments often translate well enough."
	 Gui,Font
	
	 Gui,Font, BOLD 
	 Gui, Add, Text, x240 y60 vMinDelayText, Text Sample Delay:
	 Gui,Font
	 Gui, Add, Edit, x240 y77 w50 h17 gMinDelayEdit vMinDelay, % minDelayBetweenTextGrabAttempts
	 MinDelay_TT := "The number of milliseconds between this app's attempts to grab text from a transcription application for one participant.`nIf more than one participant is enabled then this delay is divided by however many are active."
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y105 vNewLineText, New Line Delay:
	 Gui,Font
	 Gui, Add, Edit, x240 y122 w50 h17 gMinLineDelayEdit vMinLineDelay, % minDelayBeforeNewLine
	 MinLineDelay_TT := "The number of milliseconds this app will wait before creating a new line`n(rather than adding to the current line) if no new transcribed text is detected from one participant."
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y150 vNextLineText, Next Line Processing Delay:
	 Gui,Font
	 Gui, Add, Edit, x240 y167 w50 h17 gNextLineEdit vNextLineDelay, % minDelayBeforeProcessingNewLine
	 NextLineDelay_TT := "The number of milliseconds this app will wait to start taking in text for a new line after finishing the previous line.`nThis is to help prevent innacurrate early results if Partial Transcriptions are enabled."
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y195 vTotalLinesText, Total Lines to Display:
	 Gui,Font
	 Gui, Add, Edit, x240 y212 w40 h17 gLinesEdit Limit2 vMaxLines
	 MaxLines_TT := "The number lines of text to be shown in the display area`nor --TransDisplayLog--.txt display file (created in this script's directory on startup).`nIf both transcription and translation are enabled this counts as two lines (one for each language)."
	 Gui, Add, UpDown, vLinesUpDown gLinesCheck +Wrap Range1-99, % maxDisplayLines
	 
	 Gui,Font, BOLD
	 Gui, Add, Text, x240 y240 vLineTimeoutText, Line Display Timeout:
	 Gui,Font
	 Gui, Add, Edit, x240 y257 w40 h17 gTimeoutEdit vTextTimeout, % lineTimeout
	 TextTimeout_TT := "The number milliseconds to wait before removing an old text line from from the display area`nor --TransDisplayLog--.txt display file (created in this script's directory on startup)."
	 Gui, Add, Text, x290 y258 vLineTimeoutHelpText, (0 = No timeout)
	 
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
	 ShowAdvanvedSetup()
	 ToggleEditFields(!running)
	 Gui, Show, w400 h286, Transcription/Translation
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
	if (NextLineDelay is digit) && (NextLineDelay != "") && (NextLineDelay > 0) 
	{
	 minDelayBeforeProcessingNewLine := NextLineDelay
	}
return
}

NextLineEdit:
{
gui,submit,nohide ;updates gui variable
	if (MinLineDelay is digit) && (MinLineDelay != "") && (MinLineDelay > 0) 
	{
	 minDelayBeforeNewLine := MinLineDelay
	}
return
}

HideAdvanvedSetup()
{
 global
 advancedOptionsDisplay := false
 GUIControl, Hide, PartialTranscriptionsCheck
 GUIControl, Hide, PartialTranslationsCheck
 GUIControl, Hide, MinDelayText
 GUIControl, Hide, MinDelay
 GUIControl, Hide, MinLineDelay
 GUIControl, Hide, NewLineText
 GUIControl, Hide, MinLineDelayEdit
 GUIControl, Hide, NextLineText
 GUIControl, Hide, NextLineDelay
 GUIControl, Hide, TotalLinesText
 GUIControl, Hide, MaxLines
 GUIControl, Hide, LinesUpDown
 GUIControl, Hide, LineTimeoutText
 GUIControl, Hide, TextTimeout
 GUIControl, Hide, LineTimeoutHelpText
 return
}

ShowAdvanvedSetup()
{
 global
 advancedOptionsDisplay := true
 GUIControl, Show, PartialTranscriptionsCheck
 GUIControl, Show, PartialTranslationsCheck
 GUIControl, Show, MinDelayText
 GUIControl, Show, MinDelay
 GUIControl, Show, MinLineDelay
 GUIControl, Show, NewLineText
 GUIControl, Show, MinLineDelayEdit
 GUIControl, Show, NextLineText
 GUIControl, Show, NextLineDelay
 GUIControl, Show, TotalLinesText
 GUIControl, Show, MaxLines
 GUIControl, Show, LinesUpDown
 GUIControl, Show, LineTimeoutText
 GUIControl, Show, TextTimeout
 GUIControl, Show, LineTimeoutHelpText
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
ready := false
running := false
enabledCount := 0
titleSet := 0
	Loop, %maxMembers%
	{ ; CHECK IF AT LEAST ONE MEMBER IS ENABLED AND HAS A WINDOW TITLE SET
		if (memberEnabled[A_Index] = true) || (translateEnabled[A_Index] = true)
		{
		 enabledCount = enabledCount
			if (windowTitles[A_Index] != "") && (windowTitles[A_Index] != "Text output area not set.")
			{
			 ready := true
			 break
			}
		}
		else if (windowTitles[A_Index] != "") && (windowTitles[A_Index] != "Text output area not set.")
		{
		 titleSet += 1
		}
	}

	if (ready = false)
	{
		if (enabledCount = 0)
		{
		 GuiControl, Move, ActiveText, x25 y240 w220
		 GuiControl, Text, ActiveText, Status: All participants are disabled.
		}
		else if (titleSet = 0)
		{
		 GuiControl, Move, ActiveText, x11 y240 w222
		 GuiControl,, ActiveText, Status: No participant output windows set.
		}
	 return
	}
 
 GuiControl, Move, ActiveText, x76 y240 w100
 GuiControl, Text, ActiveText, Status: ACTIVE
 running := true
 ResetAll()
 ToggleEditFields(false)
 SetStoreCapsLockMode, Off
 savedClipboard := Clipboard
 savedClipboardAll := ClipboardAll ;THE USER's CLIPBOARD
 previousTransText := "" ;LAST LINE THE APP GRABBED FROM THE TRANSLATOR
 previousClipboard := "" ;THE APPS'S CLIPBOARD
 SetTimer, LineTimeoutLoop, Off
 inLineTimeoutLoop := false
 
	Loop
	{
	 	if (running = false)
		{
		 return
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
	 copyID := windowCopyID[loopMember]
	 newText := newTexts[loopMember]
	 previousText := previousTexts[loopMember]
	 newString := newStrings[loopMember]
	 newLine := newLines[loopMember]
	 fullLine := fullLines[loopMember]
	 lastLine :=  lastLines[loopMember]
	 transText := transTexts[loopMember]
	 lastControlState := lastControlStates[loopMember]
	 lastLineID := lastLineIds[loopMember]
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
				if ((translateEnabled[loopMember] = true) && ((lineComplete = true) || (partialTranslations = true)))
				{
				 grabAttempts := 0
				 SetText(textInputControl, textInputControlPosition, textInputWindow, textInputWindowID, textInputControlVerified, 1, fullPartialLine, textInputClickPos, textInputPastePos, textInputPasteID, true, false, true)
				 PushButton:
					if (translationWindow != "") && ((translationButton != "") || (translationWindowID != ""))
					{ ; PRESS THE TRANSLATE BUTTON
						
						if ((translationButton = "") || GetKeyState("Control") || GetKeyState("Alt") || GetKeyState("Shift") || GetKeyState("CapsLock") || GetKeyState("Win"))
						{
							if (translationButton != "")
							{
								if (translationWindowID != "")
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
								if (translationWindowID != "")
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
							if (translationWindowID != "")
							{
							 ControlSend, %translationButton%, {Space}, ahk_id %translationWindowID%
							}
							else 
							{
							 ControlSend, %translationButton%, {Space}, %translationWindow%
							}
						 ;ControlSend, %translationButton%, {NumpadEnter down}{NumpadEnter up}, %translationWindow% ;
						}
					}
					
					if (translationOutputControl != "") && ((translationOutputWindow != "") || (translationOutputWindowID != ""))
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
				 previousTransText := transText
				 match = `n ; COUNT THE NUMBER OF LINE BREAKS IN THE ORIGINAL LINE AND TRANSLATED OUTPUT TO DETECT EXTRA ADDED INFORMATION
				 RegexReplace(fullPartialLine, "(" match ")", match, newLineBreakCount)
				 RegexReplace(transText, "(" match ")", match, transBreakCount)
				 foundBreak := InStr(transText, "`n",,,newLineBreakCount + 1)
					if (transBreakCount > newLineBreakCount)
					{ ;REMOVE THE EXTRA INFORMATION
					 transText := SubStr(transText, 1, foundBreak - 2)
					}
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
			 UpdateDisplay() ; WRITES ALL THE LINES TO THE --TransDisplayLog--.txt FILE (CREATED ON STARTUP IN THE SCRIPT'S DIRECTORY) FOR USE IN DISPLAY IN TEXT READER APPLICATIONS, SUCH AS AN OBS Text (GDI+) SOURCE
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
GuiControl, Move, ActiveText, x69 y240 w120 
GuiControl, Text, ActiveText, Status: Not Active
Hotkey, $~LButton, off
Hotkey, ESC, off
ResetCurrentCursor()
ResetAll()
ToggleEditFields(true)
	if (inLineTimeoutLoop = false)
	{
	 SetTimer, LineTimeoutLoop, 1000
	}
return
}

GrabText(control, controlPosition, window, controlID, controlVerified, controlVerificationText, controlVerificationTextID, thisClickPos, thisCopyPos, thisCopyID, skipMouseMethod, skipKeyboardMethod, forceClickOnce)
{
 global
 grabbedText := ""
 forceAlternateMethod := false
	if (control != "")
	{ ; GRAB THE TEXT DIRECTLY FROM APP MEMORY USING A CONTORL AREA IF POSSIBLE
		if (controlID != "")
		{
		 ControlGetText, grabbedText, %control%, ahk_id %controlID%
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
		|| ((processID = currentPID) && (active_id != controlID))
		{ ; USES THE MOUSE CLICK METHOD TO GRAB THE TEXT IF CONTROL IS BEING USED OR THE WINDOW DOES NOT HAVE FOCUS
		 waitIterations := 0
			while (((processID = currentPID) || (processID = scriptPID)) && (GetKeyState("LButton"))) 
			|| ((processID = currentPID) && (active_id != controlID) && (active_id != currentMainID))
			{ ; IF THE USER IS DRAGGING THE ACTIVE WINDOW, WAIT BEFORE CLICKING DURING THIS PERIOD WILL CAUSE THE WHOLE WINDOW TO SHIFT IN A REALLY ANNOYING MANNER
				if (running = false)
				{
				 return
				}
			 Sleep, 100
			 WinGet, processID, PID, A
			 WinGet, active_id, ID, A
				if ((processID = currentPID) && (active_id != controlID))
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
			
			if (controlID != "")
			{
			 ControlClick, %thisClickPos%, ahk_id %controlID%,, Left, 3
			 ControlClick, %thisClickPos%, ahk_id %controlID%,, Right, 1
			 savedClipboard := Clipboard
			 savedClipboardAll := ClipboardAll
			ControlClick, %thisCopyPos%, ahk_id %controlID%,, Left, 1
				if (Clipboard = "") || (Clipboard = previousClipboard)
				{ ; TRY AGAIN
				 ControlClick, %thisClickPos%, ahk_id %controlID%,, Left, 3
				 ControlClick, %thisClickPos%, ahk_id %controlID%,, Right, 1
				 ControlClick, %thisCopyPos%, ahk_id %controlID%,, Left, 1
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
				 ControlClick, %control%, ahk_id %controlID%,, Left, 1, %controlPosition%
				}
				if (controlID != "")
				{
				 ControlClick, %thisClickPos%, ahk_id %controlID%,, Left, 1
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
				if (control != "")
				{
				 ControlSend, %control%, {RControl down}ac{RControl up}, ahk_id %controlID%
				}
			 	else if (controlID != "")
				{
				 ControlSend,, {RControl down}ac{RControl up}, ahk_id %controlID%
				}
				else 
				{
				 ControlSend,, {RControl down}ac{RControl up}, %window%
				}
			}
			else
			{		
				if (control != "")
				{
				 ControlSend, %control%, ac, ahk_id %controlID%
				}
			 	else if (controlID != "")
				{
				 ControlSend,, ac, ahk_id %controlID%
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

SetText(control, controlPosition, window, controlID, controlVerified, controlVerifiedID, textToSet, thisClickPos, thisPastePos, thisPasteID, skipMouseMethod, skipKeyboardMethod, forceClickOnce)
{
 global
 forceAlternateMethod := false
 lastPasteControlState := false
 mouseMethodFinished := false
	if (control != "")
	{ ; SET THE TEXT DIRECTLY INTO THE APP IF POSSIBLE
		if (controlID != "")
		{
		 ControlSetText, %control%, %textToSet%, ahk_id %controlID%
		}
		else 
		{
		 ControlSetText, %control%, %textToSet%, %window%
		}
		if (controlVerified = false)
		{
		 testText := ""
			if (controlID != "")
			{
			 ControlGetText, testText, %control%, ahk_id %controlID%
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
			|| ((processID = currentPID) && (active_id != controlID) && (active_id != currentMainID))
			{ ; IF THE USER IS DRAGGING THE ACTIVE WINDOW, WAIT BEFORE CLICKING DURING THIS PERIOD WILL CAUSE THE WHOLE WINDOW TO SHIFT IN A REALLY ANNOYING MANNER
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
			if (controlID != "") ;COMMENTED OUT BECAUSE thisPasteID MIGHT CHANGE BETWEEN CALLING UP THE RIGHT CLICK MENU, MAYBE FIXED BY USING REGULAR EXPRESSION SEARCHES
			{
			 ControlClick, %thisClickPos%, ahk_id %controlID%,, Left, 3
			 ControlClick, %thisClickPos%, ahk_id %controlID%,, Right, 1
			 savedClipboardAll := ClipboardAll
			 ClipBoard := textToSet
			 ControlClick, %thisPastePos%, ahk_id %controlID%,, Left, 1
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
			 	if (control != "")
				{ ; CLICK THE RELATIVE POSITION WITHIN THE CONTROL AREA
				 ControlClick, %control%, ahk_id %controlID%,, Left, 1, %controlPosition%
				}
				if (controlID != "")
				{
				 ControlClick, %thisClickPos%, ahk_id %controlID%,, Left, 1
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
				if (control != "")
				{
				 ControlSend, %control%, {RControl down}av{RControl up}, ahk_id %controlID%
				}
				else if (controlID != "")
				{
				 ControlSend,, {RControl down}av{RControl up}, ahk_id %controlID%
				}
				else 
				{
				 ControlSend,, {RControl down}av{RControl up}, %window%
				}
			}
			else
			{		
				if (control != "")
				{
				 ControlSend, %control%, av, ahk_id %controlID%
				}
				else if (controlID != "")
				{
				 ControlSend,, av, ahk_id %controlID%
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

ToggleEditFields(toggle)
{ ; TURNS OFF EDIT FIELDS BECAUSE THESE WILL BUG OUT IF THE LOOP IS ACTIVE
 GuiControl, Enable%toggle%, NameEdit
 GuiControl, Enable%toggle%, MinDelay
 GuiControl, Enable%toggle%, MinLineDelay
 GuiControl, Enable%toggle%, NextLineDelay
 GuiControl, Enable%toggle%, TextTimeout
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
 questionWords := ["who", "what", "when", "where", "why", "how"]
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
	if (inLineTimeoutLoop = true) && (currentLines.MaxIndex() <= 0) || (lineTimeout <= 0)
	{
	 SetTimer, LineTimeoutLoop, Off
	 inLineTimeoutLoop := false
	}	
}


UpdateDisplay()
{
global
	if FileExist(displayFile)
	{ ; REFORM THE DISPLAY FILE TO SHOW THE NEW CONTENT
	 FileDelete, % displayFile
	}
 allLines := ""
	for key, value in currentLines
	{
	 allLines := allLines . value "`n"
	}
 FileAppend, %allLines%, %displayFile%, UTF-8		
	if ((translationDisplayWindow != "") || (translationDisplayWindowID != ""))
	{ ; PUT THE TEXT IN THE FINAL DISPLAY AREA, IF NEEDED
	 SetText(translationDisplayControl, translationDisplayControlPosition, translationDisplayWindow, translationDisplayWindowID,translationDisplayControlVerified, 2, allLines, translationDisplayClickPos, translationDisplayPastePos, translationDisplayPasteID, true, false, false)
	}
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
	 lastLineComplete[A_Index] := 0
	 newLineDelayTime[A_Index] := minDelayBeforeProcessingNewLine
	}
}

SaveKeyDownStates()
{
global
controlDownState := GetKeyState("Control")
altDownState := GetKeyState("Alt")
shiftDownState := GetKeyState("Shift")
capsDownState := GetKeyState("CapsLock")
winDownState := GetKeyState("Win")
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
}


MemberEdit:
gui,submit,nohide ;updates gui variable
	if (MemberEdit is digit) && (MemberEdit != "") && (MemberEdit > 0) && (MemberEdit <= maxMembers)
	{
	 currentMember := MemberEdit
	 GuiControl,, MemberEnabledCheck, % memberEnabled[currentMember]
	 GuiControl,, TranslateEnabledCheck, % translateEnabled[currentMember]
	 GuiControl,, NameEdit, % memberNames[currentMember]
	 GuiControl,, WindowEdit, % windowTitles[currentMember]
	 GuiControl,, ShowNameCheck, % showNames[currentMember]
	}
return

MemberCheck:
gui,submit,nohide ;updates gui variable
currentMember := MemberEdit
GuiControl,, MemberEnabledCheck, % memberEnabled[currentMember]
GuiControl,, TranslateEnabledCheck, % translateEnabled[currentMember]
GuiControl,, NameEdit, % memberNames[currentMember]
GuiControl,, WindowEdit, % windowTitles[currentMember]
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
memberNames[currentMember] := NameEdit
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
;GuiControl,, FileEnabledCheck, % FileCheckEnabled
return

BrowseButton:
FileSelectFolder, newDirectory, % "*"directory
;Folder := RegExReplace(Folder, "\\$")
	if (newDirectory = "")
	{
	 return
	}
	if (newDirectory != directory)
	{
		if FileExist(displayFile)
		{
		 newDisplayFile := newDirectory "\--TransDisplayLog--.txt"
		 FileCopy, displayFile, newDisplayFile
		 FileDelete, % displayFile
		 displayFile := newDisplayFile
		}
	 FileAppend,, %displayFile%, UTF-8
	 directory := newDirectory
	 GuiControl,, FileEdit, %directory%
	}
return

TimestampCheck:
gui,submit,nohide ;updates gui variable
return

WindowGetButton:
Hotkey, $~LButton, on
Hotkey, ESC, on
ResetCurrentCursor()
settingTextOutputWindow := true
SetTimer, WatchCursor, 25
return

TransInputGetButton:
Hotkey, $~LButton, on
Hotkey, ESC, on
ResetCurrentCursor()
settingTextInputWindow := true
SetTimer, WatchCursor, 25
return

TransOutputGetButton:
Hotkey, $~LButton, on
Hotkey, ESC, on
ResetCurrentCursor()
settingTranslationOutputWindow := true
SetTimer, WatchCursor, 25
return

TransDisplayGetButton:
Hotkey, $~LButton, on
Hotkey, ESC, on
ResetCurrentCursor()
settingTranslatedTextDisplay := true
SetTimer, WatchCursor, 25
return

TransButtonGetButton:
Hotkey, $~LButton, on
Hotkey, ESC, on
ResetCurrentCursor()
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
SetTimer, WatchCursor, Off
detectingWindow := false
RangeTip()
ResetCurrentCursor()
MouseGetPos, , , id, control
MouseGetPos, xpos, ypos 
ToolTip
Hotkey, $~LButton, off
Hotkey, ESC, off
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
	 windowCopyID[currentMember] := active_id
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

GuiClose:
{
	if FileExist(displayFile)
	{
	 FileDelete, % displayFile
	}
	ExitApp
return
}