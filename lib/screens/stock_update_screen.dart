import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class StockUpdateScreen extends StatefulWidget {
  const StockUpdateScreen({super.key});

  @override
  State<StockUpdateScreen> createState() => _StockUpdateScreenState();
}

class _StockUpdateScreenState extends State<StockUpdateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Stock Update'),
        backgroundColor: AppTheme.bgDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(
              icon: Icon(Icons.add_circle_outline_rounded),
              text: 'Stock In',
            ),
            Tab(
              icon: Icon(Icons.remove_circle_outline_rounded),
              text: 'Stock Out',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StockForm(type: 'in'),
          _StockForm(type: 'out'),
        ],
      ),
    );
  }
}

// ─── Stock Form ────────────────────────────────────────────────────────────────

class _StockForm extends StatefulWidget {
  final String type; // 'in' or 'out'
  const _StockForm({required this.type});

  @override
  State<_StockForm> createState() => _StockFormState();
}

class _StockFormState extends State<_StockForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  Product? _selectedProduct;
  bool _isSaving = false;

  bool get isStockIn => widget.type == 'in';

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = isStockIn ? AppTheme.secondary : AppTheme.error;

    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final products = provider.allProducts;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isStockIn
                              ? Icons.add_circle_rounded
                              : Icons.remove_circle_rounded,
                          color: color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isStockIn ? 'Stock In' : 'Stock Out',
                            style: TextStyle(
                              color: color,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isStockIn
                                ? 'Record new items added to inventory'
                                : 'Record items used or sold',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Select Product',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                // Product picker
                if (products.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Text(
                      'No products found. Add products first.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                else
                  _buildProductDropdown(products, color),
                const SizedBox(height: 20),
                // Show current stock info if product selected
                if (_selectedProduct != null) ...[
                  _buildStockInfo(_selectedProduct!, color),
                  const SizedBox(height: 20),
                ],
                const Text('Quantity',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixIcon: Icon(Icons.numbers_rounded, color: color),
                    suffixText: 'units',
                    suffixStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter quantity';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text('Note (optional)',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Received from supplier, Used in production...',
                    prefixIcon: Icon(Icons.note_alt_rounded),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSaving || _selectedProduct == null ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Icon(isStockIn
                            ? Icons.add_circle_rounded
                            : Icons.remove_circle_rounded),
                    label: Text(
                      isStockIn ? 'Confirm Stock In' : 'Confirm Stock Out',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductDropdown(List<Product> products, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedProduct != null
              ? color.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Product>(
          value: _selectedProduct,
          isExpanded: true,
          dropdownColor: AppTheme.bgCard,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          hint: const Text('Choose a product',
              style: TextStyle(color: AppTheme.textMuted)),
          icon: const Icon(Icons.expand_more_rounded, color: AppTheme.textSecondary),
          items: products
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.stockColor(p.stockStatus),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                        ),
                        Text(
                          '${p.quantity} units',
                          style: TextStyle(
                            color: AppTheme.stockColor(p.stockStatus),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (p) => setState(() => _selectedProduct = p),
        ),
      ),
    );
  }

  Widget _buildStockInfo(Product product, Color color) {
    final statusColor = AppTheme.stockColor(product.stockStatus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                Text(product.category,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Text('Current: ',
                      style:
                          TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  Text(
                    '${product.quantity}',
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18),
                  ),
                ],
              ),
              Text('Min: ${product.minimumThreshold}',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) return;
    setState(() => _isSaving = true);

    final provider = context.read<InventoryProvider>();
    final qty = int.parse(_quantityCtrl.text);
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    String? error;
    if (isStockIn) {
      error = await provider.stockIn(
          productId: _selectedProduct!.id, quantity: qty, note: note);
    } else {
      error = await provider.stockOut(
          productId: _selectedProduct!.id, quantity: qty, note: note);
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (error == null) {
          _quantityCtrl.clear();
          _noteCtrl.clear();
          _selectedProduct = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? (isStockIn ? 'Stock added successfully!' : 'Stock removed successfully!')),
          backgroundColor: error != null ? AppTheme.error : AppTheme.success,
        ),
      );
    }
  }
}
