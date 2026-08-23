import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

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
    'Where is my order',
    'Explain delay on Siliguri corridor',
    'Inventory replenishment recommendation',
    'Supplier compliance report summary',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(const _ChatMessage(
      text: 'Hi, I am SupplyChainX Logistics Assistant. How can I help you today?',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true));
      _isTyping = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.post(
        ApiEndpoints.aiChat,
        data: {'message': trimmed},
      );

      if (!mounted) return;

      if (response != null && response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final replyText = data['reply'] as String? ?? 'No response generated.';
        final referencedProds = (data['referenced_products'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final suggestedActs = (data['suggested_actions'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final isGrounded = data['grounded_in_ledger'] as bool? ?? false;
        final predData = data['prediction'] as Map<String, dynamic>?;

        setState(() {
          _messages.add(_ChatMessage(
            text: replyText,
            isUser: false,
            referencedProducts: referencedProds,
            suggestedActions: suggestedActs,
            isGroundedInLedger: isGrounded,
            prediction: predData,
          ));
          _isTyping = false;
        });
      } else {
        setState(() {
          _messages.add(const _ChatMessage(
            text: '⚠️ Unable to connect to backend GenAI service. Please verify that the backend server is running on http://localhost:8000.',
            isUser: false,
          ));
          _isTyping = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: '⚠️ Network connection error: $e',
          isUser: false,
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
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
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SupplyX AI Operations Assistant (Live GenAI + RAG)',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                      ),
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
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!m.isUser) ...[
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 820),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: m.isUser ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: m.isUser ? null : Border.all(color: AppColors.cardBorder),
                                boxShadow: [
                                  if (!m.isUser)
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (m.isGroundedInLedger) ...[
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.successLight,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.successBorder),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified_outlined, size: 13, color: AppColors.success),
                                          const SizedBox(width: 5),
                                          Text(
                                            'GROUNDED IN BLOCKCHAIN LEDGER',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  _MarkdownRenderer(
                                    text: m.text,
                                    isUser: m.isUser,
                                  ),
                                  if (m.prediction != null) ...[
                                    const SizedBox(height: 12),
                                    _MLPredictionCard(pred: m.prediction!),
                                  ],
                                ],
                              ),
                            ),

                            // Suggested action chips
                            if (m.suggestedActions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: m.suggestedActions.map((action) {
                                  return ActionChip(
                                    avatar: const Icon(Icons.arrow_outward_rounded, size: 12, color: AppColors.primaryBorder),
                                    label: Text(
                                      action,
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                    ),
                                    backgroundColor: AppColors.surface,
                                    side: const BorderSide(color: AppColors.cardBorderStrong),
                                    onPressed: () => _send(action),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Typing Indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Querying live blockchain ledger & running ML delay model...',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
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
                    height: 40,
                    child: TextField(
                      controller: _inputCtrl,
                      style: GoogleFonts.inter(fontSize: 13),
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: 'Ask about any consignment, route delays, inventory rules, or policies...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _send(_inputCtrl.text),
                  icon: const Icon(Icons.send_rounded, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual ML Delivery Prediction & SHAP Analysis Card
class _MLPredictionCard extends StatelessWidget {
  final Map<String, dynamic> pred;

  const _MLPredictionCard({required this.pred});

  @override
  Widget build(BuildContext context) {
    final expTime = pred['expected_delivery_time_minutes'] ?? pred['estimated_delay_hours'];
    final baseTime = pred['baseline_time_minutes'];
    final isDelayed = pred['is_delayed'] as bool? ?? (pred['risk_level'] == 'High' || pred['risk_level'] == 'Critical');
    final delayMin = pred['delay_minutes'] ?? pred['estimated_delay_hours'] ?? 0;
    final riskLevel = pred['risk_level'] as String? ?? (isDelayed ? 'Delayed' : 'On-Time');
    final reasons = (pred['reasons'] as List?) ?? [];
    final action = pred['recommended_action'] as String?;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDelayed ? AppColors.warning.withValues(alpha: 0.4) : AppColors.success.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: isDelayed ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                'ML Transit Prediction (Random Forest + SHAP)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDelayed ? AppColors.warningLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDelayed ? AppColors.warningBorder : AppColors.successBorder,
                  ),
                ),
                child: Text(
                  isDelayed ? 'DELAY RISK: $riskLevel' : 'ON-TIME (NOMINAL)',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isDelayed ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Expected Duration',
                  expTime != null ? '$expTime min' : 'N/A',
                  Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 8),
              if (baseTime != null)
                Expanded(
                  child: _buildMetricTile(
                    'Category Baseline',
                    '$baseTime min',
                    Icons.speed_outlined,
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Delay Variance',
                  isDelayed ? '+$delayMin min' : '0 min',
                  Icons.trending_up_rounded,
                  highlight: isDelayed,
                ),
              ),
            ],
          ),

          // SHAP Reasons Breakdown
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'SHAP Feature Attribution (Root Causes):',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            ...reasons.map((r) {
              final fName = r['feature']?.toString() ?? 'Factor';
              final fVal = r['value']?.toString() ?? '';
              final fImpact = r['impact_minutes']?.toString() ?? '0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      '$fName: ${fVal.isNotEmpty ? fVal : "impact"}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '+$fImpact min',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Recommended Action
          if (action != null && action.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.primaryBorder),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Action: $action',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String val, IconData icon, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.warning : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rich Markdown Block & Inline Formatter
class _MarkdownRenderer extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MarkdownRenderer({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return SelectableText(
        text,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.4),
      );
    }

    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final trimmed = rawLine.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Horizontal rule
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: AppColors.cardBorder, height: 1),
        ));
        continue;
      }

      // Heading 1 / 2 / 3
      if (trimmed.startsWith('### ')) {
        final content = trimmed.substring(4).replaceAll('**', '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            content,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ));
        continue;
      } else if (trimmed.startsWith('## ')) {
        final content = trimmed.substring(3).replaceAll('**', '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(
            content,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ));
        continue;
      } else if (trimmed.startsWith('# ')) {
        final content = trimmed.substring(2).replaceAll('**', '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            content,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ));
        continue;
      }

      // Numbered List (e.g. "1. ", "2. ")
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        final numStr = numMatch.group(1)!;
        final content = numMatch.group(2)!;
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(right: 8, top: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  numStr,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBorder,
                  ),
                ),
              ),
              Expanded(
                child: _buildRichInline(content, 13, AppColors.textPrimary),
              ),
            ],
          ),
        ));
        continue;
      }

      // Bullet List (e.g. "• ", "* ", "- ")
      if (trimmed.startsWith('• ') || trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
        final content = trimmed.substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 8, top: 7),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: _buildRichInline(content, 13, AppColors.textPrimary),
              ),
            ],
          ),
        ));
        continue;
      }

      // Standard Paragraph
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _buildRichInline(trimmed, 13, AppColors.textPrimary),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichInline(String text, double fontSize, Color defaultColor) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*.*?\*\*|`.*?`|\*.*?\*)');
    int lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: GoogleFonts.inter(color: defaultColor, fontSize: fontSize, height: 1.45),
        ));
      }

      final matchedStr = match.group(0)!;
      if (matchedStr.startsWith('**') && matchedStr.endsWith('**')) {
        spans.add(TextSpan(
          text: matchedStr.substring(2, matchedStr.length - 2),
          style: GoogleFonts.inter(
            color: defaultColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
        ));
      } else if (matchedStr.startsWith('`') && matchedStr.endsWith('`')) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              matchedStr.substring(1, matchedStr.length - 1),
              style: GoogleFonts.jetBrainsMono(
                fontSize: fontSize - 1.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBorder,
              ),
            ),
          ),
        ));
      } else if (matchedStr.startsWith('*') && matchedStr.endsWith('*')) {
        spans.add(TextSpan(
          text: matchedStr.substring(1, matchedStr.length - 1),
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: fontSize,
            fontStyle: FontStyle.italic,
            height: 1.45,
          ),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: GoogleFonts.inter(color: defaultColor, fontSize: fontSize, height: 1.45),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<String> referencedProducts;
  final List<String> suggestedActions;
  final bool isGroundedInLedger;
  final Map<String, dynamic>? prediction;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.referencedProducts = const [],
    this.suggestedActions = const [],
    this.isGroundedInLedger = false,
    this.prediction,
  });
}
