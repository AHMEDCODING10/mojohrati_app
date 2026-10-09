import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';

class ReportDialog extends StatefulWidget {
  final String type;
  final String id;

  const ReportDialog({super.key, required this.type, required this.id});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إبلاغ عن ${widget.type == 'product' ? 'منتج' : 'تاجر'}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('يرجى توضيح سبب الإبلاغ:'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'اكتب السبب هنا...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('إرسال البلاغ'),
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى كتابة السبب')));
      return;
    }

    setState(() => _isSubmitting = true);
    
    final success = await context.read<AppState>().reportContent(
      widget.type,
      widget.id,
      _reasonController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال البلاغ بنجاح. سنقوم بمراجعته.'), backgroundColor: Colors.green),
      );
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل إرسال البلاغ. يرجى المحاولة لاحقاً.'), backgroundColor: Colors.red),
      );
    }
  }
}
