import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/localization/language_controller.dart';

enum AppLanguage {
  english('en', 'English', 'English'),
  telugu('te', 'Telugu', 'తెలుగు'),
  hindi('hi', 'Hindi', 'हिन्दी');

  const AppLanguage(this.code, this.englishName, this.nativeName);

  final String code;
  final String englishName;
  final String nativeName;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) {
    return values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

extension AppStringsContext on BuildContext {
  AppStrings get l10n => watch<LanguageController>().strings;
}

class AppStrings {
  const AppStrings(this.appLanguage);

  final AppLanguage appLanguage;

  static const supportedLocales = [
    Locale('en'),
    Locale('te'),
    Locale('hi'),
  ];

  String get appName => 'WaterBook';
  String get languageLabel => _t('Language', 'భాష', 'भाषा');
  String get chooseLanguage => _t('Choose language', 'భాషను ఎంచుకోండి', 'भाषा चुनें');
  String get english => 'English';
  String get telugu => 'తెలుగు';
  String get hindi => 'हिन्दी';
  String get save => _t('Save', 'సేవ్ చేయండి', 'सेव करें');
  String get cancel => _t('Cancel', 'రద్దు చేయండి', 'रद्द करें');
  String get done => _t('Done', 'పూర్తైంది', 'हो गया');
  String get open => _t('Open', 'తెరవండి', 'खोलें');
  String get close => _t('Close', 'మూసివేయండి', 'बंद करें');
  String get signIn => _t('Sign in', 'సైన్ ఇన్', 'साइन इन');
  String get securedSignIn => _t('Secured sign-in', 'సురక్షిత సైన్ ఇన్', 'सुरक्षित साइन इन');
  String get newShopOwner => _t('New shop owner?', 'కొత్త షాప్ యజమానా?', 'नए दुकान मालिक?');
  String get createAccount => _t('Create account', 'ఖాతా సృష్టించండి', 'खाता बनाएं');
  String get signOut => _t('Sign out', 'సైన్ అవుట్', 'साइन आउट');
  String get forgotPassword => _t('Forgot password?', 'పాస్‌వర్డ్ మర్చిపోయారా?', 'पासवर्ड भूल गए?');
  String get mobileNumber => _t('Mobile number', 'మొబైల్ నంబర్', 'मोबाइल नंबर');
  String get password => _t('Password', 'పాస్‌వర్డ్', 'पासवर्ड');
  String get yourPassword => _t('Your password', 'మీ పాస్‌వర్డ్', 'आपका पासवर्ड');
  String get mobileRequired => _t('Mobile number is required', 'మొబైల్ నంబర్ తప్పనిసరి', 'मोबाइल नंबर जरूरी है');
  String get passwordRequired => _t('Password is required', 'పాస్‌వర్డ్ తప్పనిసరి', 'पासवर्ड जरूरी है');
  String get validMobile => _t('Enter a valid 10-digit mobile number', 'సరైన 10 అంకెల మొబైల్ నంబర్ నమోదు చేయండి', 'सही 10 अंकों का मोबाइल नंबर दर्ज करें');
  String get inactiveDriver => _t('This driver account is inactive. Contact admin.', 'ఈ డ్రైవర్ ఖాతా యాక్టివ్‌లో లేదు. అడ్మిన్‌ను సంప్రదించండి.', 'यह ड्राइवर खाता सक्रिय नहीं है। एडमिन से संपर्क करें।');
  String get staffSubtitle => _t('For shop owners and drivers', 'షాప్ యజమానులు మరియు డ్రైవర్ల కోసం', 'दुकान मालिकों और ड्राइवरों के लिए');
  String get loginTagline => _t('Water delivery, customers and billing', 'వాటర్ డెలివరీ, కస్టమర్లు మరియు బిల్లింగ్', 'पानी डिलीवरी, ग्राहक और बिलिंग');
  String get driverLoginHint => _t('Drivers: use the mobile number and password given by your shop owner.', 'డ్రైవర్లు: మీ షాప్ యజమాని ఇచ్చిన మొబైల్ నంబర్ మరియు పాస్‌వర్డ్ ఉపయోగించండి.', 'ड्राइवर: दुकान मालिक द्वारा दिया गया मोबाइल नंबर और पासवर्ड उपयोग करें।');
  String get dashboard => _t('Dashboard', 'డ్యాష్‌బోర్డ్', 'डैशबोर्ड');
  String get customers => _t('Customers', 'కస్టమర్లు', 'ग्राहक');
  String get quickOrder => _t('Quick order', 'త్వరిత ఆర్డర్', 'त्वरित ऑर्डर');
  String get products => _t('Products', 'ఉత్పత్తులు', 'उत्पाद');
  String get account => _t('Account', 'ఖాతా', 'खाता');
  String get deliveries => _t('Deliveries', 'డెలివరీలు', 'डिलीवरी');
  String get profile => _t('Profile', 'ప్రొఫైల్', 'प्रोफाइल');
  String get waterPlant => _t('Water plant', 'వాటర్ ప్లాంట్', 'वॉटर प्लांट');
  String get notAssignedYet => _t('Not assigned yet', 'ఇంకా కేటాయించలేదు', 'अभी असाइन नहीं हुआ');
  String get noneAssigned => _t('None assigned', 'ఎవరూ కేటాయించలేదు', 'कोई असाइन नहीं');
  String customersOnRoute(int count) => _t('$count on your route', 'మీ రూట్‌లో $count మంది', 'आपके रूट पर $count');
  String get profileHelp => _t('Contact and plant details are set by your admin.', 'కాంటాక్ట్ మరియు ప్లాంట్ వివరాలను మీ అడ్మిన్ సెట్ చేస్తారు.', 'संपर्क और प्लांट विवरण आपके एडमिन सेट करते हैं।');
  String get email => _t('Email', 'ఈమెయిల్', 'ईमेल');
  String get inactive => _t('Inactive', 'యాక్టివ్‌లో లేదు', 'निष्क्रिय');
  String get all => _t('All', 'అన్నీ', 'सभी');
  String get pending => _t('Pending', 'పెండింగ్', 'बाकी');
  String get doneToday => _t('Done today', 'ఈరోజు పూర్తైంది', 'आज पूरा');
  String get noCustomersFound => _t('No customers found', 'కస్టమర్లు కనబడలేదు', 'कोई ग्राहक नहीं मिला');
  String get searchNamePhone => _t('Search name or phone', 'పేరు లేదా ఫోన్ వెతకండి', 'नाम या फोन खोजें');
  String instantOrdersWaiting(int count) => _t(
        '$count instant order${count == 1 ? '' : 's'} waiting',
        '$count తక్షణ ఆర్డర్${count == 1 ? '' : 'లు'} వేచి ఉన్నాయి',
        '$count तत्काल ऑर्डर प्रतीक्षा में',
      );
  String get order => _t('Order', 'ఆర్డర్', 'ऑर्डर');
  String get deliverProducts => _t('Deliver products & collect empties', 'ఉత్పత్తులు డెలివర్ చేసి ఖాళీ క్యాన్లు తీసుకోండి', 'उत्पाद डिलीवर करें और खाली कैन लें');
  String get normalCans => _t('Normal cans', 'సాధారణ క్యాన్లు', 'नॉर्मल कैन');
  String get coolCans => _t('Cool cans', 'కూల్ క్యాన్లు', 'कूल कैन');
  String get emptyReturned => _t('Empty returned', 'తిరిగి వచ్చిన ఖాళీలు', 'वापस आए खाली कैन');
  String get emptyCans => _t('Empty cans', 'ఖాళీ క్యాన్లు', 'खाली कैन');
  String get emptyReturnSaved => _t('Empty return saved', 'ఖాళీ క్యాన్ రిటర్న్ సేవ్ అయింది', 'खाली कैन वापसी सेव हुई');
  String get recordDelivery => _t('Record delivery', 'డెలివరీ నమోదు చేయండి', 'डिलीवरी दर्ज करें');
  String get emptyNormal => _t('Empty normal', 'ఖాళీ సాధారణ', 'खाली नॉर्मल');
  String get emptyCool => _t('Empty cool', 'ఖాళీ కూల్', 'खाली कूल');
  String deliveredItems(int count) => _t(
        'Delivered $count item${count == 1 ? '' : 's'}',
        '$count వస్తువులు డెలివర్ చేశారు',
        '$count आइटम डिलीवर हुए',
      );
  String returningEmpty(int count) => _t(
        'Returning $count empty can${count == 1 ? '' : 's'}',
        '$count ఖాళీ క్యాన్‌లు తిరిగి తీసుకున్నారు',
        '$count खाली कैन वापस',
      );
  String get saveDelivery => _t('Save delivery', 'డెలివరీ సేవ్ చేయండి', 'डिलीवरी सेव करें');
  String get deliverySaved => _t('Delivery saved', 'డెలివరీ సేవ్ అయింది', 'डिलीवरी सेव हुई');
  String get adminUpdated => _t('Admin updated automatically', 'అడ్మిన్‌కు ఆటోమేటిక్‌గా అప్‌డేట్ అయింది', 'एडमिन अपने आप अपडेट हुआ');
  String get couldNotSave => _t('Could not save', 'సేవ్ కాలేదు', 'सेव नहीं हुआ');
  String get enterDelivered => _t('Enter what you delivered', 'మీరు డెలివర్ చేసినది నమోదు చేయండి', 'जो डिलीवर किया है उसे दर्ज करें');
  String get noProductsEnabled => _t('No products are enabled for this customer.', 'ఈ కస్టమర్‌కు ఉత్పత్తులు ఎనేబుల్ చేయలేదు.', 'इस ग्राहक के लिए कोई उत्पाद चालू नहीं है।');
  String get actualDelivered => _t('Actual delivered', 'నిజంగా డెలివర్ చేసినవి', 'वास्तव में डिलीवर');
  String get payment => _t('Payment', 'చెల్లింపు', 'भुगतान');
  String get cashCollected => _t('Cash collected', 'క్యాష్ తీసుకున్నారు', 'कैश मिला');
  String get upiReceived => _t('UPI / GPay received', 'UPI / GPay వచ్చింది', 'UPI / GPay मिला');
  String get notPaidAdmin => _t('Not paid - customer will pay admin', 'చెల్లించలేదు - కస్టమర్ అడ్మిన్‌కు చెల్లిస్తారు', 'भुगतान नहीं - ग्राहक एडमिन को देगा');
  String get payLater => _t('Pay later', 'తర్వాత చెల్లింపు', 'बाद में भुगतान');
  String get amount => _t('Amount', 'మొత్తం', 'राशि');
  String get openDeliver => _t('Open & deliver', 'తెరిచి డెలివర్ చేయండి', 'खोलें और डिलीवर करें');
  String get collectCash => _t('Collect cash', 'క్యాష్ తీసుకోండి', 'कैश लें');
  String get orderLockedByAdmin => _t(
    'Quantities set by admin — confirm delivery & payment only',
    'పరిమాణాలు అడ్మిన్ సెట్ చేసారు — డెలివరీ & చెల్లింపు మాత్రమే',
    'मात्रा एडमिन ने तय की — केवल डिलीवरी और भुगतान',
  );
  String get confirmDelivery => _t('Confirm delivery', 'డెలివరీ నిర్ధారించండి', 'डिलीवरी पुष्टि करें');
  String get instantDelivery => _t('Instant delivery', 'తక్షణ డెలివరీ', 'तत्काल डिलीवरी');
  String get completedToday => _t('Completed today', 'ఈరోజు పూర్తైనవి', 'आज पूरा हुआ');
  String get savedDeliveriesHere => _t('Saved deliveries appear here', 'సేవ్ చేసిన డెలివరీలు ఇక్కడ కనిపిస్తాయి', 'सेव डिलीवरी यहां दिखेगी');
  String get notifications => _t('Notifications', 'నోటిఫికేషన్లు', 'नोटिफिकेशन');
  String get markAllRead => _t('Mark all read', 'అన్నీ చదివినట్లు చేయండి', 'सब पढ़ा हुआ करें');
  String get noDriverNotifications => _t('No driver notifications yet', 'ఇంకా డ్రైవర్ నోటిఫికేషన్లు లేవు', 'अभी कोई ड्राइवर नोटिफिकेशन नहीं');
  String get normal => _t('Normal', 'సాధారణ', 'नॉर्मल');
  String get cool => _t('Cool', 'కూల్', 'कूल');
  String get normalCan => _t('Normal Can', 'సాధారణ క్యాన్', 'नॉर्मल कैन');
  String get coolCan => _t('Cool Can', 'కూల్ క్యాన్', 'कूल कैन');
  String get lorryInLiters => _t('Lorry in Liters', 'లారీలో లీటర్లు', 'लॉरी में लीटर');
  String get fullLorry => _t('Full Lorry', 'పూర్తి లారీ', 'पूरी लॉरी');
  String get autoInLiters => _t('Auto in Liters', 'ఆటోలో లీటర్లు', 'ऑटो में लीटर');
  String get autoCans => _t('Auto Cans', 'ఆటో క్యాన్లు', 'ऑटो कैन');
  String get twentyLitre => _t('20 Litre', '20 లీటర్లు', '20 लीटर');
  String get litreRange1000To5000 => _t('1000 - 5000 Litre', '1000 - 5000 లీటర్లు', '1000 - 5000 लीटर');
  String get fullLoad => _t('Full Load', 'పూర్తి లోడ్', 'पूरा लोड');
  String get litreRange20To200 => _t('20 - 200 Litre', '20 - 200 లీటర్లు', '20 - 200 लीटर');
  String get cansRange2To10 => _t('2 - 10 Cans', '2 - 10 క్యాన్లు', '2 - 10 कैन');
  String get twentyLRoomTemperature => _t('20L room temperature', '20L సాధారణ ఉష్ణోగ్రత', '20L सामान्य तापमान');
  String get twentyLChilled => _t('20L chilled', '20L చల్లగా', '20L ठंडा');
  String get noCans => _t('No cans', 'క్యాన్లు లేవు', 'कोई कैन नहीं');
  String get noItems => _t('No items', 'వస్తువులు లేవు', 'कोई आइटम नहीं');
  String get adminConfirmed => _t('Admin confirmed', 'అడ్మిన్ నిర్ధారించారు', 'एडमिन ने कन्फर्म किया');
  String adminConfirmedAdjust(String summary) => _t(
        'Admin confirmed $summary. Ask customer and adjust below if different.',
        'అడ్మిన్ $summary నిర్ధారించారు. కస్టమర్‌ను అడిగి వేరుగా ఉంటే క్రింద మార్చండి.',
        'एडमिन ने $summary कन्फर्म किया। ग्राहक से पूछकर अलग हो तो नीचे बदलें।',
      );
  String get amountMustBeGreaterThanZero => _t('Amount must be greater than zero', 'మొత్తం సున్నా కంటే ఎక్కువగా ఉండాలి', 'राशि शून्य से अधिक होनी चाहिए');
  String get copyShopNumberForUpi => _t('Copy shop number for UPI', 'UPI కోసం షాప్ నంబర్ కాపీ చేయండి', 'UPI के लिए दुकान नंबर कॉपी करें');
  String get shopNumberCopiedUpi => _t('Shop number copied - open GPay/PhonePe', 'షాప్ నంబర్ కాపీ అయింది - GPay/PhonePe తెరవండి', 'दुकान नंबर कॉपी हुआ - GPay/PhonePe खोलें');
  String get upiCollectVia => _t('Collect via UPI', 'UPI ద్వారా సేకరించండి', 'UPI से वसूली');
  String get upiPayToShop => _t('Pay to shop number', 'షాప్ నంబర్‌కు చెల్లించండి', 'दुकान नंबर पर भुगतान');
  String get upiDriverHint => _t(
        'Show this to customer. They pay in GPay or PhonePe to the shop number below. Confirm after payment is received.',
        'దీన్ని కస్టమర్‌కు చూపించండి. వారు క్రింది షాప్ నంబర్‌కు GPay/PhonePeలో చెల్లిస్తారు. చెల్లింపు వచ్చిన తర్వాత నిర్ధారించండి.',
        'ग्राहक को दिखाएँ। वे नीचे दुकान नंबर पर GPay/PhonePe से भुगतान करें। भुगतान मिलने के बाद कन्फर्म करें।',
      );
  String get upiSameAsAdmin => _t(
        'Same shop UPI number admin uses at the plant.',
        'ప్లాంట్‌లో అడ్మిన్ ఉపయోగించే అదే షాప్ UPI నంబర్.',
        'प्लांट में एडमिन जो दुकान UPI नंबर उपयोग करता है, वही।',
      );
  String get directions => _t('Directions', 'దారి', 'रास्ता');
  String get call => _t('Call', 'కాల్', 'कॉल');
  String get noPreviousVisit => _t('No previous visit on record', 'మునుపటి విజిట్ రికార్డ్ లేదు', 'पिछली विजिट रिकॉर्ड में नहीं है');
  String lastVisit(String date, String summary) => _t('Last visit $date - $summary', 'చివరి విజిట్ $date - $summary', 'पिछली विजिट $date - $summary');
  String emptyReturnedCount(int count) => _t('$count empty returned', '$count ఖాళీలు తిరిగి వచ్చాయి', '$count खाली वापस आए');
  String emptyReturnWithDetails(String details) => _t('Empty return ($details)', 'ఖాళీ రిటర్న్ ($details)', 'खाली वापसी ($details)');
  String get driverNotLinked => _t('Driver is not linked to a water plant.', 'డ్రైవర్ వాటర్ ప్లాంట్‌కు లింక్ కాలేదు.', 'ड्राइवर किसी वॉटर प्लांट से लिंक नहीं है।');
  String get customerAnotherPlant => _t('This customer belongs to another plant.', 'ఈ కస్టమర్ మరో ప్లాంట్‌కు చెందినవారు.', 'यह ग्राहक दूसरे प्लांट का है।');
  String copiedPhone(String phone) => _t('Copied $phone', '$phone కాపీ అయింది', '$phone कॉपी हुआ');
  String get emptyCansWithCustomer => _t('Empty cans with customer', 'కస్టమర్ దగ్గర ఖాళీ క్యాన్లు', 'ग्राहक के पास खाली कैन');
  String jarsOutCollect(int count) => _t('$count jars out - collect before delivering more', '$count జార్లు బయట ఉన్నాయి - మరిన్ని ఇచ్చే ముందు తీసుకోండి', '$count जार बाहर हैं - और देने से पहले लें');
  String stillOutCollect(int count) => _t('$count still out - collect when you can', '$count ఇంకా బయట ఉన్నాయి - వీలైనప్పుడు తీసుకోండి', '$count अभी बाहर हैं - मौका मिले तो लें');
  String get allEmptyCansReturned => _t('All empty cans returned', 'అన్ని ఖాళీ క్యాన్లు తిరిగి వచ్చాయి', 'सभी खाली कैन वापस आ गए');
  String get withCustomer => _t('with customer', 'కస్టమర్ దగ్గర', 'ग्राहक के पास');
  String get returnEmptiesOnly => _t('Return empties only', 'ఖాళీలు మాత్రమే రిటర్న్ చేయండి', 'सिर्फ खाली कैन वापस करें');
  String get route => _t('Route', 'రూట్', 'रूट');
  String get allRoutes => _t('All routes', 'అన్ని రూట్లు', 'सभी रूट');
  String allRoutesCount(int count) => _t('All routes ($count)', 'అన్ని రూట్లు ($count)', 'सभी रूट ($count)');
  String get noRouteYet => _t('No route yet', 'ఇంకా రూట్ లేదు', 'अभी रूट नहीं');
  String noRouteYetCount(int count) => _t('No route yet ($count)', 'ఇంకా రూట్ లేదు ($count)', 'अभी रूट नहीं ($count)');
  String get orders => _t('Orders', 'ఆర్డర్లు', 'ऑर्डर');
  String get cansToday => _t('Cans today', 'ఈరోజు క్యాన్లు', 'आज के कैन');
  String get noInstantJobs => _t('No instant jobs right now. Admin will add phone orders here.', 'ఇప్పుడు తక్షణ పనులు లేవు. ఫోన్ ఆర్డర్లను అడ్మిన్ ఇక్కడ జోడిస్తారు.', 'अभी कोई तुरंत काम नहीं है। एडमिन फोन ऑर्डर यहां जोड़ेंगे।');
  String get instant => _t('Instant', 'తక్షణం', 'तुरंत');
  String get dispatch => _t('Dispatch', 'డిస్పాచ్', 'डिस्पैच');
  String get collectPaymentAtDoor => _t('Collect payment at door', 'తలుపు వద్ద చెల్లింపు తీసుకోండి', 'दरवाजे पर भुगतान लें');
  String get deliverNow => _t('Deliver now', 'ఇప్పుడు డెలివర్ చేయండి', 'अभी डिलीवर करें');
  String get viewCustomer => _t('View customer', 'కస్టమర్‌ను చూడండి', 'ग्राहक देखें');

  String _t(String en, String te, String hi) {
    return switch (appLanguage) {
      AppLanguage.english => en,
      AppLanguage.telugu => te,
      AppLanguage.hindi => hi,
    };
  }
}
