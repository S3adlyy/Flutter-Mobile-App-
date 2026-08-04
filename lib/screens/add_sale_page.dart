import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_search_dialog.dart';
import 'manage_clients_page.dart';

/// Admin-only screen for creating a new sale.
/// Supports selling in cartons, pieces, or both.
class AddSalePage extends StatefulWidget {
  const AddSalePage({super.key});

  @override
  State<AddSalePage> createState() => _AddSalePageState();
}

class _AddSalePageState extends State<AddSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientSearchController = TextEditingController();

  String? _selectedClientId;
  List<_SaleItemEntry> _items = [];
  bool _isSaving = false;
  bool _isNewClient = false;

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadClients();
    });
  }

  void _addProduct(ProductModel product) {
    setState(() {
      _items.add(_SaleItemEntry(
        product: product,
        piecesPerCarton: 30,
        cartonsSold: 0,
        piecesSold: 0,
        pricePerCarton: product.sellingPrice * 30,
        pricePerPiece: product.sellingPrice,
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
      return sum + (item.cartonsSold * item.pricePerCarton) +
          (item.piecesSold * item.pricePerPiece);
    });
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClientId == null && !_isNewClient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client or create a new one')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final saleProvider = context.read<SaleProvider>();

    setState(() => _isSaving = true);

    String clientId = _selectedClientId ?? '';
    String clientName = _clientNameController.text.trim();
    String clientPhone = _clientPhoneController.text.trim();

    // If new client, create them first
    if (_isNewClient) {
      final newClientId = await saleProvider.createClient(
        name: clientName,
        phone: clientPhone,
      );
      if (newClientId == null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(saleProvider.errorMessage ?? 'Failed to create client'),
            backgroundColor: AppColors.coral,
          ),
        );
        return;
      }
      clientId = newClientId;
    }

    final success = await saleProvider.createSale(
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      items: _items.map((item) {
        return SaleItemInput(
          product: item.product,
          piecesPerCarton: item.piecesPerCarton,
          cartonsSold: item.cartonsSold,
          piecesSold: item.piecesSold,
          pricePerCarton: item.pricePerCarton,
          pricePerPiece: item.pricePerPiece,
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
          content: Text('Sale recorded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saleProvider.errorMessage ?? 'Failed to save sale'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final saleProvider = context.watch<SaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
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
            // Client selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _selectedClientId,
                          hint: const Text('Select Client'),
                          decoration: InputDecoration(
                            labelText: 'Client *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('-- Select Client --'),
                            ),
                            ...saleProvider.clients.map((client) {
                              return DropdownMenuItem(
                                value: client.id,
                                child: Text('${client.name} (${client.phone})'),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedClientId = value;
                              _isNewClient = false;
                              if (value != null) {
                                final client = saleProvider.clients
                                    .firstWhere((c) => c.id == value);
                                _clientNameController.text = client.name;
                                _clientPhoneController.text = client.phone;
                              }
                            });
                          },
                          validator: (value) {
                            if (!_isNewClient && value == null) {
                              return 'Please select a client';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // New Client button
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isNewClient = !_isNewClient;
                            if (_isNewClient) {
                              _selectedClientId = null;
                              _clientNameController.clear();
                              _clientPhoneController.clear();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isNewClient ? AppColors.amber : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(_isNewClient ? 'Existing' : 'New'),
                      ),
                      const SizedBox(width: 4),
                      // Manage Clients button
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ManageClientsPage()),
                        ),
                        icon: const Icon(Icons.people_alt_rounded),
                        color: AppColors.amber,
                        tooltip: 'Manage Clients',
                      ),
                    ],
                  ),
                  if (_isNewClient) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _clientNameController,
                            decoration: InputDecoration(
                              labelText: 'Client Name *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) {
                              if (_isNewClient && (v == null || v.trim().isEmpty)) {
                                return 'Please enter client name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _clientPhoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (_isNewClient && (v == null || v.trim().isEmpty)) {
                                return 'Please enter phone';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  return _SaleItemCard(
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
            onPressed: _isSaving ? null : _saveSale,
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
                : const Text('Save Sale'),
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
        onProductSelected: (product) {
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
        title: const Text('How to record a sale'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Select or create a client',
                style: AppText.body,
              ),
              const SizedBox(height: 4),
              Text(
                '2. Add products to the sale',
                style: AppText.body,
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  '• Cartons Sold: Number of full cartons\n'
                      '• Pieces Sold: Individual pieces (less than a carton)\n'
                      '• Price per Carton: Selling price per carton\n'
                      '• Price per Piece: Selling price per piece',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '3. The app will automatically calculate:\n'
                    '   • Total pieces = (cartons × pieces per carton) + pieces\n'
                    '   • Subtotal = (cartons × price/carton) + (pieces × price/piece)\n'
                    '   • Total sale amount',
                style: AppText.body,
              ),
              const SizedBox(height: 4),
              Text(
                '4. Save - products will be deducted from inventory',
                style: AppText.body.copyWith(color: Colors.green),
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

/// Internal class for tracking sale item entries in the UI
class _SaleItemEntry {
  final ProductModel product;
  int piecesPerCarton;
  int cartonsSold;
  int piecesSold;
  double pricePerCarton;
  double pricePerPiece;

  _SaleItemEntry({
    required this.product,
    required this.piecesPerCarton,
    required this.cartonsSold,
    required this.piecesSold,
    required this.pricePerCarton,
    required this.pricePerPiece,
  });
}

/// UI Card for each sale item
class _SaleItemCard extends StatelessWidget {
  final _SaleItemEntry entry;
  final Function(_SaleItemEntry) onUpdate;
  final VoidCallback onRemove;

  const _SaleItemCard({
    required this.entry,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = (entry.cartonsSold * entry.pricePerCarton) +
        (entry.piecesSold * entry.pricePerPiece);
    final totalPieces = (entry.cartonsSold * entry.piecesPerCarton) + entry.piecesSold;
    final maxCartons = entry.product.stockQuantity ~/ entry.piecesPerCarton;
    final maxPieces = entry.piecesPerCarton - 1;

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
            const SizedBox(height: 8),

            // Stock info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.taupe.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Stock: ${entry.product.stockQuantity} pieces '
                    '(${maxCartons} cartons + ${entry.product.stockQuantity % entry.piecesPerCarton} pieces)',
                style: AppText.body.copyWith(fontSize: 11, color: AppColors.taupe),
              ),
            ),
            const SizedBox(height: 12),

            // Quantity fields
            Row(
              children: [
                Expanded(
                  child: _QuantityField(
                    label: 'Cartons',
                    value: entry.cartonsSold,
                    maxValue: maxCartons,
                    onChanged: (v) {
                      final updated = _SaleItemEntry(
                        product: entry.product,
                        piecesPerCarton: entry.piecesPerCarton,
                        cartonsSold: v,
                        piecesSold: entry.piecesSold,
                        pricePerCarton: entry.pricePerCarton,
                        pricePerPiece: entry.pricePerPiece,
                      );
                      onUpdate(updated);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuantityField(
                    label: 'Pieces',
                    value: entry.piecesSold,
                    maxValue: maxPieces,
                    onChanged: (v) {
                      final updated = _SaleItemEntry(
                        product: entry.product,
                        piecesPerCarton: entry.piecesPerCarton,
                        cartonsSold: entry.cartonsSold,
                        piecesSold: v,
                        pricePerCarton: entry.pricePerCarton,
                        pricePerPiece: entry.pricePerPiece,
                      );
                      onUpdate(updated);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price fields
            Row(
              children: [
                Expanded(
                  child: _PriceField(
                    label: 'Price/Carton',
                    value: entry.pricePerCarton,
                    onChanged: (v) {
                      final updated = _SaleItemEntry(
                        product: entry.product,
                        piecesPerCarton: entry.piecesPerCarton,
                        cartonsSold: entry.cartonsSold,
                        piecesSold: entry.piecesSold,
                        pricePerCarton: v,
                        pricePerPiece: entry.pricePerPiece,
                      );
                      onUpdate(updated);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PriceField(
                    label: 'Price/Piece',
                    value: entry.pricePerPiece,
                    onChanged: (v) {
                      final updated = _SaleItemEntry(
                        product: entry.product,
                        piecesPerCarton: entry.piecesPerCarton,
                        cartonsSold: entry.cartonsSold,
                        piecesSold: entry.piecesSold,
                        pricePerCarton: entry.pricePerCarton,
                        pricePerPiece: v,
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
                    '${totalPieces} pcs • ${entry.cartonsSold} carton${entry.cartonsSold > 1 ? 's' : ''}',
                    style: AppText.body.copyWith(fontSize: 12),
                  ),
                  Text(
                    '\$${subtotal.toStringAsFixed(2)}',
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
  final int maxValue;
  final Function(int) onChanged;

  const _QuantityField({
    required this.label,
    required this.value,
    required this.maxValue,
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
                if (value > 0) onChanged(value - 1);
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
              onPressed: () {
                if (value < maxValue) onChanged(value + 1);
              },
            ),
          ],
        ),
        if (maxValue > 0)
          Text(
            'Max: $maxValue',
            style: AppText.body.copyWith(fontSize: 10, color: AppColors.taupe),
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