import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/glass_card.dart';
import 'community_provider.dart';

// Industry palette — Indigo / Teal / Violet / Amber
const _indigo = Color(0xFF6366F1);
const _teal = Color(0xFF14B8A6);
const _violet = Color(0xFF8B5CF6);
const _amber = Color(0xFFF59E0B);

const _cardPastels = [
  Color(0xFFFFE4E4),
  Color(0xFFE4F0FF),
  Color(0xFFE4FFE4),
  Color(0xFFFFF8E4),
  Color(0xFFF0E4FF),
  Color(0xFFFFEDE4),
  Color(0xFFE4FFFA),
  Color(0xFFF0F0FF),
];

class CommunityTab extends ConsumerStatefulWidget {
  const CommunityTab({super.key});
  @override
  ConsumerState<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends ConsumerState<CommunityTab> {
  Future<void> _startChat(String userId) async {
    final convId = await ref.read(communityProvider.notifier).getOrCreateConversation(userId);
    if (convId != null && mounted) context.push('/chat/$convId');
  }

  Future<void> _sendRequest(String userId) async {
    await ref.read(communityProvider.notifier).sendFriendRequest(userId);
  }

  void _showProfileDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileSheet(
        userId: user['id'] as String,
        name: user['name'] as String? ?? '',
        avatar: user['avatarUrl'] as String?,
        headline: user['headline'] as String?,
        company: user['currentCompany'] as String?,
        skills: user['skills'] as String?,
        email: user['email'] as String?,
        friendStatus: user['friendStatus'] as String?,
        onChat: () { Navigator.pop(ctx); _startChat(user['id'] as String); },
        onSendRequest: () { Navigator.pop(ctx); _sendRequest(user['id'] as String); },
      ),
    );
  }

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  List<Map<String, dynamic>> _filteredUsers(List<Map<String, dynamic>> users) {
    if (_searchQuery.isEmpty) return users;
    final q = _searchQuery.toLowerCase();
    return users.where((u) {
      final n = (u['name'] as String? ?? '').toLowerCase();
      final h = (u['headline'] as String? ?? '').toLowerCase();
      final c = (u['currentCompany'] as String? ?? '').toLowerCase();
      return n.contains(q) || h.contains(q) || c.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);
    final users = _filteredUsers(state.allUsers);
    final conversations = state.conversations;

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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_indigo, _violet], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Community', style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
            ),
            child: Stack(
              children: [
                IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 22), onPressed: () {}),
                if (conversations.any((c) => c.unreadCount > 0))
                  Positioned(
                    right: 10, top: 10,
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: _amber, shape: BoxShape.circle)),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const GlassMeshBackground(),
          SafeArea(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: _indigo))
                : RefreshIndicator(
                    color: _indigo,
                    onRefresh: () => ref.read(communityProvider.notifier).loadCommunity(),
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        // PREMIUM BANNER — full glass with gradient orbs
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: GlassCard(
                            blur: 16, opacity: 0.62, borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -30, top: -20,
                                  child: Container(
                                    width: 140, height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(colors: [_indigo.withValues(alpha: 0.14), Colors.transparent]),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: -20, bottom: -30,
                                  child: Container(
                                    width: 120, height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(colors: [_teal.withValues(alpha: 0.13), Colors.transparent]),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.72),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.50)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                                            const SizedBox(width: 6),
                                            const Text('Live • 1.2k active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text('Connect. Share.\nSupport. Together!', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, height: 1.15, color: Color(0xFF0F172A), letterSpacing: -0.6)),
                                      const SizedBox(height: 8),
                                      Text('Stay connected with your neighbors and build a stronger community.', style: TextStyle(color: Colors.black.withValues(alpha: 0.55), height: 1.4, fontSize: 13)),
                                      const SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [_indigo, _violet]),
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6))],
                                        ),
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                            elevation: 0,
                                          ),
                                          onPressed: () {},
                                          icon: const Icon(Icons.add_rounded, size: 18),
                                          label: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        _sectionHeader('Community Groups', 'View All', Icons.groups_rounded),
                        ...conversations.take(3).map((c) => _groupTile(
                          title: c.otherUserName,
                          subtitle: c.lastMessage?.isNotEmpty == true ? c.lastMessage! : 'Tap to start conversation',
                          status: c.unreadCount > 0 ? '${c.unreadCount} new' : 'Online',
                          unread: c.unreadCount,
                          onTap: () => context.push('/chat/${c.id}'),
                        )),
                        if (conversations.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: GlassCard(
                              blur: 12, opacity: 0.58, borderRadius: BorderRadius.circular(16),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.70), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.45))),
                                    child: const Icon(Icons.forum_outlined, size: 16, color: _indigo),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(child: Text('No conversations yet. Start chatting with someone!', style: TextStyle(color: Colors.black54, fontSize: 13))),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 18),
                        if (conversations.isNotEmpty) ...[
                          _sectionHeader('Recent Conversations', '${conversations.length}', Icons.chat_bubble_outline_rounded),
                          ...conversations.map((c) => _conversationTile(
                            name: c.otherUserName,
                            msg: c.lastMessage ?? '',
                            unread: c.unreadCount,
                            onTap: () => context.push('/chat/${c.id}'),
                          )),
                          const SizedBox(height: 6),
                        ],

                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [_teal, _indigo]),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Find People', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                                ],
                              ),
                              GlassCard(
                                blur: 8, opacity: 0.62, borderRadius: BorderRadius.circular(20),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Text('${users.length} available', style: const TextStyle(color: _indigo, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) => setState(() => _searchQuery = v),
                                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: 'Search by name, role, company...',
                                  hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.35), fontSize: 13),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(6),
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.65), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.45))),
                                    child: const Icon(Icons.search_rounded, color: _indigo, size: 16),
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.black45), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.62),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.40))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.40))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: _indigo, width: 1.2)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (users.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: GlassCard(
                                blur: 12, opacity: 0.62, borderRadius: BorderRadius.circular(14),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                child: Text(_searchQuery.isNotEmpty ? 'No users found' : 'No users yet', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.82),
                              itemCount: users.length,
                              itemBuilder: (context, i) => _userGridCard(users[i], i),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String action, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                ),
                child: Icon(icon, size: 14, color: _indigo),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A), letterSpacing: -0.3)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
            ),
            child: Text(action, style: const TextStyle(color: _indigo, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _groupTile({required String title, required String subtitle, required String status, required int unread, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GlassCard(
        blur: 16, opacity: 0.62, borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_indigo, _teal]),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: _indigo, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12, height: 1.2)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(status, style: TextStyle(color: unread > 0 ? _amber : const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                  ),
                  child: const Text('9:30 AM', style: TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _conversationTile({required String name, required String msg, required int unread, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassCard(
        blur: 14, opacity: 0.58, borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(1.2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: unread > 0 ? const [_indigo, _violet] : [Colors.white.withValues(alpha: 0.65), Colors.white.withValues(alpha: 0.45)]),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, color: unread > 0 ? _indigo : Colors.black.withValues(alpha: 0.35), size: 19),
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
          subtitle: Text(msg.isEmpty ? 'No messages yet' : msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55))),
          trailing: unread > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_indigo, _violet]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                )
              : Icon(Icons.chevron_right_rounded, color: Colors.black.withValues(alpha: 0.18), size: 20),
        ),
      ),
    );
  }

  Widget _userGridCard(Map<String, dynamic> user, int index) {
    final name = user['name'] as String? ?? '';
    final avatar = user['avatarUrl'] as String?;
    final role = user['headline'] as String?;
    final online = user['online'] as bool? ?? false;
    final userId = user['id'] as String;
    final tint = _cardPastels[index % _cardPastels.length];

    return GestureDetector(
      onTap: () => _showProfileDetails(user),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: tint.withValues(alpha: 0.52),
              border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.1),
              boxShadow: [
                BoxShadow(color: tint.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 6)),
                BoxShadow(color: Colors.white.withValues(alpha: 0.45), blurRadius: 0, offset: const Offset(0, 0)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF1F5F9)]),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.70), width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: _avatar(avatar, name, 32),
                    ),
                    if (online)
                      Positioned(
                        right: 1, bottom: 1,
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981), shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.30), blurRadius: 6)],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF0F172A), letterSpacing: -0.2)),
                ),
                if (role != null && role.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
                    child: Text(role, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.black.withValues(alpha: 0.52), fontWeight: FontWeight.w600)),
                  ),
                SizedBox(height: role != null && role.isNotEmpty ? 6 : 10),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.55)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.38)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _glassIconButton(Icons.chat_bubble_outline_rounded, () => _startChat(userId)),
                      _glassIconButton(Icons.person_outline_rounded, () => _showProfileDetails(user)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Icon(icon, size: 13, color: const Color(0xFF0F172A)),
      ),
    );
  }

  Widget _avatar(String? url, String name, double radius) {
    if (url != null && url.isNotEmpty) return CircleAvatar(radius: radius, backgroundImage: CachedNetworkImageProvider(url));
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: _indigo, fontWeight: FontWeight.w800, fontSize: radius * 0.58)),
    );
  }
}

