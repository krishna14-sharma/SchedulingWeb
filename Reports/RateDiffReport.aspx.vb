Imports System
Imports System.Data
Imports System.Web.Services

''' <summary>
''' New report: scheduled quantity per customer with Schedule Rate vs Circular Rate and the difference.
''' Filters: hatchery (or ALL), hatch date range, chicks type (Broiler = Broiler + Broiler(M), Layer or Cockrel).
''' Diff = CircularRate - ScheduleRate; Diff Amount = Diff x Quantity.
''' </summary>
Partial Class RateDiffReportPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function() New With {.hatcheries = Api.Col(AppCtx.ActiveHatcheries(), "Hatcheryies")})
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Run(ByVal hatchery As String, ByVal all As Boolean, ByVal fromDate As String, ByVal toDate As String, ByVal chickType As String) As ApiResult
        Return Api.Run(Function()
                           Dim d1 As DateTime = AppCtx.ParseDate(fromDate, "Hatch Date From")
                           Dim d2 As DateTime = AppCtx.ParseDate(toDate, "Hatch Date To")
                           If d1 > d2 Then Throw New UserError("From date is after To date.")
                           Dim sql As String = "select Hatch_DAte, Cust_Code, Cust_Name, Areaname, Hatchery, Productname, " &
                                               " isnull(QtyNet,0) + isnull(Qty2Per,0) as Quantity, isnull(Qty2Per,0) as FreeQty, isnull(Rate,0) as ScheduleRate, isnull(CircularRate,0) as CircularRate, " &
                                               " isnull(CircularRate,0) - isnull(Rate,0) as Diff, " &
                                               " (isnull(CircularRate,0) - isnull(Rate,0)) * isnull(QtyNet,0) as DiffAmount " &
                                               "from V_ScheduleRepo where hatch_date between @d1 and @d2 and isnull(QtyNet,0) > 0"
                           Select Case chickType
                               Case "Layer" : sql &= " and productname = 'Layer'"
                               Case "Cockrel" : sql &= AppCtx.ChickTypeFilter("productname", "Cockrel")
                               Case Else : sql &= " and productname in ('Broiler','Broiler(M)')"
                           End Select
                           If Not all Then
                               If AppCtx.Str(hatchery) = "" Then Throw New UserError("Select Hatchery or tick ALL.")
                               sql &= " and hatchery = @h"
                           End If
                           sql &= " order by hatch_date, Cust_Code"
                           Return Api.Rows(Db.Table(sql, Db.PDate("@d1", d1), Db.PDate("@d2", d2), Db.P("@h", AppCtx.Str(hatchery))))
                       End Function)
    End Function

End Class
