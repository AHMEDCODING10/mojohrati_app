import 'package:flutter/material.dart';
import '../../../config/colors.dart';

class SizeGuideScreen extends StatelessWidget {
  const SizeGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دليل المقاسات'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'كيف أعرف مقاس الخاتم؟',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. قم بقص شريط من الورق أو استخدم خيطاً.\n'
              '2. لف الشريط حول قاعدة الإصبع المراد قياسه.\n'
              '3. ضع علامة بالقلم حيث يلتقي طرفا الشريط.\n'
              '4. قم بقياس طول الشريط بالمسطرة (بالملليمتر).\n'
              '5. قارن القياس بالجدول أدناه.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            _buildTable(),
             const SizedBox(height: 32),
             const Text(
              'ملاحظة: المقاسات قد تختلف قليلاً حسب التصميم.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        _buildRow(['المقاس (أمريكي)', 'القطر (مم)', 'المحيط (مم)'], isHeader: true),
        _buildRow(['5', '15.7', '49.3']),
        _buildRow(['6', '16.5', '51.9']),
        _buildRow(['7', '17.3', '54.4']),
        _buildRow(['8', '18.1', '57']),
        _buildRow(['9', '18.9', '59.5']),
        _buildRow(['10', '19.8', '62.1']),
      ],
    );
  }

  TableRow _buildRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      decoration: isHeader ? BoxDecoration(color: AppColors.primaryGold.withOpacity(0.1)) : null,
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            cell,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: isHeader ? AppColors.primaryGold : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
