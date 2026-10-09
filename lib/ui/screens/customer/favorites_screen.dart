import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../state/favorites_state.dart';
import '../../widgets/custom/product_card.dart';
import 'product_details_screen.dart';
import '../../widgets/shared/empty_state.dart';
import 'package:flutter/services.dart';
import '../../../utils/localization_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 500 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 500 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    HapticFeedback.mediumImpact();
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = context.watch<FavoritesState>();
    final appState = context.watch<AppState>();
    final favoriteProducts = appState.products.where((p) => favoritesState.favoriteIds.contains(p.id)).toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return Scaffold(
      appBar: AppBar(
        title: Text('favorites'.tr()),
      ),
      body: favoriteProducts.isEmpty
          ? EmptyState(
              title: 'favorites_empty_title'.tr(),
              message: 'favorites_empty_desc'.tr(),
              icon: Icons.heart_broken_outlined,
            )
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: favoriteProducts.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: favoriteProducts[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: favoriteProducts[index])),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
      floatingActionButton: _showScrollToTop ? FloatingActionButton(
        onPressed: _scrollToTop,
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
        mini: true,
        child: const Icon(Icons.keyboard_arrow_up_rounded),
      ) : null,
    );
  }
}
