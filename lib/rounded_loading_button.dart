library rounded_loading_button;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

/// States that your button can assume via the controller
// ignore: public_member_api_docs
enum ButtonState { idle, loading, success, error }

/// Initalize class
class RoundedLoadingButton extends StatefulWidget {
  /// Button controller, now required
  final RoundedLoadingButtonController controller;

  /// The callback that is called when
  /// the button is tapped or otherwise activated.
  final VoidCallback? onPressed;

  /// The button's label
  final Widget child;

  /// The primary color of the button
  final Color? color;

  /// The vertical extent of the button.
  final double height;

  /// The horiztonal extent of the button.
  final double width;

  /// The size of the CircularProgressIndicator
  final double loaderSize;

  /// The stroke width of the CircularProgressIndicator
  final double loaderStrokeWidth;

  /// Whether to trigger the animation on the tap event
  final bool animateOnTap;

  /// The color of the static icons
  final Color valueColor;

  /// reset the animation after specified duration,
  /// use resetDuration parameter to set Duration, defaults to 15 seconds
  final bool resetAfterDuration;

  /// The curve of the shrink animation
  final Curve curve;

  /// The radius of the button border
  final double borderRadius;

  /// The duration of the button animation
  final Duration duration;

  /// The elevation of the raised button
  final double elevation;

  /// Duration after which reset the button
  final Duration resetDuration;

  /// The color of the button when it is in the error state
  final Color? errorColor;

  /// The color of the button when it is in the success state
  final Color? successColor;

  /// The color of the button when it is disabled
  final Color? disabledColor;

  /// The icon for the success state
  final IconData successIcon;

  /// The icon for the failed state
  final IconData failedIcon;

  /// The success and failed animation curve
  final Curve completionCurve;

  /// The duration of the success and failed animation
  final Duration completionDuration;

  /// A shadow to be drawn behind the button, if is set, the [onPressed]
  /// callback will trigger until tap up
  final ElevationShadow? shadow;

  Duration get _borderDuration {
    return Duration(milliseconds: (duration.inMilliseconds / 2).round());
  }

