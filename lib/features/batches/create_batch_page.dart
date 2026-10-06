import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'batch_detail_page.dart';
import 'state/batch_provider.dart';
import '../products/state/product_provider.dart';
import '../stages/state/stage_provider.dart';
import '../home/state/dashboard_provider.dart';
import '../profile/state/profile_provider.dart';

class CreateBatchPage extends ConsumerStatefulWidget {
  const CreateBatchPage({super.key});

  @override
  ConsumerState<CreateBatchPage> createState() => _CreateBatchPageState();
}

class _CreateBatchPageState extends ConsumerState<CreateBatchPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedProductId;
  int? _selectedStageId;
  String _selectedUnit = 'kg';
  final _quantityController = TextEditingController();
  final _gradeController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _commonUnits = ['kg', 'g', 'lbs', 'bags', 'bundles'];

  @override
  void dispose() {
    _quantityController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final stagesAsync = ref.watch(stageListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Batch'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Product Details',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      productsAsync.when(
                        data: (products) {
                          if (products.isEmpty) {
                            return const Text('No products found. Please add a product first.');
                          }
                          if (_selectedProductId == null && products.isNotEmpty) {
                            _selectedProductId = products.first.id;
                          }
                          return DropdownButtonFormField<int>(
                            initialValue: _selectedProductId,
                            decoration: InputDecoration(
                              labelText: 'Product',
                              prefixIcon: const Icon(Icons.eco_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: products.map((product) {
                              return DropdownMenuItem<int>(
                                value: product.id,
                                child: Text('${product.name} (#${product.id})'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedProductId = val),
                            validator: (val) => val == null ? 'Please select a product' : null,
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('Failed to load products: $err', style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 16),
                      stagesAsync.when(
                        data: (stages) {
                          final activeStages = stages.where((s) => s.active).toList()
                            ..sort((a, b) => a.sequence.compareTo(b.sequence));
                          if (_selectedStageId == null && activeStages.isNotEmpty) {
                            _selectedStageId = activeStages.first.id;
                          }
                          return DropdownButtonFormField<int?>(
                            initialValue: _selectedStageId,
                            decoration: InputDecoration(
                              labelText: 'Initial Stage (Optional)',
                              prefixIcon: const Icon(Icons.timeline_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('No initial stage'),
                              ),
                              ...activeStages.map((s) => DropdownMenuItem<int?>(
                                    value: s.id,
                                    child: Text('${s.name} (Seq ${s.sequence})'),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _selectedStageId = val),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.scale_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Quantity & Grading',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                hintText: 'e.g. 50.5',
                                prefixIcon: const Icon(Icons.numbers),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Quantity is required';
                                }
                                final parsed = double.tryParse(val.trim());
                                if (parsed == null || parsed <= 0) {
                                  return 'Must be greater than 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              decoration: InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _commonUnits.map((u) {
                                return DropdownMenuItem<String>(
                                  value: u,
                                  child: Text(u),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedUnit = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gradeController,
                        decoration: InputDecoration(
                          labelText: 'Grade / Quality (Optional)',
                          hintText: 'e.g. Grade A, Premium, Alba',
                          prefixIcon: const Icon(Icons.star_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: ['Grade A', 'Grade B', 'Alba', 'Standard'].map((preset) {
                          return ActionChip(
                            label: Text(preset, style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              _gradeController.text = preset;
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _submit(context),
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(
                    _isSubmitting ? 'Creating...' : 'Create Batch',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final quantity = double.parse(_quantityController.text.trim());
    final grade = _gradeController.text.trim().isEmpty ? null : _gradeController.text.trim();

    try {
      final ownerId = ref.read(currentUserIdProvider);
      final api = ref.read(batchApiProvider);
      final batch = await api.createBatch(
        productId: _selectedProductId!,
        quantity: quantity,
        grade: grade,
        stageId: _selectedStageId,
        unit: _selectedUnit,
        ownerId: int.tryParse(ownerId),
      );

      // Invalidate relevant providers to immediately update UI everywhere
      ref.invalidate(batchListProvider);
      ref.invalidate(ownedBatchListProvider);
      ref.invalidate(recentBatchesProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch #${batch.id} created successfully!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: batch.id)),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create batch: $msg'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
