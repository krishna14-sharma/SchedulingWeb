<%@ Page Title="Area Master" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="AreaMaster.aspx.vb" Inherits="AreaMasterPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="row g-3">
    <div class="col-lg-4">
        <div class="card" id="formCard">
            <div class="card-header"><i class="bi bi-geo-alt"></i> Area details</div>
            <div class="card-body">
                <div class="alert alert-warning py-2 small align-items-center gap-2 edit-banner"><i class="bi bi-pencil"></i> Editing area ID <strong class="edit-label"></strong></div>
                <input type="hidden" id="hidId" value="0" />
                <div class="mb-3">
                    <label class="form-label" for="txtAreaCode">Area Code</label>
                    <input type="text" class="form-control text-uppercase" id="txtAreaCode" maxlength="10" />
                </div>
                <div class="mb-3">
                    <label class="form-label" for="txtAreaName">Area Name</label>
                    <input type="text" class="form-control text-uppercase" id="txtAreaName" maxlength="100" />
                </div>
                <div class="mb-3">
                    <label class="form-label" for="cmbState">State</label>
                    <select class="form-select" id="cmbState"></select>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="txtBranch">Branch</label>
                    <input type="text" class="form-control text-uppercase" id="txtBranch" maxlength="100" />
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
            <div class="card-header"><i class="bi bi-list-ul"></i> Areas <span class="text-muted fw-normal small">- tap a row to edit</span></div>
            <div class="card-body"><div id="grid"></div></div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script>
$(function () {
    var STATES = ["Andaman & Nicobar", "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chandigarh", "Chhattisgarh", "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jammu and Kashmir", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "New Delhi", "Orissa", "Puducherry", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal", "Dadra and Nagar Haveli", "Daman and Diu", "Lakshadweep"];
    App.fillSelect('#cmbState', STATES.map(function (s) { return { v: s.toUpperCase(), t: s }; }), { value: 'v', text: 't' });
    var grid;

    function load() {
        App.api('List').then(function (rows) {
            grid = App.grid('#grid', rows, {
                exportName: 'Areas',
                columns: [
                    { key: 'Areaname', title: 'Area Name' }, { key: 'prefix', title: 'Code' },
                    { key: 'state', title: 'State' }, { key: 'branch', title: 'Branch' }, { key: 'id', title: 'ID', type: 'int' }
                ],
                onRowClick: edit
            });
        });
    }

    function edit(r) {
        $('#hidId').val(App.get(r, 'id'));
        $('#txtAreaCode').val(App.get(r, 'prefix'));
        $('#txtAreaName').val(App.get(r, 'Areaname'));
        $('#txtBranch').val(App.get(r, 'branch'));
        App.setSelect('#cmbState', String(App.get(r, 'state') || '').toUpperCase());
        $('#btnSave').prop('disabled', true);
        $('#btnUpdate, #btnDelete').prop('disabled', false);
        App.editMode('#formCard', true, App.get(r, 'id'));
        if (window.innerWidth < 992) document.getElementById('formCard').scrollIntoView({ behavior: 'smooth' });
    }

    function clearAll() {
        $('#hidId').val('0'); $('#txtAreaCode, #txtAreaName, #txtBranch').val('');
        $('#cmbState').prop('selectedIndex', 0);
        $('#btnSave').prop('disabled', false); $('#btnUpdate, #btnDelete').prop('disabled', true);
        App.editMode('#formCard', false); grid && grid.clearSelection();
        $('#txtAreaName').focus();
    }

    function payload() {
        return { id: +$('#hidId').val(), code: $.trim($('#txtAreaCode').val()), name: $.trim($('#txtAreaName').val()),
                 state: $('#cmbState').val(), branch: $.trim($('#txtBranch').val()) };
    }
    function valid(p) {
        if (!p.code) { App.toast('Enter Area Code', 'warning'); $('#txtAreaCode').focus(); return false; }
        if (!p.name) { App.toast('Enter Area Name', 'warning'); $('#txtAreaName').focus(); return false; }
        if (!p.state) { App.toast('Select State', 'warning'); return false; }
        if (!p.branch) { App.toast('Enter Branch', 'warning'); $('#txtBranch').focus(); return false; }
        return true;
    }

    $('#btnSave').on('click', function () {
        var p = payload(); p.id = 0; if (!valid(p)) return;
        App.api('Save', p).then(function () { clearAll(); load(); });
    });
    $('#btnUpdate').on('click', function () {
        var p = payload(); if (!p.id || !valid(p)) return;
        App.api('Save', p).then(function () { clearAll(); load(); });
    });
    $('#btnDelete').on('click', function () {
        var id = +$('#hidId').val(); if (!id) return;
        App.confirm('Delete this area?', { okText: 'Delete', danger: true }).then(function (yes) {
            if (yes) App.api('Delete', { id: id }).then(function () { clearAll(); load(); });
        });
    });
    $('#btnClear').on('click', clearAll);
    load();
});
</script>
</asp:Content>
