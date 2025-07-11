import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/logout_button_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/profile_menu_item_widget.dart';
import './widgets/profile_section_widget.dart';

// lib/presentation/profile/profile.dart

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRefreshing = false;
  bool _biometricEnabled = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;

  // Mock user data
  final Map<String, dynamic> userData = {
    "name": "Maria Santos",
    "email": "maria.santos@email.com",
    "phone": "+63 917 123 4567",
    "address": "123 Main Street, Quezon City, Metro Manila",
    "accountNumber": "LA-2024-001234",
    "accountStatus": "active",
    "memberSince": "2023-01-15",
    "lastLogin": "2024-01-10 14:30:00",
    "avatarUrl": null,
  };

  final List<Map<String, dynamic>> recentLoginHistory = [
    {
      "device": "iPhone 14 Pro",
      "location": "Quezon City, Metro Manila",
      "timestamp": "2024-01-10 14:30:00",
      "ipAddress": "192.168.1.100",
    },
    {
      "device": "Samsung Galaxy S23",
      "location": "Makati City, Metro Manila",
      "timestamp": "2024-01-09 09:15:00",
      "ipAddress": "192.168.1.101",
    },
    {
      "device": "iPhone 14 Pro",
      "location": "Quezon City, Metro Manila",
      "timestamp": "2024-01-08 18:45:00",
      "ipAddress": "192.168.1.100",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    // Load user preferences from storage
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? false;
      _smsNotifications = prefs.getBool('sms_notifications') ?? true;
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();

    // Simulate API call to refresh user data
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
      userData["lastLogin"] = DateTime.now().toString().substring(0, 19);
    });

    HapticFeedback.selectionClick();
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildEditProfileBottomSheet(),
    );
  }

  Widget _buildEditProfileBottomSheet() {
    final nameController = TextEditingController(text: userData['name']);
    final emailController = TextEditingController(text: userData['email']);
    final phoneController = TextEditingController(text: userData['phone']);
    final addressController = TextEditingController(text: userData['address']);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _saveProfileChanges({
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'address': addressController.text,
                });
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfileChanges(Map<String, String> changes) {
    setState(() {
      userData.addAll(changes);
    });

    Fluttertoast.showToast(
      msg: "Profile updated successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    HapticFeedback.selectionClick();
  }

  void _changeMPIN() {
    Navigator.pushNamed(context, '/mpin-setup');
  }

  void _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = value;
    });
    await prefs.setBool('biometric_enabled', value);

    Fluttertoast.showToast(
      msg: value
          ? "Biometric authentication enabled"
          : "Biometric authentication disabled",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _toggleNotification(String type, bool value) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      switch (type) {
        case 'push':
          _pushNotifications = value;
          prefs.setBool('push_notifications', value);
          break;
        case 'email':
          _emailNotifications = value;
          prefs.setBool('email_notifications', value);
          break;
        case 'sms':
          _smsNotifications = value;
          prefs.setBool('sms_notifications', value);
          break;
      }
    });
  }

  void _viewLoginHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildLoginHistoryBottomSheet(),
    );
  }

  Widget _buildLoginHistoryBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Login History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: recentLoginHistory.length,
              itemBuilder: (context, index) {
                final login = recentLoginHistory[index];
                return _buildLoginHistoryItem(login);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginHistoryItem(Map<String, dynamic> login) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'devices',
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  login['device'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  login['location'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  _formatDateTime(login['timestamp']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Contact Support',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'phone',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Call Support'),
              subtitle: const Text('+63 2 8888 1234'),
              onTap: () {
                Navigator.pop(context);
                // Implement phone call
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'email',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Email Support'),
              subtitle: const Text('support@loantracker.com'),
              onTap: () {
                Navigator.pop(context);
                // Implement email
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'chat',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 24/7'),
              onTap: () {
                Navigator.pop(context);
                // Implement live chat
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _performLogout() async {
    // Clear stored data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate to login screen
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/mobile-number-authentication',
      (route) => false,
    );

    Fluttertoast.showToast(
      msg: "Logged out successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Theme.of(context).colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ProfileHeaderWidget(
                  name: userData["name"] as String,
                  email: userData["email"] as String,
                  phone: userData["phone"] as String,
                  accountNumber: userData["accountNumber"] as String,
                  accountStatus: userData["accountStatus"] as String,
                  memberSince: userData["memberSince"] as String,
                  avatarUrl: userData["avatarUrl"] as String?,
                  onEditPressed: _editProfile,
                ),
              ),
              SliverToBoxAdapter(
                child: ProfileSectionWidget(
                  title: 'Personal Information',
                  icon: 'person',
                  children: [
                    ProfileMenuItemWidget(
                      icon: 'person_outline',
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: _editProfile,
                    ),
                    ProfileMenuItemWidget(
                      icon: 'location_on_outlined',
                      title: 'Address',
                      subtitle: userData["address"] as String,
                      onTap: _editProfile,
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: ProfileSectionWidget(
                  title: 'Account Settings',
                  icon: 'settings',
                  children: [
                    ProfileMenuItemWidget(
                      icon: 'lock_outline',
                      title: 'Change MPIN',
                      subtitle: 'Update your mobile PIN',
                      onTap: _changeMPIN,
                    ),
                    ProfileMenuItemWidget(
                      icon: 'fingerprint',
                      title: 'Biometric Authentication',
                      subtitle: 'Use fingerprint or face recognition',
                      trailing: Switch(
                        value: _biometricEnabled,
                        onChanged: _toggleBiometric,
                      ),
                      onTap: () => _toggleBiometric(!_biometricEnabled),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: ProfileSectionWidget(
                  title: 'Notification Settings',
                  icon: 'notifications',
                  children: [
                    ProfileMenuItemWidget(
                      icon: 'notifications_outlined',
                      title: 'Push Notifications',
                      subtitle: 'Receive push notifications',
                      trailing: Switch(
                        value: _pushNotifications,
                        onChanged: (value) =>
                            _toggleNotification('push', value),
                      ),
                      onTap: () =>
                          _toggleNotification('push', !_pushNotifications),
                    ),
                    ProfileMenuItemWidget(
                      icon: 'email_outlined',
                      title: 'Email Notifications',
                      subtitle: 'Receive email notifications',
                      trailing: Switch(
                        value: _emailNotifications,
                        onChanged: (value) =>
                            _toggleNotification('email', value),
                      ),
                      onTap: () =>
                          _toggleNotification('email', !_emailNotifications),
                    ),
                    ProfileMenuItemWidget(
                      icon: 'sms_outlined',
                      title: 'SMS Notifications',
                      subtitle: 'Receive SMS notifications',
                      trailing: Switch(
                        value: _smsNotifications,
                        onChanged: (value) => _toggleNotification('sms', value),
                      ),
                      onTap: () =>
                          _toggleNotification('sms', !_smsNotifications),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: ProfileSectionWidget(
                  title: 'Security Center',
                  icon: 'security',
                  children: [
                    ProfileMenuItemWidget(
                      icon: 'history',
                      title: 'Login History',
                      subtitle: 'View recent login activity',
                      onTap: _viewLoginHistory,
                    ),
                    ProfileMenuItemWidget(
                      icon: 'privacy_tip_outlined',
                      title: 'Privacy Settings',
                      subtitle: 'Manage your privacy preferences',
                      onTap: () {
                        // Navigate to privacy settings
                      },
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: ProfileSectionWidget(
                  title: 'Support & Help',
                  icon: 'help',
                  children: [
                    ProfileMenuItemWidget(
                      icon: 'help_outline',
                      title: 'Help Center',
                      subtitle: 'Find answers to common questions',
                      onTap: () {
                        // Navigate to help center
                      },
                    ),
                    ProfileMenuItemWidget(
                      icon: 'support_agent',
                      title: 'Contact Support',
                      subtitle: 'Get help from our support team',
                      onTap: _contactSupport,
                    ),
                    ProfileMenuItemWidget(
                      icon: 'feedback_outlined',
                      title: 'Send Feedback',
                      subtitle: 'Help us improve the app',
                      onTap: () {
                        // Navigate to feedback
                      },
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: LogoutButtonWidget(
                  onLogout: _logout,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}