Imports System
Imports System.Web
Imports System.Web.UI

''' <summary>All screens inherit this: users who are not logged in are sent to the login page.</summary>
Public Class BasePage
    Inherits Page

    Protected Overrides Sub OnPreInit(ByVal e As EventArgs)
        If Not AppCtx.IsLoggedIn Then
            Response.Redirect("~/Login.aspx?returnUrl=" & HttpUtility.UrlEncode(Request.RawUrl), True)
            Return
        End If
        ' Pages hold no server state between AJAX calls, so the browser must not cache them after logout.
        Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Response.Cache.SetNoStore()
        MyBase.OnPreInit(e)
    End Sub

End Class
