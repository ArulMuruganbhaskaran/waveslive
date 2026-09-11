import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../models/user_model.dart';
import '../../services/user_store.dart';
import 'admin_login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: UserRole.manageable.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<UserModel> _filteredUsers(String? roleFilter) {
    return UserStore.instance.allUsers.where((u) {
      final matchRole = roleFilter == null || u.role == roleFilter;
      final matchSearch = _search.isEmpty ||
          u.name.toLowerCase().contains(_search.toLowerCase()) ||
          u.email.toLowerCase().contains(_search.toLowerCase()) ||
          u.organisationName.toLowerCase().contains(_search.toLowerCase());
      return matchRole && matchSearch;
    }).toList();
  }

  Map<String, int> get _roleCounts {
    final users = UserStore.instance.allUsers;
    return {
      for (final r in UserRole.manageable)
        r: users.where((u) => u.role == r).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final counts = _roleCounts;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF0A1628),
            leading: const SizedBox.shrink(),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                tooltip: 'Sign Out',
                onPressed: () => context.go(AppRoutes.adminLogin),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1628), Color(0xFF0A3D62)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded,
                                color: AppColors.accent, size: 20),
                            const SizedBox(width: 8),
                            const Text('WavesLive',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('MASTER ADMIN',
                                  style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('User Management',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          '${UserStore.instance.allUsers.length} total accounts',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: const Color(0xFF0D2744),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.accent,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: [
                    const Tab(text: 'All Users'),
                    ...UserRole.manageable.map((r) => Tab(
                          text:
                              '${UserRole.displayName(r)} (${counts[r] ?? 0})',
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Summary stat cards
            _buildStatsRow(counts),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search by name, email or organisation…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _UserList(users: _filteredUsers(null), onRefresh: _refresh),
                  ...UserRole.manageable.map(
                    (r) => _UserList(
                        users: _filteredUsers(r), onRefresh: _refresh),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        backgroundColor: const Color(0xFF0A3D62),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Create User',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, int> counts) {
    final roleIcons = {
      UserRole.officer: Icons.security_rounded,
      UserRole.agent: Icons.camera_alt_rounded,
      UserRole.volunteer: Icons.volunteer_activism_rounded,
      UserRole.ngo: Icons.groups_rounded,
    };
    final roleColors = {
      UserRole.officer: AppColors.primaryDeep,
      UserRole.agent: AppColors.agentColor,
      UserRole.volunteer: AppColors.volunteerColor,
      UserRole.ngo: AppColors.accent,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: UserRole.manageable.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final role = UserRole.manageable[i];
            final color = roleColors[role]!;
            return Container(
              width: 130,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(roleIcons[role], color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${counts[role] ?? 0}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                      Text(
                        _shortRoleName(role),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _shortRoleName(String role) {
    switch (role) {
      case UserRole.officer:
        return 'Officers';
      case UserRole.agent:
        return 'Agents';
      case UserRole.volunteer:
        return 'Volunteers';
      case UserRole.ngo:
        return 'NGOs';
      default:
        return role;
    }
  }

  void _refresh() => setState(() {});

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateUserDialog(onCreated: _refresh),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User list
// ─────────────────────────────────────────────────────────────────────────────
class _UserList extends StatelessWidget {
  final List<UserModel> users;
  final VoidCallback onRefresh;

  const _UserList({required this.users, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 56, color: Color(0xFFCCD0D5)),
            SizedBox(height: 12),
            Text('No users found',
                style: TextStyle(fontSize: 16, color: Color(0xFFADB5BD))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: users.length,
      itemBuilder: (context, i) =>
          _UserTile(user: users[i], onRefresh: onRefresh),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual user tile
// ─────────────────────────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onRefresh;

  const _UserTile({required this.user, required this.onRefresh});

  Color _roleColor(String role) {
    switch (role) {
      case UserRole.officer:
        return AppColors.primaryDeep;
      case UserRole.agent:
        return AppColors.agentColor;
      case UserRole.volunteer:
        return AppColors.volunteerColor;
      case UserRole.ngo:
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
                if (!user.isActive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.grey),
                    ),
                  )
                else
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.shade400,
                          border:
                              Border.all(color: Colors.white, width: 1.5)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          UserRole.displayName(user.role),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (!user.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('INACTIVE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.organisationName,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textHint),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (value) => _handleAction(context, value),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                          user.isActive
                              ? Icons.block_rounded
                              : Icons.check_circle_outline,
                          size: 18,
                          color: user.isActive
                              ? Colors.orange
                              : Colors.green),
                      const SizedBox(width: 8),
                      Text(user.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    if (action == 'toggle') {
      UserStore.instance.toggleActive(user.email);
      onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(user.isActive
            ? '${user.name} deactivated'
            : '${user.name} activated'),
        behavior: SnackBarBehavior.floating,
      ));
    } else if (action == 'delete') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete User'),
          content:
              Text('Are you sure you want to delete ${user.name}? This cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                UserStore.instance.deleteUser(user.email);
                Navigator.pop(context);
                onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${user.name} deleted'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: const Text('Delete',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create User Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _CreateUserDialog extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateUserDialog({required this.onCreated});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedRole = UserRole.officer;
  bool _obscure = true;
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _orgCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Color _roleColor(String role) {
    switch (role) {
      case UserRole.officer:
        return AppColors.primaryDeep;
      case UserRole.agent:
        return AppColors.agentColor;
      case UserRole.volunteer:
        return AppColors.volunteerColor;
      case UserRole.ngo:
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case UserRole.officer:
        return Icons.security_rounded;
      case UserRole.agent:
        return Icons.camera_alt_rounded;
      case UserRole.volunteer:
        return Icons.volunteer_activism_rounded;
      case UserRole.ngo:
        return Icons.groups_rounded;
      default:
        return Icons.person;
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    if (UserStore.instance.emailExists(_emailCtrl.text.trim())) {
      setState(() => _error = 'An account with this email already exists.');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    UserStore.instance.createUser(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: _selectedRole,
      organisationName: _orgCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);
    widget.onCreated();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '✓ ${_nameCtrl.text.trim()} (${UserRole.displayName(_selectedRole)}) created successfully'),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(_selectedRole);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_roleIcon(_selectedRole),
                          color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create New User',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          Text('Fill in the details below',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Role selector
                const Text('Role',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: UserRole.manageable.map((role) {
                    final selected = _selectedRole == role;
                    final rc = _roleColor(role);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRole = role),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? rc
                              : rc.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: selected
                                  ? rc
                                  : rc.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_roleIcon(role),
                                size: 14,
                                color: selected ? Colors.white : rc),
                            const SizedBox(width: 6),
                            Text(
                              UserRole.displayName(role),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : rc,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Fields
                _field(_nameCtrl, 'Full Name', Icons.person_outline,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _field(_emailCtrl, 'Email Address', Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                }),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon:
                        const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(_orgCtrl, 'Organisation Name', Icons.business_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _field(_phoneCtrl, 'Phone (optional)', Icons.phone_outlined,
                    keyboardType: TextInputType.phone),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(_error!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isCreating ? null : _create,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isCreating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded,
                            color: Colors.white),
                    label: Text(
                      _isCreating ? 'Creating…' : 'Create Account',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: validator,
    );
  }
}
