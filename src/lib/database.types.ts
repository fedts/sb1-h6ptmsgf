export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          uid: string | null;
          name: string;
          email: string;
          role: 'superadmin' | 'admin' | 'client';
          company_id: string | null;
          location_sharing: boolean;
          address: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          uid?: string | null;
          name: string;
          email: string;
          role?: 'superadmin' | 'admin' | 'client';
          company_id?: string | null;
          location_sharing?: boolean;
          address?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          uid?: string | null;
          name?: string;
          email?: string;
          role?: 'superadmin' | 'admin' | 'client';
          company_id?: string | null;
          location_sharing?: boolean;
          address?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      companies: {
        Row: {
          id: string;
          name: string;
          phone: string | null;
          description: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          phone?: string | null;
          description?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          name?: string;
          phone?: string | null;
          description?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      hazardous_areas: {
        Row: {
          id: string;
          name: string;
          company_id: string;
          geo_point: {
            type: 'Point';
            coordinates: [number, number];
            crs: { type: 'name'; properties: { name: 'urn:ogc:def:crs:EPSG::4326' } };
          };
          radius: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          company_id: string;
          geo_point: string;
          radius: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          name?: string;
          company_id?: string;
          geo_point?: string;
          radius?: number;
          created_at?: string;
          updated_at?: string;
        };
      };
      virtual_gates: {
        Row: {
          id: string;
          name: string;
          company_id: string;
          geo_point: {
            type: 'Point';
            coordinates: [number, number];
            crs: { type: 'name'; properties: { name: 'urn:ogc:def:crs:EPSG::4326' } };
          };
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          company_id: string;
          geo_point: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          name?: string;
          company_id?: string;
          geo_point?: string;
          created_at?: string;
          updated_at?: string;
        };
      };
    };
  };
}