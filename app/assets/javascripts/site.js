LINZ_API_KEY='d01gerrwb5fqmwwhpx3s65p62hj'
var site_map_size=1;
var contacts_layer;
var site_show_polygon=true;
var site_map_pinned=false;
var site_show_controls=true;
var site_back = false;
var refreshInterval;
var currZoom;

//callback variabkles
var site_select_row;
var site_select_code_dest;
var site_select_name_dest;
var site_select_loc_dest;
var site_select_x_dest;
var site_select_y_dest;
var site_select_append=false;
var site_current_style=null;
var site_current_click_layer=null;

//layers
var polygon_layer;
var polygon_simple_layer;
var polygon_detail_layer;
var points_layer;
var site_map_layers={}
var site_default_point_layers=['lake','island','summit']
var site_all_point_layers=['park', 'hut','island','summit','lake']
var site_default_polygon_layers=[]

//styles
var site_docland_style;
var site_island_style;
var site_lake_style;
var site_lake_point_style;
var site_island_point_style;
var site_parks_style;
var site_beacon_style;
var site_huts_style;
var site_summits_style;
var site_contacts_style;
var site_highlight_polygon;
var site_red_polygon;
var site_green_polygon;
var site_purple_star;
var site_red_star;
var site_green_star;
var site_red_circle;;
var site_green_circle;
var site_docland_styles=[];


function site_init() {
  if(typeof(map_map)=='undefined') {
    site_init_styles();
    map_init_mapspast('map_map');
    site_add_vector_layers();
    map_map.addLayer(map_scratch_layer);
    map_add_position_layer();
    

    if(site_show_controls) {
      map_add_tooltip();
      map_on_click_activate(map_navigate_on_click_callback);
      if ($(window).width() < 960) {
        site_smaller_map();
      }
      if(typeof(def_x)!='undefined' && typeof(def_y)!='undefined') {
         var centre='POINT('+def_x+' '+def_y+')';
         map_centre(centre,'EPSG:2193');
      }
    }
    if(typeof(def_zoom)!='undefined') {
       map_zoom(def_zoom);
    }
    currZoom = map_map.getView().getZoom();
    map_map.on('moveend', function(e) {
      var newZoom = map_map.getView().getZoom();
      if (currZoom != newZoom) {
        site_zoom_end_callback(); 
        currZoom = newZoom;
      }
    });
  }
}

function site_zoom_end_callback() {
  if(document.getElementById('polygon_layers')) {
    if(map_map.getView().getZoom()<4) { document.getElementById('polygon_layers').style="color: #999999 !important; font-style: italic !important"; 
    } else {
      document.getElementById('polygon_layers').style="color: #000000; font-style: normal";
    };
    if(map_map.getView().getZoom()<2) { document.getElementById('point_layers').style="color: #999999 !important; font-style: italic !important"; 
    } else {
      document.getElementById('point_layers').style="color: #000000; font-style: normal";
    };
  };
}

function place_init(plloc, keep,style) 
{
  if (typeof(map_map)=='undefined') site_init();
  if (typeof(style)=='undefined' || style==null) style=site_purple_star;

  if (keep==0) map_clear_scratch_layer();
  if(plloc && plloc.length>0) {
    map_add_feature_from_wkt(plloc, 'EPSG:4326',style);
    if (site_map_pinned==false) map_centre(plloc,'EPSG:4326');
  }
  map_map.updateSize();
}

function park_init(plloc,keep,cntloc) {
  if (typeof(map_map)=='undefined') site_init();

  if (keep==0) map_clear_scratch_layer();
  if(plloc && plloc.length>0) {
    if (cntloc==null) cntloc=map_get_centre_of_geom(plloc);
  }
  if (cntloc && cntloc.length>0)  map_add_feature_from_wkt(cntloc, 'EPSG:4326',site_purple_star);
  if (plloc && plloc.length>0)  map_add_feature_from_wkt(plloc, 'EPSG:4326',site_highlight_polygon);
  if (site_map_pinned==false) map_centre(cntloc,'EPSG:4326');
  
  map_map.updateSize();
}

