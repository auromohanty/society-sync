import { PlaceholderScreen } from '../../components/PlaceholderScreen';
import { useActiveSociety } from '../../context/ActiveSocietyContext';

export function TreasurerDashboardScreen() {
  const { society } = useActiveSociety();
  const societyName = society?.name ?? 'your society';

  return (
    <PlaceholderScreen
      title="Treasurer dashboard"
      subtitle={`Collected vs outstanding, defaulters, and PDF receipts for ${societyName} will live here.`}
    />
  );
}
