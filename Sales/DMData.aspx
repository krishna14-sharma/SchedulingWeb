<%@ Page Title="DM Data - Area Wise Supply" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="DMData.aspx.vb" Inherits="DMDataPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="card mb-3 no-print">
    <div class="card-body" data-enter-click="#btnShow">
        <div class="row g-2 align-items-end">
            <div class="col-12 col-md-3">
                <label class="form-label" for="cmbMode">Report By</label>
                <select class="form-select" id="cmbMode">
                    <option>ALL AREA</option><option>SELECTED AREA</option><option>BY HATCH DATE</option>
                    <option>SELECT AREA AND HATCH DATE</option><option>DM BETWEEN</option>
                </select>
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label" for="cmbChicksType">Chicks Type</label>
                <select class="form-select" id="cmbChicksType"><option>Broiler</option><option>Broiler(M)</option><option>Layer</option><option>Cockrel</option></select>
            </div>
            <div class="col-6 col-md-2 f f-area">
                <label class="form-label" for="cmbArea">Area</label>
                <select class="form-select" id="cmbArea"></select>
            </div>
            <div class="col-6 col-md-2 f f-date">
                <label class="form-label" for="dtFrom">Hatch Date</label>
                <input type="date" class="form-control" id="dtFrom" />
            </div>
            <div class="col-6 col-md-2 f f-date">
                <label class="form-label" for="dtTo">To</label>
                <input type="date" class="form-control" id="dtTo" />
            </div>
            <div class="col-6 col-md-2 f f-unit">
                <label class="form-label" for="cmbUnit">Unit</label>
                <select class="form-select" id="cmbUnit"></select>
            </div>
            <div class="col-3 col-md-1 f f-dm">
                <label class="form-label" for="txtDm1">DM No</label>
                <input type="number" inputmode="numeric" class="form-control" id="txtDm1" />
            </div>
            <div class="col-3 col-md-1 f f-dm">
                <label class="form-label" for="txtDm2">To</label>
                <input type="number" inputmode="numeric" class="form-control" id="txtDm2" />
            </div>
            <div class="col-6 col-md-2 f f-auth">
                <div class="form-check mt-4">
                    <input class="form-check-input" type="checkbox" id="chkIsAuth" checked="checked" />
                    <label class="form-check-label fw-semibold small" for="chkIsAuth">IS AUTH</label>
                </div>
            </div>
            <div class="col-12 col-md-auto ms-md-auto">
                <div class="btn-toolbar-app">
                    <button type="button" class="btn btn-outline-primary" id="btnShow"><i class="bi bi-search"></i> Show</button>
                    <button type="button" class="btn btn-success" id="btnAuth" disabled="disabled"><i class="bi bi-check2-all"></i> Auth.</button>
                    <button type="button" class="btn btn-primary" id="btnPrint"><i class="bi bi-printer"></i> Print</button>
                </div>
            </div>
        </div>
    </div>
</div>
<div class="card"><div class="card-body" id="out"><div class="empty-state"><i class="bi bi-funnel"></i>Choose the filters, then Show (to authorise) or Print.</div></div></div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script>
$(function () {
    var grid = null;
    var FIELDS = {
        'ALL AREA': [], 'SELECTED AREA': ['area'], 'BY HATCH DATE': ['date', 'unit', 'auth'],
        'SELECT AREA AND HATCH DATE': ['area', 'date', 'unit'], 'DM BETWEEN': ['area', 'dm']
    };
    var COLS = [
        { key: 'Area', title: 'Area' }, { key: 'DMNo', title: 'DM No' }, { key: 'DMDate', title: 'DM Date', type: 'date' },
        { key: 'HatchDate', title: 'Hatch Date', type: 'date' }, { key: 'Code', title: 'Code' }, { key: 'CName', title: 'Name' },
        { key: 'Chick_type', title: 'Chicks' }, { key: 'Rate', title: 'Rate', type: 'num' },
        { key: 'TotalChicks', title: 'Total Chicks', type: 'int', total: true }, { key: 'Mortality', title: 'Mortality', type: 'num' },
        { key: 'Hatchries', title: 'Unit' }, { key: 'Remarks', title: 'Remarks' }, { key: 'isAuth', title: 'Auth', type: 'bool' }
    ];
    function syncMode() {
        var on = FIELDS[$('#cmbMode').val()] || [];
        $('.f').each(function () {
            var cls = (this.className.match(/f-(\w+)/) || [])[1];
            $(this).toggleClass('opacity-50', on.indexOf(cls) < 0).find('input,select').prop('disabled', on.indexOf(cls) < 0);
        });
    }
    function filter() {
        return { mode: $('#cmbMode').val(), chickType: $('#cmbChicksType').val(), areaCode: $('#cmbArea').val() || '',
                 fromDate: $('#dtFrom').val(), toDate: $('#dtTo').val(), unit: $('#cmbUnit').val() || '',
                 dmFrom: $('#txtDm1').val(), dmTo: $('#txtDm2').val(), isAuth: $('#chkIsAuth').is(':checked') };
    }
    function lines(f) {
        var l = ['CHICKS: ' + f.chickType + '   ' + f.mode];
        if (FIELDS[f.mode].indexOf('area') >= 0) l.push('AREA: ' + $('#cmbArea option:selected').text());
        if (FIELDS[f.mode].indexOf('date') >= 0) l.push('HATCH DATE: ' + App.fmtDate(f.fromDate) + ' to ' + App.fmtDate(f.toDate) + '   UNIT: ' + f.unit);
        if (FIELDS[f.mode].indexOf('dm') >= 0) l.push('DM NO: ' + f.dmFrom + ' to ' + f.dmTo);
        return l;
    }

    $('#cmbMode').on('change', syncMode);
    $('#btnShow').on('click', function () {
        var f = filter();
        App.api('Run', { f: f, forPrint: false }).then(function (rows) {
            $('#out').empty();
            grid = App.grid('#out', rows, { columns: COLS, checkbox: true, exportName: 'DMData', emptyText: 'No unauthorised DM found.' });
            $('#btnAuth').prop('disabled', !rows.length);
        });
    });
    $('#btnPrint').on('click', function () {
        var f = filter();
        App.api('Run', { f: f, forPrint: true }).then(function (rows) {
            grid = null; $('#btnAuth').prop('disabled', true);
            App.report('#out', { title: 'AREA WISE SUPPLY REPORT', lines: lines(f), columns: COLS, rows: rows, exportName: 'DMSupplyReport', groupBy: 'Area' });
        });
    });
    $('#btnAuth').on('click', function () {
        if (!grid) return;
        var sel = grid.checked().map(function (r) { return String(App.get(r, 'DMNo')); });
        if (!sel.length) { App.toast('Tick the DMs to authorise.', 'warning'); return; }
        App.confirm('Authorise ' + sel.length + ' DM(s)?', { okText: 'Authorise' }).then(function (yes) {
            if (yes) App.api('Authorize', { dmNos: sel }).then(function () { $('#btnShow').trigger('click'); });
        });
    });

    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbArea', d.areas, { value: 'prefix', text: 'label' });
        App.fillSelect('#cmbUnit', d.units);
        $('#dtFrom, #dtTo').val(App.today());
        syncMode();
    });
});
</script>
</asp:Content>
