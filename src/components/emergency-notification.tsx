import { Toast } from 'react-hot-toast';

interface EmergencyNotificationProps {
  t: Toast;
}

export function EmergencyNotification({ t }: EmergencyNotificationProps) {
  return (
    <div className="max-w-md w-full bg-red-500 shadow-lg rounded-lg pointer-events-auto flex ring-1 ring-black ring-opacity-5">
      <div className="flex-1 w-0 p-4">
        <div className="flex items-start">
          <div className="ml-3 flex-1">
            <p className="text-sm font-medium text-white">
              Emergenza Simulata
            </p>
            <p className="mt-1 text-sm text-white">
              Posizione: Test Location, Milan
            </p>
          </div>
        </div>
      </div>
      <div className="flex border-l border-red-400">
        <button
          onClick={() => toast.dismiss(t.id)}
          className="w-full border border-transparent rounded-none rounded-r-lg p-4 flex items-center justify-center text-sm font-medium text-white hover:text-red-100 focus:outline-none"
        >
          Chiudi
        </button>
      </div>
    </div>
  );
}