<%@ Page Title="Dealer / Other Scheduling" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="DealerScheduling.aspx.vb" Inherits="DealerSchedulingPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="row g-3">
    <div class="col-xl-4 col-lg-5">
        <div class="card" id="formCard">
            <div class="card-header"><i class="bi bi-person-lines-fill"></i> Schedule entry</div>
            <div class="card-body">
                <div class="alert alert-warning py-2 small align-items-center gap-2 edit-banner"><i class="bi bi-pencil"></i> Editing schedule ID <strong class="edit-label"></strong></div>
                <input type="hidden" id="hidId" value="" />

                <div class="mb-2">
                    <div class="btn-group w-100" role="group" aria-label="Customer type">
                        <input type="radio" class="btn-check lock" name="kind" id="rdDealer" value="DR" checked="checked" />
                        <label class="btn btn-outline-primary" for="rdDealer">Dealer</label>
                        <input type="radio" class="btn-check lock" name="kind" id="rdOthers" value="OT" />
                        <label class="btn btn-outline-primary" for="rdOthers">Others</label>
                    </div>
                </div>

                <div class="row g-2">
                    <div class="col-12">
                        <label class="form-label" for="cmbCust">Name</label>
                        <select class="form-select lock" id="cmbCust"></select>
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="txtCode">Code</label>
                        <input type="text" class="form-control" id="txtCode" readonly="readonly" />
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="dtHatch">Hatch Date</label>
                        <input type="date" class="form-control lock" id="dtHatch" />
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="cmbChickType">Chicks Type</label>
                        <select class="form-select" id="cmbChickType"></select>
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="cmbHatchery">Hatchery</label>
                        <select class="form-select lock" id="cmbHatchery"></select>
                    </div>
                    <div class="col-4">
                        <label class="form-label" for="txtQty">Qty Net</label>
                        <input type="number" inputmode="numeric" min="0" class="form-control calc" id="txtQty" />
                    </div>
                    <div class="col-4">
                        <label class="form-label" for="txtFree">Free <span id="freePer" class="text-muted"></span></label>
                        <input type="text" class="form-control" id="txtFree" readonly="readonly" />
                    </div>
                    <div class="col-4">
                        <label class="form-label" for="txtRate">Rate</label>
                        <input type="number" inputmode="decimal" step="0.01" min="0" class="form-control calc" id="txtRate" />
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="txtAmount">Amount</label>
                        <input type="text" class="form-control fw-semibold" id="txtAmount" readonly="readonly" />
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="txtCircular">Circular Rate</label>
                        <input type="number" inputmode="decimal" step="0.01" min="0" class="form-control" id="txtCircular" />
                    </div>
                    <div class="col-4">
                        <label class="form-label" for="txtComp">Comp Rate</label>
                        <input type="number" inputmode="decimal" step="0.01" min="0" class="form-control lock" id="txtComp" />
                    </div>
                    <div class="col-4">
                        <label class="form-label" for="txtDr">Dr</label>
                        <input type="text" class="form-control text-danger" id="txtDr" readonly="readonly" />
                    </div>
                    <div class="col-4">
                        <label class="form-label" for="txtCr">Cr</label>
                        <input type="text" class="form-control text-success" id="txtCr" readonly="readonly" />
                    </div>
                </div>
                <div class="btn-toolbar-app mt-3">
                    <button type="button" class="btn btn-primary" id="btnSave"><i class="bi bi-save"></i> Save</button>
                    <button type="button" class="btn btn-primary" id="btnUpdate" disabled="disabled"><i class="bi bi-check2-square"></i> Update</button>
                    <button type="button" class="btn btn-outline-danger" id="btnDelete" disabled="disabled"><i class="bi bi-trash"></i> Delete</button>
                    <button type="button" class="btn btn-light" id="btnClear"><i class="bi bi-x-circle"></i> Clear</button>
                </div>
            </div>
        </div>
    </div>
    <div class="col-xl-8 col-lg-7">
        <div class="card">
            <div class="card-header"><i class="bi bi-list-ul"></i> Scheduled on <span id="gridTitle"></span> <span class="text-muted fw-normal small">- tap a row to edit</span></div>
            <div class="card-body"><div id="grid"></div></div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script>
