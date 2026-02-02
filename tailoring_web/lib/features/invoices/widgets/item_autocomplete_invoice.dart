import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/items/models/item.dart';
import 'package:tailoring_web/features/items/providers/item_provider.dart';

/// Item Autocomplete Widget for Invoices
/// Searchable dropdown for selecting items with debouncing
class ItemAutocompleteInvoice extends StatefulWidget {
  final Item? initialItem;
  final Function(Item?) onItemSelected;
  final String? hintText;

  const ItemAutocompleteInvoice({
    super.key,
    this.initialItem,
    required this.onItemSelected,
    this.hintText,
  });

  @override
  State<ItemAutocompleteInvoice> createState() =>
      _ItemAutocompleteInvoiceState();
}

class _ItemAutocompleteInvoiceState extends State<ItemAutocompleteInvoice> {
  final TextEditingController _controller = TextEditingController();
  Item? _selectedItem;
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
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

        // Cancel previous search
        _debounceTimer?.cancel();

        // Use completer for async debouncing
        final completer = Completer<Iterable<Item>>();

        // Wait 300ms before searching
        _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
          if (!mounted) {
            if (!completer.isCompleted) {
              completer.complete(const Iterable<Item>.empty());
            }
            return;
          }

          try {
            final provider = context.read<ItemProvider>();
            final items = await provider.searchItems(textEditingValue.text);

            if (!mounted || completer.isCompleted) return;
            completer.complete(items);
          } catch (e) {
            if (!mounted || completer.isCompleted) return;
            completer.complete(const Iterable<Item>.empty());
          }
        });

        return completer.future;
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
