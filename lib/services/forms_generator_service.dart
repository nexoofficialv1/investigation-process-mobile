import '../models/case_file.dart';
import '../models/officer_profile.dart';

class FormTemplateInfo {
  final String id;
  final String title;
  final String subtitle;
  final String category;

  const FormTemplateInfo({required this.id, required this.title, required this.subtitle, required this.category});
}

class FormsGeneratorService {
  static const List<FormTemplateInfo> templates = [
    FormTemplateInfo(id: 'bnss_179_notice', title: 'Notice U/s 179 BNSS', subtitle: 'Witness/person appearance notice', category: 'Notice'),
    FormTemplateInfo(id: 'bnss_195_notice', title: 'Notice U/s 195 BNSS', subtitle: 'UD/inquest enquiry appearance notice', category: 'UD Notice'),
    FormTemplateInfo(id: 'bnss_35_3', title: '35(3) BNSS Notice', subtitle: 'Accused/person appearance and cooperation notice', category: 'Notice'),
    FormTemplateInfo(id: 'bnss_94', title: '94 BNSS Requisition', subtitle: 'Document / thing production requisition', category: 'Requisition'),
    FormTemplateInfo(id: 'bnss_183', title: '183 BNSS Prayer', subtitle: 'Judicial statement prayer before Ld. Court', category: 'Court Prayer'),
    FormTemplateInfo(id: 'arrest_memo', title: 'Arrest Memo', subtitle: 'Official arrest memo with grounds and witness blocks', category: 'Arrest / Accused'),
    FormTemplateInfo(id: 'arrest_information', title: 'Nominated Person / Arrest Information Notice', subtitle: 'Notice/intimation to nominated person or relative', category: 'Arrest / Accused'),
    FormTemplateInfo(id: 'medical_exam', title: 'Medical Examination Requisition', subtitle: 'Victim/injured/accused medical examination', category: 'Medical'),
    FormTemplateInfo(id: 'bht_injury', title: 'BHT / Injury Report Requisition', subtitle: 'Hospital records and injury report collection', category: 'Medical'),
    FormTemplateInfo(id: 'cdr_caf', title: 'CDR / SDR / CAF Requisition', subtitle: 'Official table format for CDR/SDR/CAF/IMEI request', category: 'Digital Evidence'),
    FormTemplateInfo(id: 'bank_details', title: 'Bank Account Details Requisition', subtitle: 'Account statement/KYC/lien/freeze details', category: 'Cyber/Bank'),
    FormTemplateInfo(id: 'fsl', title: 'FSL Form + Challan + Label Package', subtitle: 'WB Form 5203 with exhibit list, challan and labels', category: 'Expert'),
    FormTemplateInfo(id: 'forwarding', title: 'Accused Forwarding Report', subtitle: 'Forwarding accused before Ld. Court', category: 'Court'),
    FormTemplateInfo(id: 'further_investigation', title: 'Further Investigation Prayer', subtitle: 'Prayer for further investigation/extension/compliance', category: 'Court Prayer'),
    FormTemplateInfo(id: 'memo_evidence', title: 'Memo of Evidence', subtitle: 'Auto draft from case, CD, investigation and evidence', category: 'Final Documents'),
    FormTemplateInfo(id: 'form54_air', title: 'Form 54 Accident Information Report', subtitle: 'Accident / MACT information report', category: 'Accident / MACT'),
    FormTemplateInfo(id: 'inquest_report_196', title: 'Inquest Report U/s 196 BNSS', subtitle: 'Additional inquest report format', category: 'UD Case'),
    FormTemplateInfo(id: 'cs_checklist', title: 'CS / FR Draft Checklist', subtitle: 'Pre-submission checklist for charge sheet/final report', category: 'Final Report'),
  ];

  FormTemplateInfo templateById(String id) => templates.firstWhere((e) => e.id == id, orElse: () => templates.first);

