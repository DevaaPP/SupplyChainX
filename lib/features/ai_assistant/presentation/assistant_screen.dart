import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});
  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  final _suggestions = [
    'Where is my order SCX-00112?',
    'Why was shipment delayed?',
    'Recommend inventory replenishment',
    'Generate supplier performance report',
    'What is the status of Darjeeling Tea?',
  ];

  // Canned AI responses for demo
  final _responses = {
    'order': 'Your package SCX-00112 (Organic Rice 5kg) left the Guwahati warehouse at 9:30 AM on Aug 19 and was delivered to ABC Retail Store on Aug 19. The full blockchain-verified journey shows 4 of 5 stages complete. ✓',
    'delay': 'The delay on shipment B-2024-002 was caused by high-demand season at the Siliguri Distribution Center and limited truck availability. I recommend rerouting through Warehouse-3 during peak months (Oct–Dec) to reduce average delay by ~40%.',
    'inventory': 'Based on current stock levels and demand trends, I recommend:\n• Organic Rice 5kg — reorder 500 units (stock: 12, 7-day demand: 45)\n• Darjeeling Tea 250g — reorder 200 units (low season)\n• Mango Pickle — adequate stock for 30 days',
    'report': 'Supplier Performance Report (Aug 2026):\n• XYZ Manufacturing — 98.2% on-time ✓\n• Fast Distributors — 91.4% (slight decline) ⚠\n• Central Warehouse — 99.1% ✓\nOverall supply chain health: 96.2%',
    'status': 'Darjeeling Tea 250g (SCX-00098) is currently with Fast Distributors at Siliguri Distribution Center. It entered the distribution network 2 days ago and is expected to reach the retailer within 3-5 business days.',
  };

  @override
  void initState() {
    super.initState();
    _messages.add(const _ChatMessage(
      text:
          'Hello! I\'m your SupplyChainX AI Assistant. I can help you track orders, analyze delays, generate reports, and optimize your supply chain.\n\nHow can I assist you today?',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Match response
    String reply = 'I understand you\'re asking about "${text.substring(0, text.length > 40 ? 40 : text.length)}...". Let me analyze the supply chain data and get back to you.\n\nFor real-time responses, please connect the GenAI backend API.';
    final lower = text.toLowerCase();
    if (lower.contains('order') || lower.contains('scx-00112') || lower.contains('where')) {
      reply = _responses['order']!;
    } else if (lower.contains('delay') || lower.contains('why')) {
      reply = _responses['delay']!;
    } else if (lower.contains('inventory') || lower.contains('reorder') || lower.contains('recommend')) {
      reply = _responses['inventory']!;
    } else if (lower.contains('report') || lower.contains('supplier') || lower.contains('performance')) {
      reply = _responses['report']!;
    } else if (lower.contains('tea') || lower.contains('status') || lower.contains('darjeeling')) {
      reply = _responses['status']!;
    }

    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Supply Chain Assistant',
                    style: TextStyle(fontSize: 15)),
                Text('Powered by GenAI',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined,
                color: AppColors.textMuted),
            onPressed: () => setState(() {
              _messages.clear();
              _messages.add(const _ChatMessage(
                text: 'Chat cleared. How can I assist you?',
                isUser: false,
              ));
            }),
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Row(
        children: [
          // Suggestions sidebar (wide only)
          if (isWide)
            Container(
              width: 220,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.cardBorder)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Questions',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ..._suggestions.map((s) => GestureDetector(
                        onTap: () => _send(s),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(s,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ),
                      )),
                ],
              ),
            ),
          // Chat area
          Expanded(
            child: Column(
              children: [
                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_isTyping && i == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessage(_messages[i]);
                    },
                  ),
                ),
                // Suggestions row (mobile)
                if (!isWide)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _suggestions.map((s) => GestureDetector(
                            onTap: () => _send(s),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDim,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withOpacity(0.3)),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          )).toList(),
                    ),
                  ),
                const SizedBox(height: 4),
                // Input bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                        top: BorderSide(color: AppColors.cardBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: TextField(
                            controller: _inputCtrl,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 14),
                            maxLines: 1,
                            onSubmitted: _send,
                            decoration: const InputDecoration(
                              hintText: 'Ask about orders, delays, inventory...',
                              hintStyle:
                                  TextStyle(color: AppColors.textMuted),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _send(_inputCtrl.text),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 14),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      Radius.circular(isUser ? 16 : 4),
                  bottomRight:
                      Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.secondaryDim,
              child: const Icon(Icons.person_rounded,
                  color: AppColors.secondary, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [1, 2, 3].map((i) => _TypingDot(delay: i * 200)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, required this.isUser});
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.4 + _ctrl.value * 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
