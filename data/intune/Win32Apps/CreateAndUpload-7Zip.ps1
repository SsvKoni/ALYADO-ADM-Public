. $PSScriptRoot\..\..\..\01_ConfigureEnv.ps1

& "$($AlyaScripts)\intune\Create-IntuneWin32Packages.ps1" -CreateOnlyAppWithName "7Zip"
& "$($AlyaScripts)\intune\Upload-IntuneWin32Packages.ps1" -UploadOnlyAppWithName "7Zip"
& "$($AlyaScripts)\intune\Configure-IntuneWin32Packages.ps1" -UploadOnlyAppWithName "7Zip"
