package models
{
	import flash.utils.describeType;

	[Bindable]
	public class ProviderModel extends UserModel
	{
		//	baisc
		public var age:String;
		public var birthday:String;
		
		//	contact
		public var email:String;
		public var phone:String;
		
		//	address
		public var street1:String;
		public var street2:String;
		public var city:String;
		public var state:String;
		public var zip:String;
		
		public var education:String;
		
		//	work
		public var location:String;
		public var office:String;
		public var certification:String;
		public var department:String;
		public var specialty:String;
		public var status:String;
		public var role:String;
		
		//	emergency contact
		public var emergencyName:String;
		public var emergencyRelation:String;
		public var emergencyPhone1:String;
		public var emergencyPhone2:String;
		
		//	security
		public var securityQuestion:String;
		public var securityAnswer:String;
		
		public function ProviderModel()
		{
			super( TYPE_PROVIDER );
		}
		
		override public function get fullName():String
		{
			var name:String = super.fullName;
			
			return (role == 'MD' ? 'Dr. ' : '') + name;
		}
		
		override public function get fullNameAbbreviated():String
		{
			var name:String = super.fullNameAbbreviated;
			
			return (role == 'MD' ? 'Dr. ' : '') + name;
		}
		
		public function clone():ProviderModel
		{
			var val:ProviderModel = new ProviderModel();
			
			var definition:XML = describeType(this);
			
			for each(var prop:XML in definition..accessor)
			{
				if( prop.@access == "readonly" ) continue;
				
				val[prop.@name] = this[prop.@name];
			}
			
			return val;
		}
		
		public function copy( from:ProviderModel ):void
		{
			var definition:XML = describeType(this);
			
			for each(var prop:XML in definition..accessor)
			{
				if( prop.@access == "readonly" ) continue;
				
				this[prop.@name] = from[prop.@name];
			}
		}
		
		public static function fromObj( data:Object ):ProviderModel
		{
			var val:ProviderModel = new ProviderModel();
			
			for (var prop:String in data)
			{
				if( val.hasOwnProperty( prop ) )
				{
					val[prop] = data[prop];
				}
			}
			
			return val;
		}
	}
}