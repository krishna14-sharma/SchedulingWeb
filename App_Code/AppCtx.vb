Imports System
Imports System.Data
Imports System.Globalization
Imports System.Text.RegularExpressions
Imports System.Web
Imports System.Web.SessionState
Imports System.Configuration

''' <summary>An error whose message is safe and useful to show to the user.</summary>
Public Class UserError
    Inherits Exception
    Public Sub New(ByVal message As String)
        MyBase.New(message)
    End Sub
End Class

''' <summary>
''' Per-user state and shared business rules. Replaces the GMod module globals
''' (username, Session, nofd, Cmpid), which in a web app must live in the user's Session.
''' </summary>
Public NotInheritable Class AppCtx

    Private Sub New()
    End Sub

    Private Shared ReadOnly Property S() As HttpSessionState
        Get
            If HttpContext.Current Is Nothing Then Return Nothing
            Return HttpContext.Current.Session
        End Get
    End Property

    Public Shared Property UserName() As String
        Get
            If S Is Nothing OrElse S("UserName") Is Nothing Then Return ""
            Return CStr(S("UserName"))
        End Get
        Set(ByVal value As String)
            S("UserName") = value
        End Set
    End Property

    ''' <summary>Financial-year code, e.g. "2627" (GMod.Session).</summary>
    Public Shared Property FinYear() As String
        Get
            If S Is Nothing OrElse S("FinYear") Is Nothing Then Return GetSession(DateTime.Now)
            Return CStr(S("FinYear"))
        End Get
        Set(ByVal value As String)
            S("FinYear") = SafeYear(value)
        End Set
    End Property

    ''' <summary>Number of back days allowed for hatch dates (GMod.nofd).</summary>
    Public Shared Property Nofd() As Integer
        Get
            If S Is Nothing OrElse S("Nofd") Is Nothing Then Return 0
            Return CInt(S("Nofd"))
        End Get
        Set(ByVal value As Integer)
            S("Nofd") = value
        End Set
    End Property

    Public Shared ReadOnly Property IsLoggedIn() As Boolean
        Get
            Return UserName.Length > 0
        End Get
    End Property

    Public Shared ReadOnly Property CmpId() As String
        Get
            Dim v As String = ConfigurationManager.AppSettings("CmpId")
            If v Is Nothing Then Return ""
            Return v
        End Get
    End Property

    Public Shared Function Setting(ByVal key As String, Optional ByVal defaultValue As String = "") As String
        Dim v As String = ConfigurationManager.AppSettings(key)
        If String.IsNullOrEmpty(v) Then Return defaultValue
        Return v
    End Function

    ' ------------------------------------------------------------------ financial year

    ''' <summary>Same rule as GMod.Getsession: April-March year, e.g. 12-Nov-2026 -> "2627".</summary>
    Public Shared Function GetSession(ByVal d As DateTime) As String
        Dim y As Integer
        If d.Month > 3 Then y = d.Year Else y = d.Year - 1
        Return (y Mod 100).ToString("00") & ((y + 1) Mod 100).ToString("00")
    End Function

    Public Shared Function CurrentSession() As String
        Return GetSession(DateTime.Now)
    End Function

    ''' <summary>Year codes are used to build table names, so only 4 digits are accepted.</summary>
    Public Shared Function SafeYear(ByVal s As String) As String
        If s Is Nothing OrElse Not Regex.IsMatch(s, "^\d{4}$") Then Throw New UserError("Invalid session/year code.")
        Return s
    End Function

    Public Shared Function FinYearStart(ByVal yearCode As String) As DateTime
        Return New DateTime(2000 + CInt(SafeYear(yearCode).Substring(0, 2)), 4, 1)
    End Function

    Public Shared Function FinYearEnd(ByVal yearCode As String) As DateTime
        Return New DateTime(2000 + CInt(SafeYear(yearCode).Substring(2, 2)), 3, 31)
    End Function

    Public Shared Function HeadTable(ByVal yearCode As String) As String
        Return "ACC_HEAD_PHHA_" & SafeYear(yearCode)
    End Function

    Public Shared Function VentryTable(ByVal yearCode As String) As String
        Return "VENTRY_PHHA_" & SafeYear(yearCode)
    End Function

    ''' <summary>Validates a configurable table name (letters, digits, underscore only).</summary>
    Public Shared Function SafeTableName(ByVal name As String) As String
        If name Is Nothing OrElse Not Regex.IsMatch(name, "^[A-Za-z_][A-Za-z0-9_]*$") Then Throw New UserError("Invalid table name in configuration.")
        Return name
    End Function

    ''' <summary>Earliest hatch date allowed on scheduling screens (dtHdatedate.MinDate = Now - nofd).</summary>
    Public Shared Function MinHatchDate() As DateTime
        Return DateTime.Today.AddDays(-Nofd)
    End Function

    ' ------------------------------------------------------------------ parsing

    ''' <summary>Parses yyyy-MM-dd as sent by input[type=date].</summary>
    Public Shared Function ParseDate(ByVal s As String, Optional ByVal fieldName As String = "Date") As DateTime
        Dim d As DateTime
        If s Is Nothing OrElse Not DateTime.TryParseExact(s.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, d) Then
            Throw New UserError(fieldName & " is not a valid date.")
        End If
        Return d
    End Function

    ''' <summary>Lenient number parse with the same behaviour as VB Val(): blanks become 0.</summary>
    Public Shared Function Num(ByVal o As Object) As Decimal
        If o Is Nothing OrElse o Is DBNull.Value Then Return 0D
        If TypeOf o Is Decimal Then Return CDec(o)
        If TypeOf o Is Integer OrElse TypeOf o Is Long OrElse TypeOf o Is Double OrElse TypeOf o Is Single OrElse TypeOf o Is Short Then Return CDec(o)
        Dim t As String = o.ToString().Trim()
        If t.Length = 0 Then Return 0D
        Dim d As Decimal
        If Decimal.TryParse(t, NumberStyles.Any, CultureInfo.InvariantCulture, d) Then Return d
        ' Like Val(): use the leading numeric part ("12 kg" -> 12), otherwise 0
        Dim m As Match = Regex.Match(t, "^[+-]?\d*\.?\d+")
        If m.Success AndAlso Decimal.TryParse(m.Value, NumberStyles.Any, CultureInfo.InvariantCulture, d) Then Return d
        Return 0D
    End Function

    Public Shared Function Str(ByVal o As Object) As String
        If o Is Nothing OrElse o Is DBNull.Value Then Return ""
        Return o.ToString()
    End Function

    ' ------------------------------------------------------------------ business rules

    ''' <summary>Free-chicks percentage used by the scheduling screens.</summary>
    Public Shared Function FreePercent(ByVal chickType As String) As Integer
        Select Case Str(chickType)
            Case "Broiler", "Broiler(M)", "Broiler(M )"
                Return 2
            Case "Layer"
                Return 5
            Case Else
                Return 0
        End Select
    End Function

    ''' <summary>Math.Round(qty * per / 100, 0) - banker's rounding, as in the WinForms app.</summary>
    Public Shared Function FreeChicks(ByVal qty As Decimal, ByVal chickType As String) As Decimal
        Return Math.Round(qty * FreePercent(chickType) / 100D, 0)
    End Function

    ''' <summary>Writes to Log_Table exactly like the WinForms screens did.</summary>
    Public Shared Sub WriteLog(ByVal vouNo As String, ByVal vouType As String, ByVal vouDate As DateTime, ByVal logType As String)
        Db.Exec("insert into [Log_Table]([Cmp_id],[vou_no],[vou_type],[vou_date],[Modfy_date],[session],[Type],[usename]) " &
                "values('PHOE', @no, @type, @vdate, @mdate, @sess, @t, @user)",
                Db.P("@no", vouNo), Db.P("@type", vouType), Db.PDate("@vdate", vouDate),
                Db.PDate("@mdate", DateTime.Today), Db.P("@sess", FinYear), Db.P("@t", logType), Db.P("@user", UserName))
    End Sub

    ''' <summary>
    ''' Customer outstanding (Dr / Cr) - the balance query from frmSheduling / frmShedulingByDemand.
    ''' Returns {Dr, Cr}; zeros when the head has no balance or the query fails.
    ''' </summary>
    Public Shared Function GetBalance(ByVal accountCode As String) As Decimal()
        Dim result As Decimal() = New Decimal() {0D, 0D}
        If String.IsNullOrEmpty(accountCode) Then Return result
        Try
            Dim yr As String = FinYear
            Dim sql As String = "select q.account_code, " &
                " DrAmt = case when ((isnull(p.dramt,0) + q.odr) - (isnull(p.cramt,0) + q.ocr)) > 0 then (isnull(p.dramt,0) + q.odr) - (isnull(p.cramt,0) + q.ocr) else 0 end, " &
                " CrAmt = case when ((isnull(p.dramt,0) + q.odr) - (isnull(p.cramt,0) + q.ocr)) < 0 then abs((isnull(p.dramt,0) + q.odr) - (isnull(p.cramt,0) + q.ocr)) else 0 end " &
                " from ( select isnull(sum(dramt),0) dramt, isnull(sum(cramt),0) cramt, acc_head_code " &
                "        from " & VentryTable(yr) &
                "        where vou_date <= @now and Pay_mode <> '-' and acc_head_code = @code " &
                "        group by acc_head_code ) p " &
                " right join ( select account_code, isnull(opening_dr,0) odr, isnull(opening_cr,0) ocr " &
                "        from " & HeadTable(yr) &
                "        where group_name not in (select GroupNameConcealed from GroupNameConcealed where Cmp_id = @cmp) " &
                "        and account_code = @code ) q " &
                " on p.acc_head_code = q.account_code " &
                " where ((isnull(p.dramt,0) + q.odr) <> (isnull(p.cramt,0) + q.ocr))"
            Dim dt As DataTable = Db.Table(sql, Db.P("@now", DateTime.Now), Db.P("@code", accountCode), Db.P("@cmp", CmpId))
            If dt.Rows.Count > 0 Then
                result(0) = Num(dt.Rows(0)("DrAmt"))
                result(1) = Num(dt.Rows(0)("CrAmt"))
            End If
        Catch
            ' same as the WinForms behaviour: show 0 / 0
        End Try
        Return result
    End Function

    ''' <summary>Distinct chick types (used by most screens).</summary>
    ''' <summary>Chick types from the demand data, always including the standard ones (Cockrel may have no demand yet).</summary>
    Public Shared Function ChickTypes() As DataTable
        Dim dt As DataTable = Db.Table("select distinct Chick_type from AreaDemandData where Chick_type is not null and Chick_type <> '' order by Chick_type")
        For Each t As String In New String() {"Broiler", "Broiler(M)", "Cockrel", "Layer"}
            Dim found As Boolean = False
            For Each r As DataRow In dt.Rows
                If String.Equals(Str(r("Chick_type")).Trim(), t, StringComparison.OrdinalIgnoreCase) Then found = True : Exit For
            Next
            If Not found Then
                Dim nr As DataRow = dt.NewRow()
                nr("Chick_type") = t
                dt.Rows.Add(nr)
            End If
        Next
        Dim dv As New DataView(dt)
        dv.Sort = "Chick_type"
        Return dv.ToTable()
    End Function

    ''' <summary>
    ''' SQL filter for a chick type. Cockrel matches both spellings used in the data (Cockrel / Cockerel);
    ''' with groupBroiler, Broiler and Broiler(M) are reported together. Other types use the @p parameter.
    ''' </summary>
    Public Shared Function ChickTypeFilter(ByVal column As String, ByVal chickType As String, Optional ByVal groupBroiler As Boolean = False) As String
        Dim t As String = Str(chickType).Trim()
        If t.Equals("Cockrel", StringComparison.OrdinalIgnoreCase) OrElse t.Equals("Cockerel", StringComparison.OrdinalIgnoreCase) Then
            Return " and " & column & " in ('Cockrel','Cockerel')"
        End If
        If groupBroiler AndAlso (t = "Broiler" OrElse t = "Broiler(M)" OrElse t = "Broiler(M )") Then
            Return " and " & column & " in ('Broiler','Broiler(M)')"
        End If
        Return " and " & column & " = @p"
    End Function

    Public Shared Function ActiveHatcheries() As DataTable
        Return Db.Table("select Hatcheryies from Hatcheries where Active = 1 order by Hatcheryies")
    End Function

End Class