function site_smaller_map() {
//  document.getElementById('map_map').style.display="none";
  if (site_map_size==1) {
    $('#left_panel').toggleClass('span5 span0');
    $('#right_panel').toggleClass('span7 span12');
    $('#actionbar').toggleClass('span7 span12');
    document.getElementById('left_panel').style.display="none";
    site_map_size=0;
    if (document.getElementById('larger_map')) {
      document.getElementById('larger_map').style.display="contents";
      document.getElementById('smaller_map').style.display="none";
    }
  }
  if (site_map_size==2) {
    document.getElementById('right_panel').style.display="block";
    $('#left_panel').toggleClass('span12 span5');
    $('#right_panel').toggleClass('span0 span7');
    $('#actionbar').toggleClass('span0 span7');
    site_map_size=1;
    if (document.getElementById('larger_map')) {
      document.getElementById('larger_map').style.display="contents";
      document.getElementById('smaller_map').style.display="contents";
    }
  }

  setTimeout( function() {
    map_map.updateSize();
    document.getElementById('map_map').style.display="block";
    setTimeout( function() { map_map.updateSize(); }, 1000);
    map_map.updateSize();
    if(typeof(hot)=="object") {
       hot.render()
    }
  }, 200);

  return false ;

}

function toggle_map() {
   if (site_map_size<1) {
     site_bigger_map();
   } else {
     site_smaller_map();
   }
}

function site_bigger_map() {
  if (site_map_size==1) {
    $('#left_panel').toggleClass('span5 span12');
    $('#right_panel').toggleClass('span7 span0');
    $('#actionbar').toggleClass('span7 span0');
  setTimeout( function() {document.getElementById('right_panel').style.display="none";}, 100);
    site_map_size=2;
    document.getElementById('larger_map').style.display="none";
    document.getElementById('smaller_map').style.display="contents";
  }

  if (site_map_size==0) {
   // document.getElementById('map_map').style.display="none";
    $('#left_panel').toggleClass('span0 span5');
    $('#right_panel').toggleClass('span12 span7');
    $('#actionbar').toggleClass('span12 span7');
    site_map_size=1;
    document.getElementById('left_panel').style.display="block";
    document.getElementById('larger_map').style.display="contents";
    document.getElementById('smaller_map').style.display="contents";
  }
  setTimeout( function() {
    map_map.updateSize();
    document.getElementById('map_map').style.display="block";
    setTimeout( function() { map_map.updateSize(); }, 1000);
    map_map.updateSize();
    if(typeof(hot)=="object") {
       hot.render()
    }
  }, 200);
  return false ;
}

function reset_map_controllers(keep) {
  //clearInterval(refreshInterval);

  document.body.classList.remove("loading");

//deactiavte all other click controllers
  if(typeof(map_map)=='undefined') {
     site_init();
  }
     deactivate_all_click();
     map_on_click_activate(map_navigate_on_click_callback);
     if (keep!=1) map_clear_scratch_layer();
     map_scratch_layer.setVisible(true);
     // toggle visible layers to default
     map_map.updateSize();

//set status icon to show click to navigate
}

function deactivate_all_click() {

  if(typeof(map_map)!='undefined') map_on_click_deactivate(map_navigate_on_click_callback);
//  if(typeof(map_map)!='undefined') map_on_click_deactivate(site_select_point_on_click_callback);
  map_disable_draw();

  //set status icon to show blank
}

function site_polygon_style_function(feature, resoluton) {
  if(feature.get('asset_type')=="island")  return site_island_style;
  if(feature.get('asset_type')=="lake")  return site_lake_style;
  if(feature.get('asset_type')=="park")  return site_docland_style_function(feature, resoluton);
  if(feature.get('asset_type')=="pota park")  return site_pota_style;
  if(feature.get('asset_type')=="wwff park")  return site_wwff_style;
}

function site_docland_style_function(feature, resoluton) {
  if(feature.get('category')=="DOC")  return site_docland_styles[1];
  return site_docland_styles[2];
}

function site_points_style_function(feature, resoluton) {
  if(feature.get('asset_type')=="hut")  return site_huts_style;
  if(feature.get('asset_type')=="lake")  return site_lake_point_style;
  if(feature.get('asset_type')=="island")  return site_island_point_style;
  if(feature.get('asset_type')=="summit")  return site_summits_style;
  if(feature.get('asset_type')=="lighthouse")  return site_beacon_style;
  if(feature.get('asset_type')=="park")  return site_park_point_style;
  if(feature.get('asset_type')=="pota park")  return site_pota_point_style;
  if(feature.get('asset_type')=="wwff park")  return site_wwff_point_style;
}


