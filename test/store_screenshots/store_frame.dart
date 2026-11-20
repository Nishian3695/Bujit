// The captioned store image: a headline and subtitle on the logo pink, over
// the screen in a phone (or tablet) outline. Colors follow BRAND.md and the
// Play feature graphic.
import 'package:flutter/material.dart';

import 'shots.dart';
import 'store_screenshots_test.dart';

const Color logoPink = Color(0xFFF495B7);
const Color softPink = Color(0xFFFCE4EE);
const Color plum = Color(0xFF4A0B26);
const Color taglinePlum = Color(0xFF6E1A3F);
const Color _bezel = Color(0xFF1C1014);

class StoreFrame extends StatelessWidget {
    final StoreDevice device;
    final Shot shot;
    final Widget screen; // A ScreenshotApp, drawn at the device's full size and scaled down
    const StoreFrame({super.key, required this.device, required this.shot, required this.screen});

    @override
    Widget build(BuildContext context) {
        final Size canvas = device.logical;
        // Sizes scale with the canvas width so every device looks alike.
        final double unit = canvas.width / 100;
        final bool tablet = device.isTablet;

        return Directionality(
            textDirection: TextDirection.ltr,
            child: DecoratedBox(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [logoPink, softPink],
                    ),
                ),
                child: SizedBox.fromSize(
                    size: canvas,
                    child: Column(children: [
                        // The same height for every caption, so the device is the same size in each image.
                        SizedBox(height: unit * (tablet ? 26 : 52), child: _caption(unit, tablet)),
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.only(bottom: unit * (tablet ? 5 : 8)),
                                child: Center(child: FittedBox(child: DeviceOutline(device: device, screen: screen))),
                            ),
                        ),
                    ]),
                ),
            ),
        );
    }

    Widget _caption(double unit, bool tablet) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: unit * 7),
                child: Text(shot.caption,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: "Roboto", color: plum, height: 1.1,
                        fontSize: unit * (tablet ? 6 : 9.5), fontWeight: FontWeight.w900)),
            ),
            SizedBox(height: unit * (tablet ? 1.6 : 3)),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: unit * (tablet ? 14 : 9)),
                child: Text(shot.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: "Roboto", color: taglinePlum, height: 1.3,
                        fontSize: unit * (tablet ? 2.8 : 4.6), fontWeight: FontWeight.w500)),
            ),
        ],
    );
}

// [screen] in a phone or tablet outline with a soft shadow, at the device's
// full logical size plus the bezel; scale it with a FittedBox.
class DeviceOutline extends StatelessWidget {
    final StoreDevice device;
    final Widget screen; // A ScreenshotApp
    const DeviceOutline({super.key, required this.device, required this.screen});

    @override
    Widget build(BuildContext context) {
        final Size size = device.logical;
        final double unit = size.width / 100;
        final bool tablet = device.isTablet;
        final double bezel = unit * (tablet ? 1.4 : 2.4);
        final double radius = unit * (tablet ? 3 : 7);
        return Container(
            padding: EdgeInsets.all(bezel),
            decoration: BoxDecoration(
                color: _bezel,
                borderRadius: BorderRadius.circular(radius + bezel),
                boxShadow: [BoxShadow(color: plum.withValues(alpha: 0.35),
                    blurRadius: unit * 6, offset: Offset(0, unit * 2))],
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: SizedBox.fromSize(size: size, child: screen),
            ),
        );
    }
}
