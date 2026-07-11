# v1.9 Implementation Notes

## Fixes

1. CD official template
   - `Particulars of Enquiry.` row is now separated from the entry/body row.
   - Marginal columns remain: `No. and hour of entry`, `Place of entry`, `Synopsis of entry`.
   - Proceedings/body is in the right-side official column.
   - Signature is kept inside the proceedings cell to avoid unwanted second page creation.

2. Bengali PDF support
   - PDF documents now use Noto Bengali PDF fonts via `PdfGoogleFonts`.
   - Applies to CD, Statement, Forms/Notices, Reports and Sketch Map PDFs.

3. Checklist
   - Checklist items can now be ticked/unticked.

4. Evidence Manager
   - Added `EvidenceScreen` for physical/digital/medical/seizure evidence entry.
   - Dashboard Evidence card and Case Detail Evidence module now open the Evidence Manager.
   - Save + CD creates pending CD action.

5. Sketch Map save
   - Added try/catch error handling for save.
   - CD mention date made safe.

## Next required work

- IF5 official serial template fine-tuning.
- Camera/OCR parser activation.
- PDF pixel-level comparison against live official forms.
