<%@ Page Title="Dashboard" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeFile="Dashboard.aspx.vb" Inherits="DashboardPage" %>

<asp:Content ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .viz-root {
        --surface-1: #ffffff;
        --text-primary: #0b0b0b;
        --text-secondary: #52514e;
        --text-muted: #898781;
        --grid: #e1e0d9;
        --axis: #c3c2b7;
        --series-scheduled: #2a78d6;   /* slot 1 blue   - scheduled qty, everywhere */
        --series-demand: #eb6834;      /* slot 2 orange - demand qty, everywhere */
        --series-production: #1baf7a;  /* slot 3 aqua   - hatch production */
        --status-good: #0ca30c;
        --status-warning: #fab219;
        --success-text: #006300;
        font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
    }
    .viz-root .dash-card { background: var(--surface-1); border-radius: .6rem; box-shadow: 0 1px 3px rgba(16,24,40,.08); padding: 1rem 1.1rem; height: 100%; }
    .viz-root .dash-card h2 { font-size: .95rem; font-weight: 600; color: var(--text-primary); margin: 0; }
    .viz-root .dash-card .sub { font-size: .78rem; color: var(--text-muted); }
    .viz-root .card-top { display: flex; align-items: flex-start; justify-content: space-between; gap: .5rem; margin-bottom: .6rem; }
    .viz-root .tbl-toggle { font-size: .75rem; padding: .1rem .5rem; }

    /* hero + stat tiles */
    .viz-root .hero-label { font-size: .82rem; color: var(--text-secondary); }
    .viz-root .hero-value { font-size: 52px; font-weight: 600; line-height: 1.05; color: var(--text-primary); letter-spacing: -.5px; }
    .viz-root .hero-delta { font-size: .85rem; color: var(--text-secondary); margin-top: .35rem; }
    .viz-root .meter { height: 8px; border-radius: 4px; background: #cde2fb; overflow: hidden; margin-top: .6rem; }
    .viz-root .meter > span { display: block; height: 100%; background: var(--series-scheduled); border-radius: 4px; }
    .viz-root .stat-label { font-size: .78rem; color: var(--text-secondary); }
    .viz-root .stat-value { font-size: 1.55rem; font-weight: 600; color: var(--text-primary); line-height: 1.2; }
    .viz-root .stat-note { font-size: .75rem; color: var(--text-muted); }

    /* status strip */
    .viz-root .status { display: flex; align-items: center; gap: .6rem; padding: .7rem .9rem; border-radius: .6rem; background: var(--surface-1); box-shadow: 0 1px 3px rgba(16,24,40,.08); text-decoration: none; color: var(--text-primary); height: 100%; }
    .viz-root .status:hover { box-shadow: 0 4px 12px rgba(20,39,90,.12); color: var(--text-primary); }
    .viz-root .status .ico { width: 34px; height: 34px; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 1rem; flex: 0 0 auto; }
    .viz-root .status.warn .ico { background: #fff4d6; color: #8a5a00; }
    .viz-root .status.good .ico { background: #e3f6e3; color: var(--success-text); }
    .viz-root .status .s-val { font-weight: 600; font-size: 1.05rem; }
    .viz-root .status .s-lbl { font-size: .8rem; color: var(--text-secondary); }

    /* legend: swatch carries identity, text stays in ink */
    .viz-root .legend { display: flex; flex-wrap: wrap; gap: .25rem 1rem; font-size: .78rem; color: var(--text-secondary); }
    .viz-root .legend i { display: inline-block; width: 10px; height: 10px; border-radius: 2px; margin-right: .35rem; vertical-align: -1px; }
    .viz-root .legend i.line { height: 2px; width: 14px; border-radius: 1px; vertical-align: 3px; }

    .viz-root .chart-box { position: relative; width: 100%; }
    .viz-root .no-data { display: flex; align-items: center; justify-content: center; color: var(--text-muted); font-size: .85rem; min-height: 120px; }

    /* tall segmented bar (chick type mix) */
    .viz-root .seg { display: flex; gap: 2px; height: 28px; margin: .4rem 0 .6rem; }
    .viz-root .seg > div { border-radius: 4px; display: flex; align-items: center; padding-left: 6px; font-size: .75rem; font-weight: 600; color: #fff; white-space: nowrap; overflow: visible; min-width: 0; }
    .viz-root .seg > div.dark-ink { color: #0b0b0b; }

    .viz-root table.tv { width: 100%; font-size: .8rem; margin-top: .5rem; }
    .viz-root table.tv th { color: var(--text-secondary); font-weight: 600; border-bottom: 1px solid var(--grid); padding: .25rem .4rem; }
    .viz-root table.tv td { border-bottom: 1px solid #f1f0ec; padding: .25rem .4rem; }
    .viz-root table.tv .n { text-align: right; font-variant-numeric: tabular-nums; }
    .viz-root .stale { opacity: .55; transition: opacity .15s; }
    /* phones: both dates must fit - the presets take over from the arrows */
    @media (max-width: 575.98px) {
        .range-group #btnPrev, .range-group #btnNext { display: none; }
        .range-group input[type=date] { max-width: none !important; padding-left: .5rem; padding-right: .35rem; font-size: .9rem; }
        .range-group #dtFrom { border-top-left-radius: var(--bs-border-radius) !important; border-bottom-left-radius: var(--bs-border-radius) !important; }
        .range-group #dtTo { border-top-right-radius: var(--bs-border-radius) !important; border-bottom-right-radius: var(--bs-border-radius) !important; }
        .range-group .input-group-text { padding: 0 .45rem; }
        #presets .btn { padding: .2rem .4rem; font-size: .78rem; }
        #btnRefresh { white-space: nowrap; padding-left: .6rem; padding-right: .6rem; }
    }
</style>
</asp:Content>

<asp:Content ContentPlaceHolderID="HeaderActions" runat="server">
    <a class="btn btn-sm btn-outline-primary" href="Menu.aspx"><i class="bi bi-grid-3x3-gap"></i> All screens</a>
</asp:Content>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
<div class="viz-root">
    <!-- one filter row scopes every figure and chart below -->
    <div class="card mb-3">
        <div class="card-body py-2" data-enter-click="#btnRefresh">
            <div class="row g-2 align-items-end">
                <div class="col-12 col-md-auto">
                    <label class="form-label" for="dtFrom">Hatch Date Between</label>
                    <div class="input-group range-group">
                        <button class="btn btn-outline-secondary" type="button" id="btnPrev" aria-label="Previous period" title="Previous period"><i class="bi bi-chevron-left"></i></button>
                        <input type="date" class="form-control" id="dtFrom" style="max-width: 160px" aria-label="Hatch date from" />
                        <span class="input-group-text">to</span>
                        <input type="date" class="form-control" id="dtTo" style="max-width: 160px" aria-label="Hatch date to" />
                        <button class="btn btn-outline-secondary" type="button" id="btnNext" aria-label="Next period" title="Next period"><i class="bi bi-chevron-right"></i></button>
                    </div>
                    <div class="btn-group btn-group-sm mt-1 flex-wrap" role="group" aria-label="Quick ranges" id="presets">
                        <button type="button" class="btn btn-outline-secondary" data-preset="today">Today</button>
                        <button type="button" class="btn btn-outline-secondary" data-preset="yesterday">Yesterday</button>
                        <button type="button" class="btn btn-outline-secondary" data-preset="7">Last 7 days</button>
                        <button type="button" class="btn btn-outline-secondary" data-preset="month">This month</button>
                    </div>
                </div>
                <div class="col-8 col-sm-auto">
                    <label class="form-label" for="cmbType">Chicks Type</label>
                    <select class="form-select" id="cmbType" style="min-width: 170px"></select>
                </div>
                <div class="col-4 col-sm-auto">
                    <button type="button" class="btn btn-primary w-100" id="btnRefresh"><i class="bi bi-arrow-clockwise"></i> Refresh</button>
                </div>
                <div class="col-12 col-sm text-sm-end small text-muted" id="asOf"></div>
            </div>
        </div>
    </div>

    <div id="dash">
        <!-- headline -->
        <div class="row g-3 mb-3">
            <div class="col-lg-5">
                <div class="dash-card">
                    <div class="hero-label">Chicks scheduled (Qty Net) &middot; <span id="heroDate"></span></div>
                    <div class="hero-value" id="heroQty">-</div>
                    <div class="hero-delta" id="heroDelta"></div>
                    <div class="meter" role="img" id="fillMeter" aria-label="Demand filled"><span id="fillBar" style="width:0"></span></div>
                </div>
            </div>
            <div class="col-lg-7">
                <div class="row g-3 h-100">
                    <div class="col-6 col-md-3"><div class="dash-card"><div class="stat-label">Demand</div><div class="stat-value" id="kDemand">-</div><div class="stat-note" id="kDemandNote"></div></div></div>
                    <div class="col-6 col-md-3"><div class="dash-card"><div class="stat-label">Free chicks</div><div class="stat-value" id="kFree">-</div><div class="stat-note" id="kFreeNote"></div></div></div>
                    <div class="col-6 col-md-3"><div class="dash-card"><div class="stat-label">Customers</div><div class="stat-value" id="kCust">-</div><div class="stat-note" id="kCustNote"></div></div></div>
                    <div class="col-6 col-md-3"><div class="dash-card"><div class="stat-label">Avg schedule rate</div><div class="stat-value" id="kRate">-</div><div class="stat-note" id="kRateNote">weighted by qty</div></div></div>
                </div>
            </div>
        </div>

        <div class="row g-3">
            <div class="col-xl-8">
                <div class="dash-card">
                    <div class="card-top">
                        <div><h2 id="trendTitle">Demand vs scheduled - last 14 days</h2><div class="sub">Chicks per hatch date</div></div>
                        <button type="button" class="btn btn-light border tbl-toggle" data-for="trend">Table</button>
                    </div>
                    <div class="legend mb-2"><span><i class="line" style="background:var(--series-demand)"></i>Demand</span><span><i class="line" style="background:var(--series-scheduled)"></i>Scheduled</span></div>
                    <div class="chart-box" style="height:260px"><canvas id="cTrend" aria-label="Demand vs scheduled, last 14 days" role="img"></canvas></div>
                    <div class="tv-host" id="tv-trend" hidden></div>
                </div>
            </div>
            <div class="col-xl-4 d-flex flex-column gap-3">
                <!-- pending approvals (status: icon + label, never colour alone) -->
                <a class="status" id="stDm" href="Sales/DMData.aspx" style="height:auto"></a>
                <a class="status" id="stTr" href="Sales/TRData.aspx" style="height:auto"></a>
                <div class="dash-card flex-grow-1" style="height:auto">
                    <div class="card-top">
                        <div><h2>Chick type mix</h2><div class="sub">Share of scheduled chicks in the period, all types</div></div>
                        <button type="button" class="btn btn-light border tbl-toggle" data-for="mix">Table</button>
                    </div>
                    <div id="mixBox"></div>
                    <div class="tv-host" id="tv-mix" hidden></div>
                </div>
            </div>
            <div class="col-xl-6">
                <div class="dash-card">
                    <div class="card-top">
                        <div><h2>Hatchery load</h2><div class="sub" id="hatchSub">Scheduled chicks vs hatch production</div></div>
                        <button type="button" class="btn btn-light border tbl-toggle" data-for="hatch">Table</button>
                    </div>
                    <div class="legend mb-2" id="hatchLegend"></div>
                    <div class="chart-box" id="hatchBox"><canvas id="cHatch" role="img" aria-label="Hatchery load"></canvas></div>
                    <div class="tv-host" id="tv-hatch" hidden></div>
                </div>
            </div>
            <div class="col-xl-6">
                <div class="dash-card">
                    <div class="card-top">
                        <div><h2>Top areas - demand vs scheduled</h2><div class="sub">Top 10 areas in the period</div></div>
                        <button type="button" class="btn btn-light border tbl-toggle" data-for="area">Table</button>
                    </div>
                    <div class="legend mb-2"><span><i style="background:var(--series-demand)"></i>Demand</span><span><i style="background:var(--series-scheduled)"></i>Scheduled</span></div>
                    <div class="chart-box" id="areaBox"><canvas id="cArea" role="img" aria-label="Top areas demand vs scheduled"></canvas></div>
                    <div class="tv-host" id="tv-area" hidden></div>
                </div>
            </div>
        </div>
    </div>
</div>
</asp:Content>

<asp:Content ContentPlaceHolderID="Scripts" runat="server">
<script src="<%: ResolveUrl("~/lib/chartjs/chart.umd.js") %>"></script>
<script>
$(function () {
    var css = getComputedStyle(document.querySelector('.viz-root'));
    function v(n) { return css.getPropertyValue(n).trim(); }
    var C = { sched: v('--series-scheduled'), demand: v('--series-demand'), prod: v('--series-production'),
              grid: v('--grid'), axis: v('--axis'), muted: v('--text-muted'), ink: v('--text-primary'), ink2: v('--text-secondary') };
    // chick type -> fixed categorical slot (colour follows the entity, never its rank)
    var TYPE_COLOR = { 'Broiler': '#2a78d6', 'Broiler(M)': '#eb6834', 'Cockrel': '#1baf7a', 'Layer': '#eda100' };
    var DARK_INK = { '#eda100': true };

    Chart.defaults.font.family = 'system-ui, -apple-system, "Segoe UI", sans-serif';
    Chart.defaults.font.size = 11;
    Chart.defaults.color = C.muted;
    Chart.defaults.plugins.legend.display = false;   // HTML legends above each chart
    Chart.defaults.plugins.tooltip.backgroundColor = '#ffffff';
    Chart.defaults.plugins.tooltip.titleColor = C.ink;
    Chart.defaults.plugins.tooltip.bodyColor = C.ink2;
    Chart.defaults.plugins.tooltip.borderColor = 'rgba(11,11,11,0.12)';
    Chart.defaults.plugins.tooltip.borderWidth = 1;
    Chart.defaults.plugins.tooltip.padding = 8;
    Chart.defaults.plugins.tooltip.boxPadding = 4;
    Chart.defaults.plugins.tooltip.usePointStyle = true;

    var charts = {}, last = null;
    function fmt(n) { return App.fmtNum(n, 0); }
    function compact(n) { n = Number(n); var a = Math.abs(n); return a >= 1e7 ? (n / 1e7).toFixed(1).replace(/\.0$/, '') + ' Cr' : a >= 1e5 ? (n / 1e5).toFixed(1).replace(/\.0$/, '') + ' L' : a >= 1000 ? (n / 1000).toFixed(a >= 1e4 ? 0 : 1).replace(/\.0$/, '') + 'K' : String(n); }
    // One style per axis: lakh if the axis reaches 1 L, thousands if it reaches 10K, otherwise in full.
    function axisLabel(x, max) {
        if (x === 0) return '0';
        if (max >= 1e5) return (x / 1e5).toFixed(x % 1e5 === 0 ? 0 : 1) + ' L';
        if (max >= 1e4) return (x / 1000).toFixed(0) + 'K';
        return App.fmtNum(x, 0);
    }
    function axisOpts(horizontalValue) {
        var val = { beginAtZero: true, grid: { color: C.grid, drawTicks: false }, border: { display: false },
                    ticks: { padding: 6, maxTicksLimit: 6, callback: function (x) { return axisLabel(x, this.max); } } };
        var cat = { grid: { display: false }, border: { color: C.axis }, ticks: { padding: 6, color: C.ink2, maxRotation: 0, autoSkip: true, autoSkipPadding: 10 } };
        return horizontalValue ? { x: val, y: cat } : { x: cat, y: val };
    }
    function destroy(id) { if (charts[id]) { charts[id].destroy(); delete charts[id]; } }
    function noData(box, msg) { $(box).find('canvas').hide(); if (!$(box).find('.no-data').length) $(box).append('<div class="no-data"></div>'); $(box).find('.no-data').text(msg || 'No schedule in this period.').show(); }
    function hasData(box) { $(box).find('canvas').show(); $(box).find('.no-data').hide(); }

    function tableView(id, cols, rows) {
        var h = '<table class="tv"><thead><tr>' + cols.map(function (c) { return '<th class="' + (c.n ? 'n' : '') + '">' + c.t + '</th>'; }).join('') + '</tr></thead><tbody>';
        rows.forEach(function (r) { h += '<tr>' + cols.map(function (c) { var x = r[c.k]; return '<td class="' + (c.n ? 'n' : '') + '">' + (c.n ? (c.f ? c.f(x) : fmt(x)) : App.esc(x)) + '</td>'; }).join('') + '</tr>'; });
        $('#tv-' + id).html(h + '</tbody></table>');
    }

    // ---------------------------------------------------------------- headline
    function headline(d, p) {
        var qty = App.num(d.kpi.qty), dem = App.num(d.demand.demand);
        var range = p.fromDate === p.toDate ? App.fmtDate(p.fromDate) : App.fmtDate(p.fromDate) + ' to ' + App.fmtDate(p.toDate);
        $('#heroDate').text(range + (p.chickType ? ' \u00b7 ' + p.chickType : ''));
        $('#heroQty').text(fmt(qty));
        if (dem > 0) {
            var pct = qty / dem * 100;
            $('#heroDelta').html('<strong>' + pct.toFixed(1) + '%</strong> of demand scheduled \u00b7 ' + (qty >= dem ? 'fully covered' : fmt(dem - qty) + ' chicks still to schedule'));
            $('#fillBar').css('width', Math.min(pct, 100) + '%');
            $('#fillMeter').attr('aria-label', pct.toFixed(1) + '% of demand scheduled');
        } else {
            $('#heroDelta').text(qty ? 'No demand entered for this period.' : 'Nothing scheduled for this period yet.');
            $('#fillBar').css('width', '0');
        }
        $('#kDemand').text(fmt(dem)); $('#kDemandNote').text(fmt(d.demand.demandCustomers) + ' customers');
        $('#kFree').text(fmt(d.kpi.free)); $('#kFreeNote').text(qty ? (App.num(d.kpi.free) / qty * 100).toFixed(1) + '% of scheduled' : '');
        $('#kCust').text(fmt(d.kpi.customers)); $('#kCustNote').text(fmt(d.kpi.hatcheries) + ' hatcheries' + (p.fromDate !== p.toDate ? ' \u00b7 ' + fmt(d.kpi.hatchDays) + ' hatch dates' : ''));
        // Weighted by Qty Net over rows that have a rate; rows saved with rate 0 / blank are left out.
        var hasRate = d.kpi.avgRate !== null && d.kpi.avgRate !== undefined;
        $('#kRate').text(hasRate ? '\u20b9' + App.num(d.kpi.avgRate).toFixed(2) : '-');
        var note = hasRate ? 'weighted by qty \u00b7 simple avg \u20b9' + App.num(d.kpi.simpleRate).toFixed(2) : 'no rates entered';
        if (hasRate) note += '<br>range \u20b9' + App.num(d.kpi.minRate).toFixed(2) + ' - \u20b9' + App.num(d.kpi.maxRate).toFixed(2);
        if (App.num(d.kpi.zeroRateRows) > 0) note += '<br>' + fmt(d.kpi.zeroRateRows) + ' row(s) without rate excluded';
        $('#kRateNote').html(note);

        function status(el, n, what) {
            var warn = n > 0;
            $(el).toggleClass('warn', warn).toggleClass('good', !warn).html(
                '<span class="ico"><i class="bi ' + (warn ? 'bi-exclamation-triangle-fill' : 'bi-check-circle-fill') + '"></i></span>' +
                '<span><span class="s-val">' + (warn ? fmt(n) + ' ' + what + ' awaiting authorisation' : 'No ' + what + ' pending') + '</span>' +
                '<span class="d-block s-lbl">' + (warn ? 'Pending \u00b7 current session \u00b7 open to authorise' : 'All authorised \u00b7 current session') + '</span></span>' +
                '<i class="bi bi-chevron-right ms-auto text-muted"></i>');
        }
        status('#stDm', d.pendingDm, 'DMs');
        status('#stTr', d.pendingTr, 'TRs');
    }

    // ---------------------------------------------------------------- trend (2 lines, one axis, same unit)
    function trend(d) {
        destroy('trend');
        $('#trendTitle').text(d.trendIsRange ? 'Demand vs scheduled by hatch date' : 'Demand vs scheduled - last 14 days');
        var labels = d.trend.map(function (r) { var p = App.fmtDate(r.day).split('/'); return p[0] + ' ' + p[1]; });
        var lastIdx = d.trend.length - 1;
        charts.trend = new Chart(document.getElementById('cTrend'), {
            type: 'line',
            data: { labels: labels, datasets: [
                { label: 'Demand', data: d.trend.map(function (r) { return r.demand; }), borderColor: C.demand, backgroundColor: C.demand, borderWidth: 2, pointRadius: function (c) { return c.dataIndex === lastIdx ? 4 : 0; }, pointHoverRadius: 5, pointBorderColor: '#fff', pointBorderWidth: 2, tension: 0.25 },
                { label: 'Scheduled', data: d.trend.map(function (r) { return r.scheduled; }), borderColor: C.sched, backgroundColor: 'rgba(42,120,214,0.10)', fill: true, borderWidth: 2, pointRadius: function (c) { return c.dataIndex === lastIdx ? 4 : 0; }, pointHoverRadius: 5, pointBorderColor: '#fff', pointBorderWidth: 2, tension: 0.25 }
            ] },
            options: { maintainAspectRatio: false, interaction: { mode: 'index', intersect: false }, scales: axisOpts(false),
                plugins: { tooltip: { callbacks: { label: function (c) { return ' ' + c.dataset.label + ': ' + fmt(c.parsed.y); } } } } }
        });
        tableView('trend', [{ k: 'day', t: 'Hatch date' }, { k: 'demand', t: 'Demand', n: 1 }, { k: 'scheduled', t: 'Scheduled', n: 1 }],
            d.trend.map(function (r) { return { day: App.fmtDate(r.day), demand: r.demand, scheduled: r.scheduled }; }).reverse());
    }

    // ---------------------------------------------------------------- horizontal grouped bars
    function hbars(id, canvas, box, labels, sets, tvCols, tvRows) {
        destroy(id);
        if (!labels.length) { noData(box); tableView(id, tvCols, []); return; }
        hasData(box);
        $(box).css('height', (labels.length * (sets.length > 1 ? 46 : 32) + 40) + 'px');
        charts[id] = new Chart(document.getElementById(canvas), {
            type: 'bar',
            data: { labels: labels, datasets: sets.map(function (s) {
                return { label: s.label, data: s.data, backgroundColor: s.color, borderRadius: 4, borderSkipped: 'start', maxBarThickness: 20,
                         categoryPercentage: 0.8, barPercentage: 1, borderColor: '#ffffff', borderWidth: { top: 1, bottom: 1, left: 0, right: 0 } };
            }) },
            options: { indexAxis: 'y', maintainAspectRatio: false, scales: axisOpts(true),
                interaction: { mode: 'index', axis: 'y', intersect: false },
                plugins: { tooltip: { callbacks: { label: function (c) { return ' ' + c.dataset.label + ': ' + fmt(c.parsed.x); } } } } }
        });
        tableView(id, tvCols, tvRows);
    }

    function hatchery(d) {
        var names = d.hatchery.map(function (r) { return r.name; });
        var prodMap = {};
        (d.production || []).forEach(function (r) { prodMap[r.name] = r.production; if (names.indexOf(r.name) < 0) names.push(r.name); });
        var schedMap = {}; d.hatchery.forEach(function (r) { schedMap[r.name] = r.scheduled; });
        var rows = names.map(function (n) { return { name: n || '(blank)', scheduled: App.num(schedMap[n]), production: d.production ? App.num(prodMap[n]) : null }; });
        var sets = [{ label: 'Scheduled', color: C.sched, data: rows.map(function (r) { return r.scheduled; }) }];
        var cols = [{ k: 'name', t: 'Hatchery' }, { k: 'scheduled', t: 'Scheduled', n: 1 }];
        if (d.production) {
            sets.push({ label: 'Hatch production', color: C.prod, data: rows.map(function (r) { return r.production; }) });
            cols.push({ k: 'production', t: 'Production', n: 1 });
            $('#hatchLegend').html('<span><i style="background:var(--series-scheduled)"></i>Scheduled</span><span><i style="background:var(--series-production)"></i>Hatch production</span>');
            $('#hatchSub').text('Scheduled chicks vs hatch production entered for the period');
        } else {
            $('#hatchLegend').html('');
            $('#hatchSub').text('Scheduled chicks (hatch production is not split by chick type - choose "All types" to compare)');
        }
        hbars('hatch', 'cHatch', '#hatchBox', rows.map(function (r) { return r.name; }), sets, cols, rows);
    }

    function areas(d) {
        var rows = d.area.map(function (r) { return { name: r.name || r.code, demand: App.num(r.demand), scheduled: App.num(r.scheduled) }; });
        hbars('area', 'cArea', '#areaBox', rows.map(function (r) { return r.name; }),
            [{ label: 'Demand', color: C.demand, data: rows.map(function (r) { return r.demand; }) },
             { label: 'Scheduled', color: C.sched, data: rows.map(function (r) { return r.scheduled; }) }],
            [{ k: 'name', t: 'Area' }, { k: 'demand', t: 'Demand', n: 1 }, { k: 'scheduled', t: 'Scheduled', n: 1 }], rows);
    }

    // ---------------------------------------------------------------- chick type mix: tall segmented bar
    function mix(d) {
        var total = d.mix.reduce(function (s, r) { return s + App.num(r.qty); }, 0);
        var order = ['Broiler', 'Broiler(M)', 'Cockrel', 'Layer'];
        var rows = d.mix.slice().sort(function (a, b) { var ia = order.indexOf(a.name), ib = order.indexOf(b.name); return (ia < 0 ? 9 : ia) - (ib < 0 ? 9 : ib); });
        if (!total) { $('#mixBox').html('<div class="no-data">No schedule in this period.</div>'); tableView('mix', [{ k: 'name', t: 'Type' }], []); return; }
        var seg = '<div class="seg" role="img" aria-label="' + rows.map(function (r) { return r.name + ' ' + fmt(r.qty) + ' (' + (r.qty / total * 100).toFixed(0) + '%)'; }).join(', ') + '">';
        var legend = '<div class="legend">';
        rows.forEach(function (r) {
            var share = App.num(r.qty) / total * 100, col = TYPE_COLOR[r.name] || '#898781';
            if (share <= 0) return;
            seg += '<div class="' + (DARK_INK[col] ? 'dark-ink' : '') + '" style="flex:' + share + ' 0 0;background:' + col + '" title="' + App.esc(r.name) + ': ' + fmt(r.qty) + ' (' + share.toFixed(1) + '%)">' + (share >= 14 ? share.toFixed(0) + '%' : '') + '</div>';
            legend += '<span><i style="background:' + col + '"></i>' + App.esc(r.name) + '</span>';
        });
        $('#mixBox').html('<div class="stat-value" style="font-size:1.2rem">' + fmt(total) + ' <span class="stat-note">chicks</span></div>' + seg + '</div>' + legend + '</div>');
        tableView('mix', [{ k: 'name', t: 'Type' }, { k: 'qty', t: 'Scheduled', n: 1 }, { k: 'share', t: 'Share', n: 1, f: function (x) { return x.toFixed(1) + '%'; } }],
            rows.map(function (r) { return { name: r.name, qty: r.qty, share: App.num(r.qty) / total * 100 }; }));
    }

    // ---------------------------------------------------------------- load
    function load() {
        var p = { fromDate: $('#dtFrom').val(), toDate: $('#dtTo').val(), chickType: $('#cmbType').val() };
        if (!p.fromDate || !p.toDate) return;
        if (p.fromDate > p.toDate) { App.toast('Hatch Date From is after Hatch Date To.', 'warning'); return; }
        markPreset();
        $('#dash').addClass('stale');   // keep the previous render, dimmed - no skeleton flash
        App.api('Data', p, { silent: true, fail: function () { $('#dash').removeClass('stale'); } }).then(function (d) {
            last = d;
            headline(d, p); trend(d); mix(d); hatchery(d); areas(d);
            $('#dash').removeClass('stale');
            $('#asOf').text('Updated ' + new Date().toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' }));
        });
    }

    $(document).on('click', '.tbl-toggle', function () {
        var id = $(this).attr('data-for'), $t = $('#tv-' + id), show = $t.prop('hidden');
        $t.prop('hidden', !show); $(this).text(show ? 'Chart' : 'Table');
        $(this).closest('.dash-card').find('.chart-box, #mixBox, .legend').toggle(!show);
    });
    $('#btnRefresh').on('click', load);
    function days(a, b) { var x = a.split('-'), y = b.split('-'); return Math.round((new Date(+y[0], +y[1] - 1, +y[2]) - new Date(+x[0], +x[1] - 1, +x[2])) / 864e5); }
    function setRange(f, t) { $('#dtFrom').val(f); $('#dtTo').val(t); load(); }
    function presetRange(k) {
        var t = App.today();
        if (k === 'today') return [t, t];
        if (k === 'yesterday') { var y = App.addDays(t, -1); return [y, y]; }
        if (k === '7') return [App.addDays(t, -6), t];
        if (k === 'month') return [App.firstOfMonth(), t];
    }
    function markPreset() {
        $('#presets button').each(function () {
            var r = presetRange($(this).attr('data-preset'));
            var on = r[0] === $('#dtFrom').val() && r[1] === $('#dtTo').val();
            $(this).toggleClass('active', on).attr('aria-pressed', on);
        });
    }
    $('#presets').on('click', 'button', function () { var r = presetRange($(this).attr('data-preset')); setRange(r[0], r[1]); });
    $('#dtFrom').on('change', function () { if ($('#dtTo').val() < this.value) $('#dtTo').val(this.value); load(); });
    $('#dtTo').on('change', function () { if ($('#dtFrom').val() > this.value) $('#dtFrom').val(this.value); load(); });
    $('#cmbType').on('change', load);
    // move the whole range back / forward by its own length (a single day moves one day)
    $('#btnPrev').on('click', function () { var n = days($('#dtFrom').val(), $('#dtTo').val()) + 1; setRange(App.addDays($('#dtFrom').val(), -n), App.addDays($('#dtTo').val(), -n)); });
    $('#btnNext').on('click', function () { var n = days($('#dtFrom').val(), $('#dtTo').val()) + 1; setRange(App.addDays($('#dtFrom').val(), n), App.addDays($('#dtTo').val(), n)); });

    App.api('Setup').then(function (s) {
        App.fillSelect('#cmbType', s.chickTypes.filter(function (t) { return t !== 'Broiler(M)'; }).map(function (t) { return { v: t, t: t === 'Broiler' ? 'Broiler + Broiler(M)' : t }; }), { value: 'v', text: 't', placeholder: 'All types' });
        $('#dtFrom').val(App.today()); $('#dtTo').val(App.today());
        load();
    });
});
</script>
</asp:Content>
