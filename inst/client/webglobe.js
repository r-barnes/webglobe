//"use strict";

var imageryViewModels = [];

imageryViewModels.push(new Cesium.ProviderViewModel({
  name : 'Natural Earth (Offline)',
  iconUrl : Cesium.buildModuleUrl('Widgets/Images/ImageryProviders/naturalEarthII.png'),
  tooltip : 'OpenStreetMap (OSM) is a collaborative project to create a free editable \
  map of the world.\nhttp://www.openstreetmap.org TODO',
  creationFunction : function() {
    return new Cesium.UrlTemplateImageryProvider({
      url:          'tiles/natural_earth/{z}/{x}/{reverseY}.jpg',
      credit:       'TODO',
      minimumLevel: 0,
      maximumLevel: 3,
      tileSize:     256
      //bounds: [[-85, -180], [85, 180]],
      //tms:true
    });
  }
}));

imageryViewModels.push(new Cesium.ProviderViewModel({
  name : 'Stamen Terrain (Offline)',
  iconUrl : Cesium.buildModuleUrl('Widgets/Images/ImageryProviders/mapboxTerrain.png'),
  tooltip : 'Terrain from Stamen.\nhttps://github.com/stamen/terrain-classic',
  creationFunction : function() {
    return new Cesium.UrlTemplateImageryProvider({
      url:          'tiles/stamen_terrain/{z}/{x}/{y}.png',
      credit:       'Stamen Design LLC',
      minimumLevel: 0,
      maximumLevel: 3,
      tileSize:     256
    });
  }
}));

imageryViewModels.push(new Cesium.ProviderViewModel({
  name : 'Stamen Toner (Offline)',
  iconUrl : Cesium.buildModuleUrl('Widgets/Images/ImageryProviders/stamenToner.png'),
  tooltip : 'Toner from Stamen.\nhttps://github.com/stamen/toner-carto',
  creationFunction : function() {
    return new Cesium.UrlTemplateImageryProvider({
      url:          'tiles/stamen_toner/{z}/{x}/{y}.png',
      credit:       'Stamen Design LLC',
      minimumLevel: 0,
      maximumLevel: 3,
      tileSize:     256
    });
  }
}));

imageryViewModels.push(new Cesium.ProviderViewModel({
  name : 'Stamen Watercolor (Offline)',
  iconUrl : Cesium.buildModuleUrl('Widgets/Images/ImageryProviders/stamenWatercolor.png'),
  tooltip : 'Watercolor from Stamen.\nhttp://maps.stamen.com/#watercolor',
  creationFunction : function() {
    return new Cesium.UrlTemplateImageryProvider({
      url:          'tiles/stamen_watercolor/{z}/{x}/{y}.png',
      credit:       'Stamen Design LLC',
      minimumLevel: 0,
      maximumLevel: 3,
      tileSize:     256
    });
  }
}));

imageryViewModels.push(new Cesium.ProviderViewModel({
  name : 'Open Street Map Offline',
  iconUrl : Cesium.buildModuleUrl('Widgets/Images/ImageryProviders/openStreetMap.png'),
  tooltip : 'OpenStreetMap (OSM) is a collaborative project to create a free editable \
  map of the world.\nhttp://www.openstreetmap.org',
  creationFunction : function() {
    return new Cesium.createOpenStreetMapImageryProvider({
      url : 'tiles/osm'
    });
  }
}));

imageryViewModels.push(new Cesium.ProviderViewModel({
  name : 'Open\u00adStreet\u00adMap',
  iconUrl : Cesium.buildModuleUrl('Widgets/Images/ImageryProviders/openStreetMap.png'),
  tooltip : 'OpenStreetMap (OSM) is a collaborative project to create a free editable \
  map of the world.\nhttp://www.openstreetmap.org',
  creationFunction : function() {
    return new Cesium.createOpenStreetMapImageryProvider({
      url : '//a.tile.openstreetmap.org/'
    });
  }
}));

var options = {
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

var viewer = new Cesium.Viewer('webglobe', options);








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
          entity.polygon.material = Cesium.Color[entity.properties.fill.toUpperCase()].withAlpha(alpha);
        } else if(msg.fill){
          entity.polygon.material = Cesium.Color[msg.fill.toUpperCase()].withAlpha(alpha);
        } else {
          entity.polygon.material = Cesium.Color.TRANSPARENT;
        }

        //TODO
        if(entity.properties.stroke){
          entity.polygon.stroke = Cesium.Color[entity.properties.stroke.toUpperCase()].withAlpha(alpha);
        } else if(msg.stroke){
          entity.polygon.stroke = Cesium.Color[msg.stroke.toUpperCase()].withAlpha(alpha);
        } else {
          entity.polygon.outline = false;
        }

        //TODO
        if(entity.properties.stroke_width){
          entity.polygon.strokeWidth = entity.properties.stroke_width;
        } else if(msg.stroke_width){
          entity.polygon.strokeWidth = msg.stroke_width;
        } else {
          entity.polygon.outline = false;
        }

        if(entity.properties.extrude_height)
          entity.polygon.extrudedHeight = entity.properties.extrude_height;
        else if(msg.extrude_height)
          entity.polygon.extrudedHeight = msg.extrude_height;
      }
    }).otherwise(function(error){
      //Display any errrors encountered while loading.
      window.alert(error);
    });
  },
  points: function(msg){
    var points = viewer.scene.primitives.add(new Cesium.PointPrimitiveCollection());
    for(var i=0;i<msg.lat.length;i++){
      points.add({
        position:  new Cesium.Cartesian3.fromDegrees(msg.lon[i], msg.lat[i], msg.alt[i]),
        color:     Cesium.Color[msg.colour[i].toUpperCase()],
        pixelSize: msg.size[i]
      });
    }
  },
  cam_reset:  function(msg){
    viewer.camera.flyHome();
  },
  cam_center: function(msg){
    if(msg.alt===null)
      msg.alt = viewer.camera.getMagnitude();
    viewer.camera.flyTo({destination:Cesium.Cartesian3.fromDegrees(msg.lon,msg.lat,msg.alt)});
  }
}

function AddData(msg){
  thedata = JSON.parse(msg.data);
  viewer.dataSources.add(Cesium.GeoJsonDataSource.load(thedata), {
    stroke:       Cesium.Color.HOTPINK,
    fill:         Cesium.Color.PINK,
    strokeWidth:  3,
    markerSymbol: '?'
  });
}

function MessageReceived(msg){
  msg = JSON.parse(msg.data);
  console.log(msg);
  router[msg.command](msg);
}

var ws = new WebSocket("ws://"+window.location.host);

ws.onmessage = MessageReceived;
//ws.send('hi');
