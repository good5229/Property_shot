import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'feedback_cue.dart';

Future<void> playFeedbackCue(FeedbackCue cue) async {
  try {
    final constructor =
        globalContext['AudioContext'] ?? globalContext['webkitAudioContext'];
    if (constructor == null || !constructor.isA<JSFunction>()) {
      return;
    }

    final context = (constructor as JSFunction).callAsConstructor<JSObject>();
    final resume = context.callMethodVarArgs<JSAny?>('resume'.toJS);
    await _awaitPromise(resume);

    final destination = context['destination'];
    if (destination == null || !destination.isA<JSObject>()) {
      await _close(context);
      return;
    }

    final spec = switch (cue) {
      FeedbackCue.ui => (
        frequency: 620.0,
        duration: 0.045,
        volume: 0.045,
        wave: 'sine',
      ),
      FeedbackCue.trait => (
        frequency: 740.0,
        duration: 0.09,
        volume: 0.055,
        wave: 'sine',
      ),
      FeedbackCue.copy => (
        frequency: 880.0,
        duration: 0.14,
        volume: 0.06,
        wave: 'triangle',
      ),
      FeedbackCue.copyCoreAwarded => (
        frequency: 960.0,
        duration: 0.22,
        volume: 0.065,
        wave: 'triangle',
      ),
      FeedbackCue.aimCharge => (
        frequency: 320.0,
        duration: 0.08,
        volume: 0.035,
        wave: 'sine',
      ),
      FeedbackCue.launch => (
        frequency: 190.0,
        duration: 0.11,
        volume: 0.08,
        wave: 'sawtooth',
      ),
      FeedbackCue.lightCollision => (
        frequency: 520.0,
        duration: 0.07,
        volume: 0.05,
        wave: 'triangle',
      ),
      FeedbackCue.heavyCollision => (
        frequency: 110.0,
        duration: 0.16,
        volume: 0.09,
        wave: 'sawtooth',
      ),
      FeedbackCue.bouncyCollision => (
        frequency: 760.0,
        duration: 0.18,
        volume: 0.06,
        wave: 'sine',
      ),
      FeedbackCue.stickyCollision => (
        frequency: 260.0,
        duration: 0.2,
        volume: 0.055,
        wave: 'triangle',
      ),
      FeedbackCue.jellyCollision => (
        frequency: 680.0,
        duration: 0.13,
        volume: 0.06,
        wave: 'sine',
      ),
      FeedbackCue.switchPressed => (
        frequency: 420.0,
        duration: 0.12,
        volume: 0.065,
        wave: 'square',
      ),
      FeedbackCue.gateOpened => (
        frequency: 300.0,
        duration: 0.22,
        volume: 0.07,
        wave: 'sine',
      ),
      FeedbackCue.holeEntered => (
        frequency: 520.0,
        duration: 0.32,
        volume: 0.075,
        wave: 'sine',
      ),
      FeedbackCue.clear => (
        frequency: 660.0,
        duration: 0.28,
        volume: 0.07,
        wave: 'sine',
      ),
      FeedbackCue.medal => (
        frequency: 1040.0,
        duration: 0.2,
        volume: 0.055,
        wave: 'triangle',
      ),
      FeedbackCue.fail => (
        frequency: 180.0,
        duration: 0.16,
        volume: 0.06,
        wave: 'triangle',
      ),
    };

    final oscillator = context.callMethodVarArgs<JSAny?>(
      'createOscillator'.toJS,
    );
    final gain = context.callMethodVarArgs<JSAny?>('createGain'.toJS);
    if (oscillator == null ||
        !oscillator.isA<JSObject>() ||
        gain == null ||
        !gain.isA<JSObject>()) {
      await _close(context);
      return;
    }

    final currentTime = context['currentTime'];
    final now = currentTime?.isA<JSNumber>() == true
        ? (currentTime as JSNumber).toDartDouble
        : 0.0;
    final oscillatorObject = oscillator as JSObject;
    final gainObject = gain as JSObject;
    oscillatorObject['type'] = spec.wave.toJS;
    final frequency = oscillatorObject['frequency'];
    final gainParam = gainObject['gain'];
    if (frequency == null ||
        !frequency.isA<JSObject>() ||
        gainParam == null ||
        !gainParam.isA<JSObject>()) {
      await _close(context);
      return;
    }

    final frequencyObject = frequency as JSObject;
    final gainParamObject = gainParam as JSObject;
    frequencyObject.callMethodVarArgs<JSAny?>('setValueAtTime'.toJS, [
      spec.frequency.toJS,
      now.toJS,
    ]);
    gainParamObject.callMethodVarArgs<JSAny?>('setValueAtTime'.toJS, [
      0.0001.toJS,
      now.toJS,
    ]);
    gainParamObject.callMethodVarArgs<JSAny?>(
      'exponentialRampToValueAtTime'.toJS,
      [spec.volume.toJS, (now + 0.008).toJS],
    );
    gainParamObject.callMethodVarArgs<JSAny?>(
      'exponentialRampToValueAtTime'.toJS,
      [0.0001.toJS, (now + spec.duration).toJS],
    );
    oscillatorObject.callMethodVarArgs<JSAny?>('connect'.toJS, [gainObject]);
    gainObject.callMethodVarArgs<JSAny?>('connect'.toJS, [destination]);
    oscillatorObject.callMethodVarArgs<JSAny?>('start'.toJS, [now.toJS]);
    oscillatorObject.callMethodVarArgs<JSAny?>('stop'.toJS, [
      (now + spec.duration + 0.02).toJS,
    ]);

    await Future<void>.delayed(
      Duration(milliseconds: ((spec.duration + 0.04) * 1000).round()),
    );
    await _close(context);
  } catch (_) {
    // 브라우저 자동 재생 정책이나 지원 여부로 실패해도 플레이는 계속한다.
  }
}

Future<void> _awaitPromise(JSAny? value) async {
  if (value != null && value.isA<JSPromise>()) {
    await (value as JSPromise).toDart;
  }
}

Future<void> _close(JSObject context) async {
  final result = context.callMethodVarArgs<JSAny?>('close'.toJS);
  await _awaitPromise(result);
}
