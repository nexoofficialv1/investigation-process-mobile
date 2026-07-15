# v3.2 FSL/CDR Structured Entry + PDF Spanning Fix

Changes:
- FSL and CDR/SDR/CAF forms now use a structured entry module in the form editor.
- IO fills form-specific fields first; the app applies them to the form draft.
- Preview renders official output from those structured fields.
- Fixed PDF preview error: long FSL/CDR content is split into spanning-safe sections/pages instead of one oversized widget.
- FSL package preview/export now generates multi-part package: Form 5203, exhibit list, nature of examination, custody/court forwarding, challan, labels.
- CDR/SDR/CAF preview/export uses table-style official requisition rows and avoids page overflow.

Known rule:
- Official format remains locked as far as possible; data is entered in mobile-friendly fields and then rendered in official PDF/DOC preview.
