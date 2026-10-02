// The tip jar (the Java app's SettingsActivity Play Billing code): three one-time
// tips, sold as consumable in-app products tip_small, tip_medium and tip_large.
// Prices come from the store; a finished purchase is completed (consumed, so it
// can be bought again) and thanked. TipStore wraps the store so tests can fake it.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

enum Tip {
    small("tip_small", "☕", "\$0.99"),
    medium("tip_medium", "🍕", "\$2.99"),
    large("tip_large", "❤️", "\$4.99");

    const Tip(this.productId, this.emoji, this.defaultPrice);
    final String productId;
    final String emoji;
    final String defaultPrice; // Shown until the store's (local) price arrives
}

abstract class TipStore {
    Future<bool> isAvailable();
    // Product id -> localized price, for the products the store knows.
    Future<Map<String, String>> prices(Set<String> productIds);
    // Starts buying; false if it couldn't start.
    Future<bool> buy(String productId);
    // Product ids of purchases that just finished (each completed by the store).
    Stream<String> get purchased;
}

class InAppPurchaseTipStore implements TipStore {
    final InAppPurchase _iap = InAppPurchase.instance;
    final Map<String, ProductDetails> _products = {};

    @override
    Future<bool> isAvailable() => _iap.isAvailable();

    @override
    Future<Map<String, String>> prices(Set<String> productIds) async {
        final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
        for (final ProductDetails product in response.productDetails) {
            _products[product.id] = product;
        }
        return {for (final ProductDetails p in response.productDetails) p.id: p.price};
    }

    @override
    Future<bool> buy(String productId) async {
        final ProductDetails? product = _products[productId];
        if (product == null) return false;
        // Consumed automatically on Android, so a tip can be given again.
        return _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
    }

    @override
    Stream<String> get purchased => _iap.purchaseStream.asyncExpand((purchases) async* {
        for (final PurchaseDetails purchase in purchases) {
            if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
            if (purchase.status == PurchaseStatus.purchased) yield purchase.productID;
        }
    });
}

// Prices for the Settings buttons and a "thank you" for each finished tip. Lives
// as long as the app, since a purchase can finish after leaving Settings.
class TipJar extends ChangeNotifier {
    final TipStore store;
    final Map<Tip, String> _prices = {};
    bool available = false;
    StreamSubscription<String>? _subscription;
    final StreamController<void> _thanks = StreamController.broadcast();

    TipJar(this.store) {
        _subscription = store.purchased.listen((_) => _thanks.add(null));
    }

    // Fires once per finished tip (Settings shows "Thank you for your support!").
    Stream<void> get thanks => _thanks.stream;

    String price(Tip tip) => _prices[tip] ?? tip.defaultPrice;

    Future<void> load() async {
        try {
            available = await store.isAvailable();
            if (!available) return;
            final Map<String, String> prices = await store.prices({for (final Tip t in Tip.values) t.productId});
            for (final Tip tip in Tip.values) {
                final String? price = prices[tip.productId];
                if (price != null) _prices[tip] = price;
            }
        } catch (_) {
            available = false;
        } finally {
            notifyListeners();
        }
    }

    // False when the store isn't reachable (Settings says "Store unavailable").
    Future<bool> give(Tip tip) async {
        if (!available || !_prices.containsKey(tip)) return false;
        try {
            return await store.buy(tip.productId);
        } catch (_) {
            return false;
        }
    }

    @override
    void dispose() {
        _subscription?.cancel();
        _thanks.close();
        super.dispose();
    }
}
