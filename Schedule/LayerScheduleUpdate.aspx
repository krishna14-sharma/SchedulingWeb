<%@ Page Title="Layer Schedule Update" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="LayerScheduleUpdate.aspx.vb" Inherits="LayerScheduleUpdatePage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="row g-3">
    <div class="col-lg-4">
        <div class="card" id="formCard">
            <div class="card-header"><i class="bi bi-egg"></i> Layer Demand</div>
            <div class="card-body" data-enter-click="#btnSave">
                <div class="alert alert-warning py-2 small align-items-center gap-2 edit-banner"><i class="bi bi-pencil"></i> Editing ID <strong class="edit-label"></strong></div>
                <input type="hidden" id="hidId" value="" />
                <div class="mb-3">
                    <label class="form-label" for="cmbCust">Name</label>
                    <select class="form-select" id="cmbCust"></select>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="dtDemand">Demand Date</label>
                    <input type="date" class="form-control" id="dtDemand" />
                </div>
                <div class="mb-3">
                    <label class="form-label" for="txtQty">Demand Qty</label>
                    <input type="number" inputmode="numeric" min="0" class="form-control" id="txtQty" />
                </div>
                <div class="btn-toolbar-app">
                    <button type="button" class="btn btn-primary" id="btnSave"><i class="bi bi-save"></i> Save</button>
                    <button type="button" class="btn btn-primary" id="btnUpdate" disabled="disabled"><i class="bi bi-check2-square"></i> Update</button>
                    <button type="button" class="btn btn-outline-danger" id="btnDelete" disabled="disabled"><i class="bi bi-trash"></i> Delete</button>
                    <button type="button" class="btn btn-light" id="btnClear"><i class="bi bi-x-circle"></i> Clear</button>
                </div>
            </div>
        </div>
    </div>
    <div class="col-lg-8">
        <div class="card">
            <div class="card-header"><i class="bi bi-list-ul"></i> Layer demand on <span id="gridTitle"></span> <span class="text-muted fw-normal small">- tap a row to edit</span></div>
            <div class="card-body"><div id="grid"></div></div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script>
$(function () {
    var grid;
    function load() {
        var d = $('#dtDemand').val(); if (!d) return;
        $('#gridTitle').text(App.fmtDate(d));
        App.api('List', { scheduleDate: d }).then(function (rows) {
            grid = App.grid('#grid', rows, { exportName: 'LayerDemand', onRowClick: edit });
        });
    }
    function edit(r) {
        App.setSelect('#cmbCust', App.get(r, 'CustomerName'));
        var sd = App.get(r, 'ScheduleDate') || App.get(r, 'DemandDate');
        if (sd) $('#dtDemand').val(App.isoDate(sd));
        var q = App.get(r, 'DemandQty'); if (q === undefined || q === null) q = App.get(r, 'Qty');
        $('#txtQty').val(App.num(q));
        $('#hidId').val(App.get(r, 'ID'));
        $('#btnSave').prop('disabled', true); $('#btnUpdate, #btnDelete').prop('disabled', false);
        App.editMode('#formCard', true, App.get(r, 'ID'));
    }
    function clearAll() {
        $('#hidId').val(''); $('#txtQty').val('');
        $('#btnSave').prop('disabled', false); $('#btnUpdate, #btnDelete').prop('disabled', true);
        App.editMode('#formCard', false); grid && grid.clearSelection();
    }
    function entry() { return { id: +($('#hidId').val() || 0), demandDate: $('#dtDemand').val(), customer: $('#cmbCust').val(), qty: App.num($('#txtQty').val()) }; }

    $('#btnSave').on('click', function () {
        var e = entry();
        if (!$.trim($('#txtQty').val())) { App.toast('Please enter Qty', 'warning'); $('#txtQty').focus(); return; }
        if (!e.customer) { App.toast('Please select Customer Name', 'warning'); return; }
        App.api('Save', e).then(function () { clearAll(); load(); });
    });
    $('#btnUpdate').on('click', function () {
        App.confirm('Update this layer demand?').then(function (yes) {
            if (yes) App.api('Update', entry()).then(function () { clearAll(); load(); });
        });
    });
    $('#btnDelete').on('click', function () {
        App.confirm('Delete this layer demand?', { okText: 'Delete', danger: true }).then(function (yes) {
            if (yes) App.api('Delete', { id: +$('#hidId').val() }).then(function () { clearAll(); load(); });
        });
    });
    $('#btnClear').on('click', clearAll);
    $('#dtDemand').on('change', function () { if (!$('#hidId').val()) load(); });

    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbCust', d.customers, { placeholder: '-- select --' });
        $('#dtDemand').val(App.today());
        load();
    });
});
</script>
</asp:Content>
