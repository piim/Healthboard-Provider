import ASfiles.ProviderConstants;

import components.AutoComplete;
import components.home.ViewPatient;
import components.modules.TeamModule;
import components.popups.UserContextMenu;

import controllers.ApplicationController;
import controllers.AppointmentsController;
import controllers.ChatController;

import events.ApplicationEvent;
import events.AutoCompleteEvent;
import events.EnhancedTitleWindowEvent;
import events.ProfileEvent;

import external.collapsibleTitleWindow.components.enhancedtitlewindow.EnhancedTitleWindow;

import flash.display.DisplayObject;
import flash.display.InteractiveObject;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.utils.Timer;
import flashx.textLayout.elements.BreakElement;

import models.Chat;
import models.ChatSearch;
import models.Message;
import models.PatientModel;
import models.ProviderModel;
import models.ProvidersModel;
import models.UserModel;

import mx.collections.ArrayCollection;
import mx.containers.ApplicationControlBar;
import mx.controls.LinkButton;
import mx.core.INavigatorContent;
import mx.events.CalendarLayoutChangeEvent;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.events.ResultEvent;

import spark.events.DropDownEvent;
import spark.events.IndexChangeEvent;

import utils.DateUtil;

private var controller:ApplicationController = ApplicationController.getInstance();

private function init():void
{
	patientsXMLdata.send();
	providersXMLdata.send();
	
	if( ProviderConstants.DEBUG ) this.currentState = "providerHome";

	userContextMenuTimer = new Timer( 2000, 1 );
	userContextMenuTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onUserMenuDelay);
	
	this.addEventListener( AutoCompleteEvent.SHOW, onShowAutoComplete );
	this.addEventListener( AutoCompleteEvent.HIDE, onHideAutoComplete );
	
	this.addEventListener( ApplicationEvent.NAVIGATE, onNavigate );
	this.addEventListener( ApplicationEvent.SHOW_CONTEXT_MENU, onShowContextMenu );
}

[Bindable] public var fullname:String;
[Bindable] private var registeredUserID:String = "thisValueWillBeReplaced";
[Bindable] private var registeredPassword:String = "thisValueWillBeReplaced";
protected function btnLogin_clickHandler(event:MouseEvent):void {
	if(userID.text == 'popo' || (userID.text == 'piim' && password.text == 'password') || (userID.text == 'gregory' && password.text == 'berg')) {
		this.currentState='providerHome';
		
		if(userID.text == 'popo' || (userID.text == 'piim' && password.text == 'password')) fullname = "Dr. Gregory Berg";
		else if(userID.text == 'gregory' && password.text == 'berg') fullname = "Dr. Gregory Berg";
		//else, fullname will contain the name the user indicated at registration.
		
		clearValidationErrorsLogin();
		bcLogin.height = 328;
	}
	else {
		usernameValidator.validate('');		//here we are forcing the userID and password text fields to show red borders, by validating them as if they had empty values.
		passwordValidator.validate('');
		hgLoginFail.visible = hgLoginFail.includeInLayout = true;
		bcLogin.height = 346;
		//this.currentState='default';
	}
}

protected function bar_initializeHandlerMain():void {
	// Set first tab as non-closable
	tabsMain.setTabClosePolicy(0, false);
}

//THE FOLLOWING TWO ARE MONSTER FUNCTIONS THAT PREVENT THE DROPDOWN FROM CLOSING WHEN CLICKING ON THE CALENDAR
//SEE http://www.blastanova.com/blog/2010/06/23/a-custom-multi-selection-spark-dropdownlist/ FOR REFERENCE
protected function dropDownCalendar_openHandler(event:DropDownEvent):void {
	patientBirthDateChooser.addEventListener(MouseEvent.MOUSE_DOWN, stopPropagation, false, 0, true);
	advBirthDateChooser.addEventListener(MouseEvent.MOUSE_DOWN, stopPropagation, false, 0, true);
}
protected function stopPropagation(event:Event):void {
	event.stopImmediatePropagation();
}

protected function dateChooser_changeHandler(event:CalendarLayoutChangeEvent):void {
	txtPatientBirthDay.text = patientBirthDateChooser.selectedDate.date < 10 ? '0' + patientBirthDateChooser.selectedDate.date : String(patientBirthDateChooser.selectedDate.date);
	txtPatientBirthMonth.text = patientBirthDateChooser.displayedMonth < 9 ? '0' + (patientBirthDateChooser.displayedMonth + 1) : String(patientBirthDateChooser.displayedMonth + 1);
	txtPatientBirthYear.text = String(patientBirthDateChooser.displayedYear);
	dropDownCalendar.closeDropDown(true);					
}