class _ProfileSheet extends ConsumerStatefulWidget {
  final String userId; final String name; final String? avatar; final String? headline; final String? company; final String? skills; final String? email; final String? friendStatus; final VoidCallback onChat; final VoidCallback onSendRequest;
  const _ProfileSheet({required this.userId, required this.name, this.avatar, this.headline, this.company, this.skills, this.email, this.friendStatus, required this.onChat, required this.onSendRequest});
  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  List<Map<String, dynamic>>? _companies;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final list = await ref.read(communityProvider.notifier).loadUserCompanies(widget.userId);
    if (mounted) setState(() => _companies = list);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 28, offset: const Offset(0, -8))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 1.0, minChildSize: 0.85, maxChildSize: 1.0, expand: false,
              builder: (_, scrollController) => ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Center(child: Container(width: 44, height: 4, margin: const EdgeInsets.only(top: 14, bottom: 14), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(2)))),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withValues(alpha: 0.60), const Color(0xFFEEF2FF).withValues(alpha: 0.70), _teal.withValues(alpha: 0.10)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.55)), bottom: BorderSide(color: Colors.white.withValues(alpha: 0.30))),
                        ),
                      ),
                      Positioned(
                        left: 0, right: 0, top: 56,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [_indigo, _violet]),
                              boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 6))],
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 43,
                                backgroundImage: widget.avatar != null && widget.avatar!.isNotEmpty ? CachedNetworkImageProvider(widget.avatar!) : null,
                                backgroundColor: Colors.white,
                                child: widget.avatar == null || widget.avatar!.isEmpty
                                    ? Text(widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _indigo))
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Text(widget.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                  if (widget.headline != null && widget.headline!.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text(widget.headline!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.52), fontWeight: FontWeight.w500))),
                  if (widget.company != null && widget.company!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_indigo, _violet]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.18), blurRadius: 10)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.business_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(widget.company!, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassCard(
                      blur: 14, opacity: 0.62, borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          _statItem('Friends', '—', _indigo),
                          Container(width: 1, height: 28, color: Colors.black.withValues(alpha: 0.07)),
                          _statItem('Companies', '${_companies?.length ?? 0}', _teal),
                          Container(width: 1, height: 28, color: Colors.black.withValues(alpha: 0.07)),
                          _statItem('Experience', '—', _violet),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (widget.skills != null && widget.skills!.isNotEmpty) ...[
                    _sectionHeader(Icons.code_rounded, 'Skills'),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 8, runSpacing: 8,
                        children: widget.skills!.split(',').map((s) => ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.68),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.50)),
                                boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.08), blurRadius: 8)],
                              ),
                              child: Text(s.trim(), style: const TextStyle(fontSize: 12, color: _indigo, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_companies != null && _companies!.isNotEmpty) ...[
                    _sectionHeader(Icons.work_history_rounded, 'Experience'),
                    const SizedBox(height: 10),
                    ..._companies!.map((c) => _companyTile(c)),
                    const SizedBox(height: 18),
                  ],
                  if (_companies == null)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: _indigo))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                            ),
                            child: OutlinedButton.icon(
                              onPressed: widget.onChat,
                              icon: const Icon(Icons.chat_bubble_rounded, size: 17),
                              label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _indigo, side: const BorderSide(color: _indigo, width: 1.1),
                                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: widget.friendStatus == 'PENDING'
                              ? Container(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.68),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _amber.withValues(alpha: 0.35)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: _amber.withValues(alpha: 0.18), shape: BoxShape.circle), child: const Icon(Icons.hourglass_top_rounded, size: 14, color: _amber)),
                                      const SizedBox(width: 6),
                                      const Text('Pending', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700, fontSize: 13)),
                                    ],
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [_indigo, _violet]),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6))],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: widget.friendStatus == null ? widget.onSendRequest : null,
                                    icon: Icon(widget.friendStatus == 'ACCEPTED' ? Icons.chat_rounded : Icons.person_add_rounded, size: 17),
                                    label: Text(widget.friendStatus == 'ACCEPTED' ? 'Message' : 'Add Friend', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(child: TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: Colors.black.withValues(alpha: 0.38), fontWeight: FontWeight.w700, fontSize: 13)))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.45))), child: Icon(icon, size: 13, color: _indigo)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black.withValues(alpha: 0.72), letterSpacing: 0.4)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color accent) {
    return Expanded(
      child: Column(
        children: [
          Container(width: 28, height: 2.5, decoration: BoxDecoration(color: accent.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.black.withValues(alpha: 0.48), fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        ],
      ),
    );
  }

  Widget _companyTile(Map<String, dynamic> c) {
    final cName = c['name'] as String? ?? '';
    final role = c['role'] as String? ?? '';
    final startDate = c['startDate'] as String?;
    final endDate = c['endDate'] as String?;
    final isCurrent = c['isCurrent'] as bool? ?? false;
    String period = '';
    if (startDate != null) {
      final s = _formatDate(startDate);
      final e = isCurrent ? 'Present' : endDate != null ? _formatDate(endDate) : '';
      period = '$s — $e';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: isCurrent ? _indigo : Colors.black.withValues(alpha: 0.20),
              shape: BoxShape.circle,
              boxShadow: isCurrent ? [BoxShadow(color: _indigo.withValues(alpha: 0.28), blurRadius: 8)] : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassCard(
              blur: 12, opacity: 0.60, borderRadius: BorderRadius.circular(14),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                  if (role.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(role, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55), fontWeight: FontWeight.w500))),
                  if (period.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text(period, style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.38), fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try { final dt = DateTime.parse(iso); return '${dt.day}-${dt.month}-${dt.year}'; } catch (_) { return iso; }
  }
}
