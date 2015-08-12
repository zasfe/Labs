# http://blogs.technet.com/b/adnanezzi/archive/2010/07/30/vbscript-to-check-if-an-iis-certificate-is-going-to-expire.aspx

strComputer = "localhost"
SET objService = GetObject( "IIS://" & strComputer & "/W3SVC")
Set WshShell = WScript.CreateObject("WScript.Shell")
Dim StrVar0

EnumServersites objService

SUB EnumServersites( objSrv )
	FOR Each objServer IN objSrv
		IF objServer.Class = "IIsWebServer" Then
			IF NOT Ubound(objServer.SecureBindings) = "-1" Then

				'check to see if there is at least one securebinding
				WScript.Echo "Site ID = " & objServer.Name & VbCrLf & "Comment = """ & objServer.ServerComment
				wscript.Echo "SSL Certificate Expiration Date: " & GetSSLExpirationDate(objServer.Name)
				wscript.Echo "Days Remaining: " & DaysRemaining(GetSSLExpirationDate(objServer.Name))
				wscript.echo vbcrlf & "-----------------------------" & vbcrlf

				StrVar0 = ""
				if DaysRemaining(GetSSLExpirationDate(objServer.Name)) < 30 Then
					'wscript.echo "entered loop"
					StrVar0 = StrVar0 & "Site ID : " & objServer.Name & VbCrLf & "Comment : " & objServer.ServerComment & VbCrLf & "SSL Certificate Expiration Date : " &GetSSLExpirationDate(objServer.Name) & VbCrLf & "Days Remaining : " & DaysRemaining(GetSSLExpirationDate(objServer.Name))

					strCommand = "eventcreate /T Warning /ID 351 /L Application /SO CertWarning /D " & _
					Chr(34) & StrVar0 & Chr(34)
					WshShell.Run strcommand

				END IF
			END IF
		END IF
		strBindings = ""
	Next
END Sub

FUNCTION GetSSLExpirationDate( strSiteID )
	Set iiscertobj = WScript.CreateObject("IIS.CertObj")
	iiscertobj.serverName = "localhost"
	iiscertobj.InstanceName = "W3SVC/" & strSiteID

	tmpArray = Split(iiscertobj.GetCertInfo,vbLf)
	For Each x in tmpArray
		If Left(x,2) = "6=" Then
			GetSSLExpirationDate = Mid(x,3,len(x)-2)
		End If
	Next
END FUNCTION

Function DaysRemaining(strdate)
	If IsDate(strDate) Then
		strdate = cDate(strdate)
	End If
	DaysRemaining = DateDiff("d",Date,strdate)
End Function
