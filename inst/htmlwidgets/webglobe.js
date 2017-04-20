function GetViewer(){
  return HTMLWidgets.getInstance(document.getElementById('webglobe'));
}

var cheese  = null;
var thedata = null;

//HTMLWidgets.shinyMode

HTMLWidgets.widget({

  name: 'webglobe',

  type: 'output',

  initialize: function(el, width, height) {
    var options = {
        animation:                              false,
        baseLayerPicker:                        false,
        fullscreenButton:                       false,
        geocoder:                               false,
        homeButton:                             false,
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
        imageryProvider:                        new Cesium.OpenStreetMapImageryProvider({
          url : 'https://a.tile.openstreetmap.org/'
        }),
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

    var viewer = new Cesium.Viewer(el.id, options);

    return {viewer:viewer};
  },

  renderValue: function(el, x, instance) {
    thedata = JSON.parse(x.data);
    instance.viewer.dataSources.add(Cesium.GeoJsonDataSource.load(JSON.parse(x.data), {
      stroke: Cesium.Color.HOTPINK,
      fill: Cesium.Color.PINK,
      strokeWidth: 3,
      markerSymbol: '?'
    }));
  },

  resize: function(el, width, height, instance) {

  }

});






//HTMLWidgets.getInstance(document.getElementById('webglobe'))


//GetViewer().viewer.dataSources.destroy()