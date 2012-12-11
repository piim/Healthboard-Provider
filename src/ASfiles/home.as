import ASclasses.Constants;

import ASfiles.ProviderConstants;

import components.AutoComplete;
import components.home.ViewPatient;
import components.modules.TeamModule;
import components.popups.UserContextMenu;

import controllers.AppointmentsController;
import controllers.ChatController;
import controllers.MainController;

import events.ApplicationDataEvent;
import events.ApplicationEvent;
import events.AutoCompleteEvent;
import events.ProfileEvent;

import external.TabBarPlus.plus.TabBarPlus;
import external.TabBarPlus.plus.TabPlus;

import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.utils.Timer;

import flashx.textLayout.elements.BreakElement;

import models.ApplicationModel;
import models.Chat;
import models.ChatSearch;
import models.Message;
import models.PatientModel;
import models.ProviderApplicationModel;
import models.ProviderModel;
import models.ProvidersModel;
import models.UserModel;

import mx.binding.utils.BindingUtils;
import mx.charts.chartClasses.CartesianDataCanvas;
import mx.collections.ArrayCollection;
import mx.collections.IList;
import mx.controls.LinkButton;
import mx.core.FlexGlobals;
import mx.core.INavigatorContent;
import mx.events.CalendarLayoutChangeEvent;
import mx.events.ListEvent;
import mx.graphics.SolidColorStroke;
import mx.managers.PopUpManager;
import mx.rpc.events.ResultEvent;

import spark.events.DropDownEvent;
import spark.events.IndexChangeEvent;

import styles.ChartStyles;

import utils.DateUtil;

[Bindable] public var controller:MainController;
[Bindable] public var model:ProviderApplicationModel;
[Bindable] public var medicalRecordsController:MainController;

[Bindable] public var chartStyles:ChartStyles;

private function init():void
{
	controller = AppProperties.getInstance().controller as MainController;
	model = controller.model as ProviderApplicationModel;
	
	model.chartStyles = chartStyles = new ChartStyles();
	
	ProviderApplicationModel(model).providersDataService.send();
}

private function onResize():void
{
	if( !this.stage ) return;
	
	FlexGlobals.topLevelApplication.height = this.stage.stageHeight;
}

private function toggleAvailability(event:MouseEvent):void
{
	var button:LinkButton = LinkButton(event.currentTarget);
	
	var user:UserModel = controller.user;
	
	user.available = user.available == UserModel.STATE_AVAILABLE ? UserModel.STATE_UNAVAILABLE : UserModel.STATE_AVAILABLE;
	
	button.setStyle('color',user.available == UserModel.STATE_AVAILABLE ? 0xCCCC33 : 0xB3B3B3 );
}

public function falsifyWidget(widget:String):void 
{
}
