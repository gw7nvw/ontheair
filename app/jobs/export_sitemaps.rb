module ExportSitemaps

  @queue = :ota_scheduled
  def self.perform
     export_sitemap
  end

  def self.export_sitemap
    File.open('public/sitemap.xml', 'w') do |file|
    xml = Builder::XmlMarkup.new(target: file, indent: 2)
    xml.instruct!
    static_paths = ['/']
     
    xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
      static_paths.each do |path|
        xml.url do
          xml.loc "https://ontheair.nz#{path}"
          xml.changefreq("monthly")
          xml.priority("0.9")
        end
      end
      Asset.where(is_active: true)
        .where.not(minor: true)
        .select(:id, :safecode, :updated_at)
        .find_each(batch_size: 1000) do |asset|
          xml.url do
            xml.loc "https://ontheair.nz/assets/#{asset.safecode}"
            xml.lastmod asset.updated_at.strftime("%F")
            xml.changefreq("yearly")
            xml.priority("1.0")
          end
        end
      end
    end
  end
end
