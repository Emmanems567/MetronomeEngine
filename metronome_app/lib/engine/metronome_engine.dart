import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:flutter/services.dart' show rootBundle, ByteData;

typedef InitMetronomeC = ffi.Void Function();
typedef PlayMetronomeC = ffi.Void Function();
typedef StopMetronomeC = ffi.Void Function();
typedef SetBpmC = ffi.Void Function(ffi.Double bpm);
typedef SetTimeSignatureC = ffi.Void Function(
  ffi.Int32 nuerator,
  ffi.Int32 denominator,
);
typedef SetSequenceC = ffi.Void Function(
  ffi.Pointer<ffi.Int32> data,
  ffi.Int32 numMeasures,
);
typedef LoadSampleC = ffi.Void Function(
  ffi.Int32 type,
  ffi.Pointer<ffi.Uint8> data,
  ffi.Int32 size,
);
typedef InitMetronomeDart = void Function();
typedef PlayMetronomeDart = void Function();
typedef StopMetronomeDart = void Function();
typedef SetBpmDart = void Function(double bpm);
typedef SetTimeSignatureDart = void Function(int numerator, int denominator);
typedef SetSequenceDart = void Function(
  ffi.Pointer<ffi.Int32> data,
  int numMeasures,
);
typedef LoadSampleDart = void Function(
  int type,
  ffi.Pointer<ffi.Uint8> data,
  int size,
);
typedef BeatCallbackC = ffi.Void Function(
  ffi.Int32 currentBeat,
  ffi.Int32 beatsPerMeasure,
  ffi.Int32 isAccent,
);
typedef SetBeatCallbackC = ffi.Void Function(
  ffi.Pointer<ffi.NativeFunction<BeatCallbackC>> callback,
);
typedef SetBeatCallbackDart = void Function(
  ffi.Pointer<ffi.NativeFunction<BeatCallbackC>> callback,
);

class MetronomeEngine {
  late ffi.DynamicLibrary _lib;
  late InitMetronomeDart _initMetronome;
  late PlayMetronomeDart _playMetronome;
  late StopMetronomeDart _stopMetronome;
  late SetBpmDart _setBpm;
  late SetTimeSignatureDart _setTimeSignature;
  late SetSequenceDart _setSequence;
  late LoadSampleDart _loadSample;
  late SetBeatCallbackDart _setBeatCallback;

  ffi.Pointer<ffi.Int32>? _currentSequencePointer;
  ffi.NativeCallable<BeatCallbackC>? _beatCallable;

  MetronomeEngine() {
    if (Platform.isWindows) {
      _lib = ffi.DynamicLibrary.open('metronome_engine.dll');
    } else if (Platform.isAndroid || Platform.isLinux) {
      _lib = ffi.DynamicLibrary.open('libmetronome_engine.so');
    } else {
      throw UnsupportedError('Not supported platform');
    }

    _initMetronome = _lib.lookupFunction<InitMetronomeC, InitMetronomeDart>(
      'init_metronome',
    );
    _playMetronome = _lib.lookupFunction<PlayMetronomeC, PlayMetronomeDart>(
      'play_metronome',
    );
    _stopMetronome = _lib.lookupFunction<StopMetronomeC, StopMetronomeDart>(
      'stop_metronome',
    );
    _setBpm = _lib.lookupFunction<SetBpmC, SetBpmDart>('set_bpm');
    _setTimeSignature = _lib
        .lookupFunction<SetTimeSignatureC, SetTimeSignatureDart>(
          'set_time_signature',
        );
    _setSequence = _lib.lookupFunction<SetSequenceC, SetSequenceDart>(
      'set_sequence',
    );
    _loadSample = _lib.lookupFunction<LoadSampleC, LoadSampleDart>(
      'load_sample_from_memory',
    );
    _setBeatCallback = _lib
        .lookupFunction<SetBeatCallbackC, SetBeatCallbackDart>(
          'set_beat_callback',
        );
  }

  void init() => _initMetronome();
  void play() => _playMetronome();
  void stop() => _stopMetronome();
  void setBpm(double bpm) => _setBpm(bpm);
  void setTimeSignature(int numerator, int denominator) {
    _setTimeSignature(numerator, denominator);
  }

  void setSequence(List<int> sequenceData) {
    if (_currentSequencePointer != null) {
      pkg_ffi.calloc.free(_currentSequencePointer!);
      _currentSequencePointer = null;
    }

    final int totalElements = sequenceData.length;
    final int numMeasures = totalElements ~/ 2;

    if (totalElements == 0) {
      _setSequence(ffi.Pointer<ffi.Int32>.fromAddress(0), 0);
      return;
    }

    _currentSequencePointer = pkg_ffi.calloc<ffi.Int32>(totalElements);

    for (int i = 0; i < totalElements; i++) {
      _currentSequencePointer![i] = sequenceData[i];
    }

    _setSequence(_currentSequencePointer!, numMeasures);
  }

  void setBeatListener(
    void Function(int currentBeat, int beatsPerMeasure, bool isAccent) onBeat,
  ) {
    _beatCallable?.close();

    _beatCallable = ffi.NativeCallable<BeatCallbackC>.listener((
      currentBeat,
      beatsPerMeasure,
      isAccent,
    ) {
      onBeat(currentBeat, beatsPerMeasure, isAccent != 0);
    });

    _setBeatCallback(_beatCallable!.nativeFunction);
  }

  void dispose() {
    _beatCallable?.close();
    if (_currentSequencePointer != null) {
      pkg_ffi.calloc.free(_currentSequencePointer!);
    }
  }

  Future<void> loadSampleFromAsset(int type, String assetPath) async {
    final ByteData byteData = await rootBundle.load(assetPath);
    final int size = byteData.lengthInBytes;

    final ffi.Pointer<ffi.Uint8> nativeBuffer = pkg_ffi.calloc
        .allocate<ffi.Uint8>(size);

    final nativeList = nativeBuffer.asTypedList(size);
    nativeList.setAll(0, byteData.buffer.asUint8List());

    _loadSample(type, nativeBuffer, size);

    pkg_ffi.calloc.free(nativeBuffer);
  }
}
