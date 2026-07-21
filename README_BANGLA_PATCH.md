# INVESTIGO — Current Repository Safe বাংলা Patch

এই patch বর্তমান `nexoofficialv1/investigation-process-mobile` repository-র নতুন feature/logic না মুছে:

- অ্যাপের UI, menu, button, heading এবং instruction বাংলায় করে;
- CD, report, form, notice, requisition, FSL, UD এবং checklist-এর স্থির template text বাংলায় করে;
- v4.5 smart investigation checklist ও duplicate/re-statement warning বাংলায় রাখে;
- description-type input field-এ English → বাংলা translate icon এবং focus ছাড়ার সময় auto-translation যোগ করে;
- case number, date, time, section, mobile, email, code, amount, IMEI, UPI ইত্যাদি field auto-translation থেকে বাদ রাখে;
- GitHub APK workflow-এ Android INTERNET permission যোগ করে।

## Termux-এ ব্যবহার

```bash
pkg update -y
pkg install git python unzip -y
cd ~
rm -rf investigation-process-mobile
git clone https://github.com/nexoofficialv1/investigation-process-mobile.git
cd investigation-process-mobile
```

এই ZIP-এর সব file এই repository folder-এর মধ্যে extract/copy করুন। তারপর:

```bash
bash apply_and_push.sh
```

তারপর GitHub → Actions → Build Android APK → Run workflow।

## শুধু patch প্রয়োগ করতে

```bash
bash apply_bangla_patch.sh
```

## গোপনীয়তা

English → বাংলা automatic translation Google-এর online translation endpoint ব্যবহার করে। গোপন/সংবেদনশীল তদন্ত-তথ্যের ক্ষেত্রে বিভাগীয় নীতি ও অনুমোদন অনুসরণ করুন। Internet না থাকলে original text অপরিবর্তিত থাকবে; বাংলা fixed templates তবুও বাংলায় থাকবে।
