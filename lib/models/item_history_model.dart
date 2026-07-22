import 'package:dad_app/utils/item_status.dart';

class ItemHistoryEntry {
  final int? id;
  final int? itemId;
  final String actorName;
  final String action;
  final String? fromBinName;
  final String? toBinName;
  final ItemStatus? fromStatus;
  final ItemStatus? toStatus;
  final DateTime? createdAt;

  const ItemHistoryEntry({
    this.id,
    this.itemId,
    required this.actorName,
    required this.action,
    this.fromBinName,
    this.toBinName,
    this.fromStatus,
    this.toStatus,
    this.createdAt,
  });

  factory ItemHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ItemHistoryEntry(
        id: int.tryParse(json['id']?.toString() ?? ''),
        itemId: int.tryParse(json['item_id']?.toString() ?? ''),
        actorName: json['changed_by_name']?.toString() ?? 'Unknown user',
        action: json['action']?.toString() ?? 'updated',
        fromBinName: json['from_bin_name']?.toString(),
        toBinName: json['to_bin_name']?.toString(),
        fromStatus: json['from_status'] == null
            ? null
            : parseItemStatus(json['from_status']),
        toStatus: json['to_status'] == null
            ? null
            : parseItemStatus(json['to_status']),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );

  String get summary {
    switch (action) {
      case 'created':
        return 'Added to ${toBinName ?? 'a bin'}';
      case 'imported':
        return 'Existing item recorded in ${toBinName ?? 'a bin'}';
      case 'moved':
      case 'moved_due_to_bin_delete':
        return 'Moved from ${fromBinName ?? 'a previous bin'} to '
            '${toBinName ?? 'another bin'}';
      case 'status_changed':
        return 'Status changed from ${fromStatus?.label ?? 'unknown'} to '
            '${toStatus?.label ?? 'unknown'}';
      case 'moved_and_status_changed':
        return 'Moved to ${toBinName ?? 'another bin'} and marked '
            '${toStatus?.label ?? 'with a new status'}';
      default:
        return 'Updated item details';
    }
  }
}
