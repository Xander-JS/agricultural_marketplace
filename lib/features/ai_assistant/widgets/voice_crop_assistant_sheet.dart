import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
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
      AppLocalizations.of(context) ?? lookupAppLocalizations(const Locale('es'));

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
    final theme = Theme.of(context);
    final l10n = _l10n;
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      key: const Key('voice_crop_close_button'),
                      tooltip: l10n.ai_close,
                      onPressed: _closing ? null : () => _close(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  l10n.ai_title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.ai_subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInstructionCard(theme),
                if (!_aiService.isConfigured) ...[
                  const SizedBox(height: 12),
                  _buildAiConfigNotice(theme),
                ],
                const SizedBox(height: 20),
                _buildPhaseContent(theme),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('voice_crop_cancel_button'),
                  onPressed: _closing ? null : () => _close(),
                  child: Text(l10n.common_cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mic_none, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.ai_examples_title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _l10n.ai_examples_desc,
                ),
                const SizedBox(height: 6),
                Text(
                  _l10n.ai_example_text,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiConfigNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_l10n.ai_unavailable_title} '
              '${_l10n.ai_unavailable_desc}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent(ThemeData theme) {
    switch (_phase) {
      case _VoicePhase.ready:
        return _buildReady(theme);
      case _VoicePhase.preparing:
        return _buildSpinner(_l10n.ai_preparing);
      case _VoicePhase.permissionDenied:
        return _buildAvailabilityError(
          theme,
          title: _l10n.ai_permission_title,
          message: _l10n.ai_permission_desc,
        );
      case _VoicePhase.unavailable:
        return _buildAvailabilityError(
          theme,
          title: _l10n.ai_voice_unavailable_title,
          message: _l10n.ai_voice_unavailable_desc,
        );
      case _VoicePhase.listening:
        return _buildListening(theme);
      case _VoicePhase.transcribing:
        return _buildSpinner(_l10n.ai_transcribing);
      case _VoicePhase.reviewingTranscript:
        return _buildTranscriptReview(theme);
      case _VoicePhase.processing:
        return _buildSpinner(_l10n.ai_interpreting);
      case _VoicePhase.result:
        return _buildResult(theme);
      case _VoicePhase.error:
        return _buildError(theme);
    }
  }

  Widget _buildReady(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _l10n.ai_intro,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('voice_crop_start_button'),
          onPressed: _startListening,
          icon: const Icon(Icons.mic),
          label: Text(_l10n.ai_start),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('voice_crop_manual_button'),
          onPressed: _continueManually,
          icon: const Icon(Icons.edit_document),
          label: Text(_l10n.ai_manual),
        ),
      ],
    );
  }

  Widget _buildSpinner(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildAvailabilityError(
    ThemeData theme, {
    required String title,
    required String message,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mic_off, size: 44, color: theme.colorScheme.error),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('voice_crop_retry_microphone_button'),
          onPressed: _startListening,
          icon: const Icon(Icons.refresh),
          label: Text(_l10n.ai_retry_mic),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('voice_crop_manual_button'),
          onPressed: _continueManually,
          child: Text(_l10n.ai_continue_manual),
        ),
      ],
    );
  }

  Widget _buildListening(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic, size: 44, color: theme.colorScheme.error),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _l10n.ai_listening,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _partialTranscript.isEmpty
                ? _l10n.ai_listening_hint
                : _partialTranscript,
            key: const Key('voice_crop_partial_transcript'),
            style: theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('voice_crop_stop_button'),
          onPressed: _stopListening,
          icon: const Icon(Icons.stop),
          label: Text(_l10n.ai_stop_review),
        ),
      ],
    );
  }

  Widget _buildTranscriptReview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _l10n.ai_review_transcript_title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _l10n.ai_review_transcript_desc,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('voice_crop_transcript_field'),
          controller: _transcriptController,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: _l10n.ai_transcript_label,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('voice_crop_interpret_button'),
          onPressed: _interpretTranscript,
          icon: const Icon(Icons.auto_awesome),
          label: Text(_l10n.ai_interpret),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('voice_crop_record_again_button'),
          onPressed: _startListening,
          icon: const Icon(Icons.mic),
          label: Text(_l10n.ai_record_again),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('voice_crop_manual_button'),
          onPressed: _continueManually,
          child: Text(_l10n.ai_continue_manual),
        ),
      ],
    );
  }

  Widget _buildResult(ThemeData theme) {
    final draft = _draft;
    if (draft == null) {
      return _buildError(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _l10n.ai_recognized_title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _l10n.ai_recognized_desc,
        ),
        const SizedBox(height: 12),
        _buildDraftSummary(theme, draft),
        if (!draft.hasAnyUsableData) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _l10n.ai_no_data_desc,
            ),
          ),
        ],
        if (draft.warnings.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildListSection(
            theme,
            title: _l10n.ai_warnings,
            items: draft.warnings,
            color: theme.colorScheme.tertiary,
          ),
        ],
        if (draft.reviewFields.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildFieldSection(
            theme,
            title: _l10n.ai_confirm_data,
            fields: draft.reviewFields,
            color: theme.colorScheme.tertiary,
          ),
        ],
        if (draft.missingFields.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildFieldSection(
            theme,
            title: _l10n.ai_missing_data,
            fields: draft.missingFields,
            color: theme.colorScheme.error,
          ),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const Key('voice_crop_continue_button'),
          onPressed: draft.hasAnyUsableData ? _continueWithDraft : null,
          icon: const Icon(Icons.arrow_forward),
          label: Text(_l10n.ai_review_continue),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('voice_crop_retry_button'),
          onPressed: _interpretTranscript,
          icon: const Icon(Icons.refresh),
          label: Text(_l10n.ai_retry_interpret),
        ),
        const SizedBox(height: 8),
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

  Widget _buildDraftSummary(ThemeData theme, VoiceCropDraft draft) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (draft.cropType != null) _summaryRow(_l10n.ai_crop, draft.cropType!),
          if (draft.quantityDescription != null)
            _summaryRow(_l10n.ai_quantity, draft.quantityDescription!),
          if (draft.pricePerKg != null)
            _summaryRow(
              _l10n.ai_price,
              CurrencyFormatters.formatPricePerKg(draft.pricePerKg),
            ),
          if (draft.notes != null) _summaryRow(_l10n.ai_note, draft.notes!),
          if (draft.cropType == null &&
              draft.quantityDescription == null &&
              draft.pricePerKg == null)
            Text(_l10n.ai_no_data),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildListSection(
    ThemeData theme, {
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(item)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldSection(
    ThemeData theme, {
    required String title,
    required List<VoiceCropField> fields,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: fields
              .map(
                (field) => Chip(
                  label: Text(field.label),
                  side: BorderSide(color: color),
                  backgroundColor: color.withValues(alpha: 0.08),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.error_outline, size: 44, color: theme.colorScheme.error),
        const SizedBox(height: 8),
        Text(
          _l10n.ai_failed_title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? _l10n.ai_failed_desc,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('voice_crop_retry_button'),
          onPressed: _retry,
          icon: const Icon(Icons.refresh),
          label: Text(_l10n.common_retry),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('voice_crop_record_again_button'),
          onPressed: _resetToReady,
          icon: const Icon(Icons.mic),
          label: Text(_l10n.ai_record_again),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('voice_crop_manual_button'),
          onPressed: _continueManually,
          child: Text(_l10n.ai_continue_manual),
        ),
      ],
    );
  }
}
