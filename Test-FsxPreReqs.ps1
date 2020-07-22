param(
    [Parameter(Mandatory)]
    [String]
    $DomainControllerIP = @()
)

# statics
$ports=@(
    "53",
    "88",
    "123",
    "135",
    "389",
    "445",
    "465",
    "636",
    "3269",
    "9389"
)
$failures = @();
$successes = @();

$x = 49152
while($x -le 65535){
    $ports += $x
    $x++
}
function refresh-path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") +
                ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}
function check-pstools(){
    if(!(get-command psping.exe)){
        Invoke-WebRequest -Uri "https://download.sysinternals.com/files/PSTools.zip"  -OutFile "pstools.zip"
        Expand-Archive "pstools.zip"
        $rootname = (Get-Item .\pstools\).FullName
        setx PATH "$env:path;$rootname" -m
        refresh-path
        Write-Host "Downloaded PSTools and added to PATH"
    }
    else{
        Write-Host "Command exists and is in path"
    }
}

foreach($DomainController in $DomainControllerIP){

    foreach($port in $ports){
        $lost = (psping.exe -n 1 -w 0 "$($DomainController):$($port)") -match "Lost = 1"
        if($lost){
            Write-Host "Failed Port: $port"
            $failures += $port
        }
        else{
            Write-Host "Port Succeeded: $port"
            $successes += $port
        }
    }

    Write-Host "Succeeded Ports for $DomainController :`n$successes" -ForegroundColor Yellow 
    "`n`n"
    Write-Host "Failed Ports for $DomainController :`n$failures" -ForegroundColor Red
}
