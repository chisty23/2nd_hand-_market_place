import 'package:flutter/foundation.dart';
import '../services/offer_service.dart';

class RatingProvider extends ChangeNotifier {
  final OfferService _offerService;
  bool _isLoading = false;
  String? _errorMessage;

  RatingProvider({OfferService? offerService})
      : _offerService = offerService ?? OfferService();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> hasRated(String listingId) async {
    return await _offerService.hasRated(listingId: listingId);
  }

  Future<bool> submitRating({
    required String listingId,
    required String sellerId,
    required String buyerId,
    required int stars,
    required String comment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _offerService.submitRating(
        listingId: listingId,
        sellerId: sellerId,
        buyerId: buyerId,
        stars: stars,
        comment: comment,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
