<%@ Page Title="TR Data - Area Wise and TR Wise" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="TRData.aspx.vb" Inherits="TRDataPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="card mb-3 no-print">
    <div class="card-body" data-enter-click="#btnShow">
        <div class="row g-2 align-items-end">
            <div class="col-12 col-md-3">
                <label class="form-label" for="cmbMode">Report By</label>
                <select class="form-select" id="cmbMode">
                    <option>ALL AREA</option><option>SELECTED AREA</option><option>BY HATCH DATE</option><option>SELECT AREA AND HATCH DATE</option>
                    <option>TR NO BETWEEN</option><option>ALL AREA-BANK DET</option><option>ALL AREA-TRANS TYPE</option>
                    <option>TR NO BETWEEN-BANK DET</option><option>TR NO BETWEEN-TRANS TYPE</option><option>ALL AREA-BANK DET-TRANSTYPE</option>
                </select>
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label" for="cmbAuth">Status</label>
                <select class="form-select" id="cmbAuth">
                    <option value="UN_AUTH">Un-authorised</option><option value="IS_AUT">Authorised</option><option value="ALL">All</option>
                </select>
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
            <div class="col-3 col-md-1 f f-tr">
                <label class="form-label" for="txtTr1">TR</label>
                <input type="number" inputmode="numeric" class="form-control" id="txtTr1" />
            </div>
            <div class="col-3 col-md-1 f f-tr">
                <label class="form-label" for="txtTr2">To</label>
                <input type="number" inputmode="numeric" class="form-control" id="txtTr2" />
            </div>
            <div class="col-6 col-md-3 f f-bank">
                <label class="form-label" for="cmbBank">Bank Det</label>
                <select class="form-select" id="cmbBank"></select>
            </div>
            <div class="col-6 col-md-2 f f-pay">
                <label class="form-label" for="cmbPayMode">Trans Type</label>
                <select class="form-select" id="cmbPayMode"></select>
            </div>
            <div class="col-12 col-md-3">
                <div class="form-check form-check-inline">
                    <input class="form-check-input" type="checkbox" id="chkAll" checked="checked" />
                    <label class="form-check-label small fw-semibold" for="chkAll">ALL Transactions</label>
                </div>
                <div class="form-check form-check-inline">
                    <input class="form-check-input" type="checkbox" id="chkCash" />
                    <label class="form-check-label small fw-semibold" for="chkCash">Cash Transactions</label>
                </div>
            </div>
            <div class="col-12 col-md-auto ms-md-auto">
                <div class="btn-toolbar-app">
                    <button type="button" class="btn btn-outline-primary" id="btnShow"><i class="bi bi-search"></i> Show</button>
                    <button type="button" class="btn btn-success" id="btnAuth" disabled="disabled"><i class="bi bi-check2-all"></i> Auth</button>
                    <button type="button" class="btn btn-outline-danger" id="btnUnAuth" disabled="disabled"><i class="bi bi-x-octagon"></i> Un-Auth</button>
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
        'ALL AREA': [], 'SELECTED AREA': ['area'], 'BY HATCH DATE': ['date'], 'SELECT AREA AND HATCH DATE': ['area', 'date'],
        'TR NO BETWEEN': ['area', 'tr'], 'ALL AREA-BANK DET': ['bank'], 'ALL AREA-TRANS TYPE': ['pay'],
        'TR NO BETWEEN-BANK DET': ['area', 'tr', 'bank'], 'TR NO BETWEEN-TRANS TYPE': ['area', 'tr', 'pay'], 'ALL AREA-BANK DET-TRANSTYPE': ['bank', 'pay']
    };
    var COLS = [
        { key: 'isAuth', title: 'Auth', type: 'bool' }, { key: 'Area', title: 'Area' }, { key: 'AreaCode', title: 'Code' },
        { key: 'TRNo', title: 'TR No' }, { key: 'TrDate', title: 'TR Date', type: 'date' }, { key: 'HatchDate', title: 'Hatch Date', type: 'date' },
        { key: 'entrydate', title: 'Entry', type: 'date' }, { key: 'Code', title: 'Cust Code' }, { key: 'CName', title: 'Name' },
        { key: 'TrAmount', title: 'Amount', type: 'num', total: true }, { key: 'Bank_det', title: 'Bank' }, { key: 'Pay_mode', title: 'Mode' },
        { key: 'bankdate', title: 'Bank Date', type: 'date' }, { key: 'DD_No', title: 'DD/Ref' }, { key: 'Chick_type', title: 'Chicks' },
        { key: 'Rate', title: 'Rate', type: 'num' }, { key: 'Remarks', title: 'Remarks' }
    ];
    function syncMode() {
        var on = FIELDS[$('#cmbMode').val()] || [];
        $('.f').each(function () {
            var cls = (this.className.match(/f-(\w+)/) || [])[1];
            $(this).toggleClass('opacity-50', on.indexOf(cls) < 0).find('input,select').prop('disabled', on.indexOf(cls) < 0);
        });
    }
    function filter() {
        return { mode: $('#cmbMode').val(), areaCode: $('#cmbArea').val() || '', fromDate: $('#dtFrom').val(), toDate: $('#dtTo').val(),
                 trFrom: $('#txtTr1').val(), trTo: $('#txtTr2').val(), authFilter: $('#cmbAuth').val(),
                 cashOnly: $('#chkCash').is(':checked'), allTrans: $('#chkAll').is(':checked'),
                 bankDet: $('#cmbBank').val() || '', payMode: $('#cmbPayMode').val() || '' };
    }
    function lines(f) {
        var on = FIELDS[f.mode], l = [f.mode + '   ' + $('#cmbAuth option:selected').text().toUpperCase() + '   ' + (f.allTrans ? 'ALL TRANSACTIONS' : (f.cashOnly ? 'CASH' : 'NON-CASH'))];
        if (on.indexOf('area') >= 0) l.push('AREA: ' + $('#cmbArea option:selected').text());
        if (on.indexOf('date') >= 0) l.push('HATCH DATE: ' + App.fmtDate(f.fromDate) + ' to ' + App.fmtDate(f.toDate));
        if (on.indexOf('tr') >= 0) l.push('TR: ' + f.trFrom + ' to ' + f.trTo);
        if (on.indexOf('bank') >= 0) l.push('BANK: ' + f.bankDet);
        if (on.indexOf('pay') >= 0) l.push('TRANS TYPE: ' + f.payMode);
        return l;
    }
    function act(on) { $('#btnAuth, #btnUnAuth').prop('disabled', !on); }

    $('#cmbMode').on('change', syncMode);
    $('#chkAll').on('change', function () { if (this.checked) $('#chkCash').prop('checked', false); });
    $('#chkCash').on('change', function () { if (this.checked) $('#chkAll').prop('checked', false); });

    $('#btnShow').on('click', function () {
        App.api('Run', { f: filter(), forPrint: false }).then(function (rows) {
            $('#out').empty();
            grid = App.grid('#out', rows, { columns: COLS, checkbox: true, exportName: 'TRData' });
            act(rows.length > 0);
        });
    });
    $('#btnPrint').on('click', function () {
        var f = filter();
        App.api('Run', { f: f, forPrint: true }).then(function (rows) {
            grid = null; act(false);
            App.report('#out', { title: 'AREA WISE AND TR WISE REPORT', lines: lines(f), columns: COLS, rows: rows, exportName: 'TRReport', groupBy: 'Area' });
        });
    });
    function selected() { return grid ? grid.checked().map(function (r) { return String(App.get(r, 'TRNo')); }) : []; }
    $('#btnAuth').on('click', function () {
        var sel = selected(); if (!sel.length) { App.toast('Tick the TRs first.', 'warning'); return; }
        App.confirm('Authorise ' + sel.length + ' TR(s)?', { okText: 'Authorise' }).then(function (yes) {
            if (yes) App.api('Authorize', { trNos: sel }).then(function () { $('#btnShow').trigger('click'); });
        });
    });
    $('#btnUnAuth').on('click', function () {
        var sel = selected(); if (!sel.length) { App.toast('Tick the TRs first.', 'warning'); return; }
        App.confirm('Remove authorisation from ' + sel.length + ' TR(s)? Posted TRs are not changed.', { okText: 'Un-authorise', danger: true }).then(function (yes) {
            if (yes) App.api('UnAuthorize', { trNos: sel }).then(function () { $('#btnShow').trigger('click'); });
        });
    });

    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbArea', d.areas, { value: 'prefix', text: 'label' });
        App.fillSelect('#cmbBank', d.banks);
        App.fillSelect('#cmbPayMode', d.payModes);
        $('#dtFrom, #dtTo').val(App.today());
        syncMode();
    });
});
</script>
</asp:Content>
