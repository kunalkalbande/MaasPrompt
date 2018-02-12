<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>


<script runat="server">

    Dim jsonRes As String = ""
    Dim outres As String = ""
    Dim outresR As String
    Dim prjid As String = ""
    Dim iterateTF As Boolean
    Dim iters As Integer
    Dim i, j, k, l, m As Integer
    Dim DataArray() As String
    Dim StringArray() As Object
    Dim valArray() As String
    Dim newrec As Boolean = True
    Dim Queries() As String
    Dim QueriesColumn() As String
    Dim QueriesValue() As String
    Dim currentindex As String
    Dim currentElement() As String
    Dim tmp() As String
    Dim part1 As String
    Dim part2 As String
    Dim valicdata(11) As String
    Dim lastUpdateBy As String = ""
    
    
    Dim occ As String = ""

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs)

        lastUpdateBy = Session("LastUpdateBy")
        outres = Request("data")
        outres = Replace(outres, "{", "")
        outres = Replace(outres, "}", "")
        
        prjid = Request("projectid")
        iterateTF = Request("iterate")
        iters = Request("iteration")
        DataArray = Split(outres, ",")
        outres = ""
        ReDim Queries(UBound(DataArray))
        ReDim QueriesColumn(UBound(DataArray))
        ReDim QueriesValue(UBound(DataArray))
        For i = 0 To UBound(DataArray)
            StringArray = Split(DataArray(i), ":")
            StringArray(0) = MyReplace(StringArray(0), """", "")
            StringArray(1) = MyReplace(StringArray(1), "&amp;", "''")
            StringArray(1) = MyReplace(StringArray(1), "&bar;", ":")
            StringArray(1) = MyReplace(StringArray(1), "&comma;", ",")
            StringArray(1) = MyReplace(StringArray(1), "&crlf;", vbCrLf)
            StringArray(1) = MyReplace(StringArray(1), """", "'")
            StringArray(1) = MyReplace(StringArray(1), "&quot;", """")
            Queries(i) = StringArray(0) & "=" & StringArray(1)
            QueriesColumn(i) = StringArray(0)
            QueriesValue(i) = StringArray(1)
        Next

        'David D 9-22-17 added below to handle save vs record new iteration (Pulling boolean from js file savePEP function passing in POSTDATA        
        If iterateTF = True Then
            outres = "INSERT INTO pep (projectid," & Join(QueriesColumn, ",") & ",lastupdateon,lastupdateby) values(" & prjid & "," & Join(QueriesValue, ",") & ",'" & Now() & "'," & "'" & lastUpdateBy & "')"
            outresR = "UPDATE pep SET " & Join(Queries, ",") & ", lastupdateon='" & Now() & "', lastupdateby='" & lastUpdateBy & "' WHERE projectId=" & prjid & " and iteration=0"
            Dim outresZ As String = ""
            outresZ = Replace(outresR, "iteration='" & iters & "'", "iteration='0'")
            outres = outres & "; " & outresZ
            Session("iteration") = iters
        Else            
            outresR = "UPDATE pep SET " & Join(Queries, ",") & ", lastupdateon='" & Now() & "', lastupdateby='" & lastUpdateBy & "' WHERE projectId=" & prjid & " and iteration=0"
            Dim outresZ As String = ""
            outresZ = Replace(outresR, "iteration='" & iters & "'", "iteration='0'")
            outres = outresZ
        End If
        
        outres = saveDBL(outres)

        Session("IterateTF") = "" '"outres =" & outres '"iterate = " & iterateTF & "  POST-iterationNo= " & iters '& Session= " & Session("iteration") 'testing for dev - comment out when done, and lblMessage in pep page as well.
        
       
    End Sub

    
    Private db As PromptDataHelper
    Public Function saveDBL(ByRef qry As String) As String
      
        Dim res As New PromptDataHelper

        With res

            res.ExecuteNonQuery(qry)
            outres &= "<br> " & qry
        End With
        Return ""

    End Function

    Public Function MyReplace(ByRef where As String, ByRef what As String, ByRef towhat As String) As String
        Dim strlen As Integer
        Dim pos As Integer
        Dim handled As String
        Dim buffer As String
        Dim therest As String
        Dim buflen As Integer
        
        
        strlen = Len(where)
        If strlen < 255 Then
            Return Replace(where, what, towhat)
        End If
        
        'Return """length = " & strlen & """ "
        pos = 0 'length of already handled part of string...
        While pos < strlen - 9
            handled = Left(where, pos)
            If strlen - pos > 240 Then
                buflen = 240
            Else
                buflen = strlen - pos
            End If
            buffer = Mid(where, pos + 1, buflen)
            therest = Mid(where, pos + 1 + buflen)
            buffer = Replace(buffer, what, towhat)
            buflen = Len(buffer)
            pos = pos + buflen - 7 'if some substr to replace was splitted
            where = handled & buffer & therest
            strlen = Len(where)
        End While 'main loop done
        Return where
        
    End Function
        
        
</script>

<%=outRes%>

