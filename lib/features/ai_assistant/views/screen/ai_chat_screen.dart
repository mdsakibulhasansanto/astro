import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../model/chat_message_model.dart';
import '../../riverpod/ai_assistant_provider.dart';
import '../../../subscription/views/widgets/premium_gate.dart';

const _starters = [
  'Where should my bed go?',
  'Which colours suit my chart?',
  'How can I make my study room calmer?',
  'What does my Moon sign need at home?',
];

/// Chat with the interior assistant about rooms, colours and the chart.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty) return;
    if (!await requirePremium(context, ref, 'The AI assistant')) return;
    _input.clear();
    final future = ref.read(aiChatStateNotifierProvider.notifier).send(value);
    _toBottom();
    await future;
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatStateNotifierProvider);
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Astro Home'),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              tooltip: 'New conversation',
              icon: const Icon(Icons.refresh),
              onPressed: ref.read(aiChatStateNotifierProvider.notifier).clear,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Icon(Icons.auto_awesome, size: 36, color: c.brass),
                      const SizedBox(height: 12),
                      Text('Ask about your space', style: AppTextStyles.display(26, c.ink)),
                      const SizedBox(height: 6),
                      Text(
                        'The assistant knows your calculated chart, Kua directions and rooms. '
                        'It explains and suggests; it does not calculate your chart.',
                        style: TextStyle(color: c.muted),
                      ),
                      const SizedBox(height: 18),
                      for (final s in _starters)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton(
                            onPressed: () => _send(s),
                            style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
                            child: Text(s),
                          ),
                        ),
                    ],
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: state.messages.length + (state.sending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == state.messages.length) return const _Typing();
                      return _Bubble(message: state.messages[i]);
                    },
                  ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(state.error!, style: TextStyle(color: c.fire, fontSize: 13)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask about a room, colours, your chart…',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: state.sending ? null : _send,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mine = message.role == ChatRole.user;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: mine ? c.ink : c.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            border: mine ? null : Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                message.text,
                style: TextStyle(color: mine ? c.bg : c.ink, height: 1.45),
              ),
              if (message.failed)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Not sent', style: TextStyle(color: c.fire, fontSize: 11.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line),
        ),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: c.brass),
        ),
      ),
    );
  }
}
