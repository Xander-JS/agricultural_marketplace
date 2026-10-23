import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../../../core/widgets/misc/pressable_scale.dart';
import '../../../core/widgets/sheets/app_sheet_frame.dart';
import '../../../core/utils/app_formatters.dart';
import '../models/voice_crop_draft.dart';
import '../services/voice_crop_assistant_service.dart';

enum _VoicePhase {
  ready,
  preparing,
  permissionDenied,
  unavailable,
  listening,
  transcribing,
  reviewingTranscript,
  processing,
  result,
  error,
}

enum _RetryAction { startListening, interpret }

/// Resultado que devuelve la hoja al mercado.
class VoiceCropAssistantResult {
  final VoiceCropDraft? draft;
  final bool openManual;

  const VoiceCropAssistantResult.withDraft(this.draft) : openManual = false;

  const VoiceCropAssistantResult.manual() : draft = null, openManual = true;
}

class VoiceCropAssistantSheet extends StatefulWidget {
  final SpeechRecognitionService? speechService;
  final AiCropExtractionService? aiService;
  final Future<void> Function()? playCue;

  const VoiceCropAssistantSheet({
    super.key,
    this.speechService,
    this.aiService,
    this.playCue,
  });

  @override
  State<VoiceCropAssistantSheet> createState() =>
      _VoiceCropAssistantSheetState();
}

class _VoiceCropAssistantSheetState extends State<VoiceCropAssistantSheet> {
  late final SpeechRecognitionService _speechService =
      widget.speechService ?? DeviceSpeechRecognitionService();
  late final AiCropExtractionService _aiService =
      widget.aiService ?? OpenAiCropExtractionService();

  final _transcriptController = TextEditingController();

  _VoicePhase _phase = _VoicePhase.ready;
  _RetryAction _retryAction = _RetryAction.startListening;
  String _partialTranscript = '';
  String _transcript = '';
  String? _errorMessage;
  VoiceCropDraft? _draft;
  bool _speechInitialized = false;
  bool _closing = false;
  bool _disposed = false;

  AppLocalizations get _l10n =>
      AppLocalizations.of(context) ??
      lookupAppLocalizations(const Locale('es'));

  bool get _isCaptureActive =>
      _phase == _VoicePhase.listening ||
      _phase == _VoicePhase.transcribing ||
      _phase == _VoicePhase.preparing;

  @override
  void dispose() {
    _disposed = true;
    _transcriptController.dispose();
    unawaited(_speechService.dispose());
    super.dispose();
  }

