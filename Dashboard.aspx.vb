Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Collections.Generic
Imports System.Web.Services

''' <summary>Dashboard: schedule vs demand for a hatch date, hatchery load, area gaps, 14-day trend and pending approvals.</summary>
Partial Class DashboardPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function() New With {.chickTypes = Api.Col(AppCtx.ChickTypes(), "Chick_type")})
    End Function

    ''' <summary>chickType "" = all types; Broiler includes Broiler(M); Cockrel matches both spellings.</summary>
    Private Shared Function TypeFilter(ByVal column As String, ByVal chickType As String) As String
        If AppCtx.Str(chickType).Trim() = "" Then Return ""
        Return AppCtx.ChickTypeFilter(column, chickType, True)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Data(ByVal fromDate As String, ByVal toDate As String, ByVal chickType As String) As ApiResult
        Return Api.Run(Function()
                           Dim d1 As DateTime = AppCtx.ParseDate(fromDate, "Hatch Date From")
                           Dim d2 As DateTime = AppCtx.ParseDate(toDate, "Hatch Date To")
                           If d1 > d2 Then Throw New UserError("Hatch Date From is after Hatch Date To.")
                           If (d2 - d1).TotalDays > 366 Then Throw New UserError("Choose a range of one year or less.")
                           Dim t As String = AppCtx.Str(chickType)
                           Dim sf As String = TypeFilter("Productname", t)
                           Dim df As String = TypeFilter("Chick_type", t)
                           ' fresh parameters for every command (a SqlParameter can only belong to one command)
                           Dim ps As Func(Of SqlParameter()) = Function() New SqlParameter() {Db.PDate("@d1", d1), Db.PDate("@d2", d2), Db.P("@p", t)}

                           ' ---- headline figures for the range
                           Dim k As DataTable = Db.Table("select isnull(sum(QtyNet),0) as qty, isnull(sum(Qty2Per),0) as free, count(distinct Cust_Code) as customers, " &
                                                         "sum(case when isnull(Rate,0) > 0 then QtyNet * Rate end) / nullif(sum(case when isnull(Rate,0) > 0 then QtyNet end),0) as avgRate, " &
                                                         "avg(case when isnull(Rate,0) > 0 then Rate * 1.0 end) as simpleRate, " &
                                                         "sum(case when isnull(Rate,0) > 0 then 0 else 1 end) as zeroRateRows, " &
                                                         "min(case when isnull(Rate,0) > 0 then Rate end) as minRate, max(Rate) as maxRate, " &
                                                         "count(distinct Hatchery) as hatcheries, count(distinct Hatch_DAte) as hatchDays " &
                                                         "from Shedule where Hatch_DAte between @d1 and @d2 and isnull(QtyNet,0) > 0" & sf, ps())
                           Dim dem As DataTable = Db.Table("select isnull(sum(TotalChicks),0) as demand, count(distinct Code) as demandCustomers from AreaDemandData " &
                                                           "where HatchDate between @d1 and @d2 and isnull(Code,'') <> 'CANCELLED'" & df, ps())

                           ' ---- hatchery: scheduled vs hatch production (production has no chick type, so only with "all")
                           Dim hatch As DataTable = Db.Table("select Hatchery as name, sum(QtyNet) as scheduled from Shedule where Hatch_DAte between @d1 and @d2 and isnull(QtyNet,0) > 0" & sf &
                                                             " group by Hatchery order by sum(QtyNet) desc", ps())
                           Dim prod As DataTable = Nothing
                           If t = "" Then
                               prod = Db.Table("select prd_unit as name, sum(Hatch_Qty) as production from Hatch_Qty where Hatch_date between @d1 and @d2 group by prd_unit", ps())
                           End If

                           ' ---- area: demand vs scheduled (top 10)
                           Dim area As DataTable = Db.Table(
                               "select top 10 isnull(a.Areaname, x.code) as name, x.code, sum(x.demand) as demand, sum(x.scheduled) as scheduled from ( " &
                               "  select AreaCode as code, sum(TotalChicks) as demand, 0 as scheduled from AreaDemandData where HatchDate between @d1 and @d2 and isnull(Code,'') <> 'CANCELLED'" & df & " group by AreaCode " &
                               "  union all " &
                               "  select Area_Code, 0, sum(QtyNet) from Shedule where Hatch_DAte between @d1 and @d2 and isnull(QtyNet,0) > 0" & sf & " group by Area_Code " &
                               ") x left join (select prefix, min(Areaname) as Areaname from Area group by prefix) a on a.prefix = x.code " &
                               "group by isnull(a.Areaname, x.code), x.code order by sum(x.demand) + sum(x.scheduled) desc", ps())

                           ' ---- daily trend: the selected range, or the 14 days ending on the date when a single day is chosen
                           Dim t1 As DateTime = If(d1 = d2, d2.AddDays(-13), d1)
                           Dim tp As Func(Of SqlParameter()) = Function() New SqlParameter() {Db.PDate("@d1", t1), Db.PDate("@d2", d2), Db.P("@p", t)}
                           Dim trendS As DataTable = Db.Table("select Hatch_DAte as day, sum(QtyNet) as qty from Shedule where Hatch_DAte between @d1 and @d2 and isnull(QtyNet,0) > 0" & sf &
                                                              " group by Hatch_DAte", tp())
                           Dim trendD As DataTable = Db.Table("select HatchDate as day, sum(TotalChicks) as qty from AreaDemandData where HatchDate between @d1 and @d2 and isnull(Code,'') <> 'CANCELLED'" & df &
                                                              " group by HatchDate", tp())
                           Dim trend As New List(Of Dictionary(Of String, Object))
                           Dim day As DateTime = t1
                           While day <= d2
                               Dim row As New Dictionary(Of String, Object)
                               row("day") = day.ToString("yyyy-MM-dd")
                               row("scheduled") = SumFor(trendS, day)
                               row("demand") = SumFor(trendD, day)
                               trend.Add(row)
                               day = day.AddDays(1)
                           End While

                           ' ---- chick type mix for the range (always all types)
                           Dim typeCase As String = "case when Productname in ('Broiler','Broiler(M)','Broiler(M )') then replace(Productname,' )',')') when Productname in ('Cockrel','Cockerel') then 'Cockrel' else Productname end"
                           Dim mix As DataTable = Db.Table("select " & typeCase & " as name, sum(QtyNet) as qty from Shedule where Hatch_DAte between @d1 and @d2 and isnull(QtyNet,0) > 0 " &
                                                           "group by " & typeCase & " order by 2 desc", ps())

                           ' ---- pending approvals (current session, not limited by the date range)
                           Dim yr As String = AppCtx.CurrentSession()
                           Dim pendingDm As Integer = 0, pendingTr As Integer = 0
                           Try
                               pendingDm = CInt(AppCtx.Num(Db.Scalar("select count(*) from AreaDMData where session = @s and isnull(isAuth,0) = 0", Db.P("@s", yr))))
                               pendingTr = CInt(AppCtx.Num(Db.Scalar("select count(*) from AreaTrData where session = @s and isnull(isAuth,0) = 0", Db.P("@s", yr))))
                           Catch
                           End Try

                           Return New With {
                               .kpi = Api.Rows(k)(0),
                               .demand = Api.Rows(dem)(0),
                               .hatchery = Api.Rows(hatch),
                               .production = If(prod Is Nothing, Nothing, Api.Rows(prod)),
                               .area = Api.Rows(area),
                               .trend = trend,
                               .trendIsRange = (d1 <> d2),
                               .mix = Api.Rows(mix),
                               .pendingDm = pendingDm,
                               .pendingTr = pendingTr
                           }
                       End Function)
    End Function

    Private Shared Function SumFor(ByVal dt As DataTable, ByVal day As DateTime) As Decimal
        Dim s As Decimal = 0D
        For Each r As DataRow In dt.Rows
            If r("day") IsNot DBNull.Value AndAlso CDate(r("day")).Date = day.Date Then s += AppCtx.Num(r("qty"))
        Next
        Return s
    End Function

End Class
