// APIs
//
// map_init() 
//
// managing layers:
//   map_add_raster_layer(name,url,source,maxresolution,numzooms) 
//   map_select_maplayer(name, url, basemap, minzoom, maxzoom) 
//   map_toggle_layer_by_name(visiblility,name) 
//   map_show_only_layer(name, type) 
//
// Adding buttons/controls:
//   map_create_control(buttonicon, buttontitle, callback, id ) 
//   map_add_control(item) 
//
// Controllers to query map
//   map_on_click_activate(callback) 
//   map_on_click_deactivate(callback) 
//
// Drawing / creating features:
//   map_create_style(shape, radius, fillcolor, linecolor, linewidth) 
//      -> return style
//   map_enable_draw(type, style, loc_dest, x_dest, y_dest, move) 
//   map_disable_draw() 
//
// Zooming
//   map_set_default_extent(extent)
//   map_zoom_to_default_extent()

var debug_f
var map_map;
//var Map = ol.Map; //import Map from 'ol/Map.js';
//var View = ol.View; // import View from 'ol/View.js';
//var TileLayer=ol.layer.Tile; //TileLayerimport TileLayer from 'ol/layer/Tile.js';
//var Draw=ol.interaction.Draw; 
//var TileGrid = ol.tilegrid.TileGrid
//var XYZ=ol.source.XYZ; //import XYZ from 'ol/source/XYZ.js';
//var Control=ol.control.Control;
//var CircleStyle=ol.style.Circle;
//var RegularShape=ol.style.RegularShape;
//var Fill=ol.style.Fill
//var Stroke=ol.style.Stroke
//var Style=ol.style.Style
//var bboxStrategy=ol.loadingstrategy.bbox;
var bboxStrategy=ol.loadingstrategy.tile(new ol.tilegrid.createXYZ());
//var VectorLayer=ol.layer.Vector;
//var GeoJSON=ol.format.GeoJSON;
//var WKT=ol.format.WKT;
//var VectorSource=ol.source.Vector;
var createStringXY=ol.coordinate.createStringXY
//var defaultControls=ol.control.defaults
var proj4=proj4
//var register=ol.proj.proj4.register
var map_map;
var map_current_layer="NZTM Topo 2019";
var map_current_proj="2193"
var map_projection_name="EPSG:2193"
var map_projection;
var map_current_projname="NZTM2000"
var map_current_projdp=0;
var map_mpc;
var mapBounds = [827933.23, 3729820.29, 3195373.59, 7039943.58];
var mapcontrols = [];
var map_control_count=0;
var map_layer_count=0;
var map_default_extent=mapBounds;
var map_scratch_source=new ol.source.Vector();
var map_scratch_layer=new ol.layer.Vector({ source: map_scratch_source, name: 'Scratch layer' });
var map_position_layer
var maplayers = [];
var map_last_centre='POINT(173 -41)';
var map_filters={null: ""}

// scratch layer behaviour
var map_x_target=null;
var map_y_target=null;
var map_click_replaces=false;
var map_draw;
var map_draw_status=false;

// debug
var persist_feature;

var mapspast_origin=[-20037508, 20037508];
var mapspast_resolutions=[156543.0339,
                          78271.51695,
                          39135.758475,
                          19567.8792375,
                          9783.93961875,
                          4891.969809375,
                          2445.9849046875,
                          1222.99245234375,
                          611.496226171875,
                          305.7481130859375,
                          152.87405654296876,
                          76.43702827148438,
                          38.21851413574219,
                          19.109257067871095,
                          9.554628533935547,
                          4.777314266967774];
var mapspast_extent=[-20037508, -20037508, 20037508, 20037508];
var mapspast_tilegrid=new ol.tilegrid.TileGrid({
	origin: mapspast_origin,
	resolutions: mapspast_resolutions,
        extent: mapspast_extent});

var linz_extent=[827933.23, 3729820.29, 3195373.59, 7039943.58];
var linz_origin=[-1000000, 10000000];
var linz_resolutions=[8960, 4480, 2240, 1120, 560, 280, 140, 70, 28, 14, 7, 2.8, 1.4, 0.7, 0.28, 0.14, 0.07];
var linz_tilegrid=new ol.tilegrid.TileGrid({
        origin: linz_origin,
        resolutions: linz_resolutions,
        extent: linz_extent});
var epsg2193;

//Map position stuff
var map_show_position=false;

