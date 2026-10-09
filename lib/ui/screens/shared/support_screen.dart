import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/colors.dart';
import '../../../utils/localization_service.dart';
import '../../../state/app_state.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<AppState>().fetchContactSettings(silently: true);
      }
    });
  }

  Future<void> _handleContactTap(BuildContext context, Map<String, dynamic> contact) async {
    final type = contact['type']?.toString().toLowerCase() ?? '';
    final value = contact['value']?.toString() ?? '';
    
    if (value.isEmpty) return;

    String url = '';
    if (type == 'whatsapp') {
      // Standardize whatsapp link to wa.me for reliability on devices
      final cleanNumber = value.replaceAll(RegExp(r'\D'), ''); // Keep only digits
      url = 'https://wa.me/$cleanNumber';
    } else if (type == 'phone' || type == 'call') {
      url = 'tel:$value';
    } else if (type == 'email') {
      url = 'mailto:$value';
    } else if (value.startsWith('http')) {
      url = value;
    }

    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('could_not_open_url'.tr())),
            );
          }
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('error_opening_url'.tr())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'help_support'.tr(),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: appState.isLoadingSettings && appState.contactList.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      _buildHeroHeader(isDark),
                      const SizedBox(height: 48),
                      if (appState.contactList.isEmpty)
                        _buildEmptyState(isDark)
                      else
                        _buildDynamicContactGrid(context, appState.contactList, isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
          ),
          child: const Icon(Icons.support_agent_rounded, size: 56, color: AppColors.primaryGold),
        ),
        const SizedBox(height: 24),
        Text('how_to_help_q'.tr(), 
          style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
        const SizedBox(height: 8),
        Text('support_availability'.tr(), 
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
      ],
    ).animate().fadeIn().scale();
  }

  Widget _buildEmptyState(bool isDark) {
    return Column(
      children: [
        Icon(Icons.contact_support_outlined, size: 64, color: AppColors.primaryGold.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(
          'لا توجد وسائل تواصل متاحة حالياً',
          style: GoogleFonts.cairo(color: isDark ? Colors.white38 : Colors.black38),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildDynamicContactGrid(BuildContext context, List<dynamic> contacts, bool isDark) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index] as Map<String, dynamic>;
        final type = contact['type']?.toString().toLowerCase() ?? '';
        final label = contact['label']?.toString() ?? _getLabelForType(type);
        
        IconData iconData = Icons.link_rounded;
        Color accentColor = AppColors.primaryGold;

        if (type == 'whatsapp') {
          iconData = Icons.chat_bubble_outline_rounded;
          accentColor = Colors.green;
        } else if (type == 'phone' || type == 'call') {
          iconData = Icons.phone_in_talk_outlined;
          accentColor = Colors.blue;
        } else if (type == 'email') {
          iconData = Icons.email_outlined;
          accentColor = Colors.redAccent;
        }

        return _buildContactCard(
          label,
          contact['value']?.toString() ?? '',
          iconData,
          accentColor,
          () => _handleContactTap(context, contact),
          isDark,
        ).animate().slideY(begin: 0.2, end: 0, delay: (index * 100).ms).fadeIn();
      },
    );
  }

  String _getLabelForType(String type) {
    switch (type) {
      case 'whatsapp': return 'whatsapp'.tr();
      case 'phone':
      case 'call': return 'contact_phone'.tr();
      case 'email': return 'contact_email'.tr();
      default: return 'help_support'.tr();
    }
  }

  Widget _buildContactCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                 if (!isDark) BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(title, 
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, 
                  textAlign: TextAlign.center, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
