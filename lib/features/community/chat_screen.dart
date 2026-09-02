import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/glass_card.dart';
import '../auth/auth_provider.dart';
import 'community_provider.dart';
import 'models/message_model.dart';

const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _teal = Color(0xFF14B8A6);

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(communityProvider.notifier).startMessagePolling(widget.conversationId));
  }

  @override
  void dispose() {
    ref.read(communityProvider.notifier).stopMessagePolling();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    ref.read(communityProvider.notifier).sendMessage(widget.conversationId, t);
    _controller.clear();
    Future.microtask(() => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  String _fmt(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);
    final me = ref.watch(authProvider).user?.id;
    final msgs = state.messages;
    final conv = state.conversations.where((c) => c.id == widget.conversationId).firstOrNull;
    final otherName = conv?.otherUserName ?? 'Chat';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.68),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.38))),
              ),
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 20), onPressed: () => Navigator.pop(context)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_indigo, _teal])),
              child: const CircleAvatar(radius: 16, backgroundColor: Colors.white, child: Icon(Icons.person_rounded, size: 16, color: _indigo)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherName, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('Online • active now', style: TextStyle(color: Colors.black.withValues(alpha: 0.50), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.68), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.45))),
            child: IconButton(icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A), size: 18), onPressed: () {}),
          ),
        ],
      ),
      body: Stack(
        children: [
          const GlassMeshBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: msgs.isEmpty
                      ? Center(
                          child: GlassCard(
                            blur: 14, opacity: 0.62, borderRadius: BorderRadius.circular(16),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [_indigo, _violet]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 14),
                                ),
                                const SizedBox(width: 10),
                                const Text('No messages yet. Say hello!', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                          itemCount: msgs.length,
                          itemBuilder: (_, i) => _bubble(msgs[i], me, otherName),
                        ),
                ),
                _inputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(MessageModel m, String? me, String otherName) {
    final mine = m.senderId == me;
    final t = _fmt(m.createdAt);

    if (mine) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1).withValues(alpha: 0.92), const Color(0xFF8B5CF6).withValues(alpha: 0.88)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (m.content != null && m.content!.isNotEmpty)
                      Align(alignment: Alignment.centerLeft, child: Text(m.content!, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35, fontWeight: FontWeight.w500))),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Icon(m.read ? Icons.done_all_rounded : Icons.done_rounded, size: 13, color: Colors.white.withValues(alpha: 0.85)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                ),
                child: Text(otherName.split(' ').first, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: _indigo, letterSpacing: 0.3)),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.50)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (m.content != null && m.content!.isNotEmpty)
                        Text(m.content!, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, height: 1.35, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 5),
                      Text(t, style: TextStyle(fontSize: 10, color: Colors.black.withValues(alpha: 0.42), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.68),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.40))),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.72), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.45))),
                child: IconButton(icon: const Icon(Icons.add_rounded, color: Color(0xFF0F172A), size: 20), onPressed: () {}),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.35), fontSize: 13, fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.82),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.45))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.45))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: _indigo, width: 1.2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_indigo, _violet]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.30), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18), onPressed: _send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