  String generate({required String templateId, required OfficerProfile officer, required CaseFile caseFile}) {
    switch (templateId) {
      case 'bnss_179_notice': return _notice179(officer, caseFile);
      case 'bnss_195_notice': return _notice195(officer, caseFile);
      case 'bnss_35_3': return _notice35(officer, caseFile);
      case 'bnss_94': return _requisition94(officer, caseFile);
      case 'bnss_183': return _prayer183(officer, caseFile);
      case 'arrest_memo': return _arrestMemo(officer, caseFile);
      case 'arrest_information': return _arrestInformation(officer, caseFile);
      case 'medical_exam': return _medicalExam(officer, caseFile);
      case 'bht_injury': return _bhtInjury(officer, caseFile);
      case 'cdr_caf': return _cdrCaf(officer, caseFile);
      case 'bank_details': return _bankDetails(officer, caseFile);
      case 'fsl': return _fsl(officer, caseFile);
      case 'forwarding': return _forwarding(officer, caseFile);
      case 'further_investigation': return _furtherInvestigation(officer, caseFile);
      case 'memo_evidence': return _memoEvidence(officer, caseFile);
      case 'form54_air': return _form54(officer, caseFile);
      case 'inquest_report_196': return _inquestReport196(officer, caseFile);
      case 'cs_checklist': return _csChecklist(officer, caseFile);
      default: return _generic(officer, caseFile);
    }
  }

  String _caseRef(OfficerProfile officer, CaseFile caseFile) => '${officer.policeStation} PS Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}';
  String _valueOrBlank(String value, String fallback) => value.trim().isEmpty ? fallback : value.trim();

  String _notice179(OfficerProfile officer, CaseFile caseFile) => '''NOTICE U/s 179 B.N.S.S.

To,
        ______________________________,
        ______________________________,
        ______________________________.

Sir,
        This is to inform you that the above-mentioned case was registered on the complaint of ${_valueOrBlank(caseFile.complainantName, '____________________________')} S/o/W/o ______________________________ R/o ______________________________. The investigation of the case is being carried by the undersigned.

        Whereas it appears that you are acquainted with the facts/circumstances of the above cited case and investigation thereof. Hence, you are hereby informed to appear before the undersigned on ____________ (date) at ____________ (time) PS ${officer.policeStation}, ${officer.district}, in connection with above cited case.

Name of I.O.: ${officer.rank} ${officer.name}
PS: ${officer.policeStation}
City/District: ${officer.district}
Dt.: ____________

Note:-
1. Failure to attend as required may attract penal proceeding U/s 208 B.N.S.
2. Person below 15 years age and above 60 years, woman or mentally or physically disabled person or person with acute illness are exempted from physical presence in police station unless they are themselves willing to attend and join the investigation, as directed.''';

  String _notice195(OfficerProfile officer, CaseFile caseFile) => '''NOTICE U/s 195 B.N.S.S.

To,
        ______________________________,
        ______________________________,
        ______________________________.

Sir,
        This is to inform you that the inquest proceedings in respect of deceased ${_valueOrBlank(caseFile.victimName, 'Late ____________________________')} S/o/W/o ______________________________ R/o ______________________________ have been initiated to ascertain the cause of death. The enquiry into the matter is being carried by the undersigned.

        Whereas it appears that you are acquainted with the facts/circumstances of the above cited matter. For the purpose of finalization of the enquiry, you are hereby informed to appear before the undersigned on date ____________ at ____________ PS ${officer.policeStation}, ${officer.district}.

Name of I.O.: ${officer.rank} ${officer.name}
PS: ${officer.policeStation}
District: ${officer.district}
Dt.: ____________''';

