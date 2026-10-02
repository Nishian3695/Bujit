// Mirrors Tutorial/TutorialOverlayLayout.java in the original Java app: dims the
// screen, cuts a rounded spotlight around the current step's target, and shows
// a card with the step's title and message plus Next/Skip. Touches outside the
// card are blocked while it's showing.
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../navigation_items/screens.dart';
import 'tutorial_manager.dart';

// Wrap a screen's Scaffold in this. When the current tutorial step belongs to
// [screen], the overlay appears on top of it.
class TutorialOverlay extends StatelessWidget {
    final AppState state;
    final TutorialScreen screen;
    final Widget child;

    const TutorialOverlay({super.key, required this.state, required this.screen, required this.child});

    @override
    Widget build(BuildContext context) {
        return ListenableBuilder(
            listenable: state,
            builder: (context, _) {
                final TutorialStep? step = state.tutorialStep;
                // Always a Stack with the screen first, so the screen keeps its state
                // (and its targets stay put) when the overlay comes and goes.
                return Stack(children: [
                    child,
                    if (step != null && step.screen == screen)
                        Positioned.fill(child: _Spotlight(state: state, step: step)),
                ]);
            },
        );
    }
}

class _Spotlight extends StatefulWidget {
    final AppState state;
    final TutorialStep step;
    const _Spotlight({required this.state, required this.step});

    @override
    State<_Spotlight> createState() => _SpotlightState();
}

class _SpotlightState extends State<_Spotlight> {
    static const double _padding = 8;
    static const double _minCardRoom = 220; // Space the card needs beside its target
    Rect? _hole; // Target's bounds in this overlay's coordinates; null = no target, center the card

    @override
    void initState() {
        super.initState();
        _measureAfterLayout();
    }

    @override
    void didUpdateWidget(_Spotlight old) {
        super.didUpdateWidget(old);
        if (old.step != widget.step) _measureAfterLayout();
    }

    // The target is laid out by the screen underneath, so measure after this frame.
    void _measureAfterLayout() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final BuildContext? targetContext = TutorialManager.targetKey(widget.step.targetId).currentContext;
            final RenderObject? target = targetContext?.findRenderObject();
            final RenderObject? overlay = context.findRenderObject();
            Rect? hole;
            if (target is RenderBox && target.hasSize && target.attached && overlay is RenderBox) {
                // The target is beside the overlay, not inside it, so compare global
                // positions (which also cancels a route transition's slide).
                final Offset topLeft = target.localToGlobal(Offset.zero) - overlay.localToGlobal(Offset.zero);
                hole = (topLeft & target.size).inflate(_padding);
            }
            setState(() => _hole = hole);
        });
    }

    // Next: advance, and open the next screen if this step leads to one. From a
    // screen other than home the next one replaces it, so Back still returns home.
    Future<void> _next() async {
        final TutorialScreen? next = widget.step.nextScreen;
        final NavigatorState navigator = Navigator.of(context);
        await widget.state.advanceTutorial();
        if (next == null || next == TutorialScreen.home) return;
        final MaterialPageRoute<void> route = MaterialPageRoute(builder: (_) => screenFor(next, widget.state));
        if (widget.step.screen == TutorialScreen.home) {
            navigator.push(route);
        } else {
            navigator.pushReplacement(route);
        }
    }

    @override
    Widget build(BuildContext context) {
        final bool last = widget.state.data.tutorialStep >= TutorialManager.steps.length - 1;
        return LayoutBuilder(builder: (context, constraints) {
            final Rect? hole = _hole;
            final double height = constraints.maxHeight;
            // Card on whichever side of the target has more room; over the bottom of
            // a target that leaves room on neither side (a whole-screen list).
            final double roomAbove = hole == null ? 0 : hole.top;
            final double roomBelow = hole == null ? 0 : height - hole.bottom;
            final bool fitsBeside = roomAbove >= _minCardRoom || roomBelow >= _minCardRoom;
            final bool cardBelow = roomBelow >= roomAbove;
            final Widget card = Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(widget.step.title, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(widget.step.message),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                    TextButton(onPressed: widget.state.skipTutorial, child: const Text("Skip")),
                                    FilledButton(onPressed: _next, child: Text(last ? "Done" : "Next")),
                                ],
                            ),
                        ],
                    ),
                ),
            );
            return Stack(children: [
                // Dim everything except the spotlight; block touches outside the card.
                Positioned.fill(
                    child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: CustomPaint(painter: _DimPainter(hole)),
                    ),
                ),
                if (hole == null)
                    Center(child: card)
                else if (!fitsBeside)
                    Positioned(left: 0, right: 0, bottom: 16, child: card)
                else if (cardBelow)
                    Positioned(left: 0, right: 0, top: hole.bottom + 16, child: card)
                else
                    Positioned(left: 0, right: 0, bottom: height - hole.top + 16, child: card),
            ]);
        });
    }
}

// Paints the dim layer with a rounded transparent hole over the target.
class _DimPainter extends CustomPainter {
    final Rect? hole;
    _DimPainter(this.hole);

    @override
    void paint(Canvas canvas, Size size) {
        final Path dim = Path()..addRect(Offset.zero & size);
        final Rect? h = hole;
        final Path path = h == null
            ? dim
            : Path.combine(PathOperation.difference, dim,
                Path()..addRRect(RRect.fromRectAndRadius(h, const Radius.circular(12))));
        canvas.drawPath(path, Paint()..color = const Color.fromARGB(185, 0, 0, 0));
    }

    @override
    bool shouldRepaint(_DimPainter old) => old.hole != hole;
}
