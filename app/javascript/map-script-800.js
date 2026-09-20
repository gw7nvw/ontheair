// APIs
//
// map_init() 
//
// managing layers:
//   map_add_raster_layer(name,url,source,maxresolution,numzooms) 
//   map_select_maplayer(name, url, basemap, minzoom, maxzoom) 
//   map_toggle_layer_by_name(visiblility,name) 
//   map_show_only_layer(name) 
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
import Map from "ol/Map";
import View from "ol/View";
import TileLayer from "ol/layer/Tile";
import VectorLayer from "ol/layer/Vector";
import VectorSource from "ol/source/Vector";
import XYZ from "ol/source/XYZ";
import Draw from "ol/interaction/Draw";
import TileGrid from "ol/tilegrid/TileGrid";
import Control from "ol/control/Control";
import { defaults as defaultControls } from "ol/control/defaults";
import CircleStyle from "ol/style/Circle";
import RegularShape from "ol/style/RegularShape";
import Fill from "ol/style/Fill";
import Stroke from "ol/style/Stroke";
import Style from "ol/style/Style";
import { bbox as bboxStrategy } from "ol/loadingstrategy";
import GeoJSON from "ol/format/GeoJSON";
import WKT from "ol/format/WKT";
import { createStringXY } from "ol/coordinate";
import { register as registerProj4 } from "ol/proj/proj4";
import { get as getProjection } from 'ol/proj';
import proj4 from "proj4";
import MousePosition from 'ol/control/MousePosition';

var debug_f
var map_map;
window.map_current_layer="NZTM Topo 2019";
var map_current_proj="2193"
var map_projection_name="EPSG:2193"
var map_projection;
var map_current_projname="NZTM2000"
var map_current_projdp=0;
var mpc;
var mapBounds = [827933.23, 3729820.29, 3195373.59, 7039943.58];
var mapcontrols = [];
var control_count=0;
var layer_count=0;
var map_default_extent=mapBounds;
var map_scratch_source=new VectorSource();
var map_scratch_layer=new VectorLayer({ source: map_scratch_source, name: 'Scratch layer' });
var maplayers = [];
var map_last_centre='POINT(173 -41)';

// scratch layer behaviour
var map_x_target=null;
var map_y_target=null;
var map_click_replaces=false;
var map_draw;

// debug
var persist_feature;
var x
var y
var loc

var mapspast_origin=[-20037508, 20037508];
var hybrid_mapspast_origin=[-20037508, 20037508];
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
var hybrid_mapspast_extent=[-20037508, -20037508, 20037508, 20037508];
var mapspast_tilegrid=new TileGrid({
	origin: mapspast_origin,
	resolutions: mapspast_resolutions,
        extent: mapspast_extent});
var mapspast_hybrid_tilegrid=new TileGrid({
	origin: hybrid_mapspast_origin,
	resolutions: mapspast_resolutions,
        extent: hybrid_mapspast_extent});

var linz_extent=[827933.23, 3729820.29, 3195373.59, 7039943.58];
var linz_origin=[-1000000, 10000000];
var linz_resolutions=[8960, 4480, 2240, 1120, 560, 280, 140, 70, 28, 14, 7, 2.8, 1.4, 0.7, 0.28, 0.14, 0.07];
var linz_tilegrid=new TileGrid({
        origin: linz_origin,
        resolutions: linz_resolutions,
        extent: linz_extent});
var epsg2193;


function map_add_control(item) {
	map_map.addControl(item);
}

