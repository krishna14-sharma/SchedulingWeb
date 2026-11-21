Imports System
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmEditDemandData (table AreaDemandData).</summary>
Partial Class EditDemandPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function() New With {.areas = Api.Rows(Db.Table("select distinct Areaname, prefix from Area order by Areaname"))})
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Show(ByVal areaName As String, ByVal prefix As String, ByVal fromDate As String, ByVal toDate As String, ByVal chickType As String) As ApiResult
        Return Api.Run(Function()
                           Dim d1 As DateTime = AppCtx.ParseDate(fromDate, "Hatch Date From")
                           Dim d2 As DateTime = AppCtx.ParseDate(toDate, "Hatch Date To")
                           Dim yr As String = AppCtx.CurrentSession()
                           Dim sql As String = "select Area, DMNo, DMDate, HatchDate, Code, CName, Chick_type, TotalChicks DemadedChicks, Mortality Rate, Remarks, id " &
                                               "from AreaDemandData where Area = @area and HatchDate between @d1 and @d2 and session = @s and isnull(isposted,0) = 0"
                           If AppCtx.Str(chickType) <> "" Then sql &= AppCtx.ChickTypeFilter("Chick_type", chickType).Replace("@p", "@t")
                           sql &= " order by HatchDate"
                           Dim rows As DataTable = Db.Table(sql, Db.P("@area", areaName), Db.PDate("@d1", d1), Db.PDate("@d2", d2), Db.P("@s", yr), Db.P("@t", AppCtx.Str(chickType)))

                           ' fillCustomer: customers of the area (account code starts with the area prefix)
                           Dim customers As DataTable = Db.Table("select account_code, account_head_name from " & AppCtx.HeadTable(yr) &
                                                                 " where cmp_id = 'PHHA' and group_name = 'CUSTOMER' and left(account_code,2) = @p order by account_head_name",
                                                                 Db.P("@p", AppCtx.Str(prefix)))
                           Return New With {.rows = Api.Rows(rows), .customers = Api.Rows(customers)}
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Update(ByVal id As Integer, ByVal hatchDate As String, ByVal code As String, ByVal cname As String,
                                  ByVal chickType As String, ByVal totalChicks As Decimal, ByVal rate As Decimal, ByVal remarks As String) As ApiResult
        Return Api.Run(Function()
                           If id <= 0 Then Throw New UserError("Please Select a DEMAND")
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           If AppCtx.Str(code) = "" Then Throw New UserError("Select Customer")
                           Db.Exec("update AreaDemandData set HatchDate = @d, Code = @c, CName = @n, Chick_type = @t, TotalChicks = @tot, Remarks = @r, Mortality = @rate where id = @id",
                                   Db.PDate("@d", d), Db.P("@c", code), Db.P("@n", cname), Db.P("@t", chickType), Db.P("@tot", totalChicks),
                                   Db.P("@r", AppCtx.Str(remarks)), Db.P("@rate", rate), Db.P("@id", id))
                           AppCtx.WriteLog("", "DEMAND", d, "M")
                           Return Api.Ok(Nothing, "Demand updated.")
                       End Function)
    End Function

    ''' <summary>Button3 ("Cancel"): keeps the DM but blanks it as CANCELLED BY HO.</summary>
    <WebMethod(EnableSession:=True)>
    Public Shared Function CancelDemand(ByVal id As Integer, ByVal hatchDate As String, ByVal chickType As String) As ApiResult
        Return Api.Run(Function()
                           If id <= 0 Then Throw New UserError("Please Select a DEMAND")
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           Db.Exec("update AreaDemandData set HatchDate = @d, Code = 'CANCELLED', CName = 'CANCELLED', Chick_type = @t, Rate = 0, " &
                                   "TotalChicks = 0, Remarks = 'CANCELLED BY HO', Mortality = 0 where id = @id",
                                   Db.PDate("@d", d), Db.P("@t", chickType), Db.P("@id", id))
                           Return Api.Ok(Nothing, "Demand cancelled.")
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Delete(ByVal id As Integer, ByVal hatchDate As String) As ApiResult
        Return Api.Run(Function()
                           If id <= 0 Then Throw New UserError("Please Select a DEMAND")
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           Db.Exec("delete from AreaDemandData where id = @id", Db.P("@id", id))
                           AppCtx.WriteLog("", "DEMAND", d, "D")
                           Return Api.Ok(Nothing, "Demand deleted.")
                       End Function)
    End Function

End Class
