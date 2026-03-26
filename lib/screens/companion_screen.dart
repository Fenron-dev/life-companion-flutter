import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';

class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'initial',
      role: MessageRole.ai,
      content: 'Hallo. Ich bin dein Companion. Wie war dein Tag bisher?',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ),
  ];

  bool _isLoading = false;     // true while resolving backend / loading model
  String? _streamingContent;   // non-null while tokens are streaming in

  bool get _isBusy => _isLoading || _streamingContent != null;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isBusy) return;

    _inputController.clear();

    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.user,
        content: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final db = ref.read(databaseProvider);
      final ai = ref.read(aiServiceProvider);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final notes = await db.getNotesForDate(today);
      final logs = await db.getLogsForDate(today);

      final context = StringBuffer()
        ..writeln('[BEGIN USER NOTES]')
        ..writeln(notes.map((n) => n.content).join('; '))
        ..writeln('[END USER NOTES]')
        ..writeln('Auto-logged events: ${logs.length}');

      final stream = ai.chatStream(
        message: text,
        context: context.toString(),
      );

      // Switch from loading indicator to streaming bubble
      if (mounted) {
        setState(() {
          _isLoading = false;
          _streamingContent = '';
        });
      }

      await for (final chunk in stream) {
        if (mounted) {
          setState(() => _streamingContent = (_streamingContent ?? '') + chunk);
          _scrollToBottom();
        }
      }

      // Finalize: move streamed content into message list
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            id: _uuid.v4(),
            role: MessageRole.ai,
            content: _streamingContent ?? '',
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ));
          _streamingContent = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _streamingContent = null;
          _isLoading = false;
          _messages.add(ChatMessage(
            id: _uuid.v4(),
            role: MessageRole.ai,
            content: 'Fehler: $e',
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ));
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Companion', style: theme.headlineLarge),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text('ALWAYS LISTENING', style: theme.labelSmall),
                ],
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _messages.length +
                (_isLoading ? 1 : 0) +
                (_streamingContent != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _messages.length) {
                final msg = _messages[index];
                return _MessageBubble(key: ValueKey(msg.id), message: msg);
              }
              if (_isLoading) return _buildTypingIndicator();
              if (_streamingContent != null) {
                return _buildStreamingBubble(_streamingContent!);
              }
              return const SizedBox();
            },
          ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  onSubmitted: (_) => _handleSend(),
                  enabled: !_isBusy,
                  decoration: const InputDecoration(
                    hintText: 'Schreib mir...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isBusy
                      ? AppColors.mutedText
                      : AppColors.accent,
                ),
                child: IconButton(
                  onPressed: _isBusy ? null : _handleSend,
                  icon: const Icon(Icons.send, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const _TypingDots(),
      ),
    );
  }

  Widget _buildStreamingBubble(String content) {
    final theme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: content.isEmpty
            ? const _TypingDots()
            : MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 14, color: AppColors.textBody),
                ),
              ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(32),
            topRight: const Radius.circular(32),
            bottomLeft: isUser ? const Radius.circular(32) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(32),
          ),
          border: isUser ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: isUser
            ? Text(
                message.content,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 14, color: AppColors.textBody),
                ),
              ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final bounce = (value < 0.5 ? value * 2 : (1 - value) * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -bounce * 6),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
