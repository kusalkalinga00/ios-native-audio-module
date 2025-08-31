import { NativeModules, Platform } from 'react-native';
const { AudioRecorderModule } = NativeModules;

interface IAudioRecorderModule {
  start(): Promise<boolean>;
  startRecording(): Promise<string | null>;
  stopRecording(): Promise<string | null>;
  playAudioChunk(base64Audio: string): Promise<boolean>;
  clearQueue(): Promise<boolean>;
}

const typedAudioRecorderModule = AudioRecorderModule as IAudioRecorderModule;

interface IAudioWrapper {
  initiateAudioModule(): Promise<boolean | void>;
  startRecording(): Promise<string | null | void>;
  stopRecording(): Promise<string | null | void>;
  playAudio(base64Audio: string): Promise<boolean | void>;
  stopPlayAudio(): Promise<boolean | void>;
}

const AudioWrapper: IAudioWrapper = {
  initiateAudioModule: async (): Promise<boolean | void> => {
    if (Platform.OS === 'ios') {
      return await typedAudioRecorderModule.start();
    }
  },

  startRecording: async (): Promise<string | null | void> => {
    if (Platform.OS === 'ios') {
      return await typedAudioRecorderModule.startRecording();
    }
  },

  stopRecording: async (): Promise<string | null | void> => {
    if (Platform.OS === 'ios') {
      return typedAudioRecorderModule.stopRecording();
    }
  },

  playAudio: async (base64Audio: string): Promise<boolean | void> => {
    if (Platform.OS === 'ios') {
      return typedAudioRecorderModule.playAudioChunk(base64Audio);
    }
  },

  stopPlayAudio: async (): Promise<boolean | void> => {
    if (Platform.OS === 'ios') {
      return typedAudioRecorderModule.clearQueue();
    }
  },
};

export default AudioWrapper;
