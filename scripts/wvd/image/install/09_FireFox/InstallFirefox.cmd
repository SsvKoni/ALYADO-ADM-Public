cd /d %~dp0
msiexec /i "Firefox Setup 75.0.msi" TASKBAR_SHORTCUT=false DESKTOP_SHORTCUT=false START_MENU_SHORTCUT=false INSTALL_MAINTENANCE_SERVICE=false OPTIONAL_EXTENSIONS=false
pause
