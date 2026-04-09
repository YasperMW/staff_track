import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_provider.dart';
import '../services/image_service.dart';
import '../services/user_profile_service.dart';
import '../config/app_config.dart';

/// A reusable avatar widget that handles profile image display and upload.
///
/// Features:
/// - Displays user's profile image with proper caching
/// - Shows upload progress indicator
/// - Handles image source selection (camera/gallery)
/// - Supports custom sizes and styling
/// - Proper error handling and loading states
class AvatarWidget extends StatefulWidget {
  final String? imageUrl;
  final String? userName;
  final double size;
  final bool editable;
  final VoidCallback? onUploadComplete;
  final VoidCallback? onUploadError;
  final bool showProgressOverlay;
  final Color? backgroundColor;
  final Color? borderColor;
  final IconData? placeholderIcon;
  final double? iconSize;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.userName,
    this.size = 120,
    this.editable = true,
    this.onUploadComplete,
    this.onUploadError,
    this.showProgressOverlay = true,
    this.backgroundColor,
    this.borderColor,
    this.placeholderIcon,
    this.iconSize,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  final ImageService _imageService = ImageService();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _localImagePath;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main avatar
        _buildAvatar(context),
        // Edit button (if editable)
        if (widget.editable && !_isUploading) _buildEditButton(context),
        // Progress overlay
        if (_isUploading && widget.showProgressOverlay) _buildProgressOverlay(context),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final borderColor = widget.borderColor ?? AppTheme.skyBlue;
    final backgroundColor = widget.backgroundColor ?? AppTheme.skyBlue.withValues(alpha: 0.1);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: _buildImageContent(context),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    // If we have a local image path (during/after upload), show it
    if (_localImagePath != null) {
      return Image.file(
        File(_localImagePath!),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      );
    }

    // If we have a URL, show the network image
    final imageUrl = widget.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return _buildNetworkImage(imageUrl);
    }

    // Otherwise show placeholder
    return _buildPlaceholder(context);
  }

  Widget _buildNetworkImage(String imageUrl) {
    // Construct proper URL
    final fullUrl = imageUrl.startsWith('http') &&
            !imageUrl.contains('127.0.0.1') &&
            !imageUrl.contains('localhost')
        ? imageUrl
        : '${AppConfig.apiBaseUrl}/uploads/$imageUrl';

    // Use cache-busting query param to ensure fresh image after upload
    final cacheBuster = DateTime.now().millisecondsSinceEpoch ~/ 60000; // Changes every minute
    final urlWithCache = '$fullUrl?v=$cacheBuster';

    return Image.network(
      urlWithCache,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: widget.size * 0.4,
            height: widget.size * 0.4,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: AppTheme.skyBlue,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      // Enable caching
      cacheWidth: (widget.size * 2).toInt(), // Cache at 2x for retina displays
      cacheHeight: (widget.size * 2).toInt(),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final iconSize = widget.iconSize ?? widget.size * 0.5;
    final icon = widget.placeholderIcon ?? Icons.person_outline;

    return Center(
      child: Icon(
        icon,
        color: AppTheme.skyBlue,
        size: iconSize,
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onTap: _isUploading ? null : () => _showImageSourceDialog(context),
        child: Container(
          padding: EdgeInsets.all(widget.size * 0.07),
          decoration: BoxDecoration(
            color: AppTheme.skyBlue,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: widget.size * 0.17,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOverlay(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size * 0.3,
              height: widget.size * 0.3,
              child: CircularProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            if (widget.size >= 80) ...[
              const SizedBox(height: 4),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.skyBlue),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to take a new photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleImageSelection(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.skyBlue),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select from your photos'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleImageSelection(ImageSource.gallery);
                },
              ),
              if (_localImagePath != null || (widget.imageUrl?.isNotEmpty ?? false))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppTheme.paleRed),
                  title: const Text('Remove Photo'),
                  subtitle: const Text('Use default avatar'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _handleRemovePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      // Pick image
      final result = source == ImageSource.camera
          ? await _imageService.capturePhoto()
          : await _imageService.pickFromGallery();

      // Handle cancellation
      if (result.cancelled) return;

      // Handle error
      if (result.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error!),
              backgroundColor: AppTheme.paleRed,
            ),
          );
        }
        return;
      }

      // Handle missing path
      if (result.path == null) return;

      // Show local image immediately
      if (mounted) {
        setState(() {
          _localImagePath = result.path;
          _isUploading = true;
          _uploadProgress = 0.0;
        });
      }

      // Upload
      await _uploadImage(result.path!);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling image selection: $e');
      }
      if (mounted) {
        setState(() {
          _isUploading = false;
          _localImagePath = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.paleRed,
          ),
        );
        widget.onUploadError?.call();
      }
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _localImagePath = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: AppTheme.paleRed,
          ),
        );
      }
      return;
    }

    try {
      // Simulate progress for better UX (actual progress would require streamed upload)
      if (mounted) {
        setState(() {
          _uploadProgress = 0.3;
        });
      }

      // Upload the image
      final uploadedUrl = await _imageService.uploadImage(imagePath);

      if (mounted) {
        setState(() {
          _uploadProgress = 0.6;
        });
      }

      if (uploadedUrl == null) {
        throw const ImageException('Failed to upload image. Please try again.');
      }

      // Update the backend
      final success = await UserProfileService.updateProfilePhoto(token, uploadedUrl);

      if (mounted) {
        setState(() {
          _uploadProgress = 0.9;
        });
      }

      if (!success) {
        throw const ImageException('Failed to update profile. Please try again.');
      }

      // Update local state in AuthProvider
      await authProvider.updateProfilePhotoLocally(uploadedUrl);

      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onUploadComplete?.call();
      }
    } on ImageException catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _localImagePath = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.paleRed,
          ),
        );
        widget.onUploadError?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _localImagePath = null;
        });
        if (kDebugMode) {
          print('Upload error: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.paleRed,
          ),
        );
        widget.onUploadError?.call();
      }
    }
  }

  Future<void> _handleRemovePhoto() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null) return;

    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.paleRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Update backend to remove photo
      final success = await UserProfileService.updateProfilePhoto(token, '');

      if (success) {
        await authProvider.updateProfilePhotoLocally('');

        if (mounted) {
          setState(() {
            _localImagePath = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo removed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove photo: $e'),
            backgroundColor: AppTheme.paleRed,
          ),
        );
      }
    }
  }
}

/// Enum for image source selection
enum ImageSource { camera, gallery }