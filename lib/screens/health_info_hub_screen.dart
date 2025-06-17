// Imports necessary packages for Flutter UI, localization, URL launching, and app-specific services.
import 'package:flutter/material.dart';
import 'package:doziyangu/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/medalpaca_service.dart';

// Abstract interface defining required methods for HealthInfoScreen state.
abstract class HealthInfoScreenState {
  // Opens the chatbot modal bottom sheet.
  void openChatbotModal();
}

// Stateless widget serving as the entry point for the Health Information screen.
class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  // Creates the state object for this widget.
  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

// State class managing UI state and interactions for HealthInfoScreen.
class _HealthInfoScreenState extends State<HealthInfoScreen>
    implements HealthInfoScreenState {
  // API key for MedAlpaca service (Note: Hardcoding keys is not recommended for production).
  static const String geminiApiKey = "AIzaSyBj0RhCf6KN1avAd39KXX_HfQwQo4-5TsY";
  // Instance of MedAlpacaService for chatbot functionality.
  final medAlpacaService = MedAlpacaService(geminiApiKey);

  // Launches an external URL in the browser.
  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  // Displays the chatbot modal bottom sheet.
  @override
  void openChatbotModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ChatbotWidget(medAlpacaService: medAlpacaService);
      },
    );
  }

  // Builds a health information card with expandable content and learn more link.
  Widget _buildHealthCard({
    required String title,
    required String description,
    required String extendedContent,
    required String url,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.teal.shade50, // Soft teal for health-related aesthetic.
      child: ExpansionTile(
        leading: Icon(Icons.info_outline, color: Colors.teal.shade600),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: Colors.black87),
          ),
        ),
        trailing: Icon(Icons.expand_more, color: Colors.teal.shade600),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extendedContent,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      // Show dialog with all card content before navigating to URL.
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              backgroundColor: Colors.teal.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      description,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      extendedContent,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    l10n.cancel,
                                    style: TextStyle(
                                      color: Colors.teal.shade600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _launchURL(url);
                                  },
                                  child: Text(
                                    l10n.learnMore,
                                    style: TextStyle(
                                      color: Colors.teal.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                    child: Text(
                      l10n.learnMore,
                      style: TextStyle(color: Colors.teal.shade600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Constructs the UI for the Health Information screen.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Alice Blue for consistency.
      appBar: AppBar(
        elevation: 0, // Flat design for modern look.
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF0F8FF), // Alice Blue.
                Color(0xFFE6F3FF), // Light Sky Blue.
              ],
            ),
          ),
        ),
        foregroundColor: Colors.grey.shade800,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.health_and_safety,
                color: Colors.teal.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.healthInfo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C5F41), // Dark green for consistency.
              ),
            ),
          ],
        ),
        actions: const [], // No chatbot button as per request.
      ),
      body: Container(
        // Gradient background matching AddMedicationScreen.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F8FF), // Alice Blue.
              Color(0xFFE6F3FF), // Light Sky Blue.
              Color(0xFFF5F9FF), // Very Light Blue.
            ],
          ),
        ),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            _buildHealthCard(
              title: l10n.commonHealthTips,
              description: l10n.exploreDailyPractices,
              extendedContent: '''
Stay healthy with these daily habits:
Hydration: Drink 8-10 glasses of water daily to support bodily functions.
Exercise: Aim for 30 minutes of moderate activity, like walking or yoga, 5 days a week.
Sleep: Get 7-8 hours of quality sleep to boost immunity and mental clarity.
Balanced Diet: Eat a variety of fruits, vegetables, lean proteins, and whole grains.
Stress Management: Practice deep breathing or journaling to reduce stress.
              ''',
              url:
                  "https://www.who.int/news-room/fact-sheets/detail/healthy-diet",
              context: context,
            ),
            _buildHealthCard(
              title: '${l10n.lisheBora}\n${l10n.nutrition}',
              description: l10n.understandNutritionImportance,
              extendedContent: '''
Nutrition is key to a healthy life:
Fruits and Vegetables: Aim for 5 servings daily for essential vitamins and minerals.
Whole Grains: Choose brown rice, quinoa, or whole wheat over refined grains.
Protein: Include lean sources like fish, beans, or poultry to support muscle health.
Healthy Fats: Opt for avocados, nuts, and olive oil; avoid trans fats.
Limit Sugar and Salt: Reduce sugary drinks and processed foods to prevent chronic diseases.
              ''',
              url: "https://www.who.int/health-topics/nutrition",
              context: context,
            ),
            _buildHealthCard(
              title: l10n.mentalHealth,
              description: l10n.mentalWellBeing,
              extendedContent: '''
Support your mental well-being with these practices:
Mindfulness: Spend 10 minutes daily meditating to improve focus and reduce anxiety.
Social Connections: Stay in touch with friends and family for emotional support.
Physical Activity: Exercise releases endorphins, boosting mood.
Professional Help: Seek a counselor if feeling persistently sad or overwhelmed.
Hobbies: Engage in activities like reading or gardening for relaxation.
              ''',
              url: "https://www.who.int/health-topics/mental-health",
              context: context,
            ),
            _buildHealthCard(
              title: l10n.maternalChildHealth,
              description: l10n.maternalChildGuidance,
              extendedContent: '''
Care for mothers and children:
Prenatal Care: Attend regular checkups to\n monitor maternal and fetal health.
Breastfeeding: Exclusive breastfeeding\n for 6 months supports infant immunity.
Vaccinations: Follow immunization schedules\n to protect children from diseases.
Nutrition: Provide nutrient-rich foods\n for both mother and child.
Safe Environment: Ensure a clean,\n safe home to prevent accidents and infections.
              ''',
              url: "https://www.unicef.org/health",
              context: context,
            ),
            _buildHealthCard(
              title: l10n.diseasePrevention,
              description: l10n.protectFromDiseases,
              extendedContent: '''
Prevent diseases with these steps:
Hygiene: Wash hands with soap for 20 seconds,\n especially before eating and in every moments like after work .

Vaccinations: Stay updated on vaccines like flu, HPV, and COVID-19.

Healthy Lifestyle: Avoid smoking and limit alcohol to reduce disease risk.

Screenings: Regular health checkups detect issues early.

Safe Practices: Use masks and social distancing during outbreaks.
              ''',
              url: "https://www.cdc.gov/globalhealth/index.html",
              context: context,
            ),
            const SizedBox(
              height: 90,
            ), // Space to avoid overlap with navigation.
          ],
        ),
      ),
    );
  }
}

