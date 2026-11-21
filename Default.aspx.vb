Imports System

''' <summary>The site root opens the Dashboard (the main page after login).</summary>
Partial Class DefaultPage
    Inherits BasePage

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        Response.Redirect("~/Dashboard.aspx", False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub
End Class
