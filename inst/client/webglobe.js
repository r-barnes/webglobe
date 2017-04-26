//"use strict";
/*jshint browser: true */
/*global Cesium: false */
/*global console: false */

function getSceneCenter(){
  var lat = null;
  var lon = null;
  var alt = null;
  if (viewer.scene.mode == 3) {
    var windowPosition           = new Cesium.Cartesian2(viewer.container.clientWidth / 2, viewer.container.clientHeight / 2);
    var pickRay                  = viewer.scene.camera.getPickRay(windowPosition);
    var pickPosition             = viewer.scene.globe.pick(pickRay, viewer.scene);
    var pickPositionCartographic = viewer.scene.globe.ellipsoid.cartesianToCartographic(pickPosition);
    lon                          = pickPositionCartographic.longitude * (180 / Math.PI);
    lat                          = pickPositionCartographic.latitude * (180 / Math.PI);
    alt                          = viewer.camera.getMagnitude();
  } else if (viewer.scene.mode == 2) {
    var camPos = viewer.camera.positionCartographic;
    lat        = camPos.latitude * (180 / Math.PI);
    lon        = camPos.longitude * (180 / Math.PI);
    alt        = viewer.camera.getMagnitude();
  }
  return [lat, lon, alt];
}

var imageryViewModels = [];

imageryViewModels.push(new Cesium.ProviderViewModel({
  name : 'Open Street Map Offline',
  iconUrl : Cesium.buildModuleUrl('Widgets/Images/ImageryProviders/openStreetMap.png'),
  tooltip : 'OpenStreetMap (OSM) is a collaborative project to create a free editable map of the world.\nhttp://www.openstreetmap.org',
  creationFunction : function() {
    return new Cesium.createOpenStreetMapImageryProvider({
      url : 'tiles/osm',
      minimumLevel: 0,
      maximumLevel: 4
    });
  }
}));

imageryViewModels.push(new Cesium.ProviderViewModel({
  name : 'Open\u00adStreet\u00adMap',
  iconUrl : Cesium.buildModuleUrl('Widgets/Images/ImageryProviders/openStreetMap.png'),
  tooltip : 'OpenStreetMap (OSM) is a collaborative project to create a free editable map of the world.\nhttp://www.openstreetmap.org',
  creationFunction : function() {
    return new Cesium.createOpenStreetMapImageryProvider({
      url : '//a.tile.openstreetmap.org/'
    });
  }
}));

var viewer_options = {
    animation:                              false,
    fullscreenButton:                       true,
    geocoder:                               false,
    homeButton:                             true,
    infoBox:                                false,
    sceneModePicker:                        true,
    selectionIndicator:                     false,
    timeline:                               false,
    navigationHelpButton:                   false,
    navigationInstructionsInitiallyVisible: false,
    scene3DOnly:                            false,
    skyBox:                                 false,
    skyAtmosphere:                          false,
    sceneMode:                              Cesium.SceneMode.SCENE3D,
    baseLayerPicker:                        true,
    imageryProviderViewModels:              imageryViewModels,
    terrainProviderViewModels:              [],
    // imageryProvider:                     new Cesium.createOpenStreetMapImageryProvider({
    //   url:                               'https://a.tile.openstreetmap.org/'
    // }),

    // terrainProvider : new Cesium.CesiumTerrainProvider({
    //   url : '//assets.agi.com/stk-terrain/world'
    // }),
    targetFrameRate: 100,
    orderIndependentTranslucency: false,
    contextOptions: {
      webgl : {
        alpha:                        false,
        depth:                        false,
        stencil:                      false,
        antialias:                    false,
        premultipliedAlpha:           true,
        preserveDrawingBuffer:        false,
        failIfMajorPerformanceCaveat: false
      },
      allowTextureFilterAnisotropic : false
    }
};










