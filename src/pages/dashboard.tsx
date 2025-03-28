import { useState, useEffect, useRef } from 'react';
import { useLocation } from 'react-router-dom';
import { AlertTriangle, Users, Building2, Bell, MapPin, Heater as Gate } from 'lucide-react';
import { loadGoogleMaps } from '../lib/maps';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';
import { useEmergencyStore } from '../stores/emergency';
import { EmergencyModal } from '../components/emergency-modal';

interface HazardousArea {
  id: string;
  name: string;
  geo_point: {
    coordinates: [number, number];
  };
  radius: number;
  company: {
    name: string;
  };
}

interface VirtualGate {
  id: string;
  name: string;
  geo_polygon: {
    coordinates: [number[][]];
  };
  company: {
    name: string;
  };
}

interface LocationState {
  emergency?: {
    id: string;
    userName: string;
    timestamp: string;
    latitude: number;
    longitude: number;
  };
}

export function Dashboard() {
  const location = useLocation();
  const state = location.state as LocationState;
  const mapRef = useRef<google.maps.Map | null>(null);
  const [stats] = useState({
    activeUsers: 42,
    companies: 8,
    activeAlerts: 3
  });
  const [map, setMap] = useState<google.maps.Map | null>(null);
  const [marker, setMarker] = useState<google.maps.Marker | null>(null);
  const [hazardousAreas, setHazardousAreas] = useState<HazardousArea[]>([]);
  const [virtualGates, setVirtualGates] = useState<VirtualGate[]>([]);
  const [circles, setCircles] = useState<google.maps.Circle[]>([]);
  const [gatePolygons, setGatePolygons] = useState<google.maps.Polygon[]>([]);
  
  const { 
    loading, 
    currentUser, 
    currentEmergency,
    showEmergencyModal,
    fetchCurrentUser, 
    simulateEmergency,
    setShowEmergencyModal,
    markEmergencyAsReceived
  } = useEmergencyStore();

  useEffect(() => {
    fetchCurrentUser();
    initializeMap();
    fetchHazardousAreas();
    fetchVirtualGates();
  }, [fetchCurrentUser]);

  useEffect(() => {
    if (map) {
      updateMapMarkers();
    }
  }, [map, hazardousAreas, virtualGates]);

  // Handle emergency location from navigation state
  useEffect(() => {
    if (state?.emergency && map) {
      const { latitude, longitude } = state.emergency;
      
      // Create or update marker
      if (marker) {
        marker.setMap(null);
      }

      const newMarker = new google.maps.Marker({
        position: { lat: latitude, lng: longitude },
        map: map,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 10,
          fillColor: '#ff0000',
          fillOpacity: 1,
          strokeWeight: 2,
          strokeColor: '#ffffff',
        },
        animation: google.maps.Animation.BOUNCE
      });

      // Add info window
      const infoWindow = new google.maps.InfoWindow({
        content: `<div class="p-2">
          <p class="font-bold">Emergenza</p>
          <p>Utente: ${state.emergency.userName}</p>
          <p>Data: ${new Date(state.emergency.timestamp).toLocaleString()}</p>
          <p>Coordinate: ${latitude.toFixed(6)}, ${longitude.toFixed(6)}</p>
        </div>`
      });

      newMarker.addListener('click', () => {
        infoWindow.open(map, newMarker);
      });

      setMarker(newMarker);

      // Center and zoom map
      map.setCenter({ lat: latitude, lng: longitude });
      map.setZoom(18);

      // Stop bounce after 2 seconds
      setTimeout(() => {
        newMarker.setAnimation(null);
      }, 2000);
    }
  }, [state?.emergency, map]);

  const fetchHazardousAreas = async () => {
    try {
      const { data, error } = await supabase
        .from('hazardous_areas')
        .select('id, name, geo_point, radius, company:companies(name)');

      if (error) throw error;
      setHazardousAreas(data);
    } catch (error) {
      console.error('Error fetching hazardous areas:', error);
      toast.error('Errore durante il caricamento delle aree pericolose');
    }
  };

  const fetchVirtualGates = async () => {
    try {
      const { data, error } = await supabase
        .from('virtual_gates')
        .select('id, name, geo_polygon, company:companies(name)');

      if (error) throw error;
      setVirtualGates(data);
    } catch (error) {
      console.error('Error fetching virtual gates:', error);
      toast.error('Errore durante il caricamento dei virtual gates');
    }
  };

  const updateMapMarkers = () => {
    if (!map) return;

    // Clear existing markers
    circles.forEach(circle => circle.setMap(null));
    gatePolygons.forEach(polygon => polygon.setMap(null));

    // Create circles for hazardous areas
    const newCircles = hazardousAreas.map(area => {
      const [lng, lat] = area.geo_point.coordinates;
      const circle = new google.maps.Circle({
        map,
        center: { lat, lng },
        radius: area.radius,
        fillColor: '#ff0000',
        fillOpacity: 0.2,
        strokeColor: '#ff0000',
        strokeOpacity: 0.8,
        strokeWeight: 2
      });

      // Add click listener for info window
      circle.addListener('click', () => {
        const infoWindow = new google.maps.InfoWindow({
          content: `
            <div class="p-2">
              <p class="font-bold">${area.name}</p>
              <p class="text-sm">Azienda: ${area.company.name}</p>
              <p class="text-sm">Raggio: ${area.radius}m</p>
            </div>
          `,
          position: { lat, lng }
        });
        infoWindow.open(map);
      });

      return circle;
    });

    // Create polygons for virtual gates
    const newPolygons = virtualGates.map(gate => {
      const coordinates = gate.geo_polygon.coordinates[0];
      const path = coordinates.map(([lng, lat]) => ({ lat, lng }));

      const polygon = new google.maps.Polygon({
        paths: path,
        map,
        fillColor: '#4F46E5',
        fillOpacity: 0.3,
        strokeColor: '#4F46E5',
        strokeWeight: 2
      });

      // Add info window
      polygon.addListener('click', (e: google.maps.PolyMouseEvent) => {
        if (!e.latLng) return;

        const infoWindow = new google.maps.InfoWindow({
          content: `
            <div class="p-2">
              <p class="font-bold">${gate.name}</p>
              <p class="text-sm">Azienda: ${gate.company.name}</p>
            </div>
          `,
          position: e.latLng
        });

        infoWindow.open(map);
      });

      return polygon;
    });

    setCircles(newCircles);
    setGatePolygons(newPolygons);

    // Fit bounds to show all markers if no emergency is being shown
    if (!state?.emergency && (newCircles.length > 0 || newPolygons.length > 0)) {
      const bounds = new google.maps.LatLngBounds();
      
      hazardousAreas.forEach(area => {
        const [lng, lat] = area.geo_point.coordinates;
        bounds.extend({ lat, lng });
      });
      
      virtualGates.forEach(gate => {
        gate.geo_polygon.coordinates[0].forEach(([lng, lat]) => {
          bounds.extend({ lat, lng });
        });
      });

      map.fitBounds(bounds);
    }
  };

  const initializeMap = async () => {
    try {
      const google = await loadGoogleMaps();
      const mapElement = document.getElementById('map');
      
      if (!mapElement) return;

      const mapInstance = new google.maps.Map(mapElement, {
        center: { lat: 45.4642, lng: 9.1900 }, // Milan coordinates
        zoom: 13,
        styles: [
          {
            featureType: 'poi',
            elementType: 'labels',
            stylers: [{ visibility: 'off' }]
          }
        ]
      });

      setMap(mapInstance);
      mapRef.current = mapInstance;
    } catch (error) {
      console.error('Error loading Google Maps:', error);
      toast.error('Errore durante il caricamento della mappa');
    }
  };

  const handleEmergency = async () => {
    if (!map) return;

    // Random location near Milan
    const latitude = 45.4642 + (Math.random() - 0.5) * 0.02;
    const longitude = 9.1900 + (Math.random() - 0.5) * 0.02;

    await simulateEmergency(latitude, longitude);

    // Update map marker
    if (marker) {
      marker.setMap(null);
    }

    const newMarker = new google.maps.Marker({
      position: { lat: latitude, lng: longitude },
      map: map,
      icon: {
        path: google.maps.SymbolPath.CIRCLE,
        scale: 10,
        fillColor: '#ff0000',
        fillOpacity: 1,
        strokeWeight: 2,
        strokeColor: '#ffffff',
      }
    });

    // Add info window
    const infoWindow = new google.maps.InfoWindow({
      content: `<div class="p-2">
        <p class="font-bold">Emergenza in corso</p>
        <p>Utente: ${currentUser?.name}</p>
        <p>Coordinate: ${latitude.toFixed(6)}, ${longitude.toFixed(6)}</p>
      </div>`
    });

    newMarker.addListener('click', () => {
      infoWindow.open(map, newMarker);
    });

    setMarker(newMarker);
  };

  const handleCloseEmergency = (latitude?: number, longitude?: number) => {
    if (!currentEmergency || !map || !marker) return;

    // If coordinates are provided, center and zoom the map
    if (latitude !== undefined && longitude !== undefined) {
      const position = { lat: latitude, lng: longitude };
      map.setCenter(position);
      map.setZoom(18); // Closer zoom level for better detail

      // Update marker position and make it bounce
      marker.setPosition(position);
      marker.setAnimation(google.maps.Animation.BOUNCE);
      setTimeout(() => marker.setAnimation(null), 2000);
    }

    if (currentEmergency) {
      markEmergencyAsReceived(currentEmergency.id);
    }
    setShowEmergencyModal(false);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        {process.env.NODE_ENV === 'development' && (
          <button
            onClick={handleEmergency}
            disabled={loading || !currentUser}
            className="flex items-center gap-2 rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 disabled:opacity-50"
          >
            <Bell className="h-4 w-4" />
            {loading ? 'Invio...' : 'Simula Emergenza'}
          </button>
        )}
      </div>
      
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-lg bg-white p-6 shadow-md">
          <div className="flex items-center">
            <Users className="h-8 w-8 text-blue-500" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Utenti Attivi</p>
              <p className="text-2xl font-semibold text-gray-900">{stats.activeUsers}</p>
            </div>
          </div>
        </div>

        <div className="rounded-lg bg-white p-6 shadow-md">
          <div className="flex items-center">
            <Building2 className="h-8 w-8 text-green-500" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Aziende</p>
              <p className="text-2xl font-semibold text-gray-900">{stats.companies}</p>
            </div>
          </div>
        </div>

        <div className="rounded-lg bg-white p-6 shadow-md">
          <div className="flex items-center">
            <AlertTriangle className="h-8 w-8 text-red-500" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600">Allarmi Attivi</p>
              <p className="text-2xl font-semibold text-gray-900">{stats.activeAlerts}</p>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Hazardous Areas Section */}
        <div className="rounded-lg bg-white p-6 shadow-md">
          <div className="mb-4 flex items-center gap-3">
            <AlertTriangle className="h-6 w-6 text-red-500" />
            <h2 className="text-lg font-semibold text-gray-900">Aree Pericolose</h2>
          </div>
          <div className="overflow-hidden rounded-lg border border-gray-200">
            <div className="max-h-64 overflow-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                      Nome
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                      Azienda
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                      Raggio (m)
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 bg-white">
                  {hazardousAreas.map((area) => (
                    <tr key={area.id}>
                      <td className="whitespace-nowrap px-6 py-4">
                        <div className="text-sm font-medium text-gray-900">{area.name}</div>
                      </td>
                      <td className="whitespace-nowrap px-6 py-4">
                        <div className="text-sm text-gray-500">{area.company.name}</div>
                      </td>
                      <td className="whitespace-nowrap px-6 py-4">
                        <div className="text-sm text-gray-500">{area.radius}</div>
                      </td>
                    </tr>
                  ))}
                  {hazardousAreas.length === 0 && (
                    <tr>
                      <td colSpan={3} className="px-6 py-4 text-center text-sm text-gray-500">
                        Nessuna area pericolosa trovata
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Virtual Gates Section */}
        <div className="rounded-lg bg-white p-6 shadow-md">
          <div className="mb-4 flex items-center gap-3">
            <Gate className="h-6 w-6 text-blue-500" />
            <h2 className="text-lg font-semibold text-gray-900">Virtual Gates</h2>
          </div>
          <div className="overflow-hidden rounded-lg border border-gray-200">
            <div className="max-h-64 overflow-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                      Nome
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                      Azienda
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 bg-white">
                  {virtualGates.map((gate) => (
                    <tr key={gate.id}>
                      <td className="whitespace-nowrap px-6 py-4">
                        <div className="text-sm font-medium text-gray-900">{gate.name}</div>
                      </td>
                      <td className="whitespace-nowrap px-6 py-4">
                        <div className="text-sm text-gray-500">{gate.company.name}</div>
                      </td>
                    </tr>
                  ))}
                  {virtualGates.length === 0 && (
                    <tr>
                      <td colSpan={2} className="px-6 py-4 text-center text-sm text-gray-500">
                        Nessun virtual gate trovato
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <div className="rounded-lg bg-white p-6 shadow-md">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Mappa Emergenze</h2>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <div className="h-3 w-3 rounded-full bg-red-500"></div>
              <span className="text-sm text-gray-600">Aree Pericolose</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="h-3 w-3 rounded-full bg-blue-600"></div>
              <span className="text-sm text-gray-600">Virtual Gates</span>
            </div>
          </div>
        </div>
        <div className="h-96 w-full rounded-lg border border-gray-200">
          <div id="map" className="h-full w-full rounded-lg"></div>
        </div>
      </div>

      {currentEmergency && (
        <EmergencyModal
          isOpen={showEmergencyModal}
          
          onClose={handleCloseEmergency}
          emergency={currentEmergency}
        />
      )}
    </div>
  );
}