protected function advDateChooser_changeHandler(event:CalendarLayoutChangeEvent):void {
	txtAdvBirthDay.text = advBirthDateChooser.selectedDate.date < 10 ? '0' + advBirthDateChooser.selectedDate.date : String(advBirthDateChooser.selectedDate.date);
	txtAdvBirthMonth.text = advBirthDateChooser.displayedMonth < 9 ? '0' + (advBirthDateChooser.displayedMonth + 1) : String(advBirthDateChooser.displayedMonth + 1);
	txtAdvBirthYear.text = String(advBirthDateChooser.displayedYear);
	dropDownAdvCalendar.closeDropDown(true);					
}

[Bindable] public var patientsData:ArrayCollection = new ArrayCollection();
private function patientsResultHandler(event:ResultEvent):void {
	/*if(event.result.autnresponse.responsedata.clusters.cluster is ObjectProxy ) {
	= new ArrayCollection( [event.result.autnresponse.responsedata.clusters.cluster] );
	}
	else {
	clusterData = event.result.autnresponse.responsedata.clusters.cluster;	
	}*/
	
	var results:ArrayCollection = event.result.patients.patient;
	
	var patients:ArrayCollection = new ArrayCollection();
	
	for each(var result:Object in results)
	{
		var patient:PatientModel = PatientModel.fromObj(result);
		patients.addItem( patient );
	}
	
	patientsData = patients;
	
	controller.patients = ChatController.getInstance().model.patients = patientsData;

	initChatHistory();
}

public var arrOpenPatients:Array = new Array();
protected function dgPatients_itemClickHandler(event:ListEvent):void {
	var user:PatientModel = PatientModel( event.itemRenderer.data );
	showPatient(user);
}

protected function onPatientProfileClick(event:ProfileEvent):void {
	var user:PatientModel = PatientModel( event.user );
	showPatient(user);
}

protected function onPatientNameClick(event:MouseEvent):void {
	var user:PatientModel = PatientModel( LinkButton(event.currentTarget).data );
	showPatient(user);
}

protected function showPatient(user:PatientModel):void {
	var isPatientAlreadyOpen:Boolean = false;
	for(var i:uint = 0; i < arrOpenPatients.length; i++) {
		if(arrOpenPatients[i] == user) {
			isPatientAlreadyOpen = true;
			viewStackMain.selectedIndex = i + 1;		//+1 because in arrOpenPatients we don't include the first tab
			break;
		}
	}				
	if(!isPatientAlreadyOpen) {
		var viewPatient:ViewPatient = new ViewPatient();
		viewPatient.patient = user;		//acMessages[event.rowIndex];
		viewStackMain.addChild(viewPatient);
		tabsMain.selectedIndex = viewStackMain.length - 1;
		arrOpenPatients.push(user);	
	}
}

private function patientsSearchFilter():void {
	patientsData.filterFunction = filterPatientsSearch;
	patientsData.refresh();
}

private function patientsModuleSearchFilter():void {
	patientsData.filterFunction = filterPatientsSearchModule;
	patientsData.refresh();
	searchResults.visible = true;
	update();
}

private function filterPatientsSearch(item:Object):Boolean {
	var pattern:RegExp = new RegExp("[^]*"+patientSearch.text+"[^]*", "i");
	var searchFilter:Boolean = (patientSearch.text == 'Search' || patientSearch.text == '') ? true : (pattern.test(item.lastName) || pattern.test(item.firstName));

	var birthDayFilter:Boolean = (txtPatientBirthDay.text == 'dd' || txtPatientBirthDay.text == '') ? true : item.dob.substr(3,2) == txtPatientBirthDay.text;
	var birthMonthFilter:Boolean = (txtPatientBirthMonth.text == 'mm' || txtPatientBirthMonth.text == '') ? true : item.dob.substr(0,2) == txtPatientBirthMonth.text;
	var birthYearFilter:Boolean = (txtPatientBirthYear.text == 'year' || txtPatientBirthYear.text == '') ? true : item.dob.substr(6,4) == txtPatientBirthYear.text;
	
	var genderFilter:Boolean = dropPatientsSex.selectedIndex == 0 ? true : item.sex == dropPatientsSex.selectedItem.label;

	var notifFilter:Boolean = showPatientsAll.selected ? true : item.urgency != "Not urgent";
	
	return searchFilter && birthDayFilter && birthMonthFilter && birthYearFilter && genderFilter && notifFilter;
}

