<%@ Page Title="Edit Demand" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="EditDemand.aspx.vb" Inherits="EditDemandPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="card mb-3">
    <div class="card-body" data-enter-click="#btnShow">
        <div class="row g-2 align-items-end">
            <div class="col-12 col-md-3">
                <label class="form-label" for="cmbArea">Area</label>
                <select class="form-select" id="cmbArea"></select>
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label" for="dtFrom">Hatch Date From</label>
                <input type="date" class="form-control" id="dtFrom" />
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label" for="dtTo">Hatch Date To</label>
                <input type="date" class="form-control" id="dtTo" />
            </div>
            <div class="col-8 col-md-3">
                <div class="form-check mb-1">
                    <input class="form-check-input" type="checkbox" id="chkType" />
                    <label class="form-check-label small fw-semibold" for="chkType">Select Type</label>
                </div>
                <select class="form-select" id="cmbType" disabled="disabled">
                    <option>Broiler</option><option>Broiler(M)</option><option>Cockrel</option><option>Layer</option>
                </select>
            </div>
            <div class="col-4 col-md-2">
                <button type="button" class="btn btn-outline-primary w-100" id="btnShow"><i class="bi bi-search"></i> Show</button>
            </div>
        </div>
    </div>
</div>

<div class="row g-3">
    <div class="col-xl-8">
        <div class="card">
            <div class="card-header"><i class="bi bi-list-ul"></i> Demand (not posted) <span class="text-muted fw-normal small">- tap a row to edit</span></div>
            <div class="card-body"><div id="grid"></div></div>
        </div>
    </div>
    <div class="col-xl-4">
        <div class="card" id="formCard">
            <div class="card-header"><i class="bi bi-pencil-square"></i> Edit Demand</div>
            <div class="card-body">
                <div class="alert alert-secondary py-2 small mb-3" id="pickHint"><i class="bi bi-hand-index"></i> Select a demand row to edit it.</div>
                <input type="hidden" id="hidId" value="0" />
                <div class="row g-2">
                    <div class="col-6">
                        <label class="form-label">DM No</label>
                        <input type="text" class="form-control" id="txtDmNo" readonly="readonly" />
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="dtDm">DM Date</label>
                        <input type="date" class="form-control" id="dtDm" disabled="disabled" />
                    </div>
                    <div class="col-12">
                        <label class="form-label" for="cmbCustomer">Customer</label>
                        <select class="form-select ed" id="cmbCustomer" disabled="disabled"></select>
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="txtCode">Code</label>
                        <input type="text" class="form-control" id="txtCode" readonly="readonly" />
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="dtHatch">Hatch Date</label>
                        <input type="date" class="form-control ed" id="dtHatch" disabled="disabled" />
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="cmbChicksType">Chicks Type</label>
                        <select class="form-select ed" id="cmbChicksType" disabled="disabled">
                            <option>Broiler</option><option>Broiler(M)</option><option>Layer</option><option>Cockrel</option>
                        </select>
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="txtTotal">Total Chicks</label>
                        <input type="number" inputmode="numeric" class="form-control ed" id="txtTotal" disabled="disabled" />
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="txtRate">Rate</label>
                        <input type="number" inputmode="decimal" step="0.01" class="form-control ed" id="txtRate" disabled="disabled" />
                    </div>
                    <div class="col-12">
                        <label class="form-label" for="txtRemarks">Remarks</label>
                        <input type="text" class="form-control ed" id="txtRemarks" maxlength="250" disabled="disabled" />
                    </div>
                </div>
                <div class="btn-toolbar-app mt-3">
                    <button type="button" class="btn btn-primary ed" id="btnUpdate" disabled="disabled"><i class="bi bi-check2-square"></i> Update</button>
                    <button type="button" class="btn btn-outline-warning ed" id="btnCancelDm" disabled="disabled"><i class="bi bi-slash-circle"></i> Cancel DM</button>
                    <button type="button" class="btn btn-outline-danger ed" id="btnDelete" disabled="disabled"><i class="bi bi-trash"></i> Delete</button>
                </div>
            </div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script>
