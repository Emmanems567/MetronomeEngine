#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
#include <iostream>

struct MetronomeState {
  int sampleRate;
  int samplesPerBeat;
  float* tickBuffer;
  int tickFrames;
  float* tockBuffer;
  int tockFrames;
  int* measureSequence;
  int sequenceLength;
  int currentMeasureIndex;
  int beatsPerMeasure;
  int currentBeat;
  int currentSample;
};

float* load_wav(const char* filepath, int targetSampleRate, int* outFrames) {

  ma_decoder_config config = ma_decoder_config_init(ma_format_f32, 2, targetSampleRate);
  ma_decoder decoder;

  if (ma_decoder_init_file(filepath, &config, &decoder) != MA_SUCCESS) {
    std::cerr << "Error: Couldn't load WAV" << filepath << std::endl;
    return nullptr;
  }

  ma_uint64 totalFrames;
  ma_decoder_get_length_in_pcm_frames(&decoder, &totalFrames);

  float* buffer = new float[totalFrames * 2];

  ma_decoder_read_pcm_frames(&decoder, buffer, totalFrames, NULL);
  ma_decoder_uninit(&decoder);

  *outFrames = (int)totalFrames;

  return buffer;

}

void data_callback(ma_device* pDevice, void* pOutput, const void* pInput,
                   ma_uint32 frameCount) {

  MetronomeState* state = (MetronomeState*)pDevice->pUserData;
  float* out = (float*)pOutput;

  for (ma_uint32 i = 0; i < frameCount; i++) {
    float sampleL = 0.0f;
    float sampleR = 0.0f;

    float* activeBuffer = (state->currentBeat == 0) ? state->tickBuffer : state->tockBuffer;
    int activeFrames = (state->currentBeat == 0) ? state->tickFrames : state->tockFrames;

    if (activeBuffer != nullptr && state->currentSample < activeFrames) {
      sampleL = activeBuffer[state->currentSample * 2];
      sampleR = activeBuffer[state->currentSample * 2 + 1];
    }

    out[i * 2] = sampleL;
    out[i * 2 + 1] = sampleR;

    state->currentSample++;

    if (state->currentSample >= state->samplesPerBeat) {
      state->currentSample = 0;
      state->currentBeat++;

      if (state->currentBeat >= state->beatsPerMeasure) {
        state->currentBeat = 0;
        state->currentMeasureIndex++;

        if (state->currentMeasureIndex >= state->sequenceLength) {
          state->currentMeasureIndex = 0;
        }

        state->beatsPerMeasure = state->measureSequence[state->currentMeasureIndex];
      }
    }
  }
}

int main() {

  int score[] = {5, 7};

  MetronomeState state;
  state.measureSequence = score;
  state.sequenceLength = 2;
  state.currentMeasureIndex = 0;
  state.beatsPerMeasure = score[0];
  state.sampleRate = 48000;
  state.currentSample = 0;
  double beatsPerSecond = 120.0 / 60.0;
  state.currentBeat = 0;
  state.samplesPerBeat = (int)(state.sampleRate / beatsPerSecond);

  std::cout << "Loading sounds..." << std::endl;
  state.tickBuffer = load_wav("sounds/tick.wav", state.sampleRate, &state.tickFrames);
  state.tockBuffer = load_wav("sounds/tock.wav", state.sampleRate, &state.tockFrames);

  if (state.tickBuffer == nullptr || state.tockBuffer == nullptr) {
    std::cerr << "Make sure to have tick.wav and tock.wav in the 'sounds' folder." << std::endl;
    return -1;
  }

  ma_device_config config = ma_device_config_init(ma_device_type_playback);
  config.playback.format = ma_format_f32;
  config.playback.channels = 2;
  config.sampleRate = state.sampleRate;
  config.dataCallback = data_callback;
  config.pUserData = &state;
  ma_device device;

  if (ma_device_init(NULL, &config, &device) != MA_SUCCESS) {
    std::cerr << "Audio device inicialization error" << std::endl;
    return -1;
  }

  ma_device_start(&device);

  std::cout << "Audio engine running on background..." << std::endl;
  std::cout << "Press ENTER to exit." << std::endl;

  getchar();

  ma_device_uninit(&device);

  delete[] state.tickBuffer;
  delete[] state.tockBuffer;
  return 0;
}
