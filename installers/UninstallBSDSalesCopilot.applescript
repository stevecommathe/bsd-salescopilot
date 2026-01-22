-- BSD Sales Copilot Uninstaller
-- Double-click this app to uninstall

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
        set scriptPath to (text 1 thru -12 of posixFolder) & "uninstall-mac.sh"
    else
        set scriptPath to posixFolder & "uninstall-mac.sh"
    end if

    -- Confirm uninstall
    set dialogResult to display dialog "Uninstall BSD Sales Copilot?

This will remove:
• Text expansion shortcuts
• Background sync services
• Configuration files

Your Espanso installation will not be affected." buttons {"Cancel", "Uninstall"} default button "Cancel" with icon caution

    if button returned of dialogResult is not "Uninstall" then
        return
    end if

    -- Ask about logs
    set keepLogs to button returned of (display dialog "Keep log files for troubleshooting?" buttons {"Delete Logs", "Keep Logs"} default button "Keep Logs")

    -- Ask about config
    set keepConfig to button returned of (display dialog "Keep config file (contains API settings)?" buttons {"Delete Config", "Keep Config"} default button "Keep Config")

    -- Build the uninstall command with responses
    set uninstallCmd to "cd " & quoted form of (text 1 thru -12 of posixFolder)

    -- Run uninstall steps manually to avoid interactive prompts
    try
        -- Stop services
        do shell script "launchctl unload ~/Library/LaunchAgents/com.bsd.salescopilot.env.plist 2>/dev/null; true"
        do shell script "launchctl unload ~/Library/LaunchAgents/com.bsd.salescopilot.sync.plist 2>/dev/null; true"
        do shell script "launchctl unload ~/Library/LaunchAgents/com.bsd.salescopilot.snippetsync.plist 2>/dev/null; true"

        -- Remove plist files
        do shell script "rm -f ~/Library/LaunchAgents/com.bsd.salescopilot.*.plist"

        -- Remove symlinks from Espanso
        do shell script "
            ESPANSO_MATCH=\"$HOME/.config/espanso/match\"
            if [ ! -d \"$ESPANSO_MATCH\" ]; then
                ESPANSO_MATCH=\"$HOME/Library/Application Support/espanso/match\"
            fi
            for file in \"$ESPANSO_MATCH\"/*.yml; do
                if [ -L \"$file\" ]; then
                    target=$(readlink \"$file\")
                    if [[ \"$target\" == *\"bsd-salescopilot\"* ]]; then
                        rm \"$file\"
                    fi
                fi
            done
        "

        -- Unset environment variable
        do shell script "launchctl unsetenv BSD_COPILOT_PATH 2>/dev/null; true"

        -- Clean shell profile
        do shell script "
            for profile in \"$HOME/.zshrc\" \"$HOME/.bash_profile\" \"$HOME/.bashrc\"; do
                if [ -f \"$profile\" ]; then
                    sed -i '' '/# BSD Sales Copilot/d' \"$profile\" 2>/dev/null || true
                    sed -i '' '/BSD_COPILOT_PATH/d' \"$profile\" 2>/dev/null || true
                fi
            done
        "

        -- Remove logs if requested
        if keepLogs is "Delete Logs" then
            do shell script "rm -rf ~/Library/Logs/BSDSalesCopilot"
        end if

        -- Remove config if requested
        if keepConfig is "Delete Config" then
            if posixFolder ends with "installers/" then
                do shell script "rm -f " & quoted form of ((text 1 thru -12 of posixFolder) & "scripts/config.json")
            else
                do shell script "rm -f " & quoted form of (posixFolder & "scripts/config.json")
            end if
        end if

        -- Restart Espanso
        do shell script "espanso restart 2>/dev/null; true"

        display dialog "Uninstall Complete!

BSD Sales Copilot has been removed.

To reinstall, run the installer app again." buttons {"OK"} default button "OK" with icon note

    on error errMsg
        display dialog "Uninstall encountered an issue:

" & errMsg buttons {"OK"} default button "OK" with icon caution
    end try
end run
