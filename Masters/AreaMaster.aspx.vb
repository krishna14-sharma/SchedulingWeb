Imports System
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmArea (table AreaS).</summary>
Partial Class AreaMasterPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function List() As ApiResult
        Return Api.Run(Function() Api.Rows(Db.Table("select * from AreaS order by Areaname")))
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Save(ByVal id As Integer, ByVal code As String, ByVal name As String, ByVal state As String, ByVal branch As String) As ApiResult
        Return Api.Run(Function()
                           code = AppCtx.Str(code).Trim().ToUpper()
                           name = AppCtx.Str(name).Trim().ToUpper()
                           state = AppCtx.Str(state).Trim().ToUpper()
                           branch = AppCtx.Str(branch).Trim().ToUpper()
                           If code = "" Then Throw New UserError("Enter Area Code")
                           If name = "" Then Throw New UserError("Enter Area Name")
                           If state = "" Then Throw New UserError("Select State")
                           If branch = "" Then Throw New UserError("Enter Branch")

                           If id = 0 Then
                               Db.Exec("insert into AreaS(Areaname, prefix, state, branch) values (@n, @c, @s, @b)",
                                       Db.P("@n", name), Db.P("@c", code), Db.P("@s", state), Db.P("@b", branch))
                               Return Api.Ok(Nothing, "Area saved.")
                           End If
                           Db.Exec("update AreaS set Areaname = @n, prefix = @c, state = @s, branch = @b where id = @id",
                                   Db.P("@n", name), Db.P("@c", code), Db.P("@s", state), Db.P("@b", branch), Db.P("@id", id))
                           Return Api.Ok(Nothing, "Area updated.")
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Delete(ByVal id As Integer) As ApiResult
        Return Api.Run(Function()
                           Db.Exec("delete from AreaS where id = @id", Db.P("@id", id))
                           Return Api.Ok(Nothing, "Area deleted.")
                       End Function)
    End Function

End Class
