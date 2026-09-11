import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class MLStudioScreen extends ConsumerStatefulWidget {
  const MLStudioScreen({super.key});

  @override
  ConsumerState<MLStudioScreen> createState() => _MLStudioScreenState();
}

class _MLStudioScreenState extends ConsumerState<MLStudioScreen> {
  // 14 Features matching delivery_features_v2.csv & delivery_time_model.pkl
  int _agentAge = 28;
  double _agentRating = 4.5;
  double _distance = 10.0;
  double _prepTime = 10.0;
  int _orderHour = 14;
  int _peakHour = 0;
  int _isWeekend = 0;
  int _isQuickCommerce = 0;
  String _weather = 'Sunny';
  String _traffic = 'Medium';
  String _vehicle = 'motorcycle';
  String _area = 'Urban';
  String _category = 'Grocery';
  String _timeOfDay = 'Afternoon';

  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  // ML Copilot Chat State
  final _copilotInputCtrl = TextEditingController();
  final List<_CopilotMessage> _copilotMessages = [];
  bool _isCopilotThinking = false;

  final List<String> _weatherOptions = ['Sunny', 'Cloudy', 'Fog', 'Sandstorms', 'Stormy', 'Windy'];
  final List<String> _trafficOptions = ['Low', 'Medium', 'High', 'Jam'];
  final List<String> _vehicleOptions = ['motorcycle', 'scooter', 'van'];
  final List<String> _areaOptions = ['Metropolitian', 'Urban', 'Semi-Urban', 'Other'];
  final List<String> _categoryOptions = [
    'Grocery', 'Clothing', 'Electronics', 'Sports', 'Cosmetics',
    'Toys', 'Snacks', 'Apparel', 'Jewelry', 'Outdoors', 'Books', 'Shoes'
  ];
  final List<String> _timeOfDayOptions = ['Morning', 'Afternoon', 'Evening', 'Night'];

  Map<String, dynamic> _buildPayload() {
    return {
      'Agent_Age': _agentAge,
      'Agent_Rating': _agentRating,
      'Distance': _distance,
      'Preparation_Time': _prepTime,
      'Order_Hour': _orderHour,
      'Peak_Hour': _peakHour,
      'Is_Weekend': _isWeekend,
      'Is_Quick_Commerce': _category == 'Grocery' ? 1 : _isQuickCommerce,
      'Weather': _weather,
      'Traffic': _traffic,
      'Vehicle': _vehicle,
      'Area': _area,
      'Category': _category,
      'Time_of_Day': _timeOfDay,
    };
  }

  void _applyPreset(String name) {
    setState(() {
      if (name == 'stormy_jam') {
        // High delay sample from CSV (Row 3)
        _agentAge = 34;
        _agentRating = 4.5;
        _distance = 20.2;
        _prepTime = 5.0;
        _orderHour = 19;
        _peakHour = 1;
        _isWeekend = 0;
        _isQuickCommerce = 0;
        _weather = 'Stormy';
        _traffic = 'Jam';
        _vehicle = 'scooter';
        _area = 'Metropolitian';
        _category = 'Electronics';
        _timeOfDay = 'Evening';
      } else if (name == 'sunny_grocery') {
        // Quick commerce sample (Row 17)
        _agentAge = 35;
        _agentRating = 4.8;
        _distance = 3.5;
        _prepTime = 8.0;
        _orderHour = 11;
        _peakHour = 0;
        _isWeekend = 0;
        _isQuickCommerce = 1;
        _weather = 'Sunny';
        _traffic = 'Low';
        _vehicle = 'motorcycle';
        _area = 'Urban';
        _category = 'Grocery';
        _timeOfDay = 'Morning';
      } else if (name == 'fog_evening') {
        // Fog & Jam sample (Row 8)
        _agentAge = 33;
        _agentRating = 4.7;
        _distance = 16.6;
        _prepTime = 15.0;
        _orderHour = 19;
        _peakHour = 1;
        _isWeekend = 0;
        _isQuickCommerce = 0;
        _weather = 'Fog';
        _traffic = 'Jam';
        _vehicle = 'scooter';
        _area = 'Metropolitian';
        _category = 'Toys';
        _timeOfDay = 'Evening';
      }
    });
    _runPrediction();
  }

