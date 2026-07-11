# Implementation Notes

## CD generator rule

Every CD body starts with:

`Resumed further investigation of the case.`

Every CD body ends with:

`Closed the diary pending for further investigation of this case.`

Middle paragraphs are generated from Yes/No answers and then edited by the IO.

## Step 4 Investigation Start

Step 4 includes:

- IO Name auto
- Took up investigation date
- Visited PO yes/no + details
- Rough sketch map prepared yes/no + details
- Witness examined yes/no + details
- Medical required yes/no + details
- Seizure required yes/no + details

This feeds CD-I generation.

## CD-II onward

CD-II and later CDs use the question-based CD builder:

- Witness examined
- PO visited
- Sketch map prepared/updated
- Medical papers collected
- Requisition sent
- Seizure made
- Arrest made
- Notice served
- Court prayer submitted
- Order/report/document received
- Local enquiry conducted
- Verification done
- Digital evidence collected
- Important development

After `Generate CD`, the IO gets an editable draft before final save and PDF export.
