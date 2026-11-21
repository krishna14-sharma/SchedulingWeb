<%@ Page Title="Hatchery Master" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="HatcheryMaster.aspx.vb" Inherits="HatcheryMasterPage" %>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="row g-3">
    <div class="col-lg-4">
        <div class="card">
            <div class="card-header"><i class="bi bi-building"></i> New Hatchery</div>
            <div class="card-body" data-enter-click="#btnSave">
                <div class="mb-3">
                    <label class="form-label" for="txtName">Hatchery Name</label>
                    <input type="text" class="form-control text-uppercase" id="txtName" maxlength="100" />
                </div>
                <button type="button" class="btn btn-primary" id="btnSave"><i class="bi bi-save"></i> Save</button>
            </div>
        </div>
    </div>
    <div class="col-lg-8">
        <div class="card">
            <div class="card-header"><i class="bi bi-list-ul"></i> Hatcheries</div>
            <div class="card-body"><div id="grid"></div></div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script>
$(function () {
    function load() {
        App.api('List').then(function (rows) {
            App.grid('#grid', rows, { exportName: 'Hatcheries', columns: [{ key: 'Hatcheryies', title: 'Hatchery' }, { key: 'ID', title: 'ID', type: 'int' }] });
        });
    }
    $('#btnSave').on('click', function () {
        var n = $.trim($('#txtName').val());
        if (!n) { App.toast('Enter Hatchery Name', 'warning'); $('#txtName').focus(); return; }
        App.api('Save', { name: n }).then(function () { $('#txtName').val('').focus(); load(); });
    });
    load();
});
</script>
</asp:Content>
