Mac OS has a bug where the audio drifts to the left under heavy cpu load. This
apple script plus wrapper allows it to be fixed on the command line.


1. Click System Preferences
1. Click Security & Privacy
1. Click Accessibility
1. Click the Lock to Unlock
1. Login with Your Password
1. Click the Plus Sign
1. Add Script Editor.app
1. Click the Plus Sign
1. Add Terminal.app
1. Open Apple Script Editor
1. Paste and save the contents of fix_audio_balance.scpt to your machine
1. Add a wrapper script to your $PATH (mine is called “fix_audio”, but you can
use “rebalance”)
/usr/bin/osascript ~/scripts/fix_audio.scpt

chmod +x the the wrapper script.
