# Investigation & Process Mobile MVP v2.4

This patch stabilizes Sketch Map label/index editing.

## Key fix
Sketch Map object edit no longer uses popup/bottom sheet. Tap an object, then edit Marker/Label/Index/Rotation in the inline editor card below the map canvas. This avoids the repeated Flutter red-screen assertion crash.

## v2.5 Backend Server Mode

This build adds optional Custom Server + PostgreSQL mode. The app still works offline by default. Later, enter your API server URL in **Backend** from dashboard and enable sync.

Server starter is in `backend_server/` and web panel is in `web_app_server/`.

## v2.6 UD Case Module
- Added UD Case dashboard module.
- Added Inquest Form data entry as per uploaded scanned format under Section 194/196 BNSS.
- Inquest supports Save Draft, Preview, Export PDF and Export DOC.
- UD Final Report/Panchanama placeholders will be locked once exact official formats are provided.

### v2.7 SOP Compliance

The app now includes an SOP module for investigation under new Acts:

- Electronic FIR/information signature tracking within 3 days.
- Woman officer / women-sensitive offence prompts for BNS 64-71, 74-79 and 124.
- Interpreter/special educator / videography prompts for disabled victims/informants.
- 176(3) BNSS PO photography/videography prompts.
- Forensic expert prompt for serious offences punishable with more than 7 years.
- 180 BNSS and 183 BNSS statement prompts.
- Two-month completion prompt for specified sexual/POCSO offences.
- Electronic device sequence/chain of custody prompt.
- 90-day progress/result intimation and further investigation extension prompt.

The SOP screen is case-based and appears as a separate dashboard card named **SOP**.

### v2.8 Investigation Module
After creating a case, use **Investigation** to feed daily investigation work. The module is SOP-guided and creates pending CD entries date-wise. For field work outside the police station, departure and arrival/action entries are mandatory. Raid/arrest actions trigger forwarding and PC/JC suggestion reminders.
