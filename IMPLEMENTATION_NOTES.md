# v2.4 Sketch Map Stable Inline Editor Fix

Fixes repeated Flutter red-screen assertion when editing object marker/label on Sketch Map.

Root cause avoided: overlay edit widgets (dialog/bottom sheet) were repeatedly mounting/unmounting TextFormField/Dropdown widgets from draggable Stack children, triggering Flutter inherited-widget dependency assertion on some Android builds.

Change:
- Removed popup/bottom-sheet label editor for sketch objects.
- Object tap now selects the object and opens a permanent inline editor card below the canvas.
- Marker, label, direction, index description, size, and rotation are edited in the inline card.
- Apply button updates selected object.
- Version label changed to Sketch Map Builder v2.4.

## v2.6 Notes
UD Inquest form has been added from the uploaded two-page scan. It preserves the official field order and dotted-line style. The uploaded Final-Report.pdf appears to be a legal reference note about final report/disposal, not a UD final report blank template, so UD Final Report exact locked template still needs the actual office format.

## v2.7 SOP Compliance Patch

Added SOP-driven investigation compliance layer based on the uploaded SOP for investigation under new Acts.

New files:
- `lib/services/sop_compliance_service.dart`
- `lib/screens/sop_compliance_screen.dart`

Changes:
- Dashboard now has a separate **SOP** card.
- Compliance checklist now includes SOP mandatory prompts.
- Investigation checklist now includes SOP mandatory checks.
- SOP rules are section-sensitive: BNS 64-71, 74-79, 124, POCSO and electronic/serious offence triggers.

Current app behavior:
- SOP screen shows grouped rule checklist with category, section reference and explanation.
- IO can tick/untick each SOP item before final CD/IF5.
- Future patch may link each SOP item to document evidence/CD entry/report automatically.

## v2.8 SOP Investigation Workflow Patch
- Added case-wise **Investigation** module.
- IO can feed date-wise SOP-guided investigation actions separately from Evidence.
- Outside-PS work now enforces Departure + Arrival/action time before save.
- Investigation entries automatically create pending CD entries for CD-II onwards.
- Raid/arrest entries trigger procedure suggestions: court forwarding, arrest formalities, medical, relative intimation, and PC/JC prayer where required.
- Investigation screen displays SOP prompts for the selected case/sections.
- Case Detail and Dashboard now include Investigation module navigation.