  /// initalize constructor
  const RoundedLoadingButton({
    Key? key,
    required this.controller,
    required this.onPressed,
    required this.child,
    this.color = Colors.lightBlue,
    this.height = 50,
    this.width = 300,
    this.loaderSize = 24.0,
    this.loaderStrokeWidth = 2.0,
    this.animateOnTap = true,
    this.valueColor = Colors.white,
    this.borderRadius = 35,
    this.elevation = 2,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOutCirc,
    this.errorColor = Colors.red,
    this.successColor,
    this.resetDuration = const Duration(seconds: 15),
    this.resetAfterDuration = false,
    this.successIcon = Icons.check,
    this.failedIcon = Icons.close,
    this.completionCurve = Curves.elasticOut,
    this.completionDuration = const Duration(milliseconds: 1000),
    this.disabledColor,
    this.shadow,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoundedLoadingButtonState();
}

/// Class implementation
class RoundedLoadingButtonState extends State<RoundedLoadingButton>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late AnimationController _borderController;
  late AnimationController _checkButtonControler;

  late Animation _squeezeAnimation;
  late Animation _bounceAnimation;
  late Animation _borderAnimation;

  final _state = BehaviorSubject<ButtonState>.seeded(ButtonState.idle);
  final _elevationState =
      BehaviorSubject<ElevationState>.seeded(ElevationState.up);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget _check = Container(
      alignment: FractionalOffset.center,
      decoration: BoxDecoration(
        color: widget.successColor ?? theme.primaryColor,
        borderRadius:
            BorderRadius.all(Radius.circular(_bounceAnimation.value / 2)),
      ),
      width: _bounceAnimation.value,
      height: _bounceAnimation.value,
      child: _bounceAnimation.value > 20
          ? Icon(
              widget.successIcon,
              color: widget.valueColor,
            )
          : null,
    );

    Widget _cross = Container(
      alignment: FractionalOffset.center,
      decoration: BoxDecoration(
        color: widget.errorColor,
        borderRadius:
            BorderRadius.all(Radius.circular(_bounceAnimation.value / 2)),
      ),
      width: _bounceAnimation.value,
      height: _bounceAnimation.value,
      child: _bounceAnimation.value > 20
          ? Icon(
              widget.failedIcon,
              color: widget.valueColor,
            )
          : null,
    );

    Widget _loader = SizedBox(
      height: widget.loaderSize,
      width: widget.loaderSize,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor),
        strokeWidth: widget.loaderStrokeWidth,
      ),
    );

    Widget childStream = StreamBuilder(
      stream: _state,
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: snapshot.data == ButtonState.loading ? _loader : widget.child,
        );
      },
    );

    final btn = widget.shadow != null
        ? _buildButtonWithShadow(childStream, widget.shadow!)
        : _buildButtonWithoutShadow(childStream);

    return SizedBox(
      height: widget.height,
      child: Center(
        child: _state.value == ButtonState.error
            ? _cross
            : _state.value == ButtonState.success
                ? _check
                : btn,
      ),
    );
  }

  Widget _buildButtonWithoutShadow(Widget child) {
    return ButtonTheme(
      shape: RoundedRectangleBorder(borderRadius: _borderAnimation.value),
      disabledColor: widget.disabledColor,
      padding: const EdgeInsets.all(0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          onSurface: widget.disabledColor,
          minimumSize: Size(_squeezeAnimation.value, widget.height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          primary: widget.color,
          elevation: widget.elevation,
          padding: const EdgeInsets.all(0),
        ),
        onPressed: widget.onPressed == null ? null : _btnPressed,
        child: child,
      ),
    );
  }

  Widget _buildButtonWithShadow(Widget child, ElevationShadow shadow) {
    final isDisabled = widget.onPressed == null;
    return StreamBuilder(
      stream: _elevationState,
      builder: (context, snapshot) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: _squeezeAnimation.value,
            minHeight: widget.height,
          ),
          child: GestureDetector(
            child: Container(
              height: widget.height,
              transform: _elevationState.value == ElevationState.down &&
                      _state.value == ButtonState.idle
                  ? Transform.translate(offset: shadow.upOffset).transform
                  : null,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  color: isDisabled ? widget.disabledColor : widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      offset: shadow.downOffset,
                      blurRadius: shadow.blurRadius,
                    ),
                    if (_elevationState.value == ElevationState.up &&
                        _state.value == ButtonState.idle)
                      BoxShadow(
                        color: shadow.color,
                        offset: shadow.upOffset,
                      ),
                  ]),
              child: child,
            ),
            onTapDown: (details) {
              _elevationState.add(ElevationState.down);
            },
            onTapUp: (details) {
              _elevationState.add(ElevationState.up);
              widget.onPressed == null ? null : _btnPressed();
            },
            onTapCancel: () {
              _elevationState.add(ElevationState.up);
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _buttonController =
        AnimationController(duration: widget.duration, vsync: this);

    _checkButtonControler =
        AnimationController(duration: widget.completionDuration, vsync: this);

    _borderController =
        AnimationController(duration: widget._borderDuration, vsync: this);

    _bounceAnimation = Tween<double>(begin: 0, end: widget.height).animate(
      CurvedAnimation(
        parent: _checkButtonControler,
        curve: widget.completionCurve,
      ),
    );
    _bounceAnimation.addListener(() {
      setState(() {});
    });

    _squeezeAnimation =
        Tween<double>(begin: widget.width, end: widget.height).animate(
      CurvedAnimation(parent: _buttonController, curve: widget.curve),
    );

    _squeezeAnimation.addListener(() {
      setState(() {});
    });

    _squeezeAnimation.addStatusListener((state) {
      if (state == AnimationStatus.completed && widget.animateOnTap) {
        if (widget.onPressed != null) {
          widget.onPressed!();
        }
      }
    });

    _borderAnimation = BorderRadiusTween(
      begin: BorderRadius.circular(widget.borderRadius),
      end: BorderRadius.circular(widget.height),
    ).animate(_borderController);

    _borderAnimation.addListener(() {
      setState(() {});
    });

    // There is probably a better way of doing this...
    _state.stream.listen((event) {
      if (!mounted) return;
      widget.controller._state.sink.add(event);
    });

    widget.controller._addListeners(_start, _stop, _success, _error, _reset);
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _checkButtonControler.dispose();
    _borderController.dispose();
    _state.close();
    super.dispose();
  }

  void _btnPressed() async {
    if (widget.animateOnTap) {
      _start();
    } else {
      if (widget.onPressed != null) {
        widget.onPressed!();
      }
    }
  }

  void _start() {
    if (!mounted) return;
    _state.sink.add(ButtonState.loading);
    _borderController.forward();
    _buttonController.forward();
    if (widget.resetAfterDuration) _reset();
  }

  void _stop() {
    if (!mounted) return;
    _state.sink.add(ButtonState.idle);
    _buttonController.reverse();
    _borderController.reverse();
  }

  void _success() {
    if (!mounted) return;
    _state.sink.add(ButtonState.success);
    _checkButtonControler.forward();
  }

  void _error() {
    if (!mounted) return;
    _state.sink.add(ButtonState.error);
    _checkButtonControler.forward();
  }

  void _reset() async {
    if (widget.resetAfterDuration) await Future.delayed(widget.resetDuration);
    if (!mounted) return;
    _state.sink.add(ButtonState.idle);
    unawaited(_buttonController.reverse());
    unawaited(_borderController.reverse());
    _checkButtonControler.reset();
  }
}

