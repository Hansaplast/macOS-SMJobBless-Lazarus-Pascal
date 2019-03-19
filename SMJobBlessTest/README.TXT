SMJOBBLESS TEST FOR LAZARUS PASCAL

Purpose:
Simple example to create a Privileged Helper Tool using Lazarus Pascal.


Requirement: Valid Apple Developer ID
Tested with: Lazarus 2.1.0 r60620M FPC 3.0.4 x86_64-darwin-cocoa (alpha)


Before you start:

1. Replace "XXXXXXXXXX" with your Developer ID in these files:

SMJobBlessTest/project1.app/Contents/Info.plist
SMJobBlessTest/Helper/SMJobBlessHelper-Info.plist

1. Replace "John Doe (XXXXXXXXXX)" with your Developer info in this file:

SMJobBlessTest/prepareproject1.sh

2. Open the com.tweaking4all.SMJobBlessHelper.lpi project in Lazarus and compile it with "Build".

3. Open the project1.lpi in Lazarus and compile it with "Build".

4. in Terminal, go to the "SMJobBlessTest" directory and run "./prepareproject.sh"
   Optionally verify with "./SMJobBlessUtil.py check project1.app"

5. Open Console (Applications/Utilities) and set the filter to "SMJOBBLESS"

6. Run project1.app (or project1) from the "SMJobBlessTest" directory.

- Click "Initialize" to install the Helper Tool
- "Start Complicated" will start a process that keeps putting timestamps in the log
- "Is Active?"" will show if it's active or not
- "Abort Complicated" will stop the time stamping
- "Last Error" will just show a dummy message
- "Get Version" will show the current Helper Version
- "Quit Helper" will terminate the Helper tool



*** Clean up: ***

-> remove Helper Tool:

sudo rm /Library/PrivilegedHelperTools/com.tweaking4all.SMJobBlessHelper



-> Kill running task:

ps -ax | grep com.tweaking4all
sudo kill -9 <PID>

Where <PID> is the PID from the "ps" line that had com.tweaking4all.SMJobBlessHelper in it.