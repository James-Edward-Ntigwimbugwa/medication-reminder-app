// Updated Chatbot to ensure scroll-to-bottom works after response
// Added: Settings icon removed and AppBar styled with only one title and subtitle
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/medalpaca_service.dart';

class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  static const String geminiApiKey = "AIzaSyBj0RhCf6KN1avAd39KXX_HfQwQo4-5TsY";
  final medAlpacaService = MedAlpacaService(geminiApiKey);

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Widget _buildHealthCard({
    required String title,
    required String description,
    required String url,
    required BuildContext context,
  }) {
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
                child: const Text("Learn More"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatbotModal() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Colors.teal,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 8.0),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    "Health Information Hub",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Jua Afya Yako",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 10),
              _buildHealthCard(
                title: "Common Health Tips",
                description:
                    "Explore daily practices to maintain a healthy lifestyle.",
                url:
                    "https://www.who.int/news-room/fact-sheets/detail/healthy-diet",
                context: context,
              ),
              _buildHealthCard(
                title: "Lishe bora\nNutrition",
                description:
                    "Jifunze na kuelewa umuhimu wa lishe bora\n Understand the importance of balanced nutrition.",
                url: "https://www.who.int/health-topics/nutrition",
                context: context,
              ),
              _buildHealthCard(
                title: "Mental Health",
                description:
                    "Learn about mental well-being and stress management.",
                url: "https://www.who.int/health-topics/mental-health",
                context: context,
              ),
              _buildHealthCard(
                title: "Maternal & Child Health",
                description:
                    "Vital guidance for pregnant mothers and children.",
                url: "https://www.unicef.org/health",
                context: context,
              ),
              _buildHealthCard(
                title: "Disease Prevention",
                description: "Protect yourself from malaria, HIV, TB and more.",
                url: "https://www.cdc.gov/globalhealth/index.html",
                context: context,
              ),
              const SizedBox(height: 90),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChatbotModal,
        label: const Text("Chatbot"),
        icon: const Icon(Icons.chat_bubble_outline),
        backgroundColor: Colors.teal,
      ),
    );
  }
}

// ChatbotWidget remains as updated with scroll-to-bottom fix.

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
        _messages.add({'sender': 'bot', 'text': 'Error: \${e.toString()}'});
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
              const Text(
                "Chat with Health Assistant",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        decoration: const InputDecoration(
                          hintText: "Type your message...",
                          border: OutlineInputBorder(),
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
