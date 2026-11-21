<%@ Page Title="Edit Scheduling" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="EditScheduling.aspx.vb" Inherits="EditSchedulingPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="card mb-3 no-print">
    <div class="card-body" data-enter-click="#btnShow">
        <div class="row g-2 align-items-end">
            <div class="col-8 col-md-3">
                <label class="form-label" for="cmbArea">Area Name</label>
                <select class="form-select" id="cmbArea"></select>
            </div>
            <div class="col-4 col-md-1">
                <label class="form-label" for="txtAreaCode">Code</label>
                <input type="text" class="form-control" id="txtAreaCode" readonly="readonly" />
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label" for="dtHatch">Hatch Date</label>
                <input type="date" class="form-control" id="dtHatch" />
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label" for="cmbChickType">Chicks Type</label>
                <select class="form-select" id="cmbChickType"></select>
            </div>
            <div class="col-12 col-md-auto">
                <button type="button" class="btn btn-outline-primary w-100" id="btnShow"><i class="bi bi-search"></i> Show</button>
            </div>
        </div>
    </div>
</div>

<div class="row g-2 mb-3">
    <div class="col-4"><div class="stat"><div class="stat-label">Demand Qty</div><div class="stat-value" id="lblDemand">-</div></div></div>
    <div class="col-4"><div class="stat"><div class="stat-label">Schedule Qty</div><div class="stat-value" id="lblSchedule">-</div></div></div>
    <div class="col-4"><div class="stat"><div class="stat-label">Free Qty</div><div class="stat-value" id="lblFree">-</div></div></div>
</div>

<div class="card">
    <div class="card-header d-flex flex-wrap align-items-center gap-2">
        <span><i class="bi bi-table"></i> Schedule <span class="text-muted fw-normal small">- edited rows are marked and saved on Update</span></span>
        <div class="ms-auto d-flex flex-wrap gap-2 align-items-center">
            <div class="input-group input-group-sm" style="width:auto">
                <select class="form-select form-select-sm" id="cmbAllHatchery" aria-label="Hatchery for all rows"></select>
                <button type="button" class="btn btn-outline-secondary" id="btnAllHatchery">Apply to all</button>
            </div>
            <button type="button" class="btn btn-primary btn-sm" id="btnUpdate" disabled="disabled"><i class="bi bi-check2-square"></i> Update</button>
            <button type="button" class="btn btn-outline-danger btn-sm" id="btnDelete"><i class="bi bi-trash"></i> Delete</button>
        </div>
    </div>
    <div class="card-body"><div id="grid"></div></div>
</div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script src="<%: ResolveUrl("~/Scripts/schedule-grid.js") %>?v=1"></script>
<script>
$(function () {
    var grid, shown = null;
    function setTotals(t) {
        var any = grid && grid.rows().length;
        $('#lblDemand').text(any ? App.fmtNum(t.demand) : '-');
        $('#lblSchedule').text(any ? App.fmtNum(t.schedule) : '-');
        $('#lblFree').text(any ? App.fmtNum(t.free) : '-');
    }
    function syncArea() { $('#txtAreaCode').val($('#cmbArea').val()); }
    function reset() { grid.clear(); shown = null; $('#btnUpdate').prop('disabled', true); }
    function show() {
        var p = { areaCode: $('#cmbArea').val(), hatchDate: $('#dtHatch').val(), chickType: $('#cmbChickType').val() };
        if (!p.areaCode || !p.hatchDate) { App.toast('Select area and hatch date.', 'warning'); return; }
        reset();
        App.api('Show', p).then(function (rows) {
            shown = p; grid.load(rows);
            $('#btnUpdate').prop('disabled', !rows.length);
            if (!rows.length) App.toast('No schedule found for this selection.', 'info');
        });
    }

    $('#btnShow').on('click', show);
    $('#btnAllHatchery').on('click', function () {
        var h = $('#cmbAllHatchery').val(); if (!h || !grid.rows().length) return;
        grid.setAll('hatchery', h);
    });
    $('#btnUpdate').on('click', function () {
        var changed = grid.data().filter(function (r) { return r.isEdit == 1; });
        if (!changed.length) { App.toast('Nothing changed.', 'info'); return; }
        App.api('Update', { rows: changed }).then(function () { show(); });
    });
    $('#btnDelete').on('click', function () {
        var area = $('#cmbArea option:selected').text(), d = $('#dtHatch').val();
        if (!d) return;
        App.confirm('Delete <strong>ALL</strong> schedules of area <strong>' + App.esc(area) + '</strong> for hatch date <strong>' + App.fmtDate(d) +
            '</strong>?<br><span class="text-danger small">This removes every chick type for that area and date, as the desktop version did.</span>',
            { html: true, okText: 'Delete all', danger: true, title: 'Delete schedule' })
            .then(function (yes) {
                if (yes) App.api('DeleteAll', { areaCode: $('#cmbArea').val(), hatchDate: d }).then(reset);
            });
    });

    $('#cmbArea').on('change', function () { syncArea(); reset(); });
    $('#dtHatch, #cmbChickType').on('change', reset);

    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbArea', d.areas, { value: 'prefix', text: 'AreaName' });
        App.fillSelect('#cmbChickType', d.chickTypes);
        App.fillSelect('#cmbAllHatchery', d.hatcheries, { placeholder: 'Hatchery for all rows' });
        $('#dtHatch').attr('min', d.minDate).val(App.today());
        syncArea();
        grid = App.scheduleGrid('#grid', { mode: 'edit', hatcheries: d.hatcheries, chickType: function () { return shown ? shown.chickType : $('#cmbChickType').val(); }, onTotals: setTotals });
        grid.clear();
    });
});
</script>
</asp:Content>