function map_create_control(buttonicon, buttontitle, callback, id) {
  const theListener = callback;
  const theButtonTitle = buttontitle;
  const theButtonIcon = buttonicon;
  const theButtonPosition = 64 + (36 * control_count);

  // Define a modern ES6 class that natively extends the OpenLayers Control
  class DynamicMapControl extends Control {
    constructor(opt_options) {
      const options = opt_options || {};
      
      const button = document.createElement('button');
      button.innerHTML = `<img src="${theButtonIcon}">`;
      button.title = theButtonTitle;
      button.style.cssText = 'background-color:rgba(255,255,255,.4);';
      
      const element = document.createElement('div');
      element.className = 'olControlButton ol-unselectable ol-control';
      element.style.cssText = `left:${theButtonPosition}px !important;`;
      element.id = id;
      element.appendChild(button);

      // Invoke the parent class constructor cleanly using super()
      super({
        element: element,
        target: options.target
      });

      // Bind the click listener to our handleClick method
      button.addEventListener('click', this.handleClick.bind(this), false);
    }

    handleClick() {
      theListener();
    }
  }

  // Instantiate the fresh control class and store it in your tracking array
  mapcontrols[control_count] = new DynamicMapControl();
  control_count=control_count+1;
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
  registerProj4(proj4);
  epsg2193=getProjection('EPSG:2193');
  map_projection=getProjection(map_projection_name);
}
function map_add_raster_layer(name,url,source,maxresolution,numzooms) {
   if (source=="mapspast") {
           var tilegrid=mapspast_tilegrid;
   } else {
	   var tilegrid=linz_tilegrid;
   };
   maplayers[layer_count]=new TileLayer({
     source: new XYZ({
       projection: epsg2193,
       url: url,
       maxResolution: maxresolution,
       numZoomLevels: numzooms,
       tileGrid: tilegrid
     }),
     name: name,
     visible: false,
     projection: epsg2193,
     maxResolution: maxresolution,
     numZoomLevels: numzooms
   });
   layer_count=layer_count+1;
}


