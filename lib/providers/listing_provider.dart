import 'dart:async';
import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../models/rating_and_favorite_model.dart';
import '../services/listing_service.dart';

enum SortOption { newest, priceLowToHigh, priceHighToLow }

class ListingProvider extends ChangeNotifier {
  final ListingService _listingService;
  StreamSubscription<List<ListingModel>>? _browseSubscription;
  StreamSubscription<List<FavoriteModel>>? _favoritesSubscription;

  List<ListingModel> _allAvailable = [];
  List<FavoriteModel> _favorites = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search & Filter state
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedCondition = 'All';
  RangeValues _priceRange = const RangeValues(0, 100000);
  SortOption _currentSort = SortOption.newest;

  ListingProvider({ListingService? listingService})
      : _listingService = listingService ?? ListingService() {
    initBrowseStream();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedCondition => _selectedCondition;
  RangeValues get priceRange => _priceRange;
  SortOption get currentSort => _currentSort;
  List<FavoriteModel> get favorites => _favorites;

  void initBrowseStream() {
    _isLoading = true;
    notifyListeners();
    _browseSubscription?.cancel();
    _browseSubscription = _listingService.streamAvailableListings().listen(
      (listings) {
        _allAvailable = listings;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void initFavoritesStream(String userId) {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = _listingService.streamFavorites(userId).listen((favs) {
      _favorites = favs;
      notifyListeners();
    });
  }

  void cancelSubscriptions() {
    _browseSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _allAvailable = [];
    _favorites = [];
    notifyListeners();
  }

  bool isFavorite(String listingId) {
    return _favorites.any((f) => f.listingId == listingId);
  }

  Future<void> toggleFavorite({
    required String userId,
    required String listingId,
    required String listingTitle,
  }) async {
    final currentlyFav = isFavorite(listingId);
    await _listingService.toggleFavorite(
      userId: userId,
      listingId: listingId,
      listingTitle: listingTitle,
      isCurrentlyFavorited: currentlyFav,
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setCondition(String condition) {
    _selectedCondition = condition;
    notifyListeners();
  }

  void setPriceRange(RangeValues range) {
    _priceRange = range;
    notifyListeners();
  }

  void setSortOption(SortOption sort) {
    _currentSort = sort;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _selectedCondition = 'All';
    _priceRange = const RangeValues(0, 100000);
    _currentSort = SortOption.newest;
    notifyListeners();
  }

  // Filtered and Sorted Listings computed list
  List<ListingModel> get filteredListings {
    var result = List<ListingModel>.from(_allAvailable);

    // Keyword Search
    if (_searchQuery.isNotEmpty) {
      final queryWords = _searchQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      result = result.where((listing) {
        final title = listing.title.toLowerCase();
        final desc = listing.description.toLowerCase();
        // Matches if any query word is contained in title keywords or title/desc
        return queryWords.any((q) =>
            title.contains(q) ||
            desc.contains(q) ||
            listing.keywords.any((kw) => kw.contains(q)));
      }).toList();
    }

    // Category Filter
    if (_selectedCategory != 'All') {
      result = result.where((item) => item.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // Condition Filter
    if (_selectedCondition != 'All') {
      result = result.where((item) => item.condition.toLowerCase() == _selectedCondition.toLowerCase()).toList();
    }

    // Price Range Filter
    result = result.where((item) => item.price >= _priceRange.start && item.price <= _priceRange.end).toList();

    // Sorting
    switch (_currentSort) {
      case SortOption.newest:
        result.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case SortOption.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
    }

    return result;
  }

  @override
  void dispose() {
    _browseSubscription?.cancel();
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}
