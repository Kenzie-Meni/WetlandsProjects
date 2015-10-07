// 03.07.13 - NE - Added check and handling for lat/lon geocode rather than lon/lat.
// 02.26.13 - NE - Fixed wetland query bug.
// 02.01.13 - NE - Added popup for historic wetlands.
// 04.24.12 - NE - Updated map click conditional, so that wetlands can't be queried when the layer is not visible.
// 04.12.12 - NE - Added and implemented resource file.
// 03.13.12 - NE - Removed watershed tool for release build in cloud.
// 01.20.12 - NE - Added code to generalize input polygons in watershed download extract.
// 10.24.11 - NE - Updated for new WimInfoWindow close handling.
// 10.20.11 - NE - Adjusted location of download data form.
// 08.17.11 - NE - Updates to print function to include zoom slider in print preview but exclude in pdf.
// 07.28.11 - NE - Added handling for measure tool closing and deactivating the draw tool.
// 07.26.11 - NE - Updates to accept latlng parameter in URL and zoom to location and first scale that wetlands draw. Also, automatically turn on wetlands layer.
// 07.06.11 - NE - Updated onMapClick handling. 
// 06.28.11 - NE - Start as Wetlands Mapper 2.0
// 04.01.11 - JB - Added AS side logic for right-click and mousewheel
// 03.28.11 - JB - Template clean-up and updates 
// 06.28.10 - JB - Added new Wim LayerLegend component
// 03.26.10 - JB - Created
/***
 * ActionScript file for template */

import com.esri.ags.FeatureSet;
import com.esri.ags.Graphic;
import com.esri.ags.SpatialReference;
import com.esri.ags.events.DrawEvent;
import com.esri.ags.events.ExtentEvent;
import com.esri.ags.events.GeometryServiceEvent;
import com.esri.ags.events.GeoprocessorEvent;
import com.esri.ags.events.GraphicEvent;
import com.esri.ags.events.LayerEvent;
import com.esri.ags.events.MapMouseEvent;
import com.esri.ags.geometry.Extent;
import com.esri.ags.geometry.MapPoint;
import com.esri.ags.geometry.Polygon;
import com.esri.ags.layers.TiledMapServiceLayer;
import com.esri.ags.symbols.InfoSymbol;
import com.esri.ags.tasks.IdentifyTask;
import com.esri.ags.tasks.QueryTask;
import com.esri.ags.tasks.supportClasses.AddressCandidate;
import com.esri.ags.tasks.supportClasses.AddressToLocationsParameters;
import com.esri.ags.tasks.supportClasses.GeneralizeParameters;
import com.esri.ags.tasks.supportClasses.IdentifyParameters;
import com.esri.ags.tasks.supportClasses.Query;
import com.esri.ags.utils.GraphicUtil;
import com.esri.ags.utils.WebMercatorUtil;

import flash.display.StageDisplayState;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.net.FileReference;
import flash.utils.ByteArray;

import gov.usgs.wim.controls.WiMInfoWindow;
import gov.usgs.wim.controls.skins.WiMInfoWindowSkin;
import gov.usgs.wim.utils.XmlResourceLoader;

import mx.binding.utils.BindingUtils;
import mx.collections.ArrayCollection;
import mx.controls.*;
import mx.core.FlexGlobals;
import mx.core.IVisualElement;
import mx.core.IVisualElementContainer;
import mx.core.UIComponent;
import mx.effects.Fade;
import mx.effects.Glow;
import mx.effects.Resize;
import mx.effects.Rotate;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.events.MenuEvent;
import mx.events.Request;
import mx.events.ResizeEvent;
import mx.managers.BrowserManager;
import mx.managers.IBrowserManager;
import mx.managers.PopUpManager;
import mx.resources.ResourceBundle;
import mx.rpc.AsyncResponder;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;
import mx.rpc.http.HTTPService;
import mx.utils.ObjectProxy;
import mx.utils.URLUtil;

import org.alivepdf.colors.RGBColor;
import org.alivepdf.fonts.CoreFont;
import org.alivepdf.fonts.FontFamily;
import org.alivepdf.fonts.IFont;
import org.alivepdf.layout.Orientation;
import org.alivepdf.layout.Size;
import org.alivepdf.layout.Unit;
import org.alivepdf.pdf.PDF;
import org.alivepdf.saving.Download;
import org.alivepdf.saving.Method;

import skins.FeatureDataWindowSkin;

