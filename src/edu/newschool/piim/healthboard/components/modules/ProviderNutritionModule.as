package edu.newschool.piim.healthboard.components.modules
{
	import edu.newschool.piim.healthboard.components.popups.nutrition.AddFoodNotePopup;
	import edu.newschool.piim.healthboard.components.popups.nutrition.FoodPlanPopup;
	import edu.newschool.piim.healthboard.model.PatientModel;
	import edu.newschool.piim.healthboard.model.module.nutrition.FoodPlan;
	import edu.newschool.piim.healthboard.view.modules.NutritionModule;
	
	import flash.events.MouseEvent;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.TitleWindow;
	
	public class ProviderNutritionModule extends NutritionModule
	{
		private var _patient:PatientModel;
		
		public function ProviderNutritionModule()
		{
			super();
			
			currentState = "provider";
		}
		
		override protected function init():void 
		{
			super.init();
			
			hgNutrition.removeElement(vgRecordIntake);
			hgNutrition.removeElement(vLine1);
			hgNutrition.addElementAt(vgTotalCaloriesTaken,0);
			hgFoodPlate.removeElement(vLine2);
			vgTotalCaloriesTaken.addElementAt(nutJournalDate,0);
			vgMealList.paddingTop = 46;
			hgFoodPlate.addElement(vgFoodPlateDetails);
		}
		
		override protected function onSetFoodPlanClick(event:MouseEvent):void
		{
			var popup:FoodPlanPopup = FoodPlanPopup( PopUpManager.createPopUp(AppProperties.getInstance().controller.application, FoodPlanPopup) as TitleWindow );
			popup.patient = patient as PatientModel;
			PopUpManager.centerPopUp( popup );
		}
		
		override protected function onAddCommentsClick(event:MouseEvent):void
		{
			var popup:AddFoodNotePopup = AddFoodNotePopup( PopUpManager.createPopUp(AppProperties.getInstance().controller.application, AddFoodNotePopup) as TitleWindow );
			popup.addEventListener( CloseEvent.CLOSE, onAddNoteClose );
			PopUpManager.centerPopUp( popup );
		}
		
		private function onAddNoteClose(event:CloseEvent):void
		{
			var popup:AddFoodNotePopup = AddFoodNotePopup( event.currentTarget );
			
			if( event.detail == Alert.YES )
			{
				var note:Object = { note: popup.message.text, recommendation: popup.recommendation.selectedItem.label, urgency: popup.urgency.selectedItem.data, completed:false, removed:false };
				
				foodPlan.addNote( note );
			}
			
			PopUpManager.removePopUp( popup );
		}

		
		public function get patient():PatientModel
		{
			return _patient;
		}
		
		public function set patient(value:PatientModel):void
		{
			_patient = value;
			
			BindingUtils.bindProperty(this,'foodPlan',patient,'foodPlan');
		}

	}
}
