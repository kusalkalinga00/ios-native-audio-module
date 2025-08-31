import { View, Text, TouchableOpacity } from 'react-native';
import React from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import AudioWrapper from '../utils/AudioWrapper';

const Home = () => {
  const initiateAudioModule = async () => {
    await AudioWrapper.initiateAudioModule();
  };

  const handleStartRecording = async () => {
    await initiateAudioModule();
    await AudioWrapper.startRecording();
  };

  const handleStopRecording = async () => {
    await AudioWrapper.stopRecording();
  };

  return (
    <SafeAreaView style={{ flex: 1, padding: 16 }}>
      <View
        style={{
          flexDirection: 'row',
          flex: 1,
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        <View
          style={{
            gap: 40,
          }}
        >
          <TouchableOpacity
            style={{
              backgroundColor: '#8FA31E',
              width: 250,
              height: 50,
              justifyContent: 'center',
              alignItems: 'center',
            }}
          >
            <Text
              style={{
                color: 'white',
                fontSize: 20,
                fontWeight: 'bold',
              }}
            >
              Start Recording
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={{
              backgroundColor: '#556B2F',
              width: 250,
              height: 50,
              justifyContent: 'center',
              alignItems: 'center',
            }}
          >
            <Text
              style={{
                color: 'white',
                fontSize: 20,
                fontWeight: 'bold',
              }}
            >
              Stop Recording
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
};

export default Home;
