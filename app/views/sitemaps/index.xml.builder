# app/views/sitemaps/index.xml.builder
xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
  @static_paths.each do |path|
    xml.url do
      xml.loc "#{root_url}#{path}"
      xml.changefreq("monthly")
      xml.priority("0.9")
    end
  end
  @assets.each do |asset|
    xml.url do
      xml.loc "#{root_url}assets/#{asset.safecode}"
      xml.lastmod asset.updated_at.strftime("%F")
      xml.changefreq("yearly")
      xml.priority("1.0")
    end
  end
end
