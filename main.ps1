# Installera dbatools om det inte redan är installerat
if (-not (Get-Module -ListAvailable -Name dbatools)) {
    Install-Module dbatools -Force
}

# Definiera server och sessionnamn
$serverName = 'ServerName'
$sessionName = 'LockEscalationSession'

# Funktion för att köra Extended Event Session
function Run-XESession {
    param (
        [string]$serverName,
        [string]$sessionName,
        [int]$duration
    )

    # Skapa en ny Extended Event Session för lock escalations
    New-DbaXESession -SqlInstance $serverName -SessionName $sessionName -Event 'sqlserver.lock_escalation' -Target 'ring_buffer'

    # Starta sessionen
    Start-DbaXESession -SqlInstance $serverName -SessionName $sessionName

    # Vänta en viss tid för att fånga händelser
    Start-Sleep -Seconds $duration

    # Stoppa sessionen
    Stop-DbaXESession -SqlInstance $serverName -SessionName $sessionName

    # Hämta och visa fångade händelser i Out-GridView
    $events = Get-DbaXESessionTarget -SqlInstance $serverName -SessionName $sessionName -TargetType 'ring_buffer'
    $events | Out-GridView
}

# Starta jobbet med tidsstämplar
$job = Start-Job -ScriptBlock {
    $startTime = Get-Date
    Write-Output "Job started at: $startTime"

    Run-XESession -serverName 'ServerName' -sessionName 'LockEscalationSession' -duration 60

    $endTime = Get-Date
    Write-Output "Job ended at: $endTime"
}

# Vänta på att jobbet ska slutföras och visa resultat
Wait-Job -Job $job
Receive-Job -Job $job
