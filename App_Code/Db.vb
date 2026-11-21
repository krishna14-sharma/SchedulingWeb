Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Configuration

''' <summary>
''' Data access helper. Replaces GMod.DataSetRet / GMod.SqlExecuteNonQuery.
''' Every value goes in as a SQL parameter (the WinForms code concatenated strings, which allowed SQL injection
''' and broke on names containing an apostrophe).
''' </summary>
Public NotInheritable Class Db

    Private Sub New()
    End Sub

    Public Shared ReadOnly Property ConnStr() As String
        Get
            Return ConfigurationManager.ConnectionStrings("PhxGroupERP").ConnectionString
        End Get
    End Property

    ''' <summary>Creates a parameter; Nothing becomes DBNull.</summary>
    Public Shared Function P(ByVal name As String, ByVal value As Object) As SqlParameter
        If value Is Nothing Then Return New SqlParameter(name, DBNull.Value)
        Return New SqlParameter(name, value)
    End Function

    ''' <summary>Date-only parameter (the WinForms code sent dtPicker.Value.ToShortDateString).</summary>
    Public Shared Function PDate(ByVal name As String, ByVal value As DateTime) As SqlParameter
        Dim prm As New SqlParameter(name, SqlDbType.DateTime)
        prm.Value = value.Date
        Return prm
    End Function

    Public Shared Function Table(ByVal sql As String, ByVal ParamArray ps() As SqlParameter) As DataTable
        Using cn As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand(sql, cn)
                cmd.CommandTimeout = 180
                If ps IsNot Nothing AndAlso ps.Length > 0 Then cmd.Parameters.AddRange(ps)
                Using da As New SqlDataAdapter(cmd)
                    Dim dt As New DataTable()
                    da.Fill(dt)
                    Return dt
                End Using
            End Using
        End Using
    End Function

    Public Shared Function Exec(ByVal sql As String, ByVal ParamArray ps() As SqlParameter) As Integer
        Using cn As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand(sql, cn)
                cmd.CommandTimeout = 180
                If ps IsNot Nothing AndAlso ps.Length > 0 Then cmd.Parameters.AddRange(ps)
                cn.Open()
                Return cmd.ExecuteNonQuery()
            End Using
        End Using
    End Function

    Public Shared Function Scalar(ByVal sql As String, ByVal ParamArray ps() As SqlParameter) As Object
        Using cn As New SqlConnection(ConnStr)
            Using cmd As New SqlCommand(sql, cn)
                cmd.CommandTimeout = 180
                If ps IsNot Nothing AndAlso ps.Length > 0 Then cmd.Parameters.AddRange(ps)
                cn.Open()
                Dim o As Object = cmd.ExecuteScalar()
                If o Is DBNull.Value Then Return Nothing
                Return o
            End Using
        End Using
    End Function

    ''' <summary>Runs several statements as one unit: all are saved or none are.</summary>
    Public Shared Sub InTransaction(ByVal work As Action(Of SqlConnection, SqlTransaction))
        Using cn As New SqlConnection(ConnStr)
            cn.Open()
            Using tx As SqlTransaction = cn.BeginTransaction()
                Try
                    work(cn, tx)
                    tx.Commit()
                Catch
                    Try
                        tx.Rollback()
                    Catch
                    End Try
                    Throw
                End Try
            End Using
        End Using
    End Sub

    Public Shared Function ExecTx(ByVal cn As SqlConnection, ByVal tx As SqlTransaction, ByVal sql As String, ByVal ParamArray ps() As SqlParameter) As Integer
        Using cmd As New SqlCommand(sql, cn, tx)
            cmd.CommandTimeout = 180
            If ps IsNot Nothing AndAlso ps.Length > 0 Then cmd.Parameters.AddRange(ps)
            Return cmd.ExecuteNonQuery()
        End Using
    End Function

End Class
