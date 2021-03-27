
function place_init() {

  Proj4js.defs["EPSG:2193"] = "+proj=tmerc +lat_0=0 +lon_0=173 +k=0.9996 +x_0=1600000 +y_0=10000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs";
  Proj4js.defs["EPSG:900913"] = "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs";

  if (typeof(map_map)=='undefined') init();

  style_blue = OpenLayers.Util.extend({}, layer_style);
  style_blue.strokeColor = "blue";
  style_blue.fillColor = "blue";
  style_blue.graphicName = "star";
  style_blue.pointRadius = 10;
  style_blue.strokeWidth = 3;
  style_blue.rotation = 45;
  style_blue.strokeLinecap = "butt";

  style_purple = OpenLayers.Util.extend({}, layer_style);
  style_purple.strokeColor = "purple";
  style_purple.fillColor = "purple";
  style_purple.graphicName = "star";
  style_purple.pointRadius = 10;
  style_purple.strokeWidth = 3;
  style_purple.rotation = 45;
  style_purple.strokeLinecap = "butt";
  

  if(typeof(vectorLayer)=='undefined') {
    vectorLayer = new OpenLayers.Layer.Vector("Current feature", {
                style: layer_style,
                renderers: renderer
            });
    map_map.addLayer(vectorLayer);
  } else {
      vectorLayer.destroyFeatures();
  }
  /* get location from form */
  var x = document.placeform.place_x.value;
  var y = document.placeform.place_y.value;
  var proj = document.placeform.place_projn.value;

  /*convert to map projectiob */
  var srcProj =  new OpenLayers.Projection("EPSG:2193");
  var mapProj =  new OpenLayers.Projection("EPSG:900913");
  var thisPoint = new OpenLayers.Geometry.Point(x, y).transform(srcProj, mapProj);

  /*add to map */
  var point = new OpenLayers.Geometry.Point(thisPoint.x,thisPoint.y)
  var pointFeature = new OpenLayers.Feature.Vector(point,null,style_purple);
  vectorLayer.addFeatures(pointFeature);

  /* turn on click to get coords */
  if(!document.placeform.place_x.disabled) {
     click_to_select.deactivate();
     click_to_create.activate();
  }
}



