import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../items/models/item.dart';
import '../../items/providers/item_provider.dart';

/// Item Autocomplete Widget
/// Searchable dropdown for selecting items
class ItemAutocomplete extends StatefulWidget {
  final Item? initialItem;
  final Function(Item?) onItemSelected;
  final String? hintText;

  const ItemAutocomplete({
    super.key,
    this.initialItem,
    required this.onItemSelected,
    this.hintText,
  });

  @override
  State<ItemAutocomplete> createState() => _ItemAutocompleteState();
}

class _ItemAutocompleteState extends State<ItemAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  Item? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialItem;
    if (_selectedItem != null) {
      _controller.text = _selectedItem!.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Item>(
      displayStringForOption: (Item item) => item.name,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Item>.empty();
        }

        final provider = context.read<ItemProvider>();
        final items = await provider.searchItems(textEditingValue.text);

        return items;
      },
      onSelected: (Item item) {
        setState(() {
          _selectedItem = item;
          _controller.text = item.name;
        });
        widget.onItemSelected(item);
      },
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // Sync controllers
            if (_controller.text.isNotEmpty &&
                textEditingController.text.isEmpty) {
              textEditingController.text = _controller.text;
            }

            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search items...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: textEditingController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          textEditingController.clear();
                          _controller.clear();
                          setState(() {
                            _selectedItem = null;
                          });
                          widget.onItemSelected(null);
                        },
                      )
                    : null,
              ),
            );
          },
      optionsViewBuilder:
          (
            BuildContext context,
            AutocompleteOnSelected<Item> onSelected,
            Iterable<Item> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  width: 400,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: options.length,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      final Item item = options.elementAt(index);
                      return InkWell(
                        onTap: () {
                          onSelected(item);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontWeight: AppTheme.fontSemibold,
                                      ),
                                    ),
                                  ),
                                  // Item type badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.itemType == 'SERVICE'
                                          ? AppTheme.info.withOpacity(0.1)
                                          : AppTheme.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      item.itemType == 'SERVICE'
                                          ? 'Service'
                                          : 'Product',
                                      style: AppTheme.bodyXSmall.copyWith(
                                        color: item.itemType == 'SERVICE'
                                            ? AppTheme.info
                                            : AppTheme.success,
                                        fontWeight: AppTheme.fontSemibold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (item.sellingPrice != null) ...[
                                    Text(
                                      '₹${item.sellingPrice!.toStringAsFixed(2)}',
                                      style: AppTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (item.trackStock) ...[
                                    Icon(
                                      Icons.inventory_2,
                                      size: 12,
                                      color: item.isLowStock
                                          ? AppTheme.danger
                                          : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Stock: ${item.currentStock.toStringAsFixed(0)}',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: item.isLowStock
                                            ? AppTheme.danger
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (item.description != null &&
                                  item.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.description!,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
    );
  }
}
