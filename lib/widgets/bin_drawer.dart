import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dad_app/models/item_model.dart';
import 'package:dad_app/models/location_model.dart';
import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/item_status.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/optional_image_picker.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<bool> showCreateBinDialog(
  BuildContext context, {
  required LatLng position,
  int? initialParentId,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _CreateBinDialog(
        position: position,
        initialParentId: initialParentId,
      ),
    ) ??
    false;

class _CreateBinDialog extends StatefulWidget {
  final LatLng position;
  final int? initialParentId;

  const _CreateBinDialog({
    required this.position,
    this.initialParentId,
  });

  @override
  State<_CreateBinDialog> createState() => _CreateBinDialogState();
}

class _CreateBinDialogState extends State<_CreateBinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  late int? _parentId = widget.initialParentId;
  Color _color = Colors.red;
  File? _image;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    var selected = _color;
    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Header('Pick a bin color'),
        content: ColorPicker(
          enableAlpha: false,
          pickerColor: selected,
          onColorChanged: (color) => selected = color,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, selected),
            child: const ButtonText('Choose color'),
          ),
        ],
      ),
    );
    if (result != null && mounted) setState(() => _color = result);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final response = await Location(
      parentId: _parentId,
      name: _name.text.trim(),
      description: _description.text.trim(),
      color: colorToString(_color),
      location: latLngToString(widget.position),
    ).post(imageFile: _image);
    if (!mounted) return;
    if (response?.status == SQLResponseStatusTypes.success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: BodyText(response?.errorMessage ?? 'Could not create bin'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Header('New Bin'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? InputErrors.empty
                      : null,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _parentId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Parent bin'),
                  hint: const BodyText('Top level'),
                  validator: (value) => !User.user.isAdmin && value == null
                      ? 'Observers must choose an editable parent bin'
                      : null,
                  items: editableBins()
                      .map((bin) => DropdownMenuItem<int>(
                            value: bin.id,
                            child: BodyText(binDisplayPath(bin)),
                          ))
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _parentId = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                OptionalImagePicker(
                  label: 'Bin picture (optional)',
                  onChanged: (selection) =>
                      _image = selection.removeExisting ? null : selection.file,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FloatingActionButton.small(
                    heroTag: 'create-bin-color',
                    backgroundColor: _color,
                    onPressed: _saving ? null : _pickColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const ButtonText('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const ButtonText('Add'),
          ),
        ],
      );
}

class BinDrawer extends StatefulWidget {
  final VoidCallback? onBinsChanged;

  const BinDrawer({super.key, this.onBinsChanged});

  @override
  State<BinDrawer> createState() => _BinDrawerState();
}

class _BinDrawerState extends State<BinDrawer> {
  List<Location> visibleBins = [];
  List<Item> visibleItems = [];

  @override
  void initState() {
    super.initState();
    _resetLists();
  }

  void _resetLists() {
    visibleBins = [...locationsJsonList]
      ..sort((a, b) => binDisplayPath(a).compareTo(binDisplayPath(b)));
    visibleItems = [...itemsJsonList];
  }

  void _search(String keyword) {
    final normalized = keyword.trim().toLowerCase();
    setState(() {
      if (normalized.isEmpty) {
        _resetLists();
      } else if (listLocations) {
        visibleBins = locationsJsonList
            .where(
                (bin) => binDisplayPath(bin).toLowerCase().contains(normalized))
            .toList()
          ..sort((a, b) => binDisplayPath(a).compareTo(binDisplayPath(b)));
      } else {
        visibleItems = itemsJsonList
            .where((item) =>
                (item.name ?? '').toLowerCase().contains(normalized) ||
                (item.location ?? '').toLowerCase().contains(normalized) ||
                item.tags
                    .any((tag) => tag.toLowerCase().contains(normalized)))
            .toList();
      }
    });
  }

  Future<Color?> _pickColor(Color initial) async {
    var selected = initial;
    return showDialog<Color>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Header('Pick a bin color'),
        content: ColorPicker(
          enableAlpha: false,
          pickerColor: selected,
          onColorChanged: (color) => selected = color,
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

  Future<void> _createBin({int? initialParentId}) async {
    final created = await showCreateBinDialog(
      context,
      position: targetPosition,
      initialParentId: initialParentId,
    );
    if (!mounted) return;
    setState(_resetLists);
    if (created) widget.onBinsChanged?.call();
  }

  Set<int> _descendantIds(int rootId) {
    final result = <int>{rootId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final bin in locationsJsonList) {
        if (bin.id != null &&
            bin.parentId != null &&
            result.contains(bin.parentId) &&
            result.add(bin.id!)) {
          changed = true;
        }
      }
    }
    return result;
  }

  Future<void> _editBin(Location bin) async {
    final formKey = GlobalKey<FormState>();
    var name = bin.name ?? '';
    var description = bin.description ?? '';
    int? parentId = bin.parentId;
    Color color = stringToColor(bin.color ?? 'F44336');
    File? image;
    bool removeImage = false;
    final excluded = _descendantIds(bin.id!);
    final parentChoices = editableBins()
        .where((candidate) => !excluded.contains(candidate.id))
        .toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Header(bin.name ?? 'Bin'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    onChanged: (value) => name = value,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? InputErrors.empty
                        : null,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  DropdownButtonFormField<int>(
                    value: parentChoices.any((choice) => choice.id == parentId)
                        ? parentId
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Parent bin'),
                    hint: const BodyText('Top level'),
                    items: parentChoices
                        .map((candidate) => DropdownMenuItem<int>(
                              value: candidate.id,
                              child: BodyText(binDisplayPath(candidate)),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => parentId = value),
                  ),
                  TextFormField(
                    initialValue: description,
                    onChanged: (value) => description = value,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  OptionalImagePicker(
                    existingImage: bin.image,
                    label: 'Bin picture (optional)',
                    onChanged: (selection) {
                      image = selection.file;
                      removeImage = selection.removeExisting;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton.small(
                      heroTag: 'edit-bin-color-${bin.id}',
                      backgroundColor: color,
                      onPressed: () async {
                        final result = await _pickColor(color);
                        if (result != null) {
                          setDialogState(() => color = result);
                        }
                      },
                    ),
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
                if (!formKey.currentState!.validate()) return;
                final response = await Location(
                  id: bin.id,
                  parentId: parentId,
                  name: name.trim(),
                  description: description.trim(),
                  location: bin.location,
                  color: colorToString(color),
                ).put(null, image, removeImage);
                if (response?.status == SQLResponseStatusTypes.success &&
                    dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                } else if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                    content: BodyText(
                        response?.errorMessage ?? 'Could not update bin'),
                  ));
                }
              },
              child: const ButtonText('Save'),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(_resetLists);
  }

  Future<void> _deleteBin(Location bin) async {
    bool deleteContents = true;
    int? replacementId;
    final excluded = _descendantIds(bin.id!);
    final replacements = editableBins()
        .where((candidate) => !excluded.contains(candidate.id))
        .toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Header('Delete ${bin.name}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<bool>(
                value: deleteContents,
                decoration: const InputDecoration(labelText: 'Contents'),
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: BodyText('Delete bin, sub-bins, and items'),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: BodyText('Move contents to another bin'),
                  ),
                ],
                onChanged: (value) => setDialogState(
                    () => deleteContents = value ?? deleteContents),
              ),
              if (!deleteContents)
                DropdownButtonFormField<int>(
                  value: replacementId,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Replacement bin'),
                  items: replacements
                      .map((candidate) => DropdownMenuItem<int>(
                            value: candidate.id,
                            child: BodyText(binDisplayPath(candidate)),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => replacementId = value),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const ButtonText('Cancel'),
            ),
            ElevatedButton(
              onPressed: !deleteContents && replacementId == null
                  ? null
                  : () async {
                      final response = await bin.drop(
                        allItems: deleteContents,
                        replacementBinId: replacementId,
                      );
                      if (response?.status == SQLResponseStatusTypes.success &&
                          dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      } else if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(SnackBar(
                          content: BodyText(
                              response?.errorMessage ?? 'Could not delete bin'),
                        ));
                      }
                    },
              child: const ButtonText('Delete'),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(_resetLists);
  }

  Future<void> _manageAccess(Location bin) async {
    final response = await bin.getAccess();
    if (response?.status != SQLResponseStatusTypes.success || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: BodyText(response?.errorMessage ?? 'Could not load access'),
      ));
      return;
    }
    final users =
        response!.users.where((user) => user.role == 'observer').toList();
    final access = <int, String>{};
    for (final permission in response.permissions) {
      final userId = int.tryParse(permission['user_id']?.toString() ?? '');
      if (userId != null) {
        access[userId] = permission['permission']?.toString() ?? 'view';
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Header('${bin.name} Access'),
          content: SizedBox(
            width: screenWidth(context),
            child: users.isEmpty
                ? const BodyText(
                    'Add observer accounts from the Team page first.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      const BodyText('Access is inherited by all sub-bins.'),
                      ...users.map((user) => ListTile(
                            title: BodyText(user.name ?? user.userid ?? ''),
                            trailing: DropdownButton<String>(
                              value: access[user.id] ?? 'none',
                              items: const [
                                DropdownMenuItem(
                                    value: 'none', child: BodyText('None')),
                                DropdownMenuItem(
                                    value: 'view', child: BodyText('View')),
                                DropdownMenuItem(
                                    value: 'edit', child: BodyText('Edit')),
                              ],
                              onChanged: (value) async {
                                if (user.id == null || value == null) return;
                                final update = value == 'none'
                                    ? await bin.revokeAccess(user.id!)
                                    : await bin.grantAccess(user.id!, value);
                                if (update?.status ==
                                    SQLResponseStatusTypes.success) {
                                  setDialogState(() {
                                    if (value == 'none') {
                                      access.remove(user.id);
                                    } else {
                                      access[user.id!] = value;
                                    }
                                  });
                                }
                              },
                            ),
                          )),
                    ],
                  ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const ButtonText('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _binActions(Location bin) => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Header(binDisplayPath(bin)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _createBin(initialParentId: bin.id);
              },
              child: const ButtonText('Add Sub-bin'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _editBin(bin);
              },
              child: const ButtonText('Update'),
            ),
            if (bin.canManageAccess)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _manageAccess(bin);
                },
                child: const ButtonText('Access'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteBin(bin);
              },
              child: const ButtonText('Delete'),
            ),
          ],
        ),
      );

  Future<void> _moveMapToBin(Location? bin) async {
    if (bin == null || !(bin.location?.contains(',') ?? false)) return;
    final controller = await googleMapsController.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: stringToLatLng(bin.location!),
        zoom: cameraZoom >= 14 ? cameraZoom : 14,
      ),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canCreateBin = User.user.isAdmin || editableBins().isNotEmpty;
    final count = listLocations ? visibleBins.length : visibleItems.length;
    return Drawer(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: screenHeightWithSafeArea(context) / 20,
          horizontal: screenWidth(context) / 25,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: searchController,
                    onChanged: _search,
                    decoration: InputDecoration(
                      hintText: listLocations ? 'Search bins' : 'Search items',
                      suffixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                if (listLocations && canCreateBin)
                  IconButton(
                    onPressed: _createBin,
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: count,
                itemBuilder: (context, index) => listLocations
                    ? _binTile(visibleBins[index])
                    : _itemTile(visibleItems[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _binTile(Location bin) => Card(
        shadowColor: Colors.white,
        elevation: 2,
        color: primaryColor(context),
        child: ListTile(
          contentPadding: EdgeInsets.only(
            left: 16 + (binDepth(bin) * 14),
            right: 8,
          ),
          leading: bin.image == null || bin.image!.isEmpty
              ? Icon(Icons.inventory_2, color: stringToColor(bin.color!))
              : CachedNetworkImage(
                  imageUrl: '${Urls.baseUrl}/${bin.image}',
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Icon(Icons.inventory_2, color: stringToColor(bin.color!)),
                ),
          title: Text(bin.name ?? '', overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${bin.permission == 'edit' ? 'Can edit' : 'View only'}'
            '${bin.canEdit ? ' • Hold to manage' : ''}',
          ),
          trailing: Icon(Icons.location_on, color: stringToColor(bin.color!)),
          onTap: () => _moveMapToBin(bin),
          onLongPress: bin.canEdit ? () => _binActions(bin) : null,
        ),
      );

  Widget _itemTile(Item item) => Card(
        shadowColor: Colors.white,
        elevation: 2,
        color: primaryColor(context),
        child: ListTile(
          onTap: () => _moveMapToBin(getLocationFromId(item.binId)),
          trailing: item.image == null || item.image!.isEmpty
              ? const Icon(Icons.image_not_supported_outlined)
              : CachedNetworkImage(
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  imageUrl: '${Urls.baseUrl}/${item.image}',
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.image_not_supported),
                ),
          title: Text(item.name ?? '', overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getLocationFromId(item.binId) == null
                    ? item.location ?? ''
                    : binDisplayPath(getLocationFromId(item.binId)!),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                item.status.label,
                style: TextStyle(
                  color: item.status.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (item.tags.isNotEmpty)
                Text(
                  item.tags.take(3).join(' • '),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(color: middleGrey(context), fontSize: 12),
                ),
            ],
          ),
        ),
      );
}