/// Options that can be chosen by the controller
/// each will perform a unique animation
class RoundedLoadingButtonController {
  VoidCallback? _startListener;
  VoidCallback? _stopListener;
  VoidCallback? _successListener;
  VoidCallback? _errorListener;
  VoidCallback? _resetListener;

  void _addListeners(
    VoidCallback startListener,
    VoidCallback stopListener,
    VoidCallback successListener,
    VoidCallback errorListener,
    VoidCallback resetListener,
  ) {
    _startListener = startListener;
    _stopListener = stopListener;
    _successListener = successListener;
    _errorListener = errorListener;
    _resetListener = resetListener;
  }

  final BehaviorSubject<ButtonState> _state =
      BehaviorSubject<ButtonState>.seeded(ButtonState.idle);

  /// A read-only stream of the button state
  Stream<ButtonState> get stateStream => _state.stream;

  /// Gets the current state
  ButtonState? get currentState => _state.value;

  /// Notify listeners to start the loading animation
  void start() {
    if (_startListener != null) _startListener!();
  }

  /// Notify listeners to start the stop animation
  void stop() {
    if (_stopListener != null) _stopListener!();
  }

  /// Notify listeners to start the sucess animation
  void success() {
    if (_successListener != null) _successListener!();
  }

  /// Notify listeners to start the error animation
  void error() {
    if (_errorListener != null) _errorListener!();
  }

  /// Notify listeners to start the reset animation
  void reset() {
    if (_resetListener != null) _resetListener!();
  }
}

/// The state of the button when elevation state is set
enum ElevationState {
  /// When the button is not pressed and showing the up shadow
  up,

  /// When the button is pressed and showing the down shadow
  down,
}

/// The shadow of the button
class ElevationShadow {
  /// The shadow color
  final Color color;

  /// The shadow offset when the button is not pressed
  final Offset upOffset;

  /// The shadow offset when the button is pressed
  final Offset downOffset;

  /// The shadow elevation when the button is disabled
  final double blurRadius;

  /// Shadow that will be shown when the button is not pressed
  const ElevationShadow({
    this.color = Colors.black,
    this.upOffset = const Offset(1, 4),
    this.downOffset = const Offset(1, 0),
    this.blurRadius = 2,
  });
}
