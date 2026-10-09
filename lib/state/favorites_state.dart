import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_service.dart';

class FavoritesState extends ChangeNotifier {
  final Set<String> _favoriteIds = {};
  bool _initialized = false;
  final ApiService _apiService = ApiService();
  String? _token;

  Set<String> get favoriteIds => _favoriteIds;
  bool get isInitialized => _initialized;

  FavoritesState() {
    _loadLocalFavorites();
  }

  void setToken(String? token) {
    if (_token != token) {
      _token = token;
      if (token != null) {
        fetchFavorites();
      }
    }
  }

  Future<void> _loadLocalFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedFavorites = prefs.getStringList('favorite_ids');
    if (storedFavorites != null) {
      _favoriteIds.addAll(storedFavorites);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> fetchFavorites() async {
    if (_token == null) return;
    try {
      final response = await _apiService.getFavorites();
      final List data = response.data['data']['data'] as List;
      _favoriteIds.clear();
      for (var item in data) {
         if (item['product_id'] != null) {
           _favoriteIds.add(item['product_id'].toString());
         }
      }
      
      // Update local storage to match cloud
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_ids', _favoriteIds.toList());
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching favorites from backend: $e');
    }
  }

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<void> toggleFavorite(String productId) async {
    // Optimistic UI update
    bool wasFavorite = _favoriteIds.contains(productId);
    if (wasFavorite) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();
    
    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_ids', _favoriteIds.toList());

    // Sync with backend if logged in
    if (_token != null) {
      try {
        await _apiService.toggleFavorite(productId);
        // We trust the optimistic update, but could re-sync if needed
      } catch (e) {
        debugPrint('Error toggling favorite on backend: $e');
        // Revert on failure (optional but recommended for strictly consistent UX)
        if (wasFavorite) {
          _favoriteIds.add(productId);
        } else {
          _favoriteIds.remove(productId);
        }
        notifyListeners();
      }
    }
  }

  Future<void> clear() async {
    _favoriteIds.clear();
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favorite_ids');
    notifyListeners();
  }
}
