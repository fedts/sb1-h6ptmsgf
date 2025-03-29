import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { useEmergencyStore } from "../stores/emergency";
import { supabase } from "../lib/supabase";
import toast from "react-hot-toast";

export const GlobalAlertMonitorContext = createContext<
    Emergency[]
    | undefined>(
        [] as Emergency[]
    );

export const useGlobalAlertMonitor = () => {
    const context = useContext(GlobalAlertMonitorContext);
    if (!context) {
        throw new Error('useGlobalAlertMonitor must be used within an GlobalAlertMonitorProvider');
    }
    return context;
};

interface Emergency {
    id: string;
    userName: string;
    timestamp: string;
    type?: string;
    latitude: number;
    longitude: number;
}


export const GlobalAlertMonitorProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {

    // Constants for alert monitoring
    const TWO_MINUTES = 2 * 60 * 1000; // 2 minutes in milliseconds
    const CHECK_INTERVAL = 30 * 1000; // 30 seconds in milliseconds



    // const showNextAlert = useEmergencyStore();
    const [emergencies, setEmergencies] = useState<Emergency[]>([]);
    // const [warningMessages, setWarningMessages] = useState<Emergency[]>([]);
    // const [currentWarningIndex, setCurrentWarningIndex] = useState(0);

    // const fetchEmergencys = useEmergencyStore(state => state.fetchEmergencys);
    // const currentUser = useEmergencyStore(state => state.currentUser);
    const fetchEmergencys = useEmergencyStore(state => state.fetchEmergencys);


    // const fetchEmergencys = async () => {

    //     try {
    //         const { data, error } = await supabase
    //             .from('alerts')
    //             .select('*')
    //             .eq('user_id', currentUser!.id)
    //             .eq('received', false)
    //             .order('timestamp', { ascending: false });

    //         if (error) throw error;

    //         if (data && data.length > 0) {
    //             console.log(`Found ${data.length} unacknowledged alerts`);

    //             // Store all alerts and start processing them

    //             const alertsToProcess = data.map((alert) => ({
    //                 id: alert.id,
    //                 userName: alert.user_name,
    //                 timestamp: alert.timestamp,
    //                 type: 'Test Emergency',
    //                 latitude: parseFloat(alert.current_location.split(' ')[1]),
    //                 longitude: parseFloat(alert.current_location.split(' ')[0])
    //             }));

    //             console.log('Processing emergencies:', alertsToProcess);

    //             useEmergencyStore.getState().setCurrentEmergency(alertsToProcess[0]); // Update the store with processed alerts


    //         }
    //     } catch (error) {
    //         console.error('Error fetching emergencies:', error);
    //         toast.error('Errore durante il recupero delle emergenze');
    //     }
    // }


    const checkRecentAlerts = useCallback(async () => {
        try {
            await fetchEmergencys();
            const now = new Date().getTime();

            // Find all unread alerts that haven't been updated in 2 minutes
            const warnings = emergencies.filter((emergency: Emergency) => {
                if (!emergency.timestamp) {
                    const lastWrittenTime = new Date(emergency.timestamp).getTime();
                    const timeDiff = now - lastWrittenTime;
                    return timeDiff >= TWO_MINUTES;
                }
                return false;
            });

            console.log('Warnings:', warnings);

            // setWarningMessages(warnings);
            // setCurrentWarningIndex(0); // Reset to show the first warning
        } catch (error) {
            console.error('Error checking alerts:', error);
        }
    }, [TWO_MINUTES, emergencies, fetchEmergencys]);

    useEffect(() => {
        // Fetch initial emergencies    
        checkRecentAlerts();

        // Set up periodic alert checking
        const checkInterval = setInterval(checkRecentAlerts, CHECK_INTERVAL);

        // Subscribe to new messages
        const subscription = supabase
            .channel('messages')
            .on(
                'postgres_changes',
                {
                    event: 'INSERT',
                    schema: 'public',
                    table: 'alerts'
                },
                (payload) => { // Moved callback as third argument
                    const newAlert = payload.new as Emergency;
                    setEmergencies((prev) => [newAlert, ...prev]);
                    // Uncomment this line and define warningMessages state to use it
                    // setWarningMessages(prev => [...prev, newAlert]);
                }
            )
            .subscribe();
        return () => {
            clearInterval(checkInterval);
            subscription.unsubscribe();
        };
    }, [checkRecentAlerts]);
    //}, [checkRecentMessages]);

    const value = emergencies;

    return (
        <GlobalAlertMonitorContext.Provider value={value}>
            {children}
        </GlobalAlertMonitorContext.Provider>
    );
};