<%@ Page Title="Scheduling Report" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="SchedulingReport.aspx.vb" Inherits="SchedulingReportPage" %>

<asp:Content ContentPlaceHolderID="HeadContent" runat="server">
<style>
    /* Layout copied from the Crystal report CrRepSchedule */
    .hs-sheet { background: #fff; border-radius: .5rem; padding: 1rem; overflow-x: auto; }
    .hs-page { max-width: 900px; margin: 0 auto; border: 1px dotted #9aa3b2; padding: 14px 16px 10px; font-family: Arial, Helvetica, sans-serif; color: #000; }
    .hs-head { display: flex; align-items: flex-start; gap: 16px; margin-bottom: 14px; }
    .hs-head img { height: 26px; margin-top: 8px; }
    .hs-head .hs-titles { flex: 1; text-align: center; }
    .hs-head .t1 { font-size: 20px; }
    .hs-head .t2, .hs-head .t3 { font-size: 16px; }
    .hs-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
    .hs-table th { font-weight: 700; border: 1px solid #000; padding: 3px 4px; vertical-align: bottom; line-height: 1.15; }
    .hs-table td { border: 1px solid #000; padding: 3px 4px; }
    .hs-table .n { text-align: right; padding-right: 8px; }
    .hs-table .c { text-align: right; padding-right: 18px; }
    .hs-table .grp td { border-left: 0; border-right: 0; font-weight: 700; padding-top: 2px; }
    .hs-table .tot td { font-weight: 400; }
    .hs-table .tot .lbl { white-space: nowrap; }
    .hs-table .blank td { height: 22px; }
    .hs-note { margin-top: 18px; font-size: 13px; }
    .hs-note b { margin-right: 6px; }
    @media print {
        .hs-sheet { padding: 0 !important; overflow: visible; }
        .hs-page { border: 0; max-width: none; padding: 0; }
        .hs-table { font-size: 10.5px; }
        .hs-table thead { display: table-header-group; }
        .hs-table tr { page-break-inside: avoid; }
        .hs-head .t1 { font-size: 16px; } .hs-head .t2, .hs-head .t3 { font-size: 13px; }
    }
</style>
</asp:Content>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="card mb-3 no-print">
    <div class="card-body" data-enter-click="#btnShow">
        <div class="row g-2 align-items-end">
            <div class="col-6 col-md-2">
                <label class="form-label" for="dtHatch">Hatch Date</label>
                <input type="date" class="form-control" id="dtHatch" />
            </div>
            <div class="col-6 col-md-3">
                <div class="d-flex justify-content-between">
                    <label class="form-label" for="cmbHatchery">Hatcheries</label>
                    <div class="form-check form-check-inline m-0">
                        <input class="form-check-input" type="checkbox" id="chkAll" />
                        <label class="form-check-label small fw-semibold" for="chkAll">ALL</label>
                    </div>
                </div>
                <select class="form-select" id="cmbHatchery"></select>
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label" for="cmbChickType">Chicks Type</label>
                <select class="form-select" id="cmbChickType"></select>
            </div>
            <div class="col-6 col-md-3">
                <label class="form-label" for="txtNote">Note</label>
                <input type="text" class="form-control" id="txtNote" maxlength="300" />
            </div>
            <div class="col-12 col-md-2">
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
    var LOGO = '<%: ResolveUrl("~/Content/img/logo.jpg") %>';
    var last = null;

    function f2(v) { return App.fmtNum(v, 2).replace(/,/g, ''); }
    function avg(list, key) { return list.length ? list.reduce(function (s, r) { return s + App.num(App.get(r, key)); }, 0) / list.length : 0; }
    function sum(list, key) { return list.reduce(function (s, r) { return s + App.num(App.get(r, key)); }, 0); }
    function qty(r) { return App.num(App.get(r, 'QtyNet')) + App.num(App.get(r, 'Qty2Per')); }   // Quantity = Qty Net + Free Qty
    function sumQty(list) { return list.reduce(function (s, r) { return s + qty(r); }, 0); }
    function wavg(list, key, w) { var q = sum(list, w); return q ? list.reduce(function (s, r) { return s + App.num(App.get(r, key)) * App.num(App.get(r, w)); }, 0) / q : 0; }

    function render(p, rows) {
        // group by hatchery (Crystal group header)
        var groups = {}, order = [];
        rows.forEach(function (r) { var h = App.get(r, 'Hatchery') || ''; if (!groups[h]) { groups[h] = []; order.push(h); } groups[h].push(r); });
        order.sort();

        var h = '<div class="hs-sheet">' +
            '<div class="d-flex flex-wrap gap-2 justify-content-end mb-2 no-print">' +
            '<button type="button" class="btn btn-sm btn-outline-success" id="btnXls"><i class="bi bi-file-earmark-spreadsheet"></i> Excel</button>' +
            '<button type="button" class="btn btn-sm btn-outline-secondary" onclick="window.print()"><i class="bi bi-printer"></i> Print / PDF</button></div>' +
            '<div class="hs-page"><div class="hs-head"><img src="' + LOGO + '" alt="Phoenix" />' +
            '<div class="hs-titles"><div class="t1">PHOENIX HATCHERIES HATCH SCHEDULE</div>' +
            '<div class="t2">HATCH DATE:<b>' + App.fmtDate(p.hatchDate) + '</b></div>' +
            '<div class="t3">CHICKS:<b>' + App.esc(p.chickType) + '</b></div></div>' +
            '<div style="width:150px"></div></div>' +
            '<table class="hs-table"><colgroup><col style="width:11%"><col style="width:35%"><col style="width:15%"><col style="width:10%"><col style="width:10%"><col style="width:10%"><col style="width:9%"></colgroup>' +
            '<thead><tr><th>Code</th><th>Name</th><th>Area</th><th class="n">Quantity</th><th class="n">Schedule<br>Rate</th><th class="n">Circular<br>Rate</th><th class="n">Diff.</th></tr></thead><tbody>';

        if (!rows.length) h += '<tr><td colspan="7" class="text-center text-muted py-4">No schedule found.</td></tr>';
        order.forEach(function (g) {
            var list = groups[g];   // entry order, as in the Crystal report
            h += '<tr class="grp"><td colspan="7">' + App.esc(g) + '</td></tr>';
            list.forEach(function (r) {
                var sr = App.num(App.get(r, 'Rate')), cr = App.num(App.get(r, 'CircularRate'));
                h += '<tr><td>' + App.esc(App.get(r, 'Cust_Code')) + '</td><td>' + App.esc(App.get(r, 'Cust_Name')) + '</td><td>' + App.esc(App.get(r, 'Areaname')) + '</td>' +
                     '<td class="c">' + qty(r) + '</td><td class="c">' + f2(sr) + '</td><td class="c">' + f2(cr) + '</td><td class="c">' + f2(cr - sr) + '</td></tr>';
            });
            // Total/Avg Rate: schedule rate weighted by quantity, circular rate simple average (same as the Crystal report)
            h += '<tr class="tot"><td></td><td></td><td class="lbl">Total/Avg Rate:</td><td class="c">' + sumQty(list) + '</td>' +
                 '<td class="c">' + f2(wavg(list, 'Rate', 'QtyNet')) + '</td><td class="c">' + f2(avg(list, 'CircularRate')) + '</td><td></td></tr>';
        });
        if (rows.length) {
            h += '<tr class="tot"><td></td><td></td><td class="lbl">Grand Total/Avg:</td><td class="c">' + sumQty(rows) + '</td>' +
                 '<td class="c">' + f2(avg(rows, 'Rate')) + '</td><td class="c">' + f2(avg(rows, 'CircularRate')) + '</td><td></td></tr>' +
                 '<tr class="blank"><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>';
        }
        h += '</tbody></table><div class="hs-note"><b>Note:</b>' + App.esc(p.note) + '</div></div></div>';
        $('#report').html(h);
        $('#btnXls').on('click', function () {
            App.exportCsv('HatchSchedule', rows.map(function (r) {
                return { Hatchery: App.get(r, 'Hatchery'), Code: App.get(r, 'Cust_Code'), Name: App.get(r, 'Cust_Name'), Area: App.get(r, 'Areaname'),
                         Quantity: qty(r), ScheduleRate: App.get(r, 'Rate'), CircularRate: App.get(r, 'CircularRate'),
                         Diff: (App.num(App.get(r, 'CircularRate')) - App.num(App.get(r, 'Rate'))).toFixed(2) };
            }));
        });
    }

    $('#chkAll').on('change', function () { $('#cmbHatchery').prop('disabled', this.checked); });
    $('#btnShow').on('click', function () {
        var p = { hatchDate: $('#dtHatch').val(), chickType: $('#cmbChickType').val(), hatchery: $('#cmbHatchery').val(), all: $('#chkAll').is(':checked') };
        if (!p.hatchDate) { App.toast('Select hatch date.', 'warning'); return; }
        App.api('Run', p).then(function (rows) {
            var $ps = $('#reportPageSize');
            if (!$ps.length) $ps = $('<style id="reportPageSize"></style>').appendTo('head');
            $ps.text('@media print { @page { size: A4 portrait; } }');
            p.note = $('#txtNote').val();
            render(p, rows);
        });
    });
    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbChickType', d.chickTypes);
        App.fillSelect('#cmbHatchery', d.hatcheries);
        $('#dtHatch').val(App.today());
    });
});
</script>
</asp:Content>
