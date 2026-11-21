Imports System
''' <summary>One row of the Demand Scheduling / Edit Scheduling grid (sent to and from the browser as JSON).</summary>
Public Class ScheduleRow
    Public Property id As Integer
    Public Property code As String
    Public Property name As String
    Public Property demandQty As Decimal
    Public Property rate As Decimal
    Public Property scheduleQty As Decimal
    Public Property free As Decimal
    Public Property scheduleRate As Decimal
    Public Property circularRate As Decimal
    Public Property hatchery As String
    Public Property compRate As Decimal
    Public Property dr As Decimal
    Public Property cr As Decimal
    Public Property isEdit As Integer
End Class

''' <summary>Dealer / Other Scheduling single entry.</summary>
Public Class DealerSchedule
    Public Property id As Integer
    Public Property kind As String          ' DR = Dealer, OT = Others
    Public Property custCode As String
    Public Property custName As String
    Public Property hatchDate As String     ' yyyy-MM-dd
    Public Property chickType As String
    Public Property hatchery As String
    Public Property qty As Decimal
    Public Property rate As Decimal
    Public Property circularRate As Decimal
    Public Property compRate As Decimal
    Public Property dr As Decimal
    Public Property cr As Decimal
End Class

''' <summary>Filters for the DM Data (supply) screen.</summary>
Public Class DmFilter
    Public Property mode As String
    Public Property chickType As String
    Public Property areaCode As String
    Public Property fromDate As String
    Public Property toDate As String
    Public Property unit As String
    Public Property dmFrom As String
    Public Property dmTo As String
    Public Property isAuth As Boolean
End Class

''' <summary>Filters for the TR Data screen.</summary>
Public Class TrFilter
    Public Property mode As String
    Public Property areaCode As String
    Public Property fromDate As String
    Public Property toDate As String
    Public Property trFrom As String
    Public Property trTo As String
    Public Property authFilter As String    ' ALL / IS_AUT / UN_AUTH
    Public Property cashOnly As Boolean
    Public Property allTrans As Boolean
    Public Property bankDet As String
    Public Property payMode As String
End Class
