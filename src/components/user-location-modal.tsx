import { useEffect, useState } from 'react';
import { X } from 'lucide-react';
import { loadGoogleMaps } from '../lib/maps';

interface UserLocationModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: {
    name: string;
    address: string | null;
    location_sharing: boolean;
  };
}

export function UserLocationModal({ isOpen, onClose, user }: UserLocationModalProps) {
  const [map, setMap] = useState<google.maps.Map | null>(null);
  const [marker, setMarker] = useState<google.maps.Marker | null>(null);

  useEffect(() => {
    if (isOpen && user.location_sharing) {
      initializeMap();
    }
  }, [isOpen, user]);

  const initializeMap = async () => {
    try {
      const google = await loadGoogleMaps();
      const mapElement = document.getElementById('user-location-map');
      
      if (!mapElement) return;

      // Default to Milan coordinates
      const defaultPosition = { lat: 45.4642, lng: 9.1900 };

      const mapInstance = new google.maps.Map(mapElement, {
        center: defaultPosition,
        zoom: 13,
        styles: [
          {
            featureType: 'poi',
            elementType: 'labels',
            stylers: [{ visibility: 'off' }]
          }
        ]
      });

      // Create marker
      const markerInstance = new google.maps.Marker({
        position: defaultPosition,
        map: mapInstance,
        title: user.name,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 10,
          fillColor: '#4F46E5',
          fillOpacity: 1,
          strokeWeight: 2,
          strokeColor: '#ffffff',
        }
      });

      // If we have an address, geocode it
      if (user.address) {
        const geocoder = new google.maps.Geocoder();
        geocoder.geocode({ address: user.address }, (results, status) => {
          if (status === 'OK' && results?.[0]?.geometry?.location) {
            const position = results[0].geometry.location;
            mapInstance.setCenter(position);
            markerInstance.setPosition(position);

            // Add info window
            const infoWindow = new google.maps.InfoWindow({
              content: `
                <div class="p-2">
                  <p class="font-bold">${user.name}</p>
                  <p class="text-sm">${user.address}</p>
                </div>
              `
            });

            markerInstance.addListener('click', () => {
              infoWindow.open(mapInstance, markerInstance);
            });
          }
        });
      }

      setMap(mapInstance);
      setMarker(markerInstance);
    } catch (error) {
      console.error('Error loading Google Maps:', error);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-10 overflow-y-auto">
      <div className="flex min-h-screen items-end justify-center px-4 pb-20 pt-4 text-center sm:block sm:p-0">
        <div className="fixed inset-0 transition-opacity" aria-hidden="true">
          <div className="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <div className="inline-block transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left align-bottom shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6 sm:align-middle">
          <div className="absolute right-0 top-0 hidden pr-4 pt-4 sm:block">
            <button
              type="button"
              onClick={onClose}
              className="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none"
            >
              <X className="h-6 w-6" />
            </button>
          </div>

          <div className="sm:flex sm:items-start">
            <div className="mt-3 w-full text-center sm:ml-4 sm:mt-0 sm:text-left">
              <h3 className="text-lg font-medium leading-6 text-gray-900">
                Posizione di {user.name}
              </h3>

              {user.location_sharing ? (
                <>
                  <div className="mt-2">
                    <p className="text-sm text-gray-500">
                      Indirizzo: {user.address || 'Non disponibile'}
                    </p>
                  </div>
                  <div className="mt-4 h-96 w-full rounded-lg border border-gray-300">
                    <div id="user-location-map" className="h-full w-full rounded-lg"></div>
                  </div>
                </>
              ) : (
                <div className="mt-2">
                  <p className="text-sm text-gray-500">
                    Questo utente non ha attivato la condivisione della posizione.
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}