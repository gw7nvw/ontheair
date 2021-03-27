// browser history handler
if (typeof(lastUrl)=='undefined')  var lastUrl=document.URL;

window.onpopstate = function(event)  {
  if (document.URL != lastUrl) location.reload();
};

var tiff_map;
var dots="";
var map;
var vectorLayer;
var ourcanvas;
var searchMode;
var cross_red;
var click_to_create;
var click_to_create_grid;
var clickDest;
var clickForm;
var layer_style;
var clickMode=""
var mapBounds = new OpenLayers.Bounds(748961,3808210, 2940563,  6836339);
var preferredExtent = new OpenLayers.Bounds(1078269,4639780, 2098245,  6268806);
var tiffBounds = new OpenLayers.Bounds( -20037508.34,-20037508.34,20037508.34,20037508.34)
var tiffProj="900913";
var mapMinZoom = 5;
var mapMaxZoom = 15;
var emptyTileURL = document.location.origin+"/none.png";
var renderer;
OpenLayers.IMAGE_RELOAD_ATTEMPTS = 3;


function init(){
  init_styles();
  //Projections
  Proj4js.defs["EPSG:2193"] = "+proj=tmerc +lat_0=0 +lon_0=173 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs";
  Proj4js.defs["EPSG:999999"] = "+proj=tmerc +lat_0=0 +lon_0=167.5 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs";
  Proj4js.defs["EPSG:999998"] = "+proj=tmerc +lat_0=0 +lon_0=170 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs";
  Proj4js.defs["EPSG:999997"] = "+proj=tmerc +lat_0=0 +lon_0=167.625 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs";
  Proj4js.defs["EPSG:900913"] = "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs";
  Proj4js.defs["EPSG:27200"] = "+proj=nzmg +lat_0=-41 +lon_0=173 +x_0=2510000 +y_0=6023150 +ellps=intl +datum=nzgd49 +units=m +no_defs";
  Proj4js.defs["EPSG:27291"] = "+proj=tmerc +lat_0=-39 +lon_0=175.5 +k=1 +x_0=274319.5243848086 +y_0=365759.3658464114 +ellps=intl +datum=nzgd49 +to_meter=0.9143984146160287 +no_defs";
  Proj4js.defs["EPSG:27292"] = "+proj=tmerc +lat_0=-44 +lon_0=171.5 +k=1 +x_0=457199.2073080143 +y_0=457199.2073080143 +ellps=intl +datum=nzgd49 +to_meter=0.9143984146160287 +no_defs";
  Proj4js.defs["ESPG:4326"] = '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs '
  Proj4js.defs["ESPG:4272"] = '+proj=longlat +ellps=intl +datum=nzgd49 +no_defs'
  Proj4js.defs["ESPG:4167"] = '+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs'

  document.getElementById('map_map').setAttribute("style","width:"+wwidth+"px;height:"+wheight+"px");

  // map 
  var options = {
      maxResolution: 4891.969809375,
      numZoomLevels: 11,
      maxExtent: new OpenLayers.Bounds(-20037508, -20037508, 20037508, 20037508.34),
      div: "map_map",
      controls: [],
      projection: new OpenLayers.Projection("EPSG:2193"),
      units: "m",
      displayProjection: new OpenLayers.Projection("EPSG:2193"),
  };
  map = new OpenLayers.Map(options);
  
    renderer = OpenLayers.Util.getParameters(window.location.href).renderer;
    renderer = (renderer) ? [renderer] : OpenLayers.Layer.Vector.prototype.renderers;

  map.events.register("moveend", map, check_zoomend);
  // layers
  var nztm2009 = new OpenLayers.Layer.TMS("Topo50 2009", "http://au.mapspast.org.nz/topo50/",
  {
      serviceVersion: '.',
      layername: '.',
      alpha: true,
      type: 'png',
      isBaseLayer: true,
      tileOptions: {crossOriginKeyword: 'anonymous'},
      getURL: getURL
  });

  var nzms1999 = new OpenLayers.Layer.TMS("NZMS260 1999", "http://au.mapspast.org.nz/nzms260-1999/",
  {
      serviceVersion: '.',
      layername: '.',
      alpha: true,
      type: 'png',
      isBaseLayer: true,
      tileOptions: {crossOriginKeyword: 'anonymous'},
      getURL: getURL
  });

  var nzms1989 = new OpenLayers.Layer.TMS("NZMS1/260 1989", "http://au.mapspast.org.nz/nzms-1989/",
  {
      serviceVersion: '.',
      layername: '.',
      alpha: true,
      type: 'png',
      isBaseLayer: true,
      tileOptions: {crossOriginKeyword: 'anonymous'},
      getURL: getURL
  });

  var nzms1979 = new OpenLayers.Layer.TMS("NZMS1 1979", "http://au.mapspast.org.nz/nzms-1979/",
  {
      serviceVersion: '.',
      layername: '.',
      alpha: true,
      type: 'png',
      isBaseLayer: true,
      tileOptions: {crossOriginKeyword: 'anonymous'},
      getURL: getURL
  });

  var nzms1969 = new OpenLayers.Layer.TMS("NZMS1 1969", "http://au.mapspast.org.nz/nzms-1969/",
  {
      serviceVersion: '.',
      layername: '.',
      alpha: true,
      type: 'png',
      isBaseLayer: true,
      tileOptions: {crossOriginKeyword: 'anonymous'},
      getURL: getURL
  });

  var nzms1959 = new OpenLayers.Layer.TMS("NZMS1 1959", "http://au.mapspast.org.nz/nzms-1959/",
  {
      serviceVersion: '.',
      layername: '.',
      alpha: true,
      type: 'png',
      isBaseLayer: true,
      tileOptions: {crossOriginKeyword: 'anonymous'},
      getURL: getURL
  });

  var places_layer = new OpenLayers.Layer.Vector("Places", {
                    strategies: [new OpenLayers.Strategy.BBOX()],
                    protocol: new OpenLayers.Protocol.WFS({
                        url:  "http://routeguides.co.nz/cgi-bin/mapserv?map=/ms4w/apps/matts_app/htdocs/places.map",
                        featureType: "places",
                        extractAttributes: true
                    }),
                    styleMap: pt_styleMap,
                    displayInLayerSwitcher:false
                });

   var routes_layer = new OpenLayers.Layer.Vector("routes", {
                    strategies: [new OpenLayers.Strategy.BBOX()],
                    protocol: new OpenLayers.Protocol.WFS({
                        url:  "http://routeguides.co.nz/cgi-bin/mapserv?map=/ms4w/apps/matts_app/htdocs/routes.map",
                        featureType: "routes",
                        extractAttributes: true
                    }),
                    styleMap: rt_styleMap,
                    displayInLayerSwitcher:false
                });

  if(typeof(print_mode)=='undefined') {
    /* create click controllers*/
    add_click_to_query_controller();
    click_to_query = new OpenLayers.Control.Click();
    map.addControl(click_to_query);

    add_click_to_create_controller_grid();
    click_to_create_grid = new OpenLayers.Control.Click();
    map.addControl(click_to_create_grid);
  
  var my_button = new OpenLayers.Control.Button({
  displayClass: 'olControlInfo',
  trigger: mapInfo,
  title: 'Show mapsheet details for current series when you click on the map'
  });
  var search_button = new OpenLayers.Control.Button({
  displayClass: 'olControlSearch',
  trigger: mapSearch,
  title: 'List all available mapsheets at point you click on the map'
  });
  var maxextent_button = new OpenLayers.Control.Button({
  displayClass: 'olControlMaxExtent',
  trigger: zoom_to_mapsheet,
  title: 'Zoom to extent of current mapsheet/series'
  });
  
      var panel = new OpenLayers.Control.Panel({
  //        defaultControl: my_button,
          createControlMarkup: function(control) {
              var button = document.createElement('button'),
                  iconSpan = document.createElement('span'),
                  textSpan = document.createElement('span');
              iconSpan.innerHTML = '&nbsp;';
              button.appendChild(iconSpan);
              if (control.text) {
                  textSpan.innerHTML = control.text;
              }
              button.appendChild(textSpan);
              return button;
         }
      });
  
      panel.addControls([my_button, search_button, maxextent_button]);
    
    // controllers
    var switcherControl = new OpenLayers.Control.LayerSwitcher();
    map.addControl(switcherControl);
    switcherControl.maximizeControl();
          
    map.addControls([new OpenLayers.Control.Zoom(),
                   new OpenLayers.Control.Navigation(),
                   new OpenLayers.Control.MousePosition(),
                   new OpenLayers.Control.Scale(),
                   panel
                   ]);
  }
  if (layerid=='selected sheet') {
    create_selected_layer(sheetid, document.location.origin+"/");   
  } else { 
    map.addLayers([ nztm2009, nzms1999, nzms1989, nzms1979, nzms1969, nzms1959, places_layer, routes_layer]);
  }
  if (mleft!='' && mright!='' && mtop!='' && mbottom!='')  {
    preferredExtent = new OpenLayers.Bounds(mleft,mbottom, mright,  mtop);
  }
  map.zoomToExtent(preferredExtent.transform(map.displayProjection, map.projection));
  
  if (layerid!='') {
    ourlayer=map.getLayersByName(layerid);
    if (ourlayer.length>0) {
      map.setBaseLayer(ourlayer[0]);
    }
  }

  if (filetype=='png') {
    map.baseLayer.events.register("loadend", map.baseLayer, function() {setTimeout(function() {
      map.baseLayer.events.destroy("loadend");
      document.getElementById("map_status").innerHTML="";
      html2canvas(document.getElementById("map_map"),  
       {
         allowTaint: true, onrendered: function(canvas) {
           ourcanvas=canvas;
           document.body.appendChild(canvas);
           document.getElementById("map_map").style.display="none";
           canvas.toBlob(function(blob) {
             saveAs(blob, filename+".png");
           });          
         }
       });
    }, 5000)});
  }
  if (filetype=='pgw') {
    map.baseLayer.events.register("loadend", map.baseLayer, function() {
      map.baseLayer.events.destroy("loadend");
      document.getElementById("map_status").innerHTML="";
      var xres=0+map.getResolution();
      var yres=-xres;
      var xleft=map.getExtent().left;
      var ytop=map.getExtent().top;
      var blob = new Blob([""+xres+"\n0\n0\n"+yres+"\n"+xleft+"\n"+ytop+"\n"], {type: "text/plain"});
      saveAs(blob, filename+".pgw");
      window.close();
    });
  }
  if (filetype=='prj') {
      var blob = new Blob(['PROJCS["NZGD_2000_New_Zealand_Transverse_Mercator",GEOGCS["GCS_NZGD_2000",DATUM["D_NZGD_2000",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",1600000.0],PARAMETER["False_Northing",10000000.0],PARAMETER["Central_Meridian",173.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]'], {type: "text/plain"});
      saveAs(blob, filename+".prj");
      window.close();
  }
}

