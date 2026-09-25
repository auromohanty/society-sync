import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { ActivityIndicator, View } from 'react-native';
import { useAuth } from '../context/AuthContext';
import { useRoleHomeScreen } from '../hooks/useRoleHomeScreen';
import { SignInScreen } from '../screens/auth/SignInScreen';
import { TreasurerDashboardScreen } from '../screens/admin/TreasurerDashboardScreen';
import { ResidentHomeScreen } from '../screens/resident/ResidentHomeScreen';
import { PreApproveGuestScreen } from '../screens/resident/PreApproveGuestScreen';
import { GuardGateScreen } from '../screens/security/GuardGateScreen';

export type RootStackParamList = {
  SignIn: undefined;
  TreasurerDashboard: undefined;
  ResidentHome: undefined;
  PreApproveGuest: undefined;
  GuardGate: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

function RoleBasedStacks() {
  const home = useRoleHomeScreen();

  if (home === 'auth') {
    return (
      <Stack.Navigator>
        <Stack.Screen name="SignIn" component={SignInScreen} options={{ title: 'Sign in' }} />
      </Stack.Navigator>
    );
  }

  if (home === 'admin') {
    return (
      <Stack.Navigator>
        <Stack.Screen
          name="TreasurerDashboard"
          component={TreasurerDashboardScreen}
          options={{ title: 'Treasurer' }}
        />
      </Stack.Navigator>
    );
  }

  if (home === 'resident') {
    return (
      <Stack.Navigator>
        <Stack.Screen
          name="ResidentHome"
          component={ResidentHomeScreen}
          options={{ title: 'Home' }}
        />
        <Stack.Screen
          name="PreApproveGuest"
          component={PreApproveGuestScreen}
          options={{ title: 'Pre-approve' }}
        />
      </Stack.Navigator>
    );
  }

  return (
    <Stack.Navigator>
      <Stack.Screen name="GuardGate" component={GuardGateScreen} options={{ title: 'Gate' }} />
    </Stack.Navigator>
  );
}

export function RootNavigator() {
  const { loading } = useAuth();

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <RoleBasedStacks />
    </NavigationContainer>
  );
}