private function filterPatientsSearchModule(item:Object):Boolean {
	var pattern:RegExp = new RegExp("[^]*"+patientModuleSearch.text+"[^]*", "i");
	var searchFilter:Boolean = (patientModuleSearch.text == 'First Name, Last Name, or ID Number' || patientModuleSearch.text == '') ? true : (pattern.test(item.lastName) || pattern.test(item.firstName));
	
	var selectedUrgencies:Array = [];
	for each(var urgency:Object in arrUrgencies.source) {
		if(urgency.selected) selectedUrgencies.push(urgency);
	}
	var urgencyFilter:Boolean = false;
	for each(var selectedUrgency:Object in selectedUrgencies) {
		if(selectedUrgency.label == item.urgency) {
			urgencyFilter = true;
			break;
		}
	}
	
	var selectedTeams:Array = [];
	for each(var team:Object in arrTeams.source) {
		if(team.selected) selectedTeams.push(team);
	}
	var teamsFilter:Boolean = false;
	for each(var selectedTeam:Object in selectedTeams) {
		if(String(selectedTeam.label).substr(5) == item.team) {
			teamsFilter = true;
			break;
		}
	}
	
	var patternAdvName:RegExp = new RegExp("[^]*"+txtAdvFirstLast.text+"[^]*", "i");
	var searchAdvName:Boolean = (txtAdvFirstLast.text == 'e.g., Arthur Adams' || txtAdvFirstLast.text == '') ? true : (patternAdvName.test(item.lastName) || patternAdvName.test(item.firstName));
	
	var birthDayFilter:Boolean = (txtAdvBirthDay.text == 'dd' || txtAdvBirthDay.text == '') ? true : item.dob.substr(3,2) == txtAdvBirthDay.text;
	var birthMonthFilter:Boolean = (txtAdvBirthMonth.text == 'mm' || txtAdvBirthMonth.text == '') ? true : item.dob.substr(0,2) == txtAdvBirthMonth.text;
	var birthYearFilter:Boolean = (txtAdvBirthYear.text == 'year' || txtAdvBirthYear.text == '') ? true : item.dob.substr(6,4) == txtAdvBirthYear.text;
	
	var selectedSexes:Array = [];
	for each(var sex:Object in arrSexes.source) {
		if(sex.selected) selectedSexes.push(sex);
	}
	var sexFilter:Boolean = false;
	for each(var selectedSex:Object in selectedSexes) {
		if(selectedSex.label == item.sex) {
			sexFilter = true;
			break;
		}
	}
	
	var minAgeFilter:Boolean = (txtAdvAgeFrom.text == '##' || txtAdvAgeFrom.text == '') ? true : calculateAge(item.dob) >= uint(txtAdvAgeFrom.text);
	var maxAgeFilter:Boolean = (txtAdvAgeTo.text == '##' || txtAdvAgeTo.text == '') ? true : calculateAge(item.dob) <= uint(txtAdvAgeTo.text);
	
	var patternID:RegExp = new RegExp("[^]*"+txtAdvID.text+"[^]*", "i");
	var idFilter:Boolean = (txtAdvID.text == '#########' || txtAdvID.text == '') ? true : patternID.test(item.id);
	
	var patternSSN:RegExp = new RegExp("[^]*"+txtAdvSSN.text+"[^]*", "i");
	var ssnFilter:Boolean = (txtAdvSSN.text == '###-##-####' || txtAdvSSN.text == '') ? true : patternSSN.test(item.ssn);
	
	var patternSponsorSSN:RegExp = new RegExp("[^]*"+txtAdvSponsorSSN.text+"[^]*", "i");
	var sponsorSSNFilter:Boolean = (txtAdvSponsorSSN.text == '###-##-####' || txtAdvSponsorSSN.text == '') ? true : patternSponsorSSN.test(item.sponsorSSN);
	
	return searchFilter && urgencyFilter && teamsFilter && searchAdvName && birthDayFilter && birthMonthFilter && birthYearFilter && sexFilter && minAgeFilter && maxAgeFilter && idFilter && ssnFilter && sponsorSSNFilter;
}

[Bindable] public var providersModel:ProvidersModel = new ProvidersModel();

