Imports System
Imports System.Globalization
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmHatchQty (table Hatch_Qty).</summary>
Partial Class HatchProductionPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function()
                           Dim yr As String = AppCtx.FinYear
                           Return New With {
                               .units = Api.Col(Db.Table("select Hatcheryies from Hatcheries order by Hatcheryies"), "Hatcheryies"),
                               .minDate = AppCtx.FinYearStart(yr).ToString("yyyy-MM-dd"),
                               .maxDate = AppCtx.FinYearEnd(yr).ToString("yyyy-MM-dd")
                           }
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function List() As ApiResult
        Return Api.Run(Function() Api.Rows(Db.Table(
            "select id, Hatch_date, Hatch_Qty, prd_unit from Hatch_Qty where session = @s and cmp_id = @c order by Hatch_date desc, id desc",
            Db.P("@s", AppCtx.FinYear), Db.P("@c", AppCtx.CmpId))))
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Save(ByVal hatchDate As String, ByVal qty As Decimal, ByVal unit As String) As ApiResult
        Return Api.Run(Function()
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           Dim yr As String = AppCtx.FinYear
                           If d < AppCtx.FinYearStart(yr) OrElse d > AppCtx.FinYearEnd(yr) Then
                               Throw New UserError("Hatch Date must be inside the session " & AppCtx.FinYearStart(yr).ToString("dd/MMM/yyyy", CultureInfo.InvariantCulture) & " - " & AppCtx.FinYearEnd(yr).ToString("dd/MMM/yyyy", CultureInfo.InvariantCulture) & ".")
                           End If
                           If qty <= 0 Then Throw New UserError("Item Qty Required")
                           If AppCtx.Str(unit) = "" Then Throw New UserError("Select Prod. Unit")
                           Db.Exec("insert into Hatch_Qty(Hatch_date, Hatch_Qty, Entry_date, Session, cmp_id, prd_unit) values (@d, @q, @e, @s, @c, @u)",
                                   Db.PDate("@d", d), Db.P("@q", qty), Db.PDate("@e", DateTime.Today), Db.P("@s", yr), Db.P("@c", AppCtx.CmpId), Db.P("@u", unit))
                           Return Api.Ok(Nothing, "Hatch Qty Saved")
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Delete(ByVal id As Integer) As ApiResult
        Return Api.Run(Function()
                           Db.Exec("delete from Hatch_Qty where id = @id", Db.P("@id", id))
                           Return Api.Ok(Nothing, "Entry deleted.")
                       End Function)
    End Function

End Class
