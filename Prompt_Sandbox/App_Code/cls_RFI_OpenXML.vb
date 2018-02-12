Imports Microsoft.VisualBasic
Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Text
Imports System.Data
Imports System.Data.SqlClient
Imports System.Net
'Imports DocumentFormat.OpenXml.Packaging
'Imports DocumentFormat.OpenXml.Spreadsheet


Namespace Prompt



    Public Class OpenXML
        Implements IDisposable
        Public db As New PromptDataHelper


#Region "OPEN XML Functions"

        Public Sub writeFile(ByVal newFile As String) ' Not used anymore. Created for proof of concept.
            Dim zRead As String = ""
            Using reader As StreamReader = New StreamReader(HttpContext.Current.Server.MapPath("~/") & "docs\RFI_Template.xml")
                zRead = reader.ReadToEnd
            End Using

            IO.File.WriteAllText(newFile, zRead)
        End Sub

        Public Function getFileSnippet(ByVal file As String) As String
            Dim zRead As String = ""
            Using reader As StreamReader = New StreamReader(HttpContext.Current.Server.MapPath("~/") & "docs\snippets\" & file)
                zRead = reader.ReadToEnd
            End Using

            Return zRead
        End Function

        Public Sub appendFile(ByVal file As String, ByVal snip As String)
            Using appendFile As IO.StreamWriter = IO.File.AppendText(file)
                appendFile.WriteLine(snip)
            End Using
        End Sub

        Public Sub callbackDeleteFile(ByVal zfile As String)

            If IO.File.Exists(zfile) Then
                Try
                    File.Delete(zfile)
                Catch
                End Try
            End If

        End Sub

        Public Function RFIPrint(ByVal RFIID As Integer) As String
            Dim sql As String = ""
            Dim snip As String = ""
            Dim tblObjs As Object = buildRFIObjects(RFIID)

            Dim newFile As String = HttpContext.Current.Server.MapPath("~/") & "docs\temp\" & tblObjs(0).rows.item(0).item("RefNumber") & ".xml"

            If IO.File.Exists(newFile) Then
                Try
                    File.Delete(newFile)
                Catch
                End Try
            End If

            Dim AddrSender As String = tblObjs(2).rows(0).item("City") & ", " & tblObjs(2).rows(0).item("State") & " " & tblObjs(2).rows(0).item("Zip")
            Dim AddrTo As String = ""
            Try
                AddrTo = tblObjs(1).rows(0).item("City") & ", " & tblObjs(1).rows(0).item("State") & " " & tblObjs(1).rows(0).item("Zip")
            Catch ex As Exception
                AddrTo = ""
            End Try

            Dim createDate As String = tblObjs(0).rows(0).item("ReceivedOn")
            Dim requiredBy As String = tblObjs(0).rows(0).item("RequiredBy")
            Dim returnedOn As String
            Dim sResponse As String = ""

            Try
                returnedOn = tblObjs(0).rows(0).item("ReturnedOn")
                sql = "Select name from contacts where ContactID = " & tblObjs(0).rows(0).item("RespondedBy")
                Dim RespondName As String = db.ExecuteScalar(sql)
                sResponse = "Response By: " & RespondName & " | " & tblObjs(0).rows(0).item("Answer")
            Catch
                returnedOn = ""
                sResponse = ""
            End Try

            Dim numAttach As Integer = 0
            Dim responseAttach As Integer = 0

            Using db As New RFI
                numAttach = db.countRFIAttachments(RFIID, "Request", 0)
                responseAttach = db.countRFIAttachments(RFIID, "Response", 1)
            End Using

            'create an object array for the for next loop to consume
            Dim arrSnip() As Object = New Object() {"RFI_1.xml", 2, "RFI_3.xml", "RFI_4.xml", 5, 6, 7, 8, 9, 10, 11, 12, 13, "RFI_14.xml", 14, 15 _
                                                   , 16, 17, "RFI_18.xml", 19, 20, "RFI_21.xml", "RFI_22.xml", 23, 24, "RFI_end.xml"}
            'create the data array
            'Dim arrData(25)

            Dim arrData() = {"", tblObjs(3).rows(0).item("DistrictName"), tblObjs(3).rows(0).item("College"), tblObjs(3).rows(0).item("ProjectName"), tblObjs(2).rows(0).item("Name") _
                            , tblObjs(0).rows(0).item("ProjectID"), tblObjs(2).rows(0).item("Contact"), tblObjs(0).rows(0).item("ContractID"), tblObjs(2).rows(0).item("Address1") _
                            , tblObjs(0).rows(0).item("RefNumber"), AddrSender, tblObjs(2).rows(0).item("Phone1"), createDate, requiredBy, tblObjs(1).rows(0).item("Name"), tblObjs(1).rows(0).item("Contact") _
                            , tblObjs(1).rows(0).item("Address1"), AddrTo, tblObjs(1).rows(0).item("Phone1"), createDate, numAttach, tblObjs(0).rows(0).item("Question"), tblObjs(0).rows(0).item("Proposed") _
                            , returnedOn, responseAttach, sResponse}


            For i As Integer = 0 To arrSnip.Length - 1
                If IsNumeric(arrSnip(i)) Then
                    snip = arrData(i) & RFISnippets(arrSnip(i))
                Else
                    snip = arrData(i) & getFileSnippet(arrSnip(i))
                End If
                'xmlFile &= snip
                appendFile(newFile, snip)
            Next

            Return newFile
        End Function

        Public Function RFISnippets(ByVal lineNum As Integer) As String
            Dim str As String = ""

            Select lineNum
                Case 2
                    str = "</Data></Cell></Row><Row ss:AutoFitHeight='0'><Cell ss:MergeAcross='2' ss:StyleID='m40700584'><Data ss:Type='String' >"
                Case 5
                    str = "</Data></Cell></Row><Row ss:AutoFitHeight='0'><Cell ss:StyleID='s80'><Data ss:Type='String'> Project ID:</Data></Cell><Cell ss:StyleID='s81'><Data ss:Type='String' >"
                Case 6, 8
                    str = "</Data></Cell><Cell ss:StyleID='s82'/><Cell ss:MergeAcross='2' ss:StyleID='s78'><Data ss:Type='String' >"
                Case 7
                    str = "</Data></Cell></Row><Row ss:AutoFitHeight='0'><Cell ss:StyleID='s80'><Data ss:Type='String'>Contract ID:</Data></Cell><Cell ss:StyleID='s81'><Data ss:Type='String' >"
                Case 9
                    str = "</Data></Cell></Row><Row ss:AutoFitHeight='0'><Cell ss:StyleID='s80'><Data ss:Type='String'> RFI Number:</Data></Cell><Cell ss:MergeAcross='1' ss:StyleID='s84'><Data ss:Type='String' >"
                Case 10
                    str = "</Data></Cell><Cell ss:MergeAcross='2' ss:StyleID='s78'><Data ss:Type='String' >"
                Case 11
                    str = "</Data></Cell></Row><Row ss:AutoFitHeight='0'><Cell ss:Index='4' ss:MergeAcross='2' ss:StyleID='s86'><Data ss:Type='String'>"
                Case 12
                    str = "</Data></Cell></Row><Row ss:AutoFitHeight='0'><Cell ss:StyleID='s80'><Data ss:Type='String'> Created On:</Data></Cell><Cell ss:StyleID='s90'><Data ss:Type='String' >"
                Case 13
                    str = "</Data></Cell><Cell ss:StyleID='s91'/><Cell ss:StyleID='s75'/><Cell ss:StyleID='s76'/><Cell ss:StyleID='s76'/></Row><Row ss:AutoFitHeight='0'><Cell ss:StyleID='s80'><Data ss:Type='String'> Required By:</Data></Cell><Cell ss:StyleID='s90'><Data ss:Type='String' >"
                Case 14 'spliting the RFI file up
                    str = "</Data></Cell></Row><Row ss:AutoFitHeight='0'><Cell ss:StyleID='s92'/><Cell ss:StyleID='s92'/><Cell ss:StyleID='s92'/><Cell ss:MergeAcross='2' ss:StyleID='s87'><Data ss:Type='String' >"
                Case 15, 16, 17
                    str = "</Data></Cell></Row><Row ss:AutoFitHeight='0'><Cell ss:Index='4' ss:MergeAcross='2' ss:StyleID='s87'><Data ss:Type='String'>"
                Case 19, 23
                    str = "</Data></Cell><Cell ss:StyleID='s101'><Data ss:Type='String'>Attachments:</Data></Cell><Cell ss:StyleID='s102'><Data ss:Type='String' >"
                Case 20
                    str = "</Data></Cell></Row><Row ss:AutoFitHeight='0'><Cell ss:MergeAcross='5' ss:MergeDown='7' ss:StyleID='s104'><Data ss:Type='String' >"
                Case 24
                    str = "</Data></Cell></Row><Row ss:AutoFitHeight='0'><Cell ss:MergeAcross='5' ss:MergeDown='6' ss:StyleID='m40701460'><Data ss:Type='String' >"
                Case Else
                    str = ""
            End Select

            Return str
        End Function

        Public Function buildRFIObjects(ByVal nRFIID As Integer) As Object
            'get rfi data
            Dim sql As String = "Select * from RFIs Where RFIs.RFIID = " & nRFIID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            'get sent to
            Dim tblTo As DataTable
            Dim subTo As Integer = tbl.Rows.Item(0).Item("SubmittedToID")
            If subTo > 1 Then
                sql = "Select * From Contacts Where ContactID = " & subTo
                tblTo = db.ExecuteDataTable(sql)
            Else
                sql = "Select * From Contacts Where ContactID = 18787"
                tblTo = db.ExecuteDataTable(sql)
            End If
           

            'get sent by
            Dim tranBy As Integer = tbl.Rows.Item(0).Item("TransmittedByID")
            sql = "Select * From Contacts Where ContactID = " & tranBy
            Dim tblBy As DataTable = db.ExecuteDataTable(sql)

            'get district name,college name and project name
            Dim disId As Integer = tbl.Rows.Item(0).Item("districtID")
            Dim projId As Integer = tbl.Rows.Item(0).Item("ProjectID")

            sql = "Select Name as DistrictName, Projects.ProjectName, colleges.college from Districts"
            sql &= " Join Projects ON Projects.DistrictID = Districts.DistrictID "
            sql &= " join Colleges on colleges.CollegeID = projects.collegeid"
            sql &= " Where ProjectID = " & projId
            Dim zNames As DataTable = db.ExecuteDataTable(sql)

            Dim dataArr(3) As Object
            dataArr(0) = tbl
            dataArr(1) = tblTo
            dataArr(2) = tblBy
            dataArr(3) = zNames

            Return dataArr
        End Function

        Public Function LogPrint(ByVal ProjectID As Integer) As String
            Dim logDat As Object = BuildLogObjects(ProjectID) 'logDat(0) = District Info, logDat(1) = Contracts

            Dim snip As String = ""
            Dim newFile As String = HttpContext.Current.Server.MapPath("~/") & "docs\temp\" & ProjectID & "_LOG.xml"

            If IO.File.Exists(newFile) Then
                Try
                    File.Delete(newFile)
                Catch
                End Try
            End If
            Dim dStamp As DateTime = Today
            'dStamp = 

            Dim arrSnip() As Object = New Object() {"LOG_1.xml", 2, "LOG_2.xml", 3, "LOG_4.xml"}
            Dim arrData() = {logDat(0).rows.item(0).item("Name"), logDat(0).rows.item(0).item("ProjectName"), dStamp, ProjectID, ""}

            For i As Integer = 0 To arrSnip.Length - 1
                If IsNumeric(arrSnip(i)) Then
                    snip &= logSnippets(arrSnip(i)) & arrData(i)
                Else
                    snip &= getFileSnippet(arrSnip(i)) & arrData(i)
                End If
            Next
            appendFile(newFile, snip)

            'loop through all the PROJECT contracts with RFIs
            For Each row As DataRow In logDat(1).Rows
                Dim contStr As String = "<Row ss:AutoFitHeight='0' ss:Height='19.5'><Cell ss:MergeAcross='2' ss:StyleID='s39'><Data ss:Type='String'>Contract Number:"

                contStr &= row.Item("ContractID") & "</Data></Cell>"
                contStr &= "<Cell ss:MergeAcross='2' ss:StyleID='s30'><Data ss:Type='String'>" & row.Item("Description") & " </Data></Cell>"
                contStr &= "<Cell ss:StyleID='s25'/>"
                'contStr &= "<Cell ss:StyleID='s25'/><Cell ss:StyleID='s25'/>"
                contStr &= "<Cell ss:StyleID='s30' ss:MergeAcross='2'><Data ss:Type='String'>" & row.Item("Contractor") & "</Data></Cell>"
                contStr &= "<Cell ss:StyleID='s30' ss:MergeAcross='2'><Data ss:Type='String'>" & row.Item("Contact") & " : " & row.Item("Phone1") & "</Data></Cell>"

                'contStr &= "<Cell ss:StyleID='s27'/><Cell ss:StyleID='s28'/><Cell ss:StyleID='s25'/><Cell ss:StyleID='s25'/><Cell ss:StyleID='s25'/><Cell ss:StyleID='s25'/>"
                contStr &= "<Cell ss:StyleID='s27'/></Row>"
                'contStr &= " <Cell ss:MergeAcross='1' ss:StyleID='s43'/></Row>"
                appendFile(newFile, contStr)

                Dim sql As String = "Select * from RFIs JOIN Contacts ON Contacts.ContactID=RFIs.TransmittedbyID where ContractID = " & row("ContractID")
                'sql &= " JOIN Contacts ON Contacts.
                Dim rfis As DataTable = db.ExecuteDataTable(sql)
                Dim rfiCell As String = "<Cell ss:StyleID='s30'/>"
                Dim rfiStr As String = ""
                Dim Ans As String = ""
                Dim AnsLen As Integer = 0

                For Each zow As DataRow In rfis.Rows

                    Using db As New RFI
                        Ans = db.getAllRFIAnswers(zow("RFIID"), "Log", 0)
                        AnsLen = getRowHeight(Ans, zow("RFIID"))
                    End Using
                    sql = "Select Answer from RFIs Where RFIID = " & zow("RFIID")
                    Dim Que As String = db.ExecuteScalar(sql)
                    Dim QueLen As Integer = getRowHeight(Que, zow("RFIID"))
                    If QueLen > AnsLen Then AnsLen = QueLen

                    'rfiStr &= " <Row ss:AutoFitHeight='0' ss:Height='18'><Cell ss:StyleID='s30'><Data ss:Type='String' >" & zow("RefNumber") & "</Data></Cell>"
                    'rfiStr &= rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & "</Row>"
                    'rfiStr &= "<Row ss:AutoFitHeight='0' ss:Height='" & AnsLen & "'>" & getFileSnippet("LOG_RFI_Q.xml") & zow("Question")
                    'rfiStr &= getFileSnippet("LOG_RFI_A.xml") & Ans & "</Data></Cell></Row>"

                    rfiStr &= buildLogString(Ans, AnsLen, zow("RefNumber"), zow, False, Nothing)

                    sql = "Select * From RFIQuestions Where RFIID = " & zow("RFIID") & " Order By Revision"
                    Dim revTbl As DataTable = db.ExecuteDataTable(sql)
                    For Each inRow As DataRow In revTbl.Rows
                        Using db As New RFI
                            Ans = db.getAllRFIAnswers(zow("RFIID"), "Log", inRow.Item("Revision"))
                            AnsLen = getRowHeight(Ans, zow("RFIID"))
                        End Using
                        rfiStr &= buildLogString(Ans, AnsLen, zow("RefNumber"), Nothing, True, inRow)
                    Next
                Next
                appendFile(newFile, rfiStr)

            Next

            appendFile(newFile, getFileSnippet("LOG_End.xml"))

            'Dim dwnData() As Object = {newFile}

            Return newFile

        End Function

        Public Function buildLogString(Ans As String, AnsLen As Integer, refNum As String, zow As DataRow, isIn As Boolean, inRow As DataRow) As String

            Dim rfiCell As String = "<Cell ss:StyleID='s30'/>"
            Dim rfiStr As String = ""
            Dim Que As String = ""
            If isIn = False Then
                rfiStr &= " <Row ss:AutoFitHeight='0' ss:Height='18'><Cell ss:StyleID='s30'><Data ss:Type='String' >" & zow("RefNumber") & "</Data></Cell>"
                rfiStr &= rfiCell & "<Cell ss:StyleID='s30b'><Data ss:Type='String' >Status: " & zow("Status") & "         Originator: " & zow("name") & "</Data></Cell>" & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & rfiCell & "</Row>"
            End If
            rfiStr &= "<Row ss:AutoFitHeight='0' ss:Height='" & AnsLen & "'>"
            '& getFileSnippet("LOG_RFI_Q.xml") & Que
            If isIn = True Then
                rfiStr &= logSnippets(5) & inRow("Revision") & logSnippets(6)
                Que = "[Requested: " & inRow("ResubmittedOn") & "Required By: " & inRow("RequiredBy") & " ] " & "&#10;" & inRow("Question")
            Else
                rfiStr &= logSnippets(4)
                Que = "[Requested: " & zow("ReceivedOn") & " - Required By: " & zow("RequiredBy") & " ] " & "&#10;" & zow("Question")
            End If
            rfiStr &= logSnippets(7) & Que
            rfiStr &= getFileSnippet("LOG_RFI_A.xml") & Ans & "</Data></Cell></Row>"

            Return rfiStr
        End Function

        Public Function getRowHeight(ByVal Ans As String, RFIID As Integer) As Integer
            Dim Len As Integer
            Dim AnsLen As Integer
            Dim factor As Integer

            Len = (Ans.Length)
            AnsLen = Ans.Split("&#10;").Length
            Select Case Len
                Case Is < 450
                    factor = 20
                Case Is < 900
                    factor = 8
                Case Is < 1200
                    factor = 5
                Case Is < 2000
                    factor = 8
                Case Else
                    factor = 1
            End Select

            AnsLen = (AnsLen * 12) + (Len / factor)
            If AnsLen < 80 Then
                AnsLen = 80
            End If

            Return AnsLen
        End Function

        Public Function getQuestionLength(ByVal RFIID As Integer) As Integer
            Dim sql As String = "Select Question from "
            Return 0
        End Function

        Public Function logSnippets(ByVal lineNum As Integer) As String
            Dim str As String = ""

            Select Case lineNum
                Case 2
                    str = "</Data></Cell><Cell ss:StyleID='s16'/><Cell ss:StyleID='s16'/><Cell ss:StyleID='s16'/><Cell ss:StyleID='s16'/><Cell ss:StyleID='s16'/><Cell ss:StyleID='s16'/><Cell ss:StyleID='s16'/><Cell ss:MergeAcross='3' ss:StyleID='s41'><Data ss:Type='String' > "
                Case 3
                    str = "</Data></Cell></Row><Row ss:AutoFitHeight='0' ss:Height='19.5'><Cell ss:MergeAcross='2' ss:StyleID='s39'><Data ss:Type='String'>Project No: "
                Case 4
                    str = "<Cell ss:StyleID='s31'><Data ss:Type='String'>Issue:</Data></Cell>"
                Case 5
                    str = "<Cell ss:StyleID='s31'><Data ss:Type='String'>Rev - "
                Case 6
                    str = "</Data></Cell>"
                Case 7
                    str = "<Cell ss:MergeAcross='5' ss:StyleID='s36'><Data ss:Type='String'>"
            End Select


            Return str
        End Function

        Public Function BuildLogObjects(ByVal ProjectID As Integer) As Object

            Dim sql As String = "Select Name, ProjectName From Projects"
            sql &= " Join Districts on Districts.DistrictID=Projects.DistrictID "
            sql &= " Where ProjectID = " & ProjectID

            Dim tbl As DataTable = db.ExecuteDataTable(sql) 'District Information

            Using rfi As New RFI
                Dim contracts As DataTable = rfi.getAllProjectContracts(ProjectID, "false", "", "RFIs")

                Dim dataArr(1) As Object
                dataArr(0) = tbl
                dataArr(1) = contracts

                Return dataArr
            End Using

        End Function

        Public Function getClientDownloadDir() As String 'Not used anymore
            Dim zuser As String = Environment.GetFolderPath(Environment.SpecialFolder.Personal)
            'zuser = Left(zuser, Len(zuser) - 9)
            Dim dwnString As String = zuser & "Downloads\"

            Return dwnString
        End Function

        Public Function getXmlFromFile(ByVal zfile As String, ByVal xfile As String) As String 'Not used anymore. Created for testing

            Dim newFile As String = HttpContext.Current.Server.MapPath("~/") & "docs\temp\RFI_" & xfile & ".xml"
            writeFile(newFile)

            Dim zuser As String = Environment.GetFolderPath(Environment.SpecialFolder.Personal)
            zuser = Left(zuser, Len(zuser) - 9)

            Dim dwnString As String = zuser & "Downloads\RFI_" & xfile & ".xml"
            Try
                Dim web_client As New System.Net.WebClient
                web_client.DownloadFile(newFile, dwnString)

                File.Delete(newFile)

                Return newFile
            Catch
                Return dwnString & "  - not so much"
            End Try

        End Function

#End Region

#Region "IDisposable"


        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            If Not db Is Nothing Then
                db.Dispose()
            End If
        End Sub
#End Region

    End Class





End Namespace