const map_geolocation = new ol.Geolocation({
  // enableHighAccuracy must be set to true to have the heading value.
  trackingOptions: {
    enableHighAccuracy: true,
  },
  projection: ol.proj.get(map_projection_name),
});

function map_enable_tracking() {
  map_show_position=!map_show_position;
  map_position_layer.setVisible(map_show_position)
  map_geolocation.setTracking(map_show_position)
}

function map_add_control(item) {
	map_map.addControl(new item);
}

const positionFeature = new ol.Feature();
positionFeature.setStyle(
  new ol.style.Style({
    image: new ol.style.Circle({
      radius: 6,
      fill: new ol.style.Fill({
        color: '#ff1493',
      }),
      stroke: new ol.style.Stroke({
        color: '#8b008b',
        width: 2,
      }),
    }),
  })
);

map_geolocation.on('change', function () {
  const coordinates = map_geolocation.getPosition();
  const proj_coords = ol.proj.transform(coordinates, 'EPSG:4326',map_projection_name);
  positionFeature.setGeometry(coordinates ? new ol.geom.Point(proj_coords) : null);
});

function map_add_position_layer() {
  map_position_layer=new ol.layer.Vector({
    source: new ol.source.Vector({
      features: [positionFeature],
    }),
    name: 'position',
    visible: true
  });
  map_map.addLayer(map_position_layer);
};

function map_create_control(buttonicon, buttontitle, callback, id ) {
   var theListener=callback;
   var theButtonTitle=buttontitle;
   var theButtonIcon=buttonicon;
   var theButtonPosition=64+(36*map_control_count);
   mapcontrols[map_control_count] = /*@__PURE__*/(function (Control) {
     function thisController(opt_options) {
       var options = opt_options || {};
       var button = document.createElement('button');
       button.innerHTML = '<img src="'+theButtonIcon+'">';
       button.title = theButtonTitle;
       button.style.cssText='background-color:rgba(255,255,255,.4);';
       var element = document.createElement('div');
       element.className = 'olControlButton ol-unselectable ol-control';
       element.style.cssText='left:'+theButtonPosition+'px !important;';
       element.id=id;
       element.appendChild(button);

       Control.call(this, {
         element: element,
         target: options.target
       });

       button.addEventListener('click', this.handleClick.bind(this), false);
     }
     if ( Control ) thisController.__proto__ = Control;
     thisController.prototype = Object.create( Control && Control.prototype );
     thisController.prototype.constructor = thisController;

     thisController.prototype.handleClick= function handleClick() {
          theListener();
     }
     return thisController;
   }(ol.control.Control));
   map_control_count=map_control_count+1;
}



function map_init_mapspast(divid) {
  map_add_projections();
  mapset="mapspast";
  currentextent=mapBounds;
  if(typeof(map_map)!='undefined') {
     var currentextent=map_map.getView().calculateExtent()
     return 1;
  }
  map_init(divid);
  //map_map.getView().fit(currentextent , map_map.getSize());
}

function map_add_projections() {
  proj4.defs('EPSG:2193', '+proj=tmerc +lat_0=0 +lon_0=173 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs');
  proj4.defs('EPSG:27200', '+proj=nzmg +lat_0=-41 +lon_0=173 +x_0=2510000 +y_0=6023150 +ellps=intl +datum=nzgd49 +units=m +no_defs');
  proj4.defs('EPSG:999999', '+proj=tmerc +lat_0=0 +lon_0=167.5 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs');
  proj4.defs('EPSG:999998', '+proj=tmerc +lat_0=0 +lon_0=170 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs');
  proj4.defs('EPSG:999997', '+proj=tmerc +lat_0=0 +lon_0=167.625 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs');
  proj4.defs('EPSG:900913', '+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs');
  proj4.defs('EPSG:27200', '+proj=nzmg +lat_0=-41 +lon_0=173 +x_0=2510000 +y_0=6023150 +ellps=intl +datum=nzgd49 +units=m +no_defs');
  proj4.defs('EPSG:27291', '+proj=tmerc +lat_0=-39 +lon_0=175.5 +k=1 +x_0=274319.5243848086 +y_0=365759.3658464114 +ellps=intl +datum=nzgd49 +to_meter=0.9143984146160287 +no_defs');
  proj4.defs('EPSG:27292', '+proj=tmerc +lat_0=-44 +lon_0=171.5 +k=1 +x_0=457199.2073080143 +y_0=457199.2073080143 +ellps=intl +datum=nzgd49 +to_meter=0.9143984146160287 +no_defs');
  proj4.defs('EPSG:4326', '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ');
  proj4.defs('EPSG:4272', '+proj=longlat +ellps=intl +datum=nzgd49 +no_defs');
  proj4.defs('EPSG:4167', '+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs');
  ol.proj.proj4.register(proj4);
  epsg2193=ol.proj.get('EPSG:2193');
  map_projection=ol.proj.get(map_projection_name);
}
function map_add_wmts_layer(name,url,layer,source,maxresolution,numzooms) {
   if (source=="mapspast") {
           var tilegrid=mapspast_tilegrid;
   } else {
	   var tilegrid=linz_tilegrid;
   };
   maplayers[map_layer_count]=new ol.layer.Tile({
     source: new ol.source.WMTS({
       projection: epsg2193,
       url: url,
       layer: layer,
       maxResolution: maxresolution,
       numZoomLevels: numzooms,
       tileGrid: tilegrid,
       crossOrigin: 'anonymous'
     }),
     name: name,
     visible: false,
     projection: epsg2193,
     maxResolution: maxresolution,
     numZoomLevels: numzooms
   });
   map_layer_count=map_layer_count+1;
}


