import 'package:google_generative_ai/google_generative_ai.dart';

enum SupportedLanguage { english, swahili }

class MedAlpacaService {
  final String apiKey;
  late final GenerativeModel _model;
  SupportedLanguage currentLanguage = SupportedLanguage.english;

  // Health-related keywords for filtering (English and Swahili)
  static const Map<SupportedLanguage, List<String>> _healthKeywords = {
    SupportedLanguage.english: [
      'health',
      'medical',
      'medicine',
      'doctor',
      'hospital',
      'clinic',
      'symptom',
      'disease',
      'illness',
      'pain',
      'fever',
      'headache',
      'treatment',
      'medication',
      'therapy',
      'surgery',
      'diagnosis',
      'nutrition',
      'diet',
      'exercise',
      'fitness',
      'wellness',
      'mental health',
      'depression',
      'anxiety',
      'stress',
      'sleep',
      'fatigue',
      'nausea',
      'cough',
      'cold',
      'flu',
      'infection',
      'injury',
      'wound',
      'bleeding',
      'diabetes',
      'hypertension',
      'cancer',
      'heart',
      'lung',
      'kidney',
      'pregnancy',
      'birth',
      'child',
      'elderly',
      'vaccine',
      'immunization',
      'prevention',
      'screening',
      'checkup',
      'examination',
      'test',
      'lab',
    ],
    SupportedLanguage.swahili: [
      'afya',
      'matibabu',
      'dawa',
      'daktari',
      'hospitali',
      'kliniki',
      'dalili',
      'ugonjwa',
      'maumivu',
      'homa',
      'maumivu ya kichwa',
      'matibabu',
      'dawa',
      'tiba',
      'upasuaji',
      'utambuzi',
      'lishe',
      'chakula',
      'mazoezi',
      'afya',
      'ustawi',
      'afya ya akili',
      'huzuni',
      'wasiwasi',
      'msongo wa mawazo',
      'usingizi',
      'uchovu',
      'kichefuchefu',
      'kikohozi',
      'mafua',
      'homa ya mafua',
      'maambukizo',
      'jeraha',
      'kidonda',
      'kutokwa na damu',
      'kisukari',
      'shinikizo la damu',
      'saratani',
      'moyo',
      'mapafu',
      'figo',
      'ujauzito',
      'kujifungua',
      'mtoto',
      'mzee',
      'chanjo',
      'kinga',
      'uzuiaji',
      'uchunguzi',
      'upimaji',
      'mtihani',
      'maabara',
    ],
  };

  // Non-health keywords to reject (English and Swahili)
  static const Map<SupportedLanguage, List<String>> _nonHealthKeywords = {
    SupportedLanguage.english: [
      'politics',
      'sports',
      'entertainment',
      'weather',
      'business',
      'travel',
      'cooking',
      'recipe',
      'shopping',
      'technology',
      'software',
      'programming',
      'gaming',
      'movie',
      'music',
      'celebrity',
      'news',
      'finance',
      'investment',
      'stock',
      'cryptocurrency',
      'fashion',
    ],
    SupportedLanguage.swahili: [
      'siasa',
      'michezo',
      'burudani',
      'hali ya hewa',
      'biashara',
      'usafiri',
      'kupika',
      'mapishi',
      'ununuzi',
      'teknolojia',
      'programu',
      'uprogramu',
      'michezo ya kompyuta',
      'filamu',
      'muziki',
      'mashuhuri',
      'habari',
      'fedha',
      'uwekezaji',
      'hisa',
      'sarafu ya dijiti',
      'mitindo',
    ],
  };

  // Emergency keywords (English and Swahili)
  static const Map<SupportedLanguage, List<String>> _emergencyKeywords = {
    SupportedLanguage.english: [
      'chest pain',
      'can\'t breathe',
      'severe bleeding',
      'unconscious',
      'overdose',
      'suicide',
      'heart attack',
      'stroke',
      'emergency',
      'dying',
      'severe injury',
      'choking',
      'poisoning',
      'seizure',
    ],
    SupportedLanguage.swahili: [
      'maumivu ya kifua',
      'sipati hewa',
      'kutokwa damu nyingi',
      'kuzimia',
      'pumu za dawa',
      'kujiua',
      'shambulizi la moyo',
      'kiharusi',
      'dharura',
      'kufa',
      'jeraha kali',
      'kunyang\'anya',
      'sumu',
      'kifafa',
    ],
  };

