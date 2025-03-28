/*
  # Update Virtual Gates to Support Area Drawing

  1. Changes
    - Modify virtual_gates table to use POLYGON geometry instead of POINT
    - Add new column for storing the polygon vertices
    - Migrate existing point data to polygons
    - Update RLS policies

  2. Notes
    - Creates default polygons around existing points
    - Preserves existing data while changing the structure
*/

-- Temporarily disable RLS
ALTER TABLE virtual_gates DISABLE ROW LEVEL SECURITY;

-- Add new column for polygon
ALTER TABLE virtual_gates 
ADD COLUMN IF NOT EXISTS geo_polygon geometry(Polygon, 4326);

-- Convert existing points to polygons (create a small square around each point)
UPDATE virtual_gates
SET geo_polygon = ST_Buffer(
  geo_point::geography,
  10, -- 10 meters radius
  'quad_segs=4' -- Make it a square
)::geometry
WHERE geo_polygon IS NULL;

-- Make geo_polygon required and drop old geo_point column
ALTER TABLE virtual_gates 
ALTER COLUMN geo_polygon SET NOT NULL;

ALTER TABLE virtual_gates 
DROP COLUMN geo_point;

-- Re-enable RLS
ALTER TABLE virtual_gates ENABLE ROW LEVEL SECURITY;