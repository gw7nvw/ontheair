
var map;
function init(){

    map = new OpenLayers.Map( 'map', {
        displayProjection: new OpenLayers.Projection("EPSG:4326")
    } );
    var extent = new OpenLayers.Bounds(19342958.233236, -5095432.4834721,  19551784.194512, -5000803.4424551);
    var test_g_wmts_layer = new OpenLayers.Layer.WMTS({
        name: "test-g-WMTS",
        url: "http://wharncliffe.co.nz/mapcache/wmts/",
        layer: 'test',
        matrixSet: 'g',
        format: 'image/png',
        style: 'default',
        gutter:0,buffer:0,isBaseLayer:true,transitionEffect:'resize',
        resolutions:[156543.03392804099712520838,78271.51696402048401068896,39135.75848201022745342925,19567.87924100512100267224,9783.93962050256050133612,4891.96981025128025066806,2445.98490512564012533403,1222.99245256282006266702,611.49622628141003133351,305.74811314070478829308,152.87405657035250783338,76.43702828517623970583,38.21851414258812695834,19.10925707129405992646,9.55462853564703173959,4.77731426782351586979,2.38865713391175793490,1.19432856695587897633,0.59716428347793950593],
        zoomOffset:0,
        units:"m",
        maxExtent: new OpenLayers.Bounds(-20037508.342789,-20037508.342789,20037508.342789,20037508.342789),
        projection: new OpenLayers.Projection("EPSG:900913".toUpperCase()),
        sphericalMercator: true
      }
    );
    map.addLayer(test_g_wmts_layer);


    map.zoomToExtent(extent);
    map.addControl(new OpenLayers.Control.LayerSwitcher());
    map.addControl(new OpenLayers.Control.MousePosition());
}