function map_add_raster_layer(name,url,source,maxresolution,numzooms) {
   if (source=="mapspast") {
           var tilegrid=mapspast_tilegrid;
   } else {
	   var tilegrid=linz_tilegrid;
   };
   maplayers[map_layer_count]=new ol.layer.Tile({
     source: new ol.source.XYZ({
       projection: epsg2193,
       url: url,
       maxResolution: maxresolution,
       numZoomLevels: numzooms,
       tileGrid: tilegrid,
       crossOrigin: 'anonymous'
     }),
     name: name,
     visible: false,
     projection: epsg2193,
     maxResolution: maxresolution,
     numZoomLevels: numzooms
   });
   map_layer_count=map_layer_count+1;
}


function map_add_vector_layer(name, url, field, style, visible,minzoom,maxzoom,filter) {
  var vector;
  var zeroresolution=156543.0339;
  var maxresolution=zeroresolution/Math.pow(2,minzoom);
  var minresolution=zeroresolution/Math.pow(2,maxzoom);
//  var vectorSource = new VectorSource({
//      format: new ol.format.GeoJSON(),
//      url: function(extent) {
//         return url+'&service=WFS&' +
//        'version=1.0.0&request=GetFeature&typename='+field+'&' +
//        'outputFormat=application/geojson&srsname=EPSG:2193&' +
//        'bbox=' + extent.join(',') + ',EPSG:2193';},
//    strategy: ol.loadingstrategy.bbox,
////    strategy: ol.loadingstrategy.tile(new ol.tilegrid.createXYZ()),
//    projection: 'EPSG:2193'
//  });
  if (filter) {
    var vectorSource = new ol.source.Vector({
      loader: function(extent) {
        $.ajax(url, {
          type: 'GET',
          data: {
            service: 'WFS',
            version: '1.0.0',
            request: 'GetFeature',
            typename: field,
            srsname: 'EPSG:2193',
            outputFormat: 'application/geojson',
            FILTER: '<ogc:Filter><AND><ogc:BBOX><ogc:PropertyName>Shape</ogc:PropertyName><gml:Box srsName="urn:x-ogc:def:crs:EPSG:2193"><gml:coordinates>'+extent[0]+','+extent[1]+' '+extent[2]+','+extent[3]+'</gml:coordinates></gml:Box></ogc:BBOX>'+map_filters[filter]+'</AND></ogc:Filter>'
          }
        }).done(function(response) {
          var tmp_f=new ol.format.GeoJSON().readFeatures(response);
          var length=tmp_f.length;
          for(var count=0; count<length; count++) {
             tmp_f[count].id_=tmp_f[count].get('id');
          }
          vector.getSource().addFeatures(tmp_f);
        });    
      },
      strategy: ol.loadingstrategy.bbox,
      projection: 'EPSG:2193'
    })
  } else {
    var vectorSource = new ol.source.Vector({
      loader: function(extent) {
        $.ajax(url, {
          type: 'GET',
          data: {
            service: 'WFS',
            version: '1.0.0',
            request: 'GetFeature',
            typename: field,
            srsname: 'EPSG:2193',
              outputFormat: 'application/geojson',
            bbox: extent.join(',') + ',EPSG:2193'
          }
        }).done(function(response) {
          var tmp_f=new ol.format.GeoJSON().readFeatures(response);
          var length=tmp_f.length;
          for(var count=0; count<length; count++) {
             tmp_f[count].id_=tmp_f[count].get('id');
          }
          vector.getSource().addFeatures(tmp_f);
        });
      },
      strategy: ol.loadingstrategy.bbox,
      projection: 'EPSG:2193'
    });
  }

  vector=new ol.layer.Vector({
      minResolution: minresolution,
      maxResolution: maxresolution,
      source: vectorSource,
      style: style,
      visible: visible,
      name: name
  });
  return vector;
}

