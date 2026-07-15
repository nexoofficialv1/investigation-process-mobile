# v3.3 FSL multi-exhibit / multi-accused fix

- FSL package now supports multiple exhibits.
  - In FSL entry module, use one line per exhibit:
    `A | Description | How/when found and by whom | Ownership of exhibit | Remarks`
  - The remarks column remains editable.
- FSL package now supports multiple persons in custody.
  - Use one line per accused/person:
    `Full name | Occupation | Age | Sex | Date & time of arrest | Whether on bail or in custody | Court`
  - Export keeps the official `PARTICULARS OF PERSONS IN CUSTODY` table format.
- FSL certificate, exhibit challan, IO/PS details and labels are now generated as separate pages/sections, not squeezed into one page.
- FSL labels are generated per exhibit.
- CDR/SDR/CAF preview now splits long gist text into continued rows to avoid PdfException overflow.
- Existing official CD/IF5/notice format logic is not intentionally changed.