// Stateful widget for the chatbot modal interface.
class ChatbotWidget extends StatefulWidget {
  final MedAlpacaService medAlpacaService;
  const ChatbotWidget({required this.medAlpacaService, super.key});

  // Creates the state object for this widget.
  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

// State class managing chatbot conversation and UI state.
class _ChatbotWidgetState extends State<ChatbotWidget> {
  // Controller for the chat input field.
  final TextEditingController _controller = TextEditingController();
  // Controller for scrolling the chat list.
  final ScrollController _scrollController = ScrollController();
  // List storing chat messages with sender and text.
  final List<Map<String, String>> _messages = [];
  // Tracks loading state during API calls.
  bool _loading = false;

  // Sends user message to MedAlpacaService and updates chat.
  void _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _loading) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': query});
      _controller.clear();
      _loading = true;
    });

    // Scrolls to bottom after UI update.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      // Fetches response from MedAlpacaService.
      final response = await widget.medAlpacaService.getChatResponse(query);
      setState(() {
        _messages.add({'sender': 'bot', 'text': response});
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      // Handles errors by displaying them in chat.
      setState(() {
        _messages.add({'sender': 'bot', 'text': 'Error: ${e.toString()}'});
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Scrolls the chat list to the latest message.
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 50,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Builds a message bubble for user or bot messages.
  Widget _buildMessageBubble(String sender, String text) {
    final isUser = sender == 'user';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.teal : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // Constructs the UI for the chatbot modal.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                l10n.chatWithHealthAssistant,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              // Chat message list.
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg['sender']!, msg['text']!);
                  },
                ),
              ),
              const Divider(),
              // Input field and send button.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: l10n.typeYourMessage,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _loading
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : IconButton(
                          icon: const Icon(Icons.send, color: Colors.teal),
                          onPressed: _sendMessage,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
