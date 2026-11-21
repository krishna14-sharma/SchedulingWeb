<%@ Page Title="Layer Placement Tentative Date" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="LayerTentativeDate.aspx.vb" Inherits="LayerTentativeDatePage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="card mb-3 no-print">
    <div class="card-body" data-enter-click="#btnShow">
        <div class="row g-2 align-items-end">
            <div class="col-8 col-md-4">
                <label class="form-label" for="cmbStation">Area / Station</label>
                <select class="form-select" id="cmbStation"></select>
            </div>
            <div class="col-4 col-md-2">
                <button type="button" class="btn btn-primary w-100" id="btnShow"><i class="bi bi-file-earmark-text"></i> Show</button>
            </div>
            <div class="col-12 col-md-6 small text-muted">
                Layer chick sales whose 70th week is still ahead, with tentative placement dates at 75, 85 and 90 weeks from hatch.
            </div>
        </div>
    </div>
</div>
<div id="report"></div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script>
$(function () {
    $('#btnShow').on('click', function () {
        var st = $('#cmbStation').val();
        App.api('Run', { station: st }).then(function (rows) {
            App.report('#report', {
                title: 'LAYER PLACEMENT TENTATIVE DATE',
                lines: ['AS ON ' + App.fmtDate(App.today()) + (st ? '   STATION: ' + st : '')],
                exportName: 'LayerTentativeDate',
                columns: [
                    { key: 'account_code', title: 'Code' }, { key: 'account_head_name', title: 'Name' }, { key: 'address', title: 'Address' },
                    { key: 'state', title: 'State' }, { key: 'phone', title: 'Phone' }, { key: 'Station', title: 'Station' },
                    { key: 'Qty', title: 'Qty', type: 'int', total: true },
                    { key: 'T75', title: '75 Weeks', type: 'date' }, { key: 'T85', title: '85 Weeks', type: 'date' }, { key: 'T90', title: '90 Weeks', type: 'date' }
                ],
                rows: rows
            });
        });
    });
    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbStation', d.stations, { placeholder: 'ALL' });
    });
});
</script>
</asp:Content>
