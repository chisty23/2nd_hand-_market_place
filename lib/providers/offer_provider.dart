import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/offer_model.dart';
import '../services/offer_service.dart';

class OfferProvider extends ChangeNotifier {
  final OfferService _offerService;
  StreamSubscription<List<OfferModel>>? _receivedOffersSubscription;
  StreamSubscription<List<OfferModel>>? _madeOffersSubscription;

  List<OfferModel> _receivedOffers = [];
  List<OfferModel> _madeOffers = [];
  bool _isLoading = false;
  String? _errorMessage;

  OfferProvider({OfferService? offerService})
      : _offerService = offerService ?? OfferService();

  List<OfferModel> get receivedOffers => _receivedOffers;
  List<OfferModel> get madeOffers => _madeOffers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void initOffers(String userId) {
    _isLoading = true;
    notifyListeners();

    _receivedOffersSubscription?.cancel();
    _receivedOffersSubscription = _offerService.streamReceivedOffers(userId).listen(
      (offers) {
        _receivedOffers = offers;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _madeOffersSubscription?.cancel();
    _madeOffersSubscription = _offerService.streamMadeOffers(userId).listen(
      (offers) {
        _madeOffers = offers;
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

  void cancelSubscriptions() {
    _receivedOffersSubscription?.cancel();
    _madeOffersSubscription?.cancel();
    _receivedOffers = [];
    _madeOffers = [];
    notifyListeners();
  }

  // Count pending offers for a specific listing (used in Sell tab)
  int pendingCountForListing(String listingId) {
    return _receivedOffers
        .where((o) => o.listingId == listingId && o.effectiveStatus == 'pending')
        .length;
  }

  Future<bool> makeOffer({
    required String listingId,
    required String listingTitle,
    required String sellerId,
    required String buyerId,
    required String buyerName,
    required int amount,
    required String message,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _offerService.makeOffer(
        listingId: listingId,
        listingTitle: listingTitle,
        sellerId: sellerId,
        buyerId: buyerId,
        buyerName: buyerName,
        amount: amount,
        message: message,
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

  // State Machine Actions:
  Future<bool> acceptOffer(String offerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _offerService.acceptOffer(offerId);
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

  Future<bool> declineOffer(String offerId) async {
    try {
      await _offerService.declineOffer(offerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> counterOffer({
    required String offerId,
    required int counterAmount,
    String? message,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _offerService.counterOffer(
        offerId: offerId,
        counterAmount: counterAmount,
        message: message,
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

  Future<bool> acceptCounter(String offerId) async {
    return await acceptOffer(offerId);
  }

  Future<bool> declineCounter(String offerId) async {
    return await declineOffer(offerId);
  }

  Future<bool> withdrawOffer(String offerId) async {
    try {
      await _offerService.withdrawOffer(offerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _receivedOffersSubscription?.cancel();
    _madeOffersSubscription?.cancel();
    super.dispose();
  }
}
