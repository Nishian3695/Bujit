// Store screenshots for Google Play and the App Store, rendered from the real
// screens with demo data. Skipped in normal test runs; generate them with
//
//   flutter test test/store_screenshots --dart-define=SCREENSHOTS=true
//
// Writes store-screenshots/<device>/NN-name.png (captioned, ready to upload) and
// store-screenshots/<device>/raw/NN-name.png (the bare screen, also valid to
// upload). Each device's images are exactly the size its store asks for.
//
// Also writes the App Store's product page header and search results images to
// store-screenshots/app-store-creative/ (see store_banner.dart), each with a
// -safe-area copy that outlines the area Apple never crops (not for upload).
// Every image is an RGB PNG with no alpha channel, as the App Store requires.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_data.dart';
import 'png_rgb.dart';
import 'shots.dart';
import 'store_banner.dart';
import 'store_frame.dart';

const bool _enabled = bool.fromEnvironment("SCREENSHOTS");

// A store's screenshot size: [pixels] at [ratio] pixels per logical pixel, with
// the phone's status bar and home indicator as [padding] (logical pixels).
class StoreDevice {
    final String folder;
    final Size pixels;
    final double ratio;
    final EdgeInsets padding;
    final TargetPlatform platform;
    const StoreDevice(this.folder, this.pixels, this.ratio, this.padding, this.platform);

    Size get logical => pixels / ratio;
    bool get isTablet => logical.shortestSide >= 600;
}

const List<StoreDevice> devices = [
    // Play phone screenshots: 9:16, 1080 wide.
    StoreDevice("play-phone", Size(1080, 1920), 2.625, EdgeInsets.only(top: 24, bottom: 16), TargetPlatform.android),
    // App Store 6.9" iPhone (the one size Apple requires for iPhone).
    StoreDevice("iphone-6.9", Size(1320, 2868), 3, EdgeInsets.only(top: 62, bottom: 34), TargetPlatform.iOS),
    // App Store 6.3" iPhone (the 6.1"/6.3" slot), for when App Store Connect asks for it too.
    StoreDevice("iphone-6.3", Size(1206, 2622), 3, EdgeInsets.only(top: 62, bottom: 34), TargetPlatform.iOS),
    // App Store 13" iPad (required, since the app runs on iPad). Drawn larger
    // than the real iPad's 2x, since the phone layout looks sparse at full width.
    StoreDevice("ipad-13", Size(2064, 2752), 2.6, EdgeInsets.only(top: 24, bottom: 20), TargetPlatform.iOS),
];

