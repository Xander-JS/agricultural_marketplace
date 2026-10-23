import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:lucide_icons_flutter/lucide_icons_600.dart' show LucideIcons600;

import '../../../core/theme/app_icons.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
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
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.ai_title,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontSize: 22,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              IconButton(
                key: const Key('voice_crop_close_button'),
                tooltip: l10n.ai_close,
                onPressed: _closing ? null : () => _close(),
                color: context.appTextPrimary,
                style: IconButton.styleFrom(
                  backgroundColor: context.appSurfaceVariant,
                ),
                // A heavier stroke than the app's 300 weight keeps the close
                // mark legible on the neutral chip without borrowing red.
                icon: const Icon(LucideIcons600.x, size: 20),
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
        return _buildWorking(_l10n.ai_preparing);
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
        return _buildWorking(_l10n.ai_transcribing);
      case _VoicePhase.reviewingTranscript:
        return _buildTranscriptReview();
      case _VoicePhase.processing:
        return _buildWorking(_l10n.ai_interpreting, accent: true);
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
          child: _VoiceSpectrum(
            key: const Key('voice_crop_start_button'),
            mode: _SpectrumMode.idle,
            semanticLabel: _l10n.ai_start,
            onTap: _startListening,
          ),
        ),
        _buildGuidance(_l10n.ai_start),
        const SizedBox(height: AppDimensions.space12),
        Center(child: _HintPill(text: _l10n.ai_hint_pill)),
        const SizedBox(height: AppDimensions.space12),
        Text(
          _l10n.ai_review_promise,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: context.appTextMuted),
        ),
        const SizedBox(height: AppDimensions.space16),
        _buildManualEntryButton(),
      ],
    );
  }

  /// The manual path out of the ready state: a full-width outlined control
  /// on the neutral fill, brand hairline and label, so it reads as a real
  /// alternative to speaking rather than a footnote.
  Widget _buildManualEntryButton() {
    final primary = context.appPrimary;
    return PressableScale(
      child: OutlinedButton.icon(
        key: const Key('voice_crop_manual_button'),
        onPressed: _continueManually,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: context.appSurfaceVariant,
          foregroundColor: primary,
          side: BorderSide(color: primary),
          textStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(LucideIcons.pencilLine, size: 18),
        label: Text(_l10n.ai_manual, textAlign: TextAlign.center),
      ),
    );
  }

  /// Transient states (preparing the microphone, transcribing, interpreting
  /// with AI): the spectrum bars pulse softly until the next state
  /// arrives.
  Widget _buildWorking(String message, {bool accent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _VoiceSpectrum(
            mode: _SpectrumMode.working,
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
          child: _VoiceSpectrum(
            mode: _SpectrumMode.listening,
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

    _FieldStatus statusOf(bool needsReview) =>
        needsReview ? _FieldStatus.review : _FieldStatus.identified;
    final unit = draft.unit;

    final chips = <_DraftChip>[
      if (draft.cropType != null)
        _DraftChip(
          icon: LucideIcons.sprout,
          label: _l10n.ai_crop,
          value: draft.cropType!,
          status: statusOf(review.contains(VoiceCropField.cropType)),
        ),
      if (draft.quantityDescription != null)
        _DraftChip(
          icon: LucideIcons.weight,
          label: _l10n.ai_quantity,
          value: draft.quantityDescription!,
          status: statusOf(quantityNeedsReview),
        ),
      if (unit != null)
        _DraftChip(
          icon: LucideIcons.package,
          label: _l10n.ai_unit,
          value: unit == VoiceCropUnit.kilogram
              ? unit.label
              : '${unit.label} · ${UnitFormatters.formatKg(unit.kgEquivalent)}',
          status: statusOf(review.contains(VoiceCropField.unit)),
        ),
      if (draft.pricePerKg != null)
        _DraftChip(
          icon: LucideIcons.tag,
          label: _l10n.ai_price,
          value: CurrencyFormatters.formatPricePerKg(draft.pricePerKg),
          status: statusOf(review.contains(VoiceCropField.pricePerKg)),
        ),
      if (draft.notes != null)
        _DraftChip(
          icon: LucideIcons.messageSquareText,
          label: _l10n.ai_note,
          value: draft.notes!,
          fullWidth: true,
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
        if (chips.isEmpty)
          _TranscriptBubble(
            child: Text(
              _l10n.ai_no_data,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          )
        else
          _DraftChipGrid(chips: chips),
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
        Row(
          children: [
            Expanded(
              child: TextButton(
                key: const Key('voice_crop_record_again_button'),
                onPressed: _startListening,
                child: Text(_l10n.ai_record_again, textAlign: TextAlign.center),
              ),
            ),
            Expanded(
              child: TextButton(
                key: const Key('voice_crop_manual_button'),
                onPressed: _continueManually,
                child: Text(
                  _l10n.ai_continue_manual,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
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

enum _SpectrumMode { idle, listening, working }

enum _FieldStatus { identified, review, pending }

/// Central voice indicator: a row of thin, symmetric harmonic bars drawn by
/// [_VoiceSpectrumPainter], in the flat equalizer language of a voice
/// recorder.
///
/// - idle: the bars rest low and breathe a few times, then settle, so the
///   invitation is noticed without becoming background noise.
/// - listening: each transcript update energizes the bars, which oscillate
///   on layered sine/cosine waves while speech keeps arriving and ease back
///   to rest after a pause, so the motion answers the farmer's voice.
/// - working: a soft pulse travels across the bars; with [accent] they take
///   the emerald-to-sapphire AI gradient while the draft is structured.
///
/// Phase changes cross-fade through the sheet's switcher. With Reduce
/// Motion on, the bars hold still at medium height; only color follows the
/// state.
class _VoiceSpectrum extends StatefulWidget {
  final _SpectrumMode mode;
  final bool accent;
  final String voiceActivity;
  final String semanticLabel;
  final VoidCallback? onTap;

  const _VoiceSpectrum({
    super.key,
    required this.mode,
    required this.semanticLabel,
    this.accent = false,
    this.voiceActivity = '',
    this.onTap,
  });

  @override
  State<_VoiceSpectrum> createState() => _VoiceSpectrumState();
}

class _VoiceSpectrumState extends State<_VoiceSpectrum>
    with TickerProviderStateMixin {
  static const Size _stageSize = Size(168, 96);
  static const Duration _breathPeriod = Duration(milliseconds: 2400);
  static const Duration _wavePeriod = Duration(milliseconds: 3000);
  static const Duration _pulsePeriod = Duration(milliseconds: 1600);
  static const Duration _energyRise = Duration(milliseconds: 120);
  static const Duration _energyDecay = Duration(milliseconds: 2200);
  // Three full breaths (in + out), then the bars rest.
  static const int _idleBreaths = 6;

  /// Idle breath (0..1, reversing a few times, then resting).
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: _breathPeriod,
  );

  /// Wave phase (0..1, looping) for listening and working.
  late final AnimationController _phase = AnimationController(vsync: this);

  /// Listening: voice energy, raised by each transcript update and decaying
  /// back to rest during a pause.
  late final AnimationController _energy = AnimationController(vsync: this);

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _energy.addStatusListener((status) {
      // Speech has paused long enough for the bars to rest: stop ticking.
      if (status == AnimationStatus.completed &&
          _energy.value == 0 &&
          widget.mode == _SpectrumMode.listening) {
        _phase.stop();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _syncMotion();
      if (widget.mode == _SpectrumMode.listening) _energize(0.7);
    }
  }

  @override
  void didUpdateWidget(covariant _VoiceSpectrum oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) _syncMotion();
    if (widget.mode == _SpectrumMode.listening &&
        widget.voiceActivity != oldWidget.voiceActivity) {
      _energize(1);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _phase.dispose();
    _energy.dispose();
    super.dispose();
  }

  void _syncMotion() {
    _breath.stop();
    if (AppMotion.reduced(context)) {
      _phase.stop();
      _energy.stop();
      return;
    }
    switch (widget.mode) {
      case _SpectrumMode.idle:
        _phase.stop();
        _energy.animateTo(0, duration: AppMotion.emphasized);
        _breath.repeat(reverse: true, count: _idleBreaths);
      case _SpectrumMode.listening:
        // Phase runs from [_energize] while speech arrives.
        break;
      case _SpectrumMode.working:
        _energy.animateTo(0, duration: AppMotion.emphasized);
        _phase.repeat(period: _pulsePeriod);
    }
  }

  /// Raises the voice energy to [peak] (never lowering it mid-word), then
  /// lets it decay. Retargets from the current value, so rapid transcript
  /// updates read as one continuous utterance.
  void _energize(double peak) {
    if (AppMotion.reduced(context)) return;
    if (!_phase.isAnimating) _phase.repeat(period: _wavePeriod);
    final target = math.max(peak, _energy.value);
    _energy
        .animateTo(target, duration: _energyRise, curve: AppMotion.easeOut)
        .whenCompleteOrCancel(() {
          if (!mounted || _energy.value != target) return;
          if (widget.mode != _SpectrumMode.listening) return;
          _energy.animateTo(
            0,
            duration: _energyDecay,
            curve: AppMotion.easeOut,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    final stage = SizedBox.fromSize(
      size: _stageSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.appSurfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSheet),
          border: Border.all(
            color: context.appBorder,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _VoiceSpectrumPainter(
              repaint: Listenable.merge([_breath, _phase, _energy]),
              mode: widget.mode,
              start: context.appPrimary,
              end: widget.accent ? context.appAccentAi : context.appPrimary,
              reduced: reduced,
              breath: _breath,
              phase: _phase,
              energy: _energy,
            ),
          ),
        ),
      ),
    );

    final Widget indicator = widget.onTap == null
        ? Semantics(label: widget.semanticLabel, child: stage)
        : Semantics(
            button: true,
            label: widget.semanticLabel,
            excludeSemantics: true,
            child: PressableScale(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: stage,
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space24),
      child: indicator,
    );
  }
}

/// Seven thin, rounded bars mirrored around the center line. Each bar's
/// height is a 0..1 amplitude under a symmetric taper, so the middle bar
/// reaches highest and the outer ones stay shorter, like a voice spectrum.
class _VoiceSpectrumPainter extends CustomPainter {
  final _SpectrumMode mode;

  /// Left and right gradient stops; equal for a flat emerald.
  final Color start;
  final Color end;
  final bool reduced;
  final Animation<double> breath;
  final Animation<double> phase;
  final Animation<double> energy;

  _VoiceSpectrumPainter({
    required Listenable repaint,
    required this.mode,
    required this.start,
    required this.end,
    required this.reduced,
    required this.breath,
    required this.phase,
    required this.energy,
  }) : super(repaint: repaint);

  static const int _bars = 7;
  static const double _barWidth = 4;
  static const double _gap = 8;
  static const double _maxHeight = 56;
  static const double _minHeight = 6;

  /// Symmetric taper, highest in the middle.
  static const List<double> _taper = [0.42, 0.66, 0.88, 1, 0.88, 0.66, 0.42];

  static const double _rest = 0.14;
  static const double _medium = 0.5;

  double _amplitude(int i) {
    if (reduced) return _medium;
    final taper = _taper[i];
    final t = phase.value * 2 * math.pi;
    switch (mode) {
      case _SpectrumMode.idle:
        final b = Curves.easeInOut.transform(breath.value);
        return _rest + 0.12 * b * taper;
      case _SpectrumMode.listening:
        // Two layered harmonics with per-bar offsets, mirrored around the
        // center so the shape stays symmetric while it moves.
        final d = (i - _bars ~/ 2).abs().toDouble();
        final wave =
            0.5 + 0.5 * math.sin(3 * t + d * 0.9) * math.cos(5 * t - d * 0.6);
        return _rest + 0.08 * taper + energy.value * taper * 0.78 * wave;
      case _SpectrumMode.working:
        // A gentle pulse travelling outwards from the center.
        final d = (i - _bars ~/ 2).abs().toDouble();
        final pulse = 0.5 + 0.5 * math.sin(t - d * 0.85);
        return 0.3 + 0.28 * pulse * taper;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    const totalWidth = _bars * _barWidth + (_bars - 1) * _gap;
    final left = (size.width - totalWidth) / 2;
    final centerY = size.height / 2;
    final bounds = Rect.fromLTWH(
      left,
      centerY - _maxHeight / 2,
      totalWidth,
      _maxHeight,
    );
    final paint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(colors: [start, end]).createShader(bounds);

    for (var i = 0; i < _bars; i++) {
      final height =
          _minHeight +
          (_maxHeight - _minHeight) * _amplitude(i).clamp(0.0, 1.0);
      final x = left + i * (_barWidth + _gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, centerY - height / 2, _barWidth, height),
          const Radius.circular(_barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceSpectrumPainter old) =>
      old.mode != mode ||
      old.start != start ||
      old.end != end ||
      old.reduced != reduced;
}

/// Contextual hint in a soft capsule; it drifts in once after the
/// spectrum.
class _HintPill extends StatelessWidget {
  final String text;

  const _HintPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.appBorder),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(
          color: context.appTextSecondary,
        ),
      ),
    );

    if (AppMotion.reduced(context)) return pill;
    return pill
        .animate()
        .fadeIn(delay: 180.ms, duration: AppMotion.entrance)
        .slideY(
          begin: 0.35,
          end: 0,
          delay: 180.ms,
          duration: AppMotion.entrance,
          curve: AppMotion.easeOut,
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

/// Live transcript on a frosted-glass card.
class _TranscriptBubble extends StatelessWidget {
  final Widget child;

  const _TranscriptBubble({required this.child});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedSize(
          duration: AppMotion.of(context, AppMotion.standard),
          curve: AppMotion.easeOut,
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: context.appSurfaceVariant.withValues(alpha: 0.72),
              borderRadius: radius,
              border: Border.all(color: context.appBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Two-column grid of extracted fields; a chip marked [_DraftChip.fullWidth]
/// takes the whole row. Chips settle in with a short stagger.
class _DraftChipGrid extends StatelessWidget {
  final List<_DraftChip> chips;

  const _DraftChipGrid({required this.chips});

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    final reduced = AppMotion.reduced(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < chips.length; i++)
              SizedBox(
                width: chips[i].fullWidth ? constraints.maxWidth : half,
                child: reduced
                    ? chips[i]
                    : chips[i]
                          .animate(
                            delay:
                                AppMotion.staggerStep *
                                math.min(i, AppMotion.staggerMaxItems),
                          )
                          .fadeIn(duration: AppMotion.emphasized)
                          .scaleXY(
                            begin: 0.96,
                            end: 1,
                            duration: AppMotion.emphasized,
                            curve: AppMotion.easeOut,
                          ),
              ),
          ],
        );
      },
    );
  }
}

class _DraftChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _FieldStatus? status;
  final bool fullWidth;

  const _DraftChip({
    required this.icon,
    required this.label,
    required this.value,
    this.status,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('es'));
    final needsReview = status == _FieldStatus.review;
    final triad = needsReview
        ? context.appWarningTriad
        : context.appSuccessTriad;

    return Semantics(
      container: true,
      label: status == null
          ? null
          : (needsReview ? l10n.ai_field_review : l10n.ai_field_identified),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
        decoration: BoxDecoration(
          color: context.appSurfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: needsReview ? triad.border : context.appBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: context.appTextSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                ),
                if (status != null)
                  Icon(
                    needsReview ? LucideIcons.eye : LucideIcons.circleCheck,
                    size: 14,
                    color: triad.foreground,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: fullWidth ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.appTextPrimary,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
          ],
        ),
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
