@echo off
:: Requesting admin privileges
:checkPrivileges
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Please run this script as an administrator.
    pause
    exit /b
)

:: Setting default values
set port=3000
set action=create

:: Asking for port number with a default value
set /p userPort="Enter the port number (default is 3000): "
IF NOT "%userPort%"=="" SET port=%userPort%

:: Asking for create/delete action with a default value
set /p userAction="Do you want to create or delete the interface? (default is 'create'): "
IF NOT "%userAction%"=="" SET action=%userAction%

:: Set the name for the firewall rule
set ruleName=wsl%port%

IF /I "%action%"=="create" (
    :: Create interface using netsh command
    echo Creating port proxy on port %port%...
    netsh interface portproxy add v4tov4 listenport=%port% listenaddress=0.0.0.0 connectport=%port% connectaddress=172.28.156.132
    echo Port proxy created successfully for port %port%.

    :: Check if the firewall rule already exists
    netsh advfirewall firewall show rule name="%ruleName%" >nul 2>&1
    IF %ERRORLEVEL% NEQ 0 (
        :: Add firewall rule if it doesn't exist
        echo Adding firewall rule for port %port%...
        netsh advfirewall firewall add rule name="%ruleName%" dir=in action=allow protocol=TCP localport=%port%
        echo Firewall rule "%ruleName%" created successfully.
    ) ELSE (
        echo Firewall rule "%ruleName%" already exists. Skipping creation.
    )
) ELSE IF /I "%action%"=="delete" (
    :: Delete interface using netsh command
    echo Deleting port proxy on port %port%...
    netsh interface portproxy delete v4tov4 listenport=%port% listenaddress=0.0.0.0
    echo Port proxy deleted successfully for port %port%.

    :: Remove firewall rule if it exists
    netsh advfirewall firewall delete rule name="%ruleName%"
    IF %ERRORLEVEL% NEQ 0 (
        echo Firewall rule "%ruleName%" does not exist. Skipping deletion.
    ) ELSE (
        echo Firewall rule deleted successfully.
    )
) ELSE (
    echo Invalid action. Please enter 'create' or 'delete'.
)

pause
exit /b