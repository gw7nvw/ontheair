module RgeoHelper
    def wgs84_proj4
        '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'
    end

    def nztm_proj4
       '+proj=tmerc +lat_0=0 +lon_0=173 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'
    end
    
    def wgs84_factory
        RGeo::Geographic.spherical_factory(:srid => 4326, :proj4 => wgs84_proj4)
    end

    def nztm_factory
        RGeo::Cartesian.factory(:srid => 2193, :proj4 => nztm_proj4)
    end

end
