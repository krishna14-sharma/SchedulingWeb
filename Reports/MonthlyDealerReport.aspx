<%@ Page Title="Monthly Dealer Report (Chicks)" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="MonthlyDealerReport.aspx.vb" Inherits="MonthlyDealerReportPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="card mb-3 no-print">
    <div class="card-body" data-enter-click="#btnShow">
        <div class="row g-2 align-items-end">
            <div class="col-6 col-md-2">
                <label class="form-label" for="dtFrom">Hatch Date From</label>
                <input type="date" class="form-control" id="dtFrom" />
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label" for="dtTo">To</label>
                <input type="date" class="form-control" id="dtTo" />
            </div>
            <div class="col-6 col-md-3">
                <label class="form-label" for="cmbChickType">Chicks Type</label>
                <select class="form-select" id="cmbChickType"></select>
            </div>
            <div class="col-6 col-md-5">
                <label class="form-label" for="cmbArea">Area</label>
                <select class="form-select" id="cmbArea"></select>
            </div>
            <div class="col-12 col-md-3">
                <label class="form-label d-block">Type</label>
                <div class="btn-group w-100" role="group">
                    <input type="radio" class="btn-check" name="kind" id="rdDealer" value="DR" checked="checked" />
                    <label class="btn btn-outline-primary" for="rdDealer">Dealer</label>
                    <input type="radio" class="btn-check" name="kind" id="rdOthers" value="OT" />
                    <label class="btn btn-outline-primary" for="rdOthers">Others</label>
                </div>
            </div>
            <div class="col-12 col-md-6">
                <div class="d-flex justify-content-between">
                    <label class="form-label" for="cmbCust">Name</label>
                    <div class="form-check form-check-inline m-0">
                        <input class="form-check-input" type="checkbox" id="chkAll" />
                        <label class="form-check-label small fw-semibold" for="chkAll" id="lblAll">ALL dealers</label>
                    </div>
                </div>
                <select class="form-select" id="cmbCust"></select>
            </div>
            <div class="col-12 col-md-3">
                <button type="button" class="btn btn-primary w-100" id="btnShow"><i class="bi bi-file-earmark-text"></i> Show</button>
            </div>
        </div>
    </div>
</div>
<div id="report"></div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script>
$(function () {
    function kind() { return $('input[name=kind]:checked').val(); }
    function loadHeads() {
        App.api('Heads', { kind: kind(), areaCode: $('#cmbArea').val() || '' }, { silent: true }).then(function (rows) {
            App.fillSelect('#cmbCust', rows, { value: 'account_code', text: 'account_head_name' });
        });
    }
    $('input[name=kind], #cmbArea').on('change', loadHeads);
    $('#cmbArea').on('change', function () { $('#lblAll').text(this.value ? 'ALL in area' : 'ALL dealers'); });
    $('#chkAll').on('change', function () { $('#cmbCust').prop('disabled', this.checked); });
    $('#btnShow').on('click', function () {
        var p = { fromDate: $('#dtFrom').val(), toDate: $('#dtTo').val(), chickType: $('#cmbChickType').val(), all: $('#chkAll').is(':checked'), code: $('#cmbCust').val() || '',
                  areaCode: $('#cmbArea').val() || '', areaName: $('#cmbArea').val() ? $('#cmbArea option:selected').text() : '' };
        if (!p.fromDate || !p.toDate) { App.toast('Select dates.', 'warning'); return; }
        if (!p.all && !p.code) { App.toast('Select a name or tick ALL.', 'warning'); return; }
        App.api('Run', p).then(function (rows) {
            App.report('#report', {
                title: 'MONTHLY DEALER DATA (CHICKS)',
                lines: ['Hatch Date: ' + App.fmtDate(p.fromDate) + ' to ' + App.fmtDate(p.toDate) + '   CHICKS: ' + p.chickType,
                        'AREA: ' + (p.areaName || 'ALL') + '   ' + (p.all ? (p.areaName ? 'ALL CUSTOMERS IN AREA' : 'ALL DEALERS') : $('#cmbCust option:selected').text() + ' (' + p.code + ')')],
                exportName: 'MonthlyDealerReport', groupBy: p.all ? (p.areaName ? 'Cust_Name' : 'Areaname') : null,
                columns: [
                    { key: 'Hatch_DAte', title: 'Hatch Date', type: 'date' }, { key: 'Cust_Code', title: 'Code' }, { key: 'Cust_Name', title: 'Name' },
                    { key: 'Areaname', title: 'Area' }, { key: 'Productname', title: 'Chicks' }, { key: 'Hatchery', title: 'Hatchery' },
                    { key: 'QtyNet', title: 'Qty Net', type: 'int', total: true }, { key: 'Qty2Per', title: 'Free Qty', type: 'int', total: true }, { key: 'Quantity', title: 'Quantity', type: 'int', total: true },
                    { key: 'Rate', title: 'Rate', type: 'num' }, { key: 'Amount', title: 'Amount', type: 'num', total: true }
                ],
                rows: rows
            });
        });
    });
    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbChickType', d.chickTypes);
        App.fillSelect('#cmbArea', d.areas, { value: 'prefix', text: 'AreaName', placeholder: 'All areas' });
        $('#dtFrom').val(App.firstOfMonth()); $('#dtTo').val(App.today());
        loadHeads();
    });
});
</script>
</asp:Content>
