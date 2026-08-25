import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'feedback_cue.dart';
import 'feedback_sound_spec.dart';

Future<void> playFeedbackCue(FeedbackCue cue) async {
  try {
    final constructor =
        globalContext['AudioContext'] ?? globalContext['webkitAudioContext'];
    if (constructor == null || !constructor.isA<JSFunction>()) return;

    final context = (constructor as JSFunction).callAsConstructor<JSObject>();
    await _awaitPromise(context.callMethodVarArgs<JSAny?>('resume'.toJS));
    final destination = context['destination'];
    if (destination == null || !destination.isA<JSObject>()) {
      await _close(context);
      return;
    }

    final currentTime = context['currentTime'];
    final now = currentTime?.isA<JSNumber>() == true
        ? (currentTime as JSNumber).toDartDouble
        : 0.0;
    var cursor = now;
    for (final tone in feedbackTonesFor(cue)) {
      if (!_scheduleTone(
        context: context,
        destination: destination as JSObject,
        tone: tone,
        startTime: cursor,
      )) {
        await _close(context);
        return;
      }
      cursor +=
          (tone.milliseconds + tone.gapAfterMilliseconds).toDouble() / 1000;
    }

    await Future<void>.delayed(
      Duration(milliseconds: feedbackPatternDurationMilliseconds(cue) + 45),
    );
    await _close(context);
  } catch (_) {
    // 브라우저 자동 재생 정책이나 지원 여부로 실패해도 플레이는 계속한다.
  }
}

bool _scheduleTone({
  required JSObject context,
  required JSObject destination,
  required FeedbackTone tone,
  required double startTime,
}) {
  final oscillator = context.callMethodVarArgs<JSAny?>('createOscillator'.toJS);
  final gain = context.callMethodVarArgs<JSAny?>('createGain'.toJS);
  if (oscillator == null ||
      !oscillator.isA<JSObject>() ||
      gain == null ||
      !gain.isA<JSObject>()) {
    return false;
  }

  final oscillatorObject = oscillator as JSObject;
  final gainObject = gain as JSObject;
  oscillatorObject['type'] = tone.wave.name.toJS;
  final frequency = oscillatorObject['frequency'];
  final gainParam = gainObject['gain'];
  if (frequency == null ||
      !frequency.isA<JSObject>() ||
      gainParam == null ||
      !gainParam.isA<JSObject>()) {
    return false;
  }

  final frequencyObject = frequency as JSObject;
  final gainParamObject = gainParam as JSObject;
  final endTime = startTime + tone.milliseconds / 1000;
  frequencyObject.callMethodVarArgs<JSAny?>('setValueAtTime'.toJS, [
    tone.frequency.toJS,
    startTime.toJS,
  ]);
  gainParamObject.callMethodVarArgs<JSAny?>('setValueAtTime'.toJS, [
    0.0001.toJS,
    startTime.toJS,
  ]);
  gainParamObject.callMethodVarArgs<JSAny?>(
    'exponentialRampToValueAtTime'.toJS,
    [tone.volume.toJS, (startTime + 0.008).toJS],
  );
  gainParamObject.callMethodVarArgs<JSAny?>(
    'exponentialRampToValueAtTime'.toJS,
    [0.0001.toJS, endTime.toJS],
  );
  oscillatorObject.callMethodVarArgs<JSAny?>('connect'.toJS, [gainObject]);
  gainObject.callMethodVarArgs<JSAny?>('connect'.toJS, [destination]);
  oscillatorObject.callMethodVarArgs<JSAny?>('start'.toJS, [startTime.toJS]);
  oscillatorObject.callMethodVarArgs<JSAny?>('stop'.toJS, [
    (endTime + 0.02).toJS,
  ]);
  return true;
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