var router = {
  clear: function(msg){
    viewer.dataSources.removeAll();
    viewer.scene.primitives.removeAll();
  },
  polygons: function(msg){
    var promise = Cesium.GeoJsonDataSource.load(msg.polys);
    promise.then(function(dataSource) {
      viewer.dataSources.add(dataSource);

      var entities = dataSource.entities.values;
      for (var i = 0; i < entities.length; i++) {
        var entity = entities[i];

        var alpha = msg.alpha;
        if(entity.properties.alpha)
          alpha = entity.properties.alpha;


        if(entity.properties.fill){
          entity.polygon.material = Cesium.Color.fromCssColorString(entity.properties.fill.valueOf()).withAlpha(alpha);
        } else if(msg.fill){
          entity.polygon.material = Cesium.Color.fromCssColorString(msg.fill).withAlpha(alpha);
        } else {
          entity.polygon.material = Cesium.Color.TRANSPARENT;
        }

        console.log(entity);

        //TODO
        if(entity.properties.stroke){
          entity.polygon.stroke = Cesium.Color.fromCssColorString(entity.properties.stroke.valueOf()).withAlpha(alpha);
        } else if(msg.stroke){
          entity.polygon.stroke = Cesium.Color.fromCssColorString(msg.stroke).withAlpha(alpha);
        } else {
          entity.polygon.outline = false;
        }

        //TODO
        if(entity.properties.stroke_width){
          entity.polygon.strokeWidth = parseFloat(entity.properties.stroke_width);
        } else if(msg.stroke_width){
          entity.polygon.strokeWidth = msg.stroke_width;
        } else {
          entity.polygon.outline = false;
        }

        if(entity.properties.extrude_height)
          entity.polygon.extrudedHeight = parseFloat(entity.properties.extrude_height);
        else if(msg.extrude_height)
          entity.polygon.extrudedHeight = msg.extrude_height;
      }
    }).otherwise(function(error){
      //Display any errrors encountered while loading.
      console.error(error);
    });
  },
  points: function(msg){
    for(var i=0;i<msg.lat.length;i++){
      var newpoint = {
        position: Cesium.Cartesian3.fromDegrees(msg.lon[i], msg.lat[i], msg.alt[i]),
        point:    {
          pixelSize: msg.size[i],
          color:     Cesium.Color.fromCssColorString(msg.colour[i])
        }
      };

      if(msg.label[i]){
        newpoint.label = {
          text:           msg.label[i],
          font:           '14pt monospace',
          style:          Cesium.LabelStyle.FILL_AND_OUTLINE,
          outlineWidth:   2,
          verticalOrigin: Cesium.VerticalOrigin.BOTTOM,
          pixelOffset:    new Cesium.Cartesian2(0, -9)
        };
      }

      viewer.entities.add(newpoint);
    }
  },
  bars: function(msg){
    for(var i=0;i<msg.lat.length;i++){
      viewer.entities.add({
        name:     'bar',
        polyline: {
          positions : Cesium.Cartesian3.fromDegreesArrayHeights(
            [msg.lon[i], msg.lat[i], 0, msg.lon[i], msg.lat[i], msg.alt[i]]
          ),
          width:    msg.width[i],
          material: new Cesium.PolylineOutlineMaterialProperty({
            color : Cesium.Color.fromCssColorString(msg.colour[i])
            //outlineWidth : 2,
            //outlineColor : Cesium.Color.BLACK
          })
        }
      });
    }
  },
  cam_reset:  function(msg){
    viewer.camera.flyHome();
  },
  cam_center: function(msg){
    if(msg.alt===null)
      msg.alt = viewer.camera.positionCartographic();
    viewer.camera.flyTo({destination:Cesium.Cartesian3.fromDegrees(msg.lon,msg.lat,msg.alt)});
  },
  title: function(msg){
    document.title = msg.title;
  }
};

var viewer   = new Cesium.Viewer('webglobe', viewer_options);
var ws       = new WebSocket("ws://"+window.location.host);

ws.onmessage = function(msg){
  msg = JSON.parse(msg.data);
  console.log(msg);
  router[msg.command](msg);
};

ws.onopen = function(e){
  ws.send('sally_forth');
};

var pos_interval_handle = setInterval(function() {
  var pos = viewer.camera.positionCartographic;
  var lat = pos.latitude *180/Math.PI;
  var lon = pos.longitude*180/Math.PI;
  var alt = pos.height   /1000;
  
  document.getElementById('currentpos').innerHTML = 
    lat.toFixed(5) + "&deg;, " + lon.toFixed(5) + "&deg;, " + alt.toFixed(0);
}, 1000);
