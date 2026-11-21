Imports System
Imports System.Globalization
Imports System.Data
Imports System.Data.SqlClient
Imports System.Collections.Generic
Imports System.Web.Services

''' <summary>Converted from frmShedulingByDemand (creates Shedule rows from AreaDemandData).</summary>
Partial Class DemandSchedulingPage
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

    Private Shared Sub EnsureNotScheduled(ByVal areaCode As String, ByVal d As DateTime, ByVal chickType As String)
        Dim n As Integer = CInt(AppCtx.Num(Db.Scalar("select count(*) from Shedule where Hatch_DAte = @d and Productname = @p and Area_Code = @a",
                                                     Db.PDate("@d", d), Db.P("@p", chickType), Db.P("@a", areaCode))))
        If n > 0 Then
            Throw New UserError("Scheduling Already Done for Area " & areaCode & " on Hatch Date: " & d.ToString("dd/MMM/yyyy", CultureInfo.InvariantCulture) & ". Use Edit Scheduling to change it.")
        End If
    End Sub

    ''' <summary>btsave_Click ("Show"): loads the demand for the area / date / chick type.</summary>
    <WebMethod(EnableSession:=True)>
    Public Shared Function Show(ByVal areaCode As String, ByVal hatchDate As String, ByVal chickType As String, ByVal kind As String) As ApiResult
        Return Api.Run(Function()
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           If AppCtx.Str(areaCode) = "" Then Throw New UserError("Select Area")
                           EnsureNotScheduled(areaCode, d, chickType)

                           Dim isCustomer As Boolean = (kind <> "DR")
                           Dim demandArea As String = If(isCustomer, areaCode, "DR")
                           Dim dt As DataTable = Db.Table("select Code, CName, TotalChicks, Mortality from AreaDemandData " &
                                                          "where HatchDate = @d and AreaCode = @a and chick_type = @p",
                                                          Db.PDate("@d", d), Db.P("@a", demandArea), Db.P("@p", chickType))
                           Dim per As Decimal = AppCtx.FreePercent(chickType)
                           Dim list As New List(Of Dictionary(Of String, Object))
                           For Each r As DataRow In dt.Rows
                               Dim total As Decimal = AppCtx.Num(r("TotalChicks"))
                               Dim row As New Dictionary(Of String, Object)
                               row("id") = 0
                               row("code") = AppCtx.Str(r("Code"))
                               row("name") = AppCtx.Str(r("CName"))
                               row("demandQty") = Api.ToJsonValue(r("TotalChicks"))
                               row("rate") = Api.ToJsonValue(r("Mortality"))
                               row("hatchery") = ""
                               row("isEdit") = 0
                               If isCustomer Then
                                   row("scheduleQty") = Math.Round(total)
                                   row("free") = Math.Round(total * per / 100D, 0)
                                   row("scheduleRate") = Api.ToJsonValue(r("Mortality"))
                                   Dim bal As Decimal() = AppCtx.GetBalance(AppCtx.Str(r("Code")))
                                   row("dr") = bal(0)
                                   row("cr") = bal(1)
                               Else
                                   ' Dealer: the WinForms grid only filled code, name, demand qty and rate.
                                   row("scheduleQty") = Nothing
                                   row("free") = Nothing
                                   row("scheduleRate") = Nothing
                                   row("dr") = Nothing
                                   row("cr") = Nothing
                               End If
                               row("circularRate") = Nothing
                               row("compRate") = Nothing
                               list.Add(row)
                           Next
                           Return list
                       End Function)
    End Function

    ''' <summary>Button1_Click ("Save"): inserts one Shedule row per grid row, all in one transaction.</summary>
    <WebMethod(EnableSession:=True)>
    Public Shared Function Save(ByVal areaCode As String, ByVal hatchDate As String, ByVal chickType As String, ByVal rows As List(Of ScheduleRow)) As ApiResult
        Return Api.Run(Function()
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           If d < AppCtx.MinHatchDate() Then Throw New UserError("Hatch Date cannot be earlier than " & AppCtx.MinHatchDate().ToString("dd/MMM/yyyy", CultureInfo.InvariantCulture) & ".")
                           If rows Is Nothing OrElse rows.Count = 0 Then Throw New UserError("Nothing to save.")
                           For i As Integer = 0 To rows.Count - 1
                               If AppCtx.Str(rows(i).hatchery).Trim() = "" Then Throw New UserError("Row " & (i + 1) & " (" & rows(i).name & "): select a hatchery.")
                           Next
                           EnsureNotScheduled(areaCode, d, chickType)

                           Dim yr As String = AppCtx.FinYear
                           Dim user As String = AppCtx.UserName
                           Db.InTransaction(Sub(cn As SqlConnection, tx As SqlTransaction)
                                                For Each r As ScheduleRow In rows
                                                    Db.ExecTx(cn, tx,
                                                        "insert into Shedule(Area_Code, Cust_Code, Cust_Name, Hatch_DAte, Productname, Qty2Per, QtyNet, Rate, Amount, " &
                                                        " Trans_Mode, Hatchery, SheduleDate, Session, rem1, CircularRate, DemandQty, DemandRate, Comprate, dr, cr, Uname) values " &
                                                        "(@area, @code, @name, @hd, @prd, @free, @qty, @srate, 0, '-', @hatch, @hd, @sess, '-', @circ, @dqty, @drate, @comp, @dr, @cr, @user)",
                                                        Db.P("@area", areaCode), Db.P("@code", r.code), Db.P("@name", r.name), Db.PDate("@hd", d),
                                                        Db.P("@prd", chickType), Db.P("@free", r.free), Db.P("@qty", r.scheduleQty), Db.P("@srate", r.scheduleRate),
                                                        Db.P("@hatch", r.hatchery), Db.P("@sess", yr), Db.P("@circ", r.circularRate),
                                                        Db.P("@dqty", r.demandQty), Db.P("@drate", r.rate), Db.P("@comp", r.compRate),
                                                        Db.P("@dr", r.dr), Db.P("@cr", r.cr), Db.P("@user", user))
                                                Next
                                            End Sub)
                           Return Api.Ok(Nothing, "Data saved successfully! (" & rows.Count & " rows)")
                       End Function)
    End Function

End Class
