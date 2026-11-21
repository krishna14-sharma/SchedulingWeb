Imports System
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmLayerCalanderDataCURD (table ChickSchedule).</summary>
Partial Class LayerScheduleUpdatePage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function()
                           Dim dt As DataTable = Db.Table("select account_head_name + '-' + Areaname as account_head_name from " & AppCtx.HeadTable(AppCtx.FinYear) &
                                                          " a inner join Area ar on left(account_code, 2) = prefix where group_name = 'CUSTOMER' order by 1")
                           Return New With {.customers = Api.Col(dt, "account_head_name")}
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function List(ByVal scheduleDate As String) As ApiResult
        Return Api.Run(Function() Api.Rows(Db.Table("select * from ChickSchedule where [ScheduleDate] = @d order by ID",
                                                     Db.PDate("@d", AppCtx.ParseDate(scheduleDate, "Demand Date")))))
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Save(ByVal id As Integer, ByVal demandDate As String, ByVal customer As String, ByVal qty As Decimal) As ApiResult
        Return Api.Run(Function()
                           Dim d As DateTime = AppCtx.ParseDate(demandDate, "Demand Date")
                           If qty <= 0 Then Throw New UserError("Please enter Qty")
                           If AppCtx.Str(customer).Trim() = "" Then Throw New UserError("Please select Customer Name")
                           Db.Exec("insert into [ChickSchedule]([DemandDate], [CustomerName], [DemandQty], [CreatedOn], [ScheduleDate], [Qty]) values (@d, @c, @q, @now, @d, 0)",
                                   Db.PDate("@d", d), Db.P("@c", customer), Db.P("@q", qty), Db.PDate("@now", DateTime.Today))
                           Return Api.Ok(Nothing, "Layer demand saved.")
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Update(ByVal id As Integer, ByVal demandDate As String, ByVal customer As String, ByVal qty As Decimal) As ApiResult
        Return Api.Run(Function()
                           If id <= 0 Then Throw New UserError("Select a row first.")
                           Dim d As DateTime = AppCtx.ParseDate(demandDate, "Demand Date")
                           Db.Exec("update [ChickSchedule] set DemandDate = @d, CustomerName = @c, DemandQty = @q, CreatedOn = @now, ScheduleDate = @d, Qty = 0 where ID = @id",
                                   Db.PDate("@d", d), Db.P("@c", customer), Db.P("@q", qty), Db.PDate("@now", DateTime.Today), Db.P("@id", id))
                           Return Api.Ok(Nothing, "Layer demand updated.")
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Delete(ByVal id As Integer) As ApiResult
        Return Api.Run(Function()
                           If id <= 0 Then Throw New UserError("Select a row first.")
                           Db.Exec("delete from ChickSchedule where id = @id", Db.P("@id", id))
                           Return Api.Ok(Nothing, "Layer demand deleted.")
                       End Function)
    End Function

End Class
