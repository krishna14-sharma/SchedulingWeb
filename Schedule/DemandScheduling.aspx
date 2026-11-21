<%@ Page Title="Demand Scheduling" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="DemandScheduling.aspx.vb" Inherits="DemandSchedulingPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="card mb-3 no-print">
    <div class="card-body" data-enter-click="#btnShow">
        <div class="row g-2 align-items-end">
            <div class="col-12 col-md-auto">
                <div class="btn-group w-100" role="group" aria-label="Demand type">
                    <input type="radio" class="btn-check" name="kind" id="rdCustomer" value="CU" checked="checked" />
                    <label class="btn btn-outline-primary" for="rdCustomer">Customer</label>
                    <input type="radio" class="btn-check" name="kind" id="rdDealer" value="DR" />
                    <label class="btn btn-outline-primary" for="rdDealer">Dealer</label>
                </div>
            </div>
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
        <span><i class="bi bi-table"></i> Demand</span>
        <div class="ms-auto d-flex flex-wrap gap-2 align-items-center">
            <div class="input-group input-group-sm" style="width:auto">
                <select class="form-select form-select-sm" id="cmbAllHatchery" aria-label="Hatchery for all rows"></select>
                <button type="button" class="btn btn-outline-secondary" id="btnAllHatchery" title="Set this hatchery on every row">Apply to all</button>
            </div>
            <button type="button" class="btn btn-primary btn-sm" id="btnSave" disabled="disabled"><i class="bi bi-save"></i> Save</button>
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

    function reset() { grid.clear(); shown = null; $('#btnSave').prop('disabled', true); }

    $('#btnShow').on('click', function () {
        var p = { areaCode: $('#cmbArea').val(), hatchDate: $('#dtHatch').val(), chickType: $('#cmbChickType').val(), kind: $('input[name=kind]:checked').val() };
        if (!p.areaCode || !p.hatchDate || !p.chickType) { App.toast('Select area, hatch date and chicks type.', 'warning'); return; }
        reset();
        App.api('Show', p).then(function (rows) {
            shown = p;
            grid.load(rows);
            $('#btnSave').prop('disabled', !rows.length);
            if (!rows.length) App.toast('No demand found for this selection.', 'info');
        });
    });

    $('#btnAllHatchery').on('click', function () {
        var h = $('#cmbAllHatchery').val(); if (!h || !grid.rows().length) return;
        grid.setAll('hatchery', h);
    });

    $('#btnSave').on('click', function () {
        if (!shown) return;
        var rows = grid.rows();
        var missing = rows.filter(function (r) { return !r.hatchery; }).length;
        if (missing) { App.toast('Select a hatchery on every row (' + missing + ' missing).', 'warning'); return; }
        App.confirm('Save schedule for ' + rows.length + ' rows (' + $('#cmbArea option:selected').text() + ', ' + App.fmtDate(shown.hatchDate) + ', ' + shown.chickType + ')?')
            .then(function (yes) {
                if (!yes) return;
                App.api('Save', { areaCode: shown.areaCode, hatchDate: shown.hatchDate, chickType: shown.chickType, rows: grid.data() })
                    .then(function () { reset(); });
            });
    });

    $('#cmbArea').on('change', function () { syncArea(); reset(); });
    $('#dtHatch, #cmbChickType, input[name=kind]').on('change', reset);

    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbArea', d.areas, { value: 'prefix', text: 'AreaName' });
        App.fillSelect('#cmbChickType', d.chickTypes);
        App.fillSelect('#cmbAllHatchery', d.hatcheries, { placeholder: 'Hatchery for all rows' });
        $('#dtHatch').attr('min', d.minDate).val(App.today());
        syncArea();
        grid = App.scheduleGrid('#grid', { mode: 'new', hatcheries: d.hatcheries, chickType: function () { return shown ? shown.chickType : $('#cmbChickType').val(); }, onTotals: setTotals });
        grid.clear();
    });
});
</script>
</asp:Content>
