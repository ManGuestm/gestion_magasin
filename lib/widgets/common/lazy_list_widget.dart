import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class LazyListWidget<T> extends StatefulWidget {
  final Future<List<T>> Function(int offset, int limit) loadItems;
  final Widget Function(T item, bool isSelected) itemBuilder;
  final T? selectedItem;
  final Function(T) onItemSelected;
  final double itemHeight;

  const LazyListWidget({
    super.key,
    required this.loadItems,
    required this.itemBuilder,
    required this.onItemSelected,
    this.selectedItem,
    this.itemHeight = AppConstants.tableRowHeight,
  });

  @override
  State<LazyListWidget<T>> createState() => _LazyListWidgetState<T>();
}

class _LazyListWidgetState<T> extends State<LazyListWidget<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newItems = await widget.loadItems(_items.length, AppConstants.defaultPageSize);
      
      setState(() {
        _items.addAll(newItems);
        _hasMore = newItems.length == AppConstants.defaultPageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemExtent: widget.itemHeight,
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final item = _items[index];
        final isSelected = widget.selectedItem == item;
        
        return GestureDetector(
          onTap: () => widget.onItemSelected(item),
          child: Container(
            height: widget.itemHeight,
            decoration: BoxDecoration(
              color: isSelected 
                ? Colors.blue[600] 
                : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
            ),
            child: widget.itemBuilder(item, isSelected),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}