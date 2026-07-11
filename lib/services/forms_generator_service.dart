import '../models/case_file.dart';
import '../models/officer_profile.dart';

class FormTemplateInfo {
  final String id;
  final String title;
  final String subtitle;
  final String category;

  const FormTemplateInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
  });
}

class FormsGeneratorService {
  static const List<FormTemplateInfo> templates = [
    FormTemplateInfo(id: 'bnss_35_3', title: '35(3) BNSS Notice', subtitle: 'Accused/person appearance and cooperation notice', category: 'Notice'),
    FormTemplateInfo(id: 'bnss_94', title: '94 BNSS Requisition', subtitle: 'Document / thing production requisition', category: 'Requisition'),
    FormTemplateInfo(id: 'bnss_183', title: '183 BNSS Prayer', subtitle: 'Judicial statement prayer before Ld. Court', category: 'Court Prayer'),
    FormTemplateInfo(id: 'medical_exam', title: 'Medical Examination Requisition', subtitle: 'Victim/injured/accused medical examination', category: 'Medical'),
    FormTemplateInfo(id: 'bht_injury', title: 'BHT / Injury Report Requisition', subtitle: 'Hospital records and injury report collection', category: 'Medical'),
    FormTemplateInfo(id: 'cdr_caf', title: 'CDR / CAF Requisition', subtitle: 'Mobile number CDR/CAF/IPDR request draft', category: 'Digital Evidence'),
    FormTemplateInfo(id: 'bank_details', title: 'Bank Account Details Requisition', subtitle: 'Account statement/KYC/lien/freeze details', category: 'Cyber/Bank'),
    FormTemplateInfo(id: 'fsl', title: 'FSL Requisition', subtitle: 'Forward seized article/electronic exhibit to FSL', category: 'Expert'),
    FormTemplateInfo(id: 'forwarding', title: 'Accused Forwarding Report', subtitle: 'Forwarding accused before Ld. Court', category: 'Court'),
    FormTemplateInfo(id: 'further_investigation', title: 'Further Investigation Prayer', subtitle: 'Prayer for further investigation/extension/compliance', category: 'Court Prayer'),
    FormTemplateInfo(id: 'cs_checklist', title: 'CS / FR Draft Checklist', subtitle: 'Pre-submission checklist for charge sheet/final report', category: 'Final Report'),
  ];

  FormTemplateInfo templateById(String id) {
    return templates.firstWhere(
      (e) => e.id == id,
      orElse: () => templates.first,
    );
  }

  String generate({
    required String templateId,
    required OfficerProfile officer,
    required CaseFile caseFile,
  }) {
    switch (templateId) {
      case 'bnss_35_3':
        return _notice35(officer, caseFile);
      case 'bnss_94':
        return _requisition94(officer, caseFile);
      case 'bnss_183':
        return _prayer183(officer, caseFile);
      case 'medical_exam':
        return _medicalExam(officer, caseFile);
      case 'bht_injury':
        return _bhtInjury(officer, caseFile);
      case 'cdr_caf':
        return _cdrCaf(officer, caseFile);
      case 'bank_details':
        return _bankDetails(officer, caseFile);
      case 'fsl':
        return _fsl(officer, caseFile);
      case 'forwarding':
        return _forwarding(officer, caseFile);
      case 'further_investigation':
        return _furtherInvestigation(officer, caseFile);
      case 'cs_checklist':
        return _csChecklist(officer, caseFile);
      default:
        return _generic(officer, caseFile);
    }
  }

  String _caseRef(OfficerProfile officer, CaseFile caseFile) {
    return '${officer.policeStation} PS Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}';
  }

  String _notice35(OfficerProfile officer, CaseFile caseFile) => '''To,
_____________________________
S/O / W/O ____________________
Address: _____________________

Sub: Notice u/s 35(3) BNSS in connection with ${_caseRef(officer, caseFile)}.

You are hereby directed to appear before the undersigned at ${officer.policeStation} on __________ at ______ hrs and cooperate with the investigation of the above noted case.

You are further directed not to tamper with evidence, not to threaten or influence any witness, and to remain available during investigation as and when required.

Given under my hand and seal.

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}
District: ${officer.district}''';

  String _requisition94(OfficerProfile officer, CaseFile caseFile) => '''To,
The ___________________________
Address: ______________________

Sub: Requisition u/s 94 BNSS in connection with ${_caseRef(officer, caseFile)}.

Sir/Madam,
Most respectfully, it is requested to provide/produce the following document/article/information for the purpose of investigation of the above noted case:

1. ______________________________________
2. ______________________________________
3. ______________________________________

The said document/article/information is required for fair and proper investigation. Kindly provide the same at the earliest.

Yours faithfully,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}
District: ${officer.district}''';

  String _prayer183(OfficerProfile officer, CaseFile caseFile) => '''In the Court of ${officer.courtName}

Sub: Prayer for recording statement u/s 183 BNSS in connection with ${_caseRef(officer, caseFile)}.

May it please your honour,
Most respectfully I beg to submit that during investigation of the above noted case, it is necessary to record the statement of the victim/witness namely ____________________ u/s 183 BNSS for the purpose of fair and proper investigation.

It is therefore prayed before your honour to kindly allow recording of the statement of the said victim/witness u/s 183 BNSS.

Submitted by,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

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

  String _cdrCaf(OfficerProfile officer, CaseFile caseFile) => '''To,
The Nodal Officer,
____________________________ Telecom Service Provider

Sub: Requisition for CDR/CAF/IPDR in connection with ${_caseRef(officer, caseFile)}.

Sir/Madam,
In connection with investigation of the above noted case, it is requested to provide CDR/CAF/IPDR/subscriber details of the following mobile number(s):

1. Mobile No: ____________________ Period: From __________ To __________
2. Mobile No: ____________________ Period: From __________ To __________

The information is required for lawful investigation. Kindly provide the same with certificate as applicable.

Yours faithfully,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

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

  String _fsl(OfficerProfile officer, CaseFile caseFile) => '''To,
The Director / Assistant Director,
Forensic Science Laboratory,
____________________________

Sub: Requisition for examination of seized article/exhibit in connection with ${_caseRef(officer, caseFile)}.

Sir/Madam,
The following seized article/exhibit is being forwarded for scientific examination and opinion:

1. Description of exhibit: ____________________
2. Seizure list reference: ____________________
3. Malkhana reference: ____________________
4. Required examination: ____________________

Kindly examine the exhibit and furnish expert opinion at the earliest.

Yours faithfully,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _forwarding(OfficerProfile officer, CaseFile caseFile) => '''In the Court of ${officer.courtName}

Sub: Forwarding report of arrested accused in connection with ${_caseRef(officer, caseFile)}.

May it please your honour,
Most respectfully I beg to submit that during investigation of the above noted case, accused namely ____________________, S/O ____________________, address ____________________, has been arrested on __________ at ______ hrs after observing all legal formalities.

The accused is forwarded before your honour with prayer for necessary order.

Submitted by,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

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
