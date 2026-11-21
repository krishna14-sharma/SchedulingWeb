/* Phoenix Scheduling - shared client helpers.
 * All server calls go through App.api(), which posts JSON to the page's [WebMethod] functions
 * (Page.aspx/MethodName), so screens update without a full page reload. */
(function ($) {
    'use strict';

    var App = window.App = {};
    App.root = (document.body.getAttribute('data-root') || '/');

    // ------------------------------------------------------------------ basics
    App.esc = function (s) {
        if (s === null || s === undefined) return '';
        return String(s).replace(/[&<>"']/g, function (c) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
        });
    };

    /** Case-insensitive field read (DB column casing varies: Hatch_DAte, hatch_date ...). */
    App.get = function (row, key) {
        if (!row) return undefined;
        if (Object.prototype.hasOwnProperty.call(row, key)) return row[key];
        var lk = String(key).toLowerCase();
        for (var k in row) { if (Object.prototype.hasOwnProperty.call(row, k) && k.toLowerCase() === lk) return row[k]; }
        return undefined;
    };

    /** Same idea as VB Val(): leading number, otherwise 0. */
    App.num = function (v) {
        if (v === null || v === undefined || v === '') return 0;
        if (typeof v === 'number') return isFinite(v) ? v : 0;
        var n = parseFloat(String(v).replace(/,/g, ''));
        return isNaN(n) ? 0 : n;
    };

    /** Math.Round(x, 0) in .NET uses banker's rounding (0.5 -> 0, 1.5 -> 2, 2.5 -> 2). */
    App.bround = function (x) {
        var f = Math.floor(x), diff = x - f;
        if (Math.abs(diff - 0.5) < 1e-9) return (f % 2 === 0) ? f : f + 1;
        return Math.round(x);
    };

    /** Free chicks % used by the scheduling screens. */
    App.freePercent = function (chickType) {
        switch (chickType) {
            case 'Broiler': case 'Broiler(M)': case 'Broiler(M )': return 2;
            case 'Layer': return 5;
            default: return 0;
        }
    };

    var MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    function pad(n) { return (n < 10 ? '0' : '') + n; }

    App.toIso = function (d) { return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()); };
    App.today = function () { return App.toIso(new Date()); };
    App.addDays = function (iso, n) {
        var p = String(iso).split('-'); var d = new Date(+p[0], +p[1] - 1, +p[2]); d.setDate(d.getDate() + n); return App.toIso(d);
    };
    App.firstOfMonth = function () { var d = new Date(); return App.toIso(new Date(d.getFullYear(), d.getMonth(), 1)); };

    /** "2026-11-12" or "2026-11-12T10:20:00" -> "12/Nov/2026" (the format the WinForms date pickers used). */
    App.fmtDate = function (v) {
        if (!v) return '';
        var m = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(v));
        if (!m) return String(v);
        return m[3] + '/' + MONTHS[+m[2] - 1] + '/' + m[1];
    };
    App.isoDate = function (v) { var m = /^(\d{4}-\d{2}-\d{2})/.exec(String(v || '')); return m ? m[1] : ''; };

    App.fmtNum = function (v, dec) {
        if (v === null || v === undefined || v === '') return '';
        var n = Number(v);
        if (isNaN(n)) return App.esc(v);
        dec = (dec === undefined) ? 0 : dec;
        return n.toLocaleString('en-IN', { minimumFractionDigits: dec, maximumFractionDigits: dec });
    };

    // ------------------------------------------------------------------ busy + toast + confirm
    var busyCount = 0;
    App.busy = function (on) {
        busyCount = Math.max(0, busyCount + (on ? 1 : -1));
        document.getElementById('busy') && document.getElementById('busy').classList.toggle('show', busyCount > 0);
    };

    App.toast = function (msg, type) {
        type = type || 'info';
        var icon = { success: 'check-circle-fill', danger: 'exclamation-octagon-fill', warning: 'exclamation-triangle-fill', info: 'info-circle-fill' }[type] || 'info-circle-fill';
        var $t = $('<div class="toast align-items-center border-0 text-bg-' + type + '" role="alert" aria-live="assertive" aria-atomic="true">' +
            '<div class="d-flex"><div class="toast-body"><i class="bi bi-' + icon + ' me-2"></i>' + App.esc(msg) + '</div>' +
            '<button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button></div></div>');
        var area = $('#toastArea');
        if (!area.length) { alert(msg); return; }
        area.append($t);
        var t = new bootstrap.Toast($t[0], { delay: type === 'danger' ? 7000 : 3500 });
        $t.on('hidden.bs.toast', function () { $t.remove(); });
        t.show();
    };

    /** Promise<boolean> - replaces MessageBox.Show("Are U sure", ..., YesNo). */
    App.confirm = function (message, opts) {
        opts = opts || {};
        return new Promise(function (resolve) {
            var el = document.getElementById('confirmModal');
            if (!el) { resolve(window.confirm(message)); return; }
            $('#confirmTitle').text(opts.title || 'Confirmation');
            $('#confirmBody').html(opts.html ? message : App.esc(message));
            var $ok = $('#confirmOk').text(opts.okText || 'Yes')
                .removeClass('btn-primary btn-danger').addClass(opts.danger ? 'btn-danger' : 'btn-primary');
            var modal = bootstrap.Modal.getOrCreateInstance(el);
            var answered = false;
            $ok.off('click').on('click', function () { answered = true; modal.hide(); });
            $(el).off('hidden.bs.modal').on('hidden.bs.modal', function () { resolve(answered); });
            modal.show();
        });
    };

    // ------------------------------------------------------------------ AJAX
    /**
     * Calls a [WebMethod] on the current page (or opts.page).
     * Resolves with result.data when ok; on failure shows a toast and calls opts.fail (the promise stays pending).
     */
    App.api = function (method, data, opts) {
        opts = opts || {};
        var url = (opts.page || window.location.pathname) + '/' + method;
        if (!opts.silent) App.busy(true);
        return new Promise(function (resolve) {
            $.ajax({
                url: url, type: 'POST', dataType: 'json',
                contentType: 'application/json; charset=utf-8',
                data: JSON.stringify(data || {})
            }).done(function (r) {
                var res = (r && r.d !== undefined) ? r.d : r;
                if (res && res.ok) {
                    if (res.msg && opts.toast !== false) App.toast(res.msg, 'success');
                    resolve(res.data);
                } else if (res && res.data === 'LOGIN') {
                    App.toast(res.msg, 'warning');
                    setTimeout(function () { window.location.href = App.root + 'Login.aspx?returnUrl=' + encodeURIComponent(location.pathname); }, 1200);
                } else {
                    App.toast((res && res.msg) || 'Request failed.', 'danger');
                    if (opts.fail) opts.fail(res);
                }
            }).fail(function (xhr) {
                var m = 'Server error (' + xhr.status + ').';
                if (xhr.responseJSON && xhr.responseJSON.Message) m = xhr.responseJSON.Message;
                if (xhr.status === 0) m = 'Cannot reach the server. Check your connection.';
                App.toast(m, 'danger');
                if (opts.fail) opts.fail({ ok: false, msg: m });
            }).always(function () { if (!opts.silent) App.busy(false); });
        });
    };

    // ------------------------------------------------------------------ form helpers
    /** Fills a <select>. items: array of strings or objects; opts: {value, text, placeholder, selected, data:{attr:key}} */
    App.fillSelect = function (sel, items, opts) {
        opts = opts || {};
        var $s = $(sel), html = '';
        if (opts.placeholder !== undefined) html += '<option value="">' + App.esc(opts.placeholder) + '</option>';
        (items || []).forEach(function (it) {
            var v, t, extra = '';
            if (typeof it === 'object' && it !== null) {
                v = App.get(it, opts.value); t = opts.text ? App.get(it, opts.text) : v;
                if (opts.data) { for (var a in opts.data) { extra += ' data-' + a + '="' + App.esc(App.get(it, opts.data[a])) + '"'; } }
            } else { v = it; t = it; }
            html += '<option value="' + App.esc(v) + '"' + extra + '>' + App.esc(t) + '</option>';
        });
        $s.html(html);
        if (opts.selected !== undefined && opts.selected !== null) $s.val(opts.selected);
        return $s;
    };

    /** Selects an option by value, adding it if missing (like setting ComboBox.Text). */
    App.setSelect = function (sel, value) {
        var $s = $(sel);
        if (value === null || value === undefined) value = '';
        var exists = $s.find('option').filter(function () { return this.value === String(value); }).length > 0;
        if (!exists && value !== '') $s.append('<option value="' + App.esc(value) + '">' + App.esc(value) + '</option>');
        $s.val(String(value));
        return $s;
    };

    /** Shows the "editing" banner state on a form card. */
    App.editMode = function (card, on, label) {
        var $c = $(card);
        $c.toggleClass('is-editing', !!on);
        if (label !== undefined) $c.find('.edit-label').text(label);
    };

    // ------------------------------------------------------------------ grid
    function cellText(col, row) {
        var v = App.get(row, col.key);
        switch (col.type) {
            case 'date': return App.fmtDate(v);
            case 'int': return (v === null || v === undefined || v === '') ? '' : App.fmtNum(v, 0);
            case 'num': return (v === null || v === undefined || v === '') ? '' : App.fmtNum(v, col.dec === undefined ? 2 : col.dec);
            case 'bool': return (v === true || v === 1 || v === '1' || v === 'True') ? 'Yes' : 'No';
            default: return (v === null || v === undefined) ? '' : String(v);
        }
    }

    function deriveColumns(rows) {
        if (!rows || !rows.length) return [];
        return Object.keys(rows[0]).map(function (k) {
            var sample = null;
            for (var i = 0; i < rows.length && i < 20; i++) { var x = rows[i][k]; if (x !== null && x !== undefined && x !== '') { sample = x; break; } }
            var type = 'text';
            if (typeof sample === 'number') type = (Math.round(sample) === sample) ? 'int' : 'num';
            else if (typeof sample === 'string' && /^\d{4}-\d{2}-\d{2}(T|$)/.test(sample)) type = 'date';
            return { key: k, title: k, type: type };
        });
    }

    function isNumType(t) { return t === 'num' || t === 'int'; }

    /**
     * Read-only data grid.
     * opts: columns [{key,title,type:'text|int|num|date|bool', dec, total:true|'avg'|fn(rows), render:fn(row), cls}],
     *       onRowClick(row), checkbox (bool), search (bool, default true), stack (phones: rows as cards, default true),
     *       exportName, emptyText, groupBy (key), noMax (no height limit)
     */
    App.grid = function (container, rows, opts) {
        opts = opts || {};
        var $c = $(container).empty();
        var cols = opts.columns || deriveColumns(rows);
        var state = { all: rows || [], view: rows || [], selectedRow: null };

        var $tools = $('<div class="grid-tools"></div>');
        var $search = $('<input type="search" class="form-control form-control-sm grid-search" placeholder="Search...">');
        var $count = $('<span class="badge text-bg-light border"></span>');
        if (opts.search !== false) $tools.append($search);
        $tools.append($count);
        if (opts.checkbox) {
            var $selInfo = $('<span class="small text-muted"></span>');
            $tools.append($selInfo);
        }
        if (opts.exportName) {
            $tools.append($('<button type="button" class="btn btn-sm btn-outline-success ms-auto"><i class="bi bi-file-earmark-spreadsheet"></i> Excel</button>')
                .on('click', function () { App.exportCsv(opts.exportName, state.view, cols); }));
        }
        var $wrap = $('<div class="grid-wrap"></div>').toggleClass('stack-sm', opts.stack !== false).toggleClass('no-max', !!opts.noMax);
        var $table = $('<table class="table table-sm table-hover table-app"></table>');
        $wrap.append($table);
        $c.append($tools, $wrap);

        function totalsFor(list) {
            var out = {};
            cols.forEach(function (col) {
                if (!col.total) return;
                if (typeof col.total === 'function') { out[col.key] = col.total(list); return; }
                var s = 0; list.forEach(function (r) { s += App.num(App.get(r, col.key)); });
                out[col.key] = (col.total === 'avg') ? (list.length ? s / list.length : 0) : s;
            });
            return out;
        }

        function rowHtml(r, idx) {
            var h = '<tr data-i="' + idx + '"' + (opts.onRowClick ? ' class="row-click"' : '') + '>';
            if (opts.checkbox) h += '<td class="chk"><input type="checkbox" class="form-check-input row-chk"' + (r.__checked ? ' checked' : '') + ' aria-label="Select row"></td>';
            cols.forEach(function (col) {
                var content = col.render ? col.render(r) : App.esc(cellText(col, r));
                var cls = (isNumType(col.type) ? 'num ' : '') + (col.cls || '');
                h += '<td class="' + cls + '" data-label="' + App.esc(col.title || col.key) + '">' + content + '</td>';
            });
            return h + '</tr>';
        }

        function footHtml(list) {
            if (!cols.some(function (c) { return c.total; }) || !list.length) return '';
            var t = totalsFor(list);
            var h = '<tfoot><tr>' + (opts.checkbox ? '<td></td>' : '');
            var labelDone = false;
            cols.forEach(function (col) {
                if (col.total) {
                    h += '<td class="num" data-label="' + App.esc(col.title || col.key) + '">' + App.fmtNum(t[col.key], col.type === 'int' ? 0 : (col.dec === undefined ? 2 : col.dec)) + '</td>';
                } else if (!labelDone) { h += '<td>Total</td>'; labelDone = true; }
                else h += '<td></td>';
            });
            return h + '</tr></tfoot>';
        }

        function render() {
            var q = ($search.val() || '').toLowerCase().trim();
            state.view = !q ? state.all : state.all.filter(function (r) {
                return cols.some(function (col) { return cellText(col, r).toLowerCase().indexOf(q) >= 0; });
            });
            var head = '<thead><tr>' + (opts.checkbox ? '<th class="chk"><input type="checkbox" class="form-check-input chk-all" aria-label="Select all"></th>' : '');
            cols.forEach(function (col) { head += '<th class="' + (isNumType(col.type) ? 'num' : '') + '">' + App.esc(col.title || col.key) + '</th>'; });
            head += '</tr></thead>';

            var body = '<tbody>';
            if (!state.view.length) {
                body += '<tr><td colspan="' + (cols.length + (opts.checkbox ? 1 : 0)) + '"><div class="empty-state"><i class="bi bi-inbox"></i>' + App.esc(opts.emptyText || 'No records found.') + '</div></td></tr>';
            } else if (opts.groupBy) {
                var groups = {}, order = [];
                state.view.forEach(function (r) { var g = String(App.get(r, opts.groupBy) || '(blank)'); if (!groups[g]) { groups[g] = []; order.push(g); } groups[g].push(r); });
                order.forEach(function (g) {
                    body += '<tr class="group-row"><td colspan="' + (cols.length + (opts.checkbox ? 1 : 0)) + '">' + App.esc(g) + '</td></tr>';
                    groups[g].forEach(function (r) { body += rowHtml(r, state.all.indexOf(r)); });
                    var t = totalsFor(groups[g]);
                    if (Object.keys(t).length) {
                        body += '<tr class="subtotal-row">' + (opts.checkbox ? '<td></td>' : '');
                        var lbl = false;
                        cols.forEach(function (col) {
                            if (col.total) body += '<td class="num" data-label="' + App.esc(col.title) + '">' + App.fmtNum(t[col.key], col.type === 'int' ? 0 : (col.dec === undefined ? 2 : col.dec)) + '</td>';
                            else if (!lbl) { body += '<td class="text-muted">Sub total</td>'; lbl = true; } else body += '<td></td>';
                        });
                        body += '</tr>';
                    }
                });
            } else {
                state.view.forEach(function (r) { body += rowHtml(r, state.all.indexOf(r)); });
            }
            body += '</tbody>';
            $table.html(head + body + footHtml(state.view));
            $count.text(state.view.length + (state.view.length === 1 ? ' record' : ' records'));
            updateSel();
        }

        function updateSel() {
            if (!opts.checkbox) return;
            var n = state.all.filter(function (r) { return r.__checked; }).length;
            $selInfo.text(n ? n + ' selected' : '');
            var allChecked = state.view.length > 0 && state.view.every(function (r) { return r.__checked; });
            $table.find('.chk-all').prop('checked', allChecked);
        }

        $search.on('input', render);
        $table.on('click', 'tbody tr[data-i]', function (e) {
            var r = state.all[+$(this).attr('data-i')];
            if ($(e.target).is('.row-chk')) { r.__checked = e.target.checked; updateSel(); return; }
            if ($(e.target).closest('td.chk').length) return;
            if (opts.onRowClick) {
                $table.find('tr.selected').removeClass('selected');
                $(this).addClass('selected');
                state.selectedRow = r;
                opts.onRowClick(r);
            }
        });
        $table.on('change', '.chk-all', function () {
            var on = this.checked;
            state.view.forEach(function (r) { r.__checked = on; });
            $table.find('.row-chk').prop('checked', on);
            updateSel();
        });

        render();
        return {
            rows: function () { return state.all; },
            visibleRows: function () { return state.view; },
            checked: function () { return state.all.filter(function (r) { return r.__checked; }); },
            clearSelection: function () { state.selectedRow = null; $table.find('tr.selected').removeClass('selected'); },
            refresh: function (newRows) { state.all = newRows || []; render(); }
        };
    };


    // ------------------------------------------------------------------ printable report
    /**
     * Renders a printable report (replaces the Crystal Reports viewer).
     * opts: title, lines [string], columns, rows, groupBy, exportName, emptyText
     */
    App.report = function (container, opts) {
        var $c = $(container).empty();
        var $sheet = $('<div class="report-sheet"></div>');
        var head = '<div class="report-head"><div class="r-company">PHOENIX HATCHERIES</div><div class="r-title">' + App.esc(opts.title || '') + '</div>';
        (opts.lines || []).forEach(function (l) { if (l) head += '<div class="r-sub">' + App.esc(l) + '</div>'; });
        head += '</div>';
        var $bar = $('<div class="d-flex flex-wrap gap-2 justify-content-end mb-2 no-print"></div>');
        $bar.append($('<button type="button" class="btn btn-sm btn-outline-secondary"><i class="bi bi-printer"></i> Print / PDF</button>').on('click', function () { window.print(); }));
        var $gridHost = $('<div></div>');
        $sheet.append($bar, $(head), $gridHost);
        $c.append($sheet);
        // Wide reports print landscape so every column fits on A4.
        var landscape = opts.landscape !== undefined ? opts.landscape : ((opts.columns || []).length > 9);
        var $ps = $('#reportPageSize');
        if (!$ps.length) $ps = $('<style id="reportPageSize"></style>').appendTo('head');
        $ps.text('@media print { @page { size: A4 ' + (landscape ? 'landscape' : 'portrait') + '; } }');
        return App.grid($gridHost, opts.rows, {
            columns: opts.columns, groupBy: opts.groupBy, exportName: opts.exportName, stack: opts.stack,
            emptyText: opts.emptyText || 'No records found.', noMax: true, checkbox: opts.checkbox, onRowClick: opts.onRowClick
        });
    };

    // ------------------------------------------------------------------ export
    /** Downloads rows as a CSV file that opens directly in Excel. */
    App.exportCsv = function (name, rows, cols) {
        cols = cols || deriveColumns(rows);
        function q(v) { v = (v === null || v === undefined) ? '' : String(v); return /[",\n\r]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v; }
        var lines = [cols.map(function (c) { return q(c.title || c.key); }).join(',')];
        (rows || []).forEach(function (r) {
            lines.push(cols.map(function (c) {
                var v = App.get(r, c.key);
                if (c.type === 'date') v = App.fmtDate(v);
                return q(v);
            }).join(','));
        });
        var blob = new Blob(['\ufeff' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8' });
        var a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = String(name).replace(/[^\w\-]+/g, '_') + '_' + App.today() + '.csv';
        document.body.appendChild(a); a.click();
        setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 500);
    };

    // ------------------------------------------------------------------ page setup
    $(function () {
        // Pages are AJAX driven - never let Enter or a button post the whole form back.
        $('#form1').on('submit', function (e) { e.preventDefault(); return false; });

        // Highlight the current menu entry.
        var path = window.location.pathname.toLowerCase();
        $('.app-nav .navbar-nav > .nav-item > a.nav-link:not(.dropdown-toggle)').each(function () {
            if (new URL(this.getAttribute('href'), window.location.href).pathname.toLowerCase() === path) $(this).addClass('active');
        });
        $('.app-nav .dropdown-item').each(function () {
            var href = this.getAttribute('href');
            if (!href || href === '#' || this.target === '_blank') return;
            if (new URL(href, window.location.href).pathname.toLowerCase() === path) {
                $(this).addClass('active');
                $(this).closest('.dropdown').find('> .nav-link').addClass('active');
            }
        });

        // Enter in a filter box triggers that card's primary button.
        $(document).on('keydown', '[data-enter-click] input, [data-enter-click] select', function (e) {
            if (e.key === 'Enter') { e.preventDefault(); $($(this).closest('[data-enter-click]').attr('data-enter-click')).trigger('click'); }
        });
    });

})(jQuery);
