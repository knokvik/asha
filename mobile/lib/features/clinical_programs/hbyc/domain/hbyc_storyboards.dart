import 'hbyc_models.dart';

/// Pictorial storyboard card for caregiver counselling (Requirement 13.5).
class HbycStoryboardCard {
  final String id;
  final HbycMilestone milestone;
  final String title;
  final String titleHi;
  final String topic; // Feeding, Cognitive Play, Hygiene, Illness Care
  final String visualDescription; // Description of the pictorial illustration
  final List<String> bulletTips;
  final List<String> bulletTipsHi;
  final String audioScriptEn;
  final String audioScriptHi;

  const HbycStoryboardCard({
    required this.id,
    required this.milestone,
    required this.title,
    required this.titleHi,
    required this.topic,
    required this.visualDescription,
    required this.bulletTips,
    required this.bulletTipsHi,
    required this.audioScriptEn,
    required this.audioScriptHi,
  });
}

/// Repository of MoHFW-aligned HBYC counselling storyboards and audio scripts.
class HbycStoryboardsCatalog {
  static const List<HbycStoryboardCard> cards = [
    // ── 3 Months Storyboard ──────────────────────────────────────────────────
    HbycStoryboardCard(
      id: 'sb_3m_feeding',
      milestone: HbycMilestone.month3,
      title: 'Exclusive Breastfeeding & Loving Interaction',
      titleHi: 'केवल माँ का दूध और प्यार भरी बातचीत',
      topic: 'Feeding & Bonding',
      visualDescription: 'Mother holding infant skin-to-skin, breastfeeding calmly and smiling at the infant.',
      bulletTips: [
        'Give only breast milk — no water, animal milk, or ghutti needed.',
        'Nurse on demand at least 8 to 10 times day and night.',
        'Talk, smile, and make eye contact while feeding to nurture brain growth.',
      ],
      bulletTipsHi: [
        'केवल माँ का दूध दें — पानी, घुट्टी या शहद बिल्कुल न दें।',
        'दिन और रात मिलाकर कम से कम 8 से 10 बार दूध पिलाएँ।',
        'दूध पिलाते समय बच्चे से मुस्कुराकर बात करें जिससे दिमागी विकास हो।',
      ],
      audioScriptEn:
          'At three months, mother\'s breast milk fulfills all food and water requirements. Talk warmly and sing to your baby every day. This develops baby\'s intelligence and happiness.',
      audioScriptHi:
          'तीन महीने तक बच्चे को सिर्फ माँ का दूध ही दें। बच्चे से प्यार से बात करें, लोरी सुनाएँ और मुस्कुराएँ। इससे बच्चे का मानसिक और शारीरिक विकास तेज़ी से होता है।',
    ),

    // ── 6 Months Storyboard ──────────────────────────────────────────────────
    HbycStoryboardCard(
      id: 'sb_6m_complementary',
      milestone: HbycMilestone.month6,
      title: 'Starting Semi-Solid Foods (Annaprashan)',
      titleHi: 'ऊपरी आहार की शुरुआत (अन्नप्राशन)',
      topic: 'Complementary Feeding',
      visualDescription: 'Caregiver feeding mashed thick porridge/khichdi with clean small spoon, bowl beside a clean cup of water.',
      bulletTips: [
        'Baby is now 6 months: start soft, thick foods in addition to breastfeeding.',
        'Feed 2 to 3 tablespoons, 2 times a day, gradually increasing quantity.',
        'Prepare mashed khichdi, dalia, cooked yellow dal with a drop of ghee or oil.',
        'Always wash hands with soap before preparing and feeding.',
      ],
      bulletTipsHi: [
        '6 महीने पूरे होने पर माँ के दूध के साथ गाढ़ा ऊपरी आहार शुरू करें।',
        'दिन में 2 बार, 2 से 3 चम्मच से शुरुआत करें और धीरे-धीरे मात्रा बढ़ाएँ।',
        'गाढ़ी खिचड़ी, मसला हुआ दलिया, दाल-चावल में थोड़ा घी या तेल मिलाकर दें।',
        'खाना बनाने और खिलाने से पहले हमेशा साबुन से हाथ धोएँ।',
      ],
      audioScriptEn:
          'Congratulations, your baby is six months old! Start thick, freshly cooked complementary foods twice daily while continuing breastfeeding. Wash hands with soap every time before feeding.',
      audioScriptHi:
          'बधाई हो, आपका बच्चा 6 महीने का हो गया है! अब माँ के दूध के साथ दिन में दो बार गाढ़ा मसला हुआ खाना देना शुरू करें। खाना खिलाने से पहले अपने और बच्चे के हाथ ज़रूर धोएँ।',
    ),

    // ── 9 Months Storyboard ──────────────────────────────────────────────────
    HbycStoryboardCard(
      id: 'sb_9m_diversity',
      milestone: HbycMilestone.month9,
      title: 'Dietary Diversity & 9th Month Vaccines',
      titleHi: 'विभिन्न प्रकार का पौष्टिक भोजन और 9वें महीने का टीका',
      topic: 'Diet Diversity & Immunity',
      visualDescription: 'Plate divided into 4 food groups: grains, dal, egg/greens, seasonal fruit; immunization card shown with MR-1 marked.',
      bulletTips: [
        'Feed 3 times a day: half a katori (bowl) of thick food each time.',
        'Include 4 food groups: grains, pulses, green leafy vegetables/fruits, and egg/dairy.',
        'Ensure 9th month MR vaccine and Vitamin A dose are administered at VHSND.',
        'Play interactive games like peek-a-boo and encourage crawling in a clean area.',
      ],
      bulletTipsHi: [
        'दिन में 3 बार, हर बार आधी कटोरी गाढ़ा भोजन खिलाएँ।',
        'भोजन में अनाज, दाल, हरी पत्तेदार सब्ज़ियाँ, फल और अंडा या दूध शामिल करें।',
        '9वें महीने का खसरा-रूबेला (MR) का टीका और विटामिन-ए की खुराक ज़रूर दिलवाएँ।',
        'बच्चे के साथ लुका-छिपी खेलें और साफ़ फर्श पर घुटनों के बल चलने दें।',
      ],
      audioScriptEn:
          'At nine months, feed your child half a bowl of diverse food three times a day. Get the MR vaccine and Vitamin A drops at your village health session to protect against measles.',
      audioScriptHi:
          '9 महीने पर बच्चे को दिन में 3 बार अलग-अलग तरह का पौष्टिक आहार दें। वीएचएसएनडी सत्र में ले जाकर खसरा-रूबेला का टीका और विटामिन-ए की दवा अवश्य पिलवाएँ।',
    ),

    // ── 12 Months Storyboard ─────────────────────────────────────────────────
    HbycStoryboardCard(
      id: 'sb_12m_family_foods',
      milestone: HbycMilestone.month12,
      title: 'Family Foods & Encouraging Words',
      titleHi: 'परिवार का खाना और प्यार भरी बातें',
      topic: 'Family Pot & Language',
      visualDescription: 'Toddler sitting with family at mealtime, picking up bite-sized pieces from a bowl and smiling as mother praises him.',
      bulletTips: [
        'Offer food from the family pot, mashed or cut into small soft bite-sized pieces.',
        'Feed 3 to 4 meals plus 1 or 2 nutritious snacks (like banana or boiled potato) daily.',
        'Encourage self-feeding with fingers or a small spoon; never force-feed.',
        'Talk frequently, name objects around the house, and praise every attempt to speak.',
      ],
      bulletTipsHi: [
        'घर में जो खाना बनता है, उसे थोड़ा मसलकर छोटे टुकड़ों में बच्चे को दें।',
        'दिन में 3-4 बार खाना और 1-2 बार पौष्टिक नाश्ता (जैसे केला, उबला आलू) दें।',
        'बच्चे को खुद अपने हाथ से खाने दें, जबरदस्ती खाना न खिलाएँ।',
        'घर की चीज़ों के नाम बार-बार बोलकर बच्चे को बोलना सिखाएँ।',
      ],
      audioScriptEn:
          'Your baby has completed one full year! Serve family meals three to four times a day plus nutritious snacks. Encourage self-feeding and talk clearly to foster language skills.',
      audioScriptHi:
          'आपका बच्चा एक साल का हो गया है! उसे घर का बना पौष्टिक खाना दिन में 3-4 बार और 1-2 बार फल या नाश्ता दें। बच्चे को खुद खाने दें और उससे बातें करें।',
    ),

    // ── 15 Months Storyboard ─────────────────────────────────────────────────
    HbycStoryboardCard(
      id: 'sb_15m_growth_care',
      milestone: HbycMilestone.month15,
      title: 'Active Exploration & Booster Vaccines',
      titleHi: 'सक्रिय खेलकूद और बूस्टर टीके की तैयारी',
      topic: 'Physical Growth & Safety',
      visualDescription: 'Toddler walking happily across a safe, obstacle-free floor holding an open cup, father clapping encouragingly.',
      bulletTips: [
        'Provide an open cup for water and milk instead of bottles.',
        'Keep home safe: cover electrical outlets, store medicines and hot liquids out of reach.',
        'Read picture books, point to animals, and tell short bedtime stories.',
        'Prepare for 16–24 month booster vaccinations: MR-2, DPT Booster, and OPV Booster.',
      ],
      bulletTipsHi: [
        'बोतल की जगह कटोरी या खुले कप से पानी और दूध पिलाने की आदत डालें।',
        'घर को सुरक्षित रखें: गर्म पानी, दवाइयाँ और बिजली के तार बच्चे की पहुँच से दूर रखें।',
        'चित्रों वाली किताबें दिखाएँ और छोटी कहानियाँ सुनाएँ।',
        '16 से 24 महीने के बीच लगने वाले बूस्टर टीकों (MR-2, DPT और पोलियो) के लिए तैयार रहें।',
      ],
      audioScriptEn:
          'At fifteen months, celebrate your toddler walking and exploring. Ensure clean drinking water from a cup and keep hazards out of reach. Remember to bring your child for booster vaccines at sixteen months.',
      audioScriptHi:
          '15 महीने पर बच्चा चलना और नई चीज़ें सीखना शुरू कर देता है। कप से पानी पीने दें और घर को सुरक्षित रखें। 16 महीने पर लगने वाले बूस्टर टीकों के लिए समय पर स्वास्थ्य केंद्र पहुँचें।',
    ),
  ];

  static HbycStoryboardCard forMilestone(HbycMilestone milestone) {
    return cards.firstWhere(
      (c) => c.milestone == milestone,
      orElse: () => cards.first,
    );
  }
}