void main() {
    // Only when generating: in normal runs every test here is skipped, and the
    // fonts' location in the Flutter SDK differs between machines (CI included).
    setUpAll(() async {
        if (_enabled) await _loadFonts();
    });

    for (final StoreDevice device in devices) {
        for (final (int i, Shot shot) in shots.indexed) {
            final String name = "${(i + 1).toString().padLeft(2, "0")}-${shot.name}";
            testWidgets("${device.folder} $name", skip: !_enabled,
                    variant: TargetPlatformVariant.only(device.platform), (tester) async {
                // flutter_test draws shadows as black outlines unless told otherwise.
                debugDisableShadows = false;
                try {
                final String dir = "store-screenshots/${device.folder}";

                // The bare screen, full size.
                await _render(tester, device.pixels, device.ratio, ScreenshotApp(device: device, shot: shot, state: demoState()));
                await shot.interact?.call(tester);
                await _save(tester, device.ratio, "$dir/raw/$name.png");

                // The same screen in a captioned frame.
                await _render(tester, device.pixels, device.ratio, StoreFrame(device: device, shot: shot,
                    screen: ScreenshotApp(device: device, shot: shot, state: demoState())));
                await shot.interact?.call(tester);
                await _save(tester, device.ratio, "$dir/$name.png");
                } finally {
                    debugDisableShadows = true;
                }
            });
        }
    }

    // The App Store's creative assets, with iPhone screens on the phones.
    final StoreDevice iphone = devices.firstWhere((d) => d.folder == "iphone-6.9");
    for (final BannerSpec spec in banners) {
        testWidgets("app-store-creative ${spec.name}", skip: !_enabled,
                variant: TargetPlatformVariant.only(TargetPlatform.iOS), (tester) async {
            debugDisableShadows = false;
            try {
                final ui.Image logo = (await tester.runAsync(() async {
                    final ui.Codec codec = await ui.instantiateImageCodec(
                        await File("site-assets/bujit-logo-512.png").readAsBytes());
                    return (await codec.getNextFrame()).image;
                }))!;
                // Each phone's screen is captured on its own first: the app can
                // only be on screen once at a time (the tutorial's keys are global).
                final Map<String, ui.Image> screens = {};
                for (final String name in spec.phones) {
                    final Shot shot = shots.firstWhere((s) => s.name == name);
                    await _render(tester, iphone.pixels, iphone.ratio,
                        ScreenshotApp(device: iphone, shot: shot, state: demoState()));
                    await shot.interact?.call(tester);
                    screens[name] = await _capture(tester, iphone.ratio);
                }
                Widget banner({bool showSafeArea = false}) => StoreBanner(
                    spec: spec,
                    logo: logo,
                    showSafeArea: showSafeArea,
                    phones: {
                        for (final MapEntry(:key, :value) in screens.entries)
                            key: DeviceOutline(device: iphone, screen: RawImage(image: value,
                                width: iphone.logical.width, height: iphone.logical.height,
                                fit: BoxFit.fill, filterQuality: FilterQuality.high)),
                    },
                );
                const String dir = "store-screenshots/app-store-creative";
                await _render(tester, spec.pixels, spec.ratio, banner());
                await _save(tester, spec.ratio, "$dir/${spec.name}.png");
                await _render(tester, spec.pixels, spec.ratio, banner(showSafeArea: true));
                await _save(tester, spec.ratio, "$dir/${spec.name}-safe-area.png");
            } finally {
                debugDisableShadows = true;
            }
        });
    }
}

final GlobalKey _boundary = GlobalKey();

Future<void> _render(WidgetTester tester, Size pixels, double ratio, Widget child) async {
    tester.view.physicalSize = pixels;
    tester.view.devicePixelRatio = ratio;
    tester.view.padding = FakeViewPadding.zero;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox()); // A fresh tree for each image
    await tester.pumpWidget(RepaintBoundary(key: _boundary, child: child));
    await tester.pumpAndSettle();
}

// What's on screen now, as an image.
Future<ui.Image> _capture(WidgetTester tester, double ratio) async => (await tester.runAsync(() {
    final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: ratio);
}))!;

Future<void> _save(WidgetTester tester, double ratio, String path) async {
    final ui.Image image = await _capture(tester, ratio);
    await tester.runAsync(() async {
        final ByteData? rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final Uint8List png = encodeRgbPng(rgba!.buffer.asUint8List(), image.width, image.height);
        image.dispose();
        final File file = File(path)..parent.createSync(recursive: true);
        file.writeAsBytesSync(png);
    });
}

// Widget tests draw text in a placeholder font; load the real ones from the
// Flutter SDK. Roboto stands in for San Francisco on iOS too (Apple's font
// isn't available here).
Future<void> _loadFonts() async {
    final String root = Platform.environment["FLUTTER_ROOT"]
        ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
    final String fonts = "$root/bin/cache/artifacts/material_fonts";
    Future<ByteData> font(String file) async =>
        ByteData.sublistView(await File("$fonts/$file").readAsBytes());

    const List<String> roboto = ["regular", "italic", "medium", "mediumitalic", "bold", "bolditalic",
        "light", "lightitalic", "thin", "black"];
    for (final String family in ["Roboto", "CupertinoSystemText", "CupertinoSystemDisplay",
            ".SF UI Text", ".SF UI Display", ".SF Pro Text", ".SF Pro Display"]) {
        final FontLoader loader = FontLoader(family);
        for (final String style in roboto) {
            loader.addFont(font("roboto-$style.ttf"));
        }
        await loader.load();
    }
    await (FontLoader("MaterialIcons")..addFont(font("materialicons-regular.otf"))).load();
}
