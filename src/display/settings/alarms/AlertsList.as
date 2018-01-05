package display.settings.alarms
{
	import flash.system.System;
	
	import databaseclasses.AlertType;
	import databaseclasses.Database;
	
	import display.LayoutFactory;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Sprite;
	import starling.events.Event;
	
	import utils.AlertManager;
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("alertsettingsscreen")]

	public class AlertsList extends List 
	{
		/* Display Objects */
		private var addAlertButton:Button;
		private var positionHelper:Sprite;
		private var alertCreatorCallout:Callout;
		private var alertCreatorList:AlertCustomizerList;
		
		/* Internal Variables/Objects */
		private var alertTypesList:Array;
		private var alertTypesButtonsList:Array;
		
		public function AlertsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialContent();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			/* Get All Current Alert Types */
			alertTypesList = Database.getAlertTypesList();
			
			/* Instantiate Objects */
			alertTypesButtonsList = [];
		}
		
		private function setupContent():void
		{
			/* Controls */
			addAlertButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"add_alert_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.addAlertTexture);
			addAlertButton.gap = 5;
			addAlertButton.pivotX = -15;
			addAlertButton.addEventListener(Event.TRIGGERED, onAddAlert);
			
			/* Data */
			var listContent:ListCollection = new ListCollection();
			
			var dataLength:int = alertTypesList.length
			for (var i:int = 0; i < dataLength; i++) 
			{
				var alertType:AlertType = alertTypesList[i];
				
				if (alertType.alarmName != "null" && alertType.alarmName != "No Alert")
				{
					var alertControls:AlertManagerAccessory = new AlertManagerAccessory();
					alertControls.addEventListener(AlertManagerAccessory.DELETE, onDeleteAlert);
					alertControls.addEventListener(AlertManagerAccessory.EDIT, onEditAlert);
					alertTypesButtonsList.push(alertControls);
					
					listContent.push( { label: alertType.alarmName, accessory: alertControls, data: alertType, index: i } )
				}
			}
			
			listContent.push( { label: "", accessory: addAlertButton } );
			
			dataProvider = listContent;
			
			/* Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				
				return item;
			};
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
		}
		
		private function setupCalloutPosition():void
		{
			positionHelper = new Sprite();
			positionHelper.x = (Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2)) / 2;
			positionHelper.y = -45;
			addChild(positionHelper);
		}
		
		private function showAlertCreator():void
		{
			alertCreatorList.addEventListener(Event.COMPLETE, onAlertCreatorClosed);
			
			alertCreatorCallout = new Callout();
			alertCreatorCallout.content = alertCreatorList;
			
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_4_4S)
				alertCreatorCallout.padding = 18;
			else
			{
				if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_5_5S_5C_SE)
					alertCreatorCallout.padding = 18;
				
				setupCalloutPosition();
				alertCreatorCallout.origin = positionHelper;
			}
			
			PopUpManager.addPopUp(alertCreatorCallout, false, false);
		}
		
		public function closeAlertCallout():void
		{
			if (alertCreatorCallout != null)
				alertCreatorCallout.close(true);
		}
		
		/**
		 * Event Handlers
		 */
		private function onDeleteAlert(e:Event):void
		{
			//Get alert data
			var alertData:AlertType = (((e.currentTarget as AlertManagerAccessory).parent as DefaultListItemRenderer).data as Object).data as AlertType;
			var alertName:String = alertData.alarmName;
			
			//Check if alert is in use
			if (AlertType.alertTypeUsed(alertName)) 
			{
				//Alert is in use. Display messag to user notifying that the alert can't be deleted
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"alerttype_in_use_alert_title"),
					ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"alerttype_in_use_alert_message")
				);
			}
			else
			{
				//Alert not in use. Delete it from databalse
				Database.deleteAlertTypeSynchronous(alertData);
				
				//Update screen
				var alertIndex:int = (((e.currentTarget as AlertManagerAccessory).parent as DefaultListItemRenderer).data as Object).index;
				alertTypesList.removeAt(alertIndex);
				setupContent();
			}
		}
		
		private function onEditAlert(e:Event):void
		{
			//Get alert type data
			var alertData:AlertType = (((e.currentTarget as AlertManagerAccessory).parent as DefaultListItemRenderer).data as Object).data as AlertType;
			
			//Create Alert Creator and Show it
			alertCreatorList = new AlertCustomizerList(alertData);
			showAlertCreator();
		}
		
		private function onAddAlert(e:Event):void 
		{
			//Create Alert Creator and Show it
			alertCreatorList = new AlertCustomizerList(null);
			showAlertCreator();
		}
		
		private function onAlertCreatorClosed():void
		{
			//Refresh Screen
			alertTypesList = Database.getAlertTypesList();
			setupContent();
			
			//Close callout
			alertCreatorCallout.close(true);
		}
		
		/**
		 * Utility 
		 */
		override public function dispose():void
		{			
			if(addAlertButton != null)
			{
				addAlertButton.addEventListener(Event.TRIGGERED, onAddAlert);
				addAlertButton.dispose();
				addAlertButton = null;
			}
			
			if (alertTypesButtonsList != null && alertTypesButtonsList.length > 0)
			{
				var buttonsListLength:int = alertTypesButtonsList.length;
				for (var i:int = 0; i < buttonsListLength; i++) 
				{
					var alertManagerButton:AlertManagerAccessory = alertTypesButtonsList[i];
					alertManagerButton.dispose();
					alertManagerButton = null;
				}
			}
			
			if (positionHelper != null)
			{
				removeChild(positionHelper);
				positionHelper.dispose();
				positionHelper = null;
			}
			
			if (alertCreatorCallout != null)
			{
				alertCreatorCallout.dispose();
				alertCreatorCallout = null;
			}
			
			if (alertCreatorList != null)
			{
				alertCreatorList.dispose();
				alertCreatorList = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}