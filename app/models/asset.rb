class Asset 

   include ActiveModel::Model

def self.url_from_code(code)
  url=nil
  external=false
  if code[0..4]=="VKFF-" then
    #wwff - VK
    url="https://parksnpeaks.org/getPark.php?actPark="+code[0..8]+"&submit=Process"
    external=true
  elsif code[0..4]=="ZLFF-" then
    #wwff - NZ
    pp=WwffPark.find_by(code: code[0..8])
    if pp then url="/parks/"+pp.napalis_id.to_s end
  elsif code[0..2]=="ZL-" then
    #POTA NZ
    pp=PotaPark.find_by(reference: code[0..6])
    if pp then url="/parks/"+pp.park_id.to_s end
  elsif code[0..2]=="VK-" then
    #POTA VK
    url="https://parksnpeaks.org/getPark.php?actPark="+code[0..6]+"&submit=Process"
    external=true
  elsif code[0..3]=="ZLP/" then
    #ZLOTA Park
    park=Park.find_by(id: code[4..10])
    if park then url="/parks/"+park.id.to_s end
  elsif code[0..3]=="ZLH/" then
    #ZLOTA hut
    hut=Hut.find_by(id: code[4..7])
    if hut then url="/huts/"+hut.id.to_s end
  elsif code[0..3]=="ZLI/" then
    #ZLOTA island
    island=Island.find_by(id: code[4..8])
    if island then url="/islands/"+island.id.to_s end
  elsif code.scan(/ZL\d\//).length>0 then
    #NZ SOTA
    summit=SotaPeak.find_by(summit_code: code[0..9])
    if summit then url="/summits/"+summit.short_code end
  elsif code.scan(/VK\d\//).length>0 then
    #VK SOTA
    url="https://summits.sota.org.uk/summit/"+code[0..10]
    external=true
  end
  {url: url, external: external}
end

end
