import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../repositories/product_repository.dart';
import '../services/storage_service.dart';

/// Admin-only screen. Reachable only from admin screens; the real
/// enforcement is the Firestore rules (products write requires isAdmin()).
class AddEditProductPage extends StatefulWidget {
  final ProductModel? existingProduct;
  const AddEditProductPage({super.key, this.existingProduct});

  bool get isEditing => existingProduct != null;

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ProductRepository();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  late final TextEditingController _name;
  late final TextEditingController _barcode;
  late final TextEditingController _category;
  late final TextEditingController _brand;
  late final TextEditingController _supplier;
  late final TextEditingController _description;
  late final TextEditingController _purchasePrice;
  late final TextEditingController _sellingPrice;
  late final TextEditingController _stockQuantity;
  late final TextEditingController _minimumStock;
  late final TextEditingController _maximumStock;

  DateTime? _expirationDate;
  DateTime? _manufacturingDate;
  File? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _name = TextEditingController(text: p?.name ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _supplier = TextEditingController(text: p?.supplier ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _purchasePrice = TextEditingController(text: p?.purchasePrice.toString() ?? '');
    _sellingPrice = TextEditingController(text: p?.sellingPrice.toString() ?? '');
    _stockQuantity = TextEditingController(text: p?.stockQuantity.toString() ?? '0');
    _minimumStock = TextEditingController(text: p?.minimumStock.toString() ?? '5');
    _maximumStock = TextEditingController(text: p?.maximumStock.toString() ?? '100');
    _expirationDate = p?.expirationDate;
    _manufacturingDate = p?.manufacturingDate;
  }

  @override
  void dispose() {
    for (final c in [
      _name, _barcode, _category, _brand, _supplier, _description,
      _purchasePrice, _sellingPrice, _stockQuantity, _minimumStock, _maximumStock,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _pickedImage = File(file.path));
  }

  Future<void> _pickDate({required bool isExpiration}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isExpiration) {
          _expirationDate = picked;
        } else {
          _manufacturingDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final userName = auth.userModel?.name ?? 'Unknown';
    String? imageWarning;

    try {
      if (widget.isEditing) {
        final id = widget.existingProduct!.id;
        String? imageUrl = widget.existingProduct!.imageUrl;

        if (_pickedImage != null) {
          // Save the product fields FIRST, independent of the image.
          // If the image upload fails, the edit itself still succeeds.
          try {
            imageUrl = await _storageService.uploadProductImage(
                file: _pickedImage!, productId: id);
          } catch (e) {
            imageWarning = 'Product saved, but the image failed to upload: $e';
          }
        }

        await _repository.updateProduct(id, {
          'name': _name.text.trim(),
          'category': _category.text.trim(),
          'brand': _brand.text.trim(),
          'supplier': _supplier.text.trim(),
          'description': _description.text.trim(),
          'purchasePrice': double.parse(_purchasePrice.text),
          'sellingPrice': double.parse(_sellingPrice.text),
          'stockQuantity': int.parse(_stockQuantity.text),
          'minimumStock': int.parse(_minimumStock.text),
          'maximumStock': int.parse(_maximumStock.text),
          'expirationDate': _expirationDate,
          'manufacturingDate': _manufacturingDate,
          'imageUrl': imageUrl,
          'lastModifiedBy': userName,
        });
      } else {
        final newProduct = ProductModel(
          id: '',
          barcode: _barcode.text.trim(),
          qrCode: _barcode.text.trim(), // QR encodes the same product ref by default
          name: _name.text.trim(),
          category: _category.text.trim(),
          brand: _brand.text.trim(),
          description: _description.text.trim(),
          supplier: _supplier.text.trim(),
          purchasePrice: double.parse(_purchasePrice.text),
          sellingPrice: double.parse(_sellingPrice.text),
          stockQuantity: int.parse(_stockQuantity.text),
          reservedQuantity: 0,
          minimumStock: int.parse(_minimumStock.text),
          maximumStock: int.parse(_maximumStock.text),
          expirationDate: _expirationDate,
          manufacturingDate: _manufacturingDate,
          lastUpdated: DateTime.now(),
          createdBy: userName,
          lastModifiedBy: userName,
        );

        // Create the product doc FIRST. The image is a nice-to-have on
        // top of it, not a precondition for the product existing.
        final id = await _repository.addProduct(newProduct);

        if (_pickedImage != null) {
          try {
            final imageUrl = await _storageService.uploadProductImage(
                file: _pickedImage!, productId: id);
            await _repository.updateProduct(id, {'imageUrl': imageUrl});
          } catch (e) {
            imageWarning = 'Product saved, but the image failed to upload: $e';
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        if (imageWarning != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(imageWarning), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Product' : 'Add Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    image: _pickedImage != null
                        ? DecorationImage(image: FileImage(_pickedImage!), fit: BoxFit.cover)
                        : (widget.existingProduct?.imageUrl != null
                        ? DecorationImage(
                        image: NetworkImage(widget.existingProduct!.imageUrl!),
                        fit: BoxFit.cover)
                        : null),
                  ),
                  child: (_pickedImage == null && widget.existingProduct?.imageUrl == null)
                      ? const Icon(Icons.add_a_photo_outlined, size: 32)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _field(_name, 'Product Name', required: true),
            _field(_barcode, 'Barcode', required: true, enabled: !widget.isEditing),
            Row(children: [
              Expanded(child: _field(_category, 'Category', required: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_brand, 'Brand')),
            ]),
            _field(_supplier, 'Supplier'),
            _field(_description, 'Description', maxLines: 3),

            Row(children: [
              Expanded(child: _field(_purchasePrice, 'Purchase Price', number: true, required: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_sellingPrice, 'Selling Price', number: true, required: true)),
            ]),
            Row(children: [
              Expanded(child: _field(_stockQuantity, 'Stock Qty', number: true, required: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_minimumStock, 'Min Stock', number: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_maximumStock, 'Max Stock', number: true)),
            ]),

            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Manufacturing Date'),
              subtitle: Text(_manufacturingDate == null
                  ? 'Not set'
                  : '${_manufacturingDate!.day}/${_manufacturingDate!.month}/${_manufacturingDate!.year}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(isExpiration: false),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiration Date'),
              subtitle: Text(_expirationDate == null
                  ? 'Not set'
                  : '${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(isExpiration: true),
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.isEditing ? 'Save Changes' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {bool required = false, bool number = false, int maxLines = 1, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) return 'Required';
          if (number && v != null && v.isNotEmpty && double.tryParse(v) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
      ),
    );
  }
}