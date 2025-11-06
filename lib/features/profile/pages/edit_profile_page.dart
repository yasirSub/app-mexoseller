import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/profile_service.dart';
import '../../../services/token_storage.dart';
import '../../../services/api_service.dart';
import '../../../constants/endpoints.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  bool _loading = false;
  String? _error;

  // Image handling
  File? _selectedImageFile;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile['name'] ?? '';
    _phoneController.text = widget.profile['phone'] ?? '';
    _businessNameController.text = widget.profile['business_name'] ?? '';
    _businessAddressController.text = widget.profile['business_address'] ?? '';

    // Load existing profile picture if available
    final profilePicture = widget.profile['profile_picture'];
    if (profilePicture != null && profilePicture.toString().isNotEmpty) {
      _uploadedImageUrl = profilePicture.toString();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await TokenStorage.readToken();
      // debug: ensure token present
      // ignore: avoid_print
      print('Update profile token: $token');

      if (token == null || token.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Not authenticated. Please login again.';
        });
        return;
      }

      // If image was uploaded but not yet saved, upload it now
      if (_selectedImageFile != null && _uploadedImageUrl == null) {
        await _uploadImage();
        if (_uploadedImageUrl == null) {
          setState(() => _loading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please wait for image upload to complete'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'business_name': _businessNameController.text.trim(),
        'business_address': _businessAddressController.text.trim(),
      };

      // Add profile picture URL if available
      if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
        updateData['profile_picture'] = _uploadedImageUrl!;
      }

      final result = await ProfileService.updateProfile(updateData);

      // ignore: avoid_print
      print('Update profile response: $result');

      setState(() => _loading = false);

      if (result['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        setState(() {
          _error = result['message'] ?? 'Update failed';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to update profile: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(92),
        // Custom curved app bar matching dashboard style
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 18, left: 16, right: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Profile Picture Upload Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child:
                                _selectedImageFile != null ||
                                    _uploadedImageUrl != null
                                ? (_selectedImageFile != null
                                      ? Image.file(
                                          _selectedImageFile!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        )
                                      : _uploadedImageUrl != null
                                      ? Image.network(
                                          _getProfileImageUrl(
                                            _uploadedImageUrl!,
                                          ),
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return _buildProfilePlaceholder();
                                              },
                                          loadingBuilder: (context, child, loadingProgress) {
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
                                        )
                                      : _buildProfilePlaceholder())
                                : _buildProfilePlaceholder(),
                          ),
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (_selectedImageFile != null ||
                            _uploadedImageUrl != null)
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImageFile = null;
                                  _uploadedImageUrl = null;
                                });
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade500,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Profile Picture',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: 'Business Name',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Business name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _businessAddressController,
                decoration: InputDecoration(
                  labelText: 'Business Address',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.deepPurple,
                  elevation: 2,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _uploadedImageUrl = null; // Clear previous URL
        });
        await _uploadImage();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImageFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final response = await ApiService.uploadImage(
        Endpoints.uploadImage,
        _selectedImageFile!,
        type: 'profile',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String imageUrl = data['url'] ?? '';

        // Fix malformed URLs
        if (imageUrl.contains('http://') &&
            imageUrl.split('http://').length > 2) {
          final parts = imageUrl.split('http://');
          if (parts.length >= 2) {
            final lastPart = parts.last;
            final uri = Uri.tryParse('http://$lastPart');
            if (uri != null) {
              final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
              imageUrl =
                  '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
            }
          }
        } else if (imageUrl.contains('localhost')) {
          final uri = Uri.tryParse(imageUrl);
          if (uri != null) {
            final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
            imageUrl =
                '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
          }
        } else if (imageUrl.startsWith('/storage/')) {
          final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
          imageUrl = '$baseUrl$imageUrl';
        }

        setState(() {
          _uploadedImageUrl = imageUrl;
          _isUploadingImage = false;
        });
        debugPrint(
          '✅ Profile picture uploaded successfully: $_uploadedImageUrl',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint('❌ Profile picture upload failed: ${response.statusCode}');
        setState(() => _isUploadingImage = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload image: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfilePlaceholder() {
    return Icon(Icons.person, size: 60, color: Colors.grey.shade400);
  }

  String _getProfileImageUrl(String imageUrl) {
    // Fix malformed URLs
    if (imageUrl.contains('http://') && imageUrl.split('http://').length > 2) {
      final parts = imageUrl.split('http://');
      if (parts.length >= 2) {
        final lastPart = parts.last;
        final uri = Uri.tryParse('http://$lastPart');
        if (uri != null) {
          final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
          return '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
        }
      }
    } else if (imageUrl.contains('localhost')) {
      final uri = Uri.tryParse(imageUrl);
      if (uri != null) {
        final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
        return '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      }
    } else if (imageUrl.startsWith('/storage/')) {
      final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
      return '$baseUrl$imageUrl';
    }

    return imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }
}
