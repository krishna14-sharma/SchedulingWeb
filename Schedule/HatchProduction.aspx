<%@ Page Title="Hatch Production" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="HatchProduction.aspx.vb" Inherits="HatchProductionPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="row g-3">
    <div class="col-lg-4">
        <div class="card" id="formCard">
            <div class="card-header"><i class="bi bi-egg-fried"></i> Hatch Qty</div>
            <div class="card-body" data-enter-click="#btnSave">
                <div class="alert alert-info py-2 small align-items-center gap-2 edit-banner"><i class="bi bi-hand-index"></i> Selected entry ID <strong class="edit-label"></strong></div>
                <input type="hidden" id="hidId" value="" />
                <div class="mb-3">
                    <label class="form-label" for="cmbUnit">Prod. Unit</label>
                    <select class="form-select" id="cmbUnit"></select>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="dtHatch">Hatch Date</label>
                    <input type="date" class="form-control" id="dtHatch" />
                    <div class="form-text" id="rangeHint"></div>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="txtQty">Hatch Qty</label>
                    <input type="number" inputmode="numeric" min="0" step="1" class="form-control" id="txtQty" />
                </div>
                <div class="btn-toolbar-app">
                    <button type="button" class="btn btn-primary" id="btnSave"><i class="bi bi-save"></i> Save</button>
                    <button type="button" class="btn btn-outline-danger" id="btnDelete" disabled="disabled"><i class="bi bi-trash"></i> Delete</button>
                    <button type="button" class="btn btn-light" id="btnClear"><i class="bi bi-x-circle"></i> Clear</button>
                </div>
            </div>
        </div>
    </div>
    <div class="col-lg-8">
        <div class="card">
            <div class="card-header"><i class="bi bi-list-ul"></i> Hatch Qty this session <span class="text-muted fw-normal small">- tap a row to select</span></div>
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
        App.api('List').then(function (rows) {
            grid = App.grid('#grid', rows, {
                exportName: 'HatchQty',
                columns: [
                    { key: 'Hatch_date', title: 'Hatch Date', type: 'date' }, { key: 'prd_unit', title: 'Prod. Unit' },
                    { key: 'Hatch_Qty', title: 'Hatch Qty', type: 'int', total: true }, { key: 'id', title: 'ID', type: 'int' }
                ],
                onRowClick: function (r) {
                    App.setSelect('#cmbUnit', App.get(r, 'prd_unit'));
                    $('#dtHatch').val(App.isoDate(App.get(r, 'Hatch_date')));
                    $('#txtQty').val(App.get(r, 'Hatch_Qty'));
                    $('#hidId').val(App.get(r, 'id'));
                    $('#btnDelete').prop('disabled', false);
                    App.editMode('#formCard', true, App.get(r, 'id'));
                }
            });
        });
    }
    function clearSel() {
        $('#hidId').val(''); $('#txtQty').val(''); $('#btnDelete').prop('disabled', true);
        App.editMode('#formCard', false); grid && grid.clearSelection();
    }

    $('#btnSave').on('click', function () {
        var qty = $.trim($('#txtQty').val());
        if (!qty) { App.toast('Item Qty Required', 'warning'); $('#txtQty').focus(); return; }
        App.api('Save', { hatchDate: $('#dtHatch').val(), qty: App.num(qty), unit: $('#cmbUnit').val() })
            .then(function () { clearSel(); load(); $('#dtHatch').focus(); });
    });
    $('#btnDelete').on('click', function () {
        var id = $('#hidId').val(); if (!id) return;
        App.confirm('Delete this hatch qty entry?', { okText: 'Delete', danger: true }).then(function (yes) {
            if (yes) App.api('Delete', { id: +id }).then(function () { clearSel(); load(); });
        });
    });
    $('#btnClear').on('click', clearSel);

    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbUnit', d.units);
        $('#dtHatch').attr({ min: d.minDate, max: d.maxDate });
        var t = App.today();
        $('#dtHatch').val(t < d.minDate ? d.minDate : (t > d.maxDate ? d.maxDate : t));
        $('#rangeHint').text('Allowed: ' + App.fmtDate(d.minDate) + ' to ' + App.fmtDate(d.maxDate));
        load();
    });
});
</script>
</asp:Content>
