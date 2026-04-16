import { View, Text } from 'react-native';
// ✅ LA BONNE MÉTHODE
import { SafeAreaView } from 'react-native-safe-area-context';


export default function DashboardIndex() {
    return (
        <SafeAreaView className="flex-1 bg-white">
            <View className="flex-1 items-center justify-center p-6">
                <View className="bg-blue-100 p-4 rounded-full mb-4">
                    <Text className="text-3xl">🚀</Text>
                </View>
                <Text className="text-2xl font-bold text-gray-900 text-center">
                    Nexus P2P Lending
                </Text>
                <Text className="text-gray-500 text-center mt-2">
                    Le Dashboard est prêt. La redirection après le Splash Screen a fonctionné !
                </Text>
            </View>
        </SafeAreaView>
    );
}