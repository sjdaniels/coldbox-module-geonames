component {

	this.title 				= "GeoNames Management & API Module";
	this.author				= "Sean Daniels";
	this.webURL				= "http://www.braunsmedia.com";
	this.description		= "Module for GeoNames API";
	this.version 			= "1.0";

	this.dependencies		 = ["mongoentity"];

	// The module entry point using SES
	this.entryPoint     = "geonames";
	function configure(){
		settings = {
			apiKey    = ""
		,	username  = ""	
		,	url  = "http://api.geonames.org"	
		,	premiumUrl  = "http://ws.geonames.net"	
		}

		parentSettings = {
			geonamesKey	= "istanbulnotconstantinople"
		}
		
		interceptors = [
			{ class="#moduleMapping#.interceptors.Security", name="#this.title# Security" }
		];

		binder.map("Country@GeoNames")
			.to("#moduleMapping#.models.Countries")
	}

	function onLoad(){		
		var mapper = wirebox.getInstance("mongoentity.models.AutoMapper");
		var scanLocations = {"#moduleMapping#/models":expandpath("#moduleMapping#/models")}
		var mapped = mapper.mapEntities( scanLocations );
		var mongoentities = controller.getSetting( "mongoentities" );
		mongoentities.append(mapped, true);
		controller.setSetting("mongoentities", mongoentities);
	}
}