// app/javascript/application.js

// 1. IMPORT AND INITIALIZE TURBO IMMEDIATELY
//import { Turbo } from "@hotwired/turbo-rails";
// (Optional) If you have any old legacy form links that break on Turbo:
// Turbo.setFormMode("off");

// 1. Force establish traditional jQuery globals immediately
import jQuery from "jquery";
window.jQuery = jQuery;
window.$ = jQuery;

// 2. IMPORT AND START RAILS UJS (ADD THIS BLOCK HERE)
// This instantly restores full native parsing support for 'remote: true' links
import Rails from "@rails/ujs";
if (!window.Rails) {
  Rails.start();
}

// 2. Import core Bootstrap (this exposes Bootstrap plugins to jQuery)
import * as bootstrap from "bootstrap";
window.bootstrap = bootstrap;


// 2. Import the individual OpenLayers modules your code needs
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

// Import the specific modern projection registration bridge tool
import { register as registerProj4 } from "ol/proj/proj4";
import { get as getProjection } from 'ol/proj';

// 3. Proj4 Core Bindings
import proj4 from "proj4";
window.proj4 = proj4;

// 4. Reconstruct the precise global 'ol' namespace object structure your code expects
window.ol = {
  Map: Map,
  View: View,
  layer: {
    Tile: TileLayer,
    Vector: VectorLayer
  },
  interaction: {
    Draw: Draw
  },
  tilegrid: {
    TileGrid: TileGrid
  },
  source: {
    XYZ: XYZ,
    Vector: VectorSource
  },
  control: {
    Control: Control,
    defaults: defaultControls // Maps directly to your legacy defaultControls var call
  },
  style: {
    Circle: CircleStyle,
    RegularShape: RegularShape,
    Fill: Fill,
    Stroke: Stroke,
    Style: Style
  },
  loadingstrategy: {
    bbox: bboxStrategy
  },
  format: {
    GeoJSON: GeoJSON,
    WKT: WKT
  },
  coordinate: {
    createStringXY: createStringXY
  },
  proj: {
    proj4: {
      register: registerProj4 // Rebuilds your ol.proj.proj4.register hook perfectly
    }
  }
};

// 3. Append your unaltered legacy files down at the bottom
import "./map-script";
import "./site";
