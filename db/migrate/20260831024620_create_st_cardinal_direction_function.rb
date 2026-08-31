class CreateStCardinalDirectionFunction < ActiveRecord::Migration[8.0]
  def up
    #  Inject your custom azimuth-to-compass conversion function into PostgreSQL
    execute <<~SQL
      CREATE OR REPLACE FUNCTION ST_CardinalDirection(azimuth float8)
      RETURNS varchar AS $$
      BEGIN
        -- Guard against null or missing inputs gracefully
        IF azimuth IS NULL THEN
          RETURN NULL;
        END IF;

        -- Group azimuth degrees into standard 45-degree compass vectors
        RETURN CASE
          WHEN azimuth >= 337.5 OR azimuth < 22.5  THEN 'N'
          WHEN azimuth >= 22.5  AND azimuth < 67.5  THEN 'NE'
          WHEN azimuth >= 67.5  AND azimuth < 112.5 THEN 'E'
          WHEN azimuth >= 112.5 AND azimuth < 157.5 THEN 'SE'
          WHEN azimuth >= 157.5 AND azimuth < 202.5 THEN 'S'
          WHEN azimuth >= 202.5 AND azimuth < 247.5 THEN 'SW'
          WHEN azimuth >= 247.5 AND azimuth < 292.5 THEN 'W'
          WHEN azimuth >= 292.5 AND azimuth < 337.5 THEN 'NW'
          ELSE 'N'
        END;
      END;
      $$ LANGUAGE plpgsql IMMUTABLE STRICT;
    SQL
  end

  def down
    # Provide a clean rollback path to drop the function safely if needed
    execute "DROP FUNCTION IF EXISTS ST_CardinalDirection(float8);"
  end
end

