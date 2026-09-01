import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'community_provider.dart';

const _primaryGreen = Color(0xFF2E7D32);
const _bg = Color(0xFFFAFAF5);
const _bannerBg = Color(0xFFEAF4E5);

const _cardColors = [
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
    final notifier = ref.read(communityProvider.notifier);
    final convId = await notifier.getOrCreateConversation(userId);
    if (convId != null && mounted) {
      context.push('/chat/$convId');
    }
  }

  Future<void> _sendRequest(String userId) async {
    await ref.read(communityProvider.notifier).sendFriendRequest(userId);
  }

  void _showProfileDetails(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    final name = user['name'] as String? ?? '';
    final avatar = user['avatarUrl'] as String?;
    final headline = user['headline'] as String?;
    final company = user['currentCompany'] as String?;
    final skills = user['skills'] as String?;
    final email = user['email'] as String?;
    final friendStatus = user['friendStatus'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileSheet(
        userId: userId,
        name: name,
        avatar: avatar,
        headline: headline,
        company: company,
        skills: skills,
        email: email,
        friendStatus: friendStatus,
        onChat: () { Navigator.pop(ctx); _startChat(userId); },
        onSendRequest: () { Navigator.pop(ctx); _sendRequest(userId); },
      ),
    );
  }

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredUsers(List<Map<String, dynamic>> users) {
    if (_searchQuery.isEmpty) return users;
    final q = _searchQuery.toLowerCase();
    return users.where((u) {
      final name = (u['name'] as String? ?? '').toLowerCase();
      final headline = (u['headline'] as String? ?? '').toLowerCase();
      final company = (u['currentCompany'] as String? ?? '').toLowerCase();
      return name.contains(q) || headline.contains(q) || company.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);
    final users = _filteredUsers(state.allUsers);
    final conversations = state.conversations;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Community",
          style: TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(communityProvider.notifier).loadCommunity(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // Banner
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _bannerBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Connect. Share.\nSupport. Together!",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Stay connected with your neighbors and build a stronger community.",
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                          label: const Text("Create Group"),
                        ),
                      ],
                    ),
                  ),

                  // Groups header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Community Groups", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("View All", style: TextStyle(color: _primaryGreen)),
                      ],
                    ),
                  ),

                  // Group tiles from conversations
                  ...conversations.take(3).map((c) => _groupTile(
                    title: c.otherUserName,
                    subtitle: c.lastMessage ?? '',
                    members: 'Online',
                    icon: Icons.person,
                    onTap: () => context.push('/chat/${c.id}'),
                  )),

                  if (conversations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Text(
                        "No conversations yet. Start chatting with someone!",
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Recent Conversations
                  if (conversations.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Recent Conversations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...conversations.map((c) => _conversationTile(
                      name: c.otherUserName,
                      msg: c.lastMessage ?? '',
                      unread: c.unreadCount,
                      onTap: () => context.push('/chat/${c.id}'),
                    )),
                  ],

                  const SizedBox(height: 20),

                  // Find People section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Find People", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("${users.length} available", style: const TextStyle(color: _primaryGreen, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search by name, role, company...',
                        prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.black54),
                                onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  if (users.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          _searchQuery.isNotEmpty ? 'No users found' : 'No users yet',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: users.length,
                        itemBuilder: (context, i) => _userGridCard(users[i], i),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _groupTile({
    required String title,
    required String subtitle,
    required String members,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _bannerBg,
                child: Icon(icon, color: _primaryGreen),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    Text(members, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Text("9:30 AM", style: TextStyle(color: _primaryGreen, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conversationTile({
    required String name,
    required String msg,
    required int unread,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _bannerBg,
        child: const Icon(Icons.person, color: _primaryGreen),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("$unread", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _userGridCard(Map<String, dynamic> user, int index) {
    final name = user['name'] as String? ?? '';
    final avatar = user['avatarUrl'] as String?;
    final role = user['headline'] as String?;
    final online = user['online'] as bool? ?? false;
    final userId = user['id'] as String;
    final bgColor = _cardColors[index % _cardColors.length];

    return GestureDetector(
      onTap: () => _showProfileDetails(user),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: bgColor,
          boxShadow: [
            BoxShadow(color: bgColor.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Stack(
              children: [
                _avatar(avatar, name, 34),
                if (online)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textPrimary),
              ),
            ),
            if (role != null && role.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 1, 6, 0),
                child: Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                ),
              ),
            SizedBox(height: role != null && role.isNotEmpty ? 4 : 6),
            Divider(height: 1, thickness: 0.5, color: AppColors.textLight.withValues(alpha: 0.3)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _startChat(userId),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bgColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showProfileDetails(user),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bgColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.person_outline, size: 14, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String? url, String name, double radius) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: CachedNetworkImageProvider(url));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: radius * 0.65)),
    );
  }
}

class _ProfileSheet extends ConsumerStatefulWidget {
  final String userId;
  final String name;
  final String? avatar;
  final String? headline;
  final String? company;
  final String? skills;
  final String? email;
  final String? friendStatus;
  final VoidCallback onChat;
  final VoidCallback onSendRequest;

  const _ProfileSheet({
    required this.userId,
    required this.name,
    this.avatar,
    this.headline,
    this.company,
    this.skills,
    this.email,
    this.friendStatus,
    required this.onChat,
    required this.onSendRequest,
  });

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  List<Map<String, dynamic>>? _companies;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ref.read(communityProvider.notifier).loadUserCompanies(widget.userId);
    if (mounted) setState(() => _companies = list);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.85,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_bannerBg, Color(0xFFF5F5F0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  left: 0, right: 0,
                  top: 50,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundImage: widget.avatar != null && widget.avatar!.isNotEmpty
                          ? CachedNetworkImageProvider(widget.avatar!) : null,
                      backgroundColor: _primaryGreen.withValues(alpha: 0.12),
                      child: widget.avatar == null || widget.avatar!.isEmpty
                          ? Text(widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: _primaryGreen))
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 52),
            Text(widget.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            if (widget.headline != null && widget.headline!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(widget.headline!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ),
            if (widget.company != null && widget.company!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.business, size: 14, color: _primaryGreen),
                    const SizedBox(width: 4),
                    Text(widget.company!, style: const TextStyle(fontSize: 13, color: _primaryGreen, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statItem('Friends', '—'),
                Container(width: 1, height: 30, color: Colors.grey.shade200),
                _statItem('Companies', '${_companies?.length ?? 0}'),
                Container(width: 1, height: 30, color: Colors.grey.shade200),
                _statItem('Experience', '—'),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.skills != null && widget.skills!.isNotEmpty) ...[
              _sectionHeader(Icons.code, 'Skills'),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: widget.skills!.split(',').map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _bannerBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s.trim(), style: const TextStyle(fontSize: 12, color: _primaryGreen, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_companies != null && _companies!.isNotEmpty) ...[
              _sectionHeader(Icons.work_history_outlined, 'Experience'),
              const SizedBox(height: 10),
              ..._companies!.map((c) => _companyTile(c)),
              const SizedBox(height: 20),
            ],
            if (_companies == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onChat,
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryGreen,
                        side: const BorderSide(color: _primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: widget.friendStatus == 'PENDING'
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                              color: AppColors.warning.withValues(alpha: 0.06),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hourglass_empty, size: 18, color: AppColors.warning),
                                SizedBox(width: 6),
                                Text('Pending', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: widget.friendStatus == null ? widget.onSendRequest : null,
                            icon: Icon(widget.friendStatus == 'ACCEPTED' ? Icons.chat : Icons.person_add, size: 18),
                            label: Text(widget.friendStatus == 'ACCEPTED' ? 'Message' : 'Add Friend'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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

    String period;
    if (startDate != null) {
      final start = _formatDate(startDate);
      final end = isCurrent ? 'Present' : endDate != null ? _formatDate(endDate) : '';
      period = '$start - $end';
    } else {
      period = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: isCurrent ? _primaryGreen : AppColors.textLight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                  if (role.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(role, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                  if (period.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(period, style: const TextStyle(fontSize: 11, color: AppColors.textLight))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}-${dt.month}-${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}