$(function () {
    var grid, editing = false;
    function kind() { return $('input[name=kind]:checked').val(); }

    function calc() {
        var per = App.freePercent($('#cmbChickType').val());
        var qty = App.num($('#txtQty').val()), rate = App.num($('#txtRate').val());
        var free = App.bround(qty * per / 100);
        $('#freePer').text('(' + per + '%)');
        $('#txtFree').val(free);
        $('#txtAmount').val(((qty - free) * rate).toFixed(2));
    }

    function loadHeads() {
        return App.api('Heads', { kind: kind() }, { silent: true }).then(function (rows) {
            App.fillSelect('#cmbCust', rows, { value: 'account_code', text: 'account_head_name', placeholder: '-- select --' });
            $('#txtCode, #txtDr, #txtCr').val('');
        });
    }

    function loadBalance() {
        var code = $('#cmbCust').val();
        $('#txtCode').val(code || '');
        if (!code) { $('#txtDr, #txtCr').val(''); return; }
        App.api('Balance', { code: code }, { silent: true }).then(function (b) {
            $('#txtDr').val(App.fmtNum(b.dr, 2)); $('#txtCr').val(App.fmtNum(b.cr, 2));
        });
    }

    function loadGrid() {
        if (editing) return;
        var d = $('#dtHatch').val(); if (!d) return;
        $('#gridTitle').text(App.fmtDate(d) + ' (' + (kind() === 'DR' ? 'Dealer' : 'Others') + ')');
        App.api('List', { hatchDate: d, kind: kind() }).then(function (rows) {
            grid = App.grid('#grid', rows, {
                exportName: 'Schedule_' + kind(),
                columns: [
                    { key: 'Cust_Code', title: 'Code' }, { key: 'Cust_Name', title: 'Name' }, { key: 'Productname', title: 'Chicks' },
                    { key: 'QtyNet', title: 'Qty Net', type: 'int', total: true }, { key: 'Qty2Per', title: 'Free', type: 'int', total: true },
                    { key: 'Rate', title: 'Rate', type: 'num' }, { key: 'Amount', title: 'Amount', type: 'num', total: true },
                    { key: 'CircularRate', title: 'Circular', type: 'num' }, { key: 'Hatchery', title: 'Hatchery' },
                    { key: 'Uname', title: 'User' }
                ],
                onRowClick: edit
            });
        });
    }

    function edit(r) {
        editing = true;
        $('#hidId').val(App.get(r, 'id'));
        App.setSelect('#cmbCust', App.get(r, 'Cust_Code'));
        $('#cmbCust option:selected').text(App.get(r, 'Cust_Name'));
        $('#txtCode').val(App.get(r, 'Cust_Code'));
        $('#dtHatch').val(App.isoDate(App.get(r, 'Hatch_DAte')));
        App.setSelect('#cmbChickType', App.get(r, 'Productname'));
        $('#txtQty').val(App.get(r, 'QtyNet'));
        $('#txtRate').val(App.get(r, 'Rate'));
        $('#txtCircular').val(App.get(r, 'CircularRate'));
        $('#txtComp').val(App.get(r, 'comprate'));
        App.setSelect('#cmbHatchery', App.get(r, 'Hatchery'));
        calc();
        $('#txtFree').val(App.get(r, 'Qty2Per')); $('#txtAmount').val(App.num(App.get(r, 'Amount')).toFixed(2));
        $('#txtDr').val(App.fmtNum(App.get(r, 'dr'), 2)); $('#txtCr').val(App.fmtNum(App.get(r, 'cr'), 2));
        $('.lock').prop('disabled', true);
        $('#btnSave').prop('disabled', true); $('#btnUpdate, #btnDelete').prop('disabled', false);
        App.editMode('#formCard', true, App.get(r, 'id'));
        if (window.innerWidth < 992) document.getElementById('formCard').scrollIntoView({ behavior: 'smooth' });
    }

    function clearAll(reloadGrid) {
        editing = false;
        $('#hidId').val('');
        $('#txtQty, #txtFree, #txtRate, #txtAmount, #txtCircular, #txtComp').val('');
        $('.lock').prop('disabled', false);
        $('#btnSave').prop('disabled', false); $('#btnUpdate, #btnDelete').prop('disabled', true);
        App.editMode('#formCard', false); grid && grid.clearSelection();
        calc();
        if (reloadGrid !== false) loadGrid();
    }

    function entry() {
        return {
            id: +($('#hidId').val() || 0), kind: kind(), custCode: $('#cmbCust').val(), custName: $('#cmbCust option:selected').text(),
            hatchDate: $('#dtHatch').val(), chickType: $('#cmbChickType').val(), hatchery: $('#cmbHatchery').val(),
            qty: App.num($('#txtQty').val()), rate: App.num($('#txtRate').val()), circularRate: App.num($('#txtCircular').val()),
            compRate: App.num($('#txtComp').val()), dr: App.num($('#txtDr').val()), cr: App.num($('#txtCr').val())
        };
    }

    $('#btnSave').on('click', function () {
        var e = entry();
        if (!$.trim($('#txtQty').val())) { App.toast('Please enter Qty', 'warning'); $('#txtQty').focus(); return; }
        if (!$.trim($('#txtRate').val())) { App.toast('Please enter rate', 'warning'); $('#txtRate').focus(); return; }
        if (!e.custCode) { App.toast('Please select head', 'warning'); $('#cmbCust').focus(); return; }
        App.api('Save', { entry: e }).then(function () { clearAll(); });
    });
    $('#btnUpdate').on('click', function () {
        App.confirm('Update this schedule?').then(function (yes) {
            if (yes) App.api('Update', { entry: entry() }).then(function () { clearAll(); });
        });
    });
    $('#btnDelete').on('click', function () {
        App.confirm('Delete this schedule?', { okText: 'Delete', danger: true }).then(function (yes) {
            if (yes) App.api('Delete', { id: +$('#hidId').val(), hatchDate: $('#dtHatch').val() }).then(function () { clearAll(); });
        });
    });
    $('#btnClear').on('click', function () { clearAll(); });

    $('input[name=kind]').on('change', function () { loadHeads(); loadGrid(); });
    $('#cmbCust').on('change', loadBalance);
    $('#dtHatch').on('change', loadGrid);
    $('.calc, #cmbChickType').on('input change', calc);

    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbChickType', d.chickTypes);
        App.fillSelect('#cmbHatchery', d.hatcheries);
        $('#dtHatch').attr('min', d.minDate).val(App.today());
        calc();
        loadHeads(); loadGrid();
    });
});
</script>
</asp:Content>
