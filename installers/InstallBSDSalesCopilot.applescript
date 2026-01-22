-- BSD Sales Copilot Installer
-- Double-click this app to install

on run
    -- Get the path to this app's parent directory
    tell application "Finder"
        set appPath to (path to me) as text
        set appFolder to (container of (path to me)) as text
    end tell

    -- Convert to POSIX path
    set posixFolder to POSIX path of appFolder

    -- Check if running from installers folder (development) or root (distribution)
    if posixFolder ends with "installers/" then
        set scriptPath to (text 1 thru -12 of posixFolder) & "install-mac-silent.sh"
    else
        set scriptPath to posixFolder & "install-mac-silent.sh"
    end if

    -- Check if Espanso is installed
    try
        do shell script "command -v espanso"
    on error
        set dialogResult to display dialog "Espanso is not installed.

Espanso is a free text expander that BSD Sales Copilot requires.

Click 'Download Espanso' to open the download page, install it, then run this installer again." buttons {"Cancel", "Download Espanso"} default button "Download Espanso" with icon caution

        if button returned of dialogResult is "Download Espanso" then
            open location "https://espanso.org/install/"
        end if
        return
    end try

    -- Show starting dialog
    display dialog "BSD Sales Copilot Installer

This will set up text expansion shortcuts for the BSD sales team.

Click Install to continue." buttons {"Cancel", "Install"} default button "Install" with icon note

    -- Run the install script
    try
        set installResult to do shell script "bash " & quoted form of scriptPath

        if installResult contains "SUCCESS" then
            display dialog "Installation Complete!

BSD Sales Copilot is now ready to use.

Try it out:
• Type ;hi in any app for a greeting
• Type ;reply with text copied to get an AI response

Shortcuts will automatically update in the background." buttons {"OK"} default button "OK" with icon note
        else if installResult contains "ESPANSO_NOT_FOUND" then
            display dialog "Error: Espanso not found.

Please install Espanso first from:
https://espanso.org/install/" buttons {"OK"} default button "OK" with icon stop
        else if installResult contains "PYTHON_NOT_FOUND" then
            display dialog "Error: Python 3 not found.

Please install Python 3 first." buttons {"OK"} default button "OK" with icon stop
        else
            display dialog "Installation encountered an issue.

Check the log at:
~/Library/Logs/BSDSalesCopilot/install.log" buttons {"OK"} default button "OK" with icon caution
        end if

    on error errMsg
        display dialog "Installation failed:

" & errMsg & "

Check the log at:
~/Library/Logs/BSDSalesCopilot/install.log" buttons {"OK"} default button "OK" with icon stop
    end try
end run
