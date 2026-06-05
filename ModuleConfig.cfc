component {

	this.title 				= "GeoNames Management & API Module";
	this.author				= "Sean Daniels";
	this.webURL				= "http://www.braunsmedia.com";
	this.description		= "Module for GeoNames API";
	this.version 			= "1.0";

	this.dependencies		 = ["mongoentity","geoIP"];

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

		controller.getCacheBox().createCache(
			name       = "geoNamesCache",
			provider   = "coldbox.system.cache.providers.CacheBoxProvider",
			properties = {
				maxObjects                    = 150000,
				defaultTimeout                = 10080,
				defaultLastAccessTimeout      = 1440,
				reapFrequency                 = 60,
				evictionPolicy                = "LRU",
				evictCount                    = 500,
				freeMemoryPercentageThreshold = 15,
				objectStore                   = "coldbox.system.cache.store.ConcurrentSoftReferenceStore"
			}
		);
		
		mongoentities.append(mapped, true);
		controller.setSetting("mongoentities", mongoentities);
	}

	function onUnload(){
		if( controller.getCacheBox().cacheExists("geoNamesCache") ){
			controller.getCacheBox().removeCache("geoNamesCache");
		}
	}	
}