import spark.components.Group;

	private var xmlResourceLoader:XmlResourceLoader = new XmlResourceLoader();

	private var initExtent:Extent;
	private var poiExisting:Object = new Object();
	
	//private var poiInfoWindowRenderer:ClassFactory = new ClassFactory(PoiInfoWindowRenderer);
	
	private var wetPoint:MapPoint;
	private var metaPoint:MapPoint;
	private var ripPoint:MapPoint;
	
	private var ptGraphic:Graphic;
	
	private var mapCurrentExtent:Extent;
	private var mapCPoint:MapPoint;
	
	[Bindable] private var lineDistance:String = "...";
	[Bindable] private var polyArea:String = "...";
	[Bindable] private var lenLabel:String = "Distance";
	[Bindable] private var areaLabel:String = "Area";
	
	[Bindable]
	private var level:Number;
	private var mapLevel:Number;
	private var numb:Number = 1;
	
	[Bindable]
	private var mapX:Number = 0;
	[Bindable]
	private var mapY:Number = 0;

	private var queryX:Number;
	private var queryY:Number;

	private var Xpt:Number;
	private var Ypt:Number;
	
	private var pdf:PDF;
	private var poiCheck:Boolean;
	
	[Bindable]
	private var printS:String;
	
	[Bindable]
	public var serverContext:String;
	
	[Bindable]
	private var windLoc:String;
	
	[Bindable]
	private var genAlpha:Number = 0.6;
	
	[Bindable]
	private var transLayer:String = "";
	
	private var min:Resize = new Resize();
	private var max:Resize = new Resize();		
	private var operLayersFull:Number = 0;
	private var operLayersTitleHeight:Number = 46;
	
	private var mouseDiffX:Number;
	private var mouseDiffY:Number;
	private var measureToolActivated:Boolean;
	
	private var toolMenu:Menu;
	private var toolItems:Object;
	
	[Bindable]
	private var HUCNumber:String;
	[Bindable]
	private var HUCName:String;
	
	private var alert:Alert;

	private var _measureWindow:WiMInfoWindow;

	public var identifyPoint:MapPoint;

	private var _queryWindow:WiMInfoWindow;
	
	[Bindable]
	public var measureToolClose:Function;

	/* Image based on file from Wikimedia Commons and is licensed under https://secure.wikimedia.org/wikipedia/en/wiki/en:GNU_Free_Documentation_License */
	[Bindable]
	[Embed(source='assets/images/shield.png')] 
	private var streetsIcon:Class;
	/* Image based on file from Wikimedia Commons and is licensed under https://secure.wikimedia.org/wikipedia/en/wiki/en:GNU_Free_Documentation_License */
	[Bindable]
	[Embed(source='assets/images/Satellite.png')] 
	private var satelliteIcon:Class;
	/* Image based on file from Wikimedia Commons and is licensed under https://secure.wikimedia.org/wikipedia/en/wiki/en:GNU_Free_Documentation_License */
	[Bindable]
	[Embed(source='assets/images/mountain.png')] 
	private var mountainIcon:Class;
	[Bindable]
	[Embed(source='assets/images/usgsIcon.png')]
	private var usgsIcon:Class;

	private var params:Object;
	private var latlngParamUsed:Boolean;
	
	
	//Array of parameters for info queries
	private var queryParameters:Object = {
		cities: new ArrayCollection(["POP1990", "City Population", "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/"]),
		rivers: new ArrayCollection(["RIVERS", "River", "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/"])
	};
	//Initialize mapper
	private function setup():void
	{			
		xmlResourceLoader.load(["locale/en_US", "en_US"]);
		
		ExternalInterface.addCallback("rightClick", onRightClick);
		ExternalInterface.addCallback("handleWheel", handleWheel);
		
		//serverContext = "107.20.228.18";
		/*serverContext = "igsarchwasfws32";
		trace(serverContext);*/
		
		/*var bm:IBrowserManager= BrowserManager.getInstance();
		bm.init(url);
		var aurl:String = bm.base;
		serverContext = URLUtil.getServerNameWithPort(aurl);*/  
	}

	private function load():void {
		if (resourceManager.getString('urls', 'redirectUrl')) {
				
		}
		
		//Alert.show("The use of trade, product, industry or firm names or products is for informative purposes only and does not constitute an endorsement by the U.S. Government or the Fish and Wildlife Service.\n\nLinks to non-Service Web sites do not imply any official U.S. Fish and Wildlife Service endorsement of the opinions or ideas expressed therein, or guarantee the validity of the information provided.\n\nBase cartographic information used as part of this Wetlands Mapper has been provided through third party products.  The Fish and Wildlife Service does not maintain, and is not responsible for the accuracy or completeness of the base cartographic information.", "", 0, null, initAlertClose);
		mapMask.visible = false;
		
		initExtent = map.extent;
		
		params = getURLParameters();
		if (params["latlng"]) {
			var latlng:Array = String(params.latlng).split(",");
			if (latlng.length >= 2) {
				latlngParamUsed = true;
				map.centerAt(WebMercatorUtil.geographicToWebMercator(new MapPoint(latlng[1], latlng[0])) as MapPoint);
				if (params["scale"]) {
					map.scale = params["scale"];
				} else {
					map.scale = 144448;
				}
				//wetlandsToggle.selected = true;
			}
		} else {
			//wetlandsToggle.selected = false;
		}
		
		//geomService.addEventListener(GeometryServiceEvent.GENERALIZE_COMPLETE, onGeneralizeComp);
		trace(map.extent);
	}

	private function wetlands_loadHandler(event:LayerEvent):void
	{
		// TODO Auto-generated method stub
		var latlng:Array = String(params.latlng).split(",");
		if (latlngParamUsed == true && latlng.length == 3 && latlng[2] == 'c') {
			
			var identifyParameters:IdentifyParameters = new IdentifyParameters();
			identifyParameters.returnGeometry = true;
			identifyParameters.tolerance = 0;
			identifyParameters.width = map.width;
			identifyParameters.height = map.height;
			identifyParameters.geometry = WebMercatorUtil.geographicToWebMercator(new MapPoint(latlng[1], latlng[0])) as MapPoint
			identifyParameters.layerOption = IdentifyParameters.LAYER_OPTION_ALL;
			identifyParameters.mapExtent = map.extent;
			identifyParameters.spatialReference = map.spatialReference;										
			
			var identifyTask:IdentifyTask = new IdentifyTask();
			identifyTask.showBusyCursor = true;
			identifyTask.url = resourceManager.getString('urls', 'wetlandsUrl');
			identifyTask.proxyURL = resourceManager.getString('urls', 'proxyUrl');
			
			identifyTask.execute( identifyParameters, new AsyncResponder(infoResult, infoFault, new ArrayCollection([{type: 'wetlandOnLoad', lat: latlng[0], lng: latlng[1]}])) );
			
			latlngParamUsed = false;
		}
	}

	private function onRightClick():void {
		//Recenter at mouse location
		var cursorLocation:Point = new Point(contentMouseX, contentMouseY);
		map.centerAt(map.toMap(cursorLocation));
		//Zoom out
		map.zoomOut();
	}
	
	public function handleWheel(event:Object): void {
		var obj:InteractiveObject = null;
		var objects:Array = getObjectsUnderPoint(new Point(event.x, event.y));
		for (var i:int = objects.length - 1; i >= 0; i--) {
			if (objects[i] is InteractiveObject) {
				obj = objects[i] as InteractiveObject;
				break;
			} else {
				if (objects[i] is Shape && (objects[i] as Shape).parent) {
					obj = (objects[i] as Shape).parent;
					break;
				}
			}
		}
		if (obj) {
			var mEvent:MouseEvent = new MouseEvent(MouseEvent.MOUSE_WHEEL, true, false,
				event.x, event.y, obj,
				event.ctrlKey, event.altKey, event.shiftKey,
				false, -Number(event.delta));
			obj.dispatchEvent(mEvent);
		}
	}    	

	protected function hucAddHandler(event:GraphicEvent):void
	{
		// just so we can add tool tips
		event.graphic.toolTip = event.graphic.attributes.Name + "\n";
		event.graphic.toolTip += "HUC " + event.graphic.attributes.HUC8;
	}

	private function onExtentChange(event:ExtentEvent):void            
	{
		var level:Number = map.level;
		if (level < 12) {
			wetQueryGraphicsLayer.clear();
			PopUpManager.removePopUp(_queryWindow);
		}
		trace("level: " + map.level);
		
		
	}
	
	//Handles click requests for map layer info
	private function onMapClick(event:MapMouseEvent):void
	{
		if (measureToolActivated) {
			return;
		}
		
		var level:Number = map.level;
		
		wetQueryGraphicsLayer.clear();
		wetInfo.clear();
		PopUpManager.removePopUp(_queryWindow);
		
		/*if (((level > 11 && wetlands.visible) || (level > 11 && riparian.visible) || level > 11 && historicQuad.visible) && watershedsForDownload.visible == false) {
			
			//wetland identify task
			var identifyParameters:IdentifyParameters = new IdentifyParameters();
			identifyParameters.returnGeometry = true;
			identifyParameters.tolerance = 0;
			identifyParameters.width = map.width;
			identifyParameters.height = map.height;
			identifyParameters.geometry = event.mapPoint;
			identifyParameters.layerOption = "all";
			identifyParameters.layerIds = [0,1];
			identifyParameters.mapExtent = map.extent;
			identifyParameters.spatialReference = map.spatialReference;										
			
			var identifyTask:IdentifyTask = new IdentifyTask();
			identifyTask.showBusyCursor = true;
			identifyTask.proxyURL = resourceManager.getString('urls', 'proxyUrl');
			identifyTask.url = resourceManager.getString('urls', 'wetlandsUrl');
			
			//Riparian Identify task
			var riparianIdentifyParameters:IdentifyParameters = new IdentifyParameters();
			riparianIdentifyParameters.returnGeometry = true;
			riparianIdentifyParameters.tolerance = 0;
			riparianIdentifyParameters.width = map.width;
			riparianIdentifyParameters.height = map.height;
			riparianIdentifyParameters.geometry = event.mapPoint;
			riparianIdentifyParameters.layerOption = IdentifyParameters.LAYER_OPTION_ALL;
			riparianIdentifyParameters.mapExtent = map.extent;
			riparianIdentifyParameters.spatialReference = map.spatialReference;	
			riparianIdentifyParameters.layerIds = [0,1];
			
			var riparianIdentifyTask:IdentifyTask = new IdentifyTask();
			riparianIdentifyTask.showBusyCursor = true;
			riparianIdentifyTask.proxyURL = resourceManager.getString('urls', 'proxyUrl');
			riparianIdentifyTask.url = resourceManager.getString('urls', 'riparianUrl');
			
			//Historic Wetland Identify task
			var historicIdentifyParameters:IdentifyParameters = new IdentifyParameters();
			historicIdentifyParameters.returnGeometry = true;
			historicIdentifyParameters.tolerance = 0;
			historicIdentifyParameters.width = map.width;
			historicIdentifyParameters.height = map.height;
			historicIdentifyParameters.geometry = event.mapPoint;
			historicIdentifyParameters.layerOption = IdentifyParameters.LAYER_OPTION_ALL;
			historicIdentifyParameters.mapExtent = map.extent;
			historicIdentifyParameters.spatialReference = map.spatialReference;	
			historicIdentifyParameters.layerIds = [0,1];
			
			var historicIdentifyTask:IdentifyTask = new IdentifyTask();
			historicIdentifyTask.showBusyCursor = true;
			historicIdentifyTask.proxyURL = resourceManager.getString('urls', 'proxyUrl');
			historicIdentifyTask.url = resourceManager.getString('urls', 'historicUrl');
			
			
			identifyPoint = event.mapPoint;
			Xpt = identifyPoint.x;
			Ypt = identifyPoint.y;
			queryX = event.stageX;
			queryY = event.stageY;
			
			
			//All wetlands
			identifyParameters.layerIds = [0,1];
			
			
			if (wetlands.visible) {
				identifyTask.execute( identifyParameters, new AsyncResponder(infoResult, infoFault, new ArrayCollection([{type: 'wetland'}])) );
			}
			
			if (riparian.visible) {
				riparianIdentifyTask.execute( riparianIdentifyParameters, new AsyncResponder(infoResult, infoFault, new ArrayCollection([{type: 'riparian'}])) );
			}
			
			if (historicQuad.visible) {
				historicIdentifyTask.execute( historicIdentifyParameters, new AsyncResponder(infoResult, infoFault, new ArrayCollection([{type: 'historic'}])) );
			}
			
		} else if (watershedsForDownload.visible == true) {
			//watershed identify task
			watershedGraphicsLayer.clear();
			var identifyParameters:IdentifyParameters = new IdentifyParameters();
			identifyParameters.returnGeometry = true;
			identifyParameters.tolerance = 0;
			identifyParameters.width = map.width;
			identifyParameters.height = map.height;
			identifyParameters.geometry = event.mapPoint;
			identifyParameters.layerOption = IdentifyParameters.LAYER_OPTION_TOP;
			identifyParameters.mapExtent = map.extent;
			identifyParameters.spatialReference = map.spatialReference;										
			
			var identifyTask:IdentifyTask = new IdentifyTask();
			identifyTask.showBusyCursor = true;
			identifyTask.proxyURL = resourceManager.getString('urls', 'proxyUrl');
			identifyTask.url = resourceManager.getString('urls', 'huc8Url');
			
			identifyTask.execute( identifyParameters, new AsyncResponder(infoResult, infoFault, new ArrayCollection([{type: 'watershed'}])) );
		} else {
			return;
		}*/
		
	}

	private function infoResult(resultSet:Array, configObjects:ArrayCollection):void
	{
		
		var type:String = configObjects.getItemAt(0).type;
		if (configObjects.getItemAt(0).lat != null) {
			var lat:Number = Number(configObjects.getItemAt(0).lat);
			var lng:Number = Number(configObjects.getItemAt(0).lng);
		}
		
		//identifyPoint = event.mapPoint;
		
		if (type == 'wetland' && resultSet && resultSet.length > 0) {
			
			var i:int;
			var dataObj:Object = new Object();
			var wetGraphic:Graphic;
			
			for (i=0;i<resultSet.length;i++) {
				if (resultSet[i].layerName.search("Metadata") != -1) {
					if (resultSet[i].feature.attributes.STATUS == "Scan") {
						var scanDataObj:Object = resultSet[i].feature.attributes;
						//var metaGraphic:Graphic = resultSet[i].feature;
						
						quadQuery.geometry = FlexGlobals.topLevelApplication.identifyPoint;
						quadTask.execute(quadQuery, new AsyncResponder(quadResult, quadFault));
						
						function quadResult(featureSet:FeatureSet, token:Object = null):void
						{
							if (featureSet.features.length != 0) {
								var quadAttr:Object = new ObjectProxy(featureSet.features[0].attributes);
								if (quadAttr.QUAD_NAME != null) {
									scanDataObj.quad24k = quadAttr.QUAD_NAME;
								} else if (quadAttr.NAME != null) {
									scanDataObj.quad63k = quadAttr.NAME;
								} 
							}
							
							quadTask2.execute(quadQuery, new AsyncResponder(quadResult2, quadFault));
							function quadResult2(featureSet:FeatureSet, token:Object = null):void
							{
								if (featureSet.features.length != 0) {
									var quadAttr:Object = new ObjectProxy(featureSet.features[0].attributes);
									scanDataObj.quad100k = quadAttr.QUAD_NAME;
									
									ptGraphic = new Graphic(identifyPoint, scanSym);
									ptGraphic.attributes = scanDataObj;
									
									wetInfo.add(ptGraphic);
									return;
								}
								
							}
							
						}
						
						function quadFault(info:Object, token:Object = null):void
						{
							Alert.show("quadFault: " + info.toString());
						}
						
						
					} else {
						if (dataObj == null) {
							dataObj = resultSet[i].feature.attributes;
						} else {
							dataObj.STATUS = resultSet[i].feature.attributes.STATUS;
							dataObj.IMAGE_DATE = resultSet[i].feature.attributes.IMAGE_DATE;
							dataObj.SUPPMAPINFO = resultSet[i].feature.attributes.SUPPMAPINFO;
							dataObj.EMULSION = resultSet[i].feature.attributes.EMULSION;
							dataObj.IMAGE_SCALE = resultSet[i].feature.attributes.IMAGE_SCALE;
							dataObj.SOURCE_TYPE = resultSet[i].feature.attributes.SOURCE_TYPE;
						}
					}
				} else if (resultSet[i].value != "NoData"){
					if (dataObj == null) {
						dataObj = resultSet[i].feature.attributes;
						if (resultSet[i].layerName == "Wetlands") {
							wetGraphic = resultSet[i].feature;
							wetGraphic.symbol = aQuerySym;
							wetQueryGraphicsLayer.add(wetGraphic);
						}
					} else {
						dataObj.ATTRIBUTE = resultSet[i].feature.attributes.ATTRIBUTE;
						dataObj.WETLAND_TYPE = resultSet[i].feature.attributes.WETLAND_TYPE;
						dataObj.ACRES = resultSet[i].feature.attributes.ACRES;
						if (resultSet[i].layerName == "Wetlands") {
							wetGraphic = resultSet[i].feature;
							wetGraphic.symbol = aQuerySym;
							wetQueryGraphicsLayer.add(wetGraphic);
						}
					}
				}
				
			}
			//else if (resultSet[i].value != "NoData")
			if (wetGraphic != null) {
				_queryWindow = PopUpManager.createPopUp(map, WetlandDataWindow, false) as WiMInfoWindow;
				_queryWindow.data = dataObj;
				_queryWindow.setStyle("skinClass", FeatureDataWindowSkin);
				_queryWindow.x = queryX;
				_queryWindow.y = queryY;
				_queryWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
			}
		} else if (type == 'wetlandOnLoad' && resultSet && resultSet.length > 0) {
			
			var i:int;
			var dataObj:Object = new Object();
			var wetGraphic:Graphic;
			
			identifyPoint = WebMercatorUtil.geographicToWebMercator(new MapPoint(lng,lat)) as MapPoint;
			
			for (i=0;i<resultSet.length;i++) {
				if (resultSet[i].layerName.search("Metadata") != -1) {
					if (resultSet[i].feature.attributes.STATUS == "Scan") {
						var scanDataObj:Object = resultSet[i].feature.attributes;
						//var metaGraphic:Graphic = resultSet[i].feature;
						
						quadQuery.geometry = new MapPoint(lng,lat);
						quadTask.execute(quadQuery, new AsyncResponder(onLoadQuadResult, onLoadquadFault, new ArrayCollection([{type: 'quadOnLoad'}])));
						
						function onLoadQuadResult(featureSet:FeatureSet, token:Object = null):void
						{
							if (featureSet.features.length != 0) {
								var quadAttr:Object = new ObjectProxy(featureSet.features[0].attributes);
								if (quadAttr.QUAD_NAME != null) {
									scanDataObj.quad24k = quadAttr.QUAD_NAME;
								} else if (quadAttr.NAME != null) {
									scanDataObj.quad63k = quadAttr.NAME;
								} 
							}
							
							quadTask2.execute(quadQuery, new AsyncResponder(quadResult2, onLoadquadFault));
							function quadResult2(featureSet:FeatureSet, token:Object = null):void
							{
								if (featureSet.features.length != 0) {
									var quadAttr:Object = new ObjectProxy(featureSet.features[0].attributes);
									scanDataObj.quad100k = quadAttr.QUAD_NAME;
									
									ptGraphic = new Graphic(identifyPoint, scanSym);
									ptGraphic.attributes = scanDataObj;
									
									wetInfo.add(ptGraphic);
									return;
								}
								
							}
							
						}
						
						function onLoadquadFault(info:Object, token:Object = null):void
						{
							Alert.show("type: " + token.getItemAt(0).type + "/n" + info.toString());
							Alert.show('onloadquadfault');
						}
						
						
					} else {
						if (dataObj == null) {
							dataObj = resultSet[i].feature.attributes;
						} else {
							dataObj.STATUS = resultSet[i].feature.attributes.STATUS;
							dataObj.IMAGE_DATE = resultSet[i].feature.attributes.IMAGE_DATE;
							dataObj.SUPPMAPINFO = resultSet[i].feature.attributes.SUPPMAPINFO;
							dataObj.EMULSION = resultSet[i].feature.attributes.EMULSION;
							dataObj.IMAGE_SCALE = resultSet[i].feature.attributes.IMAGE_SCALE;
							dataObj.SOURCE_TYPE = resultSet[i].feature.attributes.SOURCE_TYPE;
						}
					}
				} else {
					if (dataObj == null) {
						dataObj = resultSet[i].feature.attributes;
						if (resultSet[i].layerName.search("Wetlands") != -1) {
							wetGraphic = resultSet[i].feature;
							wetGraphic.symbol = aQuerySym;
							wetQueryGraphicsLayer.add(wetGraphic);
						}
					} else {
						dataObj.ATTRIBUTE = resultSet[i].feature.attributes.ATTRIBUTE;
						dataObj.WETLAND_TYPE = resultSet[i].feature.attributes.WETLAND_TYPE;
						dataObj.ACRES = resultSet[i].feature.attributes.ACRES;
						if (resultSet[i].layerName.search("Wetlands") != -1) {
							wetGraphic = resultSet[i].feature;
							wetGraphic.symbol = aQuerySym;
							wetQueryGraphicsLayer.add(wetGraphic);
						}
					}
				}
				
			}
			
			if (wetGraphic != null) {
				_queryWindow = PopUpManager.createPopUp(map, WetlandDataWindow, false) as WiMInfoWindow;
				_queryWindow.data = dataObj;
				_queryWindow.setStyle("skinClass", FeatureDataWindowSkin);
				_queryWindow.x = map.width/2;
				_queryWindow.y = map.height/2;
				_queryWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
			}
		} else if (type == 'riparian' && resultSet && resultSet.length > 0) {
			var i:int;
			var dataObj:Object = new Object();
			var ripGraphic:Graphic;
			
			for (i=0;i<resultSet.length;i++) {
				if (resultSet[i].layerName.search("Mapping Areas") != -1) {
					if (dataObj == null) {
						dataObj = resultSet[i].feature.attributes;
					} else {
						dataObj.STATUS = resultSet[i].feature.attributes.STATUS;
						dataObj.IMAGE_DATE = resultSet[i].feature.attributes.IMAGE_DATE;
						dataObj.SUPPMAPINFO = resultSet[i].feature.attributes.SUPPMAPINFO;
						dataObj.EMULSION = resultSet[i].feature.attributes.EMULSION;
						dataObj.IMAGE_SCALE = resultSet[i].feature.attributes.IMAGE_SCALE;
					}
				} else {
					if (dataObj == null) {
						dataObj = resultSet[i].feature.attributes;
						ripGraphic = resultSet[i].feature;
						ripGraphic.symbol = aQuerySym;
						wetQueryGraphicsLayer.add(ripGraphic);
					} else {
						dataObj.ATTRIBUTE = resultSet[i].feature.attributes.ATTRIBUTE;
						dataObj.WETLAND_TYPE = resultSet[i].feature.attributes.WETLAND_TYPE;
						dataObj.ACRES = resultSet[i].feature.attributes.ACRES;
						ripGraphic = resultSet[i].feature;
						ripGraphic.symbol = aQuerySym;
						wetQueryGraphicsLayer.add(ripGraphic);
					}
				}
				
			}
			
			if (ripGraphic != null) {
				_queryWindow = PopUpManager.createPopUp(map, RiparianDataWindow, false) as WiMInfoWindow;
				_queryWindow.data = dataObj;
				_queryWindow.setStyle("skinClass", FeatureDataWindowSkin);
				_queryWindow.x = queryX;
				_queryWindow.y = queryY;
				_queryWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
			}
		} else if (type == 'historic' && resultSet && resultSet.length > 0) {
			var i:int;
			var dataObj:Object = new Object();
			var histGraphic:Graphic;
			
			for (i=0;i<resultSet.length;i++) {
				if (resultSet[i].layerName.search("Metadata") != -1) {
					if (dataObj == null) {
						dataObj = resultSet[i].feature.attributes;
					} else {
						dataObj.SUPPMAPINFO = resultSet[i].feature.attributes.SUPPMAPINFO;
						dataObj.FGDC_METADATA = resultSet[i].feature.attributes.FGDC_METADATA;
					}
				} else {
					if (dataObj == null) {
						dataObj = resultSet[i].feature.attributes;
						histGraphic = resultSet[i].feature;
						histGraphic.symbol = aQuerySym;
						wetQueryGraphicsLayer.add(histGraphic);
					} else {
						dataObj.ATTRIBUTE = resultSet[i].feature.attributes.ATTRIBUTE;
						dataObj.WETLAND_TYPE = resultSet[i].feature.attributes.WETLAND_TYPE;
						dataObj.ACRES = resultSet[i].feature.attributes.ACRES;
						histGraphic = resultSet[i].feature;
						histGraphic.symbol = aQuerySym;
						wetQueryGraphicsLayer.add(histGraphic);
					}
				}
				
			}
			
			if (histGraphic != null) {
				_queryWindow = PopUpManager.createPopUp(map, HistoricDataWindow, false) as WiMInfoWindow;
				_queryWindow.data = dataObj;
				_queryWindow.setStyle("skinClass", FeatureDataWindowSkin);
				_queryWindow.x = queryX;
				_queryWindow.y = queryY;
				_queryWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
			}
		} else if (type == 'watershed' && resultSet && resultSet.length > 0) {
			var i:int;
			var dataObj:Object = new Object();
			var watershedGraphic:Graphic;
			
			for (i=0;i<resultSet.length;i++) {
				if (resultSet[i].layerName.search("HU8") != -1) {
					dataObj = resultSet[i].feature.attributes;
					HUCNumber = dataObj.HUC8;
					HUCName = dataObj.Name;
					watershedGraphic = resultSet[i].feature;
					watershedGraphic.symbol = aQuerySym;
					watershedGraphic.toolTip = dataObj.Name + "\nHUC " + dataObj.HUC8;
					watershedGraphic.alpha = 0;
					watershedGraphicsLayer.clear();
					watershedGraphicsLayer.add(watershedGraphic);
					watershedGraphicsLayer.visible = true;
					//watershedStartDownloadNote.visible = false;
					//watershedStartDownloadNote.includeInLayout = false;
					//watershedDownloadNote.visible = true;
					//watershedDownloadNote.includeInLayout = true;
					
					//watershedsHighlight.layerDefinitions = [ "OBJECTID = -1", "OBJECTID = " + resultSet[i].feature.attributes["OBJECTID"] ]
					
					//watershedEmailInput.visible = true;
					//watershedEmailInput.includeInLayout = true;
					
					var graphicProvider:ArrayCollection = watershedGraphicsLayer.graphicProvider as ArrayCollection;
					var graphicsExtent:Extent = GraphicUtil.getGraphicsExtent(graphicProvider.toArray());
					map.extent = graphicsExtent.expand(2.1);
				}
			}
		}
	}

	private function hucLinkListener():void {
		var logRequest:HTTPService = new HTTPService();
		logRequest.method = "GET";
		logRequest.url = resourceManager.getString('urls', 'downloadLogUrl')+HUCNumber; 
		logRequest.addEventListener(ResultEvent.RESULT, reqResult);
		logRequest.send();
		
		function reqResult(event:ResultEvent):void {
			trace(event.result.string);
		}
		
		navigateToURL(new URLRequest('http://www.fws.gov/wetlands/downloads/Watershed/HU8_'+HUCNumber+'_watershed.zip'));
	}
	
	private function infoFault(info:Object, token:Object = null):void
	{
		//Alert.show(info.toString());
	} 
	
	/* End query tooltip methods */
	
	
	
	
	private function baseSwitch(event:FlexEvent):void            
	{                
		var tiledLayer:TiledMapServiceLayer = event.target as TiledMapServiceLayer;                
		if ((tiledLayer != null) && (tiledLayer.tileInfo != null) && (tiledLayer.id != "labelsMapLayer")) {
			map.lods = tiledLayer.tileInfo.lods;
		}
	}
	
	
	
	
	//Original code taken from ESRI sample: http://resources.arcgis.com/en/help/flex-api/samples/index.html#/Geocode_an_address/01nq00000068000000/
	//Adjusted for handling lat/lng vs. lng/lat inputs
	private function geoCode(searchCriteria:String):void
	{
		var parameters:AddressToLocationsParameters = new AddressToLocationsParameters();
		
		parameters.address = { SingleLine: searchCriteria };
		
		// Use outFields to get back extra information
		// The exact fields available depends on the specific Locator used.
		parameters.outFields = [ "*" ];
		
		locator.addressToLocations(parameters, new AsyncResponder(onResult, onFault));
		function onResult(candidates:Array, token:Object = null):void
		{
			if (candidates.length >= 0)
			{
				//if (candidates.length > 0 && (candidates[0].attributes.Loc_name != "LatLong" || latLonNeedsFix(searchCriteria) == false)) {
					
					var addressCandidate:AddressCandidate = candidates[0];
					
					var addressCandidate:AddressCandidate = candidates[0];
					
					map.extent = com.esri.ags.utils.WebMercatorUtil.geographicToWebMercator(new Extent(addressCandidate.attributes.Xmin, addressCandidate.attributes.Ymin,  addressCandidate.attributes.Xmax, addressCandidate.attributes.Ymax, map.spatialReference)) as Extent;
					
				/*} else if (latLonNeedsFix(searchCriteria) == true) {
					if (searchCriteria.search(",") != -1) {
						var newSearchArray:Array = searchCriteria.split(",");
						if (Number(newSearchArray[1]) < 0 || Number(newSearchArray[1]) > 90) {
							var newSearch:String = newSearchArray[1] + ", " + newSearchArray[0];
						}
						
					}
					geoCode(newSearch);
				}*/
				
			}
			else
			{
				//myInfo.htmlText = "<b><font color='#FF0000'>Found nothing :(</b></font>";
				
				Alert.show("Sorry, couldn't find a location for this address"
					+ "\nAddress: " + searchCriteria);
			};
			
		}
		
		function onFault(info:Object, token:Object = null):void
		{
			//myInfo.htmlText = "<b>Failure</b>" + info.toString();
			Alert.show("Failure: \n" + info.toString());
		}
	}

	public function latLonNeedsFix(criteria:String):Boolean {
		var needsFix:Boolean = false;
		
		if (criteria.search(",") != -1) {
			var newSearchArray:Array = criteria.split(",");
			if (Number(newSearchArray[1]) < 0 || Number(newSearchArray[1]) > 90) {
				needsFix = true;
			}
		}
		
		return needsFix;
	}
	
	
	private function onFault(info:Object, token:Object = null):void
	{
		Alert.show("Error: " + info.toString(), "problem with Locator");
	}
	
	/* End geo-coding methods */

	/* Start tools menu methods */

	private function initToolPop():void 
	{
		toolMenu = new Menu();
		/*toolItems = [ 
			{label: "Measure"},
			{label: "Download Data by State"},
			{label: "Download Data in Current Extent", enabled: true, toolTip: "You must be zoomed farther in to extract data"} //,
		];*/
		toolItems = [ 
			{label: "Measure"},
			{label: "Download Data by State"},
			{label: "Download Data by Watershed"}
		];
		toolMenu.dataProvider = toolItems;
		toolMenu.addEventListener("itemClick", toolSelection);
		//toolPop.popUp = toolMenu;
	}
	
	private function toolSelection(event:MenuEvent):void 
	{
		var select:String = event.label;
		if (select == "Measure") {
			measureToolClose();
			PopUpManager.removePopUp(_measureWindow);
			measureLayer.clear();
			watershedGraphicsLayer.clear();
			//watershedDownloadForm.visible = false;
			//watershedsForDownload.visible = false;
			//watershedsHighlight.visible = false;
			measureToolActivated = true;
			_measureWindow = PopUpManager.createPopUp(map, MeasureTool, false) as WiMInfoWindow;
			_measureWindow.setStyle("skinClass", WiMInfoWindowSkin);
			_measureWindow.x = (FlexGlobals.topLevelApplication.width/2) - (_measureWindow.width/2);
			_measureWindow.y = (FlexGlobals.topLevelApplication.height/2) - (_measureWindow.height/2);
			_measureWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
		} else if (select == "Download Data by State") {
			navigateToURL(new URLRequest(resourceManager.getString('urls', 'stateDownloadsUrl')));
		} else if (select == "Download Data in Current Extent") {
			if (map.level > 11) {
				//downloadForm.x = event.target.x;
				//downloadForm.y = event.target.y + 55;
				//downloadForm.visible = true;
				//watershedDownloadForm.visible = false;
				//watershedsForDownload.visible = false;
				//watershedsHighlight.visible = false;
				watershedGraphicsLayer.clear();
			} else {
				alert = Alert.show('');
				Alert.show('You must be zoomed in farther to download by extent', '', 0, map);
				PopUpManager.removePopUp(alert);
			}
		} else if (select == "Download Data by Watershed") {
			measureToolClose();
			PopUpManager.removePopUp(_measureWindow);
			measureLayer.clear();
			//watershedDownloadForm.x = event.target.x;
			//watershedDownloadForm.y = event.target.y + 55;
			
			//watershedStartDownloadNote.visible = true;
			//watershedStartDownloadNote.includeInLayout = true;
			
			//watershedDownloadNote.visible = false;
			//watershedDownloadNote.includeInLayout = false;
			//watershedEmailInput.visible = false;
			//watershedEmailInput.includeInLayout = false;
			//watershedDownloadForm.visible = true;
			//watershedsForDownload.visible = true;
			//watershedsHighlight.layerDefinitions = [ "OBJECTID = -1", "OBJECTID = -1" ]
			//watershedsHighlight.visible = true;
			
			//downloadForm.visible = false;
		}
	}

	private function getURLParameters():Object
	{
		var result:URLVariables = new URLVariables();
		
		try
		{
			if (ExternalInterface.available)
			{
				// Use JavaScript to get the search string from the current browser location.
				// Use substring() to remove leading '?'.
				// See http://livedocs.adobe.com/flex/3/langref/flash/external/ExternalInterface.html
				var search:String = ExternalInterface.call("location.search.substring", 1);
				if (search && search.length > 0)
				{
					result.decode(search);
				}
			}
		}
		catch (error:Error)
		{
			Alert.show(error.toString());
		}
		
		return result;
	}

	public function closePopUp(event:CloseEvent):void {
		if (event.currentTarget is MeasureTool) {
			measureToolClose();
			measureLayer.clear();
			measureToolActivated = false;
		}
		PopUpManager.removePopUp(event.currentTarget as WiMInfoWindow);
		if (event.currentTarget is WetlandDataWindow || event.currentTarget is RiparianDataWindow || event.currentTarget is HistoricDataWindow) {
			wetQueryGraphicsLayer.clear();
		}
	}

	private function onGeneralizeComp(event:GeometryServiceEvent):void {
		//var email:String = watershedDownloadEmail.text;
		
		var poly:Polygon = new Polygon();
		poly.rings = event.result[0].rings;
		poly.spatialReference = map.spatialReference; 
		var bGraphic:Graphic = new Graphic();
		bGraphic.geometry = poly;
		
		var recordSet:FeatureSet = new FeatureSet();
		recordSet.features = new Array();
		recordSet.features[0] = bGraphic;
		
		/*var params:Object = {
			"Area_To_Download":recordSet,
			"Email_address_to_send_zip_file":email,
			"Layers_to_Download":""
		};*/
		wetlandsDownload.updateDelay = 5000;
		//wetlandsDownload.submitJob(params, new AsyncResponder(onGPResult,onGPFault));
		//wetlandsDownload.execute(params, new AsyncResponder(onGPResult,onGPFault));
		
		watershedGraphicsLayer.clear();
		//watershedDownloadForm.visible = false;
		//watershedStartDownloadNote.visible = true;
		//watershedStartDownloadNote.includeInLayout = true;
		//watershedDownloadNote.visible = false;
		//watershedDownloadNote.includeInLayout = false;
		//watershedEmailInput.visible = false;
		//watershedEmailInput.includeInLayout = false;
		//watershedsForDownload.visible = false;
		//watershedsHighlight.visible = false;
		
		Alert.show('Request sent');
		
		function onGPResult():void {
			Alert.show('Your data request has been completed. Please check your email.');
		}
		
		function onGPFault(info:Object, token:Object = null):void
		{
			Alert.show("Error: " + info.toString(), "problem with Data Download");
		}
	}
	
	private function alertClose(event:CloseEvent):void
	{
		//map.extent = mapCurrentExtent;
		map.centerAt(mapCPoint);//-10644926.307107488,4666939.198981996
		map.level = mapLevel;
		mapMask.visible = false;
		//map.visible = true;
	}
	
	private function initAlertClose(event:CloseEvent):void
	{
		mapMask.visible = false;
	}

	public function fade(object:DisplayObject,inOut:String,alphaFrom:Number,alphaTo:Number,duration:Number):void
	{
		
		var fade:Fade = new Fade();
		fade.target = object;
		fade.alphaFrom = alphaFrom;
		fade.alphaTo = alphaTo;
		fade.play();
		
		if (inOut == "in") {
			object.visible = true;
		} else if (inOut == "out") {
			object.visible = false;
		}
	}
	
	public function hideAll():void
	{
		header.visible = false;
		headerLogo.visible = false;
		zoomTo.visible = false;
		//baseLayers.visible = false;
		navigation.visible = false;
		//tools.visible = false;
		scaleZeroes.visible = false;
		geocoder.visible = false;
		controlLayers.visible = false;
		//printButton.visible = false;
		//help1.visible = false;
		//printStatus.visible = false;
		coordsScale.visible = false;
	}
	
	public function showAll():void
	{
		header.visible = true;
		headerLogo.visible = true;
		zoomTo.visible = true;
		//baseLayers.visible = true;
		navigation.visible = true;
		//tools.visible = true;
		map.zoomSliderVisible = true;
		scaleZeroes.visible = true;
		geocoder.visible = true;
		controlLayers.visible = true;
		//printButton.visible = true;
		//help1.visible = true;
		//printStatus.visible = true;
		coordsScale.visible = true;
	}



