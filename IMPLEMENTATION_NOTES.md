# v1.5 Official Template Correction

Implemented from user-supplied samples:

1. Case Diary CD format
- CD export now follows West Bengal Form No. 5363 / P.R.B Form No. 43 style.
- CD table uses one continuous enquiry block: No. and hour of entry, Place of entry, Synopsis of entry, and proceedings/body.
- No horizontal dividing lines are drawn between individual CD entries.
- CD-I generator now places PO, DO, DR, DD, DA, RO and IO notes at the beginning of the first entry.
- Continuation pages are marked as CASE DIARY ... (Continued) through the PDF header.

2. Sketch Map Builder
- Replaced round/generic symbol display with more recognizable house, shop, pond, tree, road, field, PO and north arrow visuals.
- PDF sketch export also uses recognizable object-like shapes rather than generic round labels.

3. Forms / Notices
- 35(3) BNSS notice PDF follows the user-supplied Notice of Appearance style.
- 94 BNSS notice/requisition follows the user-supplied NOTICE U/S 94 BNSS style.
- Forwarding report follows the user-supplied court forwarding style with Ref, Sub, Sir body, prayer, enclosure and submitted block.

Note: official document output remains locked-template based; app UI can remain modern.

## v1.6 DOC Export + Entry-wise CD Editor
- Added DOC export support alongside PDF export in the preview screen.
- Preview screen now shows Edit / PDF / DOC options when DOC builder is available.
- Added `DocExportService` which generates Word-compatible `.doc` files using official HTML layouts.
- CD editor now uses mobile-scroll entry-wise fields instead of only one body box:
  - Entry No. and Hour / Time
  - Place of Entry
  - Synopsis of Entry
  - Proceedings / Main Body
- Existing generated entries are prefilled and editable. Additional entry lines can be added or deleted before preview/export.
- PDF and DOC export both use the same entry-wise data model, so official CD columns remain separate.
