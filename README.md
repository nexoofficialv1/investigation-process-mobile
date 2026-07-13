# Investigation & Process Mobile MVP v1.9

This patch fixes field-test issues:

- CD PDF: official PRB Form No. 43 / West Bengal Form No. 5363 layout refinement.
- CD PDF: no extra second page unless content genuinely overflows.
- CD PDF: Bengali-capable PDF font theme added for statement/forms/report/sketch map exports.
- Checklists: checkbox items are now tappable and stateful.
- Evidence: added separate Evidence Manager instead of opening case entry.
- Sketch Map: save flow hardened with error handling and CD mention option.

Official document format rule: CD, IF5, statement, notice, forwarding and requisition output must remain locked official templates. App UI may be modern, but export layout must not be redesigned.

### v2.1 Sketch Map Fix
Sketch Map Builder now uses object-like drawn symbols for house, shop, pond, tree, road, field, PO and arrow instead of plain boxes/circles. Road and arrow can be rotated from the object edit dialog. Object size can also be adjusted before preview/export.

### v2.2 Sketch Map Force Fix
Open Sketch Map and check the title `Sketch Map Builder v2.2`. If it is not visible, the new APK is not installed. Use the clear-map button once for old saved sketches, then add House/Road/Pond/Tree again.
