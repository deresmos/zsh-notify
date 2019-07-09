#!/usr/bin/osascript

on run ttyName
    try 
        set ttyName to first item of ttyName
    on error
        set ttyName to ""
    end

    if ttyName is equal to "" then error "Usage: is-apple-terminal-active.applescript TTY"
	
	  tell application id "com.apple.terminal"
		  if frontmost is not true then error "Apple Terminal is not the frontmost application"

      if 0 is equal to count of (first tab of windows whose tty is ttyName and selected is true)
        error "Cannot find an active tab for '" & ttyName & "'"
      end
	  end tell
end run
