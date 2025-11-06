// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/api_service.dart';
import 'edit_profile_page.dart';
import '../../store/pages/store_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  Map<String, dynamic> _profile = {};
  String? _error;
  int _imageRefreshKey = 0; // For forcing image reload

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ProfileService.getProfile();
      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            _profile = result['data'];
            _loading = false;
            _imageRefreshKey++; // Increment to force image reload
          });
          debugPrint(
            '🔄 Profile reloaded, image refresh key: $_imageRefreshKey',
          );
          debugPrint('🖼️ Profile picture URL: ${_profile['profile_picture']}');
        }
      } else {
        if (mounted) {
          setState(() {
            _error = result['message'] ?? 'Failed to load profile';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(profile: _profile)),
    );

    if (result == true) {
      _loadProfile(); // Reload profile after successful edit
    }
  }

  String _getProfileImageUrl(dynamic imageUrl) {
    if (imageUrl == null || imageUrl.toString().isEmpty) {
      return '';
    }

    String url = imageUrl.toString();

    // Fix malformed URLs
    if (url.contains('http://') && url.split('http://').length > 2) {
      final parts = url.split('http://');
      if (parts.length >= 2) {
        final lastPart = parts.last;
        final uri = Uri.tryParse('http://$lastPart');
        if (uri != null) {
          final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
          url = '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
        }
      }
    } else if (url.contains('localhost')) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
        url = '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      }
    } else if (url.startsWith('/storage/')) {
      final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
      url = '$baseUrl$url';
    }

    return url;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 50,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _error!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Profile Header - Simple and Clean
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  // Profile Avatar with Edit
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Profile Picture
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withOpacity(0.1),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child:
                              _profile['profile_picture'] != null &&
                                  _profile['profile_picture']
                                      .toString()
                                      .isNotEmpty
                              ? Builder(
                                  builder: (context) {
                                    final imageUrl = _getProfileImageUrl(
                                      _profile['profile_picture'],
                                    );
                                    final separator = imageUrl.contains('?')
                                        ? '&'
                                        : '?';
                                    return Image.network(
                                      '$imageUrl${separator}t=$_imageRefreshKey', // Cache-busting
                                      key: ValueKey(
                                        'profile_image_${_profile['id']}_$_imageRefreshKey',
                                      ),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 50,
                                              color: colorScheme.primary,
                                            );
                                          },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.person,
                                  size: 50,
                                  color: colorScheme.primary,
                                ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _editProfile,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile['name'] ?? 'No Name',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _profile['email'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildMenuItem(
                    Icons.person_outline_rounded,
                    'Edit Profile',
                    'Update your personal information',
                    _editProfile,
                    colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  _buildMenuItem(
                    Icons.store_rounded,
                    'Store Settings',
                    'Manage your store details',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StoreSettingsPage(),
                        ),
                      );
                    },
                    Colors.blue.shade600,
                  ),
                  const SizedBox(height: 10),
                  _buildMenuItem(
                    Icons.inventory_2_rounded,
                    'Inventory Management',
                    'View and manage your products',
                    () {},
                    Colors.orange.shade600,
                  ),
                  const SizedBox(height: 10),
                  _buildMenuItem(
                    Icons.payment_rounded,
                    'Payment Methods',
                    'Manage payment settings',
                    () {},
                    Colors.green.shade600,
                  ),
                  const SizedBox(height: 10),
                  _buildMenuItem(
                    Icons.help_outline_rounded,
                    'Help & Support',
                    'Get help and contact support',
                    () {},
                    Colors.purple.shade600,
                  ),
                  const SizedBox(height: 28),
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await AuthService.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        shadowColor: Colors.red.withOpacity(0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
