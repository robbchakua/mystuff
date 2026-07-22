import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OptionalImageSelection {
  final File? file;
  final bool removeExisting;

  const OptionalImageSelection({this.file, this.removeExisting = false});
}

class OptionalImagePicker extends StatefulWidget {
  final String? existingImage;
  final ValueChanged<OptionalImageSelection> onChanged;
  final String label;

  const OptionalImagePicker({
    super.key,
    this.existingImage,
    required this.onChanged,
    this.label = 'Picture',
  });

  @override
  State<OptionalImagePicker> createState() => _OptionalImagePickerState();
}

class _OptionalImagePickerState extends State<OptionalImagePicker> {
  File? _file;
  bool _removeExisting = false;

  bool get _hasExisting =>
      !_removeExisting && (widget.existingImage?.trim().isNotEmpty ?? false);

  Future<void> _pick(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 35,
      maxWidth: 2048,
    );
    if (image == null || !mounted) return;
    setState(() {
      _file = File(image.path);
      _removeExisting = false;
    });
    widget.onChanged(OptionalImageSelection(file: _file));
  }

  void _useNoImage() {
    setState(() {
      _file = null;
      _removeExisting = true;
    });
    widget.onChanged(const OptionalImageSelection(removeExisting: true));
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              color: inverseColor(context),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: secondaryColor(context),
                border: Border.all(color: inverseColor(context)),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _file != null
                  ? Image.file(_file!, fit: BoxFit.cover)
                  : _hasExisting
                      ? CachedNetworkImage(
                          imageUrl: '${Urls.baseUrl}/${widget.existingImage}',
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Icon(
                                Icons.image_not_supported,
                                color: inverseColor(context),
                              ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: 44,
                                color: inverseColor(context),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No image selected',
                                style: TextStyle(
                                  color: inverseColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                style: OutlinedButton.styleFrom(
                  foregroundColor: inverseColor(context),
                  side: BorderSide(color: inverseColor(context)),
                ),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Camera'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  foregroundColor: inverseColor(context),
                  side: BorderSide(color: inverseColor(context)),
                ),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
              OutlinedButton.icon(
                onPressed: _file != null || _hasExisting ? _useNoImage : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: inverseColor(context),
                  disabledForegroundColor:
                      inverseColor(context).withOpacity(0.4),
                  side: BorderSide(color: inverseColor(context)),
                ),
                icon: const Icon(Icons.hide_image_outlined),
                label: const Text('No image'),
              ),
            ],
          ),
        ],
      );
}
