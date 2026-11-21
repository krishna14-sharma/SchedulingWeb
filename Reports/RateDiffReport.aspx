<%@ Page Title="Schedule Rate vs Circular Rate" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="RateDiffReport.aspx.vb" Inherits="RateDiffReportPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="card mb-3 no-print">
    <div class="card-body" data-enter-click="#btnShow">
        <div class="row g-2 align-items-end">
            <div class="col-12 col-md-3">
                <div class="d-flex justify-content-between">
                    <label class="form-label" for="cmbHatchery">Hatchery</label>
                    <div class="form-check form-check-inline m-0">
                        <input class="form-check-input" type="checkbox" id="chkAll" />
                        <label class="form-check-label small fw-semibold" for="chkAll">ALL</label>
                    </div>
                </div>
                <select class="form-select" id="cmbHatchery"></select>
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label" for="dtFrom">Hatch Date From</label>
                <input type="date" class="form-control" id="dtFrom" />
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label" for="dtTo">To</label>
                <input type="date" class="form-control" id="dtTo" />
            </div>
            <div class="col-12 col-md-3">
                <label class="form-label d-block">Chicks Type</label>
                <div class="btn-group w-100" role="group" aria-label="Chicks type">
                    <input type="radio" class="btn-check" name="ctype" id="rdBroiler" value="Broiler" checked="checked" />
                    <label class="btn btn-outline-primary" for="rdBroiler">Broiler</label>
                    <input type="radio" class="btn-check" name="ctype" id="rdLayer" value="Layer" />
                    <label class="btn btn-outline-primary" for="rdLayer">Layer</label>
                    <input type="radio" class="btn-check" name="ctype" id="rdCockrel" value="Cockrel" />
                    <label class="btn btn-outline-primary" for="rdCockrel">Cockrel</label>
                </div>
            </div>
            <div class="col-4 col-md-2">
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
    $('#chkAll').on('change', function () { $('#cmbHatchery').prop('disabled', this.checked); });
    $('#btnShow').on('click', function () {
        var p = { hatchery: $('#cmbHatchery').val() || '', all: $('#chkAll').is(':checked'),
                  fromDate: $('#dtFrom').val(), toDate: $('#dtTo').val(), chickType: $('input[name=ctype]:checked').val() };
        if (!p.fromDate || !p.toDate) { App.toast('Select hatch dates.', 'warning'); return; }
        if (p.fromDate > p.toDate) { App.toast('From date is after To date.', 'warning'); return; }
        App.api('Run', p).then(function (rows) {
            App.report('#report', {
                title: 'SCHEDULE RATE vs CIRCULAR RATE',
                lines: ['HATCHERY: ' + (p.all ? 'ALL' : p.hatchery) + '   CHICKS: ' + (p.chickType === 'Broiler' ? 'BROILER / BROILER(M)' : p.chickType.toUpperCase()),
                        'HATCH DATE: ' + App.fmtDate(p.fromDate) + ' to ' + App.fmtDate(p.toDate)],
                exportName: 'RateDiffReport',
                columns: [
                    { key: 'Hatch_DAte', title: 'Hatch Date', type: 'date' }, { key: 'Cust_Code', title: 'Code' },
                    { key: 'Cust_Name', title: 'Name' }, { key: 'Areaname', title: 'Area' },
                    { key: 'Quantity', title: 'Quantity', type: 'int', total: true }, { key: 'FreeQty', title: 'Free Qty', type: 'int', total: true },
                    { key: 'ScheduleRate', title: 'Schedule Rate', type: 'num' }, { key: 'CircularRate', title: 'Circular Rate', type: 'num' },
                    { key: 'Diff', title: 'Diff', type: 'num' },
                    { key: 'DiffAmount', title: 'Diff Amount', type: 'num', total: true }
                ],
                rows: rows
            });
        });
    });
    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbHatchery', d.hatcheries);
        $('#dtFrom').val(App.today()); $('#dtTo').val(App.today());
    });
});
</script>
</asp:Content>
