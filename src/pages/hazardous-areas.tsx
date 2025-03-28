import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Pencil, Trash2, X } from 'lucide-react';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';
import { loadGoogleMaps } from '../lib/maps';

interface HazardousArea {
  id: string;
  name: string;
  company_id: string;
  radius: number;
  geo_point: any;
  created_at: string;
  company: {
    name: string;
  };
}

interface HazardousAreaFormData {
  name: string;
  company_id: string;
  radius: number;
  latitude: number;
  longitude: number;
}

export function HazardousAreas() {
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingArea, setEditingArea] = useState<HazardousArea | null>(null);
  const [map, setMap] = useState<google.maps.Map | null>(null);
  const [marker, setMarker] = useState<google.maps.Marker | null>(null);
  const [circle, setCircle] = useState<google.maps.Circle | null>(null);
  const [formData, setFormData] = useState<HazardousAreaFormData>({
    name: '',
    company_id: '',
    radius: 100,
    latitude: 45.4642,
    longitude: 9.1900
  });

  // Fetch hazardous areas
  const { data: areas, isLoading: areasLoading } = useQuery({
    queryKey: ['hazardous-areas'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('hazardous_areas')
        .select('*, company:companies(name)')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data as HazardousArea[];
    }
  });

  // Fetch companies for the select dropdown
  const { data: companies, isLoading: companiesLoading } = useQuery({
    queryKey: ['companies'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('companies')
        .select('id, name')
        .order('name');

      if (error) throw error;
      return data as { id: string; name: string }[];
    }
  });

  // Create hazardous area mutation
  const createArea = useMutation({
    mutationFn: async (data: HazardousAreaFormData) => {
      const { error } = await supabase
        .from('hazardous_areas')
        .insert([{
          name: data.name,
          company_id: data.company_id,
          radius: data.radius,
          geo_point: `POINT(${data.longitude} ${data.latitude})`
        }]);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['hazardous-areas'] });
      toast.success('Area pericolosa creata con successo');
      handleCloseModal();
    },
    onError: () => {
      toast.error('Errore durante la creazione dell\'area pericolosa');
    }
  });

  // Update hazardous area mutation
  const updateArea = useMutation({
    mutationFn: async ({ id, data }: { id: string; data: HazardousAreaFormData }) => {
      const { error } = await supabase
        .from('hazardous_areas')
        .update({
          name: data.name,
          company_id: data.company_id,
          radius: data.radius,
          geo_point: `POINT(${data.longitude} ${data.latitude})`
        })
        .eq('id', id);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['hazardous-areas'] });
      toast.success('Area pericolosa aggiornata con successo');
      handleCloseModal();
    },
    onError: () => {
      toast.error('Errore durante l\'aggiornamento dell\'area pericolosa');
    }
  });

  // Delete hazardous area mutation
  const deleteArea = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('hazardous_areas')
        .delete()
        .eq('id', id);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['hazardous-areas'] });
      toast.success('Area pericolosa eliminata con successo');
    },
    onError: () => {
      toast.error('Errore durante l\'eliminazione dell\'area pericolosa');
    }
  });

  const initializeMap = async () => {
    try {
      const google = await loadGoogleMaps();
      const mapElement = document.getElementById('map');
      
      if (!mapElement) return;

      const mapInstance = new google.maps.Map(mapElement, {
        center: { lat: formData.latitude, lng: formData.longitude },
        zoom: 13,
        styles: [
          {
            featureType: 'poi',
            elementType: 'labels',
            stylers: [{ visibility: 'off' }]
          }
        ]
      });

      const markerInstance = new google.maps.Marker({
        position: { lat: formData.latitude, lng: formData.longitude },
        map: mapInstance,
        draggable: true
      });

      const circleInstance = new google.maps.Circle({
        map: mapInstance,
        center: { lat: formData.latitude, lng: formData.longitude },
        radius: formData.radius,
        fillColor: '#ff0000',
        fillOpacity: 0.2,
        strokeColor: '#ff0000',
        strokeOpacity: 0.8,
        strokeWeight: 2
      });

      markerInstance.addListener('dragend', () => {
        const position = markerInstance.getPosition();
        if (position) {
          setFormData(prev => ({
            ...prev,
            latitude: position.lat(),
            longitude: position.lng()
          }));
          circleInstance.setCenter(position);
        }
      });

      setMap(mapInstance);
      setMarker(markerInstance);
      setCircle(circleInstance);
    } catch (error) {
      console.error('Error loading Google Maps:', error);
      toast.error('Errore durante il caricamento della mappa');
    }
  };

  const handleOpenModal = async (area?: HazardousArea) => {
    if (area) {
      // Extract coordinates from PostGIS geometry
      const coordinates = area.geo_point.coordinates || [9.1900, 45.4642];
      setEditingArea(area);
      setFormData({
        name: area.name,
        company_id: area.company_id,
        radius: area.radius,
        longitude: coordinates[0],
        latitude: coordinates[1]
      });
    } else {
      setEditingArea(null);
      setFormData({
        name: '',
        company_id: '',
        radius: 100,
        latitude: 45.4642,
        longitude: 9.1900
      });
    }
    setIsModalOpen(true);
    setTimeout(initializeMap, 100);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingArea(null);
    setMap(null);
    setMarker(null);
    setCircle(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (editingArea) {
      updateArea.mutate({ id: editingArea.id, data: formData });
    } else {
      createArea.mutate(formData);
    }
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Sei sicuro di voler eliminare questa area pericolosa?')) {
      deleteArea.mutate(id);
    }
  };

  const handleRadiusChange = (value: number) => {
    setFormData(prev => ({ ...prev, radius: value }));
    if (circle) {
      circle.setRadius(value);
    }
  };

  if (areasLoading || companiesLoading) {
    return <div className="flex items-center justify-center">Caricamento...</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Aree Pericolose</h1>
        <button
          onClick={() => handleOpenModal()}
          className="flex items-center gap-2 rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          <Plus className="h-4 w-4" />
          Nuova Area
        </button>
      </div>

      <div className="overflow-hidden rounded-lg border border-gray-200 bg-white shadow">
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
              <th className="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">
                Azioni
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {areas?.map((area) => (
              <tr key={area.id}>
                <td className="whitespace-nowrap px-6 py-4">
                  <div className="text-sm font-medium text-gray-900">
                    {area.name}
                  </div>
                </td>
                <td className="whitespace-nowrap px-6 py-4">
                  <div className="text-sm text-gray-500">
                    {area.company.name}
                  </div>
                </td>
                <td className="whitespace-nowrap px-6 py-4">
                  <div className="text-sm text-gray-500">
                    {area.radius}
                  </div>
                </td>
                <td className="whitespace-nowrap px-6 py-4 text-right text-sm font-medium">
                  <button
                    onClick={() => handleOpenModal(area)}
                    className="mr-2 text-blue-600 hover:text-blue-900"
                  >
                    <Pencil className="h-4 w-4" />
                  </button>
                  <button
                    onClick={() => handleDelete(area.id)}
                    className="text-red-600 hover:text-red-900"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </td>
              </tr>
            ))}
            {areas?.length === 0 && (
              <tr>
                <td colSpan={4} className="px-6 py-4 text-center text-sm text-gray-500">
                  Nessuna area pericolosa trovata
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 z-10 overflow-y-auto">
          <div className="flex min-h-screen items-end justify-center px-4 pb-20 pt-4 text-center sm:block sm:p-0">
            <div className="fixed inset-0 transition-opacity" aria-hidden="true">
              <div className="absolute inset-0 bg-gray-500 opacity-75"></div>
            </div>

            <div className="inline-block transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left align-bottom shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6 sm:align-middle">
              <div className="absolute right-0 top-0 hidden pr-4 pt-4 sm:block">
                <button
                  type="button"
                  onClick={handleCloseModal}
                  className="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none"
                >
                  <X className="h-6 w-6" />
                </button>
              </div>

              <div className="sm:flex sm:items-start">
                <div className="mt-3 w-full text-center sm:ml-4 sm:mt-0 sm:text-left">
                  <h3 className="text-lg font-medium leading-6 text-gray-900">
                    {editingArea ? 'Modifica Area Pericolosa' : 'Nuova Area Pericolosa'}
                  </h3>
                  <form onSubmit={handleSubmit} className="mt-6 space-y-6">
                    <div>
                      <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                        Nome
                      </label>
                      <input
                        type="text"
                        name="name"
                        id="name"
                        required
                        value={formData.name}
                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                        className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm"
                      />
                    </div>

                    <div>
                      <label htmlFor="company" className="block text-sm font-medium text-gray-700">
                        Azienda
                      </label>
                      <select
                        id="company"
                        name="company"
                        required
                        value={formData.company_id}
                        onChange={(e) => setFormData({ ...formData, company_id: e.target.value })}
                        className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm"
                      >
                        <option value="">Seleziona un'azienda</option>
                        {companies?.map((company) => (
                          <option key={company.id} value={company.id}>
                            {company.name}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label htmlFor="radius" className="block text-sm font-medium text-gray-700">
                        Raggio (metri)
                      </label>
                      <input
                        type="range"
                        name="radius"
                        id="radius"
                        min="50"
                        max="1000"
                        step="50"
                        value={formData.radius}
                        onChange={(e) => handleRadiusChange(parseInt(e.target.value))}
                        className="mt-1 block w-full"
                      />
                      <div className="mt-1 text-sm text-gray-500">
                        {formData.radius} metri
                      </div>
                    </div>

                    <div className="h-64 w-full rounded-lg border border-gray-300">
                      <div id="map" className="h-full w-full rounded-lg"></div>
                    </div>

                    <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
                      <button
                        type="submit"
                        className="inline-flex w-full justify-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 sm:ml-3 sm:w-auto sm:text-sm"
                      >
                        {editingArea ? 'Aggiorna' : 'Crea'}
                      </button>
                      <button
                        type="button"
                        onClick={handleCloseModal}
                        className="mt-3 inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 sm:mt-0 sm:w-auto sm:text-sm"
                      >
                        Annulla
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}