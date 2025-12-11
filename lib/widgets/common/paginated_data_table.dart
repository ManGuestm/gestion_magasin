import 'package:flutter/material.dart';

class PaginatedDataTable<T> extends StatefulWidget {
  final List<T> data;
  final List<DataColumn> columns;
  final List<DataCell> Function(T item) cellBuilder;
  final int rowsPerPage;
  final String? searchHint;
  final String Function(T item)? searchFilter;
  final VoidCallback? onRefresh;
  final Widget? emptyWidget;
  final bool showSearch;
  final bool showRefresh;

  const PaginatedDataTable({
    super.key,
    required this.data,
    required this.columns,
    required this.cellBuilder,
    this.rowsPerPage = 10,
    this.searchHint,
    this.searchFilter,
    this.onRefresh,
    this.emptyWidget,
    this.showSearch = true,
    this.showRefresh = true,
  });

  @override
  State<PaginatedDataTable<T>> createState() => _PaginatedDataTableState<T>();
}

class _PaginatedDataTableState<T> extends State<PaginatedDataTable<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredData = [];
  int _currentPage = 0;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.rowsPerPage;
    _filteredData = widget.data;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(PaginatedDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _applyFilter();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredData = widget.data;
      } else if (widget.searchFilter != null) {
        _filteredData = widget.data
            .where((item) => widget.searchFilter!(item).toLowerCase().contains(query))
            .toList();
      } else {
        _filteredData = widget.data;
      }
      _currentPage = 0;
    });
  }

  int get _totalPages => (_filteredData.length / _rowsPerPage).ceil();
  int get _startIndex => _currentPage * _rowsPerPage;
  int get _endIndex => (_startIndex + _rowsPerPage).clamp(0, _filteredData.length);

  List<T> get _currentPageData => _filteredData.sublist(_startIndex, _endIndex);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showSearch || widget.showRefresh) _buildToolbar(),
        Expanded(child: _buildTable()),
        if (_totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          if (widget.showSearch) ...[
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? 'Rechercher...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (widget.showRefresh && widget.onRefresh != null)
            IconButton(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualiser',
            ),
          Text('${_filteredData.length} élément(s)'),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_filteredData.isEmpty) {
      return widget.emptyWidget ?? 
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aucune donnée disponible', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
    }

    return SingleChildScrollView(
      child: DataTable(
        columns: widget.columns,
        rows: _currentPageData.map((item) {
          return DataRow(cells: widget.cellBuilder(item));
        }).toList(),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('Lignes par page: '),
              DropdownButton<int>(
                value: _rowsPerPage,
                items: [5, 10, 25, 50, 100].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _rowsPerPage = value;
                      _currentPage = 0;
                    });
                  }
                },
              ),
            ],
          ),
          Row(
            children: [
              Text('${_startIndex + 1}-$_endIndex sur ${_filteredData.length}'),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}