  // System prompts for different languages
  static const Map<SupportedLanguage, String> _healthSystemPrompts = {
    SupportedLanguage.english: '''
You are a health information assistant designed exclusively for health and medical topics. Your role is to:

SCOPE - Only discuss:
- General health information and wellness
- Common symptoms and their potential causes
- Preventive care and healthy lifestyle advice
- Basic information about medical conditions
- Mental health and wellness
- Nutrition and fitness guidance
- Public health information

RESTRICTIONS:
- Never provide specific medical diagnoses
- Never recommend specific medications or dosages
- Never suggest stopping prescribed medications
- Always recommend consulting healthcare professionals for medical concerns
- Decline to discuss non-health topics politely
- Include medical disclaimers when appropriate

SAFETY:
- For emergencies, immediately direct to emergency services
- Always emphasize the importance of professional medical consultation
- Provide general information only, not personalized medical advice

LANGUAGE: Respond in English unless the user asks in Swahili, then respond in Swahili.

If asked about non-health topics, respond: "I'm specialized in health information only. How can I help you with a health-related question today?"

Always end health-related responses with: "⚠️ This information is for educational purposes only. Please consult with a healthcare professional for personalized medical advice."
''',
    SupportedLanguage.swahili: '''
Wewe ni msaidizi wa maelezo ya afya uliyeundwa hasa kwa mada za afya na matibabu. Jukumu lako ni:

MIPAKA - Jadili tu:
- Maelezo ya jumla ya afya na ustawi
- Dalili za kawaida na sababu zake zinazowezekana
- Huduma za kuzuia na ushauri wa maisha mazuri
- Maelezo ya msingi kuhusu hali za kimatibabu
- Afya ya akili na ustawi
- Mwongozo wa lishe na mazoezi
- Maelezo ya afya ya umma

VIKWAZO:
- Usitoe utambuzi mahususi wa kimatibabu
- Usipendekeze dawa mahususi au kipimo
- Usishauri kuacha dawa zilizoandikwa
- Daima pendekeza kushauriana na wataalamu wa afya kwa wasiwasi wa kimatibabu
- Kataa kujadili mada zisizo za afya kwa upole
- Jumuisha onyo la kimatibabu linapofaa

USALAMA:
- Kwa dharura, elekeza moja kwa moja kwa huduma za dharura
- Daima sisitiza umuhimu wa kushauriana na mtaalamu wa kimatibabu
- Toa maelezo ya jumla tu, sio ushauri wa kibinafsi wa kimatibabu

LUGHA: Jibu kwa Kiswahili isipokuwa mtumiaji anauliza kwa Kiingereza, basi jibu kwa Kiingereza.

Ikiwa utaulizwa kuhusu mada zisizo za afya, jibu: "Mimi ni mtaalamu wa maelezo ya afya tu. Nawezaje kukusaidia na swali la kihusika na afya leo?"

Daima malizia majibu yanayohusiana na afya na: "⚠️ Maelezo haya ni kwa madhumuni ya kielimu tu. Tafadhali shauriana na mtaalamu wa afya kwa ushauri wa kibinafsi wa kimatibabu."
''',
  };

