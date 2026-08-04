import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Use 'product_models' as prefix to avoid conflicts with local variables
import '../models/product_model.dart' as product_models;
import '../providers/auth_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_search_dialog.dart';

/// Admin-only screen for creating a new purchase.
/// Allows adding products with carton-based quantities.
class AddPurchasePage extends StatefulWidget {
  const AddPurchasePage({super.key});

  @override
  State<AddPurchasePage> createState() => _AddPurchasePageState();
}

class _AddPurchasePageState extends State<AddPurchasePage> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _invoiceController = TextEditingController();

  List<_PurchaseItemEntry> _items = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _supplierController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  void _addProduct(product_models.ProductModel product) {
    setState(() {
      _items.add(_PurchaseItemEntry(
        product: product,
        cartonQuantity: 1,
        piecesPerCarton: 30,
        pricePerCarton: 0,
        expirationDate: null,
        manufacturingDate: null,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) {
      return sum + (item.cartonQuantity * item.pricePerCarton);
    });
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final purchaseProvider = context.read<PurchaseProvider>();

    setState(() => _isSaving = true);

    final success = await purchaseProvider.createPurchase(
      supplierId: 'supplier_${DateTime.now().millisecondsSinceEpoch}',
      supplierName: _supplierController.text.trim(),
      invoiceNumber: _invoiceController.text.trim(),
      items: _items.map((item) {
        return PurchaseItemInput(
          product: item.product,
          cartonQuantity: item.cartonQuantity,
          piecesPerCarton: item.piecesPerCarton,
          pricePerCarton: item.pricePerCarton,
          expirationDate: item.expirationDate,
          manufacturingDate: item.manufacturingDate,
        );
      }).toList(),
      adminUid: auth.userModel!.uid,
      adminName: auth.userModel!.name,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase recorded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchaseProvider.errorMessage ?? 'Failed to save purchase'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Purchase details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _supplierController,
                    decoration: InputDecoration(
                      labelText: 'Supplier Name *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.business_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter supplier name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _invoiceController,
                    decoration: InputDecoration(
                      labelText: 'Invoice Number (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.receipt_outlined),
                    ),
                  ),
                ],
              ),
            ),

            // Product list header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products (${_items.length})',
                    style: AppText.label.copyWith(fontSize: 16),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showProductSearch(context, products),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product list
            Expanded(
              child: _items.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_shopping_cart_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No products added yet',
                      style: AppText.body.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Add Product" to get started',
                      style: AppText.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _PurchaseItemCard(
                    entry: _items[index],
                    onUpdate: (updated) {
                      setState(() {
                        _items[index] = updated;
                      });
                    },
                    onRemove: () => _removeItem(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = _calculateTotal();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: AppText.body.copyWith(color: AppColors.taupe),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: AppText.display.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _savePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
              minimumSize: const Size(140, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Save Purchase'),
          ),
        ],
      ),
    );
  }

  void _showProductSearch(BuildContext context, ProductProvider products) {
    showDialog(
      context: context,
      builder: (ctx) => ProductSearchDialog(
        products: products.allProducts,
        onProductSelected: (product_models.ProductModel product) {
          Navigator.pop(ctx);
          _addProduct(product);
        },
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How to record a purchase'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Enter the supplier name',
                style: AppText.body,
              ),
              const SizedBox(height: 4),
              Text(
                '2. Add products with carton details:',
                style: AppText.body,
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  '• Carton Quantity: How many cartons\n'
                      '• Pieces per Carton: How many pieces in each carton\n'
                      '• Price per Carton: Cost per carton\n'
                      '• Expiration Date: Optional',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '3. The app will automatically calculate:\n'
                    '   • Total pieces = cartons × pieces per carton\n'
                    '   • Price per piece = price per carton ÷ pieces per carton\n'
                    '   • Total price = cartons × price per carton',
                style: AppText.body,
              ),
              const SizedBox(height: 4),
              Text(
                '4. Save - products will be added to inventory',
                style: AppText.body,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Internal class for tracking purchase item entries in the UI
class _PurchaseItemEntry {
  final product_models.ProductModel product;
  int cartonQuantity;
  int piecesPerCarton;
  double pricePerCarton;
  DateTime? expirationDate;
  DateTime? manufacturingDate;

  _PurchaseItemEntry({
    required this.product,
    required this.cartonQuantity,
    required this.piecesPerCarton,
    required this.pricePerCarton,
    this.expirationDate,
    this.manufacturingDate,
  });
}

/// UI Card for each purchase item
class _PurchaseItemCard extends StatelessWidget {
  final _PurchaseItemEntry entry;
  final Function(_PurchaseItemEntry) onUpdate;
  final VoidCallback onRemove;

  const _PurchaseItemCard({
    required this.entry,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = entry.cartonQuantity * entry.pricePerCarton;
    final totalPieces = entry.cartonQuantity * entry.piecesPerCarton;
    final pricePerPiece = entry.piecesPerCarton > 0
        ? entry.pricePerCarton / entry.piecesPerCarton
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name and remove button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.product.name,
                    style: AppText.label.copyWith(fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Text(
              '${entry.product.category} • ${entry.product.brand}',
              style: AppText.body.copyWith(
                color: AppColors.taupe,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),

            // Quantity fields
            Row(
              children: [
                Expanded(
                  child: _QuantityField(
                    label: 'Cartons',
                    value: entry.cartonQuantity,
                    onChanged: (v) {
                      final updated = _PurchaseItemEntry(
                        product: entry.product,
                        cartonQuantity: v,
                        piecesPerCarton: entry.piecesPerCarton,
                        pricePerCarton: entry.pricePerCarton,
                        expirationDate: entry.expirationDate,
                        manufacturingDate: entry.manufacturingDate,
                      );
                      onUpdate(updated);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuantityField(
                    label: 'Pcs/Carton',
                    value: entry.piecesPerCarton,
                    onChanged: (v) {
                      final updated = _PurchaseItemEntry(
                        product: entry.product,
                        cartonQuantity: entry.cartonQuantity,
                        piecesPerCarton: v,
                        pricePerCarton: entry.pricePerCarton,
                        expirationDate: entry.expirationDate,
                        manufacturingDate: entry.manufacturingDate,
                      );
                      onUpdate(updated);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PriceField(
                    label: 'Price/Carton',
                    value: entry.pricePerCarton,
                    onChanged: (v) {
                      final updated = _PurchaseItemEntry(
                        product: entry.product,
                        cartonQuantity: entry.cartonQuantity,
                        piecesPerCarton: entry.piecesPerCarton,
                        pricePerCarton: v,
                        expirationDate: entry.expirationDate,
                        manufacturingDate: entry.manufacturingDate,
                      );
                      onUpdate(updated);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Expiration date and summary
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Expiration',
                    value: entry.expirationDate,
                    onChanged: (date) {
                      final updated = _PurchaseItemEntry(
                        product: entry.product,
                        cartonQuantity: entry.cartonQuantity,
                        piecesPerCarton: entry.piecesPerCarton,
                        pricePerCarton: entry.pricePerCarton,
                        expirationDate: date,
                        manufacturingDate: entry.manufacturingDate,
                      );
                      onUpdate(updated);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateField(
                    label: 'Manufacturing',
                    value: entry.manufacturingDate,
                    onChanged: (date) {
                      final updated = _PurchaseItemEntry(
                        product: entry.product,
                        cartonQuantity: entry.cartonQuantity,
                        piecesPerCarton: entry.piecesPerCarton,
                        pricePerCarton: entry.pricePerCarton,
                        expirationDate: entry.expirationDate,
                        manufacturingDate: date,
                      );
                      onUpdate(updated);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${totalPieces} pcs • \$${pricePerPiece.toStringAsFixed(2)}/pc',
                    style: AppText.body.copyWith(fontSize: 12),
                  ),
                  Text(
                    '\$${totalPrice.toStringAsFixed(2)}',
                    style: AppText.label.copyWith(
                      fontSize: 14,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quantity input field
class _QuantityField extends StatelessWidget {
  final String label;
  final int value;
  final Function(int) onChanged;

  const _QuantityField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body.copyWith(fontSize: 11, color: AppColors.taupe)),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                if (value > 1) onChanged(value - 1);
              },
            ),
            Expanded(
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: AppText.label.copyWith(fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}

/// Price input field
class _PriceField extends StatelessWidget {
  final String label;
  final double value;
  final Function(double) onChanged;

  const _PriceField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body.copyWith(fontSize: 11, color: AppColors.taupe)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value > 0 ? value.toStringAsFixed(2) : '',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: AppText.label.copyWith(fontSize: 16),
          decoration: InputDecoration(
            prefixText: '\$',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          onChanged: (text) {
            final val = double.tryParse(text);
            if (val != null && val >= 0) onChanged(val);
          },
        ),
      ],
    );
  }
}

/// Date picker field
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final Function(DateTime?) onChanged;

  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body.copyWith(fontSize: 11, color: AppColors.taupe)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.taupe,
                ),
                const SizedBox(width: 4),
                Text(
                  value == null ? 'Set' : '${value!.day}/${value!.month}/${value!.year}',
                  style: AppText.body.copyWith(
                    fontSize: 12,
                    color: value == null ? AppColors.taupe : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}