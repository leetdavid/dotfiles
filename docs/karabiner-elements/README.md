# Karabiner Elements Complex Modifications

The JSON files here are meant to be used with Karabiner Elements.

It will:
- Map your Caps Lock key to a Hyper key (Control + Option + Command).
- Map Hyper+1,2,3 to F1, F2, F3...
- Map Hyper+WASD to arrow keys, Hyper+Q/E to Cmd+Left/Right, Hyper+R/F to PgUp/PgDown
- Map right Command+I/O/P/[ to the English, Korean, Japanese and Chinese input sources.

## Input source rule

`right-command-input-source.json` sends macOS's own input source keys (英数, かな, and F20 as "Select next source in Input menu"), so the frontmost app performs the switch itself. Switching from outside the app (BetterTouchTool's "Change Input Source", Karabiner's `select_input_source`) leaves the menu bar and the typed language out of sync.

The rule needs "Select next source in Input menu" bound to a bare F20:

```sh
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>90</integer><integer>0</integer></array><key>type</key><string>standard</string></dict></dict>'
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
```

Korean and Chinese are reached by pressing "next" from Hiragana, so the rule assumes the cycle order U.S. → Hiragana → 2-Set Korean → Pinyin. Adjust the number of `f20` presses if the input sources change.

The last manipulator makes right Command lazy. Without it Karabiner releases right Command before sending the keys, and a "tap right Command" trigger in BetterTouchTool fires on every chord.


## Usage

Open Karabiner Elements, and go to the "Complex Modifications" tab. Click "Add your own rule", then paste the contents of the file for each rule.
