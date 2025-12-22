import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class BriefingAvatar extends StatefulWidget {
  final bool isTalking;

  const BriefingAvatar({super.key, required this.isTalking});

  @override
  State<BriefingAvatar> createState() => _BriefingAvatarState();
}

class _BriefingAvatarState extends State<BriefingAvatar> {
  SMINumber? _headBob;
  SMINumber? _armFloat;

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
    if (controller != null) {
      artboard.addController(controller);
      _headBob = controller.findInput<double>('HeadBobAmount') as SMINumber?;
      _armFloat = controller.findInput<double>('ArmFloatAmount') as SMINumber?;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_headBob != null) _headBob!.value = widget.isTalking ? 100.0 : 10.0;
    if (_armFloat != null) _armFloat!.value = widget.isTalking ? 80.0 : 30.0;

    return Center(
      child: SizedBox(
        height: 180, 
        width: 180,
        child: RiveAnimation.asset(
          'assets/rive/robot_agent.riv',
          onInit: _onRiveInit,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}