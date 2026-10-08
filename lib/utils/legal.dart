// The Java app's legal text and outside links (strings.xml disclaimer_text and
// SettingsActivity's openHelpEmail/openPrivacyPolicy/openTellerPrivacy/...).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

const String disclaimerText =
    "Bujit is a personal budgeting tool for informational purposes only. It does not constitute financial "
    "advice.\n\nDisplayed balances may not reflect real-time account data. Bank account data is accessed "
    "securely via Plaid, a third-party service.\n\nBalance projections are estimates and should not be relied "
    "upon for financial decisions. Users are themselves responsible for verifying all financial information "
    "and making informed decisions.\n\nYou may find Plaid's legal and privacy information and this disclaimer "
    "in the settings menu.";

// Added to the disclaimer on first launch, before "I Understand".
const String disclaimerAcknowledgement =
    "By tapping \"I Understand\", you acknowledge that Bujit is not a financial advisor, balances may not "
    "reflect real-time data, projections are estimates, and should not be relied upon for financial decisions.";

class Links {
    static const String helpSuggestions = "https://bujits.com/support.html";
    static const String website = "https://bujits.com/";
    static const String csvReference = "https://bujits.com/csv-import-reference.html";
    static const String privacyPolicy = "https://bujits.com/privacy-policy.html";
    static const String plaidPrivacy = "https://plaid.com/legal/#privacy-statement";
    static const String packageName = "io.github.nishian3695.bujit";
    // The App Store's numeric ID for Bujit (App Store Connect > App Information >
    // Apple ID), for Rate Bujit on iPhone.
    static const String appStoreId = "6818891149";

    static bool get canRate =>
        defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

    // Rate Bujit (Settings): the store's page for writing a review (Play Store,
    // or the App Store's "Write a Review"), falling back to Play's web page.
    static Future<void> rate(BuildContext context) async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        try {
            await InAppReview.instance.openStoreListing(appStoreId: appStoreId.isEmpty ? null : appStoreId);
            return;
        } catch (_) {
            // No store app (e.g. an emulator without Play): try the web page.
        }
        if (await _launch("https://play.google.com/store/apps/details?id=$packageName")) return;
        messenger.showSnackBar(const SnackBar(content: Text("No browser found")));
    }

    // Opens [url] in the browser, saying so if there isn't one (as in the Java app).
    static Future<void> open(BuildContext context, String url) async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        if (!await _launch(url)) messenger.showSnackBar(const SnackBar(content: Text("No browser found")));
    }

    static Future<bool> _launch(String url) async {
        try {
            return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } catch (_) {
            return false;
        }
    }
}
