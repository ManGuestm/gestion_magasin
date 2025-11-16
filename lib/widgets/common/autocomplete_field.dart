import 'package:flutter/material.dart';

class AutocompleteField<T extends Object> extends StatelessWidget {
  final List<T> options;
  final String Function(T) displayStringForOption;
  final void Function(T) onSelected;
  final String Function(String) filterFunction;
  final TextEditingController? controller;
  final double height;

  const AutocompleteField({
    super.key,
    required this.options,
    required this.displayStringForOption,
    required this.onSelected,
    required this.filterFunction,
    this.controller,
    this.height = 25,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: Autocomplete<T>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return <T>[];
                }
                return options.where((item) {
                  return displayStringForOption(item)
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              displayStringForOption: displayStringForOption,
              onSelected: onSelected,
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          SizedBox(
            width: 25,
            height: height,
            child: PopupMenuButton<T>(
              icon: const Icon(Icons.arrow_drop_down, size: 16),
              itemBuilder: (context) {
                return options.map((item) {
                  return PopupMenuItem<T>(
                    value: item,
                    child: Text(displayStringForOption(item), style: const TextStyle(fontSize: 12)),
                  );
                }).toList();
              },
              onSelected: onSelected,
            ),
          ),
        ],
      ),
    );
  }
}
