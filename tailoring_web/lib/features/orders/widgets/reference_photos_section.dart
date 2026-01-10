import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

/// Reference Photo Data Model (for local storage before upload)
class ReferencePhotoData {
  final String? id; // Temporary ID for local tracking
  final Uint8List? imageBytes; // Image data as bytes
  final String? base64Image; // Base64 encoded image
  final String? fileName;
  final String description;
  final DateTime addedAt;

  ReferencePhotoData({
    this.id,
    this.imageBytes,
    this.base64Image,
    this.fileName,
    required this.description,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  // Convert to base64 for API
  String get imageBase64 {
    if (base64Image != null) return base64Image!;
    if (imageBytes != null) return base64Encode(imageBytes!);
    return '';
  }

  // Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'photo': imageBase64,
      'description': description,
      'file_name': fileName,
    };
  }

  ReferencePhotoData copyWith({String? description}) {
    return ReferencePhotoData(
      id: id,
      imageBytes: imageBytes,
      base64Image: base64Image,
      fileName: fileName,
      description: description ?? this.description,
      addedAt: addedAt,
    );
  }
}

/// Reusable Reference Photos Picker Widget
class ReferencePhotosPicker extends StatefulWidget {
  final List<ReferencePhotoData> initialPhotos;
  final Function(List<ReferencePhotoData>) onPhotosChanged;
  final int maxPhotos;
  final bool readOnly;

  const ReferencePhotosPicker({
    super.key,
    this.initialPhotos = const [],
    required this.onPhotosChanged,
    this.maxPhotos = 5,
    this.readOnly = false,
  });

  @override
  State<ReferencePhotosPicker> createState() => _ReferencePhotosPickerState();
}

class _ReferencePhotosPickerState extends State<ReferencePhotosPicker> {
  late List<ReferencePhotoData> _photos;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
  }

  Future<void> _pickImage() async {
    if (_photos.length >= widget.maxPhotos) {
      _showMaxPhotosMessage();
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final photoData = ReferencePhotoData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imageBytes: bytes,
          fileName: image.name,
          description: '',
        );

        setState(() {
          _photos.add(photoData);
        });

        widget.onPhotosChanged(_photos);
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
    widget.onPhotosChanged(_photos);
  }

  void _updateDescription(int index, String description) {
    setState(() {
      _photos[index] = _photos[index].copyWith(description: description);
    });
    widget.onPhotosChanged(_photos);
  }

  void _showMaxPhotosMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maximum ${widget.maxPhotos} photos allowed'),
        backgroundColor: AppTheme.warning,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with upload button
        Row(
          children: [
            const Icon(
              Icons.photo_library,
              size: 20,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text('Reference Photos', style: AppTheme.bodyMediumBold),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_photos.length}/${widget.maxPhotos}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            const Spacer(),
            if (!widget.readOnly && _photos.length < widget.maxPhotos)
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate, size: 16),
                label: const Text('Add Photo'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Photos grid or empty state
        if (_photos.isEmpty) _buildEmptyState() else _buildPhotosGrid(),
      ],
    );
  }

  Widget _buildEmptyState() {
    if (widget.readOnly) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGrey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                'No reference photos',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGrey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.borderLight,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.add_photo_alternate,
                size: 48,
                color: AppTheme.primaryBlue.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Click to add reference photos',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Neck designs, embroidery patterns, etc.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        return _buildPhotoCard(_photos[index], index);
      },
    );
  }

  Widget _buildPhotoCard(ReferencePhotoData photo, int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.backgroundWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  child: photo.imageBytes != null
                      ? Image.memory(photo.imageBytes!, fit: BoxFit.cover)
                      : Container(
                          color: AppTheme.backgroundGrey,
                          child: const Icon(
                            Icons.image,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                        ),
                ),
                // Delete button
                if (!widget.readOnly)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.danger,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Description input
          Container(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: TextEditingController(text: photo.description),
              decoration: const InputDecoration(
                hintText: 'Description...',
                hintStyle: TextStyle(fontSize: 11),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              readOnly: widget.readOnly,
              onChanged: (value) => _updateDescription(index, value),
            ),
          ),
        ],
      ),
    );
  }
}
