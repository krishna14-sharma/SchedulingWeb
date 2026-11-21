Imports System
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmPrd (table Prd).</summary>
Partial Class ProductMasterPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function List() As ApiResult
        Return Api.Run(Function() Api.Rows(Db.Table("select Product, ID from Prd order by Product")))
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Save(ByVal name As String) As ApiResult
        Return Api.Run(Function()
                           name = AppCtx.Str(name).Trim().ToUpper()
                           If name = "" Then Throw New UserError("Enter Product Name")
                           Db.Exec("insert into Prd (Product) values (@n)", Db.P("@n", name))
                           Return Api.Ok(Nothing, "Product saved.")
                       End Function)
    End Function

End Class
