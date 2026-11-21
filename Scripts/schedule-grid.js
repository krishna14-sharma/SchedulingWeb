/* Editable scheduling grid shared by Demand Scheduling and Edit Scheduling
 * (replaces the editable DataGridView "dgsch" of frmShedulingByDemand / frmShedulingByDemand_Edit). */
(function ($) {
    'use strict';

    /**
     * opts: mode 'new' | 'edit', hatcheries [string], chickType: fn() -> string, onTotals: fn({demand, schedule, free})
     */
    App.scheduleGrid = function (container, opts) {
        var $c = $(container), rows = [];
        var isNew = opts.mode === 'new';

        var cols = [
            { k: 'code', t: 'Code', ro: true },
            { k: 'name', t: 'Name', ro: true },
            { k: 'demandQty', t: 'Demand Qty', ro: true, num: true, dec: 0 },
            { k: 'rate', t: 'Rate', ro: true, num: true, dec: 2 },
            { k: 'scheduleQty', t: 'Schedule Qty', num: true, step: 1 },
            { k: 'free', t: 'Free Chicks', num: true, step: 1 },
            { k: 'scheduleRate', t: 'Schedule Rate', num: true, step: 0.01 },
            { k: 'circularRate', t: 'Circular Rate', num: true, step: 0.01 },
            { k: 'hatchery', t: 'Hatchery', select: true }
        ];
        if (isNew) {
            cols.push({ k: 'compRate', t: 'Comp. Rate', num: true, step: 0.01 });
            cols.push({ k: 'dr', t: 'DR', ro: true, num: true, dec: 2 });
            cols.push({ k: 'cr', t: 'CR', ro: true, num: true, dec: 2 });
        } else {
            cols.push({ k: 'isEdit', t: 'Status', status: true });
        }

        function hatchSelect(val) {
            var h = '<select class="form-select form-select-sm" data-k="hatchery"><option value="">--</option>';
            var list = opts.hatcheries.slice();
            if (val && list.indexOf(val) < 0) list.push(val);
            list.forEach(function (x) { h += '<option' + (x === val ? ' selected' : '') + ' value="' + App.esc(x) + '">' + App.esc(x) + '</option>'; });
            return h + '</select>';
        }

        function render() {
            if (!rows.length) {
                $c.html('<div class="empty-state"><i class="bi bi-calendar-x"></i>Pick the area, hatch date and chick type, then press Show.</div>');
                totals(); return;
            }
            var h = '<div class="grid-wrap stack-sm"><table class="table table-sm table-app"><thead><tr><th>#</th>';
            cols.forEach(function (c) { h += '<th class="' + (c.num ? 'num' : '') + '">' + c.t + '</th>'; });
            h += '</tr></thead><tbody>';
            rows.forEach(function (r, i) {
                h += '<tr data-i="' + i + '"><td data-label="#" class="text-muted">' + (i + 1) + '</td>';
                cols.forEach(function (c) {
                    var v = r[c.k];
                    h += '<td data-label="' + c.t + '" class="' + (c.num && c.ro ? 'num' : '') + '">';
                    if (c.status) h += '<span class="badge ' + (r.isEdit == 1 ? 'text-bg-warning' : 'text-bg-light border') + '">' + (r.isEdit == 1 ? 'Edited' : '-') + '</span>';
                    else if (c.select) h += hatchSelect(v || '');
                    else if (c.ro) h += c.num ? App.fmtNum(v, c.dec) : App.esc(v);
                    else h += '<input type="number" inputmode="decimal" class="form-control form-control-sm text-end" data-k="' + c.k + '" step="' + c.step + '" value="' + (v === null || v === undefined ? '' : App.esc(v)) + '">';
                    h += '</td>';
                });
                h += '</tr>';
            });
            h += '</tbody></table></div>';
            $c.html(h);
            totals();
        }

        function totals() {
            var t = { demand: 0, schedule: 0, free: 0 };
            rows.forEach(function (r) { t.demand += App.num(r.demandQty); t.schedule += App.num(r.scheduleQty); t.free += App.num(r.free); });
            if (opts.onTotals) opts.onTotals(t);
        }

        $c.on('input change', '[data-k]', function () {
            var $tr = $(this).closest('tr'), r = rows[+$tr.attr('data-i')], k = $(this).attr('data-k');
            r[k] = (k === 'hatchery') ? $(this).val() : ($(this).val() === '' ? null : App.num($(this).val()));
            if (k === 'scheduleQty') {
                r.free = App.bround(App.num(r.scheduleQty) * App.freePercent(opts.chickType()) / 100);
                $tr.find('[data-k=free]').val(r.free);
            }
            if (!isNew) { r.isEdit = 1; $tr.find('.badge').attr('class', 'badge text-bg-warning').text('Edited'); }
            totals();
        });

        return {
            load: function (data) { rows = (data || []).map(function (r) { return $.extend({}, r); }); render(); },
            clear: function () { rows = []; render(); },
            rows: function () { return rows; },
            /** Rows ready to post to the server (blank numbers become 0, as VB Val("") did). */
            data: function () {
                return rows.map(function (r) {
                    return {
                        id: App.num(r.id), code: r.code || '', name: r.name || '', hatchery: r.hatchery || '',
                        demandQty: App.num(r.demandQty), rate: App.num(r.rate), scheduleQty: App.num(r.scheduleQty),
                        free: App.num(r.free), scheduleRate: App.num(r.scheduleRate), circularRate: App.num(r.circularRate),
                        compRate: App.num(r.compRate), dr: App.num(r.dr), cr: App.num(r.cr), isEdit: App.num(r.isEdit)
                    };
                });
            },
            setAll: function (key, value) {
                rows.forEach(function (r) { r[key] = value; if (!isNew) r.isEdit = 1; });
                render();
            }
        };
    };
})(jQuery);
