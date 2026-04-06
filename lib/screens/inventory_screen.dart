import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirestoreService _service = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String _selectedCategory = 'General';
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAsc = true;

  final List<String> _categories = [
    'General',
    'Electronics',
    'Food',
    'Clothing',
    'Tools',
    'Other',
  ];

  
  void _showItemForm([Item? existing]) {
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _priceCtrl.text = existing.price.toString();
      _qtyCtrl.text = existing.quantity.toString();
      _selectedCategory = existing.category;
    } else {
      _nameCtrl.clear();
      _priceCtrl.clear();
      _qtyCtrl.clear();
      _selectedCategory = 'General';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Add Item' : 'Update Item',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 10),

              // Price
              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  final n = double.tryParse(v);
                  if (n == null || n < 0) return 'Enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Quantity
              TextFormField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Quantity is required';
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return 'Enter a valid whole number';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7377),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final item = Item(
                      id: existing?.id,
                      name: _nameCtrl.text.trim(),
                      price: double.parse(_priceCtrl.text.trim()),
                      quantity: int.parse(_qtyCtrl.text.trim()),
                      category: _selectedCategory,
                    );

                    if (existing == null) {
                      await _service.addItem(item);
                      _showSnack('Item added successfully', Colors.green);
                    } else {
                      await _service.updateItem(item);
                      _showSnack('Item updated successfully', Colors.blue);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    existing == null ? 'Add Item' : 'Update Item',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  void _confirmDelete(Item item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _service.deleteItem(item.id!);
              Navigator.pop(context);
              _showSnack('Item deleted', Colors.red);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  
  List<Item> _applyFiltersAndSort(List<Item> items) {
    var filtered = items;

    // search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q))
          .toList();
    }

    // sort
    filtered.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'price':
          cmp = a.price.compareTo(b.price);
          break;
        case 'quantity':
          cmp = a.quantity.compareTo(b.quantity);
          break;
        case 'category':
          cmp = a.category.compareTo(b.category);
          break;
        default:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _sortAsc ? cmp : -cmp;
    });

    return filtered;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Manager'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D7377),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (v) {
              setState(() {
                if (_sortBy == v) {
                  _sortAsc = !_sortAsc;
                } else {
                  _sortBy = v;
                  _sortAsc = true;
                }
              });
            },
            itemBuilder: (_) => [
              _sortMenuItem('name', 'Name'),
              _sortMenuItem('price', 'Price'),
              _sortMenuItem('quantity', 'Quantity'),
              _sortMenuItem('category', 'Category'),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or category...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // item list
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _service.streamItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final items =
                    _applyFiltersAndSort(snapshot.data ?? []);

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No items found',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D7377).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.inventory,
                              color: Color(0xFF0D7377)),
                        ),
                        title: Text(item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${item.price.toStringAsFixed(2)}  •  Qty: ${item.quantity}',
                              style: const TextStyle(
                                  color: Color(0xFF0D7377),
                                  fontWeight: FontWeight.bold),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(item.category,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.teal.shade700)),
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 96,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueGrey),
                                onPressed: () => _showItemForm(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _confirmDelete(item),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D7377),
        foregroundColor: Colors.white,
        onPressed: () => _showItemForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  PopupMenuItem<String> _sortMenuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Text(label),
          if (_sortBy == value) ...[
            const SizedBox(width: 6),
            Icon(
              _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: const Color(0xFF0D7377),
            ),
          ],
        ],
      ),
    );
  }
}
