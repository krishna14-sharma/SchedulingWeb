<%@ Page Language="VB" AutoEventWireup="false" CodeFile="Login.aspx.vb" Inherits="LoginPage" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#14275a" />
    <title>Scheduling Login</title>
    <link href="lib/bootstrap/css/bootstrap.min.css" rel="stylesheet" />
    <link href="lib/bootstrap-icons/bootstrap-icons.min.css" rel="stylesheet" />
    <link href="Content/site.css?v=2" rel="stylesheet" />
</head>
<body class="login-body" data-root="<%: ResolveUrl("~/") %>">
    <form id="form1" runat="server" autocomplete="on" novalidate="novalidate" class="w-100 d-flex justify-content-center">
        <div class="card login-card shadow-lg">
            <div class="card-body p-4">
                <div class="logo-wrap"><img src="Content/img/logo.jpg" alt="Phoenix" /></div>
                <h1 class="h5 text-center mb-1" style="color:#14275a">Scheduling Login</h1>
                <p class="text-center text-muted small mb-4">Phoenix Hatcheries</p>

                <div class="mb-3">
                    <label class="form-label" for="txtUser">User Name</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bi bi-person"></i></span>
                        <input type="text" class="form-control" id="txtUser" autocomplete="username" autofocus="autofocus" />
                    </div>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="txtPwd">Password</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bi bi-lock"></i></span>
                        <input type="password" class="form-control" id="txtPwd" autocomplete="current-password" />
                        <button class="btn btn-outline-secondary" type="button" id="btnEye" aria-label="Show password"><i class="bi bi-eye"></i></button>
                    </div>
                </div>
                <div class="mb-4">
                    <label class="form-label" for="cmbSession">Session</label>
                    <select class="form-select" id="cmbSession">
                        <% For Each y As String In YearOptions %>
                        <option value="<%: y %>" <%= If(y = CurrentYear, "selected", "") %>>20<%: y.Substring(0, 2) %>-<%: y.Substring(2, 2) %></option>
                        <% Next %>
                    </select>
                </div>
                <div id="loginError" class="alert alert-danger py-2 small d-none" role="alert"></div>
                <button type="button" class="btn btn-primary w-100 py-2" id="btnLogin"><i class="bi bi-box-arrow-in-right"></i> Login</button>
            </div>
        </div>
    </form>

    <div id="busy" class="busy-overlay"><div class="spinner-border text-light" role="status"></div></div>

    <script src="lib/jquery/jquery.min.js"></script>
    <script src="lib/bootstrap/js/bootstrap.bundle.min.js"></script>
    <script src="Scripts/app.js?v=1"></script>
    <script>
        $(function () {
            function showErr(m) { $('#loginError').text(m).toggleClass('d-none', !m); }
            function login() {
                var u = $.trim($('#txtUser').val()), p = $('#txtPwd').val();
                if (!u) { showErr('User Name Required'); $('#txtUser').focus(); return; }
                if (!p) { showErr('Password Required'); $('#txtPwd').focus(); return; }
                showErr('');
                App.api('Login', { userName: u, password: p, yearCode: $('#cmbSession').val(), returnUrl: new URLSearchParams(location.search).get('returnUrl') || '' },
                    { toast: false, fail: function (r) { showErr(r && r.msg); } })
                    .then(function (d) { window.location.href = d.redirect; });
            }
            // On the login page errors are shown inline instead of as toasts.
            App.toast = function (m, type) { if (type === 'danger' || type === 'warning') showErr(m); };
            $('#btnLogin').on('click', login);
            $('#txtUser, #txtPwd, #cmbSession').on('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); login(); } });
            $('#btnEye').on('click', function () {
                var $p = $('#txtPwd'), show = $p.attr('type') === 'password';
                $p.attr('type', show ? 'text' : 'password');
                $(this).find('i').toggleClass('bi-eye bi-eye-slash');
            });
        });
    </script>
</body>
</html>
