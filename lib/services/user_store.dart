import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

const _uuid = Uuid();

/// In-memory user store for admin-managed accounts.
/// In production, replace with Firestore/backend calls.
class UserStore {
  UserStore._();
  static final UserStore instance = UserStore._();

  // All user accounts (keyed by email → {password, user})
  final Map<String, Map<String, dynamic>> _accounts = {
    'officer@waveslive.com': {
      'password': 'demo123',
      'user': UserModel(
        id: 'usr_officer_001',
        name: 'Arjun Krishnan',
        email: 'officer@waveslive.com',
        role: UserRole.officer,
        organisationId: 'org_cdma_001',
        organisationName: 'Coastal Disaster Management Authority',
        phone: '+91 98765 43210',
        isActive: true,
        createdAt: DateTime(2024, 1, 15),
      ),
    },
    'agent@waveslive.com': {
      'password': 'demo123',
      'user': UserModel(
        id: 'usr_agent_001',
        name: 'Priya Nair',
        email: 'agent@waveslive.com',
        role: UserRole.agent,
        organisationId: 'org_cdma_001',
        organisationName: 'Coastal Disaster Management Authority',
        phone: '+91 87654 32109',
        isActive: true,
        createdAt: DateTime(2024, 3, 10),
      ),
    },
    'volunteer@waveslive.com': {
      'password': 'demo123',
      'user': UserModel(
        id: 'usr_volunteer_001',
        name: 'Rajan Pillai',
        email: 'volunteer@waveslive.com',
        role: UserRole.volunteer,
        organisationId: 'org_volunteer_001',
        organisationName: 'Kerala Coastal Volunteers Network',
        phone: '+91 76543 21098',
        isActive: true,
        createdAt: DateTime(2024, 2, 20),
      ),
    },
    'ngo@waveslive.com': {
      'password': 'demo123',
      'user': UserModel(
        id: 'usr_ngo_001',
        name: 'Meena Subramaniam',
        email: 'ngo@waveslive.com',
        role: UserRole.ngo,
        organisationId: 'org_ngo_001',
        organisationName: 'Sea Guard NGO',
        phone: '+91 65432 10987',
        isActive: true,
        createdAt: DateTime(2024, 1, 5),
      ),
    },
  };

  List<UserModel> get allUsers =>
      _accounts.values.map((e) => e['user'] as UserModel).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  Map<String, dynamic>? getAccount(String email) =>
      _accounts[email.toLowerCase().trim()];

  /// Create a new user account. Returns the created UserModel.
  UserModel createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String organisationName,
    String? phone,
  }) {
    final user = UserModel(
      id: 'usr_${_uuid.v4().substring(0, 8)}',
      name: name,
      email: email.toLowerCase().trim(),
      role: role,
      organisationId: 'org_${_uuid.v4().substring(0, 8)}',
      organisationName: organisationName,
      phone: phone,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _accounts[email.toLowerCase().trim()] = {
      'password': password,
      'user': user,
    };
    return user;
  }

  /// Toggle a user's active status.
  void toggleActive(String email) {
    final acc = _accounts[email.toLowerCase().trim()];
    if (acc == null) return;
    final user = acc['user'] as UserModel;
    _accounts[email.toLowerCase().trim()] = {
      'password': acc['password'],
      'user': UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        organisationId: user.organisationId,
        organisationName: user.organisationName,
        phone: user.phone,
        isActive: !user.isActive,
        createdAt: user.createdAt,
        lastLoginAt: user.lastLoginAt,
      ),
    };
  }

  /// Delete a user account.
  void deleteUser(String email) {
    _accounts.remove(email.toLowerCase().trim());
  }

  bool emailExists(String email) =>
      _accounts.containsKey(email.toLowerCase().trim());
}