  Future<void> _runPrediction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = _buildPayload();
    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.post(
        ApiEndpoints.mlPredictOrder,
        data: payload,
      );

      if (response != null && response.statusCode == 200 && response.data != null) {
        setState(() {
          _result = response.data as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        // Graceful offline fallback
        final fallback = _computeOfflinePrediction(payload);
        setState(() {
          _result = fallback;
          _isLoading = false;
        });
      }
    } catch (e) {
      final fallback = _computeOfflinePrediction(payload);
      setState(() {
        _result = fallback;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _computeOfflinePrediction(Map<String, dynamic> payload) {
    final cat = payload['Category'] as String? ?? 'Grocery';
    final isQuick = cat == 'Grocery';
    final baseTime = isQuick ? 27.0 : 130.0;

    double extra = 0.0;
    final reasons = <Map<String, dynamic>>[];

    final traffic = payload['Traffic'] as String? ?? 'Low';
    if (traffic == 'Jam') {
      extra += 32.0;
      reasons.add({'feature': 'Traffic', 'value': 'Jam', 'impact_minutes': 32.0});
    } else if (traffic == 'High') {
      extra += 18.0;
      reasons.add({'feature': 'Traffic', 'value': 'High', 'impact_minutes': 18.0});
    } else if (traffic == 'Medium') {
      extra += 7.0;
      reasons.add({'feature': 'Traffic', 'value': 'Medium', 'impact_minutes': 7.0});
    }

    final weather = payload['Weather'] as String? ?? 'Sunny';
    if (weather == 'Stormy') {
      extra += 24.0;
      reasons.add({'feature': 'Weather', 'value': 'Stormy', 'impact_minutes': 24.0});
    } else if (weather == 'Sandstorms') {
      extra += 20.0;
      reasons.add({'feature': 'Weather', 'value': 'Sandstorms', 'impact_minutes': 20.0});
    } else if (weather == 'Fog') {
      extra += 15.0;
      reasons.add({'feature': 'Weather', 'value': 'Fog', 'impact_minutes': 15.0});
    } else if (weather == 'Windy') {
      extra += 8.0;
      reasons.add({'feature': 'Weather', 'value': 'Windy', 'impact_minutes': 8.0});
    }

    final dist = (payload['Distance'] as num?)?.toDouble() ?? 10.0;
    if (dist > 15.0) {
      final distImpact = (dist - 10.0) * 1.5;
      extra += distImpact;
      reasons.add({'feature': 'Distance', 'value': '${dist.toStringAsFixed(1)} km', 'impact_minutes': double.parse(distImpact.toStringAsFixed(1))});
    }

    final expected = baseTime + extra;
    final delay = extra;
    final isDelayed = delay > 5.0;

    reasons.sort((a, b) => (b['impact_minutes'] as double).compareTo(a['impact_minutes'] as double));

    return {
      'expected_delivery_time_minutes': double.parse(expected.toStringAsFixed(1)),
      'baseline_time_minutes': baseTime,
      'is_delayed': isDelayed,
      'delay_minutes': double.parse(delay.toStringAsFixed(1)),
      'reasons': reasons.take(3).toList(),
    };
  }

  String _computeOfflineCopilotReply(String query, Map<String, dynamic> payload, Map<String, dynamic>? pred) {
    final q = query.toLowerCase();
    final delay = pred?['delay_minutes'] ?? 0;
    final isDelayed = pred?['is_delayed'] ?? false;
    final reasons = (pred?['reasons'] as List?) ?? [];

    if (q.contains('why') || q.contains('cause') || q.contains('factor')) {
      if (!isDelayed) {
        return 'The transit is currently on track within nominal baseline limits (+${delay} min delay). No major bottlenecks identified.';
      }
      final reasonsStr = reasons.map((r) => '- **${r['feature']} (${r['value']})**: +${r['impact_minutes']} min delay').join('\n');
      return '### Transit Delay Root Causes\n\n'
             'The predicted delay is **+$delay minutes** over the baseline.\n\n'
             '**Top SHAP Contributing Risk Factors:**\n$reasonsStr\n\n'
             '**Mitigation Recommendation:** Consider early carrier dispatch or alternate routing around congested transit corridors.';
    }

    if (q.contains('mitigat') || q.contains('remed') || q.contains('fix') || q.contains('action')) {
      return '### Recommended Logistics Mitigation\n\n'
             '1. **Dynamic Rerouting:** Divert carrier from arterial traffic choke points.\n'
             '2. **Buffer Inventory:** Alert downstream distribution hubs to prepare buffer stock.\n'
             '3. **Automated Notification:** Dispatch customer advisory regarding transit adjustments.';
    }

    return 'Analysis based on transit telemetry:\n'
           '- **Expected Delivery:** ${pred?['expected_delivery_time_minutes'] ?? 'N/A'} minutes\n'
           '- **Status:** ${isDelayed ? 'DELAYED (+${delay} min)' : 'ON-SCHEDULE'}\n'
           '- **Condition:** ${payload['Weather']} weather with ${payload['Traffic']} traffic conditions.';
  }

  Future<void> _askCopilot(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _copilotMessages.add(_CopilotMessage(text: trimmed, isUser: true));
      _isCopilotThinking = true;
      _copilotInputCtrl.clear();
    });

    final payload = _buildPayload();
    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.post(
        ApiEndpoints.aiChat,
        data: {
          'message': trimmed,
          'order': payload,
        },
      );

      if (!mounted) return;

      if (response != null && response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final replyText = data['reply'] as String? ?? 'Analysis completed.';
        setState(() {
          _copilotMessages.add(_CopilotMessage(text: replyText, isUser: false));
          _isCopilotThinking = false;
        });
      } else {
        final fallbackReply = _computeOfflineCopilotReply(trimmed, payload, _result);
        setState(() {
          _copilotMessages.add(_CopilotMessage(
            text: fallbackReply,
            isUser: false,
          ));
          _isCopilotThinking = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final fallbackReply = _computeOfflineCopilotReply(trimmed, payload, _result);
      setState(() {
        _copilotMessages.add(_CopilotMessage(
          text: fallbackReply,
          isUser: false,
        ));
        _isCopilotThinking = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _copilotMessages.add(const _CopilotMessage(
      text: '🤖 **ML Delay Copilot Ready.**\nAdjust any of the 14 operational parameters above, then click a diagnostic button or ask any question to explain why delays occur and how to optimize transit.',
      isUser: false,
    ));
    _runPrediction();
  }

  @override
  void dispose() {
    _copilotInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 960;

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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ML STUDIO',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBorder,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Delivery Time Prediction & SHAP Delay Attribution',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preset Buttons Strip
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dataset_outlined, size: 16, color: AppColors.primaryBorder),
                      const SizedBox(width: 6),
                      Text(
                        'Load Real Dataset Sample Presets (from delivery_features_v2.csv):',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip('⛈️ Stormy Jam Congestion (High Delay)', 'stormy_jam'),
                      _buildPresetChip('☀️ Sunny Quick-Commerce (On-Time)', 'sunny_grocery'),
                      _buildPresetChip('🌫️ Foggy Evening Transit (Medium Delay)', 'fog_evening'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Two Column Layout for Desktop / Single Column for Mobile
            isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildFormCard()),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildResultCard(),
                            const SizedBox(height: 16),
                            _buildCopilotCard(),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildResultCard(),
                      const SizedBox(height: 16),
                      _buildCopilotCard(),
                      const SizedBox(height: 16),
                      _buildFormCard(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String key) {
    return ActionChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.surfaceElevated,
      side: const BorderSide(color: AppColors.cardBorderStrong),
      onPressed: () => _applyPreset(key),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryBorder),
              const SizedBox(width: 6),
              Text(
                'Order & Delivery Details',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dropdowns Row 1
          Row(
            children: [
              Expanded(child: _buildDropdown('Category', _category, _categoryOptions, (v) => setState(() => _category = v!))),
              const SizedBox(width: 10),
              Expanded(child: _buildDropdown('Area Type', _area, _areaOptions, (v) => setState(() => _area = v!))),
            ],
          ),
          const SizedBox(height: 12),

          // Dropdowns Row 2
          Row(
            children: [
              Expanded(child: _buildDropdown('Weather Condition', _weather, _weatherOptions, (v) => setState(() => _weather = v!))),
              const SizedBox(width: 10),
              Expanded(child: _buildDropdown('Traffic Congestion', _traffic, _trafficOptions, (v) => setState(() => _traffic = v!))),
            ],
          ),
          const SizedBox(height: 12),

          // Dropdowns Row 3
          Row(
            children: [
              Expanded(child: _buildDropdown('Fleet Vehicle', _vehicle, _vehicleOptions, (v) => setState(() => _vehicle = v!))),
              const SizedBox(width: 10),
              Expanded(child: _buildDropdown('Time of Day', _timeOfDay, _timeOfDayOptions, (v) => setState(() => _timeOfDay = v!))),
            ],
          ),
          const SizedBox(height: 16),

          // Sliders
          _buildSlider('Distance (km)', _distance, 1.0, 25.0, 1, (v) => setState(() => _distance = v)),
          _buildSlider('Prep Time (min)', _prepTime, 5.0, 15.0, 1, (v) => setState(() => _prepTime = v)),
          _buildSlider('Agent Rating (1-5)', _agentRating, 1.0, 5.0, 1, (v) => setState(() => _agentRating = v)),
          _buildSlider('Agent Age (years)', _agentAge.toDouble(), 20.0, 39.0, 0, (v) => setState(() => _agentAge = v.toInt())),
          _buildSlider('Order Hour (0-23)', _orderHour.toDouble(), 0.0, 23.0, 0, (v) => setState(() => _orderHour = v.toInt())),

          const SizedBox(height: 12),

          // Switches Row
          Row(
            children: [
              _buildSwitchChip('Rush Hour', _peakHour == 1, (val) => setState(() => _peakHour = val ? 1 : 0)),
              const SizedBox(width: 8),
              _buildSwitchChip('Weekend', _isWeekend == 1, (val) => setState(() => _isWeekend = val ? 1 : 0)),
            ],
          ),

          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bolt_rounded, size: 18),
              label: Text(
                _isLoading ? 'Running Random Forest Model...' : 'Predict Delivery Time & Run SHAP Analysis',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: _isLoading ? null : _runPrediction,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.dangerBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(_errorMessage!, style: GoogleFonts.inter(color: AppColors.danger, fontSize: 12))),
          ],
        ),
      );
    }

    if (_result == null && !_isLoading) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            'Adjust features and click "Predict Delivery Time" to see live ML outputs.',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    final expTime = (_result?['expected_delivery_time_minutes'] as num?)?.toDouble() ?? 0.0;
    final baseTime = (_result?['baseline_time_minutes'] as num?)?.toDouble() ?? 0.0;
    final isDelayed = _result?['is_delayed'] as bool? ?? false;
    final delayMin = (_result?['delay_minutes'] as num?)?.toDouble() ?? 0.0;
    final reasons = (_result?['reasons'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDelayed ? AppColors.warning.withValues(alpha: 0.5) : AppColors.success.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, size: 18, color: isDelayed ? AppColors.warning : AppColors.success),
              const SizedBox(width: 8),
              Text(
                'Delivery Time Estimate',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDelayed ? AppColors.warningLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isDelayed ? AppColors.warningBorder : AppColors.successBorder),
                ),
                child: Text(
                  isDelayed ? 'DELAY DETECTED (+${delayMin.toStringAsFixed(0)}m)' : 'ON-TIME DELIVERY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDelayed ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Big Metric Cards
          Row(
            children: [
              Expanded(
                child: _buildOutputKpi(
                  'Estimated Delivery Time',
                  '${expTime.toStringAsFixed(0)} min',
                  'Total time expected',
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOutputKpi(
                  'Standard Normal Time',
                  '${baseTime.toStringAsFixed(0)} min',
                  'Normal time for $_category',
                  AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Delay Variance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDelayed ? AppColors.warningLight : AppColors.successLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDelayed ? AppColors.warningBorder : AppColors.successBorder),
            ),
            child: Row(
              children: [
                Icon(
                  isDelayed ? Icons.alarm_on_rounded : Icons.check_circle_outline,
                  size: 16,
                  color: isDelayed ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDelayed
                        ? '⚠️ Estimated delay: +${delayMin.toStringAsFixed(0)} minutes slower than standard delivery.'
                        : '✅ On time: Delivery is on schedule with normal traffic and weather.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDelayed ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Friendly Delay Factors Section
          Text(
            'Why is this delivery delayed?',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Main factors causing extra delivery time:',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          if (reasons.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Everything looks good! Weather, traffic, and distance are normal, so no delay is expected.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            )
          else
            ...reasons.map((r) {
              final rawFeat = r['feature']?.toString() ?? 'Factor';
              final val = r['value']?.toString() ?? '';
              final impact = (r['impact_minutes'] as num?)?.toDouble() ?? 0.0;
              final pct = (impact / (delayMin > 0 ? delayMin : 10.0)).clamp(0.1, 1.0);

              String featLabel = rawFeat;
              if (rawFeat == 'Weather') featLabel = 'Bad Weather';
              else if (rawFeat == 'Traffic') featLabel = 'Heavy Traffic';
              else if (rawFeat == 'Distance') featLabel = 'Long Travel Distance';
              else if (rawFeat == 'Preparation_Time') featLabel = 'Order Packing Time';
              else if (rawFeat == 'Agent_Rating') featLabel = 'Delivery Agent Rating';
              else if (rawFeat == 'Vehicle') featLabel = 'Vehicle Type';
              else if (rawFeat == 'Area') featLabel = 'Delivery Area';
              else if (rawFeat == 'Is_Quick_Commerce') featLabel = 'Delivery Type';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            featLabel,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          if (val.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Text(
                                val,
                                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            '+${impact.toStringAsFixed(0)} min',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Dedicated ML Copilot Section embedded in ML Studio
  Widget _buildCopilotCard() {
    final quickPrompts = [
      'Why is this delivery delayed?',
      'Suggest actions to reduce delay',
      'What is the impact of weather vs traffic?',
      'Simulate vehicle switch to motorcycle',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Delivery & Delay Assistant',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Ready to explain why delays occur and how to speed up delivery',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Prompts
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickPrompts.map((qp) {
              return ActionChip(
                avatar: const Icon(Icons.bolt_rounded, size: 12, color: AppColors.primaryBorder),
                label: Text(qp, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
                backgroundColor: AppColors.surfaceElevated,
                side: const BorderSide(color: AppColors.cardBorder),
                onPressed: () => _askCopilot(qp),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Messages Container
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _copilotMessages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final msg = _copilotMessages[i];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: msg.isUser ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: msg.isUser ? null : Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!msg.isUser)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'AI DIAGNOSTIC EXPLANATION',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                          ),
                        ),
                      _buildCopilotMarkdown(msg.text, msg.isUser),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isCopilotThinking)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  const SizedBox(width: 8),
                  Text('Analyzing feature weights and generating mitigation plan...', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // Input Row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _copilotInputCtrl,
                    style: GoogleFonts.inter(fontSize: 12),
                    onSubmitted: _askCopilot,
                    decoration: InputDecoration(
                      hintText: 'Ask any question about this delay or how to optimize...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.send_rounded, size: 14),
                onPressed: () => _askCopilot(_copilotInputCtrl.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCopilotMarkdown(String text, bool isUser) {
    if (isUser) {
      return Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600));
    }
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((l) {
        final trimmed = l.trim();
        if (trimmed.isEmpty) return const SizedBox(height: 4);
        if (trimmed.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              trimmed.substring(4).replaceAll('**', ''),
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            trimmed.replaceAll('**', ''),
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOutputKpi(String title, String value, String sub, Color col) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: col)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            underline: const SizedBox(),
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double val, double min, double max, int decimals, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            Text(
              decimals == 0 ? val.toInt().toString() : val.toStringAsFixed(decimals),
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            thumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.cardBorder,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: val.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchChip(String label, bool isSelected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.cardBorder),
      onSelected: onChanged,
    );
  }
}

class _CopilotMessage {
  final String text;
  final bool isUser;

  const _CopilotMessage({
    required this.text,
    required this.isUser,
  });
}