# Brings Roblox Studio to the front. Studio stops drawing the 3D world while it's behind other
# windows, so screen captures over MCP come back white until it's focused.
$sig = '[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
Add-Type -MemberDefinition $sig -Name W -Namespace Win
$p = Get-Process RobloxStudioBeta | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if ($p) { [Win.W]::ShowWindow($p.MainWindowHandle, 9) | Out-Null; [Win.W]::SetForegroundWindow($p.MainWindowHandle) | Out-Null }
