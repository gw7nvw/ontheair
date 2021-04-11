var site_map_size=1;
var contacts_layer;
var site_show_docland=false;
var site_show_island=1;
var site_show_huts=true;
var site_show_summits=false;
var site_map_pinned=false;
var site_show_controls=true;

//callback variabkles
var site_select_id_dest;
var site_select_name_dest;
var site_select_loc_dest;
var site_select_x_dest;
var site_select_y_dest;
var site_current_style=null;
var site_current_click_layer=null;

//layers
var parks_layer;
var parks_simple_layer;
var parks_very_simple_layer;
var islands_layer;
var islands_simple_layer;
var islands_very_simple_layer;
var islands_point_layer;
var huts_layer;
var summits_layer;
//styles
var site_docland_style;
var site_island_style;
var site_island_point_style;
var site_parks_style;
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
    site_toggle_huts(site_show_huts);
    site_toggle_island(site_show_island);

  }
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
  document.getElementById('map_map').style.display="none";
  if (site_map_size==1) {
    $('#left_panel').toggleClass('span5 span0');
    $('#right_panel').toggleClass('span7 span12');
    $('#actionbar').toggleClass('span7 span12');
    document.getElementById('left_panel').style.display="none";
    site_map_size=0;
  }
  if (site_map_size==2) {
    document.getElementById('right_panel').style.display="block";
    $('#left_panel').toggleClass('span12 span5');
    $('#right_panel').toggleClass('span0 span7');
    $('#actionbar').toggleClass('span0 span7');
    site_map_size=1;
  }

  setTimeout( function() {
    map_map.updateSize();
    document.getElementById('map_map').style.display="block";
    setTimeout( function() { map_map.updateSize(); }, 1000);
    map_map.updateSize();
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
  document.getElementById('map_map').style.display="none";
  if (site_map_size==1) {
    $('#left_panel').toggleClass('span5 span12');
    $('#right_panel').toggleClass('span7 span0');
    $('#actionbar').toggleClass('span7 span0');
  setTimeout( function() {document.getElementById('right_panel').style.display="none";}, 100);
    site_map_size=2;
  }

  if (site_map_size==0) {
    $('#left_panel').toggleClass('span0 span5');
    $('#right_panel').toggleClass('span12 span7');
    $('#actionbar').toggleClass('span12 span7');
    document.getElementById('left_panel').style.display="block";
    site_map_size=1;
  }
  setTimeout( function() {
    map_map.updateSize();
    document.getElementById('map_map').style.display="block";
    setTimeout( function() { map_map.updateSize(); }, 1000);
    map_map.updateSize();
  }, 200);
  return false ;
}

function reset_map_controllers(keep) {

//deactiavte all other click controllers
  if(typeof(map_map)=='undefined') {
     site_init();
  }
     deactivate_all_click();
     map_on_click_activate(map_navigate_on_click_callback);
     if (keep!=1) map_clear_scratch_layer();
     map_scratch_layer.setVisible(true);
     site_toggle_docland(site_show_docland); 
     site_toggle_island(site_show_island); 
     site_toggle_huts(site_show_huts); 
     site_toggle_summits(site_show_summits); 
     map_map.updateSize();

//set status icon to show click to navigate
}

function deactivate_all_click() {

  if(typeof(map_map)!='undefined') map_on_click_deactivate(map_navigate_on_click_callback);
//  if(typeof(map_map)!='undefined') map_on_click_deactivate(site_select_point_on_click_callback);
  map_disable_draw();

  //set status icon to show blank
}

function site_docland_style_function(feature, resoluton) {
  if(feature.get('isdoc')=="t")  return site_docland_styles[1];
  return site_docland_styles[2];
}

function site_add_vector_layers() {
  parks_layer=map_add_vector_layer("Parks", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/rg_maps/rg_map.map", "parks",site_docland_style_function,false,11,32);
  parks_simple_layer=map_add_vector_layer("Parks Simple", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/rg_maps/rg_map.map", "parks_simple",site_docland_style_function,false,8,11);
  parks_very_simple_layer=map_add_vector_layer("Parks Very Simple", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/rg_maps/rg_map.map", "parks_very_simple",site_docland_style_function,false,1,8);
  islands_layer=map_add_vector_layer("Islands", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota.map", "islands",site_island_style,false,11,32);
  islands_simple_layer=map_add_vector_layer("Islands Simple", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota.map", "islands_simple",site_island_style,false,8,11);
  islands_very_simple_layer=map_add_vector_layer("Islands Very Simple", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota.map", "islands_very_simple",site_island_style,false,1,8);
  islands_point_layer=map_add_vector_layer("Island Points", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota.map", "island_points",site_island_point_style,true,1,32);
  huts_layer=map_add_vector_layer("Huts", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota.map", "huts",site_huts_style,true,1,32);
  summits_layer=map_add_vector_layer("Summits", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota.map", "summits",site_summits_style,false,1,32);
  contacts_layer=map_add_vector_layer("Contacts", "https://ontheair.nz/cgi-bin/mapserv?map=/var/www/html/hota_maps/hota.map", "contacts",site_contacts_style,false,1,32);

  map_map.addLayer(parks_layer);
  map_map.addLayer(parks_simple_layer);
  map_map.addLayer(parks_very_simple_layer);
  map_map.addLayer(islands_layer);
  map_map.addLayer(islands_simple_layer);
  map_map.addLayer(islands_very_simple_layer);
  map_map.addLayer(islands_point_layer);
  map_map.addLayer(huts_layer);
  map_map.addLayer(summits_layer);
  map_map.addLayer(contacts_layer);
}

function site_add_layers() {
        map_add_raster_layer('NZTM Topo 2019', 'https://s3-ap-southeast-2.amazonaws.com/au.mapspast.org.nz/topo50-2019/{z}/{x}/{-y}.png', 'mapspast', 4891.969809375, 11);
        map_add_raster_layer('(LINZ) Topo50 latest','http://tiles-a.data-cdn.linz.govt.nz/services;key=d8c83efc690a4de4ab067eadb6ae95e4/tiles/v4/layer=767/EPSG:2193/{z}/{x}/{y}.png','linz',8690, 17);
        map_add_raster_layer('(LINZ) Airphoto latest','http://tiles-a.data-cdn.linz.govt.nz/services;key=d8c83efc690a4de4ab067eadb6ae95e4/tiles/v4/set=2/EPSG:2193/{z}/{x}/{y}.png','linz',8690, 17);



}

function site_add_controls() {
   if(site_show_controls) {

        map_create_control("/assets/layers24.png","Select basemap",map_mapLayers,"mapLayers");
        map_create_control("/assets/doc24.png","Show DOC land",site_toggle_docland,"mapDocland");
        map_create_control("/assets/hut24.png","Show Huts",site_toggle_huts,"mapHuts");
        map_create_control("/assets/island24.png","Show Islands",site_toggle_island,"mapIsland");
        map_create_control("/assets/summit24.png","Show Summits",site_toggle_summits,"mapSummits");
        map_create_control("/assets/cog24.png","Configure map",site_mapKey,"mapKey");
        map_create_control("/assets/pin24.png","Pin map (do not automatically recentre)",site_pinMap,"mapPin");
        map_create_control("/assets/target24.png","Centre map on current item",site_centreMap,"mapCentre");
  }
}


function site_init_styles() {
  site_blue_dot=map_create_style("circle", 3, "#2222ff", "#22ffff", 1);
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
  site_huts_style=map_create_style("circle", 3, "#2222ff", "#22ffff", 1);
  site_island_point_style=map_create_style("triangle", 3, "#ff8c00", "#ff8c00", 1);
  site_summits_style=map_create_style("triangle", 3, "#6c0dc4", "#6c0dc4", 1);
  site_contacts_style=map_create_style("circle", 3, "#2222ff", "#22ffff", 1);
  site_highlight_polygon=map_create_style("", null, 'rgba(128,0,0,0.6)', "#660000", 2);
  site_red_polygon=map_create_style("", null, 'rgba(256,0,0,0.6)', "#880000", 2);
  site_green_polygon=map_create_style("", null, 'rgba(0,256,0,0.6)', "#008800", 2);
  site_docland_styles[1]=map_create_style('',0, 'rgba(0,128,0,0.4)', "#005500", 2);
  site_docland_styles[2]=map_create_style('',0, 'rgba(128,255,128,0.4)', "#20a020", 1);

}


function site_toggle_huts(show) {
  if(typeof(show)=='undefined' || show==null) {
    site_show_huts=!site_show_huts;
    show=site_show_huts;
  }
  if (site_show_controls) {
    if (show) {
       document.getElementById("mapHuts").style.backgroundColor="#008800";
    } else {
       document.getElementById("mapHuts").style.backgroundColor="#ffffff";
    }
  }

  map_toggle_layer_by_name(show,'Huts');
}
function site_toggle_summits(show) {
  if(typeof(show)=='undefined' || show==null) {
    site_show_summits=!site_show_summits;
    show=site_show_summits;
  }

  if (site_show_controls) {
  if (show) {
     document.getElementById("mapSummits").style.backgroundColor="#008800";
  } else {
     document.getElementById("mapSummits").style.backgroundColor="#ffffff";
  }
  }

  map_toggle_layer_by_name(show,'Summits');
}

function site_toggle_docland(show) {
  if(typeof(show)=='undefined' || show==null) {
    site_show_docland=!site_show_docland;
    show=site_show_docland;
  }

  if (site_show_controls) {
  if (show) {
     document.getElementById("mapDocland").style.backgroundColor="#008800";
  } else {
     document.getElementById("mapDocland").style.backgroundColor="#ffffff";
  }
  }

  map_toggle_layer_by_name(show,'Parks');
  map_toggle_layer_by_name(show,'Parks Simple');
  map_toggle_layer_by_name(show,'Parks Very Simple');
}

function site_toggle_island(show) {
  if(typeof(show)=='undefined' || show==null) {
    site_show_island=site_show_island+1;
    if(site_show_island==3) site_show_island=0;
    show=site_show_island;
  } 
  if(show>0) { 
       showpoint=true;
  } else {
       showpoint=false;
  }
  if(show>1) { 
       show=true;
  } else {
       show=false;
  }

  if (site_show_controls) {
  if (show) {
     document.getElementById("mapIsland").style.backgroundColor="#008800";
  } else {
     if (showpoint) {
       document.getElementById("mapIsland").style.backgroundColor="#ffff00";
     } else {
       document.getElementById("mapIsland").style.backgroundColor="#ffffff";
     }
  }
  }

  map_toggle_layer_by_name(show,'Islands');
  map_toggle_layer_by_name(show,'Islands Simple');
  map_toggle_layer_by_name(show,'Islands Very Simple');
  map_toggle_layer_by_name(showpoint,'Island Points');
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
          timeout: 10000,
          url: "/legend?projection="+map_current_proj,
          error: function() {
              document.getElementById("info_details2").innerHTML = 'Error contacting server';
          },
          complete: function() {
              document.getElementById("page_status").innerHTML = '';
          }
        });
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
        document.getElementById("page_status").innerHTML = 'Loading ...';

        $.ajax({
          beforeSend: function (xhr){
            xhr.setRequestHeader("Content-Type","application/javascript");
            xhr.setRequestHeader("Accept","text/javascript");
          },
          type: "GET",
          timeout: 20000,
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

function site_selectPlace(id_loc, name_loc, location_loc, x_loc, y_loc, disable_icon, enable_icon, style) {
  deactivate_all_click();
  site_toggle_huts(true);
  site_toggle_summits(false);
  site_toggle_docland(false);
  site_toggle_island(0);
  if(enable_icon!=null) document.getElementById(enable_icon).style.display="none";
  if(disable_icon!=null) document.getElementById(disable_icon).style.display="block";

  map_on_click_activate(site_select_point_on_click_callback);

  site_select_id_dest=id_loc;
  site_select_name_dest=name_loc;
  site_select_loc_dest=location_loc;
  site_select_x_dest=x_loc;
  site_select_y_dest=y_loc;
  site_current_click_layer='Huts';
  site_current_style=style;
}

function site_selectSummit(id_loc, name_loc, location_loc, x_loc, y_loc, disable_icon, enable_icon, style) {
  deactivate_all_click();
  site_toggle_huts(false);
  site_toggle_summits(true);
  site_toggle_docland(false);
  site_toggle_island(0);
  if(enable_icon!=null) document.getElementById(enable_icon).style.display="none";
  if(disable_icon!=null) document.getElementById(disable_icon).style.display="block";

  map_on_click_activate(site_select_point_on_click_callback);

  site_select_id_dest=id_loc;
  site_select_name_dest=name_loc;
  site_select_loc_dest=location_loc;
  site_select_x_dest=x_loc;
  site_select_y_dest=y_loc;
  site_current_click_layer='Summits';
  site_current_style=style;
}

function site_selectPark(id_loc, name_loc, disable_icon, enable_icon, style) {
  deactivate_all_click();
  if(enable_icon!=null) document.getElementById(enable_icon).style.display="none";
  if(disable_icon!=null) document.getElementById(disable_icon).style.display="block";

  site_toggle_huts(false);
  site_toggle_summits(false);
  site_toggle_docland(true);
  site_toggle_island(0);

  map_on_click_activate(site_select_point_on_click_callback);

  site_select_id_dest=id_loc;
  site_select_name_dest=name_loc;
  site_select_loc_dest=null;
  site_select_x_dest=null;
  site_select_y_dest=null;
  site_current_click_layer='Parks';
  site_current_style=style;
}

function site_selectIsland(id_loc, name_loc, disable_icon, enable_icon, style) {
  deactivate_all_click();
  if(enable_icon!=null) document.getElementById(enable_icon).style.display="none";
  if(disable_icon!=null) document.getElementById(disable_icon).style.display="block";

  site_toggle_huts(false);
  site_toggle_summits(false);
  site_toggle_docland(false);
  site_toggle_island(2);

  map_on_click_activate(site_select_point_on_click_callback);

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
      if(layer && layer.get('name').substr(0,site_current_click_layer.length)==site_current_click_layer) {
         return feature;
      } else {
         return null;
      }
    });
    
    if(feature) {
        //now copy it to where we want it 
      if(site_select_name_dest!=null)  document.getElementById(site_select_name_dest).value=feature.get('name');
      if(site_select_id_dest!=null)  document.getElementById(site_select_id_dest).value=feature.get('id');
      if(site_select_loc_dest!=null) document.getElementById(site_select_loc_dest).value=wktp.writeFeature(feature, { dataProjection: 'EPSG:4326', featureProjection: 'EPSG:2193'});
      if(site_select_x_dest!=null) document.getElementById(site_select_x_dest).value=feature.getGeometry().getCoordinates()[0];
      if(site_select_y_dest!=null) document.getElementById(site_select_y_dest).value=feature.getGeometry().getCoordinates()[1];
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
   

function linkHandler(entity_name) {
    /* close the dropdown */
    $('.dropdown').removeClass('open');

    /* show 'loading ...' */
    document.getElementById("page_status").innerHTML = 'Loading ...'

    $(function() {
     $.rails.ajax = function (options) {
       options.tryCount= (!options.tryCount) ? 0 : options.tryCount;0;
       options.timeout = 20000*(options.tryCount+1);
       options.retryLimit=0;
       options.complete = function(jqXHR, thrownError) {
         /* complete also fires when error ocurred, so only clear if no error has been shown */
         if(thrownError=="timeout") {
           this.tryCount++;
           document.getElementById("page_status").innerHTML = 'Retrying ...';
           this.timeout=20000*this.tryCount;
           if(this.tryCount<=this.retryLimit) {
             $.rails.ajax(this);
           } else {
             document.getElementById("page_status").innerHTML = 'Timeout';
           }
         }
         if(thrownError=="error") {
           document.getElementById("page_status").innerHTML = 'Error';
         }
         if(thrownError=="success") {
           //if(site_map_size==0) site_bigger_map();
           document.getElementById("page_status").innerHTML = ''
         }
         lastUrl=document.URL;
       }
       return $.ajax(options);
     };
   });
}

function site_clear_element(ids) {
  var length=ids.length;
  for(var count=0;count<length;count++) {  
    document.getElementById(ids[count]).value='';
  }
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
          timeout: 20000,
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
          timeout: 20000,
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
   return false;
}
function select_park(field, id, name, loc) {
  if (field=="park1") {
    document.contactform.contact_park1_id.value=id;
    document.contactform.park1_name.value=name;
    map_clear_scratch_layer(null, site_green_polygon);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_green_polygon) ;
  }
  if (field=="park2") {
    document.contactform.contact_park2_id.value=id;
    document.contactform.park2_name.value=name;
    map_clear_scratch_layer(null, site_red_polygon);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_red_polygon) ;
  }
  if (field=="park") {
    document.hutform.hut_park_id.value=id;
    document.hutform.park_name.value=name;
    map_clear_scratch_layer(null, site_highlight_polygon);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_highlight_polygon);
  }
  return false;
}

function select_island(field, id, name, loc) {
  if (field=="island1") {
    document.contactform.contact_island1_id.value=id;
    document.contactform.island1_name.value=name;
    map_clear_scratch_layer(null, site_green_star);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_green_star) ;
  }
  if (field=="island2") {
    document.contactform.contact_island2_id.value=id;
    document.contactform.island2_name.value=name;
    map_clear_scratch_layer(null, site_red_star);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_red_star) ;
  }
  if (field=="island") {
    document.hutform.hut_island_id.value=id;
    document.hutform.island_name.value=name;
    map_clear_scratch_layer(null, site_green_star);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_green_star);
  }
  return false;
}

function select_summit(field, id, name, x, y, loc, park, park_name) {
  if (field=="summit1") {
    document.contactform.contact_summit1_id.value=id;
    document.contactform.summit1_name.value=name;
    document.contactform.contact_x1.value=x;
    document.contactform.contact_y1.value=y;
    document.contactform.contact_location1.value=loc;
    document.contactform.contact_park1_id.value=park;
    document.contactform.park1_name.value=park_name;
    map_clear_scratch_layer('Point', site_green_star);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_green_star) ;
  }
  if (field=="summit2") {
    document.contactform.contact_summit2_id.value=id;
    document.contactform.summit2_name.value=name;
    document.contactform.contact_x2.value=x;
    document.contactform.contact_y2.value=y;
    document.contactform.contact_location2.value=loc;
    document.contactform.contact_park2_id.value=park;
    document.contactform.park2_name.value=park_name;
    map_clear_scratch_layer('Point', site_red_star);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_red_star) ;
  }
  return false;
}

function select_hut(field, id, name, x, y, loc, park, park_name) {
  if (field=="hut1") {
    document.contactform.contact_hut1_id.value=id;
    document.contactform.hut1_name.value=name;
    document.contactform.contact_x1.value=x;
    document.contactform.contact_y1.value=y;
    document.contactform.contact_location1.value=loc;
    document.contactform.contact_park1_id.value=park;
    document.contactform.park1_name.value=park_name;
    map_clear_scratch_layer('Point', site_green_star);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_green_star) ;
  }
  if (field=="hut2") {
    document.contactform.contact_hut2_id.value=id;
    document.contactform.hut2_name.value=name;
    document.contactform.contact_x2.value=x;
    document.contactform.contact_y2.value=y;
    document.contactform.contact_location2.value=loc;
    document.contactform.contact_park2_id.value=park;
    document.contactform.park2_name.value=park_name;
    map_clear_scratch_layer('Point', site_red_star);
    map_add_feature_from_wkt(loc,'EPSG:4326',site_red_star) ;
  }
  return false;
}


function search_huts(field) {
        BootstrapDialog.show({
            title: "Select hut",
            message: $('<div id="info_details2">Retrieving ...</div>'),
            size: "size-small"
        });

        $.ajax({
          beforeSend: function (xhr){
            xhr.setRequestHeader("Content-Type","application/javascript");
            xhr.setRequestHeader("Accept","text/javascript");
          },
          type: "GET",
          timeout: 20000,
          url: "/query?hutfield="+field,
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
          timeout: 20000,
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

