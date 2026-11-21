Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Collections.Generic

''' <summary>Envelope returned by every AJAX page method: { ok, msg, data }.</summary>
Public Class ApiResult
    Public Property ok As Boolean
    Public Property msg As String
    Public Property data As Object
End Class

''' <summary>Helpers used by the [WebMethod] functions on each page.</summary>
Public NotInheritable Class Api

    Private Sub New()
    End Sub

    ''' <summary>
    ''' Runs the work, checks the user is logged in, and turns any exception into a friendly message
    ''' (replaces the MsgBox calls of the WinForms app).
    ''' </summary>
    Public Shared Function Run(ByVal work As Func(Of Object), Optional ByVal requireLogin As Boolean = True) As ApiResult
        Try
            If requireLogin AndAlso Not AppCtx.IsLoggedIn Then
                Return New ApiResult With {.ok = False, .msg = "Your session has expired. Please log in again.", .data = "LOGIN"}
            End If
            Dim d As Object = work()
            If TypeOf d Is ApiResult Then Return DirectCast(d, ApiResult)
            Return New ApiResult With {.ok = True, .msg = "", .data = d}
        Catch ex As UserError
            Return Fail(ex.Message)
        Catch ex As SqlException
            If ex.Number = 2627 OrElse ex.Number = 2601 OrElse ex.Message.Contains("PRIMARY") Then
                Return Fail("Error: Duplicate entry.")
            End If
            Return Fail("Database error: " & ex.Message)
        Catch ex As Exception
            Return Fail("Error: " & ex.Message)
        End Try
    End Function

    Public Shared Function Ok(ByVal data As Object, ByVal msg As String) As ApiResult
        Return New ApiResult With {.ok = True, .msg = msg, .data = data}
    End Function

    Public Shared Function Fail(ByVal msg As String) As ApiResult
        Return New ApiResult With {.ok = False, .msg = msg, .data = Nothing}
    End Function

    ''' <summary>DataTable -> list of name/value rows that serialise cleanly to JSON (dates as ISO strings).</summary>
    Public Shared Function Rows(ByVal dt As DataTable) As List(Of Dictionary(Of String, Object))
        Dim list As New List(Of Dictionary(Of String, Object))(dt.Rows.Count)
        For Each r As DataRow In dt.Rows
            Dim d As New Dictionary(Of String, Object)(StringComparer.OrdinalIgnoreCase)
            For Each c As DataColumn In dt.Columns
                d(c.ColumnName) = ToJsonValue(r(c))
            Next
            list.Add(d)
        Next
        Return list
    End Function

    Public Shared Function ToJsonValue(ByVal v As Object) As Object
        If v Is Nothing OrElse v Is DBNull.Value Then Return Nothing
        If TypeOf v Is DateTime Then
            Dim dtv As DateTime = DirectCast(v, DateTime)
            If dtv.TimeOfDay.Ticks = 0 Then Return dtv.ToString("yyyy-MM-dd")
            Return dtv.ToString("yyyy-MM-ddTHH:mm:ss")
        End If
        If TypeOf v Is Byte() Then Return Nothing
        If TypeOf v Is Guid Then Return v.ToString()
        If TypeOf v Is TimeSpan Then Return v.ToString()
        Return v
    End Function

    ''' <summary>One column of a DataTable as a list of strings (for drop-downs).</summary>
    Public Shared Function Col(ByVal dt As DataTable, ByVal column As String) As List(Of String)
        Dim list As New List(Of String)
        For Each r As DataRow In dt.Rows
            Dim v As String = AppCtx.Str(r(column))
            If v.Length > 0 Then list.Add(v)
        Next
        Return list
    End Function

End Class