function map_on_click_activate(callback) {
  if(typeof(map_map)!='undefined') map_map.on('click', callback);
}
function map_on_click_deactivate(callback) {
  if(typeof(map_map)!='undefined') map_map.un('click', callback);
}

function map_create_style(shape, radius, fillcolor, linecolor, linewidth) {
  var image
  var fill=new ol.style.Fill({
      color: fillcolor
    });
  var stroke=new ol.style.Stroke({
      color: linecolor,
      width: linewidth 
    });
  switch(shape) {
    case 'triangle':
      image= new ol.style.RegularShape({
        fill: fill,
        stroke: stroke,
        points: 3,
        radius: radius,
        rotation: 0,
        angle: 0
      })
    break;
    case 'square':
      image= new ol.style.RegularShape({
        fill: fill,
        stroke: stroke,
        points: 4,
        radius: radius,
        angle: Math.PI / 4
      })
    break;
    case 'star':
      image= new ol.style.RegularShape({
        fill: fill,
        stroke: stroke,
        points: 5,
        radius: radius,
        radius2: radius/2,
        angle: 0
      });
      break;
    case 'cross':
      image= new ol.style.RegularShape({
        fill: fill,
        stroke: stroke,
        points: 4,
        radius: radius,
        radus2: 0,
        angle: 0
      });
      break;
    case 'x':
      image= new ol.style.RegularShape({
        fill: fill,
        stroke: stroke,
        points: 4,
        radius: radius,
        radus2: 0,
        angle: Math.PI / 4
      });
      break;
    case 'circle':
      image= new ol.style.Circle({
        radius: radius,
        fill: fill,
        stroke: stroke
      });
      break;
    default:
  };


  var style=new ol.style.Style({
    fill: fill,
    stroke: stroke,
    image: image
  });
  
  return style;
}

function map_disable_draw() {
  if (typeof(map_map)!='undefined') map_map.removeInteraction(map_draw);
  map_draw_status=false;
}

function map_clear_scratch_layer(type,style) {
  if ((typeof(type)=='undefined' || type==null) && (typeof(style)=='undefined' || style==null)) {
    map_scratch_source.clear();
  } else {
    var features = map_scratch_source.getFeatures();
     if (features != null && features.length > 0) {
         for (x in features) {
            var thistype = features[x].getGeometry().getType();
            if (type==null || type == thistype) {
              if (style==null) {
                map_scratch_source.removeFeature(features[x]);
              } else {
                var thisstyle=features[x].getStyle();
                if (style == thisstyle) {
                   map_scratch_source.removeFeature(features[x]);
                }
              }
            }
          }
      }
  }
}

function map_enable_draw(type, style, loc_dest, x_dest, y_dest, move) {
        map_draw_status=true; 
	map_draw= new ol.interaction.Draw({
		source: map_scratch_source,
		type: type
	});
	map_draw.on('drawend', function (event) {
		if (move==true) map_clear_scratch_layer(type,style);
		var feature = event.feature;
                var format = new ol.format.WKT;
                persist_feature=feature; 
		x=feature.values_.geometry.flatCoordinates[0];
		y=feature.values_.geometry.flatCoordinates[1];
		var loc=format.writeGeometry(feature.getGeometry(),
                     {
                            dataProjection: 'EPSG:4326',
                            featureProjection: map_projection_name
                     });
                debug_f=feature;
		// write back to webpage
                if(loc_dest!=null)  document.getElementById(loc_dest).value=loc; 
                if(x_dest!=null)  document.getElementById(x_dest).value=x; 
                if(y_dest!=null)  document.getElementById(y_dest).value=y;

	 });
	map_draw.on('drawstart',function(event){
          event.feature.setStyle(style);
        });

	map_map.addInteraction(map_draw);
}