private function providersResultHandler(event:ResultEvent):void {
	
	var results:ArrayCollection = event.result.providers.provider;
	
	var teams:Array = [ {label:"All",value:-1} ];
	
	var providers:ArrayCollection = new ArrayCollection();
	
	for each(var result:Object in results)
	{
		var provider:ProviderModel = ProviderModel.fromObj(result);
		provider.id = providers.length;
		providers.addItem( provider );
		
		if( provider.id == ProviderConstants.USER_ID ) ApplicationController.getInstance().user = provider;
		
		var team:Object = {label:"Team " + provider.team, value: provider.team};
		if( teams[provider.team] == null ) teams[provider.team] = team;
	}
	
	providersModel.providers = providers;
	providersModel.providerTeams = new ArrayCollection( teams );
	
	controller.providers = ChatController.getInstance().model.providers = providers;
	
	initChatHistory();
}

private var autocompleteCallback:Function;
private var autocomplete:AutoComplete;

private function onShowAutoComplete( event:AutoCompleteEvent ):void
{
	if( !autocomplete )
	{
		autocomplete = new AutoComplete();
		autocomplete.addEventListener( Event.CHANGE, onAutocompleteSelect );
		autocomplete.addEventListener( AutoCompleteEvent.HIDE, onHideAutoComplete );
	}
	
	autocomplete.targetField = event.targetField;
	autocomplete.callbackFunction = event.callbackFunction;
	autocomplete.labelFunction = event.labelFunction;
	autocomplete.dataProvider = event.dataProvider;
	autocomplete.width = event.desiredWidth ? event.desiredWidth : event.targetField.width;
	autocomplete.backgroundColor = event.backgroundColor;
	
	PopUpManager.addPopUp( autocomplete, this );
}

private function onHideAutoComplete( event:AutoCompleteEvent = null ):void
{
	if( autocomplete )
	{
		PopUpManager.removePopUp( autocomplete );
	}
}

private function onAutocompleteSelect( event:IndexChangeEvent ):void
{
	autocomplete.callbackFunction( event );
}

private function initChatHistory():void
{
	if( !ChatController.getInstance().model.providers || !ChatController.getInstance().model.patients ) return;
	
	var user:UserModel = controller.getUser( ProviderConstants.USER_ID, UserModel.TYPE_PROVIDER );
	
	var today:Date = ApplicationController.getInstance().today;
	var time:Number = today.getTime();
	
	var defs:Array = 
		[ 
			{time: time - (DateUtil.DAY * 1 + DateUtil.DAY * .7 * Math.random()), id: 123, type: UserModel.TYPE_PATIENT},
			{time: time - (DateUtil.DAY * 3 + DateUtil.DAY * .7 * Math.random()), id: 123, type: UserModel.TYPE_PATIENT},
			{time: time - (DateUtil.MONTH * .9 + DateUtil.DAY * .7 * Math.random()), id: 123, type: UserModel.TYPE_PATIENT},
			{time: time - (DateUtil.MONTH * 4 + DateUtil.DAY * 3 + DateUtil.DAY * .7 * Math.random()), id: 1, type: UserModel.TYPE_PROVIDER}
		];
	
	for each(var def:Object in defs)
	{
		var start:Date = new Date();
		start.setTime( def.time );
		
		var end:Date = new Date();
		end.setTime( start.time + (DateUtil.HOUR * Math.random()) );
		
		user.addChat( new Chat( user, controller.getUser( def.id, def.type ), start, end ) );
	}
	
	appointmentsXMLdata.send();
}

private function onNavigate(event:ApplicationEvent):void
{
	var module:INavigatorContent;
	
	if( event.data is int )
	{
		viewStackProviderModules.selectedIndex = event.data;
		
		module = viewStackProviderModules.selectedChild;
	}
	else if( event.data is String )
	{
		if( this.currentState == 'providerHome' ) 
		{
			var moduleName:String = event.data.toString();
			
			if( this.viewStackProviderModules.getChildByName( moduleName ) ) 
			{
				module = this.viewStackProviderModules.getChildByName( moduleName ) as INavigatorContent;
				
				this.viewStackProviderModules.selectedChild = module;
				
				if( event.data == ProviderConstants.MODULE_MESSAGES )
				{
					createNewMessage( 1 );
					
					viewStackMessages.selectedIndex = viewStackMessages.length - 2;
				}
				
				if( this.viewStackMain.selectedIndex != 0 )
				{
					this.viewStackMain.selectedIndex = 0;
				}
			}
		}
	}
	
	if( module )
	{
		if( module is TeamModule )
		{
			if( event.user )
			{
				TeamModule(module).showTeamMember( event.user );
			}
		}
	}
	
	onHideAutoComplete();
}

