import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Pencil, Trash2, X } from 'lucide-react';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';
import { loadGoogleMaps } from '../lib/maps';

interface VirtualGate {
  id: string;
  name: string;
  company_id: string;
  geo_polygon: any;
  created_at: string;
  company: {
    name: string;
  };
}

interface VirtualGateFormData {
  name: string;
  company_id: string;
  vertices: google.maps.LatLngLiteral[];
}

export function VirtualGates() {
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingGate, setEditingGate] = useState<VirtualGate | null>(null);
  const [map, setMap] = useState<google.maps.Map | null>(null);
  const [drawingManager, setDrawingManager] = useState<google.maps.drawing.DrawingManager | null>(null);
  const [currentPolygon, setCurrentPolygon] = useState<google.maps.Polygon | null>(null);
  const [formData, setFormData] = useState<VirtualGateFormData>({
    name: '',
    company_id: '',
    vertices: []
  });

  // Fetch virtual gates
  const { data: gates, isLoading: gatesLoading } = useQuery({
    queryKey: ['virtual-gates'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('virtual_gates')
        .select('*, company:companies(name)')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data as VirtualGate[];
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

  // Create virtual gate mutation
  const createGate = useMutation({
    mutationFn: async (data: VirtualGateFormData) => {
      // Convert vertices to PostGIS polygon format
      const polygonText = `POLYGON((${data.vertices
        .map(vertex => `${vertex.lng} ${vertex.lat}`)
        .join(',')},${data.vertices[0].lng} ${data.vertices[0].lat}))`;

      const { error } = await supabase
        .from('virtual_gates')
        .insert([{
          name: data.name,
          company_id: data.company_id,
          geo_polygon: polygonText
        }]);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['virtual-gates'] });
      toast.success('Virtual gate creato con successo');
      handleCloseModal();
    },
    onError: () => {
      toast.error('Errore durante la creazione del virtual gate');
    }
  });

  // Update virtual gate mutation
  const updateGate = useMutation({
    mutationFn: async ({ id, data }: { id: string; data: VirtualGateFormData }) => {
      // Convert vertices to PostGIS polygon format
      const polygonText = `POLYGON((${data.vertices
        .map(vertex => `${vertex.lng} ${vertex.lat}`)
        .join(',')},${data.vertices[0].lng} ${data.vertices[0].lat}))`;

      const { error } = await supabase
        .from('virtual_gates')
        .update({
          name: data.name,
          company_id: data.company_id,
          geo_polygon: polygonText
        })
        .eq('id', id);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['virtual-gates'] });
      toast.success('Virtual gate aggiornato con successo');
      handleCloseModal();
    },
    onError: () => {
      toast.error('Errore durante l\'aggiornamento del virtual gate');
    }
  });

  // Delete virtual gate mutation
  const deleteGate = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('virtual_gates')
        .delete()
        .eq('id', id);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['virtual-gates'] });
      toast.success('Virtual gate eliminato con successo');
    },
    onError: () => {
      toast.error('Errore durante l\'eliminazione del virtual gate');
    }
  });

  const initializeMap = async () => {
    try {
      const google = await loadGoogleMaps();
      const mapElement = document.getElementById('map');
      
      if (!mapElement) return;

      const mapInstance = new google.maps.Map(mapElement, {
        center: { lat: 45.4642, lng: 9.1900 },
        zoom: 13,
        styles: [
          {
            featureType: 'poi',
            elementType: 'labels',
            stylers: [{ visibility: 'off' }]
          }
        ]
      });

      // Initialize drawing manager
      const drawingManagerInstance = new google.maps.drawing.DrawingManager({
        drawingMode: google.maps.drawing.OverlayType.POLYGON,
        drawingControl: true,
        drawingControlOptions: {
          position: google.maps.ControlPosition.TOP_CENTER,
          drawingModes: [google.maps.drawing.OverlayType.POLYGON]
        },
        polygonOptions: {
          fillColor: '#4F46E5',
          fillOpacity: 0.3,
          strokeColor: '#4F46E5',
          strokeWeight: 2,
          editable: true,
          draggable: true
        }
      });

      drawingManagerInstance.setMap(mapInstance);

      // Handle polygon complete
      google.maps.event.addListener(drawingManagerInstance, 'polygoncomplete', (polygon) => {
        // Remove any existing polygon
        if (currentPolygon) {
          currentPolygon.setMap(null);
        }

        setCurrentPolygon(polygon);
        drawingManagerInstance.setDrawingMode(null);

        // Get vertices
        const vertices = polygon.getPath().getArray().map(vertex => ({
          lat: vertex.lat(),
          lng: vertex.lng()
        }));

        setFormData(prev => ({ ...prev, vertices }));

        // Update vertices when polygon is edited
        google.maps.event.addListener(polygon.getPath(), 'set_at', () => {
          const newVertices = polygon.getPath().getArray().map(vertex => ({
            lat: vertex.lat(),
            lng: vertex.lng()
          }));
          setFormData(prev => ({ ...prev, vertices: newVertices }));
        });

        google.maps.event.addListener(polygon.getPath(), 'insert_at', () => {
          const newVertices = polygon.getPath().getArray().map(vertex => ({
            lat: vertex.lat(),
            lng: vertex.lng()
          }));
          setFormData(prev => ({ ...prev, vertices: newVertices }));
        });
      });

      setMap(mapInstance);
      setDrawingManager(drawingManagerInstance);

      // If editing, show existing polygon
      if (editingGate) {
        // Parse PostGIS polygon to array of coordinates
        const coordinates = editingGate.geo_polygon.coordinates[0];
        const vertices = coordinates.map((coord: number[]) => ({
          lng: coord[0],
          lat: coord[1]
        }));

        const polygon = new google.maps.Polygon({
          paths: vertices,
          fillColor: '#4F46E5',
          fillOpacity: 0.3,
          strokeColor: '#4F46E5',
          strokeWeight: 2,
          editable: true,
          draggable: true
        });

        polygon.setMap(mapInstance);
        setCurrentPolygon(polygon);
        setFormData(prev => ({ ...prev, vertices }));

        // Fit bounds to polygon
        const bounds = new google.maps.LatLngBounds();
        vertices.forEach(vertex => bounds.extend(vertex));
        mapInstance.fitBounds(bounds);

        // Update vertices when polygon is edited
        google.maps.event.addListener(polygon.getPath(), 'set_at', () => {
          const newVertices = polygon.getPath().getArray().map(vertex => ({
            lat: vertex.lat(),
            lng: vertex.lng()
          }));
          setFormData(prev => ({ ...prev, vertices: newVertices }));
        });

        google.maps.event.addListener(polygon.getPath(), 'insert_at', () => {
          const newVertices = polygon.getPath().getArray().map(vertex => ({
            lat: vertex.lat(),
            lng: vertex.lng()
          }));
          setFormData(prev => ({ ...prev, vertices: newVertices }));
        });
      }
    } catch (error) {
      console.error('Error loading Google Maps:', error);
      toast.error('Errore durante il caricamento della mappa');
    }
  };

  const handleOpenModal = async (gate?: VirtualGate) => {
    if (gate) {
      setEditingGate(gate);
      setFormData({
        name: gate.name,
        company_id: gate.company_id,
        vertices: []
      });
    } else {
      setEditingGate(null);
      setFormData({
        name: '',
        company_id: '',
        vertices: []
      });
    }
    setIsModalOpen(true);
    setTimeout(initializeMap, 100);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingGate(null);
    if (currentPolygon) {
      currentPolygon.setMap(null);
    }
    setCurrentPolygon(null);
    setMap(null);
    setDrawingManager(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (formData.vertices.length < 3) {
      toast.error('Disegna un\'area valida sulla mappa');
      return;
    }
    
    if (editingGate) {
      updateGate.mutate({ id: editingGate.id, data: formData });
    } else {
      createGate.mutate(formData);
    }
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Sei sicuro di voler eliminare questo virtual gate?')) {
      deleteGate.mutate(id);
    }
  };

  if (gatesLoading || companiesLoading) {
    return <div className="flex items-center justify-center">Caricamento...</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Virtual Gates</h1>
        <button
          onClick={() => handleOpenModal()}
          className="flex items-center gap-2 rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          <Plus className="h-4 w-4" />
          Nuovo Gate
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
              <th className="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">
                Azioni
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {gates?.map((gate) => (
              <tr key={gate.id}>
                <td className="whitespace-nowrap px-6 py-4">
                  <div className="text-sm font-medium text-gray-900">
                    {gate.name}
                  </div>
                </td>
                <td className="whitespace-nowrap px-6 py-4">
                  <div className="text-sm text-gray-500">
                    {gate.company.name}
                  </div>
                </td>
                <td className="whitespace-nowrap px-6 py-4 text-right text-sm font-medium">
                  <button
                    onClick={() => handleOpenModal(gate)}
                    className="mr-2 text-blue-600 hover:text-blue-900"
                  >
                    <Pencil className="h-4 w-4" />
                  </button>
                  <button
                    onClick={() => handleDelete(gate.id)}
                    className="text-red-600 hover:text-red-900"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </td>
              </tr>
            ))}
            {gates?.length === 0 && (
              <tr>
                <td colSpan={3} className="px-6 py-4 text-center text-sm text-gray-500">
                  Nessun virtual gate trovato
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
                    {editingGate ? 'Modifica Virtual Gate' : 'Nuovo Virtual Gate'}
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
                      <label className="block text-sm font-medium text-gray-700">
                        Area del Virtual Gate
                      </label>
                      <p className="mt-1 text-sm text-gray-500">
                        Disegna l'area sulla mappa utilizzando gli strumenti di disegno
                      </p>
                      <div className="mt-2 h-64 w-full rounded-lg border border-gray-300">
                        <div id="map" className="h-full w-full rounded-lg"></div>
                      </div>
                    </div>

                    <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
                      <button
                        type="submit"
                        className="inline-flex w-full justify-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 sm:ml-3 sm:w-auto sm:text-sm"
                      >
                        {editingGate ? 'Aggiorna' : 'Crea'}
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