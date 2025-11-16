import 'package:flutter/material.dart';

class DataTableWidget<T> extends StatelessWidget {
  final List<String> headers;
  final List<T> items;
  final List<Widget> Function(T item, bool isSelected) rowBuilder;
  final T? selectedItem;
  final Function(T) onItemSelected;
  final double itemHeight;

  const DataTableWidget({
    super.key,
    required this.headers,
    required this.items,
    required this.rowBuilder,
    required this.onItemSelected,
    this.selectedItem,
    this.itemHeight = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemExtent: itemHeight,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedItem == item;
                return GestureDetector(
                  onTap: () => onItemSelected(item),
                  child: Container(
                    height: itemHeight,
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? Colors.blue[600] 
                        : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
                    ),
                    child: Row(children: rowBuilder(item, isSelected)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 25,
      decoration: BoxDecoration(color: Colors.orange[300]),
      child: Row(
        children: headers.map((header) => Expanded(
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey[400]!, width: 1),
                bottom: BorderSide(color: Colors.grey[400]!, width: 1),
              ),
            ),
            child: Text(
              header,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        )).toList(),
      ),
    );
  }
}