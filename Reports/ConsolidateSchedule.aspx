<%@ Page Title="Consolidate Schedule Report" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="ConsolidateSchedule.aspx.vb" Inherits="ConsolidateSchedulePage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="card mb-3 no-print">
    <div class="card-body" data-enter-click="#btnDisplay">
        <div class="row g-2 align-items-end">
            <div class="col-6 col-md-2">
                <label class="form-label" for="dtHatch">Hatch Date</label>
                <input type="date" class="form-control" id="dtHatch" />
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label" for="cmbChickType">Chicks Type</label>
                <select class="form-select" id="cmbChickType"></select>
            </div>
            <div class="col-6 col-md-2">
                <button type="button" class="btn btn-primary w-100" id="btnDisplay"><i class="bi bi-file-earmark-text"></i> Display</button>
            </div>
            <div class="col-6 col-md-2">
                <button type="button" class="btn btn-outline-primary w-100" id="btnMail"><i class="bi bi-envelope"></i> Send Mail</button>
            </div>
            <div class="col-12 col-md-4 small text-muted" id="mailInfo"></div>
        </div>
    </div>
</div>
<div class="row g-3">
    <div class="col-lg-6"><div id="repHatchery"></div></div>
    <div class="col-lg-6 print-break"><div id="repArea"></div></div>
</div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script>
$(function () {
    function params() { return { hatchDate: $('#dtHatch').val(), chickType: $('#cmbChickType').val() }; }
    function render(p, d) {
        var lines = ['HATCH DATE: ' + App.fmtDate(p.hatchDate), 'CHICKS: ' + p.chickType];
        App.report('#repHatchery', {
            title: 'HATCH SCHEDULE (HATCHERY WISE)', lines: lines, exportName: 'ScheduleHatcheryWise', stack: false,
            columns: [{ key: 'Hatchery', title: 'Hatchery' }, { key: 'Qty', title: 'Qty', type: 'int', total: true }, { key: 'FreeQty', title: 'Free Qty', type: 'int', total: true }, { key: 'AvgRate', title: 'AvgRate', type: 'num', total: 'avg' }],
            rows: d.hatchery
        });
        App.report('#repArea', {
            title: 'HATCH SCHEDULE (AREA WISE)', lines: lines, exportName: 'ScheduleAreaWise', stack: false,
            columns: [{ key: 'Areaname', title: 'Area Name' }, { key: 'Qty', title: 'Qty', type: 'int', total: true }, { key: 'FreeQty', title: 'Free Qty', type: 'int', total: true }, { key: 'AvgRate', title: 'AvgRate', type: 'num', total: 'avg' }],
            rows: d.area
        });
    }
    $('#btnDisplay').on('click', function () {
        var p = params(); if (!p.hatchDate) return;
        App.api('Run', p).then(function (d) { render(p, d); });
    });
    $('#btnMail').on('click', function () {
        var p = params(); if (!p.hatchDate) return;
        App.confirm('Email the hatchery-wise and area-wise schedule for ' + App.fmtDate(p.hatchDate) + ' (' + p.chickType + ')?', { okText: 'Send' })
            .then(function (yes) {
                if (yes) App.api('SendMail', p).then(function (d) { render(p, d); });
            });
    });
    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbChickType', d.chickTypes);
        $('#dtHatch').val(App.today());
        $('#mailInfo').html('<i class="bi bi-info-circle"></i> Mail goes to ' + App.esc(d.mailTo) + (d.mailBcc ? ' (bcc ' + App.esc(d.mailBcc) + ')' : ''));
    });
});
</script>
</asp:Content>
