import 'dart:async';

import 'package:anon_chat_frontend/core/extensions/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Timer? _typingStopTimer;
  bool _hasSentTypingTrue = false;

  static const _typingStopDelay = Duration(seconds: 2);

  @override
  void dispose() {
    _typingStopTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(ChatProvider provider, String text) {
    if (provider.chatId == null) return;

    final hasContent = text.trim().isNotEmpty;

    if (hasContent) {
      if (!_hasSentTypingTrue) {
        _hasSentTypingTrue = true;
        provider.setTyping(true);
      }
    } else {
      _typingStopTimer?.cancel();
      if (_hasSentTypingTrue) {
        _hasSentTypingTrue = false;
        provider.setTyping(false);
      }
      return;
    }

    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(_typingStopDelay, () {
      _hasSentTypingTrue = false;
      provider.setTyping(false);
    });
  }

  void _sendMessage(ChatProvider provider) {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _typingStopTimer?.cancel();
    if (_hasSentTypingTrue) {
      _hasSentTypingTrue = false;
      provider.setTyping(false);
    }
    provider.sendMessage(text);
    _controller.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121C),
        elevation: 0,
        title: Row(
          children: [
            _PartnerAvatar(profilePicture: provider.partnerProfilePicture),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.username ?? 'Stranger',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Leave chat?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'You will be disconnected and can find a new partner.',
                    style: TextStyle(color: Color(0xFF8888AA)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Stay',
                        style: TextStyle(color: Color(0xFF6C63FF)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        provider.leaveChat();
                      },
                      child: const Text(
                        'Leave',
                        style: TextStyle(color: Color(0xFFFF6B6B)),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(
              Icons.exit_to_app_rounded,
              color: Color(0xFFFF6B6B),
              size: 18,
            ),
            label: const Text(
              'Leave',
              style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.messages.isEmpty
                ? const Center(
                    child: Text(
                      'Say hello! 👋',
                      style: TextStyle(color: Color(0xFF44445A), fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: provider.messages.length,
                    itemBuilder: (_, index) {
                      final msg = provider.messages.reversed.elementAt(index);
                      return _MessageBubble(
                        message: msg,
                        onToggleReaction: (emoji) =>
                            provider.toggleReaction(msg.id, emoji),
                      );
                    },
                  ),
          ),
          if (provider.partnerIsTyping)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TypingIndicatorBubble(),
              ),
            ),
          _buildInputBar(provider),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF12121C),
        border: Border(top: BorderSide(color: Color(0xFF1E1E30))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              onChanged: (text) => _onTextChanged(provider, text),
              onSubmitted: (_) => _sendMessage(provider),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: Color(0xFF44445A)),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: Color(0xFF6C63FF),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(provider),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).setOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Partner avatar in app bar: profile picture or fallback dot.
class _PartnerAvatar extends StatelessWidget {
  final String? profilePicture;

  const _PartnerAvatar({this.profilePicture});

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    if (profilePicture != null && profilePicture!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2E2E4E), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3ECFCF).withOpacity(0.25),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          profilePicture!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _AvatarFallback(),
        ),
      );
    }
    return const SizedBox(
      width: size,
      height: size,
      child: _AvatarFallback(),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF3ECFCF),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3ECFCF),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white24, size: 20),
    );
  }
}

/// Curve that goes 0 → 1 → 0 over [0, 1] for a single bounce.
class _BounceUpDownCurve extends Curve {
  @override
  double transformInternal(double t) {
    if (t <= 0.5) return 2 * t;
    return 2 * (1 - t);
  }
}

/// iMessage-style typing indicator: three bouncing dots in a bubble.
class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _dotOffsets;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Each dot bounces up then down in its segment (iMessage-style)
    const segment = 1 / 3;
    _dotOffsets = List.generate(3, (i) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            i * segment,
            (i + 1) * segment,
            curve: _BounceUpDownCurve(),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: const Radius.circular(4),
          bottomRight: const Radius.circular(18),
        ),
        border: Border.all(color: const Color(0xFF2E2E4E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _dotOffsets[i],
            builder: (_, child) {
              return Transform.translate(
                offset: Offset(0, _dotOffsets[i].value),
                child: child,
              );
            },
            child: Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF8888AA),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ValueChanged<String> onToggleReaction;

  const _MessageBubble({
    required this.message,
    required this.onToggleReaction,
  });

  @override
  Widget build(BuildContext context) {
    // System messages (disconnected, etc.)
    if (!message.isMe && message.text.startsWith('🔌')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2E2E4E)),
            ),
            child: Text(
              message.text,
              style: const TextStyle(color: Color(0xFF8888AA), fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _showReactionPicker(context),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: message.isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4B44CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: message.isMe ? null : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isMe ? 18 : 4),
                  bottomRight: Radius.circular(message.isMe ? 4 : 18),
                ),
                boxShadow: message.isMe
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).setOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
                border: message.isMe
                    ? null
                    : Border.all(color: const Color(0xFF2E2E4E)),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.reactions.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.reactions.entries
                  .map(
                    (entry) => GestureDetector(
                      onTap: () => onToggleReaction(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF2E2E4E)),
                        ),
                        child: Text(
                          '${entry.key} ${entry.value.length}',
                          style: const TextStyle(
                            color: Color(0xFFD7D7F8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    const quick = ['👍', '❤️', '😂', '😮', '😢', '🔥'];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12121C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: quick
              .map(
                (emoji) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onToggleReaction(emoji);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2E2E4E)),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
