Imports System
Imports System.Globalization
Imports System.Data
Imports System.Net
Imports System.Net.Mail
Imports System.Text
Imports System.Web
Imports System.Web.Services

''' <summary>
''' Converted from frmConsolidateSchedule (Crystal reports CrConsolidateHatcheryWise / CrConsolidateAreaWise1).
''' "Send Mail" now sends both tables in the mail body plus CSV attachments, instead of Crystal PDF exports.
''' </summary>
Partial Class ConsolidateSchedulePage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function() New With {
                           .chickTypes = Api.Col(AppCtx.ChickTypes(), "Chick_type"),
                           .mailTo = AppCtx.Setting("Mail.To"),
                           .mailBcc = AppCtx.Setting("Mail.Bcc")
                       })
    End Function

    Private Shared Function HatcheryWise(ByVal d As DateTime, ByVal chickType As String) As DataTable
        Return Db.Table("select Hatchery, nullif(sum(isnull(QtyNet,0) + isnull(Qty2Per,0)), 0) as Qty, isnull(sum(Qty2Per), 0) as FreeQty, sum(QtyNet * Rate) / nullif(sum(QtyNet), 0) as AvgRate " &
                        "from Shedule where QtyNet > 0 and Hatch_DAte = @d" & AppCtx.ChickTypeFilter("Productname", chickType) & " group by Hatchery order by Hatchery",
                        Db.PDate("@d", d), Db.P("@p", chickType))
    End Function

    Private Shared Function AreaWise(ByVal d As DateTime, ByVal chickType As String) As DataTable
        Return Db.Table("select a.Areaname, p.Area_Code, p.Qty, p.FreeQty, p.AvgRate from Area a inner join ( " &
                        "  select Area_Code, nullif(sum(isnull(QtyNet,0) + isnull(Qty2Per,0)), 0) as Qty, isnull(sum(Qty2Per), 0) as FreeQty, sum(QtyNet * Rate) / nullif(sum(QtyNet), 0) as AvgRate " &
                        "  from Shedule where QtyNet > 0 and Hatch_DAte = @d" & AppCtx.ChickTypeFilter("Productname", chickType) & " group by Area_Code " &
                        ") p on a.prefix = p.Area_Code order by p.Area_Code",
                        Db.PDate("@d", d), Db.P("@p", chickType))
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Run(ByVal hatchDate As String, ByVal chickType As String) As ApiResult
        Return Api.Run(Function()
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           Return New With {.hatchery = Api.Rows(HatcheryWise(d, chickType)), .area = Api.Rows(AreaWise(d, chickType))}
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function SendMail(ByVal hatchDate As String, ByVal chickType As String) As ApiResult
        Return Api.Run(Function()
                           Dim d As DateTime = AppCtx.ParseDate(hatchDate, "Hatch Date")
                           Dim h As DataTable = HatcheryWise(d, chickType)
                           Dim a As DataTable = AreaWise(d, chickType)
                           Dim dateText As String = d.ToString("dd/MMM/yyyy", CultureInfo.InvariantCulture)

                           Dim body As New StringBuilder()
                           body.Append("<div style=""font-family:Segoe UI,Arial,sans-serif;font-size:13px"">")
                           body.Append("<p>Auto generated scheduled report, please find the reports below and attached.</p>")
                           body.Append(HtmlTable("PHOENIX HATCHERIES HATCH SCHEDULE (HATCHERY WISE)", dateText, chickType, h, "Hatchery", "Hatchery"))
                           body.Append("<br/>")
                           body.Append(HtmlTable("PHOENIX HATCHERIES HATCH SCHEDULE (AREA WISE)", dateText, chickType, a, "Areaname", "Area Name"))
                           body.Append("<p style=""color:#888"">Sent by " & HttpUtility.HtmlEncode(AppCtx.UserName) & " from the Scheduling web app.</p></div>")

                           Using mail As New MailMessage()
                               mail.From = New MailAddress(AppCtx.Setting("Mail.From"))
                               For Each addr As String In AppCtx.Setting("Mail.To").Split(New Char() {","c, ";"c}, StringSplitOptions.RemoveEmptyEntries)
                                   mail.To.Add(addr.Trim())
                               Next
                               For Each addr As String In AppCtx.Setting("Mail.Bcc").Split(New Char() {","c, ";"c}, StringSplitOptions.RemoveEmptyEntries)
                                   mail.Bcc.Add(addr.Trim())
                               Next
                               If mail.To.Count = 0 Then Throw New UserError("No recipient set (Mail.To in Web.config).")
                               mail.Subject = AppCtx.Setting("Mail.Subject", "Schedule Hatchery Wise Report") & " - " & dateText & " - " & chickType
                               mail.IsBodyHtml = True
                               mail.Body = body.ToString()
                               Dim fileDate As String = d.ToString("dd-MMM-yyyy")
                               mail.Attachments.Add(CsvAttachment("Schedule" & fileDate & ".csv", h, "Hatchery", "Hatchery"))
                               mail.Attachments.Add(CsvAttachment("ScheduleAreaWise" & fileDate & ".csv", a, "Areaname", "Area Name"))

                               Using smtp As New SmtpClient(AppCtx.Setting("Mail.SmtpHost", "smtp.gmail.com"), CInt(AppCtx.Num(AppCtx.Setting("Mail.SmtpPort", "587"))))
                                   smtp.EnableSsl = (AppCtx.Setting("Mail.EnableSsl", "true").ToLowerInvariant() = "true")
                                   smtp.Credentials = New NetworkCredential(AppCtx.Setting("Mail.User"), AppCtx.Setting("Mail.Password"))
                                   smtp.Send(mail)
                               End Using
                           End Using

                           Return Api.Ok(New With {.hatchery = Api.Rows(h), .area = Api.Rows(a)}, "Mail sent.")
                       End Function)
    End Function

    ''' <summary>Simple average of AvgRate, as the Crystal report footer showed.</summary>
    Private Shared Function Totals(ByVal dt As DataTable, ByRef qty As Decimal, ByRef free As Decimal, ByRef avg As Decimal) As Boolean
        qty = 0D : free = 0D : avg = 0D
        Dim n As Integer = 0
        For Each r As DataRow In dt.Rows
            qty += AppCtx.Num(r("Qty"))
            free += AppCtx.Num(r("FreeQty"))
            avg += AppCtx.Num(r("AvgRate"))
            n += 1
        Next
        If n > 0 Then avg = avg / n
        Return n > 0
    End Function

    Private Shared Function HtmlTable(ByVal title As String, ByVal dateText As String, ByVal chickType As String, ByVal dt As DataTable, ByVal nameCol As String, ByVal nameTitle As String) As String
        Dim sb As New StringBuilder()
        Dim td As String = "padding:4px 10px;border-bottom:1px solid #e5e7eb;"
        sb.Append("<table cellspacing=""0"" style=""border-collapse:collapse;min-width:360px"">")
        sb.Append("<tr><td colspan=""4"" style=""text-align:center;font-weight:bold;padding:4px"">" & HttpUtility.HtmlEncode(title) & "<br/>HATCH DATE: " & dateText & "<br/>CHICKS: " & HttpUtility.HtmlEncode(chickType) & "</td></tr>")
        sb.Append("<tr style=""background:#eef2f9;font-weight:bold""><td style=""" & td & """>" & nameTitle & "</td><td style=""" & td & "text-align:right"">Qty</td><td style=""" & td & "text-align:right"">Free Qty</td><td style=""" & td & "text-align:right"">AvgRate</td></tr>")
        For Each r As DataRow In dt.Rows
            sb.Append("<tr><td style=""" & td & """>" & HttpUtility.HtmlEncode(AppCtx.Str(r(nameCol))) & "</td>")
            sb.Append("<td style=""" & td & "text-align:right"">" & AppCtx.Num(r("Qty")).ToString("0") & "</td>")
            sb.Append("<td style=""" & td & "text-align:right"">" & AppCtx.Num(r("FreeQty")).ToString("0") & "</td>")
            sb.Append("<td style=""" & td & "text-align:right"">" & AppCtx.Num(r("AvgRate")).ToString("0.00") & "</td></tr>")
        Next
        Dim q As Decimal, fq As Decimal, avg As Decimal
        If Totals(dt, q, fq, avg) Then
            sb.Append("<tr style=""font-weight:bold""><td style=""" & td & """></td><td style=""" & td & "text-align:right"">" & q.ToString("0") & "</td><td style=""" & td & "text-align:right"">" & fq.ToString("0") & "</td><td style=""" & td & "text-align:right"">" & avg.ToString("0.00") & "</td></tr>")
        End If
        sb.Append("</table>")
        Return sb.ToString()
    End Function

    Private Shared Function CsvAttachment(ByVal fileName As String, ByVal dt As DataTable, ByVal nameCol As String, ByVal nameTitle As String) As Attachment
        Dim sb As New StringBuilder()
        sb.AppendLine(nameTitle & ",Qty,Free Qty,AvgRate")
        For Each r As DataRow In dt.Rows
            Dim name As String = AppCtx.Str(r(nameCol)).Replace("""", """""")
            sb.AppendLine("""" & name & """," & AppCtx.Num(r("Qty")).ToString("0") & "," & AppCtx.Num(r("FreeQty")).ToString("0") & "," & AppCtx.Num(r("AvgRate")).ToString("0.00"))
        Next
        Dim q As Decimal, fq As Decimal, avg As Decimal
        If Totals(dt, q, fq, avg) Then sb.AppendLine("Total," & q.ToString("0") & "," & fq.ToString("0") & "," & avg.ToString("0.00"))
        Dim bytes As Byte() = New UTF8Encoding(True).GetPreamble()
        Dim content As Byte() = Encoding.UTF8.GetBytes(sb.ToString())
        Dim all(bytes.Length + content.Length - 1) As Byte
        System.Buffer.BlockCopy(bytes, 0, all, 0, bytes.Length)
        System.Buffer.BlockCopy(content, 0, all, bytes.Length, content.Length)
        Return New Attachment(New System.IO.MemoryStream(all), fileName, "text/csv")
    End Function

End Class
