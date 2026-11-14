import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_helper.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sell_provider.dart';

class CreateEditListingScreen extends StatefulWidget {
  final ListingModel? listingToEdit;

  const CreateEditListingScreen({super.key, this.listingToEdit});

  @override
  State<CreateEditListingScreen> createState() => _CreateEditListingScreenState();
}

class _CreateEditListingScreenState extends State<CreateEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;

  late String _selectedCategory;
  late String _selectedCondition;
  late bool _negotiable;
  bool _isLoading = false;

  final List<String> _conditions = ['new', 'like-new', 'used', 'worn'];

  @override
  void initState() {
    super.initState();
    final item = widget.listingToEdit;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _priceController = TextEditingController(text: item != null ? item.price.toString() : '');
    _imageUrlController = TextEditingController(text: item?.imageUrl ?? '');

    _selectedCategory = item?.category ?? CategoryHelper.categories[1]; // e.g. Books
    if (_selectedCategory == 'All') _selectedCategory = 'Books';
    _selectedCondition = item?.condition ?? 'used';
    _negotiable = item?.negotiable ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    final user = auth.firebaseUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final price = int.parse(_priceController.text.trim());
    final img = _imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null;

    bool success;
    if (widget.listingToEdit != null) {
      final updated = ListingModel(
        id: widget.listingToEdit!.id,
        title: title,
        keywords: ListingModel.generateKeywords(title),
        description: desc,
        category: _selectedCategory,
        condition: _selectedCondition,
        price: price,
        negotiable: _negotiable,
        imageUrl: img,
        sellerId: widget.listingToEdit!.sellerId,
        sellerName: widget.listingToEdit!.sellerName,
        status: widget.listingToEdit!.status,
        reservedFor: widget.listingToEdit!.reservedFor,
        createdAt: widget.listingToEdit!.createdAt,
      );
      success = await sellProvider.updateListing(updated);
    } else {
      final newListing = ListingModel(
        id: '',
        title: title,
        keywords: ListingModel.generateKeywords(title),
        description: desc,
        category: _selectedCategory,
        condition: _selectedCondition,
        price: price,
        negotiable: _negotiable,
        imageUrl: img,
        sellerId: user.uid,
        sellerName: auth.userProfile?.name ?? 'Campus Student',
        status: 'available',
      );
      success = await sellProvider.createListing(newListing);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.listingToEdit != null ? 'Listing updated!' : 'Listing posted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sellProvider.errorMessage ?? 'Action failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.listingToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Listing' : 'Create Listing'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Listing Title *',
                  hintText: 'e.g. Calculus 8th Edition, Trek Mountain Bike',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter a title';
                  if (val.trim().length > 80) return 'Title too long (max 80 chars)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: CategoryHelper.categories
                    .where((c) => c != 'All')
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(CategoryHelper.getIcon(cat), size: 18, color: CategoryHelper.getColor(cat)),
                              const SizedBox(width: 10),
                              Text(cat),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              // Condition Selector
              const Text('Item Condition *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _conditions.map((cond) {
                  final isSel = _selectedCondition == cond;
                  return ChoiceChip(
                    label: Text(cond.toUpperCase()),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedCondition = cond),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Price Field
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Asking Price (৳) *',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter price';
                  final p = int.tryParse(val.trim());
                  if (p == null || p <= 0) return 'Enter a valid amount';
                  if (p > 500000) return 'Price seems unreasonably high';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Negotiable Switch
              SwitchListTile(
                title: const Text('Price Negotiable'),
                subtitle: const Text('Allow buyers to make counter offers'),
                value: _negotiable,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _negotiable = val),
              ),
              const SizedBox(height: 12),

              // Optional Image URL
              TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Optional Image URL Link',
                  hintText: 'https://images.unsplash.com/...',
                  prefixIcon: const Icon(Icons.link_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: If no image link is pasted, a category icon and color will automatically be used.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Condition details, duration used, reason for selling...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val != null && val.trim().length > 800) {
                    return 'Description cannot exceed 800 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'Save Changes' : 'Post Listing',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