$(function () {
    var grid, current = null;

    function enableForm(on) { $('.ed').prop('disabled', !on); $('#pickHint').toggle(!on); }
    function clearForm() {
        current = null; $('#hidId').val('0');
        $('#txtDmNo, #txtCode, #txtTotal, #txtRate, #txtRemarks, #dtDm, #dtHatch').val('');
        enableForm(false); grid && grid.clearSelection();
    }

    function show() {
        var p = {
            areaName: $('#cmbArea option:selected').text(), prefix: $('#cmbArea').val(),
            fromDate: $('#dtFrom').val(), toDate: $('#dtTo').val(), chickType: $('#chkType').is(':checked') ? $('#cmbType').val() : ''
        };
        if (!p.fromDate || !p.toDate) { App.toast('Select hatch dates.', 'warning'); return; }
        clearForm();
        App.api('Show', p).then(function (d) {
            App.fillSelect('#cmbCustomer', d.customers, { value: 'account_code', text: 'account_head_name', placeholder: '-- select --' });
            grid = App.grid('#grid', d.rows, {
                exportName: 'Demand',
                columns: [
                    { key: 'DMNo', title: 'DM No' }, { key: 'DMDate', title: 'DM Date', type: 'date' },
                    { key: 'HatchDate', title: 'Hatch Date', type: 'date' }, { key: 'Code', title: 'Code' },
                    { key: 'CName', title: 'Customer' }, { key: 'Chick_type', title: 'Chicks' },
                    { key: 'DemadedChicks', title: 'Demanded', type: 'int', total: true }, { key: 'Rate', title: 'Rate', type: 'num' },
                    { key: 'Remarks', title: 'Remarks' }
                ],
                onRowClick: edit
            });
        });
    }

    function edit(r) {
        current = r;
        $('#hidId').val(App.get(r, 'id'));
        $('#txtDmNo').val(App.get(r, 'DMNo'));
        $('#dtDm').val(App.isoDate(App.get(r, 'DMDate')));
        $('#dtHatch').val(App.isoDate(App.get(r, 'HatchDate')));
        var code = String(App.get(r, 'Code') || '');
        App.setSelect('#cmbCustomer', code);
        var $o = $('#cmbCustomer option:selected');
        if ($o.text() === code) $o.text(App.get(r, 'CName'));   // head not in this area's list: keep the stored name
        $('#txtCode').val(App.get(r, 'Code'));
        App.setSelect('#cmbChicksType', App.get(r, 'Chick_type'));
        $('#txtTotal').val(App.get(r, 'DemadedChicks'));
        $('#txtRate').val(App.get(r, 'Rate'));
        $('#txtRemarks').val(App.get(r, 'Remarks'));
        enableForm(true);
        if (window.innerWidth < 1200) document.getElementById('formCard').scrollIntoView({ behavior: 'smooth' });
    }

    $('#cmbCustomer').on('change', function () { $('#txtCode').val($(this).val()); });
    $('#chkType').on('change', function () { $('#cmbType').prop('disabled', !this.checked); });
    $('#btnShow').on('click', show);

    $('#btnUpdate').on('click', function () {
        if (!current) return;
        if (!$.trim($('#txtTotal').val())) { App.toast('Please Select a DEMAND', 'warning'); return; }
        if (!$.trim($('#txtRate').val())) { App.toast('Please enter the Rate', 'warning'); return; }
        App.api('Update', {
            id: +$('#hidId').val(), hatchDate: $('#dtHatch').val(), code: $('#cmbCustomer').val(), cname: $('#cmbCustomer option:selected').text(),
            chickType: $('#cmbChicksType').val(), totalChicks: App.num($('#txtTotal').val()), rate: App.num($('#txtRate').val()), remarks: $('#txtRemarks').val()
        }).then(show);
    });
    $('#btnCancelDm').on('click', function () {
        if (!current) return;
        App.confirm('Mark DM ' + App.esc($('#txtDmNo').val()) + ' as CANCELLED BY HO?', { okText: 'Cancel DM', danger: true }).then(function (yes) {
            if (yes) App.api('CancelDemand', { id: +$('#hidId').val(), hatchDate: $('#dtHatch').val(), chickType: $('#cmbChicksType').val() }).then(show);
        });
    });
    $('#btnDelete').on('click', function () {
        if (!current) return;
        App.confirm('Delete DM ' + App.esc($('#txtDmNo').val()) + '? This cannot be undone.', { okText: 'Delete', danger: true }).then(function (yes) {
            if (yes) App.api('Delete', { id: +$('#hidId').val(), hatchDate: $('#dtHatch').val() }).then(show);
        });
    });

    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbArea', d.areas, { value: 'prefix', text: 'Areaname' });
        $('#dtFrom').val(App.today()); $('#dtTo').val(App.today());
        grid = App.grid('#grid', [], { emptyText: 'Pick an area and dates, then press Show.' });
    });
});
</script>
</asp:Content>
