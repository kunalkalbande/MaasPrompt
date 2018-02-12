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

    Public Class promptReportChild
        Implements IDisposable


        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper

        End Sub


        Private _ItemID As Integer
        Public Property ItemId() As Integer
            Get
                Return _ItemID
            End Get
            Set(ByVal value As Integer)
                _ItemID = value
            End Set
        End Property


        Private _ParentItemID As Integer
        Public Property ParentItemID() As Integer
            Get
                Return _ParentItemID
            End Get
            Set(ByVal value As Integer)
                _ParentItemID = value
            End Set
        End Property

        Private _ItemName As String
        Public Property ItemName() As String
            Get
                Return _ItemName
            End Get
            Set(ByVal value As String)
                _ItemName = value
            End Set
        End Property


        Private _BudgetAmount As Double
        Public Property BudgetAmount() As Double
            Get
                Return _BudgetAmount
            End Get
            Set(ByVal value As Double)
                _BudgetAmount = value
            End Set
        End Property

        Public Sub New(ByVal itemID As Integer, ByVal parentItemID As Integer, _
                       ByVal itemName As String, ByVal budgetAmount As Double)
            _ItemID = itemID
            _ParentItemID = parentItemID
            _ItemName = ItemName
            _BudgetAmount = budgetAmount
        End Sub


#Region "IDisposable"

        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            If Not db Is Nothing Then
                db.Dispose()
            End If
        End Sub

#End Region

    End Class

End Namespace

