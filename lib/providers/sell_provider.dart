import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';

class SellProvider extends ChangeNotifier {
  final ListingService _listingService;
  StreamSubscription<List<ListingModel>>? _userListingsSubscription;
  List<ListingModel> _myListings = [];
  bool _isLoading = false;
  String? _errorMessage;

  SellProvider({ListingService? listingService})
      : _listingService = listingService ?? ListingService();

  List<ListingModel> get myListings => _myListings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void initUserListings(String userId) {
    _isLoading = true;
    notifyListeners();
    _userListingsSubscription?.cancel();
    _userListingsSubscription = _listingService.streamUserListings(userId).listen(
      (listings) {
        _myListings = listings;
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

  void cancelSubscription() {
    _userListingsSubscription?.cancel();
    _myListings = [];
    notifyListeners();
  }

  Future<bool> createListing(ListingModel listing) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _listingService.createListing(listing);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateListing(ListingModel listing) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _listingService.updateListing(listing);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setStatus(String listingId, String status, {String? reservedFor}) async {
    try {
      await _listingService.updateStatus(listingId, status, reservedFor: reservedFor);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markSold(String listingId, String sellerId, {String? buyerId}) async {
    try {
      await _listingService.markSold(
        listingId: listingId,
        sellerId: sellerId,
        buyerId: buyerId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteListing(String listingId) async {
    try {
      await _listingService.deleteListing(listingId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userListingsSubscription?.cancel();
    super.dispose();
  }
}