function getURL(bounds) {
  bounds = this.adjustBounds(bounds);
  var res = this.getServerResolution();
  var x = Math.round((bounds.left - this.tileOrigin.lon) / (res * this.tileSize.w));
  var y = Math.round((bounds.bottom - this.tileOrigin.lat) / (res * this.tileSize.h));
  var z = this.getServerZoom()+5;
  var path = this.serviceVersion + "/" + this.layername + "/" + z + "/" + x + "/" + y + "." + this.type; 
  var url = this.url;
  if (OpenLayers.Util.isArray(url)) {
      url = this.selectUrl(path, url);
  }
  if (filetype=='png' && mapBounds.intersectsBounds(bounds) && (z >= mapMinZoom) && (z <= mapMaxZoom)) {
      return url + path + '?time='+ new Date().getTime();
  } else {
      return emptyTileURL;
  }
} 
  

function create_selected_layer(layer_id, serverpath) {

  var sheetLayer = new OpenLayers.Layer.TMS("selected sheet", serverpath+"tiles-"+layer_id+"/",
  {
      serviceVersion: '.',
      layername: '.',
      alpha: true,
      type: 'png',
      isBaseLayer: true,
      tileOptions: {crossOriginKeyword: 'anonymous'},
      getURL: getURL
  });

  map.addLayer(sheetLayer);
}


function check_zoomend() {
  var layername=map.baseLayer.name;
  var maxzoom;

  if(layername=='selected sheet') {
     maxzoom=maxzoom;
  } else {
     maxzoom=14;
  }

  if(layername=='Topo50 2009') {
     maxzoom=15;
  }
  var z = map.getZoom()+5;
  //zoom back out (on a timer so current zoom envent can exit)
  if( z>maxzoom) {
          setTimeout( function() { map.zoomTo(maxzoom-5);}, 100);
  }
}
        

