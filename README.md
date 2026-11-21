# Phoenix Scheduling – Web version (ASP.NET Web Forms 4.8, VB.NET)

This is the WinForms **Sheduling** app rebuilt as a website. It is responsive, so it works on phones, tablets and desktops. Every screen loads and saves through AJAX (page `[WebMethod]`s called with jQuery), so the page never does a full reload.

## Run it
1. In Visual Studio, use **File > Open > Web Site…** and pick this folder. Press F5. This is a Web Site project, so there is nothing to build first.
2. To deploy to IIS, copy the folder to the server and create a site or application on an **.NET CLR v4.0 / Integrated** app pool. .NET Framework 4.8 must be installed.
3. Check `Web.config`:
   * `connectionStrings/PhxGroupERP` is the same database the desktop app used.
   * `appSettings` holds CmpId, the Layer Schedule URL, the Layer Tentative head table and the mail (SMTP) settings for *Consolidate Schedule Report > Send Mail*.

Bootstrap 5.3, Bootstrap Icons and jQuery are bundled in `/lib`, so the site works on an intranet with no internet access.

## Structure
| Folder | Contents |
|---|---|
| `App_Code` | `Db` (parameterised SQL), `AppCtx` (logged-in user, session year, business rules), `Api` (JSON result wrapper), `BasePage` (login check), `Models` |
| `Site.master` | Responsive menu that mirrors the old frmMDI menu (it becomes a slide-out menu on phones) |
| `Login.aspx`, `Default.aspx` | Login (Form1) and the home tiles (frmMDI) |
| `Dashboard.aspx` | Landing page after login: demand vs scheduled, hatchery load, top areas, 14-day trend, chick type mix, pending DM/TR approvals (Chart.js in `/lib/chartjs`) |
| `Masters/` | Area, Product, Hatchery, Head Creation |
| `Schedule/` | Hatch Production, Dealer/Other Scheduling, Demand Scheduling, Edit Scheduling, Edit Demand, Layer Schedule Update |
| `Reports/` | Scheduling, Monthly Dealer, Dealer Tr Data, Layer Tentative Date, Consolidate Schedule, Schedule Rate vs Circular Rate (new) |
| `Sales/` | DM Data (FormSupply), TR Data (FrmAreaWiseReport) |
| `Scripts/app.js` | AJAX helper, toasts, confirm dialog, data grid (search, totals, Excel export, phone card view), printable report |
| `Scripts/schedule-grid.js` | Editable grid used by Demand and Edit Scheduling |

## Differences from the desktop app
* **Crystal Reports** are now HTML reports. Each report has *Print / PDF* (from the browser) and *Excel* (CSV) buttons, so the Crystal runtime is not needed on the server.
* **Send Mail** puts both consolidated tables in the mail body and attaches them as CSV files, where the desktop app attached PDFs.
* **SQL is parameterised everywhere.** The old string-built queries allowed SQL injection and failed on names that contain an apostrophe.
* **Multi-row saves run in one transaction:** Demand Scheduling save, Edit Scheduling update, DM/TR authorise. They now either all succeed or all fail. Previously, rows saved before an error stayed in the database.
* **Free-chick % is the same on every screen:** Broiler and Broiler(M) 2%, Layer 5%. The old Edit Scheduling screen used 0% for Broiler(M). Rounding still uses .NET banker's rounding, like `Math.Round`.
* **Edit Scheduling** now clears the grid before each Show (it used to append rows). Its Delete still removes *all* chick types for that area and date, as before, and the confirm dialog warns about this.
* **TR Data:** the options *TR NO BETWEEN-BANK DET* and *TR NO BETWEEN-TRANS TYPE* never worked before because of a stray `'` in the code. They work now.
* **Head Creation** works out the next code again on the server at save time, so two users saving at once cannot get the same number.
* **Hatch Production** loads the row you click. The old double-click always loaded the first row.
* **Hatch dates** are sent as real dates, not locale-formatted strings, so results no longer depend on the PC's regional settings.

## Recommended before go-live
* Use a dedicated SQL login instead of `sa`, and encrypt the `connectionStrings` and `appSettings` sections (`aspnet_regiis -pef`).
* The Gmail app password was hard-coded in the old source. It is now in `Web.config`. Rotate it.
* Passwords in `Usertab4` are stored as plain text (that is the existing design). Consider hashing them.
