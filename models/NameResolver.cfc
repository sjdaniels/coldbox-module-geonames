component singleton="true" {

	property name="MongoDB" inject="id";
	property name="i18n" inject="i18n@cbi18n";
	property name="timer" inject="timer@cbdebugger";
	property name="Deployments" inject="id";
	property name="API" inject="API@geonames";
	property name="GeoNamesService" inject="GeoNamesService@geonames";
	property name="RegionService" inject="RegionService@geonames";

	function getNamesEntity() provider="Names@geonames" {}
	function getNears() provider="Nears@geonames" {}

	function init(){
		refreshdays = 600
		return this; 
	}

	function setupCollection() onDIComplete {
		names = MongoDB.getCollection("geo_names")
	}

	struct function getGeo(required numeric geoID) {
		arguments.geoID = javacast("numeric",arguments.geoID)
		var name = names.findOne({"_id":arguments.geoID})

		if (isnull(name))
			name = updateGeo(arguments.geoID)
	
		return name;
	}

	struct function getGeoPoint(required numeric geoID) {
		var name = getGeo(geoID)
		return name.geopoint;
	}

	array function getTags(required numeric geoID) {
		var name = getGeo(geoID)
		return name.path;
	}

	string function getCountryCode(required numeric geoID) {
		var name = getGeo(geoID)
		return (name.countryCode ?: "");
	}

	struct function getPath(required numeric geoID, string lang) {
		var name = getGeo(geoID)

		if (isnull(arguments.lang))
			arguments.lang = i18n.getFwLanguageCode()

		if (!structkeyexists(name.pathNames,arguments.lang)){
			var pathNames = []
			name.pathNames["en"].each(function(name){
				pathNames.append("{{#name#}}")
			});
			name.pathNames[arguments.lang] = pathNames
		}

		return { "ids":name.path, "names":name.pathNames[arguments.lang], "types":name.pathTypes };
	}

	string function getName(required numeric geoID, string lang) {
		var name = getGeo(geoID)
		if (isnull(arguments.lang))
			arguments.lang = i18n.getFwLanguageCode()

		if (!structkeyexists(name.name,arguments.lang))
			return "{{#name.name["en"]#}}";

		return name.name[arguments.lang];
	}

	string function getFullName(required numeric geoID, string lang=i18n.getFwLanguageCode()) {
		var name = getGeo(geoID)
		var nameEntity = getNamesEntity();

		nameEntity.populateFromDoc(nameEntity,name);
		return nameEntity.getFullName(arguments.lang);
	}

	string function getTextIndexContent(required numeric geoID, string lang=i18n.getFwLanguageCode()) {
		var name = getGeo(arguments.geoID);
		var result = name.pathNames.keyExists(arguments.lang)?name.pathNames[arguments.lang]:name.pathNames["en"];
		var offset = 2; // always trim off Earth and Continent
		while (offset) {
			result.deleteAt(1)
			offset--
			if (!result.len())
				break;
		}

		// add region name for US admin1 and below
		if (name.path.find(6252001) && ["admin1","admin2","city"].find( name.type )) {
			local.paths = getPath(arguments.geoID, arguments.lang);
			var admin1 = local.paths.ids[ local.paths.types.find("admin1") ];
			RegionService.getAdHocRegions()
				.filter((region)=>region.type=="usregion" && region.geoID.find(admin1))
				.each((region)=>{
					result.append(region.label);
				});
		}

		return result.toList(" ");
	}

	array function getNearNames(required numeric geoID, string lang=i18n.getFwLanguageCode()) {
		var nameEntity = getNamesEntity();
		var nears = getNears().get(arguments.geoID);

		if (isnull(nears) || !(nears.getNears()?:[]).len())
			return [];

		local.geos = nameEntity.listAsIterator({"_id":{"$in":nears.getNears()}});
		var result = [];
		while (local.geos.hasNext()) {
			result.append(local.geos.next().getName(arguments.lang));
		}

		return result;
	}

	string function getType(required numeric geoID) {
		var name = getGeo(geoID)
		return name.type;
	}

	// find "nearby" locations. Radius only applies to cities, all other types return neighbors
	any function getNearby(required numeric geoID, numeric radius, numeric limit) {
		var name = getGeo(geoID);
		var result = [];

		if (name.type eq "continent" || name.type eq "planet")
			return arguments.geoID;

		local.logmsg = "Expanding locations for #name.type# #name.ascii?:''#";
		if (name.type eq "city")
			local.logmsg &= " - radius #arguments.radius#";
		else 
			local.logmsg &= " - nearest #arguments.limit#";

		timer.start(local.logmsg);

		if (name.type eq "city") {
			local.items = names.find({
				 "geopoint":{"$geoWithin":{"$centerSphere":[name.geopoint.coordinates, (arguments.radius/3963.2)]}} // N miles 
				,"isSearchOption":true
				,"type":"city"
			},{"_id":1});
		} else {
			local.items = names.find({
				 "geopoint":{"$near":{"$geometry":name.geopoint}} 
				,"isSearchOption":true
				,"type":name.type
			},{"_id":1}).limit( arguments.limit+1 ); // +1 because we include original. we want original + arguments.limit more 
		}

		while (local.items.hasNext()) {
			result.append( local.items.next()._id );
		}

		timer.stop(local.logmsg);

		if (!result.len())
			return arguments.geoID;

		return result;
	}

	struct function updateGeo(required numeric geoID) {
		timer.start('Getting missing GeoName #arguments.geoID#');
			local.geo = API.get( arguments.geoID )
			GeoNamesService.insertGeonames( names, [ local.geo ], Deployments.getSupportedLangs(), false )
			GeoNamesService.expandPathNames( collection:names, languages:Deployments.getSupportedLangs(), geoID:arguments.geoID )
			GeoNamesService.updateNearestSearchOption( collection:names, geoID:arguments.geoID )
		timer.stop('Getting missing GeoName #arguments.geoID#');
		
		local.result = names.findOne({"_id":arguments.geoID})
		return local.result;
	}

}