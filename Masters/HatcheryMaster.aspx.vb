Imports System
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmHatchery (table Hatcheries).</summary>
Partial Class HatcheryMasterPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function List() As ApiResult
        Return Api.Run(Function() Api.Rows(Db.Table("select Hatcheryies, ID from Hatcheries order by Hatcheryies")))
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Save(ByVal name As String) As ApiResult
        Return Api.Run(Function()
                           name = AppCtx.Str(name).Trim().ToUpper()
                           If name = "" Then Throw New UserError("Enter Hatchery Name")
                           Db.Exec("insert into Hatcheries (Hatcheryies) values (@n)", Db.P("@n", name))
                           Return Api.Ok(Nothing, "Hatchery saved.")
                       End Function)
    End Function

End Class