function map_init(divid) {
        if(divid==null) divid='map';
        var view = new ol.View({
                     center: [1600000, 5500000],
                     zoom: 2, 
		     projection: map_projection,
//   		     maxResolution: 4891.969809375,
   		     maxResolution: 2445.9849046875,
                     numZoomLevels: 11
        });

        map_mpc= new ol.control.MousePosition({
             coordinateFormat: createStringXY(map_current_projdp),
             projection: ol.proj.get('EPSG:'+map_current_proj)
        }); 

	site_add_layers();
	site_add_controls();


        map_map = new ol.Map({
            view: view,
            target: divid,
            layers: maplayers,
            controls: ol.control.defaults().extend([ map_mpc ]),
          });
	mapcontrols.forEach(map_add_control);

        map_show_only_layer(map_current_layer);
	map_set_coord_format();
}

 function map_select_maplayer(name, url, basemap, minzoom, maxzoom) {
    $.each(BootstrapDialog.dialogs, function(id, dialog){
        dialog.close();
    });
    layerid='';
      map_show_only_layer(name);
      map_map.getView().setMinZoom(minzoom);
      map_map.getView().setMaxZoom(maxzoom);
      map_set_default_extent(mapBounds);
}

function map_toggle_layer_by_name(visibility,name) {
    map_map.getLayers().forEach(function (layer) {
    if (layer.get('name') != undefined && layer.get('name') === name) {
        layer.setVisible(visibility);
    };
});
}

function map_get_layer_by_name(name) {
  thelayer=null;
    map_map.getLayers().forEach(function (layer) {
    if (layer.get('name') != undefined && layer.get('name') === name) {
        thelayer=layer;
    };
  });
  return thelayer;
}

function map_show_only_layer(name, type) {
    if ((typeof(type)=='undefined') || (type==null)) type='TILE';
    map_map.getLayers().forEach(function (layer) {
      if (layer.get('name') != undefined && layer.get('name') === name) {
        layer.setVisible(true);
//        if(type!='TILE') layer.getSource().clear(); //refresh
      } else {
        if (layer.getType()==type) {
  	  layer.setVisible(false);
        };
      };
    });
    map_current_layer=name;
}

function map_mapLayers() {
        BootstrapDialog.show({
            title: "Select basemap",
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
          url: "/layerswitcher?baselayer="+map_current_layer,
          error: function() {
              document.getElementById("info_details2").innerHTML = 'Error contacting server';
          },
          complete: function() {
//              document.getElementById("page_status").innerHTML = '';
          }

        });

}


function map_set_coord_format() {
   	var prefix=map_current_projname+": ";
        $('.ol-mouse-position').attr('data-before',prefix);
	map_mpc.setCoordinateFormat(createStringXY(map_current_projdp))
}



function map_updateProjection() {
            map_current_proj=document.getElementById("projections").value;
            map_current_projname=map_getSelectedText("projections");
            //WGS 4dp, otherwise 0
            if(map_current_proj=="4326" || map_current_proj=="4272" || map_current_proj=="4167") { map_current_projdp=4 } else { map_current_projdp=0 };
            $.each(BootstrapDialog.dialogs, function(id, dialog){
                dialog.close();
            });
            map_mpc.setProjection(ol.proj.get('EPSG:'+map_current_proj)); 
	    map_set_coord_format();
}

function map_getSelectedText(elementId) {
    var elt = document.getElementById(elementId);
    if (elt.selectedIndex == -1)
        return null;

    return elt.options[elt.selectedIndex].text;
}

function map_getSelectedValue(elementId) {
    var elt = document.getElementById(elementId);
    if (elt.selectedIndex == -1)
        return null;

    return elt.options[elt.selectedIndex].value;
}

function map_setSelectedOption(elementId,value) {
   var elt = document.getElementById(elementId);
   var count=0;
   for(count=0; count<elt.options.length; count++) {
     if(elt.options[count].value==value) elt.selectedIndex=value;
   }
}

function map_set_default_extent(extent) {
	map_default_extent=extent;
}

function map_zoom_to_default_extent() {
     map_map.getView().fit(map_default_extent , map_map.getSize());
}

function map_zoom(zoom) {
     map_map.getView().setZoom(zoom-5);
}
function map_add_feature_from_wkt(wkt, source_proj, style) {
  var format = new ol.format.WKT();
  var feature=format.readFeature(wkt, {
    dataProjection: source_proj,
    featureProjection: map_projection_name
    });
  feature.setStyle(style);
  map_scratch_source.addFeature(feature);
}

function map_add_feature(feature,style) {
  map_scratch_source.addFeature(feature);
}


