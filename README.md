<img src="https://github.com/Faxanadus/TransTrans/blob/main/ttlogo.png" width="128" />

**# Trans/Trans (Transcription/Translation)**

Transcription and Translation facilitation application.

This app can combine a separate transcription app and translation app together, and display the output from both in yet another app or save to a log file, if needed.

First, you will need to specify the source area for your transcribed text by clicking the 'Set Participant Output Area' button.
A tooltip message under your mouse cursor will appear, showing which window the mouse is hovering over.  Up to nine participant output areas can be set, all potentially from different applications. Click on the area where the text will be shown and the title of the window will be updated. If this app can grab text directly from that text area the name of the text area will be shown after the window title and a forward slash.  For example: "Notepad / Edit1" where "Edit1" is the name of the text area.

If the text cannot be grabbed from directly from memory, a manual function will be used that sends mouse or keyboard commands and uses your copy/paste clipboard to grab the text. These manual methods are slower, and will pause when necessary to avoid interrupting your own keyboard or mouse usage.

If you are using a different translation app than the defaults shown under the "App Setup" button, you will need to specify the text input area, the translation output area, and the translate button of that translation app (if present). This can be done in the same manner as the first step by clicking the corresponging button in this app and then clicking the needed text areas and button of the translation app.

This app automatically generates and continuosly updates a text file named with -DisplayLog.txt in the script's own directory, or the directory set using the Browse button, on startup.  This file is intended to be used by text readers (such an OBS Text(GDI+) Source) so the final output can be shown.  Optionally, a separate app text display area can be set up under the App Setup button.  If you are using an OBS Text(GDI+) Source, be sure to specify the -DisplayLog.txt file location in the source properties and use the "Chatlog Mode" option, setting the "Chatlog Line Limit" as needed.

**Limitations**:
Being based on Autohotkey, this app may not be able to grab text from applications such as web browsers or applications based off of web browsers, and works best when it can grab text directly from windows/memory.  If the app cannot grab the text directly, the manual method using simulated keyboard and mouse button presses may still work, and while effort has been made to prevent interruptions (by swapping to the mouse method if you are using copy and paste keys on the keyboard, or swapping to the keyboard method if you are dragging around applications that are in-use by this app) interruptions may still happen as these manual methods rely on simulated mouse clicks and keyboard button presses.

If you would like to run the script directly from the .ahk file rather than the pre-compiled .exe, you'll need to download and install Autohotkey v1 from: https://www.autohotkey.com/download/ahk-install.exe

**Areas for improvement**:
+Add alternate language translations for instructions, GUI, and tooltips with automatic language detection based on OS language or selectable via Options.
+Improve text grabbing capability to reduce the need to use simulator mouse clicks or keyboard button presses when a viable control area cannot be found.

5/18/24 Version 15 Update: 
+Alternate text grabbing method implemented via IUIAutomationElements. (http://msdn.microsoft.com/en-us/library/windows/desktop/ee671425(v=vs.85).aspx)
     -Credit to Descolada for the AHK implementation: https://github.com/Descolada/UIAutomation
+Added line splitting/queueing for each user.

5/8/24 Version 14 Update: Added network functionality.
+Receive and send strings (with optional unique line IDs) to other applications via IP/Port
     -Line IDs can be sent within each string, or as a separate comma separated integer as Big Endian or Little Endian.
+Added option to send a message address with each message so a receiving application (such as one using the OSC protocol) can direct messages to the right function.
+Option to send all transcribed/translated content intended for display via IP/Port, either all at once, or as individual lines.
+Added ability to save all settings on app close.
+Added checkbox to use or not use the -DisplayLog.txt file (intended for use with text parsers).

4/28/24 Version 13 Update: 
+Added colored bounding boxes when to help show the text areas/controls to click on when selecting output/input windows and buttons.
