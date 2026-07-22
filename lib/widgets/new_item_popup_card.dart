import 'dart:io';

import 'package:dad_app/models/item_model.dart';
import 'package:dad_app/models/location_model.dart';
import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/item_tags_field.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';

class NewItemColumn extends StatefulWidget {
  const NewItemColumn({super.key});

  @override
  State<NewItemColumn> createState() => NewItemColumnState();
}

class NewItemColumnState extends State<NewItemColumn> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final formKey = GlobalKey<FormState>();

  bool multipleBool = false;
  int? selectedBinId;
  List<String> selectedTags = [];

  @override
  void initState() {
    super.initState();
    final bins = editableBins();
    if (bins.isNotEmpty) selectedBinId = bins.first.id;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<Color?> _pickColor(Color initial) async {
    var selected = initial;
    return showDialog<Color>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pick a bin color'),
        content: ColorPicker(
          pickerColor: selected,
          onColorChanged: (value) => selected = value,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, selected),
            child: const ButtonText('Choose color'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBin() async {
    final binFormKey = GlobalKey<FormState>();
    var binName = '';
    var binDescription = '';
    int? parentId = selectedBinId;
    Color color = Colors.red;
    File? binImage;

    final created = await showDialog<SQLResponse?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Bin'),
          content: SingleChildScrollView(
            child: Form(
              key: binFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    onChanged: (value) => binName = value,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return InputErrors.empty;
                      }
                      final duplicate = locationsJsonList.any((bin) =>
                          bin.parentId == parentId &&
                          bin.name?.toLowerCase() ==
                              value.trim().toLowerCase());
                      return duplicate
                          ? 'A bin with this name already exists here'
                          : null;
                    },
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  DropdownButtonFormField<int>(
                    value: parentId,
                    decoration: const InputDecoration(labelText: 'Parent bin'),
                    hint: const BodyText('Top level'),
                    items: editableBins()
                        .map((bin) => DropdownMenuItem<int>(
                              value: bin.id,
                              child: BodyText(binDisplayPath(bin)),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => parentId = value),
                  ),
                  TextFormField(
                    onChanged: (value) => binDescription = value,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final picture = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 35,
                          );
                          if (picture != null) {
                            setDialogState(() => binImage = File(picture.path));
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: BodyText(
                            binImage == null ? 'Bin picture' : 'Picture added'),
                      ),
                      FloatingActionButton.small(
                        heroTag: 'new-bin-color',
                        backgroundColor: color,
                        onPressed: () async {
                          final picked = await _pickColor(color);
                          if (picked != null)
                            setDialogState(() => color = picked);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const ButtonText('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!binFormKey.currentState!.validate()) return;
                final bin = Location(
                  parentId: parentId,
                  name: binName.trim(),
                  description: binDescription.trim(),
                  color: colorToString(color),
                  location: latLngToString(userLocation),
                );
                final response = await bin.post(imageFile: binImage);
                if (response?.status == SQLResponseStatusTypes.success &&
                    dialogContext.mounted) {
                  Navigator.pop(dialogContext, response);
                } else if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                    content: BodyText(
                        response?.errorMessage ?? 'Could not create bin'),
                  ));
                }
              },
              child: const ButtonText('Add'),
            ),
          ],
        ),
      ),
    );

    if (created?.status == SQLResponseStatusTypes.success && mounted) {
      setState(() => selectedBinId = created!.binId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bins = editableBins();
    if (selectedBinId != null && !bins.any((bin) => bin.id == selectedBinId)) {
      selectedBinId = bins.isEmpty ? null : bins.first.id;
    }
    final canCreateBin = User.user.isAdmin || bins.isNotEmpty;

    return SizedBox(
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(screenWidth(context) / 50),
                child: const Header('Add Item'),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextFormField(
                  controller: nameController,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? InputErrors.empty
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight(context) / 100,
                      horizontal: screenWidth(context) / 100,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: secondaryColor(context),
                      border: Border.all(color: inverseColor(context)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextFormField(
                  controller: descriptionController,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? InputErrors.empty
                      : null,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth(context) / 100,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ItemTagsField(
                  onChanged: (tags) => selectedTags = tags,
                ),
              ),
              const Divider(),
              Row(
                children: [
                  const Expanded(child: SubHeader('Bin')),
                  if (canCreateBin)
                    IconButton(
                      onPressed: _createBin,
                      icon: const Icon(Icons.add),
                    ),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: selectedBinId,
                      isExpanded: true,
                      validator: (value) =>
                          value == null ? 'An item must have a bin' : null,
                      items: bins
                          .map((bin) => DropdownMenuItem<int>(
                                value: bin.id,
                                child: BodyText(binDisplayPath(bin)),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedBinId = value),
                    ),
                  ),
                ],
              ),
              if (bins.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: BodyText(
                      'Create a bin first, or ask an admin for edit access.'),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SubHeader('Multiple Items'),
                  Switch(
                    activeTrackColor: Colors.blueAccent,
                    activeColor: Colors.white,
                    value: multipleBool,
                    onChanged: (value) => setState(() => multipleBool = value),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(child: SubHeader('Number of Items')),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      readOnly: !multipleBool,
                      keyboardType: TextInputType.number,
                      controller: quantityController,
                    ),
                  ),
                ],
              ).animate(target: multipleBool ? 0 : 1).fadeOut(),
              const Divider(),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const ButtonText('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => processing = true);
                      final bin = getLocationFromId(selectedBinId);
                      final item = Item(
                        name: safeString(nameController.text),
                        storeDate: timeNow.toLocal(),
                        binId: selectedBinId,
                        location: bin?.name,
                        multiple: multipleBool,
                        quantity: int.tryParse(quantityController.text) ?? 1,
                        description: safeString(descriptionController.text),
                        tags: selectedTags,
                      );
                      final response = await item.post();
                      if (!mounted) return;
                      setState(() => processing = false);
                      if (response?.status == SQLResponseStatusTypes.success) {
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: BodyText(
                              response?.errorMessage ?? 'Could not add item'),
                        ));
                      }
                    },
                    child: const ButtonText('Add Item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
