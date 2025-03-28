import { useEffect, useRef } from 'react';
import { format } from 'date-fns';
import { AlertTriangle, MapPin, X } from 'lucide-react';
import { EmergencySound } from '../lib/audio';

interface EmergencyModalProps {
  isOpen: boolean;
  onClose: (latitude?: number, longitude?: number) => void;
  emergency: {
    userName: string;
    timestamp: string;
    type?: string;
    latitude: number;
    longitude: number;
  };
}

export function EmergencyModal({ isOpen, onClose, emergency }: EmergencyModalProps) {
  const emergencySoundRef = useRef<EmergencySound | null>(null);

  useEffect(() => {
    // Create emergency sound instance once
    if (!emergencySoundRef.current) {
      emergencySoundRef.current = new EmergencySound();
    }

    const sound = emergencySoundRef.current;

    if (isOpen) {
      // Start the sound when modal opens
      sound.start();

      return () => {
        sound.stop();
      };
    }

    return () => {
      if (sound) {
        sound.stop();
      }
    };
  }, [isOpen]);

  const handleClose = () => {
    if (emergencySoundRef.current) {
      emergencySoundRef.current.stop();
    }
    // Pass the coordinates to center the map
    onClose(emergency.latitude, emergency.longitude);
  };

  const formatCoordinate = (coord: number) => coord.toFixed(6);

  return (
    <div className={`fixed inset-0 z-50 overflow-y-auto ${isOpen ? '' : 'hidden'}`}>
      <div className="flex min-h-screen items-end justify-center px-4 pb-20 pt-4 text-center sm:block sm:p-0">
        <div className="fixed inset-0 transition-opacity" aria-hidden="true">
          <div className="absolute inset-0 bg-gray-500 bg-opacity-75"></div>
        </div>

        <div className="inline-block transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left align-bottom shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6 sm:align-middle">
          <div className="absolute right-0 top-0 hidden pr-4 pt-4 sm:block">
            <button
              type="button"
              onClick={handleClose}
              className="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none"
            >
              <X className="h-6 w-6" />
            </button>
          </div>

          <div className="sm:flex sm:items-start">
            <div className="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10">
              <AlertTriangle className="h-6 w-6 text-red-600" />
            </div>
            <div className="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left">
              <h3 className="text-2xl font-bold text-red-600">
                EMERGENZA IN CORSO
              </h3>
              <div className="mt-4 space-y-2">
                <p className="text-lg font-medium text-gray-900">
                  Utente: {emergency.userName}
                </p>
                <p className="text-lg text-gray-700">
                  Data e ora: {format(new Date(emergency.timestamp), 'dd/MM/yyyy HH:mm:ss')}
                </p>
                {emergency.type && (
                  <p className="text-lg text-gray-700">
                    Tipo: {emergency.type}
                  </p>
                )}
                <div className="flex items-center gap-2 text-lg text-gray-700">
                  <MapPin className="h-5 w-5 text-red-500" />
                  <span>
                    Coordinate: {formatCoordinate(emergency.latitude)}, {formatCoordinate(emergency.longitude)}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              onClick={handleClose}
              className="inline-flex w-full justify-center rounded-md border border-transparent bg-red-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 sm:ml-3 sm:w-auto sm:text-sm"
            >
              Visualizza sulla mappa
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}