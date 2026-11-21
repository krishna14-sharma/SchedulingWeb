Imports System
Imports System.Data
Imports System.Web.Services

''' <summary>Converted from frmAccMaster (table ACC_sheduling).</summary>
Partial Class HeadCreationPage
    Inherits BasePage

    <WebMethod(EnableSession:=True)>
    Public Shared Function Setup() As ApiResult
        Return Api.Run(Function() New With {.areas = Api.Rows(Db.Table("select * from AreaS order by AreaName"))})
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function List() As ApiResult
        Return Api.Run(Function() Api.Rows(Db.Table("select * from [ACC_sheduling] order by account_code")))
    End Function

    ''' <summary>Area code + type code + 4-digit running number (frmAccMaster.nxtid).</summary>
    Private Shared Function MakeCode(ByVal areaCode As String, ByVal groupName As String, ByVal groupCode As String) As String
        Dim n As Object = Db.Scalar("select isnull(max(right(account_code,4)) + 1, 1) from [ACC_sheduling] where left(account_code,2) = @a and group_name = @g",
                                    Db.P("@a", AppCtx.Str(areaCode)), Db.P("@g", AppCtx.Str(groupName)))
        Return AppCtx.Str(areaCode) & AppCtx.Str(groupCode) & CInt(AppCtx.Num(n)).ToString("0000")
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function NextCode(ByVal areaCode As String, ByVal groupName As String, ByVal groupCode As String) As ApiResult
        Return Api.Run(Function() MakeCode(areaCode, groupName, groupCode))
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Save(ByVal areaCode As String, ByVal areaName As String, ByVal groupName As String, ByVal groupCode As String,
                                ByVal name As String, ByVal address As String, ByVal state As String, ByVal phone As String) As ApiResult
        Return Api.Run(Function()
                           If AppCtx.Str(name).Trim() = "" Then Throw New UserError("Please Enter Name")
                           If AppCtx.Str(areaCode) = "" Then Throw New UserError("Select Area")
                           ' The code is worked out again here so two users saving at once cannot get the same number.
                           Dim code As String = MakeCode(areaCode, groupName, groupCode)
                           Db.Exec("insert into [ACC_sheduling](account_code, account_head_name, group_name, address, city, state, phone, Area_code) " &
                                   "values (@code, @name, @grp, @addr, @city, @state, @phone, @area)",
                                   Db.P("@code", code), Db.P("@name", name.Trim().ToUpper()), Db.P("@grp", groupName),
                                   Db.P("@addr", AppCtx.Str(address).Trim().ToUpper()), Db.P("@city", areaName),
                                   Db.P("@state", AppCtx.Str(state).Trim().ToUpper()), Db.P("@phone", AppCtx.Str(phone)), Db.P("@area", areaCode))
                           Return Api.Ok(code, "Head " & code & " saved.")
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function UpdateName(ByVal code As String, ByVal name As String) As ApiResult
        Return Api.Run(Function()
                           If AppCtx.Str(name).Trim() = "" Then Throw New UserError("Please Enter Name")
                           Db.Exec("update ACC_sheduling set account_head_name = @n where account_code = @c",
                                   Db.P("@n", name.Trim().ToUpper()), Db.P("@c", code))
                           Return Api.Ok(Nothing, "Head updated.")
                       End Function)
    End Function

    <WebMethod(EnableSession:=True)>
    Public Shared Function Delete(ByVal code As String) As ApiResult
        Return Api.Run(Function()
                           Db.Exec("delete from ACC_sheduling where account_code = @c", Db.P("@c", code))
                           Return Api.Ok(Nothing, "Head deleted.")
                       End Function)
    End Function

End Class
