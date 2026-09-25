import { useState } from 'react';
import { Button, StyleSheet, Text, TextInput, View } from 'react-native';
import { useAuth } from '../../context/AuthContext';

export function SignInScreen() {
  const { signInWithPhone } = useAuth();
  const [phone, setPhone] = useState('');
  const [message, setMessage] = useState<string | null>(null);

  const onSendOtp = async () => {
    try {
      await signInWithPhone(phone);
      setMessage('OTP sent (configure Supabase Auth SMS for production).');
    } catch (e) {
      setMessage(e instanceof Error ? e.message : 'Sign-in failed');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>SocietySync</Text>
      <Text style={styles.subtitle}>Sign in with your registered mobile number</Text>
      <TextInput
        style={styles.input}
        placeholder="+91XXXXXXXXXX"
        keyboardType="phone-pad"
        value={phone}
        onChangeText={setPhone}
        autoComplete="tel"
      />
      <Button title="Send OTP" onPress={onSendOtp} />
      {message ? <Text style={styles.message}>{message}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 24,
    justifyContent: 'center',
    gap: 12,
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: '#0f172a',
  },
  subtitle: {
    fontSize: 15,
    color: '#64748b',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#cbd5e1',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 16,
  },
  message: {
    marginTop: 12,
    color: '#334155',
  },
});
