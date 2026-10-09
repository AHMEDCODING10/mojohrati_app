import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // To access navigatorKey
import '../ui/screens/customer/product_details_screen.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  void initialize(BuildContext context) {
    // 1. Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri, context);
    }, onError: (err) {
      debugPrint('Deep Link Error: $err');
    });

    // 2. Handle links that opened the app
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleUri(uri, context);
      }
    });
  }

  void _handleUri(Uri uri, BuildContext context) {
    debugPrint('Received Deep Link: $uri');
    
    // Support schemes: mojohrti://product/123 or mojowharati://product/123
    // Or App Links: https://mojowharati-app.web.app/product/123
    
    final pathSegments = uri.pathSegments;
    String? productId;

    if (uri.host == 'product' && pathSegments.isNotEmpty) {
      productId = pathSegments.first;
    } else if (uri.path.contains('/product/') || uri.path.contains('/p/')) {
       productId = pathSegments.last;
    }

    if (productId != null) {
      _navigateToProduct(productId, context);
    }
  }

  Future<void> _navigateToProduct(String productId, BuildContext context) async {
    final appState = context.read<AppState>();
    
    // We need to fetch the product details first because the screen requires a Product object
    // Or we could modify the screen to fetch by ID if needed.
    // For now, let's use a quick fetch.
    
    try {
      final product = await appState.fetchProductById(productId);
      if (product != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to deep link product: $e');
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
