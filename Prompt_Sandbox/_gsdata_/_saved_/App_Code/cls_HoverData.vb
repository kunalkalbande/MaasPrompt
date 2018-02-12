Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Hover Data Class
    '*  
    '*  Purpose: Processes data for Hover Windows
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    05/1/07
    '*
    '********************************************

    Public Class HoverData
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

      
        Public Function GetJCAFBudgetData(ByVal Parm As String) As String

            If Not IsNothing(Parm) Then
                Dim Parmlist() As String = Parm.Split(":")   'extract the parms to string array
                Dim PopType As String = Parmlist(0)
                Dim ProjectID As Integer = Parmlist(1)
                Dim Fld As String = Parmlist(2)

                Dim sql As String = ""
                If PopType = "Notes" Then
                    sql = "SELECT Notes FROM BudgetObjectCodes WHERE ProjectID = " & ProjectID & " AND JCAFColumnName = '" & Fld & "'"
                    Dim tbl As DataTable = db.ExecuteDataTable(sql)
                    Dim snote As String = ""
                    For Each row As DataRow In tbl.Rows
                        snote &= ProcLib.CheckNullDBField(row("Notes")) & vbCrLf
                    Next
                    Return snote

                End If
                If PopType = "Changes" Then
                    sql = "SELECT * FROM JCAFChangeLog WHERE ProjectID = " & ProjectID & " AND JCAFColumnName = '" & Fld & "'"
                    db.FillReader(sql)
                    Dim result As New StringBuilder

                    While db.Reader.Read
                        With result
                            .Append("-------------------------------- <br>")
                            .Append("<b>On: </b>" & db.Reader("LastUpdateOn") & "<br>")
                            .Append("<b>By: </b>" & db.Reader("LastUpdateBy") & "<br>")

                            If IsDBNull(db.Reader("ChangeDescription")) Then   'this is pre conversion  so concatonate description
                                .Append("Budget Item Changed <br>")
                                .Append("<b>Prev Amount: </b>" & FormatCurrency(db.Reader("OldAmount")) & "<br>")
                                .Append("<b>Prev Notes : </b>" & db.Reader("OldNote") & "<br><br>")
                            Else
                                .Append(Replace(db.Reader("ChangeDescription"), vbCrLf, "<br>") & "<br><br>")
                            End If
                        End With

                    End While

                    Return result.ToString

                End If

                If PopType = "Flag" Then
                    sql = "SELECT FlagDescription FROM Flags WHERE ProjectID = " & ProjectID & " AND BudgetItemField = '" & Fld & "'"
                    Using command As SqlCommand = db.CreateSqlStringCommand(sql)
                        Return db.ExecuteScalar("GetJCAFBudgetData", command)
                    End Using

                End If


            Else
                Return ""
            End If
 

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
