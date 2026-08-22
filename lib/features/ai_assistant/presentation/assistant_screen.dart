import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

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
    'Where is consignment SCX-00112?',
    'Explain delay on Siliguri corridor',
    'Inventory replenishment recommendation',
    'Supplier compliance report summary',
  ];

  final _responses = {
    'where': 'Consignment SCX-00112 (Organic Rice 5kg) completed transit from Guwahati Manufacturing and was accepted by ABC Retail Store. Current lifecycle status: 4/5 stages verified.',
    'delay': 'Route NH-27 near Siliguri reported monsoon congestion causing a ~1.8 day delay for batch BAT-2026-X102. Recommendation: Dispatch reserve stock from Central Warehouse Kolkata.',
    'replenishment': 'Current stock audit:\n• Darjeeling Tea 250g: 15 packs remaining (below min 40) → Reorder 100 units\n• Cold Pressed Mustard Oil: 10 bottles remaining (below min 25) → Reorder 50 units',
    'supplier': 'Supplier Scorecard (Aug 2026):\n• Guwahati Food Corp: 98.4% on-time\n• Siliguri Logistics Hub: 91.2% on-time (weather impact)\n• Kolkata Central Warehouse: 99.1% on-time',
  };

  @override
  void initState() {
    super.initState();
    _messages.add(const _ChatMessage(
      text: 'SupplyX Logistics Assistant online. How can I assist with consignment tracking, route exceptions, or stock replenishment?',
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

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    String reply = 'Analyzing logistics records for "${text.substring(0, text.length > 30 ? 30 : text.length)}...". Connect production GenAI LLM API for live telemetry querying.';
    final lower = text.toLowerCase();
    if (lower.contains('where') || lower.contains('scx-00112')) {
      reply = _responses['where']!;
    } else if (lower.contains('delay') || lower.contains('siliguri')) {
      reply = _responses['delay']!;
    } else if (lower.contains('replenish') || lower.contains('stock') || lower.contains('inventory')) {
      reply = _responses['replenishment']!;
    } else if (lower.contains('supplier') || lower.contains('report') || lower.contains('scorecard')) {
      reply = _responses['supplier']!;
    }

    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('SupplyX AI Operations Assistant', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Suggestions Strip
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _suggestions[i];
                return Center(
                  child: InkWell(
                    onTap: () => _send(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(s, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!m.isUser) ...[
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(4)),
                          child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: m.isUser ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: m.isUser ? null : Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            m.text,
                            style: GoogleFonts.inter(
                              color: m.isUser ? Colors.white : AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _inputCtrl,
                      style: GoogleFonts.inter(fontSize: 13),
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: 'Inquire about consignments, route delays, inventory...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 38,
                  width: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => _send(_inputCtrl.text),
                    child: const Icon(Icons.send_rounded, size: 16),
                  ),
                ),
              ],
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