  String _notice35(OfficerProfile officer, CaseFile caseFile) => '''NOTICE OF APPEARANCE BY THE POLICE
[As per section – 35 (3) BNSS Act.]

Serial No.............                                                   Annexure-A

To,
1. ${_valueOrBlank(caseFile.accusedName, '____________________________')}

In exercise of the powers conferred under section 35 (3) of BNSS, I hereby inform you that during the investigation of FIR/Case No ${_caseRef(officer, caseFile)}, it is revealed that there are reasonable grounds to question you to ascertain facts and circumstances from you, in relation to the present investigation. Hence you are directed to appear before undersigned officer within 03 (three) days after receiving the notice at ________ AM/PM at ${officer.policeStation}, Dist-${officer.district}.

You are directed to comply with all and/or the following directions:-
a) You will not commit any offence in future.
b) You will not tamper with the evidences in the case in any manner whatsoever.
c) You will not make any threat, inducement, or promise to any person acquainted with the fact of the case so as to dissuade him/her from disclosing such facts to the court or to police officer.
d) You will appear before the Court as and when required/directed.
e) You will join the investigation of the case as and when required and will cooperate in the investigation.
f) You will disclose all the facts truthfully without concealing any part relevant for the purpose of investigation to reach to the right conclusion of the case.
g) You will produce all relevant documents/material required for the purpose of investigation.
h) You will render your full co-operation/assistance in apprehension of the accomplice.
i) You will not allow in any manner destruction of any evidence relevant for the purpose of investigation/trial of the case.
j) Any other conditions, which may be imposed by the Investigating Officer / Officer-in-Charge as per the facts of the case.

Failure to attend/comply with the terms of this Notice can render you liable for arrest under Section 35 (6) BNSS.''';

  String _requisition94(OfficerProfile officer, CaseFile caseFile) => '''NOTICE U/S 94 BNSS, 2023

To
The Superintendent / Officer-in-Charge,
____________________________
P.S. ______________________
District – __________________.

Ref: ${officer.policeStation} Case No- ${caseFile.psCaseNo} Dated-${caseFile.caseDate}, U/S- ${caseFile.sections}.

Whereas an investigation is being conducted in c/w above reference and whereas the records/documents/articles relating to complainant/informant ${_valueOrBlank(caseFile.complainantName, 'the complainant')} and the above noted case are required for the purpose of proper investigation, you are hereby requested under the provisions of Section 94 of the BNSS, 2023, to produce and/or furnish the following documents/information:

1. Admission Register Entry / relevant register entry.
2. OPD/IPD tickets and complete treatment/official records.
3. Case history sheet / Bed Head Ticket / connected documents, if maintained.
4. Examination report / treatment records / relevant certificate, if prepared.
5. Name, designation and particulars of the concerned officers/persons.
6. Age-related documents and records available, if any.
7. Reports, forms and requisition papers, if any.
8. Copies of all relevant documents, records and reports.
9. Any other document, record or report relevant to the investigation.

You are requested to provide the aforesaid documents, duly attested, at the earliest for the purpose of investigation.

Failure to comply with this notice without lawful excuse may attract legal consequences as prescribed under law.''';

  String _prayer183(OfficerProfile officer, CaseFile caseFile) => '''In the Court of ${officer.courtName}

Sub: Prayer for recording statement u/s 183 BNSS in connection with ${_caseRef(officer, caseFile)}.

May it please your honour,
Most respectfully I beg to submit that during investigation of the above noted case, it is necessary to record the statement of the victim/witness namely ____________________ u/s 183 BNSS for the purpose of fair and proper investigation.

It is therefore prayed before your honour to kindly allow recording of the statement of the said victim/witness u/s 183 BNSS.

Submitted by,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _arrestMemo(OfficerProfile officer, CaseFile caseFile) => '''ARREST MEMO
[as per section 35 of the Bharatiya Nagarik Suraksha Sanhita, 2023]
(as per direction of Hon'ble Supreme Court of India)

1. Name with Alias and Parentage of the Arrestee: ${_valueOrBlank(caseFile.accusedName, '____________________________')}
2. Mobile No./WhatsApp Mobile No./Email Address: ______________________________
3. Present Address of the Arrestee: ______________________________
4. Permanent Address of the Arrestee: ______________________________
5. FIR No. & Sec. of Law: ${_caseRef(officer, caseFile)}
6. Place of Arrest: ______________________________
7. Date & Time of Arrest: ______________________________
8. Name, Address, e-mail ID & Tel. No. Whomsoever to convey the Arrest Information: ______________________________
9. Name, Rank & No. of the officer who making arrest: ${officer.rank} ${officer.name}, ${officer.policeStation}
10. Reasons/Grounds of arrest:
a) Prevent accused person from committing any further offence: Yes / No / Details ______________________________
b) For proper investigation of the offence: Yes / No / Details ______________________________
c) To prevent the accused person from causing the evidence of the offence to disappear or tampering with such evidence: Yes / No / Details ______________________________
d) To prevent such person from making any inducement, threat or promise to any person acquainted with the facts of the case: Yes / No / Details ______________________________
e) As unless such person is arrested, his presence in the court whenever required cannot be ensured: Yes / No / Details ______________________________

