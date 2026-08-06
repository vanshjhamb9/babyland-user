# Keep USB cable connected, then run this so the phone can reach the PC Node server on port 5000.
# App base URL should be http://127.0.0.1:5000/api/v1 (see assets/.env).
adb reverse tcp:5000 tcp:5000
adb reverse --list
Write-Host "Phone can now call http://127.0.0.1:5000 via USB."
Write-Host "For Wi-Fi (http://192.168.1.5:5000) open an Admin PowerShell and run:"
Write-Host '  netsh advfirewall firewall add rule name="Babyland Node 5000" dir=in action=allow protocol=TCP localport=5000 profile=any enable=yes'
