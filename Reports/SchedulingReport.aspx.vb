Imports System
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmHatchReport (Crystal report CrRepSchedule over view V_ScheduleRepo).</summary>
Partial Class SchedulingReportPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function() New With {
                           .chickTypes = Api.Col(AppCtx.ChickTypes(), "Chick_type"),
                           .hatcheries = Api.Col(AppCtx.ActiveHatcheries(), "Hatcheryies")
                       })
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Run(ByVal hatchDate As String, ByVal chickType As String, ByVal hatchery As String, ByVal all As Boolean) As ApiResult
        Return Api.Run(Function()
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           Dim sql As String = "select * from V_ScheduleRepo where hatch_date = @d"
                           ' Broiler and Broiler(M) are always reported together
                           sql &= AppCtx.ChickTypeFilter("productname", chickType, True)
                           If Not all Then sql &= " and hatchery = @h"
                           sql &= " order by Hatchery, id"
                           Return Api.Rows(Db.Table(sql, Db.PDate("@d", d), Db.P("@p", AppCtx.Str(chickType)), Db.P("@h", AppCtx.Str(hatchery))))
                       End Function)
    End Function

End Class