Signature of Arrestee: ______________________________
Witness-1: ______________________________
Witness-2: ______________________________

Place: ______________________________
Date: ______________________________
Signature of the I.O.: ______________________________''';

  String _arrestInformation(OfficerProfile officer, CaseFile caseFile) => '''NOTICE / INTIMATION TO NOMINATED PERSON REGARDING ARREST

Date: ____________

To,
        ______________________________
        ______________________________
        Mobile No.: ______________________________

This is to inform you that ${_valueOrBlank(caseFile.accusedName, '____________________________')}, related to ${_caseRef(officer, caseFile)}, has been arrested on ____________ at ____________ hrs from ______________________________ after observing legal formalities.

Grounds of arrest have been communicated to the arrestee in his/her known language. You are hereby informed as nominated person/relative/friend of the arrestee.

Arrestee Name: ${_valueOrBlank(caseFile.accusedName, '____________________________')}
Case Reference: ${_caseRef(officer, caseFile)}
Place of Arrest: ______________________________
Date & Time of Arrest: ______________________________
PS: ${officer.policeStation}
I.O.: ${officer.rank} ${officer.name}
Mobile: ${officer.mobile}

Signature of recipient/nominated person: ______________________________
Signature of I.O.: ______________________________''';

  String _medicalExam(OfficerProfile officer, CaseFile caseFile) => '''To,
The Medical Officer,
____________________________ Hospital

Sub: Medical examination requisition in connection with ${_caseRef(officer, caseFile)}.

Sir/Madam,
The person named ____________________, S/O/W/O ____________________, address ____________________, is being sent for medical examination in connection with the above noted case.

Kindly examine the said person and furnish the injury report/medical examination report at the earliest for the purpose of investigation.

Yours faithfully,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _bhtInjury(OfficerProfile officer, CaseFile caseFile) => '''To,
The Superintendent / Medical Officer,
____________________________ Hospital

Sub: Requisition for BHT / injury report / treatment papers in connection with ${_caseRef(officer, caseFile)}.

Sir/Madam,
It is requested to provide certified copy of BHT/injury report/treatment papers of ____________________, who was treated/admitted at your hospital on __________ in connection with the above noted case.

The said medical papers are urgently required for investigation.

Yours faithfully,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _cdrCaf(OfficerProfile officer, CaseFile caseFile) {
    final ref = '${officer.policeStation} P.S. Case No-${caseFile.psCaseNo} Dated-${caseFile.caseDate}, U/S-${caseFile.sections}';
    final gist = caseFile.firGist.trim().isEmpty ? '____________________________________________________________________________________________' : caseFile.firGist.trim();
    return '''CDR/SDR/CAF STRUCTURED ENTRY

CASE REFERENCE: $ref
GIST: $gist
REQUIRED MOBILE/IMEI: ________________________________
ACTUAL USER / INVOLVEMENT: Used by suspected / ________________________________
JUSTIFICATION: To trace out / verify / identify ________________________________
CDR DATE RANGE: From ____________ To ____________
SDR REQUIRED: Yes
CAF REQUIRED: Yes
IMEI SEARCH DATE RANGE: ---
IO NAME: ${officer.rank} ${officer.name}
IO PHONE: ${officer.mobile}
ANY OTHER POINTS: N/A

