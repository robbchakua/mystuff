import 'package:cached_network_image/cached_network_image.dart';
import 'package:dad_app/models/item_history_model.dart';
import 'package:dad_app/models/item_model.dart';
import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/pages/location_page.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/utils/item_status.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:dad_app/widgets/update_item_popup_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class ViewItemColumn extends StatefulWidget {
  final int id;
  final int locationId;
  final String? name;
  final String? location;
  final bool? multiple;
  final int? quantity;
  final String? description;
  final List<String> tags;

  const ViewItemColumn({
    super.key,
    required this.id,
    required this.locationId,
    this.name,
    this.location,
    this.multiple,
    this.quantity,
    this.description,
    this.tags = const [],
  });

  @override
  State<ViewItemColumn> createState() => _ViewItemColumnState();
}

class _ViewItemColumnState extends State<ViewItemColumn> {
  bool _deletedItem = false;

  Item? get _currentItem {
    final index = getItemIndexFromId(widget.id);
    return index >= 0 ? itemsJsonList[index] : null;
  }

  Future<void> _showUpdateDialog() async {
    final item = _currentItem;
    await showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        content: UpdateItemColumn(
          id: widget.id,
          name: item?.name ?? widget.name,
          location: item?.location ?? widget.location,
          description: item?.description ?? widget.description,
          multiple: item?.multiple ?? widget.multiple,
          quantity: item?.quantity ?? widget.quantity,
          oldImage: item?.image,
          tags: item?.tags ?? widget.tags,
          status: item?.status ?? ItemStatus.inLocation,
        ),
        backgroundColor: primaryColor(context),
      ),
    );
  }

  Future<void> _updateItem() async {
    await _showUpdateDialog();
    if (mounted) setState(() {});
  }

  Future<void> _showHistory() async {
    final history = await Item(id: widget.id).getHistory();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Header('Item History'),
        content: SizedBox(
          width: 520,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.65,
            ),
            child: history == null
                ? const BodyText('Could not load this item’s history.')
                : history.isEmpty
                    ? const BodyText('No history has been recorded yet.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) =>
                            _historyTile(history[index]),
                      ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const ButtonText('Close'),
          ),
        ],
      ),
    );
  }

  Widget _historyTile(ItemHistoryEntry entry) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.history),
        title: Text(entry.summary),
        subtitle: Text(
          '${entry.actorName}'
          '${entry.createdAt == null ? '' : ' • ${DateFormat.yMMMd().add_jm().format(entry.createdAt!.toLocal())}'}',
        ),
      );

  Future<void> _deleteItem(String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $title?'),
        content: const BodyText('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const ButtonText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const ButtonText('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final response = await Item(id: widget.id).drop();
    if (!mounted) return;
    if (response?.status == SQLResponseStatusTypes.success) {
      _deletedItem = true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BodyText(response?.errorMessage ?? 'Could not delete item'),
        ),
      );
    }
  }

  Future<void> _showOnMap() async {
    final bin = getLocationFromId(_currentItem?.binId ?? widget.locationId);
    if (bin == null || !(bin.location?.contains(',') ?? false)) return;
    if (networkError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: BodyText('Network Error...')),
      );
      return;
    }

    listItems = false;
    listLocations = false;
    targetPosition = stringToLatLng(bin.location!);
    if (googleMapsController.isCompleted) {
      final controller = await googleMapsController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: targetPosition,
            zoom: cameraZoom >= 17 ? cameraZoom : 17,
          ),
        ),
      );
    }
    Get.to(() => const ItemLocationScreen(withTarget: true));
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentItem;
    if (item == null) {
      return const SizedBox(
        width: 320,
        child: BodyText('This item is no longer available.'),
      );
    }
    final bin = getLocationFromId(item.binId ?? widget.locationId);
    final tags = item.tags.isEmpty ? widget.tags : item.tags;
    final storedAt = item.storeDate;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Header(item.name ?? widget.name ?? 'Item'),
              ),
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: secondaryColor(context),
                    border: Border.all(color: inverseColor(context)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.image == null || item.image!.isEmpty
                      ? const Icon(Icons.image_not_supported_outlined, size: 54)
                      : CachedNetworkImage(
                          fit: BoxFit.cover,
                          imageUrl: '${Urls.baseUrl}/${item.image}',
                          progressIndicatorBuilder: (_, __, progress) => Center(
                            child: CircularProgressIndicator(
                              value: progress.progress,
                            ),
                          ),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.image_not_supported),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SubHeader(
                      'Bin: ${bin?.name ?? item.location ?? ''}',
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Show bin on map',
                    onPressed: bin?.location?.contains(',') == true
                        ? _showOnMap
                        : null,
                    icon: const Icon(Icons.location_on),
                  ),
                ],
              ),
              if ((item.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                BodyText(item.description!),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(item.status.icon, color: item.status.color),
                  label: Text(item.status.label),
                  side: BorderSide(color: item.status.color),
                ),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: tags.map((tag) => Chip(label: Text(tag))).toList(),
                ),
              ],
              Divider(color: inverseColor(context), height: 28),
              if (storedAt != null)
                BodyText('Saved on ${DateFormat.yMMMMd().format(storedAt)}'),
              const SizedBox(height: 8),
              BodyText('Number of item(s): ${item.quantity ?? 1}'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showHistory,
                icon: const Icon(Icons.history),
                label: const ButtonText('View history'),
              ),
              if (item.canEdit) ...[
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _updateItem,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xAA1B1B1B),
                      ),
                      child: const ButtonText('Update Item'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _deleteItem(item.name ?? 'item');
                        if (_deletedItem && mounted) Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xAAFF0000),
                      ),
                      child: const ButtonText('Delete Item'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