  // Response templates for different scenarios
  static const Map<String, Map<SupportedLanguage, String>> _responseTemplates =
      {
        'emergency': {
          SupportedLanguage.english: '''
🚨 MEDICAL EMERGENCY DETECTED 🚨

This sounds like a medical emergency. Please:
- Call emergency services immediately (999, 112, or your local emergency number)
- Go to the nearest hospital emergency room
- Contact your doctor immediately

Do not wait for online information in emergency situations.
''',
          SupportedLanguage.swahili: '''
🚨 DHARURA YA KIMATIBABU IMEGUNDULIWA 🚨

Hii inaonekana kama dharura ya kimatibabu. Tafadhali:
- Piga simu huduma za dharura mara moja (999, 112, au nambari ya dharura ya eneo lako)
- Nenda chumba cha dharura cha hospitali iliyo karibu
- Wasiliana na daktari wako mara moja

Usisubiri maelezo ya mtandaoni katika hali za dharura.
''',
        },
        'off_topic': {
          SupportedLanguage.english: '''
I'm designed specifically to provide health and medical information only. I can help you with:

• General health questions
• Information about symptoms
• Wellness and prevention tips
• Mental health support
• Nutrition and fitness guidance
• Understanding medical conditions

How can I help you with a health-related question today?
''',
          SupportedLanguage.swahili: '''
Nimeundwa hasa kutoa maelezo ya afya na matibabu tu. Naweza kukusaidia na:

• Maswali ya jumla ya afya
• Maelezo kuhusu dalili
• Vidokezo vya ustawi na kuzuia
• Msaada wa afya ya akili
• Mwongozo wa lishe na mazoezi
• Kuelewa hali za kimatibabu

Nawezaje kukusaidia na swali la kihusika na afya leo?
''',
        },
        'unsafe_response': {
          SupportedLanguage.english: '''
I understand you're looking for health information, but I need to be careful about providing specific medical advice. 

For your safety, I recommend:
• Consulting with a healthcare professional
• Contacting your doctor or clinic
• Visiting a medical facility if you have urgent concerns

Is there general health information I can help you with instead?

⚠️ Always consult healthcare professionals for medical concerns.
''',
          SupportedLanguage.swahili: '''
Naelewa unatafuta maelezo ya afya, lakini nahitaji kuwa mwangalifu kutoa ushauri maalum wa kimatibabu.

Kwa usalama wako, napendekeza:
• Kushauriana na mtaalamu wa afya
• Kuwasiliana na daktari wako au kliniki
• Kutembelea kituo cha matibabu ikiwa una wasiwasi wa haraka

Je, kuna maelezo ya jumla ya afya ambayo naweza kukusaidia badala yake?

⚠️ Daima shauriana na wataalamu wa afya kwa wasiwasi wa kimatibabu.
''',
        },
      };

  // Disclaimers for different languages
  static const Map<SupportedLanguage, String> _disclaimers = {
    SupportedLanguage.english:
        '\n\n⚠️ This information is for educational purposes only. Please consult with a healthcare professional for personalized medical advice.',
    SupportedLanguage.swahili:
        '\n\n⚠️ Maelezo haya ni kwa madhumuni ya kielimu tu. Tafadhali shauriana na mtaalamu wa afya kwa ushauri wa kibinafsi wa kimatibabu.',
  };

