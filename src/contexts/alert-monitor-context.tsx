import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { useEmergencyStore } from '../stores/emergency';

interface AlertMonitorContextType {
    isMonitoring: boolean;
    startMonitoring: () => void;
    stopMonitoring: () => void;
    monitoringInterval: number;
    setMonitoringInterval: (interval: number) => void;
}

export const AlertMonitorContext = createContext<AlertMonitorContextType | undefined>(undefined);

export const useAlertMonitor = () => {
    const context = useContext(AlertMonitorContext);
    if (!context) {
        throw new Error('useAlertMonitor must be used within an AlertMonitorProvider');
    }
    return context;
};

export const AlertMonitorProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [isMonitoring, setIsMonitoring] = useState(false);
    const [monitoringInterval, setMonitoringInterval] = useState(30000); // Default: 10 seconds
    const [intervalId, setIntervalId] = useState<NodeJS.Timeout | null>(null);

    const fetchEmergencys = useEmergencyStore(state => state.fetchEmergencys);
    const currentUser = useEmergencyStore(state => state.currentUser);

    // Use useCallback to prevent function recreation on each render
    const startMonitoring = useCallback(() => {
        if (intervalId) return; // Already monitoring

        console.log('Starting emergency monitoring...');
        setIsMonitoring(true);

        // Initial fetch
        fetchEmergencys();

        // Set up interval for automatic fetching
        const id = setInterval(() => {
            console.log('Checking for new emergencies...');
            fetchEmergencys();
        }, monitoringInterval);

        setIntervalId(id);
    }, [fetchEmergencys, intervalId, monitoringInterval]);

    // Use useCallback to prevent function recreation on each render
    const stopMonitoring = useCallback(() => {
        if (intervalId) {
            console.log('Stopping emergency monitoring...');
            clearInterval(intervalId);
            setIntervalId(null);
            setIsMonitoring(false);
        }
    }, [intervalId]);

    // Automatically start/stop monitoring based on user authentication
    useEffect(() => {
        if (currentUser) {
            startMonitoring();
        } else {
            stopMonitoring();
        }

        // Cleanup on unmount
        return () => {
            if (intervalId) {
                clearInterval(intervalId);
                setIntervalId(null);
            }
        };
    }, [currentUser, startMonitoring, stopMonitoring, intervalId]);

    // Update interval if changed
    useEffect(() => {
        // Only update if already monitoring
        if (isMonitoring && intervalId) {
            // Clear existing interval
            clearInterval(intervalId);

            // Create new interval with updated timing
            const id = setInterval(() => {
                console.log('Checking for new emergencies...');
                fetchEmergencys();
            }, monitoringInterval);

            setIntervalId(id);
        }
    }, [monitoringInterval, isMonitoring, intervalId, fetchEmergencys]);

    const value = {
        isMonitoring,
        startMonitoring,
        stopMonitoring,
        monitoringInterval,
        setMonitoringInterval
    };

    return (
        <AlertMonitorContext.Provider value={value}>
            {children}
        </AlertMonitorContext.Provider>
    );
};

// Uncomment the following line if you want to use the context in a provider
// <AlertMonitorContext.Provider value={value}>
//     {children}
// </AlertMonitorContext.Provider>