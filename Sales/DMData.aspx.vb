Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Collections.Generic
Imports System.Web.Services

''' <summary>Converted from FormSupply (DM data / area wise supply, table AreaDMData, Crystal report CrSupplyReport1).</summary>
Partial Class DMDataPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function()
                           Dim yr As String = AppCtx.CurrentSession()
                           Return New With {
                               .areas = Api.Rows(Db.Table("select distinct prefix, prefix + ' - ' + Areaname as label from Area where prefix is not null order by prefix")),
                               .units = Api.Col(Db.Table("select distinct Hatchries from AreaDMData where session = @s order by Hatchries", Db.P("@s", yr)), "Hatchries")
                           }
                       End Function)
    End Function

    ''' <summary>Broiler and Broiler(M) are reported together; anything else that is not Layer is Cockrel.</summary>
    Private Shared Function BirdCategory(ByVal chickType As String) As String
        If chickType = "Broiler" OrElse chickType = "Broiler(M)" Then Return "'Broiler','Broiler(M)'"
        If chickType = "Layer" Then Return "'Layer'"
        Return "'Cockrel','Cockerel'"
    End Function

    ''' <summary>btnShow_Click (forPrint = False: only unauthorised rows, for ticking) and Button2_Click (forPrint = True).</summary>
    <WebMethod(EnableSession:=True)>
    Public Shared Function Run(ByVal f As DmFilter, ByVal forPrint As Boolean) As ApiResult
        Return Api.Run(Function()
                           Dim ps As New List(Of SqlParameter)
                           ps.Add(Db.P("@s", AppCtx.CurrentSession()))
                           Dim sql As String = "select Area, DMNo, DMDate, HatchDate, Code, CName, Chick_type, Rate, TotalChicks, Mortality, Hatchries, Remarks, isAuth " &
                                               "from AreaDMData where Chick_type in (" & BirdCategory(f.chickType) & ") and session = @s"
                           Dim mode As String = AppCtx.Str(f.mode)
                           Dim needArea As Boolean = False, needDates As Boolean = False, needUnit As Boolean = False
                           Select Case mode
                               Case "ALL AREA"
                               Case "SELECTED AREA"
                                   needArea = True
                               Case "BY HATCH DATE"
                                   needDates = True : needUnit = True
                               Case "SELECT AREA AND HATCH DATE"
                                   needArea = True : needDates = True : needUnit = True
                               Case "DM BETWEEN"
                                   needArea = True
                                   sql &= " and dmidarea between @m1 and @m2"
                                   ps.Add(Db.P("@m1", AppCtx.Num(f.dmFrom)))
                                   ps.Add(Db.P("@m2", AppCtx.Num(f.dmTo)))
                               Case Else
                                   Throw New UserError("Select a report option.")
                           End Select
                           If needArea Then
                               If AppCtx.Str(f.areaCode) = "" Then Throw New UserError("Select Area")
                               sql &= " and AreaCode = @a" : ps.Add(Db.P("@a", f.areaCode))
                           End If
                           If needDates Then
                               sql &= " and HatchDate between @d1 and @d2"
                               ps.Add(Db.PDate("@d1", AppCtx.ParseDate(f.fromDate, "Hatch Date")))
                               ps.Add(Db.PDate("@d2", AppCtx.ParseDate(f.toDate, "Hatch Date To")))
                           End If
                           If needUnit Then
                               sql &= " and Hatchries = @u" : ps.Add(Db.P("@u", AppCtx.Str(f.unit)))
                           End If
                           ' Authorisation filter, exactly as the WinForms screen: "BY HATCH DATE" follows the IS AUTH tick;
                           ' other options show only unauthorised DMs on screen and everything when printing.
                           If mode = "BY HATCH DATE" Then
                               sql &= " and isnull(isAuth,0) = @auth" : ps.Add(Db.P("@auth", If(f.isAuth, 1, 0)))
                           ElseIf Not forPrint Then
                               sql &= " and isnull(isAuth,0) = 0"
                           End If
                           sql &= If(forPrint AndAlso mode = "BY HATCH DATE", " order by Area, dmidarea", " order by dmidarea")
                           Return Api.Rows(Db.Table(sql, ps.ToArray()))
                       End Function)
    End Function

    ''' <summary>Button1_Click ("AUTH."): authorises the ticked DMs.</summary>
    <WebMethod(EnableSession:=True)>
    Public Shared Function Authorize(ByVal dmNos As List(Of String)) As ApiResult
        Return Api.Run(Function()
                           If dmNos Is Nothing OrElse dmNos.Count = 0 Then Throw New UserError("Tick the DMs to authorise.")
                           Dim yr As String = AppCtx.CurrentSession()
                           Db.InTransaction(Sub(cn As SqlConnection, tx As SqlTransaction)
                                                For Each dm As String In dmNos
                                                    Db.ExecTx(cn, tx, "update AreaDMData set isAuth = 1 where DMNo = @dm and session = @s", Db.P("@dm", dm), Db.P("@s", yr))
                                                Next
                                            End Sub)
                           Return Api.Ok(Nothing, "Authorised Successfully")
                       End Function)
    End Function

End Class
