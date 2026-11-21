<%@ Page Title="Head Creation" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="HeadCreation.aspx.vb" Inherits="HeadCreationPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="row g-3">
    <div class="col-lg-4">
        <div class="card" id="formCard">
            <div class="card-header"><i class="bi bi-person-plus"></i> Account head</div>
            <div class="card-body">
                <div class="alert alert-warning py-2 small align-items-center gap-2 edit-banner"><i class="bi bi-pencil"></i> Editing <strong class="edit-label"></strong> - only the name can be changed</div>
                <div class="row g-2">
                    <div class="col-8">
                        <label class="form-label" for="cmbArea">Area Name</label>
                        <select class="form-select" id="cmbArea"></select>
                    </div>
                    <div class="col-4">
                        <label class="form-label" for="txtAreaCode">Area Code</label>
                        <input type="text" class="form-control" id="txtAreaCode" readonly="readonly" />
                    </div>
                    <div class="col-8">
                        <label class="form-label" for="cmbGroup">Type</label>
                        <select class="form-select" id="cmbGroup">
                            <option value="AREA MANAGER" data-code="AG">AREA MANAGER</option>
                            <option value="DEALER" data-code="DL">DEALER</option>
                            <option value="CUSTOMER" data-code="CU">CUSTOMER</option>
                        </select>
                    </div>
                    <div class="col-4">
                        <label class="form-label" for="txtGrpCode">Type Code</label>
                        <input type="text" class="form-control" id="txtGrpCode" readonly="readonly" />
                    </div>
                    <div class="col-12">
                        <label class="form-label" for="txtCode">Code</label>
                        <input type="text" class="form-control fw-semibold" id="txtCode" readonly="readonly" />
                    </div>
                    <div class="col-12">
                        <label class="form-label" for="txtName">Name</label>
                        <input type="text" class="form-control text-uppercase" id="txtName" maxlength="150" />
                    </div>
                    <div class="col-12">
                        <label class="form-label" for="txtAddress">Address</label>
                        <textarea class="form-control text-uppercase lock-edit" id="txtAddress" rows="2" maxlength="250"></textarea>
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="txtState">State</label>
                        <input type="text" class="form-control text-uppercase lock-edit" id="txtState" maxlength="50" />
                    </div>
                    <div class="col-6">
                        <label class="form-label" for="txtPhone">Phone</label>
                        <input type="tel" class="form-control lock-edit" id="txtPhone" maxlength="30" />
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
    <div class="col-lg-8">
        <div class="card">
            <div class="card-header"><i class="bi bi-list-ul"></i> Heads <span class="text-muted fw-normal small">- tap a row to edit</span></div>
            <div class="card-body"><div id="grid"></div></div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script>
$(function () {
    var grid, editing = false;

    function syncArea() {
        var $o = $('#cmbArea option:selected');
        $('#txtAreaCode').val($o.attr('data-prefix') || '');
        if (!editing) $('#txtState').val($o.attr('data-state') || '');
    }
    function syncGroup() { $('#txtGrpCode').val($('#cmbGroup option:selected').attr('data-code')); }

    function nextCode() {
        if (editing) return;
        App.api('NextCode', { areaCode: $('#txtAreaCode').val(), groupName: $('#cmbGroup').val(), groupCode: $('#txtGrpCode').val() }, { silent: true })
            .then(function (c) { $('#txtCode').val(c); });
    }

    function loadGrid() {
        App.api('List').then(function (rows) {
            grid = App.grid('#grid', rows, {
                exportName: 'AccountHeads',
                columns: [
                    { key: 'account_code', title: 'Code' }, { key: 'account_head_name', title: 'Name' },
                    { key: 'group_name', title: 'Type' }, { key: 'address', title: 'Address' },
                    { key: 'city', title: 'City' }, { key: 'state', title: 'State' }, { key: 'phone', title: 'Phone' },
                    { key: 'Area_code', title: 'Area' }
                ],
                onRowClick: edit
            });
        });
    }

    function edit(r) {
        editing = true;
        $('#txtCode').val(App.get(r, 'account_code'));
        $('#txtName').val(App.get(r, 'account_head_name'));
        $('#txtAddress').val(App.get(r, 'address'));
        $('#txtPhone').val(App.get(r, 'phone'));
        $('#txtState').val(App.get(r, 'state'));
        $('.lock-edit, #cmbArea, #cmbGroup').prop('disabled', true);
        $('#btnSave').prop('disabled', true); $('#btnUpdate, #btnDelete').prop('disabled', false);
        App.editMode('#formCard', true, App.get(r, 'account_code'));
        if (window.innerWidth < 992) document.getElementById('formCard').scrollIntoView({ behavior: 'smooth' });
    }

    function clearAll() {
        editing = false;
        $('#txtName, #txtAddress, #txtPhone').val('');
        $('.lock-edit, #cmbArea, #cmbGroup').prop('disabled', false);
        $('#btnSave').prop('disabled', false); $('#btnUpdate, #btnDelete').prop('disabled', true);
        App.editMode('#formCard', false); grid && grid.clearSelection();
        syncArea(); nextCode();
    }

    $('#cmbArea').on('change', function () { syncArea(); nextCode(); });
    $('#cmbGroup').on('change', function () { syncGroup(); nextCode(); });

    $('#btnSave').on('click', function () {
        var p = {
            areaCode: $('#txtAreaCode').val(), areaName: $('#cmbArea option:selected').text(),
            groupName: $('#cmbGroup').val(), groupCode: $('#txtGrpCode').val(),
            name: $.trim($('#txtName').val()), address: $.trim($('#txtAddress').val()),
            state: $.trim($('#txtState').val()), phone: $.trim($('#txtPhone').val())
        };
        if (!p.name) { App.toast('Please Enter Name', 'warning'); $('#txtName').focus(); return; }
        App.confirm('Save head "' + p.name.toUpperCase() + '"?').then(function (yes) {
            if (yes) App.api('Save', p).then(function () { clearAll(); loadGrid(); });
        });
    });
    $('#btnUpdate').on('click', function () {
        var name = $.trim($('#txtName').val());
        if (!name) { App.toast('Please Enter Name', 'warning'); return; }
        App.api('UpdateName', { code: $('#txtCode').val(), name: name }).then(function () { clearAll(); loadGrid(); });
    });
    $('#btnDelete').on('click', function () {
        var code = $('#txtCode').val();
        App.confirm('Delete head ' + code + '?', { okText: 'Delete', danger: true }).then(function (yes) {
            if (yes) App.api('Delete', { code: code }).then(function () { clearAll(); loadGrid(); });
        });
    });
    $('#btnClear').on('click', clearAll);

    App.api('Setup').then(function (d) {
        App.fillSelect('#cmbArea', d.areas, { value: 'prefix', text: 'AreaName', data: { prefix: 'prefix', state: 'State' } });
        syncArea(); syncGroup(); nextCode(); loadGrid();
    });
});
</script>
</asp:Content>
