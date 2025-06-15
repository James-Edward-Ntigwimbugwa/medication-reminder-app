import 'package:flutter/material.dart';
import 'package:doziyangu/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/medalpaca_service.dart';

// Interface for HealthInfoScreen state
abstract class HealthInfoScreenState {
  void openChatbotModal();
}

class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen>
    implements HealthInfoScreenState {
  static const String geminiApiKey = "AIzaSyBj0RhCf6KN1avAd39KXX_HfQwQo4-5TsY";
  final medAlpacaService = MedAlpacaService(geminiApiKey);

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

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

  Widget _buildHealthCard({
    required String title,
    required String description,
    required String url,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () => _launchURL(url),
                child: Text(l10n.learnMore),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      children: [
        const SizedBox(height: 10),
        _buildHealthCard(
          title: l10n.commonHealthTips,
          description: l10n.exploreDailyPractices,
          url: "https://www.who.int/news-room/fact-sheets/detail/healthy-diet",
          context: context,
        ),
        _buildHealthCard(
          title: '${l10n.lisheBora}\n${l10n.nutrition}',
          description: l10n.understandNutritionImportance,
          url: "https://www.who.int/health-topics/nutrition",
          context: context,
        ),
        _buildHealthCard(
          title: l10n.mentalHealth,
          description: l10n.mentalWellBeing,
          url: "https://www.who.int/health-topics/mental-health",
          context: context,
        ),
        _buildHealthCard(
          title: l10n.maternalChildHealth,
          description: l10n.maternalChildGuidance,
          url: "https://www.unicef.org/health",
          context: context,
        ),
        _buildHealthCard(
          title: l10n.diseasePrevention,
          description: l10n.protectFromDiseases,
          url: "https://www.cdc.gov/globalhealth/index.html",
          context: context,
        ),
        const SizedBox(height: 90),
      ],
    );
  }
}

class ChatbotWidget extends StatefulWidget {
  final MedAlpacaService medAlpacaService;
  const ChatbotWidget({required this.medAlpacaService, super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  void _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _loading) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': query});
      _controller.clear();
      _loading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final response = await widget.medAlpacaService.getChatResponse(query);
      setState(() {
        _messages.add({'sender': 'bot', 'text': response});
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 50,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

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
