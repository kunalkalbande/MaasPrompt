Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO

Namespace Prompt

    '********************************************
    '*  Search Class
    '*  
    '*  Purpose: Processes data for the Search Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    09/20/07
    '*
    '********************************************

    Public Class promptSearch
        Implements IDisposable

        'Properties
        Public CallingPage As Page

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub






#Region "Subs and Functions"

        Public Function SearchPONums(ByVal sDistrict As String, ByVal sCrit As String) As DataTable
            Dim sql As String = "Select Colleges.College, Projects.ProjectNumber as [Proj#], Projects.ProjectName, Contracts.Description, PurchaseOrderNumber as [PO#], InvoiceNumber as [Inv. #], Transactions.Status, TotalAmount From Transactions join Projects on Transactions.ProjectID = Projects.ProjectID join Colleges on Projects.CollegeID = Colleges.CollegeID join Contracts on Transactions.ContractID = Contracts.ContractID join Contractors on Transactions.ContractorID = Contractors.ContractorID Where Transactions.DistrictID = '" & sDistrict & "' and PurchaseOrderNumber Like '%" & sCrit & "%'"
            Return db.ExecuteDataTable(sql)
        End Function

        Public Function SearchInvoiceNums(ByVal sDistrict As String, ByVal sCrit As String) As DataTable
            Dim sql As String = "Select Colleges.College, Projects.ProjectNumber as [Proj#], Projects.ProjectName, Contracts.Description, PurchaseOrderNumber as [PO#], InvoiceNumber as [Inv #], Transactions.Status, TotalAmount From Transactions join Projects on Transactions.ProjectID = Projects.ProjectID join Colleges on Projects.CollegeID = Colleges.CollegeID join Contracts on Transactions.ContractID = Contracts.ContractID join Contractors on Transactions.ContractorID = Contractors.ContractorID Where Transactions.DistrictID = '" & sDistrict & "' and InvoiceNumber Like '%" & sCrit & "%'"
            Return db.ExecuteDataTable(sql)
        End Function

        Public Function PerformSearch(ByVal sSearch As String, ByVal bContractorKeywordsOnly As Boolean) As DataTable

            Dim sCriteria As New System.Text.StringBuilder   'build the sql string
            With sCriteria

                If bContractorKeywordsOnly = True Then
                    .Append("SELECT * FROM qry_Search_ContractorKeywords WHERE Description Like '%" & sSearch & "%' ")
                    .Append(" AND DistrictID = " & CallingPage.Session("DistrictID"))
                Else

                    .Append("SELECT * FROM qry_Search_ContractorComments WHERE Description Like '%" & sSearch & "%' ")
                    .Append(" AND DistrictID = " & CallingPage.Session("DistrictID") & " UNION ALL ")
                    .Append("SELECT * FROM qry_Search_ContractorKeywords WHERE Description Like '%" & sSearch & "%' ")
                    .Append(" AND DistrictID = " & CallingPage.Session("DistrictID") & " UNION ALL ")

                    .Append("SELECT * FROM qry_Search_CollegeNotes WHERE Description Like '%" & sSearch & "%' ")
                    .Append(" AND DistrictID = " & CallingPage.Session("DistrictID") & " UNION ALL ")
                    .Append("SELECT * FROM qry_Search_CollegeAttachmentComments WHERE Description Like '%" & sSearch & "%' ")
                    .Append(" AND DistrictID = " & CallingPage.Session("DistrictID") & " UNION ALL ")

                    .Append("SELECT * FROM qry_Search_ContractNotes WHERE Description Like '%" & sSearch & "%' ")
                    .Append(" AND DistrictID = " & CallingPage.Session("DistrictID") & " UNION ALL ")
                    .Append("SELECT * FROM qry_Search_ContractComments WHERE Description Like '%" & sSearch & "%' ")
                    .Append(" AND DistrictID = " & CallingPage.Session("DistrictID") & " UNION ALL ")
                    .Append("SELECT * FROM qry_Search_ContractAttachmentComments WHERE Description Like '%" & sSearch & "%' ")
                    .Append(" AND DistrictID = " & CallingPage.Session("DistrictID") & " UNION ALL ")

                    .Append("SELECT * FROM qry_Search_ProjectsNotes WHERE Description Like '%" & sSearch & "%' ")
                    .Append(" AND DistrictID = " & CallingPage.Session("DistrictID") & " UNION ALL ")
                    .Append("SELECT * FROM qry_Search_ProjectAttachmentComments WHERE Description Like '%" & sSearch & "%' ")
                    .Append(" AND DistrictID = " & CallingPage.Session("DistrictID"))

                End If

                .Append(" ORDER BY Source ")

            End With

            Return db.ExecuteDataTable(sCriteria.ToString)



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
