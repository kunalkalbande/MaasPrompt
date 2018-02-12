<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>


<script runat="server">

    Dim Out() As Hashtable
    Dim prjid As String = ""
    Dim iters As Integer
    Dim prjcounter As String = ""
    Dim prjsql As String = "SELECT COUNT(*) FROM pep WHERE projectid="
    Dim jsonRes As String = ""
    Dim Tab As DataTable
    Dim indicdata() As String = {"campus", "revdate", "initdate", "iteration", "prjname", "prjnumber", "pribudget", "pccs", "pcds", "rrds", "pvs", "sds", "dds", "cds", "dsas", "pcs", "cs", "ffes", "os", "cos", "pccp", "pcdp", "rrdp", "gmps", "pvp", "sdp", "ddp", "cdp", "dsap", "pcp", "cp", "ffep", "op", "cop", "gmpp", "aor", "aorco", "cm", "cmco", "ior", "xtra1", "xtra2", "xtra3", "xtra4", "xtra5", "aorsc", "aorcosc", "cmsc", "cmscco", "iorsc", "xtras1", "xtras2", "xtras3", "xtras4", "xtras5", "aord", "aorcod", "cmd", "cmdco", "iord", "xtrad1", "xtrad2", "xtrad3", "xtrad4", "xtrad5", "xtrat0", "xtrat1", "xtrat2", "xtrat3", "xtrat4", "xtrat5", "xtrat6", "xtrat7", "xtrat8", "xtrat9", "notes", "po1", "po2", "po3", "po4", "po5", "po6", "po7", "po8", "po9", "po10"}
    Dim frompep() As Hashtable
    Dim size As Integer
    Dim ii As Integer
    Dim jj As Integer = 0
    Dim j As Integer
    Dim kk As Integer = -1
    Dim ch As Integer = -1
    Dim sect As Integer = -1
    Dim itemc As Integer = -1
    Dim occ As String = ""
    Dim amount As String
    Dim outjson() As String
    Dim minIter As Integer = 0

    Dim line As String
    Private Sub Page_Load()
        Dim resprj As New PromptDataHelper
        Dim arr() As String = {"", ""}
        prjid = Request("projectid")
        prjsql &= prjid
        iters = Session("iteration")
        With resprj
            .FillReader(prjsql)
            While .Reader.Read
                If Not IsDBNull(.Reader(arr(0))) Then
                    prjcounter = .Reader(arr(0))
                End If
            End While
            .Reader.Close()
        End With
        
        
        
        If (prjcounter = 0) Then
            makeNewProject(prjid)
        End If
        
        'David D 9-28-17 added below getMinIteration() and minIter to handle initial release with no iteration 0 that acts as the Draft in pep.aspx.  If there are iterations, but no draft found, this will create a Draft record. The prjcounter handles "New" projects and setting the initial draft
        getMinIteration()
        
        
        ReDim Out(0)

        jsonRes = getDBL("pep", indicdata, prjid, iters)
        size = UBound(Out)
        line = ""
        
        
        
        ReDim frompep(size)
        For ii = 0 To size
            frompep(ii) = New Hashtable
            For Each item As DictionaryEntry In Out(ii)
                frompep(ii).Add(item.Key, item.Value)
                jsonRes &= """" & item.Key & """:""" & item.Value & ""","
            Next
            'jsonRes = Join(outjson, ",")
            ' jsonRes &= "size=" & UBound(frompep) & " " & "key:" & frompep(ii)("campus") & " val:" & frompep(ii)("revdate") & "<br>"
            outjson = Split(jsonRes, ",")
            ReDim Preserve outjson(UBound(outjson) - 1)
            line = Join(outjson, ",")
            'line = ""
            line = "{" & line & "}"
        Next
    End Sub
       

    'Public Function newRollOut(ByRef prj As String) As Integer
    '    Dim res As New PromptDataHelper
    '    Dim request As String = "SELECT aort, aorcot, cmt, cmtco, iort FROM pep WHERE projectId=" & prj
    '    res.FillDataTable(request)
    '    Dim rowCount = res.DataTable.Rows.Count
                
    '    If rowCount < 1 Then
    '        Dim sql As String = "UPDATE pep SET aort='Architect of Record (AOR) PV', aorcot='AOR Design Throughs Close-Out',cmt='Construction Manager (CM) PC',cmtco='CM Design Throughs Close-Out',iort='Inspector of Record (IOR)' WHERE projectId=" & prj
    '        Dim rowsAffected As Integer = res.ExecuteNonQueryWithReturn(sql)
    '        Return rowsAffected
    '    Else
    '        Return rowCount
    '    End If
        
    'End Function
    
    Private Sub getMinIteration()
        Dim sql As String = "Select min(iteration) as minIteration From pep Where ProjectID=" & prjid
        Using db As New PromptDataHelper
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If tbl.Rows.Count > 0 Then
                minIter = tbl.Rows(0).Item("minIteration")
            End If
        End Using
        If minIter > 0 Then
            makeNewProject(prjid)
        End If
    End Sub
        
    Public Function getDBL(ByRef tbl As String, ByRef arr As Array, ByRef prj As String, iters As Integer) As String
        'Dim rows As Integer = newRollOut(prj)
        'Console.WriteLine("You are here")
        Dim res As New PromptDataHelper
        Dim up = UBound(arr)
        Dim tmp As String
        Dim i As Integer
        Dim j As Integer = 0
        Dim request As String = "SELECT * FROM " & tbl & " WHERE projectId=" & prj & " and iteration = " & iters
        Dim str As New Hashtable
        jsonRes = ""
        With res
            'get data
            .FillReader(request)
            While .Reader.Read
                ReDim Preserve Out(j)
                Out(j) = New Hashtable
               
                For i = 0 To up
                    If Not IsDBNull(.Reader(arr(i))) Then
                        If arr(i) = "notes" Then
                            'tmp = .Reader(arr(i))
                            'tmp = tmp.Replace("~", ",")
                            '.Reader(arr(i)) = tmp
                        End If
                        Out(j).Add(arr(i), .Reader(arr(i)))
                        '     jsonRes &= ""
                    End If
                Next
                j += 1
            End While
            .Reader.Close()
            'jsonRes &= UBound(Out)
        End With
        Return jsonRes
        'End Function          
            
        'End Using
        'Return Tab
    End Function

    
    Public Function makeNewProject(ByRef prj As String) As String
        '  prjcounter = 999
        Dim isst As String = "insert into pep (projectId) values (" & prjid & ")"
        Dim addres As New PromptDataHelper
        With addres
            addres.ExecuteNonQuery(isst)
        End With
        
        Return ""
    End Function
</script>

<%=line%>
