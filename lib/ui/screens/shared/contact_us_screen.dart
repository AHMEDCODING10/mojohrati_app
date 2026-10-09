// ignore_for_file: use_build_context_synchronously, deprecated_member_use, curly_braces_in_flow_control_structures, avoid_unnecessary_containers
import 'package:flutter/material.dart';
import 'package:mojowharati/config/colors.dart';
import 'package:mojowharati/config/constants.dart';
import 'package:mojowharati/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/localization_service.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchContactSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.premiumBlack : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Elegant AppBar with Background
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppColors.premiumBlack : AppColors.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'تواصل معنا',
                style: GoogleFonts.cairo(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [AppColors.darkGold.withValues(alpha: 0.3), AppColors.premiumBlack]
                      : [AppColors.lightGold.withValues(alpha: 0.5), AppColors.lightBackground],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       const SizedBox(height: 20),
                       // Logo Container
                       Container(
                        padding: const EdgeInsets.all(4), // Border width
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.liquidGold,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: isDark ? Colors.black : Colors.white,
                          backgroundImage: const AssetImage(AppConstants.logoPlaceholder),
                          onBackgroundImageError: (_, __) {},
                          child: const Icon(Icons.support_agent_rounded, size: 40, color: AppColors.primaryGold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نحن هنا لمساعدتك',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك التواصل معنا عبر القنوات التالية، فريقنا جاهز للرد على استفساراتك.',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Loading or List
                  if (appState.isLoadingSettings && appState.contactList.isEmpty)
                    const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                  else if (appState.contactList.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ...appState.contactList.map((info) => _buildContactTile(context, info as Map<String, dynamic>, isDark)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(30),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.headset_off_rounded, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'no_contacts_available'.tr(),
            style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, Map<String, dynamic> info, bool isDark) {
    Color iconColor = AppColors.primaryGold;
    final type = info['type']?.toString().toLowerCase() ?? '';
    
    // Determine Color slightly richer for specific brands
    switch (type) {
      case 'whatsapp': iconColor = const Color(0xFF25D366); break;
      case 'facebook': iconColor = const Color(0xFF1877F2); break;
      case 'instagram': iconColor = const Color(0xFFE4405F); break;
      case 'youtube': iconColor = const Color(0xFFFF0000); break;
      case 'phone':
      case 'call': iconColor = Colors.blue; break;
      case 'email': iconColor = Colors.redAccent; break;
      case 'location': iconColor = Colors.orange; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchURL(info['type'] ?? 'url', info['value'] ?? ''),
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primaryGold.withValues(alpha: 0.1),
          highlightColor: AppColors.primaryGold.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(2), // tiny padding
                  child: Center(child: _buildIcon(info['icon'], iconColor, info['type'])),
                ),
                const SizedBox(width: 16),
                
                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info['label'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                       Text(
                        info['value'] ?? '',
                        style: GoogleFonts.roboto( // Roboto for numbers/links
                          fontSize: 13,
                          color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right, 
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded, 
                    size: 14, 
                    color: isDark ? Colors.white30 : Colors.black38
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(dynamic iconValue, Color defaultColor, String? type) {
    if (iconValue != null && iconValue.toString().contains('/storage/')) {
       String imageUrl = iconValue.toString();
       if (imageUrl.startsWith('/')) {
           String baseUrl = AppConstants.apiBaseUrl;
           if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
           imageUrl = '$baseUrl$imageUrl';
       }
       return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
             imageUrl,
             fit: BoxFit.cover,
             width: 48,
             height: 48,
             errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: defaultColor),
             loadingBuilder: (ctx, child, progress) => progress == null ? child : const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2)),
          ),
       );
    }

    IconData iconData;
    switch (iconValue) {
      case 'phone': iconData = Icons.phone_rounded; break;
      case 'whatsapp': iconData = Icons.chat_bubble_rounded; break;
      case 'email': iconData = Icons.email_rounded; break;
      case 'location': iconData = Icons.location_on_rounded; break;
      case 'facebook': iconData = Icons.facebook_rounded; break;
      case 'instagram': iconData = Icons.camera_alt_rounded; break;
      case 'twitter': iconData = Icons.alternate_email_rounded; break;
      case 'web': iconData = Icons.language_rounded; break;
      default: 
        if (type == 'phone') {
          iconData = Icons.phone_rounded;
        } else if (type == 'location') iconData = Icons.location_on_rounded;
        else iconData = Icons.link_rounded;
    }

    return Icon(iconData, color: defaultColor, size: 26);
  }

  Future<void> _launchURL(String type, String value) async {
    final cleanType = type.toLowerCase();
    Uri uri;
    switch (cleanType) {
      case 'phone':
      case 'call':
        uri = Uri.parse('tel:$value');
        break;
      case 'email':
        uri = Uri.parse('mailto:$value');
        break;
      case 'whatsapp':
        String phone = value.replaceAll(RegExp(r'[^\d]'), '');
        uri = Uri.parse('https://wa.me/$phone');
        break;
      case 'location':
        uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(value)}');
        break;
      default:
        uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
    }
    
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
         debugPrint('Could not launch $uri');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}