  Future<void> _startListening() async {
    if (_isCaptureActive || _phase == _VoicePhase.processing) return;

    setState(() {
      _phase = _VoicePhase.preparing;
      _partialTranscript = '';
      _transcript = '';
      _transcriptController.clear();
      _draft = null;
      _errorMessage = null;
      _retryAction = _RetryAction.startListening;
    });

    SpeechRecognitionAvailability availability;
    try {
      availability = _speechInitialized
          ? SpeechRecognitionAvailability.available
          : await _speechService.initialize(
              onTranscript: _handleTranscript,
              onError: _handleSpeechError,
              onStatus: _handleSpeechStatus,
            );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _VoicePhase.unavailable;
      });
      return;
    }

    if (!mounted) return;
    if (availability != SpeechRecognitionAvailability.available) {
      setState(() {
        _phase = availability == SpeechRecognitionAvailability.permissionDenied
            ? _VoicePhase.permissionDenied
            : _VoicePhase.unavailable;
      });
      return;
    }

    _speechInitialized = true;
    await _playStartCue();
    if (!mounted) return;

    setState(() {
      _phase = _VoicePhase.listening;
    });

    try {
      await _speechService.start();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _VoicePhase.error;
        _retryAction = _RetryAction.startListening;
        _errorMessage = _l10n.ai_error_mic_start;
      });
    }
  }

  Future<void> _stopListening() async {
    if (_phase != _VoicePhase.listening) return;
    setState(() {
      _phase = _VoicePhase.transcribing;
    });
    try {
      await _speechService.stop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _VoicePhase.error;
        _retryAction = _RetryAction.startListening;
        _errorMessage = _l10n.ai_error_mic_stop;
      });
    }
  }

  void _handleTranscript(String text, bool isFinal) {
    if (!mounted || _disposed) return;
    if (isFinal && text.trim().isEmpty) {
      setState(() {
        _phase = _VoicePhase.error;
        _retryAction = _RetryAction.startListening;
        _errorMessage = _l10n.ai_error_no_speech;
      });
      return;
    }

    setState(() {
      _partialTranscript = text;
      if (isFinal) {
        _transcript = text;
        _transcriptController.text = text;
        if (_phase == _VoicePhase.listening ||
            _phase == _VoicePhase.transcribing) {
          _phase = _VoicePhase.reviewingTranscript;
        }
      }
    });
  }

  void _handleSpeechStatus(SpeechCaptureStatus status) {
    if (!mounted || _disposed) return;
    if (status != SpeechCaptureStatus.done) return;
    if (_phase != _VoicePhase.listening && _phase != _VoicePhase.transcribing) {
      return;
    }

    final text = _transcript.isNotEmpty ? _transcript : _partialTranscript;
    if (text.trim().isEmpty) {
      setState(() {
        _phase = _VoicePhase.error;
        _retryAction = _RetryAction.startListening;
        _errorMessage = _l10n.ai_error_no_speech_retry;
      });
      return;
    }

    setState(() {
      _transcript = text;
      _transcriptController.text = text;
      _phase = _VoicePhase.reviewingTranscript;
    });
  }

  void _handleSpeechError(String userMessage) {
    if (!mounted || _disposed) return;
    setState(() {
      _phase = _VoicePhase.error;
      _retryAction = _RetryAction.startListening;
      _errorMessage = userMessage;
    });
  }

  Future<void> _interpretTranscript() async {
    final text = _transcriptController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _phase = _VoicePhase.error;
        _retryAction = _RetryAction.startListening;
        _errorMessage = _l10n.ai_error_empty_transcript;
      });
      return;
    }

    if (!_aiService.isConfigured) {
      setState(() {
        _phase = _VoicePhase.error;
        _retryAction = _RetryAction.interpret;
        _errorMessage = _l10n.ai_error_not_configured;
      });
      return;
    }

    setState(() {
      _phase = _VoicePhase.processing;
      _draft = null;
      _errorMessage = null;
      _retryAction = _RetryAction.interpret;
    });

    try {
      final draft = await _aiService.extract(text);
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _phase = _VoicePhase.result;
      });
    } on AiCropExtractionException catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _VoicePhase.error;
        _retryAction = _RetryAction.interpret;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _VoicePhase.error;
        _retryAction = _RetryAction.interpret;
        _errorMessage = _l10n.ai_error_interpret;
      });
    }
  }

  Future<void> _retry() async {
    switch (_retryAction) {
      case _RetryAction.startListening:
        await _startListening();
        break;
      case _RetryAction.interpret:
        await _interpretTranscript();
        break;
    }
  }

  void _resetToReady() {
    setState(() {
      _phase = _VoicePhase.ready;
      _partialTranscript = '';
      _transcript = '';
      _transcriptController.clear();
      _draft = null;
      _errorMessage = null;
      _retryAction = _RetryAction.startListening;
    });
  }

  Future<void> _close({VoiceCropAssistantResult? result}) async {
    if (_closing) return;
    _closing = true;
    await _speechService.cancel();
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  void _continueWithDraft() {
    final draft = _draft;
    if (draft == null || !draft.hasAnyUsableData) return;
    unawaited(_close(result: VoiceCropAssistantResult.withDraft(draft)));
  }

  void _continueManually() {
    unawaited(_close(result: const VoiceCropAssistantResult.manual()));
  }

  Future<void> _playStartCue() async {
    if (widget.playCue != null) {
      await widget.playCue!();
      return;
    }
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;

    return AppSheetFrame(
      bodyPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ai_title,
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontSize: 22,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.ai_subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              IconButton(
                key: const Key('voice_crop_close_button'),
                tooltip: l10n.ai_close,
                onPressed: _closing ? null : () => _close(),
                color: context.appTextSecondary,
                style: IconButton.styleFrom(
                  backgroundColor: context.appSurfaceVariant,
                ),
                icon: const Icon(LucideIcons.x, size: 20),
              ),
            ],
          ),
          if (!_aiService.isConfigured) ...[
            const SizedBox(height: AppDimensions.space12),
            _buildAiConfigNotice(),
          ],
          const SizedBox(height: AppDimensions.space8),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.standard),
            switchInCurve: AppMotion.easeOut,
            switchOutCurve: AppMotion.easeOut,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: KeyedSubtree(
              key: ValueKey(_phase),
              child: _buildPhaseContent(),
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          TextButton(
            key: const Key('voice_crop_cancel_button'),
            onPressed: _closing ? null : () => _close(),
            child: Text(
              l10n.common_cancel,
              style: TextStyle(color: context.appTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiConfigNotice() {
    final info = context.appInfoTriad;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: info.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 16, color: info.foreground),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(
              '${_l10n.ai_unavailable_title} '
              '${_l10n.ai_unavailable_desc}',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case _VoicePhase.ready:
        return _buildReady();
      case _VoicePhase.preparing:
        return _buildWorking(_l10n.ai_preparing, LucideIcons.mic);
      case _VoicePhase.permissionDenied:
        return _buildAvailabilityError(
          title: _l10n.ai_permission_title,
          message: _l10n.ai_permission_desc,
        );
      case _VoicePhase.unavailable:
        return _buildAvailabilityError(
          title: _l10n.ai_voice_unavailable_title,
          message: _l10n.ai_voice_unavailable_desc,
        );
      case _VoicePhase.listening:
        return _buildListening();
      case _VoicePhase.transcribing:
        return _buildWorking(_l10n.ai_transcribing, LucideIcons.audioLines);
      case _VoicePhase.reviewingTranscript:
        return _buildTranscriptReview();
      case _VoicePhase.processing:
        return _buildWorking(
          _l10n.ai_interpreting,
          LucideIcons.sparkles,
          accent: true,
        );
      case _VoicePhase.result:
        return _buildResult();
      case _VoicePhase.error:
        return _buildError();
    }
  }

  Widget _buildGuidance(String text, {String? detail}) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge.copyWith(
            color: context.appTextPrimary,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReady() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _VoiceOrb(
            key: const Key('voice_crop_start_button'),
            mode: _OrbMode.idle,
            icon: LucideIcons.mic,
            semanticLabel: _l10n.ai_start,
            onTap: _startListening,
          ),
        ),
        _buildGuidance(_l10n.ai_start, detail: _l10n.ai_intro),
        const SizedBox(height: AppDimensions.space16),
        _buildExamplesCard(),
        const SizedBox(height: AppDimensions.space16),
        OutlinedButton.icon(
          key: const Key('voice_crop_manual_button'),
          onPressed: _continueManually,
          icon: const Icon(LucideIcons.squarePen, size: 18),
          label: Text(_l10n.ai_manual),
        ),
      ],
    );
  }

  Widget _buildExamplesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.ai_examples_title,
            style: AppTextStyles.titleSmall.copyWith(
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _l10n.ai_examples_desc,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            _l10n.ai_example_text,
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: context.appTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Transient states (preparing the microphone, transcribing, interpreting
  /// with AI): the orb breathes with soft concentric rings until the next
  /// state arrives.
  Widget _buildWorking(String message, IconData icon, {bool accent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _VoiceOrb(
            mode: _OrbMode.working,
            icon: icon,
            accent: accent,
            semanticLabel: message,
          ),
        ),
        _buildGuidance(message),
        const SizedBox(height: AppDimensions.space16),
      ],
    );
  }

  Widget _buildAvailabilityError({
    required String title,
    required String message,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimensions.space16),
        Center(
          child: _StatusCircle(
            icon: LucideIcons.micOff,
            triad: context.appErrorTriad,
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
        _buildGuidance(title, detail: message),
        const SizedBox(height: AppDimensions.space20),
        FilledButton.icon(
          key: const Key('voice_crop_retry_microphone_button'),
          onPressed: _startListening,
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          label: Text(_l10n.ai_retry_mic),
        ),
        const SizedBox(height: AppDimensions.space8),
        TextButton(
          key: const Key('voice_crop_manual_button'),
          onPressed: _continueManually,
          child: Text(_l10n.ai_continue_manual),
        ),
      ],
    );
  }

  Widget _buildListening() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _VoiceOrb(
            mode: _OrbMode.listening,
            icon: LucideIcons.mic,
            voiceActivity: _partialTranscript,
            semanticLabel: _l10n.ai_listening,
          ),
        ),
        _buildGuidance(_l10n.ai_listening),
        const SizedBox(height: AppDimensions.space16),
        _TranscriptBubble(
          child: Text(
            _partialTranscript.isEmpty
                ? _l10n.ai_listening_hint
                : _partialTranscript,
            key: const Key('voice_crop_partial_transcript'),
            style: AppTextStyles.bodyLarge.copyWith(
              color: _partialTranscript.isEmpty
                  ? context.appTextSecondary
                  : context.appTextPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
        FilledButton.icon(
          key: const Key('voice_crop_stop_button'),
          onPressed: _stopListening,
          icon: const Icon(LucideIcons.square, size: 16),
          label: Text(_l10n.ai_stop_review),
        ),
      ],
    );
  }

  Widget _buildTranscriptReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimensions.space12),
        Text(
          _l10n.ai_review_transcript_title,
          style: AppTextStyles.titleLarge.copyWith(
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _l10n.ai_review_transcript_desc,
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.appTextSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.space12),
        TextField(
          key: const Key('voice_crop_transcript_field'),
          controller: _transcriptController,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          style: AppTextStyles.bodyLarge.copyWith(
            color: context.appTextPrimary,
          ),
          decoration: InputDecoration(
            labelText: _l10n.ai_transcript_label,
            alignLabelWithHint: true,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 52),
              child: Icon(LucideIcons.quote, size: 18),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
        FilledButton.icon(
          key: const Key('voice_crop_interpret_button'),
          onPressed: _interpretTranscript,
          icon: const Icon(LucideIcons.sparkles, size: 18),
          label: Text(_l10n.ai_interpret),
        ),
        const SizedBox(height: AppDimensions.space8),
        OutlinedButton.icon(
          key: const Key('voice_crop_record_again_button'),
          onPressed: _startListening,
          icon: const Icon(LucideIcons.mic, size: 18),
          label: Text(_l10n.ai_record_again),
        ),
        const SizedBox(height: AppDimensions.space4),
        TextButton(
          key: const Key('voice_crop_manual_button'),
          onPressed: _continueManually,
          child: Text(_l10n.ai_continue_manual),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final draft = _draft;
    if (draft == null) {
      return _buildError();
    }

    final review = draft.reviewFields.toSet();
    final quantityNeedsReview =
        review.contains(VoiceCropField.quantity) ||
        review.contains(VoiceCropField.unit);

    final rows = <Widget>[
      if (draft.cropType != null)
        _DraftRow(
          icon: LucideIcons.sprout,
          label: _l10n.ai_crop,
          value: draft.cropType!,
          status: review.contains(VoiceCropField.cropType)
              ? _FieldStatus.review
              : _FieldStatus.identified,
        ),
      if (draft.quantityDescription != null)
        _DraftRow(
          icon: LucideIcons.weight,
          label: _l10n.ai_quantity,
          value: draft.quantityDescription!,
          status: quantityNeedsReview
              ? _FieldStatus.review
              : _FieldStatus.identified,
        ),
      if (draft.pricePerKg != null)
        _DraftRow(
          icon: LucideIcons.tag,
          label: _l10n.ai_price,
          value: CurrencyFormatters.formatPricePerKg(draft.pricePerKg),
          status: review.contains(VoiceCropField.pricePerKg)
              ? _FieldStatus.review
              : _FieldStatus.identified,
        ),
      if (draft.notes != null)
        _DraftRow(
          icon: LucideIcons.messageSquareText,
          label: _l10n.ai_note,
          value: draft.notes!,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimensions.space12),
        Row(
          children: [
            Icon(LucideIcons.sparkles, size: 18, color: context.appAccentAi),
            const SizedBox(width: AppDimensions.space8),
            Text(
              _l10n.ai_recognized_title,
              style: AppTextStyles.titleLarge.copyWith(
                color: context.appTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _l10n.ai_recognized_desc,
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.appTextSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.space12),
        InsetGroupCard(
          padding: EdgeInsets.zero,
          child: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  child: Text(
                    _l10n.ai_no_data,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 46,
                          color: context.appDivider,
                        ),
                      rows[i],
                    ],
                  ],
                ),
        ),
        if (!draft.hasAnyUsableData) ...[
          const SizedBox(height: AppDimensions.space12),
          _buildNotice(_l10n.ai_no_data_desc, context.appErrorTriad),
        ],
        if (draft.missingFields.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.space16),
          Text(
            _l10n.ai_missing_data,
            style: AppTextStyles.titleSmall.copyWith(
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final field in draft.missingFields)
                _StatusChip(label: field.label, status: _FieldStatus.pending),
            ],
          ),
        ],
        if (draft.warnings.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.space16),
          Text(
            _l10n.ai_warnings,
            style: AppTextStyles.titleSmall.copyWith(
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          for (final warning in draft.warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildNotice(warning, context.appWarningTriad),
            ),
        ],
        const SizedBox(height: AppDimensions.space20),
        FilledButton.icon(
          key: const Key('voice_crop_continue_button'),
          onPressed: draft.hasAnyUsableData ? _continueWithDraft : null,
          icon: const Icon(LucideIcons.arrowRight, size: 18),
          label: Text(_l10n.ai_review_continue),
        ),
        const SizedBox(height: AppDimensions.space8),
        OutlinedButton.icon(
          key: const Key('voice_crop_retry_button'),
          onPressed: _interpretTranscript,
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          label: Text(_l10n.ai_retry_interpret),
        ),
        const SizedBox(height: AppDimensions.space4),
        TextButton(
          key: const Key('voice_crop_record_again_button'),
          onPressed: _startListening,
          child: Text(_l10n.ai_record_again),
        ),
        TextButton(
          key: const Key('voice_crop_manual_button'),
          onPressed: _continueManually,
          child: Text(_l10n.ai_continue_manual),
        ),
      ],
    );
  }

  Widget _buildNotice(String text, AppSemanticTriad triad) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: triad.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: triad.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 16, color: triad.foreground),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimensions.space16),
        Center(
          child: _StatusCircle(
            icon: LucideIcons.circleAlert,
            triad: context.appErrorTriad,
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
        _buildGuidance(
          _l10n.ai_failed_title,
          detail: _errorMessage ?? _l10n.ai_failed_desc,
        ),
        const SizedBox(height: AppDimensions.space20),
        FilledButton.icon(
          key: const Key('voice_crop_retry_button'),
          onPressed: _retry,
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          label: Text(_l10n.common_retry),
        ),
        const SizedBox(height: AppDimensions.space8),
        OutlinedButton.icon(
          key: const Key('voice_crop_record_again_button'),
          onPressed: _resetToReady,
          icon: const Icon(LucideIcons.mic, size: 18),
          label: Text(_l10n.ai_record_again),
        ),
        const SizedBox(height: AppDimensions.space4),
        TextButton(
          key: const Key('voice_crop_manual_button'),
          onPressed: _continueManually,
          child: Text(_l10n.ai_continue_manual),
        ),
      ],
    );
  }
}