Note: Fill the above entry fields. Preview will render the official table format.''';
  }

  String _bankDetails(OfficerProfile officer, CaseFile caseFile) => '''To,
The Branch Manager / Nodal Officer,
____________________________ Bank

Sub: Requisition for bank account details in connection with ${_caseRef(officer, caseFile)}.

Sir/Madam,
It is requested to provide the following details in respect of Account No./UPI ID ____________________ for the purpose of investigation:

1. Account holder name, address, mobile number and KYC documents.
2. Statement of account from __________ to __________.
3. Details of disputed transaction(s), beneficiary account and UTR.
4. Present balance and lien/freeze status, if any.
5. Any other linked account/UPI/mobile/email details.

Yours faithfully,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _fsl(OfficerProfile officer, CaseFile caseFile) {
    final gist = caseFile.firGist.trim().isEmpty ? 'The fact of the case in brief is that ________________________________________________________________________________.' : caseFile.firGist.trim();
    return '''FSL PACKAGE STRUCTURED ENTRY

NATURE OF CRIME: $gist
EXHIBITS: A | One sealed packet/jar/container containing said to be ________________________________ in connection with the above noted case. | Seized on ____________ at ________________________________ by ${officer.rank} ${officer.name} / received from ________________________________. | Ld. C.J.M / Magistrate, ${officer.district} | May be confiscated to the State after examination / may be returned after examination
NATURE OF EXAMINATION: 1) Whether any poison / blood / semen / biological material / chemical / explosive / narcotic / digital trace / other relevant material could be detected in Exhibit Mark “A” or not.\n2) If detected, nature/type/source of such material and whether the same is relevant to the facts of the case.\n3) Any other points raised during examination.
PERSONS IN CUSTODY: ${caseFile.accusedName.trim().isEmpty ? 'Name and address of accused' : caseFile.accusedName} | Occupation | Age | Sex | Date & time of arrest | J/C / P/C / Bail / At large | Ld. Court
FSL OFFICE: Head of Office & Assistant Director\nRegional Forensic Science Laboratory\nShankarpur, Durgapur\nPaschim Bardhaman, 713212
COURT: Ld. C.J.M / Magistrate, ${officer.district}
IO / PS CONTACT DETAILS: I.O. Name:- ${officer.name}\nDesignation:- ${officer.rank}\nMobile No. of I.O.:- ${officer.mobile}\nName of the PS:- ${officer.policeStation}\nDistrict:- ${officer.district}

Note: Fill the above entry fields. Preview will generate Form 5203 + Exhibit List + Examination Required + Custody + Magistrate forwarding/certification + Challan + Labels.''';
  }

  String _forwarding(OfficerProfile officer, CaseFile caseFile) => '''Ref:   ${officer.policeStation} case no- ${caseFile.psCaseNo} Dated: - ${caseFile.caseDate} u/s - ${caseFile.sections}.

Sub:   Forwarding of FIR named arrested accused person namely- ____________________________.

Sir,
        In forwarding herewith the arrested accused person namely- ____________________________ before your honour's court with all connected paper and proper Police escort I beg to report that ${caseFile.firGist.isEmpty ? '____________________________________________________________________________' : caseFile.firGist}.

        During investigation I visited the PO, prepared rough sketch map of the PO with its index in separate sheets of paper. Examined the complainant and other available witnesses and recorded their statements u/s-180 BNSS in separate sheets of paper. Thereafter the FIR named accused person was arrested after observing all legal formalities.

        Under the above fact and circumstances, I therefore pray before your Honour's court that arrested accused person may kindly be taken in judicial custody / police custody as prayed for till investigation is over.

Enclosure:
1. Original FIR.
2. Memo of Arrest.
3. Inspection Memo.
4. Medical treatment slip.
5. Intimation of arrest.

Submitted,
${officer.rank} ${officer.name}
${officer.policeStation}
Dt. ____________''';

  String _furtherInvestigation(OfficerProfile officer, CaseFile caseFile) => '''In the Court of ${officer.courtName}

Sub: Prayer for further investigation/compliance in connection with ${_caseRef(officer, caseFile)}.

May it please your honour,
Most respectfully I beg to submit that further investigation/compliance is required in the above noted case for the following reasons:

1. ______________________________________
2. ______________________________________
3. ______________________________________

It is therefore prayed before your honour to kindly allow/permit the undersigned to proceed with the necessary investigation/compliance.

Submitted by,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _memoEvidence(OfficerProfile officer, CaseFile caseFile) => '''Memo of Evidence

