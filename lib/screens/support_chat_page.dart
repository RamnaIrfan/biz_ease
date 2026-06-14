import 'package:flutter/material.dart';
import '../services/support_agent_service.dart';

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final SupportAgentService _agent = SupportAgentService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Hello! I am your BizEase AI Assistant. How can I help you today?',
      'time': DateTime.now(),
    }
  ];

  static const primaryColor = Color(0xFFD88A1F);

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? quickText]) async {
    final text = quickText ?? _controller.text.trim();
    if (text.isEmpty) return;

    if (quickText == null) _controller.clear();

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _agent.sendMessage(text);
      setState(() {
        _messages.add({
          'isUser': false,
          'text': response,
          'time': DateTime.now(),
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.support_agent, color: primaryColor),
            ),
            SizedBox(width: 12),
            Text('BizEase AI Support'),
          ],
        ),
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _ChatBubble(
                  text: msg['text'],
                  isUser: msg['isUser'],
                  time: msg['time'],
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: primaryColor, backgroundColor: Color(0xFFFFE0B2)),
            ),
          _buildQuickActions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      'Track my order',
      'Cancel an order',
      'Find headphones',
      'Shipping info'
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(actions[index], style: const TextStyle(fontSize: 12)),
              onPressed: () => _handleSend(actions[index]),
              backgroundColor: Colors.grey.shade100,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type your question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime time;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFD88A1F) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
