import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { ActiveSocietyProvider } from './src/context/ActiveSocietyContext';
import { AuthProvider } from './src/context/AuthContext';
import { RootNavigator } from './src/navigation/RootNavigator';

export default function App() {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <ActiveSocietyProvider>
          <RootNavigator />
          <StatusBar style="auto" />
        </ActiveSocietyProvider>
      </AuthProvider>
    </SafeAreaProvider>
  );
}
