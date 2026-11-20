// The App Store's creative assets (iOS 27 and later): the product page header
// and the search results image. Apple crops them differently on each device, so
// the logo and headline stay inside each asset's safe area, and phones showing
// the app fill the sides, which may be cut off. Sizes and safe areas are from
// App Store Connect's "Creative assets specifications".
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'store_frame.dart';

class BannerSpec {
    final String name; // File name
    final Size pixels;
    final double ratio; // Pixels per logical pixel
    final Rect safe; // Apple's safe area, in pixels
    final List<String> phones; // Shot names: left side outer to inner, then right side inner to outer
    const BannerSpec(this.name, this.pixels, this.ratio, this.safe, this.phones);

    Size get logical => pixels / ratio;
    Rect get safeLogical => Rect.fromLTWH(safe.left / ratio, safe.top / ratio, safe.width / ratio, safe.height / ratio);
}

const List<BannerSpec> banners = [
    // Product page header: 21:9, exactly 3840 x 1646.
    BannerSpec("header", Size(3840, 1646), 2, Rect.fromLTWH(1097, 493, 1646, 661),
        ["cash-flow", "home", "credit", "single-events"]),
    // Search results: 3:2, 1920 x 1280 to 3840 x 2560 (the largest, for sharpness).
    BannerSpec("search-results", Size(3840, 2560), 2, Rect.fromLTWH(836, 765, 2168, 1030),
        ["home", "credit"]),
];

class StoreBanner extends StatelessWidget {
    final BannerSpec spec;
    final ui.Image logo;
    final Map<String, Widget> phones; // Shot name -> a DeviceOutline
    final bool showSafeArea; // Outlines the safe area, for checking the layout
    const StoreBanner({super.key, required this.spec, required this.logo, required this.phones,
        this.showSafeArea = false});

    @override
    Widget build(BuildContext context) {
        final Size canvas = spec.logical;
        final Rect safe = spec.safeLogical;
        final int perSide = spec.phones.length ~/ 2;
        // Two phones a side fill the height and run off the bottom edge; a single
        // phone a side is shown whole, centered.
        final double phoneHeight = canvas.height * (perSide > 1 ? 0.92 : 0.62);
        final double phoneWidth = phoneHeight * 0.475; // A phone outline's shape
        final double sideWidth = safe.left; // Each side's room, outside the safe area

        // From the safe area outward: the inner phone just clears it, the outer
        // one tucks behind it.
        List<Widget> side(List<String> names, {required bool left}) {
            final List<Widget> placed = [];
            for (int i = 0; i < names.length; i++) {
                final int fromInside = names.length - 1 - i; // 0 = inner
                final double center = sideWidth - phoneWidth / 2 - canvas.width * 0.012
                    - fromInside * phoneWidth * 0.62;
                final double top = perSide == 1
                    ? (canvas.height - phoneHeight) / 2
                    : canvas.height * (fromInside == 0 ? 0.16 : 0.07);
                final double angle = (fromInside == 0 ? 4 : 8) * 3.14159 / 180;
                placed.add(Positioned(
                    left: left ? center - phoneWidth / 2 : canvas.width - center - phoneWidth / 2,
                    top: top,
                    width: phoneWidth,
                    height: phoneHeight,
                    child: Transform.rotate(
                        angle: left ? -angle : angle,
                        child: FittedBox(child: phones[names[i]]),
                    ),
                ));
            }
            return placed;
        }

        final List<String> leftNames = spec.phones.sublist(0, perSide);
        final List<String> rightNames = spec.phones.sublist(perSide).reversed.toList();
        final double unit = safe.height / 100;

        return Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox.fromSize(
                size: canvas,
                child: Stack(clipBehavior: Clip.hardEdge, children: [
                    const Positioned.fill(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: RadialGradient(
                                    center: Alignment(0, -0.2),
                                    radius: 1.1,
                                    colors: [softPink, logoPink],
                                ),
                            ),
                        ),
                    ),
                    // Outer phones first, so the inner ones sit in front.
                    ...side(leftNames, left: true),
                    ...side(rightNames, left: false),
                    Positioned.fromRect(
                        rect: safe,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(unit * 30 * 0.225),
                                    child: RawImage(image: logo, width: unit * 30, height: unit * 30,
                                        filterQuality: FilterQuality.high),
                                ),
                                SizedBox(height: unit * 6),
                                Text("Budget by paycheck",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: "Roboto", color: plum, height: 1.05,
                                        fontSize: unit * 17, fontWeight: FontWeight.w900)),
                                SizedBox(height: unit * 4),
                                Text("See what's left after each check, before you spend it.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: "Roboto", color: taglinePlum, height: 1.25,
                                        fontSize: unit * 7, fontWeight: FontWeight.w500)),
                            ],
                        ),
                    ),
                    if (showSafeArea)
                        Positioned.fromRect(
                            rect: safe,
                            child: DecoratedBox(decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue, width: 2))),
                        ),
                ]),
            ),
        );
    }
}
