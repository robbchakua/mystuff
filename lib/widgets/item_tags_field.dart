import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/item_tags.dart';
import 'package:flutter/material.dart';

class ItemTagsField extends StatefulWidget {
  final List<String> initialTags;
  final ValueChanged<List<String>> onChanged;

  const ItemTagsField({
    super.key,
    this.initialTags = const [],
    required this.onChanged,
  });

  @override
  State<ItemTagsField> createState() => _ItemTagsFieldState();
}

class _ItemTagsFieldState extends State<ItemTagsField> {
  final _controller = TextEditingController();
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = normalizeItemTags(widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag([String? value]) {
    final candidate = (value ?? _controller.text).trim();
    if (candidate.isEmpty) return;
    final updated = normalizeItemTags([..._tags, candidate]);
    if (updated.length == _tags.length) {
      final isDuplicate = _tags.any(
        (tag) => tag.toLowerCase() == candidate.toLowerCase(),
      );
      final message = isDuplicate
          ? 'That tag is already selected'
          : candidate.length > maxItemTagLength
              ? 'Tags can be up to $maxItemTagLength characters'
              : 'You can add up to $maxItemTags tags';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    setState(() {
      _tags = updated;
      _controller.clear();
    });
    widget.onChanged(List.unmodifiable(_tags));
  }

  void _removeTag(String value) {
    setState(() => _tags.remove(value));
    widget.onChanged(List.unmodifiable(_tags));
  }

  @override
  Widget build(BuildContext context) {
    final remainingSuggestions = suggestedItemTags.where(
      (suggestion) => !_tags.any(
        (tag) => tag.toLowerCase() == suggestion.toLowerCase(),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            color: inverseColor(context),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _tags
                .map(
                  (tag) => InputChip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          enabled: _tags.length < maxItemTags,
          textInputAction: TextInputAction.done,
          maxLength: maxItemTagLength,
          onFieldSubmitted: _addTag,
          decoration: InputDecoration(
            labelText: 'Add a tag',
            hintText: 'For example: Tool',
            helperText: '${_tags.length}/$maxItemTags tags',
            suffixIcon: IconButton(
              tooltip: 'Add tag',
              onPressed: _tags.length < maxItemTags ? _addTag : null,
              icon: const Icon(Icons.add),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: remainingSuggestions
              .map(
                (tag) => ActionChip(
                  label: Text(tag),
                  avatar: const Icon(Icons.add, size: 16),
                  onPressed:
                      _tags.length < maxItemTags ? () => _addTag(tag) : null,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
