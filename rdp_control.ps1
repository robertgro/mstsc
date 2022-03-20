$config = Get-Content ./rdp_control.cfg.json | ConvertFrom-Json
$clients = @()

function UpperFirstLetter{
    param (
        [string] $word
    )
    process {
        return ($word.Substring(0,1).ToUpper() + $word.Substring(1))
    }
}

foreach($item in $config.clients.PSObject.Properties) {
    #Write-Host "Item-Name: " $item.Name
    #Write-Host "Item-Value: " $item.Value
    $client = [PSCustomObject]@{ClientID = $item.Name }
    $item.Value.PSObject.Properties | ForEach-Object { $client | Add-Member -MemberType NoteProperty -Name $(UpperFirstLetter($_.Name)) -Value $_.Value }
    #https://stackoverflow.com/questions/51451148/uppercase-only-first-two-letters-of-all-filenames-in-a-folder
    #https://stackoverflow.com/questions/54661402/how-to-dynamically-add-new-properties-to-custom-object-in-powershell
    $clients += $client
}
do {
    Write-Host #empty line
    Write-Host " RDP CLIENT SELECTION " -ForegroundColor Cyan
    Write-Host
    for($i=0; $i -lt $clients.Length; $i++) {
        (ping -n 1 -w 100 $clients[$i].Ip 2>&1) | Out-Null
        $responseCode = $LASTEXITCODE
        Write-Host "`t$($i+1). $($clients[$i].ClientID)" -ForegroundColor Cyan
        if($responseCode -eq 0) {
            Write-Host "`t`tStatus: $($clients[$i].Hostname) ONLINE" -ForegroundColor Green
        } else {
            Write-Host "`t`tStatus: $($clients[$i].Hostname) OFFLINE" -ForegroundColor DarkRed
        }
    }
    Write-Host #empty line
    try {
        $answer = (Read-Host 'Select an RDP Client to connect to') -as [int]
        Write-Host #empty line
    } catch {
        Write-Error "Please specify a valid number and hit [Enter] key"
    }

} While ((-not($answer)) -or (0 -gt $answer) -or ($clients.Count -lt $answer))

$answer -= 1

Write-Host
Write-Host "Trying to connect to $($clients[$answer].ClientID)..." -ForegroundColor Yellow
Write-Host

if (!($ip = Read-Host "Target PC [Default $($clients[$answer].Hostname)/$($clients[$answer].Ip)]")) { $ip = $($clients[$answer].Ip) }
if (!($shadow = Read-Host "Shadow Session? [Y] [N] [Default $($clients[$answer].Shadow)]")) { $shadow = [string]::Empty }
if (!($fullscreen = Read-Host "Fullscreen? [Y] [N] [Default $($clients[$answer].Fullscreen)]")) { $fullscreen = [string]::Empty }
if (!($control = Read-Host "Control Session? [Y] [N] [Default $($clients[$answer].Control)]")) { $control = [string]::Empty }
if (!($prompt = Read-Host "No consent prompt? [Y] [N] [Default $($clients[$answer].Noconsentprompt)]")) { $prompt = [string]::Empty }

$cmd = "mstsc /v:$ip"
$id = [string]::Empty

if($shadow -and ($shadow -match "[Yy]")) {
    $id = (query user /server:$ip)[1] -split "\s+"
    $cmd += " /shadow:$($id[3])"
} else {
    if($clients[$answer].Shadow -and ($shadow -notmatch "[Nn]")) {
        $id = (query user /server:$ip)[1] -split "\s+"
        $cmd += " /shadow:$($id[3])"
    }
}

if($fullscreen -and ($fullscreen -match "[Yy]")) {
    $cmd += " /f"
} else {
    if($clients[$answer].Shadow -and ($fullscreen -notmatch "[Nn]")) {
        $cmd += " /f"
    }
}

if($control -and ($control -match "[Yy]")) {
    $cmd += " /control"
} else {
    if($clients[$answer].Shadow -and ($control -notmatch "[Nn]")) {
        $cmd += " /control"
    }
}

if($prompt -and ($prompt -match "[Yy]")) {
    $cmd += " /noConsentPrompt"
} else {
    if($clients[$answer].Shadow -and ($prompt -notmatch "[Nn]")) {
        $cmd += " /noConsentPrompt"
    }
}
Write-Host
Write-Host "Invoking expression '$cmd' now" -ForegroundColor Green
Invoke-Expression $cmd
Write-Host