#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#if defined(_WIN32)
#define EXPORT extern "C" __declspec(dllexport)
#else
#define EXPORT extern "C" __attribute__((visibility("default")))
#endif

typedef void (*BeatCallback)(int currentBeat, int beatsPerMeasure,
                             int isAccent);

const double PI = 3.14159265358979323846;

struct MetronomeState {
  int sampleRate;
  int samplesPerBeat;
  int beatsPerMeasure;
  int currentBeat;
  int currentSample;
  double currentBpm;
  int noteValue;
  int *sequenceData = nullptr;
  int sequenceLength = 0;
  int currentMeasureIndex = 0;
  float *tickBuffer;
  int tickFrames;
  float *tockBuffer;
  int tockFrames;
  BeatCallback beatCallback = nullptr;
};

MetronomeState globalState;
ma_device globalDevice;
bool isInitialized = false;

void data_callback(ma_device *pDevice, void *pOutput, const void *pInput,
                   ma_uint32 frameCount) {
  float *out = (float *)pOutput;

  for (ma_uint32 i = 0; i < frameCount; ++i) {
    if (globalState.currentSample == 0 && globalState.beatCallback != nullptr) {
      int isAccent = (globalState.currentBeat == 0) ? 1 : 0;
      globalState.beatCallback(globalState.currentBeat,
                               globalState.beatsPerMeasure, isAccent);
    }

    float sampleL = 0.0f;
    float sampleR = 0.0f;

    float *activeBuffer = (globalState.currentBeat == 0)
                              ? globalState.tickBuffer
                              : globalState.tockBuffer;
    int activeFrames = (globalState.currentBeat == 0) ? globalState.tickFrames
                                                      : globalState.tockFrames;

    if (activeBuffer != nullptr && globalState.currentSample < activeFrames) {
      sampleL = activeBuffer[globalState.currentSample * 2];
      sampleR = activeBuffer[globalState.currentSample * 2 + 1];
    }

    out[i * 2] = sampleL;
    out[i * 2 + 1] = sampleR;

    globalState.currentSample++;

    if (globalState.currentSample >= globalState.samplesPerBeat) {
      globalState.currentSample = 0;
      globalState.currentBeat++;

      if (globalState.currentBeat >= globalState.beatsPerMeasure) {
        globalState.currentBeat = 0;

        if (globalState.sequenceLength > 0 &&
            globalState.sequenceData != nullptr) {
          globalState.currentMeasureIndex++;
          if (globalState.currentMeasureIndex >= globalState.sequenceLength) {
            globalState.currentMeasureIndex = 0;
          }
          int idx = globalState.currentMeasureIndex * 2;
          globalState.beatsPerMeasure = globalState.sequenceData[idx];
          globalState.noteValue = globalState.sequenceData[idx + 1];

          double effectiveBpm =
              globalState.currentBpm * ((double)globalState.noteValue / 4.0);
          globalState.samplesPerBeat =
              (int)(globalState.sampleRate / (effectiveBpm / 60.0));
        }
      }
    }
  }
}

EXPORT void init_metronome() {
  if (isInitialized)
    return;

  globalState.sampleRate = 48000;

  globalState.beatsPerMeasure = 4;
  globalState.noteValue = 4;
  globalState.currentBpm = 120.0;

  globalState.currentBeat = 0;
  globalState.currentSample = 0;

  globalState.samplesPerBeat = (int)(globalState.sampleRate / (120.0 / 60.0));

  globalState.tickBuffer = nullptr;
  globalState.tockBuffer = nullptr;
  globalState.tickFrames = 0;
  globalState.tockFrames = 0;

  ma_device_config config = ma_device_config_init(ma_device_type_playback);
  config.playback.format = ma_format_f32;
  config.playback.channels = 2;
  config.sampleRate = globalState.sampleRate;
  config.dataCallback = data_callback;

  if (ma_device_init(NULL, &config, &globalDevice) == MA_SUCCESS) {
    isInitialized = true;
  }
}

EXPORT void play_metronome() {
  if (isInitialized) {
    globalState.currentBeat = 0;
    globalState.currentSample = 0;
    ma_device_start(&globalDevice);
  }
}

EXPORT void stop_metronome() {
  if (isInitialized) {
    ma_device_stop(&globalDevice);
  }
}

EXPORT void set_bpm(double bpm) {
  globalState.currentBpm = bpm;
  double effectiveBpm = bpm * ((double)globalState.noteValue / 4.0);
  globalState.samplesPerBeat =
      (int)(globalState.sampleRate / (effectiveBpm / 60.0));
}

EXPORT void set_time_signature(int numerator, int denominator) {
  globalState.beatsPerMeasure = numerator;
  globalState.noteValue = denominator;

  if (globalState.currentBpm >= numerator) {
    globalState.currentBeat = 0;
  }

  double effectiveBpm = globalState.currentBpm * ((double)denominator / 4.0);
  globalState.samplesPerBeat =
      (int)(globalState.sampleRate / (effectiveBpm / 60.0));
}

EXPORT void set_sequence(int *data, int num_measures) {
  globalState.sequenceData = data;
  globalState.sequenceLength = num_measures;
  globalState.currentMeasureIndex = 0;

  if (num_measures > 0 && data != nullptr) {
    globalState.beatsPerMeasure = data[0];
    globalState.noteValue = data[1];

    double effectiveBpm = globalState.currentBpm * ((double)data[1] / 4.0);
    globalState.samplesPerBeat =
        (int)(globalState.sampleRate / (effectiveBpm / 60.0));
  }

  globalState.currentBeat = 0;
}

EXPORT void load_sample_from_memory(int type, const void *pData, int dataSize) {
  ma_decoder_config config =
      ma_decoder_config_init(ma_format_f32, 2, globalState.sampleRate);
  ma_decoder decoder;

  if (ma_decoder_init_memory(pData, dataSize, &config, &decoder) !=
      MA_SUCCESS) {
    return;
  }

  ma_uint64 totalFrames;
  ma_decoder_get_length_in_pcm_frames(&decoder, &totalFrames);

  float *newBuffer = new float[totalFrames * 2];
  ma_decoder_read_pcm_frames(&decoder, newBuffer, totalFrames, NULL);
  ma_decoder_uninit(&decoder);

  if (type == 0) {
    if (globalState.tickBuffer != nullptr)
      delete[] globalState.tickBuffer;
    globalState.tickBuffer = newBuffer;
    globalState.tickFrames = (int)totalFrames;
  } else {
    if (globalState.tockBuffer != nullptr)
      delete[] globalState.tockBuffer;
    globalState.tockBuffer = newBuffer;
    globalState.tockFrames = (int)totalFrames;
  }
}

EXPORT void set_beat_callback(BeatCallback callback) {
globalState.beatCallback = callback;
}