function site_add_vector_layers() {
  site_set_map_filters('polygon',site_default_polygon_layers);
  polygon_layer=map_add_vector_layer("Polygon", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota2.map", "polygon",site_polygon_style_function,true,12,15,'polygon');
  polygon_simple_layer=map_add_vector_layer("Polygon Simple", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota2.map", "polygon_simple",site_polygon_style_function,true,9,12,'polygon');
  polygon_detail_layer=map_add_vector_layer("Polygon Detail", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota2.map", "polygon_detail",site_polygon_style_function,true,15,32,'polygon');

  site_set_map_filters('point',site_default_point_layers);
  points_layer=map_add_vector_layer("Points", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota2.map", "points",site_points_style_function,true,7,32,'point');
  contacts_layer=map_add_vector_layer("Contacts", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota2.map", "contacts",site_contacts_style,false,1,32);

  map_map.addLayer(polygon_layer);
  map_map.addLayer(polygon_simple_layer);
  map_map.addLayer(polygon_detail_layer);
  map_map.addLayer(points_layer);
  map_map.addLayer(contacts_layer);
}

function site_set_map_filters(filter, list) {
  var filterstring="";
  if(list.length>1) {filterstring="<OR>"};
  list.forEach(function(element,index) { filterstring=filterstring+"<PropertyIsEqualTo><PropertyName>asset_type</PropertyName><Literal>"+element+"</Literal></PropertyIsEqualTo>";});
  if(list.length>1) {filterstring=filterstring+"</OR>"};
  if(list.length==0) {filterstring="<PropertyIsEqualTo><PropertyName>asset_type</PropertyName><Literal>donotmatch</Literal></PropertyIsEqualTo>"};
  map_filters[filter]=filterstring;
  site_map_layers[filter]=list;
}

function site_add_layers() {
        map_add_raster_layer('NZTM Topo 2019', 'https://s3-ap-southeast-2.amazonaws.com/au.mapspast.org.nz/topo50-2019/{z}/{x}/{-y}.png', 'mapspast', 4891.969809375, 11);
        map_add_raster_layer('Public Access Land', 'https://s3-ap-southeast-2.amazonaws.com/au.mapspast.org.nz/pal-2193/{z}/{x}/{-y}.png', 'mapspast', 4891.969809375, 11);
        map_add_raster_layer('(LINZ) Topo50 latest','http://tiles-a.data-cdn.linz.govt.nz/services;key=d8c83efc690a4de4ab067eadb6ae95e4/tiles/v4/layer=767/EPSG:2193/{z}/{x}/{y}.png','linz',8690, 17);
        map_add_raster_layer('(LINZ) Airphoto latest','https://basemaps.linz.govt.nz/v1/tiles/aerial/2193/{z}/{x}/{y}.png?api='+LINZ_API_KEY,'linz',8690, 17);



}

function site_add_controls() {
   if(site_show_controls) {

        map_create_control("/assets/layers24.png","Select layers",site_mapLayers,"mapLayers");
        map_create_control("/assets/cog24.png","Configure map",site_mapKey,"mapKey");
        map_create_control("/assets/pin24.png","Pin map (do not automatically recentre)",site_pinMap,"mapPin");
        map_create_control("/assets/target24.png","Centre map on current item",site_centreMap,"mapCentre");
        map_create_control("/assets/location.png","Show current position",site_show_position,"mapPosition");
  }
}


function site_init_styles() {
  site_blue_dot=map_create_style("circle", 4, "#2222ff", "#22ffff", 1);
  site_red_circle=map_create_style("circle", 5, "#ff2222", "#880000", 1);
  site_green_circle=map_create_style("circle", 5, "#22ff22", "#008800", 1);
  site_purple_star=map_create_style("star", 10, "#8b008b", "#8b008b", 1);
  site_red_star=map_create_style("star", 10, "#990000","#990000", 1);
  site_green_star=map_create_style("star", 10, "#009900", "#009900", 1);
  site_red_line=map_create_style("", null, "#990000", "#990000", 4);
  site_docland_style=map_create_style("", null, 'rgba(0,128,0,0.4)', "#005500", 2);
  site_linz_style=map_create_style("", null, 'rgba(0,0,0,0)', "#550055", 2);
  site_parks_style=map_create_style("", null, 'rgba(256,140,0,0.4)', "#331f00", 2);
  site_island_style=map_create_style("", null, 'rgba(256,256,0,0.4)', "#ff8c00", 2);
  site_lake_style=map_create_style("", null, 'rgba(0,128,255,0.4)', "#0066aa", 2);
  site_huts_style=map_create_style("circle", 3, "#2222ff", "#22ffff", 1);
  site_park_point_style=map_create_style("x", 6, "#00aa00", "#22dd22", 1);
  site_pota_point_style=map_create_style("x", 6, "#770077", "#770077", 1);
  site_wwff_point_style=map_create_style("x", 6, "#994499", "#994499", 1);
  site_island_point_style=map_create_style("triangle", 4, "#ff8c00", "#ff8c00", 1);
  site_lake_point_style=map_create_style("x", 6, "#0000ff", "#0000dd", 1);
  site_beacon_style=map_create_style("triangle", 6, "#ffff00", "#ffff00", 1);
  site_summits_style=map_create_style("triangle", 4, "#6c0dc4", "#6c0dc4", 1);
  site_contacts_style=map_create_style("circle", 4, "#2222ff", "#22ffff", 1);
  site_highlight_polygon=map_create_style("", null, 'rgba(128,0,0,0.3)', "#660000", 2);
  site_red_polygon=map_create_style("", null, 'rgba(256,0,0,0.6)', "#880000", 2);
  site_green_polygon=map_create_style("", null, 'rgba(0,256,0,0.6)', "#008800", 2);
  site_pota_style=map_create_style('',0, 'rgba(128,0,128,0.2)', "#900090", 2);
  site_wwff_style=map_create_style('',0, 'rgba(150,30,150,0.2)', "#901090", 2);
  site_docland_styles[1]=map_create_style('',0, 'rgba(0,128,0,0.2)', "#005500", 2);
  site_docland_styles[2]=map_create_style('',0, 'rgba(128,255,128,0.2)', "#20a020", 1);

}



function site_mapKey() {
        BootstrapDialog.show({
            title: "Map options",
            message: $('<div id="info_details2">Retrieving ...</div>'),
            size: "size-small"
        });

        $.ajax({
          beforeSend: function (xhr){
            xhr.setRequestHeader("Content-Type","application/javascript");
            xhr.setRequestHeader("Accept","text/javascript");
          },
          type: "GET",
          timeout: 60000,
          url: "/legend?projection="+map_current_proj,
          error: function() {
              document.getElementById("info_details2").innerHTML = 'Error contacting server';
          },
          complete: function() {
              document.getElementById("page_status").innerHTML = '';
          }
        });
}

function site_show_position() {
  if(map_show_position==0) {
     document.getElementById("mapPosition").style.backgroundColor="#008800"
  } else {
     document.getElementById("mapPosition").style.backgroundColor="#ffffff"
  }
  map_enable_tracking();

}

function site_pinMap() {
  if(site_map_pinned==0) {
     site_map_pinned=1;
     document.getElementById("mapPin").style.backgroundColor="#008800"
  } else {
     site_map_pinned=0;
     document.getElementById("mapPin").style.backgroundColor="#ffffff"
  }
}

function site_centreMap() {
  map_centre(map_last_centre,'EPSG:4326');

}

function site_navigate_to(url) {
  if(url.length>0) {
        document.body.classList.add("loading");
        document.getElementById("page_status").innerHTML = 'Loading ...';

        $.ajax({
          beforeSend: function (xhr){
            xhr.setRequestHeader("Content-Type","application/javascript");
            xhr.setRequestHeader("Accept","text/javascript");
          },
          type: "GET",
          timeout: 60000,
          url: '/'+url,
          complete: function() {
              /* complete also fires when error ocurred, so only clear if no error has been shown */
              if(site_map_size==2) site_smaller_map();
              document.getElementById("page_status").innerHTML = '';
          }

        });
      }
}

function site_drawPlace(disable_icon, enable_icon, place_loc, place_x, place_y,style) {
  if (typeof(style)=='undefined' || style==null) {
     style=site_purple_star;
  } 
     
  if(site_map_size==0) {
      site_bigger_map();
  }
  deactivate_all_click();
  document.getElementById(enable_icon).style.display="none";
  document.getElementById(disable_icon).style.display="block";

  //map_clear_scratch_layer();
  map_enable_draw("Point",style,place_loc, place_x ,place_y  ,true);
}

function drawBoundary(disable_icon, enable_icon, place_loc) {
  if(site_map_size==0) {
     site_bigger_map();
  }

  /*point_selectNothing();*/
  deactivate_all_click();

  document.getElementById(enable_icon).style.display="none";
  document.getElementById(disable_icon).style.display="block";
  //map_clear_scratch_layer();
  map_enable_draw("Polygon",site_highlight_polygon,place_loc, null, null  ,true);
}

function site_selectPlace(row, code_loc, name_loc, location_loc, x_loc, y_loc, disable_icon, enable_icon, style, append,asset_type) {
  deactivate_all_click();
  if(enable_icon!=null) document.getElementById(enable_icon).style.display="none";
  if(disable_icon!=null) document.getElementById(disable_icon).style.display="block";

  map_on_click_activate(site_select_point_on_click_callback);

  site_select_row=row;
  site_select_code_dest=code_loc;
  site_select_name_dest=name_loc;
  site_select_loc_dest=location_loc;
  site_select_x_dest=x_loc;
  site_select_y_dest=y_loc;
  site_current_click_layer=asset_type;
  site_current_style=style;
  if(append==true) {site_select_append=true } else {site_select_append=false};
}

function site_selectSummit(row, id_loc, name_loc, location_loc, x_loc, y_loc, disable_icon, enable_icon, style) {
  deactivate_all_click();
  site_toggle_huts(false);
  site_toggle_summits(true);
  site_toggle_docland(false);
  site_toggle_island(0);
  if(enable_icon!=null) document.getElementById(enable_icon).style.display="none";
  if(disable_icon!=null) document.getElementById(disable_icon).style.display="block";

  map_on_click_activate(site_select_point_on_click_callback);

  site_select_row=row;;
  site_select_id_dest=id_loc;
  site_select_name_dest=name_loc;
  site_select_loc_dest=location_loc;
  site_select_x_dest=x_loc;
  site_select_y_dest=y_loc;
  site_current_click_layer='Summits';
  site_current_style=style;
}

function site_selectPark(row, id_loc, name_loc, disable_icon, enable_icon, style) {
  deactivate_all_click();
  if(enable_icon!=null) document.getElementById(enable_icon).style.display="none";
  if(disable_icon!=null) document.getElementById(disable_icon).style.display="block";

  site_toggle_huts(false);
  site_toggle_summits(false);
  site_toggle_docland(true);
  site_toggle_island(0);

  map_on_click_activate(site_select_point_on_click_callback);

  site_select_row=row;
  site_select_id_dest=id_loc;
  site_select_name_dest=name_loc;
  site_select_loc_dest=null;
  site_select_x_dest=null;
  site_select_y_dest=null;
  site_current_click_layer='Parks';
  site_current_style=style;
}

function site_selectIsland(row, id_loc, name_loc, disable_icon, enable_icon, style) {
  deactivate_all_click();
  if(enable_icon!=null) document.getElementById(enable_icon).style.display="none";
  if(disable_icon!=null) document.getElementById(disable_icon).style.display="block";

  site_toggle_huts(false);
  site_toggle_summits(false);
  site_toggle_docland(false);
  site_toggle_island(2);

  map_on_click_activate(site_select_point_on_click_callback);

  site_select_row=row;;
  site_select_id_dest=id_loc;
  site_select_name_dest=name_loc;
  site_select_loc_dest=null;
  site_select_x_dest=null;
  site_select_y_dest=null;
  site_current_click_layer='Island';
  site_current_style=style;
}

function site_selectNothing(disable_icon, enable_icon) {
  document.getElementById(enable_icon).style.display="block";
  document.getElementById(disable_icon).style.display="none";
  deactivate_all_click();
  site_select_name_dest=null
  site_select_id_dest=null;
  site_select_loc_dest=null;
  site_select_x_dest=null;
  site_select_y_dest=null;
  site_current_style=null;
}

function site_select_point_on_click_callback(evt) {
    var pixel = evt.pixel;
    var wktp = new ol.format.WKT;   //should be handled in map, not here
    var feature = map_map.forEachFeatureAtPixel(pixel, function(feature, layer) {
      if((!site_current_click_layer||(feature.get('asset_type').substr(0,site_current_click_layer.length)==site_current_click_layer)) && feature.get('is_active')) {
         return feature;
      } else {
         return null;
      }
    });
    
    if(feature) {
      debug_f=feature;
        //now copy it to where we want it 
      if(site_select_row!=null) {
        if(site_select_name_dest!=null) data2[site_select_row][site_select_name_dest]=feature.get('name');
        data2[site_select_row]['loc_desc2']=feature.get('name');
        if(site_select_code_dest!=null) data2[site_select_row][site_select_code_dest]=feature.get('code');
        if(site_select_loc_dest!=null) data2[site_select_row][site_select_loc_dest]=wktp.writeFeature(feature, { dataProjection: 'EPSG:4326', featureProjection: 'EPSG:2193'});
        if(site_select_x_dest!=null) data2[site_select_row][site_select_x_dest]=feature.getGeometry().getCoordinates()[0];
        if(site_select_y_dest!=null) data2[site_select_row][site_select_y_dest]=feature.getGeometry().getCoordinates()[1];
        hot.render();
      } else {
        if(site_select_append) {
          if(site_select_name_dest!=null) {
            names=document.getElementById(site_select_name_dest).innerHTML;
            if(names.length>0) { names=names+"<br/>";}
            document.getElementById(site_select_name_dest).innerHTML=names+"["+feature.get('code')+"] "+feature.get('name');
          }
          if(site_select_code_dest!=null) {
            codes=document.getElementById(site_select_code_dest).value;
            if(codes.length>0) { codes=codes+",";}
            document.getElementById(site_select_code_dest).value=codes+feature.get('code');
          }
        } else {
          if(site_select_name_dest!=null)  document.getElementById(site_select_name_dest).value=feature.get('name');
          if(site_select_code_dest!=null)  document.getElementById(site_select_code_dest).value=feature.get('code');
        }
        if(site_select_loc_dest!=null) document.getElementById(site_select_loc_dest).value=wktp.writeFeature(feature, { dataProjection: 'EPSG:4326', featureProjection: 'EPSG:2193'});
        if(site_select_x_dest!=null) document.getElementById(site_select_x_dest).value=feature.getGeometry().getCoordinates()[0];
        if(site_select_y_dest!=null) document.getElementById(site_select_y_dest).value=feature.getGeometry().getCoordinates()[1];
      }
      debug_f=feature;
      //now mark it on map
      if(site_current_style!=null) {
           map_clear_scratch_layer(null, site_current_style);
           f2=feature.clone();
           f2.setStyle(site_current_style);
           map_add_feature(f2);
      }
    }
}   
   
function closeAllHandlers() {
    BootstrapDialog.closeAll();
    document.body.classList.remove("loading");
    document.getElementById("page_status").innerHTML = ''
}

function submitHandler(entity_name) {
    document.body.classList.add("loading");
    document.getElementById("page_status").innerHTML = 'Loading ...'
}

function linkHandler(entity_name) {
    clearTimeout(refreshInterval);

    if(entity_name=='back_link') {
      site_back=true;
      history.back();
    } else {
       site_back=false;
    } 
    dialog=true;
    /* close the dropdown */
    $('.dropdown').removeClass('open');

    document.body.classList.add("loading");

    document.getElementById("page_status").innerHTML = 'Loading ...'

    $(function() {
     $.rails.ajax = function (options) {
       options.tryCount= (!options.tryCount) ? 0 : options.tryCount;0;
       options.timeout = 60000*(options.tryCount+1);
       options.retryLimit=0;
       options.complete = function(jqXHR, thrownError) {
         /* complete also fires when error ocurred, so only clear if no error has been shown */
         if(thrownError=="timeout") {
           this.tryCount++;
           document.getElementById("page_status").innerHTML = 'Retrying ...';
           this.timeout=60000*this.tryCount;
           if(this.tryCount<=this.retryLimit) {
             $.rails.ajax(this);
           } else {
             document.getElementById("page_status").innerHTML = 'Timeout';
             document.body.classList.remove("loading");
             BootstrapDialog.show({
               title: "Loading",
               message: $('<div id="page_status2">Timeout</div>'),
               size: "size-small"
             });
           }
         }
         if(thrownError=="error") {
           document.getElementById("page_status").innerHTML = 'Error: '+jqXHR.status;
           document.body.classList.remove("loading");
           BootstrapDialog.show({
             title: "Loading",
             message: $('<div id="page_status2">Error: '+jqXHR.status+'</div>'),
             size: "size-small"
           });

         }
         if(thrownError=="success") {
           //if(site_map_size==0) site_bigger_map();
           document.getElementById("page_status").innerHTML = ''
           document.body.classList.remove("loading");
         }
         lastUrl=document.URL;
       }
       return $.ajax(options);
     };
   });
}

function site_clear_element(formids) {
  var length=formids.length;
  for(var count=0;count<length;count++) {  
    document.getElementById(formids[count]).value='';
  }
}
function site_clear_html_element(htmlids) {
  var length=htmlids.length;
  for(var count=0;count<length;count++) {  
    document.getElementById(htmlids[count]).innerHTML='';
  }
}

function site_clear_elementData(row,cols) {
  for (col = 0; col < cols.length; col++ ) {
    if(Array.isArray(data2[row][cols[col]])) {
      data2[row][cols[col]]=[];
    } else {
      data2[row][cols[col]]='';
    }
  }
 hot.render();
}



function search_islands(field) {
        BootstrapDialog.show({
            title: "Select island",
            message: $('<div id="info_details2">Retrieving ...</div>'),
            size: "size-small"
        });

        $.ajax({
          beforeSend: function (xhr){
            xhr.setRequestHeader("Content-Type","application/javascript");
            xhr.setRequestHeader("Accept","text/javascript");
          },
          type: "GET",
          timeout: 60000,
          url: "/queryisland?islandfield="+field,
          error: function() {
              document.getElementById("info_details2").innerHTML = 'Error contacting server';
          },
          complete: function() {
              document.getElementById("page_status").innerHTML = '';
          }

        });
 return(false);
}

function search_parks(field) {
        BootstrapDialog.show({
            title: "Select park",
            message: $('<div id="info_details2">Retrieving ...</div>'),
            size: "size-small"
        });

        $.ajax({
          beforeSend: function (xhr){
            xhr.setRequestHeader("Content-Type","application/javascript");
            xhr.setRequestHeader("Accept","text/javascript");
          },
          type: "GET",
          timeout: 60000,
          url: "/querypark?parkfield="+field,
          error: function() {
              document.getElementById("info_details2").innerHTML = 'Error contacting server';
          },
          complete: function() {
              document.getElementById("page_status").innerHTML = '';
          }

        });
 return(false);
}
function submit_search() {
   document.getElementById("info_results2").innerHTML = 'Searching...';

   return false;
}

function select_asset(field, code, name, x, y, loc, child_codes, child_names) {
  if (typeof(document.contactform)=="object")  { 
     formname="contactform";
     varprefix="contact_";
  } 
  if (typeof(document.postform)=="object")  { 
     formname="postform";
     varprefix="post_";
  }
  if (typeof(document.logform)=="object")  { 
     formname="logform";
     varprefix="log_";
  }
  if (field=='child') {
     formname="childform";
     varprefix="c_asset_link_";
  }
  if (field=='parent') {
     formname="parentform";
     varprefix="p_asset_link_";
  }

  if (field=="asset") {
    codes=document[formname][varprefix+"asset_codes"].value
    if(codes=="{}") {codes="";} 
    if(codes=="[]") {codes="";} 
    if(codes && codes.length>0) {codes=codes+","};
    document[formname][varprefix+"asset_codes"].value=codes+code;
    names=document.getElementById('asset_names').innerHTML;
    if(names && names.length>0) {names=names+"<br/>"};
    document.getElementById('asset_names').innerHTML=names+"["+code+"] "+name;
    document[formname][varprefix+"x1"].value=x;
    document[formname][varprefix+"y1"].value=y;
    document[formname][varprefix+"location1"].value=loc;
    //document[formname][varprefix+"child_codes"].value=child_codes;
    //document.getElementsById["child_names"].innerHTML=child_names;
    map_clear_scratch_layer('Point', site_green_star);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_green_star) ;
  }
  if (field=="child") {
    document[formname][varprefix+"child_code"].value=code;
    document[formname][varprefix+"child_name"].value=name;
    map_clear_scratch_layer('Point', site_red_star);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_red_star) ;
  }
  if (field=="parent") {
    document[formname][varprefix+"parent_code"].value=code;
    document[formname][varprefix+"parent_name"].value=name;
    map_clear_scratch_layer('Point', site_red_star);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_red_star) ;
  }
  if (field.substr(0,3)=="row") {
    row=field.substr(4,1000)
    if(data2[row]['asset2_codes']==null) {data2[row]['asset2_codes']=[code];} else {
    codes=data2[row]['asset2_codes'].push(code) 
 }
    names=data2[row]['asset2_names']
    if(names=='null'||name=='undefined') {names=""};
    if(names && names.length>0) {names=names+"\n"};
    data2[row]['asset2_names']=names+"["+code+"] "+name;
    data2[row]['location2']=loc;
    data2[row]['x2']=x;
    data2[row]['y2']=y;
    //data2[row]['park2_id']=child_codes;
    //data2[row]['park2_tn']=child_names;
    //data2[row]['loc_desc2']=name+" ("+park_name+")"
    map_clear_scratch_layer('Point', site_red_star);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_red_star) ;
    hot.render();
  }
  return false;
}


function search_assets(field) {
        BootstrapDialog.show({
            title: "Select",
            message: $('<div id="info_details2">Retrieving ...</div>'),
            size: "size-small"
        });

        $.ajax({
          beforeSend: function (xhr){
            xhr.setRequestHeader("Content-Type","application/javascript");
            xhr.setRequestHeader("Accept","text/javascript");
          },
          type: "GET",
          timeout: 60000,
          url: "/query?assetfield="+field,
          error: function() {
              document.getElementById("info_details2").innerHTML = 'Error contacting server';
          },
          complete: function() {
              document.getElementById("page_status").innerHTML = '';
          }

        });
 return(false);
}

function search_summits(field) {
        BootstrapDialog.show({
            title: "Select summit",
            message: $('<div id="info_details2">Retrieving ...</div>'),
            size: "size-small"
        });

        $.ajax({
          beforeSend: function (xhr){
            xhr.setRequestHeader("Content-Type","application/javascript");
            xhr.setRequestHeader("Accept","text/javascript");
          },
          type: "GET",
          timeout: 60000,
          url: "/querysummit?summitfield="+field,
          error: function() {
              document.getElementById("info_details2").innerHTML = 'Error contacting server';
          },
          complete: function() {
              document.getElementById("page_status").innerHTML = '';
          }

        });
 return(false);
}

   function clickplus(divname) {
     document.getElementById(divname).style.display = 'block';
     document.getElementById(divname+"plus").style.display="none";
     document.getElementById(divname+"minus").style.display="block";
   }


   function clickminus(divname) {
     document.getElementById(divname).style.display = 'none';
     document.getElementById(divname+"plus").style.display="block";
     document.getElementById(divname+"minus").style.display="none";
   }

   function updatexy(value) {
     id=document.contactform.contact_hut1_id.value.split(',')[0];
     x=document.contactform.contact_hut1_id.value.split(',')[1];
     y=document.contactform.contact_hut1_id.value.split(',')[2];

     document.contactform.contact_x1.value=x;
     document.contactform.contact_y1.value=y;
   }

function site_mapLayers() {
        BootstrapDialog.show({
            title: "Select layers",
            message: $('<div id="info_details2">Retrieving ...</div>'),
            size: "size-small"
        });

        $.ajax({
          beforeSend: function (xhr){
            xhr.setRequestHeader("Content-Type","application/javascript");
            xhr.setRequestHeader("Accept","text/javascript");
          },
          type: "GET",
          timeout: 60000,
          url: "/layerswitcher?baselayer="+map_current_layer+"&pointlayers=["+site_map_layers.point+"]&polygonlayers=["+site_map_layers.polygon+"]",
          error: function() {
              document.getElementById("info_details2").innerHTML = 'Error contacting server';
          },
          complete: function() {
               site_zoom_end_callback();


//              document.getElementById("page_status").innerHTML = '';
          }

        });

}


function site_toggle_vector_layers(filter, layer) {  
  if(site_map_layers[filter].includes(layer)) {
    for( var i = 0; i < site_map_layers[filter].length; i++){ 
        if ( site_map_layers[filter][i] === layer) { 
            site_map_layers[filter].splice(i, 1); 
        }
    }
  } else {
    site_map_layers[filter].push(layer);
  }; 
  site_set_map_filters(filter,site_map_layers[filter]);
}

function site_clear_vector_layers(filter, layer) { 
  site_map_layers[filter]=[];
}

function site_set_vector_layers(filter, layer, value) { 
  if(site_map_layers[filter].includes(layer)) {
    for( var i = 0; i < site_map_layers[filter].length; i++){
        if ( site_map_layers[filter][i] === layer) {
            site_map_layers[filter].splice(i, 1);
        }
    }
  } 
 
  if(value) {
    site_map_layers[filter].push(layer);
  };

  site_set_map_filters(filter,site_map_layers[filter]);
}

function site_refresh_layer(filter) {
  if (filter=='point') {
    setTimeout( function() { points_layer.getSource().clear(); }, 1000);
  } else {
    setTimeout( function() { polygon_layer.getSource().clear();polygon_simple_layer.getSource().clear();
      polygon_detail_layer.getSource().clear();
    }, 1000);
  };

}

function expand_div(divname) {
     if (document.getElementById(divname).style.display == 'block') {
       document.getElementById(divname).style.display = 'none';
     } else {
       document.getElementById(divname).style.display = 'block';
     };
  return(false);
}

function show_div(div) {
   document.getElementById(div).style.display="block";
}
function hide_div(div) {
   document.getElementById(div).style.display="none";
}

