Imports System
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmMonthlyDealterReport (Crystal report CrMonthlyDelaredata over V_ScheduleRepo).</summary>
Partial Class MonthlyDealerReportPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function() New With {
                           .chickTypes = Api.Col(AppCtx.ChickTypes(), "Chick_type"),
                           .areas = Api.Rows(Db.Table("select AreaName, prefix from AreaS where prefix is not null order by AreaName"))
                       })
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Heads(ByVal kind As String, ByVal areaCode As String) As ApiResult
        Return Api.Run(Function()
                           Dim k As String = If(kind = "OT", "OT", "DR")
                           Dim sql As String = "select account_code, account_head_name from " & AppCtx.HeadTable(AppCtx.FinYear) &
                                               " where area_code like @k and GROUP_NAME = 'Customer'"
                           ' account codes start with the area prefix (e.g. BSCU0213 -> BS)
                           If AppCtx.Str(areaCode) <> "" Then sql &= " and left(account_code, 2) = @a"
                           sql &= " order by account_head_name"
                           Return Api.Rows(Db.Table(sql, Db.P("@k", "%" & k & "%"), Db.P("@a", AppCtx.Str(areaCode))))
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Run(ByVal fromDate As String, ByVal toDate As String, ByVal chickType As String, ByVal all As Boolean, ByVal code As String,
                               ByVal areaCode As String, ByVal areaName As String) As ApiResult
        Return Api.Run(Function()
                           Dim d1 As DateTime = AppCtx.ParseDate(fromDate, "From date")
                           Dim d2 As DateTime = AppCtx.ParseDate(toDate, "To date")
                           Dim sql As String = "select *, isnull(QtyNet,0) + isnull(Qty2Per,0) as Quantity from V_ScheduleRepo where hatch_date between @d1 and @d2 and session = @s" & AppCtx.ChickTypeFilter("productname", chickType)
                           If all Then
                               ' ALL with no area = all dealers (codes containing DR), as before;
                               ' ALL with an area = every customer of that area (filtered below)
                               If AppCtx.Str(areaCode) = "" Then sql &= " and cust_Code like '%DR%'"
                           Else
                               If AppCtx.Str(code) = "" Then Throw New UserError("Select a name or tick ALL.")
                               sql &= " and cust_Code = @code"
                           End If
                           If AppCtx.Str(areaCode) <> "" Then
                               ' customer codes start with the area prefix; the view's Areaname is matched as well
                               sql &= " and (left(Cust_Code, 2) = @a or Areaname = @an)"
                           End If
                           sql &= " order by hatch_date"
                           Return Api.Rows(Db.Table(sql, Db.PDate("@d1", d1), Db.PDate("@d2", d2), Db.P("@p", AppCtx.Str(chickType)),
                                                    Db.P("@s", AppCtx.FinYear), Db.P("@code", AppCtx.Str(code)),
                                                    Db.P("@a", AppCtx.Str(areaCode)), Db.P("@an", AppCtx.Str(areaName))))
                       End Function)
    End Function

End Class
