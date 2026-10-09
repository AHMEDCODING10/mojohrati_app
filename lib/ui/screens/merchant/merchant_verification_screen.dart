// ignore_for_file: use_build_context_synchronously, deprecated_member_use, curly_braces_in_flow_control_structures, avoid_unnecessary_containers
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import '../../widgets/merchant/merchant_drawer.dart';
import 'merchant_navigation_wrapper.dart';

class MerchantVerificationScreen extends StatefulWidget {
  const MerchantVerificationScreen({super.key});

  @override
  State<MerchantVerificationScreen> createState() => _MerchantVerificationScreenState();
}

class _MerchantVerificationScreenState extends State<MerchantVerificationScreen> {
  String? _selectedFilePath;
  Uint8List? _selectedFileBytes;
  String? _fileName;
  String _selectedType = 'commercial_register';

  final Map<String, String> _typeLabels = {
    'commercial_register': 'comm_reg'.tr(),
    'national_id': 'national_id'.tr(),
    'other': 'other_doc'.tr(),
  };

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.read<AppState>().checkVerificationStatus();
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true, // Required for Web to get bytes
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        if (kIsWeb) {
          _selectedFileBytes = result.files.single.bytes;
          _selectedFilePath = _fileName; // Placeholder for UI
        } else {
          _selectedFilePath = result.files.single.path;
        }
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedFilePath == null && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('doc_pick_error'.tr())),
      );
      return;
    }

    final appState = context.read<AppState>();
    bool success;
    
    if (kIsWeb) {
      success = await appState.uploadVerificationDocumentBytes(_selectedFileBytes!, _fileName!, _selectedType);
    } else {
      success = await appState.uploadVerificationDocument(_selectedFilePath!, _selectedType);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('upload_success_wait'.tr())),
      );
      setState(() {
        _selectedFilePath = null;
        _selectedFileBytes = null;
        _fileName = null;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('upload_error'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('verification_title'.tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.primaryGold, size: 28),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryGold, size: 22), // Forward arrow for back in RTL
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (_) => const MerchantNavigationWrapper()),
                  (route) => false
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const MerchantDrawer(),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildHeader(isDark),
                const SizedBox(height: 32),
                _buildTypeDropdown(isDark),
                const SizedBox(height: 24),
                _buildFilePicker(isDark),
                const SizedBox(height: 32),
                _buildUploadButton(appState.isLoading),
                const SizedBox(height: 40),
                _buildDocumentsList(isDark, appState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        const Icon(Icons.verified_user_rounded, size: 80, color: AppColors.primaryGold),
        const SizedBox(height: 16),
        Text(
          'upload_docs'.tr(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'upload_docs_desc'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'doc_type'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              dropdownColor: isDark ? Colors.grey[900] : Colors.white,
              items: _typeLabels.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePicker(bool isDark) {
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: _selectedFilePath == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primaryGold),
                  const SizedBox(height: 12),
                   Text('tap_to_pick'.tr()),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _fileName?.toLowerCase().endsWith('.pdf') == true 
                      ? Icons.picture_as_pdf_rounded 
                      : Icons.image_rounded, 
                    size: 48, 
                    color: AppColors.primaryGold
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(_fileName ?? '...', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text('change_file'.tr(), style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
                ],
              ),
      ),
    );
  }

  Widget _buildUploadButton(bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _handleUpload,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
            )
          : Text(
              'submit_for_verif'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildDocumentsList(bool isDark, AppState appState) {
    if (appState.verificationDocuments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'prev_uploaded_docs'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appState.verificationDocuments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = appState.verificationDocuments[index];
            final status = doc['status'] ?? 'pending';
            
            Color statusColor;
            String labelKey;
            switch(status) {
              case 'approved': statusColor = Colors.green; labelKey = 'doc_approved'; break;
              case 'rejected': statusColor = Colors.red; labelKey = 'status_rejected'; break;
              default: statusColor = Colors.orange; labelKey = 'status_pending';
            }

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Row(
                children: [
                  Icon(
                    doc['path']?.toLowerCase().endsWith('.pdf') == true 
                      ? Icons.picture_as_pdf_rounded 
                      : Icons.insert_drive_file_outlined,
                    color: AppColors.primaryGold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_typeLabels[doc['type']] ?? 'doc'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(doc['uploaded_at']?.split('T')[0] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      labelKey.tr(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}