function map_add_vector_layer(name, url, field, style, visible,minzoom,maxzoom) {
  var vector;
  var zeroresolution=156543.0339;
  var maxresolution=zeroresolution/Math.pow(2,minzoom);
  var minresolution=zeroresolution/Math.pow(2,maxzoom);
  var vectorSource = new VectorSource({
      format: new GeoJSON(),
      url: function(extent) {
         return url+'&service=WFS&' +
        'version=1.0.0&request=GetFeature&typename='+field+'&' +
        'outputFormat=application/geojson&srsname=EPSG:2193&' +
        'bbox=' + extent.join(',') + ',EPSG:2193';},
    strategy: bboxStrategy,
    projection: 'EPSG:2193'
  });
  vector=new VectorLayer({
      minResolution: minresolution,
      maxResolution: maxresolution,
      source: vectorSource,
      style: style
//      visible: visible
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
  var fill=new Fill({
      color: fillcolor
    });
  var stroke=new Stroke({
      color: linecolor,
      width: linewidth 
    });
  switch(shape) {
    case 'triangle':
      image= new RegularShape({
        fill: fill,
        stroke: stroke,
        points: 3,
        radius: radius,
        rotation: 0,
        angle: 0
      })
    break;
    case 'square':
      image= new RegularShape({
        fill: fill,
        stroke: stroke,
        points: 4,
        radius: radius,
        angle: Math.PI / 4
      })
    break;
    case 'star':
      image= new RegularShape({
        fill: fill,
        stroke: stroke,
        points: 5,
        radius: radius,
        radius2: radius/2,
        angle: 0
      });
      break;
    case 'cross':
      image= new RegularShape({
        fill: fill,
        stroke: stroke,
        points: 4,
        radius: radius,
        radus2: 0,
        angle: 0
      });
      break;
    case 'x':
      image= new RegularShape({
        fill: fill,
        stroke: stroke,
        points: 4,
        radius: radius,
        radus2: 0,
        angle: Math.PI / 4
      });
      break;
    case 'circle':
      image= new CircleStyle({
        radius: radius,
        fill: fill,
        stroke: stroke
      });
      break;
    default:
  };


  var style=new Style({
    fill: fill,
    stroke: stroke,
    image: image
  });
  
  return style;
}

function map_disable_draw() {
  map_map.removeInteraction(map_draw);
}

function map_clear_scratch_layer() {
  map_scratch_source.clear();
}

function map_enable_draw(type, style, loc_dest, x_dest, y_dest, move) {
	map_draw= new Draw({
		source: map_scratch_source,
		type: type,
	});
	map_draw.on('drawend', function (event) {
		if (move==true) map_scratch_source.clear();
		var feature = event.feature;
                persist_feature=feature; 
		x=feature.values_.geometry.flatCoordinates[0];
		y=feature.values_.geometry.flatCoordinates[1];
		loc=type+"("+feature.values_.geometry.flatCoordinates.toString()+")";
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
        var view = new View({
                     center: [1600000, 5500000],
                     zoom: 2, 
		     projection: map_projection,
//   		     maxResolution: 4891.969809375,
   		     maxResolution: 2445.9849046875,
                     numZoomLevels: 11
        });
        mpc= new MousePosition({
             coordinateFormat: createStringXY(map_current_projdp),
             projection: getProjection('EPSG:'+map_current_proj)
        }); 

	site_add_layers();
	site_add_controls();


        map_map = new Map({
            view: view,
            target: divid,
            layers: maplayers,
            controls: defaultControls().extend([ mpc ]),
          });
	window.map_map = map_map;
	mapcontrols.forEach(map_add_control);

        map_show_only_layer(window.map_current_layer);
	map_set_coord_format();
}

 function map_select_maplayer(name, url, basemap, minzoom, maxzoom) {
    if (window.currentActiveModal) {
      window.currentActiveModal.close();
    }

    layerid='';
      map_show_only_layer(name);
      map_map.getView().setMinZoom(minzoom);
      map_map.getView().setMaxZoom(maxzoom);
      map_set_default_extent(mapBounds);
}

function map_toggle_layer_by_name(visiblility,name) {
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

function map_show_only_layer(name) {
    map_map.getLayers().forEach(function (layer) {
      if (layer.get('name') != undefined && layer.get('name') === name) {
        layer.setVisible(true);
      } else {
        if (layer.get('name') != 'Scratch layer') {
  	  layer.setVisible(false);
        };
      };
    });
    window.map_current_layer=name;
}

// app/javascript/map-script.js

/**
 * Creates and displays a native Bootstrap 4 small modal dialog on the fly.
 * @param {string} modal_title - The text header for the modal title.
 * @param {string|jQuery} modal_body - The text or jQuery HTML fragment for the body.
 * @returns {Object} An object container holding a handler to close the modal programmatically.
 */
function map_create_dialog(modal_title, modal_body) {
  // 1. Permanently wipe out any pre-existing modal instances from the DOM tree
  $('#dynamicMapModal').remove();
  $('.modal-backdrop').remove(); // Clear any trapped backdrop shading overlays

  // 2. Construct the clean Bootstrap 4 template structure using template literals
  const modalHtml = `
    <div class="modal fade" id="dynamicMapModal" tabindex="-1" role="dialog" aria-hidden="true">
      <div class="modal-dialog modal-sm modal-dialog-centered" role="document">
        <div class="modal-content">
          <div class="modal-header bg-dark text-white py-2">
            <h5 class="modal-title" style="font-size: 1.1em;">${modal_title}</h5>
            <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body" id="dynamicMapModalBody" style="font-size: 0.95em;">
            <!-- Content will be securely injected here -->
          </div>
        </div>
      </div>
    </div>
  `;

  // 3. Append the fresh modal shell to your document body layout
  $('body').append(modalHtml);

  // 4. Inject the body contents safely (handles both raw string text and jQuery objects)
  if (modal_body instanceof jQuery) {
    $('#dynamicMapModalBody').append(modal_body);
  } else {
    $('#dynamicMapModalBody').html(modal_body);
  }

  // 5. Fire open the modal frame using native Bootstrap 4 jQuery syntax APIs
  $('#dynamicMapModal').modal({
    backdrop: 'static', // Prevents accidental closing when clicking the map background
    keyboard: true
  });

  // 6. Return a neat reference interface back to your script handler loops
  return {
    close: function() {
      $('#dynamicMapModal').modal('hide');
    },
    updateBody: function(new_html) {
      $('#dynamicMapModalBody').html(new_html);
    }
  };
}

// Make it universally accessible to site.js and views
window.map_create_dialog = map_create_dialog;

function map_mapLayers() {
        window.currentActiveModal = map_create_dialog(
            "Select basemap",
            '<div id="info_details2">Retrieving ...</div>');

        $.ajax({
          beforeSend: function (xhr){
            xhr.setRequestHeader("Content-Type","application/javascript");
            xhr.setRequestHeader("Accept","text/javascript");
          },
          type: "GET",
          timeout: 10000,
          url: "/layerswitcher?baselayer="+window.map_current_layer,
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
	mpc.setCoordinateFormat(createStringXY(map_current_projdp))
}



function map_updateProjection() {
            map_current_proj=document.getElementById("projections").value;
            map_current_projname=map_getSelectedText("projections");
            //WGS 4dp, otherwise 0
            if(map_current_proj=="4326" || map_current_proj=="4272" || map_current_proj=="4167") { map_current_projdp=4 } else { map_current_projdp=0 };
      	    if (window.currentActiveModal) {
              window.currentActiveModal.close();
            }
            mpc.setProjection(getProjection('EPSG:'+map_current_proj)); 
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
   var count;
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
  var format = new WKT();
  var feature=format.readFeature(wkt, {
    dataProjection: source_proj,
    featureProjection: map_projection_name
    });
    feature.setStyle(style);
  map_scratch_source.addFeature(feature);
}

function map_add_feature(feature) {
  map_scratch_source.addFeature(feature);
}


function map_add_tooltip() {
  var tooltip = document.getElementById('tooltip');
  var overlay = new Overlay({
    element: tooltip,
    offset: [10, 0],
    positioning: 'bottom-left'
  });
  map_map.addOverlay(overlay);
  
  function displayTooltip(evt) {
    var pixel = evt.pixel;
    var feature = map_map.forEachFeatureAtPixel(pixel, function(feature) {
      return feature;
    });
    tooltip.style.display = feature ? '' : 'none';
    if (feature) {
        overlay.setPosition(evt.coordinate);
      tooltip.innerHTML = feature.get('name');
    }
  };
  
  map_map.on('pointermove', displayTooltip);
}

function map_navigate_on_click_callback(evt) {
    var pixel = evt.pixel;
    var feature = map_map.forEachFeatureAtPixel(pixel, function(feature) {
      return feature;
    });
    map_clear_scratch_layer();
    site_navigate_to(feature.get('url'));
    f_debug=feature;
}


function map_centre(wkt,proj) {
  var format = new WKT();
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
   layer.getSource().refresh({force: true}); 
} 

window.map_init = map_init;
window.map_init_mapspast = map_init_mapspast;
window.map_add_raster_layer = map_add_raster_layer;
window.map_select_maplayer = map_select_maplayer;
window.map_toggle_layer_by_name = map_toggle_layer_by_name;
window.map_show_only_layer = map_show_only_layer;
window.map_create_control = map_create_control;
window.map_add_control = map_add_control;
window.map_on_click_activate = map_on_click_activate;
window.map_on_click_deactivate = map_on_click_deactivate;
window.map_create_style = map_create_style;
window.map_enable_draw = map_enable_draw;
window.map_disable_draw = map_disable_draw;
window.map_set_default_extent = map_set_default_extent;
window.map_zoom_to_default_extent = map_zoom_to_default_extent;
window.map_clear_scratch_layer = map_clear_scratch_layer;
window.map_scratch_layer = map_scratch_layer;
window.map_current_proj = map_current_proj;
window.map_mapLayers = map_mapLayers;
window.mapcontrols = mapcontrols;
window.map_projection_name = map_projection_name;
window.map_add_feature = map_add_feature;
window.map_get_layer_by_name = map_get_layer_by_name;
window.epsg2193 = epsg2193;
window.mapspast_tilegrid = mapspast_tilegrid;
window.mapspast_hybrid_tilegrid = mapspast_hybrid_tilegrid;
window.mapspast_origin = mapspast_origin;
window.hybrid_mapspast_origin = hybrid_mapspast_origin;
window.mapspast_extent = mapspast_extent;
window.mapspast_resolutions = mapspast_resolutions;
