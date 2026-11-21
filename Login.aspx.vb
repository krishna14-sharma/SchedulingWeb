Imports System
Imports System.Data
Imports System.Web
Imports System.Web.Services
Imports System.Collections.Generic

''' <summary>Converted from Form1 (Scheduling Login).</summary>
Partial Class LoginPage
    Inherits System.Web.UI.Page

    Protected CurrentYear As String = AppCtx.CurrentSession()
    Protected YearOptions As New List(Of String)

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        Dim cur As DateTime = DateTime.Today
        For i As Integer = 0 To 2
            YearOptions.Add(AppCtx.GetSession(cur.AddYears(-i)))
        Next
    End Sub

    <WebMethod(EnableSession:=True)>
    Public Shared Function Login(ByVal userName As String, ByVal password As String, ByVal yearCode As String, ByVal returnUrl As String) As ApiResult
        Return Api.Run(Function()
                           userName = AppCtx.Str(userName).Trim()
                           If userName = "" Then Throw New UserError("User Name Required")
                           If String.IsNullOrEmpty(password) Then Throw New UserError("Password Required")

                           Dim dt As DataTable = Db.Table("select role, dept, isnull(staff,0) staff, isnull(uo,0) uo from Usertab4 " &
                                                         "where uname = @u and cast(Pwd as varchar(50)) = @p",
                                                         Db.P("@u", userName), Db.P("@p", password))
                           If dt.Rows.Count = 0 Then Throw New UserError("Invalid User Name and Password!")

                           AppCtx.UserName = userName
                           AppCtx.FinYear = If(String.IsNullOrEmpty(yearCode), AppCtx.CurrentSession(), yearCode)

                           ' Form1_Load: number of back days allowed on scheduling screens
                           Try
                               AppCtx.Nofd = CInt(AppCtx.Num(Db.Scalar("select nofd from nofd_session2 where session = '1718'")))
                           Catch
                               AppCtx.Nofd = 0
                           End Try

                           ' frmMDI_Load: data clean-up that ran every time the main menu opened
                           Try
                               Db.Exec("update AreaDemandData set Chick_type='Broiler(M)' where Chick_type='Broiler(M )'")
                               Db.Exec("update Shedule set Productname='Broiler(M)' where Productname='Broiler(M )'")
                           Catch
                           End Try

                           Dim target As String = VirtualPathUtility.ToAbsolute("~/Dashboard.aspx")
                           If Not String.IsNullOrEmpty(returnUrl) AndAlso returnUrl.StartsWith("/") AndAlso Not returnUrl.StartsWith("//") _
                              AndAlso Not returnUrl.ToLowerInvariant().Contains("login.aspx") _
                              AndAlso Not returnUrl.ToLowerInvariant().EndsWith("/default.aspx") AndAlso returnUrl <> "/" _
                              AndAlso Not returnUrl.ToLowerInvariant().EndsWith("/logout.aspx") Then
                               target = returnUrl
                           End If
                           Return New With {.redirect = target}
                       End Function, False)
    End Function

End Class
