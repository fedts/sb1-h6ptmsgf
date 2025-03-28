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
  fetchCurrentUser: () => Promise<void>;
  simulateEmergency: (latitude: number, longitude: number) => Promise<void>;
  setCurrentEmergency: (emergency: Emergency | null) => void;
  setShowEmergencyModal: (show: boolean) => void;
  markEmergencyAsReceived: (id: string) => Promise<void>;
}

export const useEmergencyStore = create<EmergencyState>((set, get) => ({
  loading: false,
  currentUser: null,
  currentEmergency: null,
  showEmergencyModal: false,

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
      set({ currentUser: data });
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

  setShowEmergencyModal: (show) => {
    set({ showEmergencyModal: show });
  },

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
  }
}));