import 'dart:io';

import 'package:dad_app/models/item_model.dart';
import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/item_status.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/item_tags_field.dart';
import 'package:dad_app/widgets/optional_image_picker.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UpdateItemColumn extends StatefulWidget {
  final int id;
  final String? name;
  final String? location;
  final bool? multiple;
  final int? quantity;
  final String? description;
  final String? oldImage;
  final List<String> tags;
  final ItemStatus status;

  const UpdateItemColumn({
    super.key,
    required this.id,
    this.name,
    this.location,
    this.multiple,
    this.quantity,
    this.description,
    this.oldImage,
    this.tags = const [],
    this.status = ItemStatus.inLocation,
  });

  @override
  State<UpdateItemColumn> createState() => _UpdateItemColumnState();
}

class _UpdateItemColumnState extends State<UpdateItemColumn> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final quantityController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool multipleBool = false;
  int? selectedBinId;
  late List<String> selectedTags;
  late ItemStatus selectedStatus;
  File? selectedImage;
  bool removeImage = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.name ?? '';
    descriptionController.text = widget.description ?? '';
    quantityController.text = (widget.quantity ?? 1).toString();
    multipleBool = widget.multiple ?? false;
    selectedTags = List.of(widget.tags);
    selectedStatus = widget.status;
    for (final item in itemsJsonList) {
      if (item.id == widget.id) {
        selectedBinId = item.binId;
        if (selectedTags.isEmpty) selectedTags = List.of(item.tags);
        selectedStatus = item.status;
        break;
      }
    }
    selectedBinId ??= getLocationIdFromName(widget.location ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bins = editableBins();
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(screenWidth(context) / 50),
              child: const Header('Update Item'),
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
              child: OptionalImagePicker(
                existingImage: widget.oldImage,
                label: 'Item picture (optional)',
                onChanged: (selection) {
                  selectedImage = selection.file;
                  removeImage = selection.removeExisting;
                },
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
                    vertical: screenHeight(context) / 80,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: ItemTagsField(
                initialTags: selectedTags,
                onChanged: (tags) => selectedTags = tags,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: DropdownButtonFormField<ItemStatus>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ItemStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ))
                    .toList(),
                onChanged: (value) => setState(
                  () => selectedStatus = value ?? ItemStatus.inLocation,
                ),
              ),
            ),
            const Divider(),
            Row(
              children: [
                const Expanded(child: SubHeader('Bin')),
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
                              child: Text(
                                binDisplayPath(bin),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedBinId = value),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SubHeader('Multiple Items'),
                Switch(
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
                    final selectedBin = getLocationFromId(selectedBinId);
                    final item = Item(
                      id: widget.id,
                      name: safeString(nameController.text),
                      storeDate: timeNow.toLocal(),
                      binId: selectedBinId,
                      location: selectedBin?.name,
                      multiple: multipleBool,
                      quantity: int.tryParse(quantityController.text) ?? 1,
                      description: safeString(descriptionController.text),
                      tags: selectedTags,
                      status: selectedStatus,
                    );
                    final response = await item.put(
                      imageFile: selectedImage,
                      removeImage: removeImage,
                    );
                    if (!mounted) return;
                    setState(() => processing = false);
                    if (response?.status == SQLResponseStatusTypes.success) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: BodyText(
                          response?.errorMessage ?? 'Could not update item',
                        ),
                      ));
                    }
                  },
                  child: const ButtonText('Update Item'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
