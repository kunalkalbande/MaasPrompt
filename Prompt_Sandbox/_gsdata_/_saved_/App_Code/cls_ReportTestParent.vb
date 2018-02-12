Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports System.Collections.Generic
Imports Telerik.Web.UI


Namespace Prompt

    '********************************************
    '*  Object Code Class
    '*  
    '*  Purpose: Processes data for the object codes
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    10/22/07
    '*
    '********************************************

    Public Class x
        Implements IDisposable


        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper

        End Sub


        Public Function GetPmBudgetItemObjects() As List(Of promptReportChild)
            Dim dt As DataTable
            Dim dbPM As New Prompt.PMBudget
            Dim PMBlist As New List(Of promptReportChild)
            dt = dbPM.GetPMBudgetItems(738)
            Dim i As Integer = 0
            Dim x_itemID As Integer
            Dim x_ParentItemID As Integer
            Dim x_BudgetAmount As Double
            Dim x_ItemName As String
            For Each row As DataRow In dt.Rows
                i = i + 1

                'If (row("ItemID").IsNull()) Then i = 0
                'If (row("ParentItemID").IsNull()) Then i = 0
                'If (row("BudgetAmount").IsNull()) Then i = 0

                x_itemID = IIf(IsDBNull(row("ItemID")), 0, row("ItemID"))
                x_ParentItemID = IIf(IsDBNull(row("ParentItemID")), 0, row("ParentItemID"))
                x_BudgetAmount = IIf(IsDBNull(row("BudgetAmount")), 0, row("BudgetAmount"))
                x_ItemName = IIf(IsDBNull(row("ItemName")), 0, row("ItemName"))
                PMBlist.Add(New promptReportChild(x_itemID, x_ParentItemID, x_ItemName, x_BudgetAmount))




            Next
            Return PMBlist
        End Function

#Region "IDisposable"

        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            'If Not db Is Nothing Then
            '    db.Dispose()
            'End If
        End Sub

#End Region

    End Class

End Namespace

