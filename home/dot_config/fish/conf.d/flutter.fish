set -gx JAVA_HOME $HOME/development/jdk21
set -gx ANDROID_HOME $HOME/Android/Sdk
set -gx CHROME_EXECUTABLE (command -v chromium google-chrome-stable 2>/dev/null | head -1)
fish_add_path -g $HOME/development/flutter/bin $ANDROID_HOME/cmdline-tools/latest/bin $ANDROID_HOME/platform-tools $ANDROID_HOME/emulator
