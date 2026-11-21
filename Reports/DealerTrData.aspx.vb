Imports System
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmDealerTrData (Crystal report CrTrDataMonthly over AreaTrData).</summary>
Partial Class DealerTrDataPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function() New With {.chickTypes = Api.Col(AppCtx.ChickTypes(), "Chick_type")})
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Heads(ByVal kind As String) As ApiResult
        Return Api.Run(Function()
                           Dim k As String = If(kind = "OT", "OT", "DR")
                           Return Api.Rows(Db.Table("select account_code, account_head_name from " & AppCtx.HeadTable(AppCtx.FinYear) &
                                                    " where area_code like @k and GROUP_NAME = 'Customer' order by account_head_name", Db.P("@k", "%" & k & "%")))
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Run(ByVal fromDate As String, ByVal toDate As String, ByVal chickType As String, ByVal all As Boolean, ByVal code As String) As ApiResult
        Return Api.Run(Function()
                           Dim d1 As DateTime = AppCtx.ParseDate(fromDate, "From date")
                           Dim d2 As DateTime = AppCtx.ParseDate(toDate, "To date")
                           Dim sql As String = "select * from AreaTrData where Trdate between @d1 and @d2 and session = @s" & AppCtx.ChickTypeFilter("chick_type", chickType)
                           If all Then
                               sql &= " and Code like '%DR%'"
                           Else
                               If AppCtx.Str(code) = "" Then Throw New UserError("Select a name or tick ALL.")
                               sql &= " and Code = @code"
                           End If
                           sql &= " order by Trdate"
                           Return Api.Rows(Db.Table(sql, Db.PDate("@d1", d1), Db.PDate("@d2", d2), Db.P("@p", AppCtx.Str(chickType)),
                                                    Db.P("@s", AppCtx.FinYear), Db.P("@code", AppCtx.Str(code))))
                       End Function)
    End Function

End Class
