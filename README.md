# macOS-SMJobBless-Lazarus-Pascal
How to create an privileged Helper Tool under macOS, with [Lazarus Pascal](https://www.lazarus-ide.org/), to get root acces in your application.

A full description and a ton of information can be found on my homepage: 

**English**: [MacOS - SMJobBless: Elevated Privileges in Lazarus Pascal](https://www.tweaking4all.com/software-development/lazarus-development/macos-smjobbless-elevated-privileges-lazarus-pascal/ "Tweaking4All - The main article I wrote about")

**Dutch**: [MacOS - SMJobBless: Elevated Privileges met Lazarus Pascal](https://www.tweaking4all.com/software-development/lazarus-development/macos-smjobbless-elevated-privileges-lazarus-pascal/ "Tweaking4All - Het hoofd artikel wat ik hierover heb geschreven")

## SmJoBBless and Elevated Privileges Helper Tool Example ##

***Purpose:***

Simple example to create a Privileged Helper Tool using Lazarus Pascal, so your application can get root access by using such a Helper Tool.

***Requirement:***

A valid Apple Developer ID in order to sign the app bundle and the Helper Tool.

***Tested and created with:***

Lazarus 2.1.0 r60620M FPC 3.0.4 x86_64-darwin-cocoa (alpha) from SVN.


## Before you start ##

1. Replace "**XXXXXXXXXX**" with your Developer ID in these files:

***SMJobBlessTest/project1.app/Contents/Info.plist***

***SMJobBlessTest/Helper/SMJobBlessHelper-Info.plist***

2. Replace "**John Doe (XXXXXXXXXX)**" with your Developer info in this file:

***SMJobBlessTest/prepareproject1.sh***

3. Open the **com.tweaking4all.SMJobBlessHelper.lpi** project in Lazarus and compile it with "**Build**".

4. Open the **project1.lpi** in Lazarus and compile it with "**Build**".

5. in Terminal, go to the "**SMJobBlessTest**" directory and run "**./prepareproject.sh**"

Optionally verify with
```bash
./SMJobBlessUtil.py check project1.app
```

6. Open **Console** (Applications/Utilities) and set the filter to "**SMJOBBLESS**"

7. Run **project1.app** (or project1) from the "**SMJobBlessTest**" directory.

- "**Initialize**" will initialze and optionally install the Helper Tool
- "**Start Complicated**" will start a process that keeps putting timestamps in the log
- "**Is Active?**" will show if it's active or not
- "**Abort Complicated**" will stop the time stamping
- "**Last Error**" will just show a dummy message
- "**Get Version**" will show the current Helper Version
- "**Quit Helper**" will terminate the Helper tool


## Clean up: ##

### Remove Helper Tool ###
(Caution: this may not be the appropriate method)

```bash
sudo rm /Library/PrivilegedHelperTools/com.tweaking4all.SMJobBlessHelper
```

### Kill running Helper Tool ###
(Caution: this may not be the appropriate method)

```bash
ps -ax | grep com.tweaking4all
sudo kill -9 <PID>
```

Where `<PID>` is the PID from the "ps" line that had "com.tweaking4all.SMJobBlessHelper" in it.
