Imports System
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmLayerTentativeDate (Crystal report CrystalReport1 / DataSet1.LayerTentativeData).</summary>
Partial Class LayerTentativeDatePage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function() New With {.stations = Api.Col(Db.Table("select distinct station from LayerTentativeData order by station"), "station")})
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Run(ByVal station As String) As ApiResult
        Return Api.Run(Function()
                           ' The WinForms query read a fixed head table (ACC_HEAD_PHHA_2425); it is now set in Web.config.
                           Dim headTable As String = AppCtx.SafeTableName(AppCtx.Setting("LayerTentativeHeadTable", "ACC_HEAD_PHHA_2425"))
                           Dim sql As String = "select v.account_code, v.account_head_name, v.address, v.state, v.phone, q.Qty, q.T75, q.T85, q.T90, q.Station " &
                                               "from " & headTable & " v inner join ( " &
                                               "  select AccCode, AccNAme, Station, qty, " &
                                               "  DATEADD(week, 75, HatchDate) AS T75, DATEADD(week, 85, HatchDate) AS T85, DATEADD(week, 90, HatchDate) AS T90 " &
                                               "  from PrintData where ProductName = 'Layer Chicks' and Cmp_id = 'PHHA' " &
                                               "  and DATEADD(week, 70, HatchDate) > @today and Vou_type not like '%PURCHASE%') q " &
                                               "on v.account_code = q.AccCode "
                           If AppCtx.Str(station) <> "" Then sql &= " where q.Station = @st"
                           sql &= " order by T75"
                           Return Api.Rows(Db.Table(sql, Db.PDate("@today", DateTime.Today), Db.P("@st", AppCtx.Str(station))))
                       End Function)
    End Function

End Class