1. SA No.: ______________________________
2. PS Case No.: ${_caseRef(officer, caseFile)}.
3. Name, Sex, Age, Parentage and Address of the complainant: ${_valueOrBlank(caseFile.complainantName, '____________________________')}.
4. P.O & D.O: ${_valueOrBlank(caseFile.placeOfOccurrence, '____________________________')}, ${_valueOrBlank(caseFile.dateTimeOccurrence, '____________________________')}.
5. Name of the victim/deceased (if any): ${_valueOrBlank(caseFile.victimName, 'N/A')}.
6. Gist of FIR: ${_valueOrBlank(caseFile.firGist, '____________________________')}.

7. Name of IO:
Name of IO: ${officer.rank} ${officer.name}
Date From: ${caseFile.caseDate}
Date To: Till date
CD From: I
CD To: ______________________________

8. Name of FIR named accused persons:
Sl. No. | Name & Parentage | Address | Date of arrest | Present status (JC or bailed out) | Date of bail
1 | ${_valueOrBlank(caseFile.accusedName, '____________________________')} | ______________________________ | __________________ | __________________ | __________________

9. Other accused persons whose name transpires in course of investigation: NIL / ______________________________
10. Seizure: Sl. No. | Article seized | Label (Y/N) | Date of seizure | GDE No. | Property Register No.
11. 180 BNSS statements: Sl. No. | Name Parentage & Address of Witness | Date of exam | Relation | Type of Evidence
12. 183 BNSS statements: Sl. No. | Name Parentage & Address of Witness | Date of exam | Relation | Type of Evidence
13. Medical examination Report: Name | Date | Type | Opinion
14. Inquest Report: N/A / ______________________________
15. Details of PM Report: N/A / ______________________________
16. FSM/FSL/CFSL Report: N/A / ______________________________
17. Other expert opinion: NIL / ______________________________
18. TI Parade: NIL / ______________________________

19. Evidence Chart:
A. Point wise facts to be proved against accused by prosecution:
1) ______________________________

B. Prima facie charge and evidence collected:
Name of accused: ${_valueOrBlank(caseFile.accusedName, '____________________________')}
Prima facie charge: ${caseFile.sections}
Evidence collected: Statements u/s 180 BNSS, 183 BNSS, medical/expert reports, seizure/evidence and circumstantial evidence as collected.

20. Opinion and Analysis of IO about strength and weakness of the case:
During investigation, examined available witnesses, collected relevant documents/evidence and complied with necessary legal formalities. From the statements, documents and evidence collected so far, prima facie charge under ${caseFile.sections} appears to have been established / not established against accused namely ${_valueOrBlank(caseFile.accusedName, '____________________________')}.

Submitted-
(${officer.name})
${officer.rank}
${officer.policeStation}
Dist-${officer.district}

Opinion of I/C: ______________________________
Opinion of Superior Officer: ______________________________
Final Order: ______________________________''';

  String _form54(OfficerProfile officer, CaseFile caseFile) => '''FORM 54
[Refer Rule 150(1) and (2)]
ACCIDENT INFORMATION REPORT