function map_add_tooltip() {
  var tooltip = document.getElementById('tooltip');
  var overlay = new ol.Overlay({
    element: tooltip,
    offset: [10, 0],
    positioning: 'bottom-left'
  });
  map_map.addOverlay(overlay);
  
  function displayTooltip(evt) {
    if (map_draw_status==false) {
      var pixel = evt.pixel;
      var feature = map_map.forEachFeatureAtPixel(pixel, function(feature, layer) {
        if(layer!=map_scratch_layer) {
          return feature;
        } else {
          return null;
        }
      });
      tooltip.style.display = feature ? '' : 'none';
      if (feature) {
        debug_f=feature;
        overlay.setPosition(evt.coordinate);
        tooltip.innerHTML = '';
        if (feature.get('name')) tooltip.innerHTML = feature.get('name');
        if (feature.get('owners')) tooltip.innerHTML = feature.get('owners');
      }
    }
  };
  
  map_map.on('pointermove', displayTooltip);
}

function map_navigate_on_click_callback(evt) {
    var pixel = evt.pixel;
    var feature = map_map.forEachFeatureAtPixel(pixel, function(feature, layer) {
      if(layer!=map_scratch_layer) {
        return feature;
      } else {
        return null;
      }
    });
    if(feature) {
      map_clear_scratch_layer();
      site_navigate_to(feature.get('url'));
    }
}


function map_centre(wkt,proj) {
  var format = new ol.format.WKT();
  var feature=format.readFeature(wkt, {
    dataProjection: proj,
    featureProjection: map_projection_name
    });
  debug_f=feature;
  map_map.getView().setCenter(feature.getGeometry().flatCoordinates);
  map_last_centre=wkt;
}

function map_get_centre() {
  return map_map.getView().getCenter();
}

function map_get_zoom() {
  return map_map.getView().getZoom();
}

function map_refresh_layer(layer) {       
   layer.getSource().clear();
}

function map_get_current_extent(proj) {
    var extent= map_map.getView().calculateExtent();
    return ol.proj.transformExtent(extent,'EPSG:2193',proj);
}

   function map_WKTtoGPX(wktfield, gpxfield) {
     var wktp = new ol.format.WKT;
     var gpxp = new ol.format.GPX;

     if (document.getElementById(wktfield).value) {
       var fea = wktp.readFeatures(document.getElementById(wktfield).value,'EPSG:4326', 'EPSG:4326');
       if (fea.length>0) {
         document.getElementById(gpxfield).value=gpxp.writeFeatures(fea[0],'EPSG:4326', 'EPSG:4326');
       }
     }
}


   function map_GPXtoWKT(gpxfield, wktfield) {
     var wktp = new ol.format.WKT;
     var gpxp = new ol.format.GPX;

     if (document.getElementById(gpxfield).value) {
       var fea = gpxp.readFeatures(document.getElementById(gpxfield).value,'EPSG:4326', 'EPSG:4326');
       if (fea.length>0) {
        if(fea.length>1) {
           feaindex=window.prompt('GPX file contains '+fea.length+' features. Select the number (0-'+(fea.length-1)+') you want','0');
         } else { 
           feaindex=0;
         }
         var firstfea=fea[feaindex];
         var thefea=null;

         if (firstfea.getGeometry().getType()=='MultiLineString') {
           allfea=firstfea.getGeometry().getLineStrings();
           if(allfea.length>1) {
             index=window.prompt('GPX feature contains '+allfea.length+' track segments. Select the number (0-'+allfea.length-1+') you want','0');
           } else {
             index=0
           }
           thegeom=firstfea.getGeometry().getLineString(index);
           thefea=new ol.Feature({
             geometry: thegeom
           })
         }

         if (firstfea.getGeometry().getType()=='LineString') {
           thefea=firstfea;
         }

         document.getElementById(wktfield).value=wktp.writeFeature(thefea,'EPSG:4326', 'EPSG:4326');
       } else {
         alert("Invald GPX file");
       } 
       document.getElementById(gpxfield).value="";

     }
}
function map_get_centre_of_geom(wktgeom) {
  var wktp = new ol.format.WKT;

  var fea = wktp.readFeatures(wktgeom,{dataProjection: 'EPSG:4326', featureProjection: 'EPSG:4326'});
  debug_f=fea;
  var extent=fea[0].getGeometry().getExtent();
  var X = extent[0] + (extent[2]-extent[0])/2;
  var Y = extent[1] + (extent[3]-extent[1])/2;
  return("POINT("+X+" "+Y+")");
}
 
