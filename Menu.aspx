<%@ Page Title="All Screens" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="Menu.aspx.vb" Inherits="MenuPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
    <p class="text-muted mb-1">Welcome, <strong><%: AppCtx.UserName %></strong>. Pick a screen, or go back to the <a href="Dashboard.aspx">Dashboard</a>.</p>


    <div class="section-label">Schedule</div>
    <div class="row g-3">
        <div class="col-12 col-sm-6 col-lg-3"><a class="tile" href="Schedule/HatchProduction.aspx"><span class="tile-icon"><i class="bi bi-egg-fried"></i></span><span><span class="tile-title d-block">Hatch Production</span><span class="tile-sub">Daily hatch quantity per unit</span></span></a></div>
        <div class="col-12 col-sm-6 col-lg-3"><a class="tile" href="Schedule/DealerScheduling.aspx"><span class="tile-icon"><i class="bi bi-person-lines-fill"></i></span><span><span class="tile-title d-block">Dealer/Other Scheduling</span><span class="tile-sub">Single schedule entries</span></span></a></div>
        <div class="col-12 col-sm-6 col-lg-3"><a class="tile" href="Schedule/DemandScheduling.aspx"><span class="tile-icon"><i class="bi bi-calendar-plus"></i></span><span><span class="tile-title d-block">Demand Scheduling</span><span class="tile-sub">Schedule an area from its demand</span></span></a></div>
        <div class="col-12 col-sm-6 col-lg-3"><a class="tile" href="Schedule/EditScheduling.aspx"><span class="tile-icon"><i class="bi bi-calendar-check"></i></span><span><span class="tile-title d-block">Edit Scheduling</span><span class="tile-sub">Change or delete a schedule</span></span></a></div>
    </div>

    <div class="section-label">Demand &amp; Layer</div>
    <div class="row g-3">
        <div class="col-12 col-sm-6 col-lg-3"><a class="tile" href="Schedule/EditDemand.aspx"><span class="tile-icon"><i class="bi bi-pencil-square"></i></span><span><span class="tile-title d-block">Edit Demand</span><span class="tile-sub">Correct, cancel or delete demand</span></span></a></div>
        <div class="col-12 col-sm-6 col-lg-3"><a class="tile" href="Schedule/LayerScheduleUpdate.aspx"><span class="tile-icon"><i class="bi bi-egg"></i></span><span><span class="tile-title d-block">Layer Schedule Update</span><span class="tile-sub">Layer demand by date</span></span></a></div>
        <div class="col-12 col-sm-6 col-lg-3"><a class="tile" href="<%: AppCtx.Setting("LayerScheduleUrl", "#") %>" target="_blank" rel="noopener"><span class="tile-icon"><i class="bi bi-box-arrow-up-right"></i></span><span><span class="tile-title d-block">Layer Schedule</span><span class="tile-sub">Opens the layer calendar site</span></span></a></div>
    </div>

    <div class="section-label">Masters</div>
    <div class="row g-3">
        <div class="col-6 col-lg-3"><a class="tile" href="Masters/AreaMaster.aspx"><span class="tile-icon"><i class="bi bi-geo-alt"></i></span><span class="tile-title">Area Master</span></a></div>
        <div class="col-6 col-lg-3"><a class="tile" href="Masters/ProductMaster.aspx"><span class="tile-icon"><i class="bi bi-box-seam"></i></span><span class="tile-title">Product Master</span></a></div>
        <div class="col-6 col-lg-3"><a class="tile" href="Masters/HatcheryMaster.aspx"><span class="tile-icon"><i class="bi bi-building"></i></span><span class="tile-title">Hatchery Master</span></a></div>
        <div class="col-6 col-lg-3"><a class="tile" href="Masters/HeadCreation.aspx"><span class="tile-icon"><i class="bi bi-person-plus"></i></span><span class="tile-title">Head Creation</span></a></div>
    </div>

    <div class="section-label">Reports</div>
    <div class="row g-3">
        <div class="col-12 col-sm-6 col-lg-4"><a class="tile" href="Reports/SchedulingReport.aspx"><span class="tile-icon"><i class="bi bi-file-earmark-text"></i></span><span class="tile-title">Scheduling Report</span></a></div>
        <div class="col-12 col-sm-6 col-lg-4"><a class="tile" href="Reports/MonthlyDealerReport.aspx"><span class="tile-icon"><i class="bi bi-calendar-month"></i></span><span class="tile-title">Monthly Dealer Report (Chicks)</span></a></div>
        <div class="col-12 col-sm-6 col-lg-4"><a class="tile" href="Reports/DealerTrData.aspx"><span class="tile-icon"><i class="bi bi-cash-stack"></i></span><span class="tile-title">Monthly Dealer Tr Data</span></a></div>
        <div class="col-12 col-sm-6 col-lg-4"><a class="tile" href="Reports/LayerTentativeDate.aspx"><span class="tile-icon"><i class="bi bi-hourglass-split"></i></span><span class="tile-title">Layer Placement Tentative Date</span></a></div>
        <div class="col-12 col-sm-6 col-lg-4"><a class="tile" href="Reports/ConsolidateSchedule.aspx"><span class="tile-icon"><i class="bi bi-envelope-paper"></i></span><span class="tile-title">Consolidate Schedule Report</span></a></div>
        <div class="col-12 col-sm-6 col-lg-4"><a class="tile" href="Reports/RateDiffReport.aspx"><span class="tile-icon"><i class="bi bi-arrow-left-right"></i></span><span class="tile-title">Schedule Rate vs Circular Rate</span></a></div>
    </div>

    <div class="section-label">Sales Report</div>
    <div class="row g-3">
        <div class="col-6 col-lg-3"><a class="tile" href="Sales/DMData.aspx"><span class="tile-icon"><i class="bi bi-truck"></i></span><span class="tile-title">DM Data</span></a></div>
        <div class="col-6 col-lg-3"><a class="tile" href="Sales/TRData.aspx"><span class="tile-icon"><i class="bi bi-bank"></i></span><span class="tile-title">TR Data</span></a></div>
    </div>
</asp:Content>
