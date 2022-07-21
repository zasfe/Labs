$slackChannel = "#knh_test"
$slackBotName = "RDP-login-Alert"
$slackKey = "xxxxx/xxxxx"
# example: https://hooks.slack.com/services/$slackKey 

$DataCollected = Get-Winevent -MaxEvents 1 -FilterHashTable @{ LogName = "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"; Id = 21,25}
$MessageSplit = $DataCollected.Message.Split("`n")
$UserLogged = ($MessageSplit[2].Split(":"))[1].Trim().Split("\")[1].Trim()
$UserIP = ($MessageSplit[4].Split(":"))[1].Trim()

$public_ip=(Invoke-RestMethod -uri "https://api.ip.pe.kr/json/" -UseBasicParsing).ip
$private_ip=(Test-Connection -ComputerName $env:computername -count 1).IPv4Address.IPAddressToString
$region=(Invoke-RestMethod -uri "https://api.ip.pe.kr/json/" -UseBasicParsing).country_name.en
$country_code=(Invoke-RestMethod -uri "https://api.ip.pe.kr/json/" -UseBasicParsing).country_code
$instance_name = $env:computername
$stream_name="$instance_name (private $private_ip  /  public $public_ip)"
$Message="Windows login to {0}{1}{2}" -f "*``","$public_ip","``*"

$Payload = @"
payload={
    "channel" : "$slackChannel",
	"mrkdwn": true, 
    "username": "$slackBotName",
    "icon_emoji": ":dark_sunglasses:", 
    "attachments": [
        {
			"mrkdwn_in": ["text", "fallback"],
            "color": "#F35A00",
            "fallback": "$Message",
            "text": "$Message",
            "fields": [
                {
                    "title": "User",
                    "value": "$UserLogged",
                    "short": true
                },
                {
                    "title": "UserIP",
                    "value": "$UserIP",
                    "short": true
                }
            ]
        }
    ]
}
"@

if ($slackKey)
{
	try {
		#send message to slack always.
		Invoke-RestMethod -Uri "https://hooks.slack.com/services/$slackKey" -Method Post -Body $Payload
	} 
	catch {
		$streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
		$ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json
		$streamReader.Close()
	}

	$ErrResp
	
}


#### End Script
