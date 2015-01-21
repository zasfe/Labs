Public Function Encode_UTF8(source)

Const adTypeBinary = 1
Dim adoStr, bytesthroughado
Set adoStr = CreateObject("Adodb.Stream")
    adoStr.Charset = "utf-8"
    adoStr.Open
    adoStr.WriteText source
    adoStr.Position = 0 'reset position
    adoStr.Type = adTypeBinary
    adoStr.Position = 3 'skip bom
    
    bytesthroughado = adoStr.Read 'get bytes
    adoStr.Close
Set adoStr = Nothing

ConvertUTF8String = ""
a=CByte(0)
b=CByte(0)
c=CByte(0)
For intCounter = 1 to LenB(bytesthroughado)
  a= AscB(MidB(bytesthroughado , intCounter, 1))
  if a > &HE0 Then
    ia = a 
	ib = AscB(MidB(bytesthroughado , intCounter+1, 1)) 
	ic = AscB(MidB(bytesthroughado , intCounter+2, 1)) 
	'stdout.WriteLine "0.1)" & ia & " " & ib & " " & ic
	ia = &H1000 * (ia and &H0F )+ &H40 * (ib and &H3F) + (ic and &H3F)
	
	ConvertUTF8String = ConvertUTF8String &"\u"& Right("0" & LCase(Hex(ia)), 4)
	'stdout.WriteLine "1)" & intCounter & " -> " & a & " => " & ia & " " & Right("0" & Hex(ia), 4)
	intCounter = intCounter +2
  elseIf a > &HC0 Then
	ia = a
	ib = AscB(MidB(bytesthroughado , intCounter+1, 1)) 
	ia = &H20 * (ia and &H1F) + (ib and &H3F)
	
	ConvertUTF8String = ConvertUTF8String &"\u"& Right("0" & LCase(Hex(ia)), 4)
	'stdout.WriteLine "2)" & intCounter & " -> " & a & " => " & ia & " " & ConvertUTF8String
	intCounter = intCounter +1
  elseif a > &H7F Then
	'stdout.WriteLine "3)" & intCounter & " -> " & a
	ConvertUTF8String = ConvertUTF8String &"\u"& Right("0" & LCase(Hex(a)), 4)
  else
    'stdout.WriteLine "4)" & intCounter & " -> " & a
	ConvertUTF8String = ConvertUTF8String & Chr(a)
  
  end if
Next
    Encode_UTF8 = ConvertUTF8String
    Set ConvertUTF8String = Nothing
End Function
