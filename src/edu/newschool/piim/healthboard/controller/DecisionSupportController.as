package edu.newschool.piim.healthboard.controller
{
	import edu.newschool.piim.healthboard.view.components.itemrenderers.chart.MyCircleItemRenderer;
	
	import edu.newschool.piim.healthboard.enum.RiskLevel;
	
	import edu.newschool.piim.healthboard.model.PatientModel;
	import edu.newschool.piim.healthboard.model.modules.decisionsupport.DecisionSupportModel;
	import edu.newschool.piim.healthboard.model.modules.decisionsupport.RiskFactor;
	
	import mx.charts.ChartItem;
	import mx.charts.chartClasses.Series;
	import mx.charts.renderers.BoxItemRenderer;
	import mx.charts.series.LineSeries;
	import mx.charts.series.items.LineSeriesItem;
	import mx.core.ClassFactory;
	import mx.graphics.IFill;
	
	import edu.newschool.piim.healthboard.view.styles.ChartStyles;

	public class DecisionSupportController extends BaseModuleController
	{
		public function DecisionSupportController()
		{
			super();
			
			model = new DecisionSupportModel();
		}
		
		public function getRangeForRiskFactor( riskFactor:RiskFactor, patient:PatientModel ):Array
		{
			var range:Array = [];
			
			if( riskFactor.id == 'blood_pressure' ) return [60,180];
			if( riskFactor.id == 'blood_sugar' ) return [75,150];
			if( riskFactor.id == 'cholesterol' ) return [100,300];
			if( riskFactor.id == 'smoking' ) return [-4,20];
			if( riskFactor.id == 'weight' ) return [160,210];
			
			return [0,0];
		}
		
		public function getRiskLevelLabel( riskLevel:String ):String
		{
			if( riskLevel == RiskLevel.NONE ) return 'None';
			if( riskLevel == RiskLevel.ROUTINE ) return 'Routine';
			if( riskLevel == RiskLevel.AFFECTED ) return 'Affected';
			if( riskLevel == RiskLevel.LOW ) return 'Low';
			if( riskLevel == RiskLevel.HIGH ) return 'High';
			
			return '';
		}
		
		public function getRiskUnitLabel( riskFactor:RiskFactor ):String
		{
			if( riskFactor.id == 'blood_pressure' ) return 'mmHg';
			if( riskFactor.id == 'blood_sugar' ) return 'mg/dL';
			if( riskFactor.id == 'cholesterol' ) return 'mg/dL';
			if( riskFactor.id == 'weight' ) return 'pounds';
			if( riskFactor.id == 'smoking' ) return 'cigarettes per day';
			
			return '';
		}
		
		public function fillFunction(element:ChartItem, index:Number):IFill 
		{
			var item:LineSeriesItem = LineSeriesItem(element);
			var chartStyles:ChartStyles = AppProperties.getInstance().controller.model.chartStyles;
			
			return (item.item.type == 'provider') ? chartStyles.colorVitalSignsProvider : chartStyles.colorVitalSignsPatient;
		}
	}
}