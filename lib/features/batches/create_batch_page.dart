import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'batch_detail_page.dart';
import 'state/batch_provider.dart';

class CreateBatchPage extends ConsumerStatefulWidget {
  const CreateBatchPage({super.key});

  @override
  ConsumerState<CreateBatchPage> createState() => _CreateBatchPageState();
}

class _CreateBatchPageState extends ConsumerState<CreateBatchPage> {
  final _formKey = GlobalKey<FormState>();
  final _productIdController = TextEditingController();
  final _quantityController = TextEditingController();
  final _gradeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _productIdController.dispose();
    _quantityController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Batch')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _productIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Product ID',
                  hintText: '1',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid product ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity (kg)',
                  hintText: '100',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gradeController,
                decoration: const InputDecoration(
                  labelText: 'Grade (optional)',
                  hintText: 'A',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submit(context),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Batch'),
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
    setState(() => _isSubmitting = true);

    final productId = int.parse(_productIdController.text.trim());
    final quantity = int.parse(_quantityController.text.trim());
    final grade = _gradeController.text.trim().isEmpty ? null : _gradeController.text.trim();

    try {
      final api = ref.read(batchApiProvider);
      final batch = await api.createBatch(
        productId: productId,
        quantity: quantity,
        grade: grade,
      );
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: batch.id)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create batch')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
