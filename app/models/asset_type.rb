# frozen_string_literal: true

# typed: strict
class AssetType < ActiveRecord::Base

def self.all_allow_multi?(pnp_classes)
  return true if pnp_classes.blank?
  sql = <<-SQL
     SELECT NOT EXISTS (
      select 1 from 
      unnest(ARRAY[:pnp_classes]) AS c1(pnp_class)
      -- 2. Look for combinations that are MISSING from the asset_types table
      LEFT JOIN asset_types at
        ON (at.pnp_class = c1.pnp_class AND at.allow_multi=true)
      WHERE at.pnp_class IS NULL  -- Filters for missing records
    ) as result;
  SQL
  # 2. Bind the variables safely (Double-check that start_time and zone are not nil)
  sanitized_sql = sanitize_sql_array([sql, { pnp_classes: pnp_classes }])

  # 3. Pull raw string text directly from the execution block
  result = connection.select_all(sanitized_sql)

  result.first["result"]
end

end
