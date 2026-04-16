import React, { useEffect, useRef } from 'react';
import { View, Animated, Easing, StyleSheet } from 'react-native';

export default function AnimatedSplash() {
  const pulseAnim = useRef(new Animated.Value(1)).current;
  const opacityAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    // 1. Fade-in progressif
    Animated.timing(opacityAnim, {
      toValue: 1,
      duration: 500,
      useNativeDriver: true,
      easing: Easing.inOut(Easing.ease),
    }).start();

    // 2. Pulse (breathing effect) en boucle (durée totale ~1200ms)
    Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1.08,
          duration: 600,
          useNativeDriver: true,
          easing: Easing.inOut(Easing.ease),
        }),
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 600,
          useNativeDriver: true,
          easing: Easing.inOut(Easing.ease),
        }),
      ])
    ).start();
  }, [pulseAnim, opacityAnim]);

  const textOpacity = opacityAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0, 0.6],
  });

  return (
    <View style={styles.container}>
      <Animated.Image
        source={require('../../../assets/logo.png')}
        style={[
          styles.logo,
          {
            opacity: opacityAnim,
            transform: [{ scale: pulseAnim }],
          },
        ]}
        resizeMode="contain"
      />
      <Animated.Text
        style={[
          styles.text,
          {
            opacity: textOpacity,
          },
        ]}
      >
        Chargement...
      </Animated.Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
    justifyContent: 'center',
    alignItems: 'center',
  },
  logo: {
    width: 120,
    height: 120,
    // Ombre légère : iOS
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    // Élévation : Android
    elevation: 5,
  },
  text: {
    marginTop: 16,
    fontFamily: 'PublicSans_400Regular',
    fontSize: 14,
    color: '#333',
  },
});
