import React, { useRef } from 'react';
import { Button, Text, StyleSheet, View } from 'react-native';

import { BottomSheet } from 'expo-bottom-sheet';

export default function App() {
  const sheet = useRef<BottomSheet>(null)
  const present = async () => {
    await sheet.current?.presentAsync()
  }
  
  return (
    <View style={styles.container}>
      <Button title='Present' onPress={present} />
      <BottomSheet ref={sheet} name="Hello">
        <View><Text>Hello World! 👋</Text></View>
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
