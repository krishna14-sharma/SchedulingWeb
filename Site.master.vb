Imports System
Partial Class SiteMaster
    Inherits System.Web.UI.MasterPage

    Protected ReadOnly Property UserName() As String
        Get
            Return AppCtx.UserName
        End Get
    End Property

    Protected ReadOnly Property FinYearLabel() As String
        Get
            Dim y As String = AppCtx.FinYear
            Return "20" & y.Substring(0, 2) & "-" & y.Substring(2, 2)
        End Get
    End Property

    Protected ReadOnly Property LayerScheduleUrl() As String
        Get
            Return AppCtx.Setting("LayerScheduleUrl", "#")
        End Get
    End Property

End Class
