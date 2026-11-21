Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Collections.Generic
Imports System.Web.Services

''' <summary>Converted from frmShedulingByDemand_Edit (edits existing Shedule rows).</summary>
Partial Class EditSchedulingPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function() New With {
                           .areas = Api.Rows(Db.Table("select AreaName, prefix from AreaS order by AreaName")),
                           .chickTypes = Api.Col(AppCtx.ChickTypes(), "Chick_type"),
                           .hatcheries = Api.Col(AppCtx.ActiveHatcheries(), "Hatcheryies"),
                           .minDate = AppCtx.MinHatchDate().ToString("yyyy-MM-dd")
                       })
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Show(ByVal areaCode As String, ByVal hatchDate As String, ByVal chickType As String) As ApiResult
        Return Api.Run(Function()
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           Dim dt As DataTable = Db.Table("select * from Shedule where Hatch_DAte = @d and Productname = @p and Area_Code = @a order by Id",
                                                          Db.PDate("@d", d), Db.P("@p", chickType), Db.P("@a", areaCode))
                           Dim list As New List(Of Dictionary(Of String, Object))
                           For Each r As DataRow In dt.Rows
                               Dim row As New Dictionary(Of String, Object)
                               row("id") = r("Id")
                               row("code") = AppCtx.Str(r("Cust_Code"))
                               row("name") = AppCtx.Str(r("Cust_Name"))
                               row("demandQty") = Api.ToJsonValue(r("DemandQty"))
                               row("rate") = Api.ToJsonValue(r("DemandRate"))
                               row("scheduleQty") = Api.ToJsonValue(r("QtyNet"))
                               row("free") = Api.ToJsonValue(r("Qty2Per"))
                               row("scheduleRate") = Api.ToJsonValue(r("Rate"))
                               row("circularRate") = Api.ToJsonValue(r("CircularRate"))
                               row("hatchery") = AppCtx.Str(r("Hatchery"))
                               row("isEdit") = If(r("isEdit") Is DBNull.Value, 0, CInt(AppCtx.Num(r("isEdit"))))
                               list.Add(row)
                           Next
                           Return list
                       End Function)
    End Function

    ''' <summary>Button1_Click ("Update"): saves rows marked as edited, all in one transaction.</summary>
    <WebMethod(EnableSession:=True)>
    Public Shared Function Update(ByVal rows As List(Of ScheduleRow)) As ApiResult
        Return Api.Run(Function()
                           If rows Is Nothing OrElse rows.Count = 0 Then Throw New UserError("Nothing changed.")
                           Dim n As Integer = 0
                           Db.InTransaction(Sub(cn As SqlConnection, tx As SqlTransaction)
                                                For Each r As ScheduleRow In rows
                                                    If r.isEdit <> 1 OrElse r.id <= 0 Then Continue For
                                                    Db.ExecTx(cn, tx,
                                                        "update [dbo].[Shedule] set [QtyNet] = @qty, Qty2Per = @free, Rate = @rate, CircularRate = @circ, " &
                                                        "isEdit = @e, Hatchery = @hatch where id = @id",
                                                        Db.P("@qty", r.scheduleQty), Db.P("@free", r.free), Db.P("@rate", r.scheduleRate),
                                                        Db.P("@circ", r.circularRate), Db.P("@e", r.isEdit), Db.P("@hatch", AppCtx.Str(r.hatchery)), Db.P("@id", r.id))
                                                    n += 1
                                                Next
                                            End Sub)
                           Return Api.Ok(n, "Data saved successfully! (" & n & " rows updated)")
                       End Function)
    End Function

    ''' <summary>Button2_Click ("Delete"): removes the area's schedule for the hatch date (all chick types, as before).</summary>
    <WebMethod(EnableSession:=True)>
    Public Shared Function DeleteAll(ByVal areaCode As String, ByVal hatchDate As String) As ApiResult
        Return Api.Run(Function()
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           If AppCtx.Str(areaCode) = "" Then Throw New UserError("Select Area")
                           Dim n As Integer = Db.Exec("delete from Shedule where Hatch_DAte = @d and Area_Code = @a", Db.PDate("@d", d), Db.P("@a", areaCode))
                           AppCtx.WriteLog(areaCode, "SCHDULE", d, "D")
                           Return Api.Ok(n, n & " schedule rows deleted.")
                       End Function)
    End Function

End Class