enum _OrbMode { idle, listening, working }

enum _FieldStatus { identified, review, pending }

/// Central microphone orb.
///
/// - idle: a still button with one faint halo; tapping starts listening.
/// - listening: a ripple leaves the orb each time new speech is
///   transcribed, so the rings answer the farmer's voice instead of
///   looping on their own.
/// - working: two soft rings pulse continuously while the device or the
///   AI is busy.
///
/// With Reduce Motion on, rings are not drawn; the orb and its icon still
/// change with the state.
class _VoiceOrb extends StatefulWidget {
  final _OrbMode mode;
  final IconData icon;
  final bool accent;
  final String voiceActivity;
  final String semanticLabel;
  final VoidCallback? onTap;

  const _VoiceOrb({
    super.key,
    required this.mode,
    required this.icon,
    required this.semanticLabel,
    this.accent = false,
    this.voiceActivity = '',
    this.onTap,
  });

  @override
  State<_VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<_VoiceOrb> {
  static const double _orbSize = 88;
  static const double _stageSize = 184;
  static const Duration _rippleDuration = Duration(milliseconds: 1100);
  static const Duration _rippleGap = Duration(milliseconds: 280);

  final List<int> _ripples = [];
  int _nextRippleId = 0;
  DateTime? _lastRipple;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.mode == _OrbMode.listening && _nextRippleId == 0) {
      _emitRipple();
    }
  }

  @override
  void didUpdateWidget(covariant _VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode == _OrbMode.listening &&
        widget.voiceActivity != oldWidget.voiceActivity) {
      _emitRipple();
    }
  }

  void _emitRipple() {
    if (AppMotion.reduced(context)) return;
    final now = DateTime.now();
    if (_lastRipple != null && now.difference(_lastRipple!) < _rippleGap) {
      return;
    }
    _lastRipple = now;
    _ripples.add(_nextRippleId++);
  }

  void _removeRipple(int id) {
    if (!mounted) return;
    setState(() => _ripples.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accent ? context.appAccentAi : context.appPrimary;
    final onColor = widget.accent
        ? context.appColorScheme.onTertiary
        : context.appOnPrimary;
    final reduced = AppMotion.reduced(context);

    Widget ring() => Container(
      width: _orbSize,
      height: _orbSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45), width: 2),
      ),
    );

    final rings = <Widget>[
      if (!reduced && widget.mode == _OrbMode.working)
        for (final delay in const [Duration.zero, Duration(milliseconds: 800)])
          ring()
              .animate(onPlay: (controller) => controller.repeat())
              .scaleXY(
                delay: delay,
                begin: 1,
                end: 1.9,
                duration: 1600.ms,
                curve: AppMotion.easeOut,
              )
              .fadeOut(delay: delay, duration: 1600.ms, curve: Curves.easeOut),
      if (!reduced && widget.mode == _OrbMode.listening)
        for (final id in _ripples)
          ring()
              .animate(key: ValueKey(id), onComplete: (_) => _removeRipple(id))
              .scaleXY(
                begin: 1,
                end: 2,
                duration: _rippleDuration,
                curve: AppMotion.easeOut,
              )
              .fadeOut(duration: _rippleDuration, curve: Curves.easeOut),
    ];

    final orb = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.emphasized),
      curve: AppMotion.easeOut,
      width: _orbSize,
      height: _orbSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.standard),
        switchInCurve: AppMotion.easeOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: Icon(
          widget.icon,
          key: ValueKey(widget.icon),
          size: 34,
          color: onColor,
        ),
      ),
    );

    final stage = SizedBox.square(
      dimension: _stageSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.mode == _OrbMode.idle)
            Container(
              width: _orbSize + 28,
              height: _orbSize + 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.08),
              ),
            ),
          ...rings,
          orb,
        ],
      ),
    );

    if (widget.onTap == null) {
      return Semantics(label: widget.semanticLabel, child: stage);
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: PressableScale(
        pressedScale: 0.94,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: stage,
        ),
      ),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  final IconData icon;
  final AppSemanticTriad triad;

  const _StatusCircle({required this.icon, required this.triad});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: triad.background,
        shape: BoxShape.circle,
        border: Border.all(color: triad.border),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 30, color: triad.foreground),
    );
  }
}

/// Live transcript in a message bubble, the tail corner toward the
/// speaker.
class _TranscriptBubble extends StatelessWidget {
  final Widget child;

  const _TranscriptBubble({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.appSurfaceVariant,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: child,
    );
  }
}

class _DraftRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _FieldStatus? status;

  const _DraftRow({
    required this.icon,
    required this.label,
    required this.value,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('es'));
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: context.appTextSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.appTextPrimary,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          if (status != null) ...[
            const SizedBox(width: AppDimensions.space8),
            _StatusChip(
              label: status == _FieldStatus.review
                  ? l10n.ai_field_review
                  : l10n.ai_field_identified,
              status: status!,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final _FieldStatus status;

  const _StatusChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final (AppSemanticTriad triad, IconData icon) = switch (status) {
      _FieldStatus.identified => (context.appSuccessTriad, LucideIcons.check),
      _FieldStatus.review => (context.appWarningTriad, LucideIcons.eye),
      _FieldStatus.pending => (
        context.appNeutralTriad,
        LucideIcons.circleDashed,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: triad.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: triad.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: triad.foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: triad.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
