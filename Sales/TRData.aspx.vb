Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Collections.Generic
Imports System.Web.Services

''' <summary>Converted from FrmAreaWiseReport (TR data, table AreaTrData, Crystal report CrAreaWiseTrReport).</summary>
Partial Class TRDataPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function()
                           Dim yr As String = AppCtx.CurrentSession()
                           Dim areas As DataTable = Db.Table("select distinct prefix, prefix + ' - ' + Areaname as label from Area where prefix is not null order by prefix")
                           ' The WinForms combo listed these codes; keep them even if missing from the Area table.
                           For Each c As String In New String() {"BS", "KH", "TA", "DU", "SI", "DR"}
                               If areas.Select("prefix = '" & c & "'").Length = 0 Then
                                   Dim r As DataRow = areas.NewRow()
                                   r("prefix") = c : r("label") = c
                                   areas.Rows.Add(r)
                               End If
                           Next
                           Return New With {
                               .areas = Api.Rows(areas),
                               .banks = Api.Col(Db.Table("select distinct Bank_det from AreaTrData where session = @s order by Bank_det", Db.P("@s", yr)), "Bank_det"),
                               .payModes = Api.Col(Db.Table("select distinct Pay_mode from AreaTrData where session = @s order by Pay_mode", Db.P("@s", yr)), "Pay_mode")
                           }
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Run(ByVal f As TrFilter, ByVal forPrint As Boolean) As ApiResult
        Return Api.Run(Function()
                           Dim ps As New List(Of SqlParameter)
                           ps.Add(Db.P("@s", AppCtx.CurrentSession()))
                           Dim sql As String = "select isAuth, Area, AreaCode, TRNo, TrDate, HatchDate, entrydate, Code, CName, TrAmount, Bank_det, Pay_mode, bankdate, DD_No, Chick_type, Rate, Remarks " &
                                               "from AreaTrData where session = @s"

                           ' ComboBox2: ALL -> isAuth in (1,0); IS_AUT -> (1,10); UN_AUTH -> (0,10)
                           Dim a1 As Integer = 0, a2 As Integer = 10
                           Select Case AppCtx.Str(f.authFilter)
                               Case "ALL" : a1 = 1 : a2 = 0
                               Case "IS_AUT" : a1 = 1 : a2 = 10
                               Case Else : a1 = 0 : a2 = 10
                           End Select
                           sql &= " and isAuth in (@a1, @a2)"
                           ps.Add(Db.P("@a1", a1)) : ps.Add(Db.P("@a2", a2))

                           ' chkAll / chkCash
                           Dim modes As String()
                           If f.allTrans Then
                               modes = New String() {"NEFT", "CHEQUE", "RTGS", "TRANSFER", "CASH"}
                           ElseIf f.cashOnly Then
                               modes = New String() {"CASH"}
                           Else
                               modes = New String() {"NEFT", "CHEQUE", "RTGS", "TRANSFER"}
                           End If
                           Dim names As New List(Of String)
                           For i As Integer = 0 To modes.Length - 1
                               names.Add("@pm" & i)
                               ps.Add(Db.P("@pm" & i, modes(i)))
                           Next
                           sql &= " and pay_mode in (" & String.Join(",", names.ToArray()) & ")"

                           Dim mode As String = AppCtx.Str(f.mode)
                           Dim needArea As Boolean = False, needDates As Boolean = False, needTr As Boolean = False, needBank As Boolean = False, needPay As Boolean = False
                           Select Case mode
                               Case "ALL AREA"
                               Case "SELECTED AREA" : needArea = True
                               Case "BY HATCH DATE" : needDates = True
                               Case "SELECT AREA AND HATCH DATE" : needArea = True : needDates = True
                               Case "TR NO BETWEEN" : needArea = True : needTr = True
                               Case "ALL AREA-BANK DET" : needBank = True
                               Case "ALL AREA-TRANS TYPE" : needPay = True
                               Case "TR NO BETWEEN-BANK DET" : needArea = True : needTr = True : needBank = True
                               Case "TR NO BETWEEN-TRANS TYPE" : needArea = True : needTr = True : needPay = True
                               Case "ALL AREA-BANK DET-TRANSTYPE" : needBank = True : needPay = True
                               Case Else : Throw New UserError("Select a report option.")
                           End Select
                           If needArea Then
                               If AppCtx.Str(f.areaCode) = "" Then Throw New UserError("Select Area")
                               sql &= " and AreaCode = @area" : ps.Add(Db.P("@area", f.areaCode))
                           End If
                           If needDates Then
                               sql &= " and HatchDate between @d1 and @d2"
                               ps.Add(Db.PDate("@d1", AppCtx.ParseDate(f.fromDate, "Hatch Date")))
                               ps.Add(Db.PDate("@d2", AppCtx.ParseDate(f.toDate, "Hatch Date To")))
                           End If
                           If needTr Then
                               sql &= " and tridarea between @t1 and @t2"
                               ps.Add(Db.P("@t1", AppCtx.Num(f.trFrom))) : ps.Add(Db.P("@t2", AppCtx.Num(f.trTo)))
                           End If
                           If needBank Then sql &= " and bank_det = @bank" : ps.Add(Db.P("@bank", AppCtx.Str(f.bankDet)))
                           If needPay Then sql &= " and Pay_mode = @pay" : ps.Add(Db.P("@pay", AppCtx.Str(f.payMode)))

                           ' The PRINT button of the WinForms screen printed only authorised TRs for these options.
                           If forPrint AndAlso (mode = "ALL AREA" OrElse mode = "SELECTED AREA" OrElse mode = "BY HATCH DATE" OrElse mode = "SELECT AREA AND HATCH DATE") Then
                               sql &= " and isAuth = 1"
                           End If
                           sql &= " order by tridarea"
                           Return Api.Rows(Db.Table(sql, ps.ToArray()))
                       End Function)
    End Function

    ''' <summary>Button1_Click ("AUTH"): blocks if any party has unauthorised cash of 2 lakh or more, then authorises the ticked TRs.</summary>
    <WebMethod(EnableSession:=True)>
    Public Shared Function Authorize(ByVal trNos As List(Of String)) As ApiResult
        Return Api.Run(Function()
                           If trNos Is Nothing OrElse trNos.Count = 0 Then Throw New UserError("Tick the TRs first.")
                           Dim yr As String = AppCtx.CurrentSession()
                           Dim cash As DataTable = Db.Table("select Code, Cname, sum(TrAmount) amt, bankdate from AreaTrData where session = @s and Pay_mode = 'CASH' and isAuth = 0 " &
                                                            "group by Code, Cname, bankdate having sum(TrAmount) >= 200000", Db.P("@s", yr))
                           If cash.Rows.Count > 0 Then
                               Throw New UserError("Error in cash deposit: amount is greater than two lakh (" & AppCtx.Str(cash.Rows(0)("Cname")) & ").")
                           End If
                           Dim user As String = AppCtx.UserName
                           Db.InTransaction(Sub(cn As SqlConnection, tx As SqlTransaction)
                                                For Each t As String In trNos
                                                    Db.ExecTx(cn, tx, "update AreaTrData set isAuth = 1, AuthBy = @u where TrNo = @t and session = @s",
                                                              Db.P("@u", user), Db.P("@t", t), Db.P("@s", yr))
                                                Next
                                            End Sub)
                           Return Api.Ok(Nothing, "Authorised Successfully")
                       End Function)
    End Function

    ''' <summary>Button2_Click ("UN-AUTH"): only TRs that are not posted yet.</summary>
    <WebMethod(EnableSession:=True)>
    Public Shared Function UnAuthorize(ByVal trNos As List(Of String)) As ApiResult
        Return Api.Run(Function()
                           If trNos Is Nothing OrElse trNos.Count = 0 Then Throw New UserError("Tick the TRs first.")
                           Dim yr As String = AppCtx.CurrentSession()
                           Db.InTransaction(Sub(cn As SqlConnection, tx As SqlTransaction)
                                                For Each t As String In trNos
                                                    Db.ExecTx(cn, tx, "update AreaTrData set isAuth = 0, AuthBy = '' where TrNo = @t and isnull(isPosted,0) = 0 and session = @s",
                                                              Db.P("@t", t), Db.P("@s", yr))
                                                Next
                                            End Sub)
                           Return Api.Ok(Nothing, "UN-Authorised Successfully")
                       End Function)
    End Function

End Class
