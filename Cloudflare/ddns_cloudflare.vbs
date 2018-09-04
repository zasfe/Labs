' ***************************************************************************************
'  Cloudflare DDNS
'  Author   : myseit_at_gmail.com
'  Version  : v1.0
' ***************************************************************************************

Option Explicit
'On Error Resume Next

' Define needed constants
Const App_Name="cloudflare_ddns"

Dim StartTimer : StartTimer = Timer()
Dim CRLF, TAB :TAB  = CHR( 9 ):CRLF = CHR( 13 ) & CHR( 10 )
Dim debug_off : debug_off = True
Dim split_word : split_word = "==||=="
'debug_off = False


if wscript.arguments.Length > 0 then sType = wscript.arguments(0)
Dim sFolder_LocalName : sFolder_LocalName = Mid(WScript.ScriptFullName, 1, InStrRev(WScript.ScriptFullName,"\" )-1)
Dim strServerName : strServerName = WScript.CreateObject("WScript.Shell").ExpandEnvironmentStrings("%COMPUTERNAME%")
Dim strComSpec : strComSpec = WScript.CreateObject("WScript.Shell").ExpandEnvironmentStrings("%ComSpec%")
Dim strToday : strToday = date()
'********************************************************************

Const Resolve_url = "http://ipinfo.io/json"
Const Cloudflare_api_baseurl = "https://api.cloudflare.com/client/v4/"
Const Cloudflare_api_zone_name = "zasfe.com"
Const Cloudflare_api_zone_name_full = "ddns.zasfe.com"
Const Cloudflare_api_Global_API_Key = "fffffffffffffffffffff"
Const Cloudflare_api_Auth_Mail = "xxxx@xxxx.com"

Dim tmpLine, tmpValue
Dim oServer : set oServer = New cloudflare_value
Dim external_ip, zone_id
Dim url_api, url_param, url_return_json

wComment "Resolving external IP"
For each tmpLine in split(GET_HTTP(Resolve_url,"GET","",""), CRLF)
	If instr(tmpLine,"""ip""")>0 then
		oServer.external_ip = split(tmpLine,"""")(3)
	End if
Next
wComment "External IP is "& oServer.external_ip


wComment "Getting Zone information from CloudFlare"
url_api = Cloudflare_api_baseurl
url_api = url_api &"zones"
url_param = "name="& Cloudflare_api_zone_name  &"&status=active&page=1&per_page=20&order=status&direction=desc&match=all"

debug "- url : "& url_api &"?"& url_param
url_return_json = GET_CLOUDFLARE_API(url_api,"GET",url_param,"",Cloudflare_api_Global_API_Key,Cloudflare_api_Auth_Mail)
debug "- url return : "& url_return_json

tmpLine = ""
If instr(url_return_json, """name"":"""& Cloudflare_api_zone_name &"""")>0 then
	tmpLine = Left(url_return_json, instr(url_return_json, """name"":"""& Cloudflare_api_zone_name &"""")-1)
	tmpLine = Mid(tmpLine,InStrRev(tmpLine, ":"),Len(tmpLine))
	tmpLine = split(tmpLine, """")(1)
	oServer.zoneid = tmpLine
End if
wComment "Zone ID is "& oServer.zoneid


wComment "Getting Host information from CloudFlare"
url_api = Cloudflare_api_baseurl
url_api = url_api &"zones/" & oServer.zoneid & "/dns_records"
url_param = "" '"type=A&name=" & Cloudflare_api_zone_name

debug "- url : "& url_api &"?"& url_param
url_return_json = GET_CLOUDFLARE_API(url_api,"GET",url_param,"",Cloudflare_api_Global_API_Key,Cloudflare_api_Auth_Mail)
debug "- url return : "& url_return_json

tmpLine = ""
If instr(url_return_json, """name"":"""& Cloudflare_api_zone_name_full &"""")>0 then
	tmpLine = Left(url_return_json, instr(url_return_json, """name"":"""& Cloudflare_api_zone_name_full &"""")-1)
	tmpLine = Left(tmpLine,InStrRev(tmpLine, ":")-1)
	tmpLine = Mid(tmpLine,InStrRev(tmpLine, ":")+1,Len(tmpLine))
	tmpLine = split(tmpLine, """")(1)
	oServer.hostid = tmpLine
End if
wComment "Zone Host ID is "& oServer.hostid




wComment "Update Host information from CloudFlare"
url_api = Cloudflare_api_baseurl
url_api = url_api &"zones/" & oServer.zoneid & "/dns_records/"& oServer.hostid
url_param = "{""type"":""A"",""name"":"""& Cloudflare_api_zone_name_full &""",""content"":"""& oServer.external_ip &""",""ttl"":120,""proxied"":false}"

debug "- url : "& url_api
debug "- data : "& url_param
url_return_json = GET_CLOUDFLARE_API(url_api,"PUT",url_param,"",Cloudflare_api_Global_API_Key,Cloudflare_api_Auth_Mail)
debug "- url return : "& url_return_json

debug_off = False
tmpLine = ""
If instr(url_return_json, """name"":"""& Cloudflare_api_zone_name_full &"""")>0 then
	tmpLine = mid(url_return_json, instr(url_return_json, """name"":"""& Cloudflare_api_zone_name_full &""""), Len(url_return_json))
	tmpLine = Left(tmpLine, instr(tmpLine,"""proxiable""")-2)
	debug tmpLine
End if





' ###########################################################################################################



Function GET_CLOUDFLARE_API(sURL, pType, pValue,pCharset, pAuthkey, pAuthmail)
	Const adFldLong    = &H00000080
	Const adVarChar    = 200
	Const UserAgentText =  "Mozilla/4.0+(compatible;+MSIE+6.0;+Windows+NT+5.0;+Mozilla/4.0+(compatible;+MSIE+6.0;+Windows+NT+5.1;+SV1)+;+Maxthon;+.NET+CLR+2.0.50727)"
	Dim vType, charSet, lsResult

	select case Ucase(pType)
		case "POST"	: vType = "POST"
		case "PUT"	: vType = "PUT"
		case else	: vType = "GET"
	End select

	GET_CLOUDFLARE_API = ""
    'XMLHTTP를 이용하여 전송
    With CreateObject("Msxml2.ServerXMLHTTP")
	If vType = "GET" then
			.Open "GET", sURL&"?"&pValue, False
			.setRequestHeader "Content-type", "application/json"
			.setRequestHeader "X-Auth-Key", pAuthkey
			.setRequestHeader "X-Auth-Email", pAuthmail
			.setRequestHeader "User-Agent", UserAgentText
			.Send
		ElseIf vType = "POST" then
			.Open "POST", sURL, False
			.setRequestHeader "Content-type", "application/json"
			.setRequestHeader "X-Auth-Key", pAuthkey
			.setRequestHeader "X-Auth-Email", pAuthmail
			.setRequestHeader "User-Agent", UserAgentText
			.send pValue
		ElseIf vType = "PUT" then
			.Open "PUT", sURL, False
			.setRequestHeader "Content-type", "application/json"
			.setRequestHeader "X-Auth-Key", pAuthkey
			.setRequestHeader "X-Auth-Email", pAuthmail
			.setRequestHeader "User-Agent", UserAgentText
			.send pValue
		End if

 		While .readyState <> 4
 			.waitForResponse(8000)
 		Wend

 		If Err.Number = 0 Then
 			If .Status = 200 Then
				lsResult = .responseTEXT
 			End If

 		End If
    End With

		GET_CLOUDFLARE_API = lsResult
End Function


Function GET_HTTP (sURL, pType, pValue,pCharset)
    Dim     lsResult, charSet, vType, StartTime, EndTime
    Const adFldLong    = &H00000080
    Const adVarChar    = 200
	Const UserAgentText =  "Mozilla/4.0+(compatible;+MSIE+6.0;+Windows+NT+5.0;+Mozilla/4.0+(compatible;+MSIE+6.0;+Windows+NT+5.1;+SV1)+;+Maxthon;+.NET+CLR+2.0.50727)"

	select case Ucase(pType)
		case "GET"	: vType = "GET"
		case else	: vType = "POST"
	End select

	GET_HTTP = ""

    'XMLHTTP를 이용하여 전송
    With CreateObject("Msxml2.ServerXMLHTTP")
	If vType = "GET" then
			.Open "GET", sURL&"?"&pValue, False
			.setRequestHeader "Content-type", "text/xml"
			.setRequestHeader "Referer", sURL
			.setRequestHeader "User-Agent", UserAgentText
			.Send
		Else
			.Open "POST", sURL, False
			.setRequestHeader "Content-type", "application/x-www-form-urlencoded"
			.setRequestHeader "Referer", sURL
			.setRequestHeader "User-Agent", UserAgentText
			.send pValue
		End if

 		While .readyState <> 4
 			.waitForResponse(8000)
 		Wend

 		If Err.Number = 0 Then
 			If .Status = 200 Then
				charSet =  Lcase(.getResponseHeader("Content-Type"))
				If instr(Lcase(pCharset),"utf-8")>0 then
					lsResult = .responseTEXT
				Else
					lsResult = .responseBODY
				End if
 			End If

 		End If
    End With

	If Len(lsResult) =0 then Exit Function
    '받은 결과값을 한글 인코딩 처리
    With CreateObject("ADODB.Recordset")
        .Fields.Append "txt", adVarChar, LenB(lsResult), adFldLong
        .Open
        .AddNew
        .Fields("txt").AppendChunk lsResult
        GET_HTTP = .Fields("txt").Value
        .Close
    End With

    Set lsResult = Nothing
End Function

Class cloudflare_value
	Public external_ip
	Public zoneid
	Public hostid

	Private Sub Class_Initialize()
	End Sub

    Private Sub Class_Terminate()
    End Sub
End Class

Function wComment(msg)
	Wscript.StdOut.WriteLine msg
End Function




'********************************************************************
'* Sub Debug()
'********************************************************************
Sub	Debug(msg)
	If debug_off = false Then
		WScript.Echo "["& EndTimer() &"] "& msg
	end if
End Sub


Function EndTimer()
	EndTimer = FormatNumber(Timer() - StartTimer, 3)
End Function

Function EndTime()
  Dim EndTimer, Endmin, Endcho
  EndTimer	= Timer() - StartTimer
  Endmin		= int(EndTimer / 60)
  Endcho		= EndTimer - (Endmin*60)
  EndTime = Endmin &" min  "&Endcho&" sec"
End Function


'********************************************************************
'*                                                                  *
'*                           End of File                            *
'*                                                                  *
'********************************************************************