1. Name of the police station: ${officer.policeStation}
2. FIR No./CR No./Traffic accident report: ${caseFile.psCaseNo}
2A. Sections applied: ${caseFile.sections}
3. Date, time and place of accident: ${_valueOrBlank(caseFile.dateTimeOccurrence, '____________________________')} at ${_valueOrBlank(caseFile.placeOfOccurrence, '____________________________')}
4. Name and full address of the injured/deceased: ${_valueOrBlank(caseFile.victimName, '____________________________')}
5. Name of the hospital to which he/she was removed: ______________________________
6. Registration number of vehicle and the type of the vehicle: ______________________________
7. Driving licence particulars:
   (a) Name and address of the driver: ______________________________
   (b) Driving licence number and date of expiry: ______________________________
   (c) Address of the issuing authority: ______________________________
   (d) Badge No. in case of public service vehicle: ______________________________
8. Name and address of the owner of the vehicle at the time of the accident: ______________________________
9. Name and address of the insurance company with whom the vehicle was insured and the particulars of the divisional office: ______________________________
10. Number of insurance policy/insurance certificate and date of validity: ______________________________
11. Registration particulars of the vehicle (class of vehicles): ______________________________
   (a) Registration No.: ______________________________
   (b) Engine No. or motor number in the case of Battery Operated Vehicles: ______________________________
   (c) Chassis No.: ______________________________
12. Route permit particulars or licence of use particulars: ______________________________
13. Action taken, if any, and the result thereof: Case is pending for further investigation / ______________________________''';

  String _inquestReport196(OfficerProfile officer, CaseFile caseFile) => '''INQUEST REPORT
(Under section 196 BNSS, 2023)

1. State: West Bengal        P.S.: ${officer.policeStation}
   P.S. GDE: ____________________    U.D. Case No.: ____________________    Date: ____________
2. Act/Section: ${caseFile.sections.isEmpty ? 'U/s 194/196 BNSS' : caseFile.sections}
3. Date, time and place when and where the Magistrate received intimation U/S 194(1) BNSS about the death: Date ____________ Time ____________ Place ____________________
4. Substance of information obtained and from whom: ______________________________
5. Place where dead body was found (Location): ${_valueOrBlank(caseFile.placeOfOccurrence, '____________________________')}
6. Inquest commenced/closed time and date: ______________________________
7. Place and time where dead body found/traced: ______________________________
8. Person who showed/traced the dead body: ______________________________
9. Person who identified the dead body: ______________________________
10. Dead body: Sex Male/Female, Age ____________, Approximate date & time of death ____________
11. Name & address of dead body (if known): ${_valueOrBlank(caseFile.victimName, '____________________________')}''';

  String _csChecklist(OfficerProfile officer, CaseFile caseFile) => '''CS / FR PRE-SUBMISSION CHECKLIST

Case Reference: ${_caseRef(officer, caseFile)}
IO: ${officer.rank} ${officer.name}

[ ] FIR / Formal FIR attached
[ ] Original complaint attached
[ ] Rough sketch map with index attached
[ ] Statements u/s 180 BNSS attached
[ ] Judicial statement u/s 183 BNSS, if any, attached
[ ] Medical / injury / BHT / PM report attached, if applicable
[ ] Seizure list and malkhana reference attached, if applicable
[ ] FSL / expert report attached, if applicable
[ ] CDR/CAF/bank/digital evidence attached, if applicable
[ ] Arrest memo / forwarding / custody papers attached, if applicable
[ ] Accused particulars verified
[ ] Witness list prepared
[ ] Property list prepared
[ ] 230 BNSS indexed copy supply checklist prepared
[ ] Final opinion / CS or FR ground prepared

Remarks:
______________________________________
______________________________________

Prepared by,
${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _generic(OfficerProfile officer, CaseFile caseFile) => '''Reference: ${_caseRef(officer, caseFile)}

Draft details:
______________________________________
______________________________________
______________________________________

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';
}
