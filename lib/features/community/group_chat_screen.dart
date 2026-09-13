import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';
import 'group_provider.dart';
import 'models/group_model.dart';

const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _teal = Color(0xFF14B8A6);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _green = Color(0xFF10B981);

const _cardPastels = [
  Color(0xFFFFCDD2), Color(0xFFBBDEFB), Color(0xFFC8E6C9),
  Color(0xFFFFE0B2), Color(0xFFE1BEE7), Color(0xFFB2DFDB),
];

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  const GroupChatScreen({super.key, required this.groupId, required this.groupName});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _myStatus;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(groupProvider.notifier).loadMessages(widget.groupId);
      _checkMemberStatus();
    });
  }

  Future<void> _checkMemberStatus() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/groups/${widget.groupId}/is-member');
      if (mounted) setState(() => _myStatus = res.data['status'] as String?);
    } catch (_) {}
  }

  Future<void> _requestJoin() async {
    await ref.read(groupProvider.notifier).requestJoin(widget.groupId);
    await _checkMemberStatus();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent! Waiting for admin approval.')));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(groupProvider.notifier).sendMessage(widget.groupId, text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupProvider);
    final messages = groupState.messages;

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
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_indigo, _violet]),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(widget.groupName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.groupName, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (_myStatus == 'APPROVED')
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: _indigo, size: 22),
              onPressed: _showMembers,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Colors.white, const Color(0xFFF8FAFC)],
              ),
            ),
          ),
          SafeArea(
            child: _myStatus == 'APPROVED'
                ? _buildChat(messages)
                : _buildJoinPending(),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinPending() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_indigo.withValues(alpha: 0.12), _violet.withValues(alpha: 0.08)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_rounded, size: 48, color: _indigo),
            ),
            const SizedBox(height: 20),
            Text(widget.groupName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text(
              _myStatus == 'PENDING' ? 'Your request is pending admin approval' : 'Join this group to start chatting',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (_myStatus == null || _myStatus == 'REJECTED')
              _gradientButton(_myStatus == 'REJECTED' ? 'Request Again' : 'Request to Join', _requestJoin),
            if (_myStatus == 'PENDING')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _amber.withValues(alpha: 0.3)),
                ),
                child: const Text('Pending Approval', style: TextStyle(color: _amber, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat(List<GroupMessageModel> messages) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 48, color: _indigo.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text('No messages yet', style: TextStyle(color: Colors.black38, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text('Be the first to say hello!', style: TextStyle(color: Colors.black26, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    return _groupMessageTile(m);
                  },
                ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.45))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _indigo.withValues(alpha: 0.15)),
                  ),
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12), hintStyle: TextStyle(color: Colors.black38)),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_indigo, _violet]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: _send,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _groupMessageTile(GroupMessageModel m) {
    final isMe = m.senderId == ref.read(authProvider).user?.id;
    final colorIdx = m.senderId.hashCode.abs() % _cardPastels.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _cardPastels[colorIdx], shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text((m.senderName ?? '?')[0].toUpperCase(), style: TextStyle(color: _indigo, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(m.senderName ?? 'Unknown', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isMe ? _indigo : const Color(0xFF0F172A))),
                    const SizedBox(width: 6),
                    Text(_formatTime(m.createdAt), style: const TextStyle(fontSize: 10, color: Colors.black38)),
                  ],
                ),
                const SizedBox(height: 3),
                if (m.isImage && m.fileUrl != null)
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(m.fileUrl!), mode: LaunchMode.externalApplication),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(m.fileUrl!, width: 200, fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) => progress == null ? child : Container(width: 200, height: 120, alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2, color: _indigo)),
                        errorBuilder: (ctx, err, stack) => Container(width: 200, height: 80, decoration: BoxDecoration(color: _indigo.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Icon(Icons.broken_image_rounded, color: _indigo, size: 28)),
                      ),
                    ),
                  )
                else if (m.isLink)
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(m.linkUrl!), mode: LaunchMode.externalApplication),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _violet.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _violet.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link_rounded, size: 16, color: _violet),
                          const SizedBox(width: 6),
                          Flexible(child: Text(m.content ?? 'Open link', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: _violet, decoration: TextDecoration.underline, height: 1.3))),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? _indigo.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.only(topRight: const Radius.circular(14), bottomLeft: const Radius.circular(14), bottomRight: const Radius.circular(14)),
                      border: Border.all(color: (isMe ? _indigo : Colors.black12).withValues(alpha: 0.3)),
                    ),
                    child: Text(m.content ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), height: 1.4)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _showMembers() {
    ref.read(groupProvider.notifier).loadMembers(widget.groupId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MembersSheet(groupId: widget.groupId, groupName: widget.groupName),
    );
  }

  Widget _gradientButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_indigo, _violet]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}

class _MembersSheet extends ConsumerWidget {
  final String groupId;
  final String groupName;
  const _MembersSheet({required this.groupId, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(groupProvider);
    final members = groupState.members;
    final approved = members.where((m) => m.status == 'APPROVED').toList();
    final pending = members.where((m) => m.status == 'PENDING').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.85,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20)],
        ),
        child: Column(
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Members — $groupName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (approved.isNotEmpty) ...[
                    Text('MEMBERS (${approved.length})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _indigo)),
                    const SizedBox(height: 8),
                    ...approved.map((m) => _memberTile(m)),
                    const SizedBox(height: 16),
                  ],
                  if (pending.isNotEmpty) ...[
                    Text('PENDING (${pending.length})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _amber)),
                    const SizedBox(height: 8),
                    ...pending.map((m) => _memberTile(m)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberTile(GroupMemberModel m) {
    final colorIdx = m.userId.hashCode.abs() % _cardPastels.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _cardPastels[colorIdx], shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text((m.userName ?? '?')[0].toUpperCase(), style: const TextStyle(color: _indigo, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.userName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                Text(m.userEmail ?? '', style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: m.status == 'APPROVED' ? _green.withValues(alpha: 0.12) : _amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(m.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: m.status == 'APPROVED' ? _green : _amber)),
          ),
        ],
      ),
    );
  }
}
