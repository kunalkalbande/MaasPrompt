Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient


Namespace Prompt

    Public Class FileRename

        Implements IDisposable

        Private db As PromptDataHelper
        Private sql As String
        Private zList As DataTable

#Region "File Rename"

        Public Sub New()
            db = New PromptDataHelper

        End Sub

        Public Function GetDirectories(ByVal StartPath As String) As ArrayList

            Dim list As New ArrayList

            For Each Dir As String In Directory.GetDirectories(StartPath)
                list.Add(Dir)
            Next

            Return list

        End Function

        Public Function renameFile(ByVal FilePath As String, fileName As String, newName As String) As String
            Dim status As Boolean
            If File.Exists(FilePath & fileName) Then
                status = True
                FileSystem.Rename(FilePath & fileName, FilePath & newName)
            Else
                status = False
            End If
            Return status
        End Function

        Public Function checkForUnwantedChars(ByVal FileName As String) As Boolean
            Dim zIndex As Integer = FileName.IndexOf("&")
            Dim isChar As Boolean
            If zIndex > -1 Then
                isChar = True
            Else
                zIndex = FileName.IndexOf("+")
                If zIndex > -1 Then
                    isChar = True
                Else
                    isChar = False
                End If
            End If

            Return isChar
        End Function

        Public Sub updateAttachmentFileName(ByVal FileName As String, attID As Integer)
            sql = "Update Attachments Set FileName = '" & FileName & "', LastUpdateOn = '" & Now() & "', LastUpdateBy = 'Administration Process' Where AttachmentID = " & attID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function replaceStringCharacter(ByVal str As String) As String
            Dim fixedStr As String

            fixedStr = str.Replace("&", " and ")
            fixedStr = fixedStr.Replace("+", " plus")

            Return fixedStr
        End Function

        Public Function booleanFileCheck(ByVal FileName As String, FilePath As String) As Boolean
            Dim strPath As String = getStringPath()
            Dim isFile As Boolean

            If File.Exists(strPath & FilePath & FileName) Then
                isFile = True
            Else
                isFile = False
            End If

            Return isFile
        End Function

        Public Function getStringPath() As String
            Dim sname As String = HttpContext.Current.Request.ServerVariables("SERVER_NAME")

            Dim strPath As String = ""

            If sname = "promptdev.maasco.com" Then
                strPath = "D:/PromptAttachments/COD/"
            ElseIf sname = "cod.maasco.com" Then
                strPath = "D:/PromptAttachments/COD/"
            Else
                strPath = "C:/Websites/PromptAttachments/COD/"
            End If

            Return strPath
        End Function

        Public Function checkIfFileExists(ByVal DistrictID As Integer, CollegeID As Integer, ProjectID As Integer) As ArrayList
            Dim strPath As String = ""
            strPath = getStringPath()

            Dim isFile As String
            zList = getProjectFiles(DistrictID, CollegeID, ProjectID)

            Dim list As New ArrayList

            For Each row As DataRow In zList.Rows
                If File.Exists(strPath & row.Item("FilePath") & row.Item("FileName")) Then
                    isFile = "File Exists"
                Else
                    isFile = "<font color='red'>File Not Found</font>"
                End If

                list.Add(row.Item("FileName") & " - " & isFile & " - " & row.Item("AttachmentID"))
            Next

            Return list
        End Function

        Public Function getProjectFilesToRepair(ByVal DistrictID As Integer, CollegeID As Integer, ProjectID As Integer) As DataTable

            sql = "Select FileName,FilePath,AttachmentID From Attachments Where FileName Like '%[&,+]%' AND DistrictID = " & DistrictID
            sql &= " AND CollegeID = " & CollegeID & " AND ProjectID = " & ProjectID & " order by FileName"
            zList = db.ExecuteDataTable(sql)

            Return zList
        End Function

        Public Function writeLogFile(ByVal strLog As String, projectID As Integer) As String
            Dim strPath As String = HttpContext.Current.Server.MapPath(".")
            Dim logFile As String = strPath & "/logs/Project_" & projectID & ".txt"

            Dim isFile As Boolean = File.Exists(logFile)

            If isFile = False Then
                Using sw As New StreamWriter(File.Open(logFile, FileMode.OpenOrCreate))
                End Using
            End If
            Using sw As New StreamWriter(logFile, True)
                sw.WriteLine(strLog)
            End Using



            Return strPath
        End Function

        Public Function getDistinctRepairPaths(ByVal DistrictID As Integer) As DataTable

            sql = "Select Distinct(FilePath) From Attachments Where FileName Like '%[&,+]%' And DistrictID = " & DistrictID
            sql &= " Order By FilePath"

            zList = db.ExecuteDataTable(sql)

            Return zList

        End Function

        Public Function getDistinctDistricts() As DataTable
            sql = "Select Distinct(DistrictID) From Attachments Where FileName Like '%[&,+]%' order By DistrictID  "
            zList = db.ExecuteDataTable(sql)

            Return zList
        End Function

        Public Function getDistinctColleges(ByVal DistrictID As Integer) As DataTable
            sql = "Select CollegeID, Min(FileName) as FileName From Attachments Where DistrictID =" & DistrictID & " AND FileName Like '%[&,+]%' Group By CollegeID Order By CollegeID"
            zList = db.ExecuteDataTable(sql)

            Return zList
        End Function

        Public Function getCollegeProjects(ByVal DistrictID As Integer, CollegeID As Integer) As DataTable
            sql = "Select ProjectID From Attachments Where DistrictID = " & DistrictID & " AND CollegeID = " & CollegeID
            sql &= " AND FileName Like '%[&,+]%' Group By ProjectID"
            zList = db.ExecuteDataTable(sql)

            Return zList
        End Function

        Public Function getProjectFiles(ByVal DistrictID As Integer, CollegeID As Integer, ProjectID As Integer) As DataTable
            sql = "Select FileName, FilePath,AttachmentID From Attachments Where DistrictID = " & DistrictID & " AND CollegeID = " & CollegeID & " AND ProjectID = " & ProjectID
            sql &= "AND FileName Like '%[&,+]%' Order by FileName"
            zList = db.ExecuteDataTable(sql)

            Return zList
        End Function

        Public Function getDistinctCollegeDirectories(ByVal DistrictID As Integer, CollegeID As Integer) As DataTable
            sql = "Select FileName, FilePath, AttachmentID From Attachments Where FileName Like '%[&,+]%' AND DistrictID = " & DistrictID & " AND CollegeID = " & CollegeID
            zList = db.ExecuteDataTable(sql)

            Return zList
        End Function

        Public Function getSingleAttachmentData(ByVal attID As Integer) As DataTable
            sql = "Select FileName, FilePath from Attachments Where AttachmentID = " & attID
            zList = db.ExecuteDataTable(sql)

            Return zList
        End Function







#End Region

#Region "IDisposable Support"

        Private disposedValue As Boolean ' To detect redundant calls

        ' IDisposable
        Protected Overridable Sub Dispose(disposing As Boolean)
            If Not Me.disposedValue Then
                If disposing Then
                    ' TODO: dispose managed state (managed objects).
                End If

                ' TODO: free unmanaged resources (unmanaged objects) and override Finalize() below.
                ' TODO: set large fields to null.
            End If
            Me.disposedValue = True
        End Sub

        ' TODO: override Finalize() only if Dispose(ByVal disposing As Boolean) above has code to free unmanaged resources.
        'Protected Overrides Sub Finalize()
        '    ' Do not change this code.  Put cleanup code in Dispose(ByVal disposing As Boolean) above.
        '    Dispose(False)
        '    MyBase.Finalize()
        'End Sub

        ' This code added by Visual Basic to correctly implement the disposable pattern.
        Public Sub Dispose() Implements IDisposable.Dispose
            ' Do not change this code.  Put cleanup code in Dispose(ByVal disposing As Boolean) above.
            Dispose(True)
            GC.SuppressFinalize(Me)
        End Sub
#End Region

    End Class

End Namespace
