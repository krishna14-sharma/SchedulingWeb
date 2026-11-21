Imports System
Imports System.Globalization
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmshedule / frmSheduling.vb (Dealer / Other Scheduling, table Shedule).</summary>
Partial Class DealerSchedulingPage
    Inherits BasePage

    Private Shared Function SafeKind(ByVal kind As String) As String
        If kind = "DR" OrElse kind = "OT" Then Return kind
        Throw New UserError("Select Dealer or Others.")
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function() New With {
                           .chickTypes = Api.Col(AppCtx.ChickTypes(), "Chick_type"),
                           .hatcheries = Api.Col(AppCtx.ActiveHatcheries(), "Hatcheryies"),
                           .minDate = AppCtx.MinHatchDate().ToString("yyyy-MM-dd")
                       })
    End Function

    ''' <summary>FillHeds: customers whose area_code contains DR (Dealer) or OT (Others).</summary>
    <WebMethod(EnableSession:=True)>
    Public Shared Function Heads(ByVal kind As String) As ApiResult
        Return Api.Run(Function() Api.Rows(Db.Table(
            "select account_code, account_head_name from " & AppCtx.HeadTable(AppCtx.FinYear) &
            " where area_code like @k and GROUP_NAME = 'Customer' order by account_head_name",
            Db.P("@k", "%" & SafeKind(kind) & "%"))))
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Balance(ByVal code As String) As ApiResult
        Return Api.Run(Function()
                           Dim b As Decimal() = AppCtx.GetBalance(code)
                           Return New With {.dr = b(0), .cr = b(1)}
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function List(ByVal hatchDate As String, ByVal kind As String) As ApiResult
        Return Api.Run(Function() Api.Rows(Db.Table(
            "select * from Shedule where hatch_Date = @d and Area_Code = @k order by id",
            Db.PDate("@d", AppCtx.ParseDate(hatchDate, "Hatch Date")), Db.P("@k", SafeKind(kind)))))
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Save(ByVal entry As DealerSchedule) As ApiResult
        Return Api.Run(Function()
                           Dim k As String = SafeKind(entry.kind)
                           Dim d As DateTime = AppCtx.ParseDate(entry.hatchDate, "Hatch Date")
                           If d < AppCtx.MinHatchDate() Then Throw New UserError("Hatch Date cannot be earlier than " & AppCtx.MinHatchDate().ToString("dd/MMM/yyyy", CultureInfo.InvariantCulture) & ".")
                           If entry.qty <= 0 Then Throw New UserError("Please enter Qty")
                           If AppCtx.Str(entry.custCode).Trim() = "" Then Throw New UserError("Please select head")
                           Dim free As Decimal = AppCtx.FreeChicks(entry.qty, entry.chickType)
                           Dim amount As Decimal = (entry.qty - free) * entry.rate

                           Db.Exec("insert into Shedule(Area_Code, Cust_Code, Cust_Name, Hatch_DAte, Productname, Qty2Per, QtyNet, Rate, Amount, " &
                                   " Trans_Mode, Hatchery, SheduleDate, Session, rem1, CircularRate, [DemandQty], [DemandRate], comprate, dr, cr, Uname) values " &
                                   "(@area, @code, @name, @hd, @prd, @free, @qty, @rate, @amt, '-', @hatch, @sd, @sess, '-', @circ, @qty, @rate, @comp, @dr, @cr, @user)",
                                   Db.P("@area", k), Db.P("@code", entry.custCode), Db.P("@name", entry.custName), Db.PDate("@hd", d),
                                   Db.P("@prd", entry.chickType), Db.P("@free", free), Db.P("@qty", entry.qty), Db.P("@rate", entry.rate),
                                   Db.P("@amt", amount), Db.P("@hatch", entry.hatchery), Db.PDate("@sd", DateTime.Today), Db.P("@sess", AppCtx.FinYear),
                                   Db.P("@circ", entry.circularRate), Db.P("@comp", entry.compRate), Db.P("@dr", entry.dr), Db.P("@cr", entry.cr),
                                   Db.P("@user", AppCtx.UserName))
                           Return Api.Ok(Nothing, "Schedule saved.")
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Update(ByVal entry As DealerSchedule) As ApiResult
        Return Api.Run(Function()
                           If entry.id <= 0 Then Throw New UserError("Select a schedule row first.")
                           If entry.qty <= 0 Then Throw New UserError("Please enter Qty")
                           Dim d As DateTime = AppCtx.ParseDate(entry.hatchDate, "Hatch Date")
                           Dim free As Decimal = AppCtx.FreeChicks(entry.qty, entry.chickType)
                           Dim amount As Decimal = (entry.qty - free) * entry.rate
                           Db.Exec("update Shedule set qtynet = @qty, rate = @rate, Qty2Per = @free, amount = @amt, CircularRate = @circ, " &
                                   "[DemandQty] = @qty, [DemandRate] = @rate, Productname = @prd where id = @id",
                                   Db.P("@qty", entry.qty), Db.P("@rate", entry.rate), Db.P("@free", free), Db.P("@amt", amount),
                                   Db.P("@circ", entry.circularRate), Db.P("@prd", entry.chickType), Db.P("@id", entry.id))
                           AppCtx.WriteLog("DR", "SCHEDULE", d, "M")
                           Return Api.Ok(Nothing, "Schedule updated.")
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Delete(ByVal id As Integer, ByVal hatchDate As String) As ApiResult
        Return Api.Run(Function()
                           If id <= 0 Then Throw New UserError("Select a schedule row first.")
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           Db.Exec("delete from Shedule where id = @id", Db.P("@id", id))
                           AppCtx.WriteLog("DR", "SCHEDULE", d, "D")
                           Return Api.Ok(Nothing, "Schedule deleted.")
                       End Function)
    End Function

End Class
