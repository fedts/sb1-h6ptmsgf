import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';

interface Emergency {
  id: string;
  userName: string;
  timestamp: string;
  type?: string;
  latitude: number;
  longitude: number;
}

interface EmergencyState {
  loading: boolean;
  currentUser: {
    id: string;
    name: string;
    email: string;
    company_id: string | null;
  } | null;
  currentEmergency: Emergency | null;
  showEmergencyModal: boolean;
  isEmergencyFetchingPaused: boolean;
  pendingAlerts: Emergency[];
  processingAlerts: boolean;
  showNextAlert: () => void;
  fetchCurrentUser: () => Promise<void>;
  simulateEmergency: (latitude: number, longitude: number) => Promise<void>;
  setCurrentEmergency: (emergency: Emergency | null) => void;
  setShowEmergencyModal: (show: boolean) => void;
  markEmergencyAsReceived: (id: string) => Promise<void>;
  fetchEmergencys: () => Promise<void>;
}

export const useEmergencyStore = create<EmergencyState>((set, get) => ({
  loading: false,
  currentUser: null,
  currentEmergency: null,
  showEmergencyModal: false,
  isEmergencyFetchingPaused: true,
  pendingAlerts: [],
  processingAlerts: false,

  setShowEmergencyModal: (show) => {
    set({ showEmergencyModal: show });

    // If modal is being closed, process next alert or resume fetching
    if (!show) {
      const { pendingAlerts, currentEmergency } = get();

      // Mark current emergency as processed if it exists
      if (currentEmergency) {
        get().markEmergencyAsReceived(currentEmergency.id);
      }

      // Check if there are more alerts to process
      if (pendingAlerts.length > 0) {
        // Process the next alert
        get().showNextAlert();
      } else {
        // No more alerts to process, resume fetching
        set({
          isEmergencyFetchingPaused: false,
          processingAlerts: false
        });
      }
    }
  },

  showNextAlert: () => {
    const { pendingAlerts } = get();

    if (pendingAlerts.length === 0) {
      // No more alerts to process
      set({
        currentEmergency: null,
        isEmergencyFetchingPaused: false,
        processingAlerts: false
      });
      return;
    }

    // Get the next alert and remove it from the queue
    const nextAlert = pendingAlerts[0];
    const updatedPendingAlerts = pendingAlerts.slice(1);

    // Show the alert
    set({
      pendingAlerts: updatedPendingAlerts,
      currentEmergency: {
        id: nextAlert.id,
        userName: nextAlert.userName,
        timestamp: nextAlert.timestamp,
        type: 'Test Emergency',
        latitude: nextAlert.latitude,
        longitude: nextAlert.longitude
      },
      showEmergencyModal: true,
      isEmergencyFetchingPaused: true
    });
  },

  fetchCurrentUser: async () => {
    try {

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        set({ currentUser: null });
        return;
      }

      const { data, error } = await supabase
        .from('users')
        .select('id, name, email, company_id')
        .eq('uid', user.id)
        .single();

      if (error) throw error;

      if (!data) {
        set({ currentUser: null });
        return;
      }

      console.log('Current user data:', data);
      set({ currentUser: data, isEmergencyFetchingPaused: false });


    } catch (error) {
      console.error('Error fetching current user:', error);
      toast.error('Error fetching user data');
    }
  },

  simulateEmergency: async (latitude: number, longitude: number) => {
    const { currentUser } = get();
    if (!currentUser) {
      toast.error('User data not available');
      return;
    }

    set({ loading: true });

    try {
      const { data: alert, error: alertError } = await supabase
        .from('alerts')
        .insert([{
          user_id: currentUser.id,
          user_name: currentUser.name,
          email: currentUser.email,
          company_id: currentUser.company_id,
          current_location: `${longitude} ${latitude}`,
          address: 'Test Location, Milan',
          received: false,
          timestamp: new Date().toISOString()
        }])
        .select()
        .single();

      if (alertError) throw alertError;

      // Set current emergency
      const emergency: Emergency = {
        id: alert.id,
        userName: currentUser.name,
        timestamp: new Date().toISOString(),
        type: 'Test Emergency',
        latitude,
        longitude
      };

      set({
        currentEmergency: emergency,
        showEmergencyModal: true
      });

    } catch (error) {
      console.error('Error simulating emergency:', error);
      toast.error('Errore durante la simulazione dell\'emergenza');
    } finally {
      set({ loading: false });
    }
  },

  setCurrentEmergency: (emergency) => {
    set({ currentEmergency: emergency });
  },

  // setShowEmergencyModal: (show) => {
  //   //set({ showEmergencyModal: show });
  //   set({ showEmergencyModal: show });
  //   // If modal is being closed, resume fetching
  //   if (!show) {
  //     set({ isEmergencyFetchingPaused: false });
  //   }
  // },

  markEmergencyAsReceived: async (id) => {
    try {
      const { error } = await supabase
        .from('alerts')
        .update({ received: true })
        .eq('id', id);

      if (error) throw error;
    } catch (error) {
      console.error('Error marking emergency as received:', error);
      toast.error('Errore durante l\'aggiornamento dell\'emergenza');
    }
  },

  // fetchEmergencys: async () => {
  //   console.log('Fetching emergencies...');

  //   const { currentUser, isEmergencyFetchingPaused } = get();

  //   if (isEmergencyFetchingPaused) {
  //     console.log('Emergency fetching is paused');
  //     return;
  //   }

  //   if (!currentUser) {
  //     toast.error('EMERGENCIES --> User data not available');
  //     return;
  //   }

  //   try {
  //     const { data, error } = await supabase
  //       .from('alerts')
  //       .select('*')
  //       .eq('user_id', currentUser.id)
  //       .eq('received', false)
  //       .order('timestamp', { ascending: false });

  //     if (error) throw error;

  //     if (data.length > 0) {
  //       console.log('New emergency found:', data[0]);

  //       data.forEach(element => {


  //         console.log('Processing emergency:', element);
  //       });

  //       set({
  //         currentEmergency: {
  //           id: data[0].id,
  //           userName: data[0].user_name,
  //           timestamp: data[0].timestamp,
  //           type: 'Test Emergency',
  //           latitude: parseFloat(data[0].current_location.split(' ')[1]),
  //           longitude: parseFloat(data[0].current_location.split(' ')[0])
  //         },
  //         isEmergencyFetchingPaused: true,
  //         showEmergencyModal: true,
  //       });


  //     }

  //   } catch (error) {
  //     console.error('Error fetching emergency:', error);
  //     toast.error('Errore durante il recupero dell\'emergenza');
  //   }
  // }
  fetchEmergencys: async () => {
    console.log('Fetching emergencies...');

    const { currentUser, isEmergencyFetchingPaused, processingAlerts } = get();

    if (isEmergencyFetchingPaused || processingAlerts) {
      console.log('Emergency fetching is paused or alerts are being processed');
      return;
    }

    if (!currentUser) {
      toast.error('EMERGENCIES --> User data not available');
      return;
    }

    try {
      const { data, error } = await supabase
        .from('alerts')
        .select('*')
        .eq('user_id', currentUser.id)
        .eq('received', false)
        .order('timestamp', { ascending: false });

      if (error) throw error;

      if (data && data.length > 0) {
        console.log(`Found ${data.length} unacknowledged alerts`);

        // Store all alerts and start processing them

        const alertsToProcess = data.map((alert) => ({
          id: alert.id,
          userName: alert.user_name,
          timestamp: alert.timestamp,
          type: 'Test Emergency',
          latitude: parseFloat(alert.current_location.split(' ')[1]),
          longitude: parseFloat(alert.current_location.split(' ')[0])
        }));

        console.log('Processing emergencies:', alertsToProcess);

        set({
          pendingAlerts: alertsToProcess,
          processingAlerts: true,
          isEmergencyFetchingPaused: true
        });

        // Show the first alert
        get().showNextAlert();
      }
    } catch (error) {
      console.error('Error fetching emergencies:', error);
      toast.error('Errore durante il recupero delle emergenze');
    }
  }
}));