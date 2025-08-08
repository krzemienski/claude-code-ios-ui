import Foundation

let bundleID = "com.claude.ClaudeCodeUI"
let deviceID = "69E17196-0509-48B3-ABF5-478B9887BB5B"

// Use simctl to list running apps
let listProcess = Process()
listProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
listProcess.arguments = ["simctl", "listapps", deviceID]

let pipe = Pipe()
listProcess.standardOutput = pipe

try\! listProcess.run()
listProcess.waitUntilExit()

// Send tap event using private API workaround
print("Attempting to tap on Claude Code UI project...")

// Use AppleScript to interact with the simulator
let script = """
tell application "Simulator"
    activate
end tell

delay 0.5

tell application "System Events"
    tell process "Simulator"
        set frontmost to true
        click at {360, 536}
    end tell
end tell
"""

let appleScript = Process()
appleScript.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
appleScript.arguments = ["-e", script]
try\! appleScript.run()
appleScript.waitUntilExit()

print("Tap command sent")