  MedAlpacaService(this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_healthSystemPrompts[currentLanguage]!),
    );
  }

  /// Detect language from user input
  SupportedLanguage _detectLanguage(String input) {
    final inputLower = input.toLowerCase();

    // Count Swahili words
    int swahiliCount = 0;
    for (String word in _healthKeywords[SupportedLanguage.swahili]!) {
      if (inputLower.contains(word)) swahiliCount++;
    }
    for (String word in _nonHealthKeywords[SupportedLanguage.swahili]!) {
      if (inputLower.contains(word)) swahiliCount++;
    }

    // Count English words
    int englishCount = 0;
    for (String word in _healthKeywords[SupportedLanguage.english]!) {
      if (inputLower.contains(word)) englishCount++;
    }
    for (String word in _nonHealthKeywords[SupportedLanguage.english]!) {
      if (inputLower.contains(word)) englishCount++;
    }

    // Common Swahili indicators
    List<String> swahiliIndicators = [
      'nina',
      'nimepata',
      'niko',
      'naomba',
      'nataka',
      'je',
      'nini',
      'vipi',
      'namna gani',
      'kwa nini',
      'lini',
      'wapi',
    ];

    for (String indicator in swahiliIndicators) {
      if (inputLower.contains(indicator)) swahiliCount += 2;
    }

    return swahiliCount > englishCount
        ? SupportedLanguage.swahili
        : SupportedLanguage.english;
  }

  /// Set language manually
  void setLanguage(SupportedLanguage language) {
    currentLanguage = language;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_healthSystemPrompts[language]!),
    );
  }

  /// Check if the input is health-related
  bool _isHealthRelated(String input, SupportedLanguage language) {
    final inputLower = input.toLowerCase();

    // Check for health keywords in detected language
    int healthScore = 0;
    for (String keyword in _healthKeywords[language]!) {
      if (inputLower.contains(keyword)) {
        healthScore++;
      }
    }

    // Check for non-health keywords in detected language
    int nonHealthScore = 0;
    for (String keyword in _nonHealthKeywords[language]!) {
      if (inputLower.contains(keyword)) {
        nonHealthScore++;
      }
    }

    // If no keywords found, assume it might be health-related for safety
    if (healthScore == 0 && nonHealthScore == 0) {
      return true;
    }

    // Return true if more health keywords than non-health keywords
    return healthScore >= nonHealthScore;
  }

  /// Check if the input indicates a medical emergency
  bool _isEmergency(String input, SupportedLanguage language) {
    final inputLower = input.toLowerCase();
    return _emergencyKeywords[language]!.any(
      (keyword) => inputLower.contains(keyword),
    );
  }

  /// Validate if the response is safe and appropriate
  bool _isResponseSafe(String response) {
    final responseLower = response.toLowerCase();

    // Dangerous phrases in both languages
    const dangerousPhrases = [
      // English
      'you definitely have', 'i diagnose you with', 'take this medication',
      'stop your medication', 'don\'t see a doctor', 'this will cure',
      'you don\'t need a doctor',
      // Swahili
      'una hakika', 'nakutambua na', 'chukua dawa hii',
      'acha dawa yako', 'usimwone daktari', 'hii itaponya',
      'huhitaji daktari',
    ];

    return !dangerousPhrases.any((phrase) => responseLower.contains(phrase));
  }

  /// Add medical disclaimer if needed
  String _addDisclaimerIfNeeded(String response, SupportedLanguage language) {
    final disclaimer = _disclaimers[language]!;

    // Check if response already has a disclaimer
    if (response.contains('⚠️') ||
        response.toLowerCase().contains('disclaimer') ||
        response.toLowerCase().contains('onyo')) {
      return response;
    }

    // Add disclaimer for health-related responses
    if (_containsHealthContent(response)) {
      return response + disclaimer;
    }

    return response;
  }

  /// Check if response contains health content requiring disclaimer
  bool _containsHealthContent(String response) {
    const healthIndicators = [
      // English
      'symptom', 'treatment', 'condition', 'diagnosis',
      'medication', 'therapy', 'disease', 'health',
      // Swahili
      'dalili', 'matibabu', 'hali', 'utambuzi',
      'dawa', 'tiba', 'ugonjwa', 'afya',
    ];

    final responseLower = response.toLowerCase();
    return healthIndicators.any(
      (indicator) => responseLower.contains(indicator),
    );
  }

  /// Main method to get chat response with health filtering and language support
  Future<String> getChatResponse(String userInput) async {
    try {
      // Step 1: Detect language
      SupportedLanguage detectedLanguage = _detectLanguage(userInput);

      // Step 2: Update model if language changed
      if (detectedLanguage != currentLanguage) {
        setLanguage(detectedLanguage);
      }

      // Step 3: Check for emergency
      if (_isEmergency(userInput, detectedLanguage)) {
        return _responseTemplates['emergency']![detectedLanguage]!;
      }

      // Step 4: Check if input is health-related
      if (!_isHealthRelated(userInput, detectedLanguage)) {
        return _responseTemplates['off_topic']![detectedLanguage]!;
      }

      // Step 5: Generate response from Gemini with language instruction
      String languageInstruction =
          detectedLanguage == SupportedLanguage.swahili
              ? "Jibu kwa Kiswahili: "
              : "Respond in English: ";

      final response = await _model.generateContent([
        Content.text(languageInstruction + userInput),
      ]);

      String generatedResponse =
          response.text ??
          (detectedLanguage == SupportedLanguage.swahili
              ? "Samahani, sikuweza kutoa jibu. Tafadhali jaribu kuuliza swali lako la afya kwa namna nyingine."
              : "I'm sorry, I couldn't generate a response. Please try rephrasing your health question.");

      // Step 6: Validate response safety
      if (!_isResponseSafe(generatedResponse)) {
        return _responseTemplates['unsafe_response']![detectedLanguage]!;
      }

      // Step 7: Add disclaimer if needed
      generatedResponse = _addDisclaimerIfNeeded(
        generatedResponse,
        detectedLanguage,
      );

      return generatedResponse;
    } catch (e) {
      return currentLanguage == SupportedLanguage.swahili
          ? '''
Samahani, nilipata hitilafu wakati wa kuchakata swali lako la afya.

Hitilafu: ${e.toString()}

Tafadhali jaribu tena, au zamu:
• Kuuliza swali lako kwa njia nyingine
• Kushauriana na mtaalamu wa afya kwa wasiwasi wa kimatibabu
• Kuwasiliana na msaada wa kiufundi ikiwa tatizo litaendelea

⚠️ Kwa mambo ya haraka ya afya, tafadhali wasiliana na mtoa huduma za afya moja kwa moja.
'''
          : '''
I apologize, but I encountered an error while processing your health question.

Error: ${e.toString()}

Please try again, or consider:
• Rephrasing your question
• Consulting with a healthcare professional for medical concerns
• Contacting technical support if the problem persists

⚠️ For urgent health matters, please contact your healthcare provider directly.
''';
    }
  }

  /// Get current language
  SupportedLanguage getCurrentLanguage() => currentLanguage;

  /// Additional method for checking if a topic is health-related (utility)
  bool isHealthTopic(String topic, {SupportedLanguage? language}) {
    language ??= _detectLanguage(topic);
    return _isHealthRelated(topic, language);
  }

  /// Method to get health categories for UI purposes
  static Map<SupportedLanguage, List<String>> getHealthCategories() {
    return {
      SupportedLanguage.english: [
        'General Health',
        'Symptoms & Conditions',
        'Mental Health',
        'Nutrition & Diet',
        'Exercise & Fitness',
        'Preventive Care',
        'Women\'s Health',
        'Men\'s Health',
        'Child Health',
        'Senior Health',
      ],
      SupportedLanguage.swahili: [
        'Afya ya Jumla',
        'Dalili na Hali',
        'Afya ya Akili',
        'Lishe na Chakula',
        'Mazoezi na Afya',
        'Huduma za Kuzuia',
        'Afya ya Wanawake',
        'Afya ya Wanaume',
        'Afya ya Watoto',
        'Afya ya Wazee',
      ],
    };
  }

  /// Method to get sample health questions for UI
  static Map<SupportedLanguage, List<String>> getSampleHealthQuestions() {
    return {
      SupportedLanguage.english: [
        'What are the symptoms of common cold?',
        'How can I improve my sleep quality?',
        'What are healthy eating habits?',
        'How much exercise should I do daily?',
        'What are signs of dehydration?',
        'How can I manage stress effectively?',
        'What are preventive measures for heart disease?',
        'How can I boost my immune system?',
      ],
      SupportedLanguage.swahili: [
        'Dalili za homa ya kawaida ni zipi?',
        'Ninawezaje kuboresha ubora wa usingizi wangu?',
        'Tabia za chakula chenye afya ni zipi?',
        'Ni mazoezi mangapi yapaswa nifanye kila siku?',
        'Dalili za ukosefu wa maji mwilini ni zipi?',
        'Ninawezaje kushughulika na msongo wa mawazo kwa ufanisi?',
        'Hatua za kuzuia ni zipi kwa magonjwa ya moyo?',
        'Ninawezaje kuimarisha mfumo wa kinga wa mwili wangu?',
      ],
    };
  }
}