private function toggleAvailability(event:MouseEvent):void
{
	var button:LinkButton = LinkButton(event.currentTarget);
	
	var user:UserModel = ApplicationController.getInstance().user;
	
	user.available = user.available == UserModel.STATE_AVAILABLE ? UserModel.STATE_UNAVAILABLE : UserModel.STATE_AVAILABLE;
	
	button.setStyle('color',user.available == UserModel.STATE_AVAILABLE ? 0xCCCC33 : 0xB3B3B3 );
}

public function falsifyWidget(widget:String):void 
{
}

/**
 * User context menu
*/
private var userContextMenu:UserContextMenu;
private var userContextMenuTimer:Timer;

private function onShowContextMenu(event:ApplicationEvent):void 
{
	if( userContextMenu ) hideContextMenu();
	
	userContextMenu = new UserContextMenu();
	userContextMenu.user = event.user;
	userContextMenu.addEventListener( ProfileEvent.VIEW_PROFILE, onUserAction );
	userContextMenu.addEventListener( ProfileEvent.VIEW_APPOINTMENTS, onUserAction );
	userContextMenu.addEventListener( ProfileEvent.SEND_MESSAGE, onUserAction );
	userContextMenu.addEventListener( ProfileEvent.START_CHAT, onUserAction );
	
	userContextMenu.x = this.stage.mouseX;
	userContextMenu.y = this.stage.mouseY;
	
	PopUpManager.addPopUp( userContextMenu, DisplayObject(mx.core.FlexGlobals.topLevelApplication) );
	
	userContextMenuTimer.reset();
	userContextMenuTimer.start();
}

private function hideContextMenu():void
{
	userContextMenu.removeEventListener( ProfileEvent.VIEW_PROFILE, onUserAction );
	userContextMenu.removeEventListener( ProfileEvent.VIEW_APPOINTMENTS, onUserAction );
	userContextMenu.removeEventListener( ProfileEvent.SEND_MESSAGE, onUserAction );
	userContextMenu.removeEventListener( ProfileEvent.START_CHAT, onUserAction );
	
	PopUpManager.removePopUp( userContextMenu );
}

private function onUserAction( event:ProfileEvent ):void
{
	var evt:ApplicationEvent;
	
	if( event.type == ProfileEvent.VIEW_PROFILE )
	{
		evt = new ApplicationEvent( ApplicationEvent.NAVIGATE, true );
		evt.data = ProviderConstants.MODULE_TEAM;
		evt.user = event.user;
		this.dispatchEvent( evt );
	}
	else if( event.type == ProfileEvent.VIEW_APPOINTMENTS )
	{
		if( AppointmentsController.getInstance().model.selectedProviders.getItemIndex( event.user ) == -1 )
		{
			AppointmentsController.getInstance().model.selectedProviders.addItem( event.user );
		}
		
		evt = new ApplicationEvent( ApplicationEvent.NAVIGATE, true );
		evt.data = ProviderConstants.MODULE_APPOINTMENTS;
		this.dispatchEvent( evt );
	}
	else if( event.type == ProfileEvent.SEND_MESSAGE )
	{
		var message:Message = new Message();
		message.recipients = [ event.user ];
		
		evt = new ApplicationEvent( ApplicationEvent.NAVIGATE, true );
		evt.data = ProviderConstants.MODULE_MESSAGES;
		evt.message = message;
		this.dispatchEvent( evt );
	}
	else if( event.type == ProfileEvent.START_CHAT )
	{
		ChatController.getInstance().chat( ApplicationController.getInstance().user, event.user );
	}
	
	hideContextMenu();
}

private function onUserMenuDelay( event:TimerEvent ):void
{
	if( userContextMenu 
		&& userContextMenu.parent )
	{
		if( !userContextMenu.hitTestPoint(this.stage.mouseX,this.stage.mouseY)
			&& !userContextMenu.chatModes.hitTestPoint(this.stage.mouseX,this.stage.mouseY) )
		{
			hideContextMenu();
		}
		else
		{
			userContextMenuTimer.reset();
			userContextMenuTimer.start();
		}
	}
}
