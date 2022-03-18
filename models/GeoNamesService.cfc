component output="false" {

	property name="API" inject="API@geonames";

	// provider injection
	function getNames() provider="Names@geonames" {};
	function getNears() provider="Nears@geonames" {};

	this.EARTH = 6295630;
	this.CONT = {
		 "AS":6255147
		,"AF":6255146
		,"SA":6255150
		,"EU":6255148
		,"NA":6255149
		,"OC":6255151
		,"AN":6255152
	}
	this.FCODES = {
		 "AREA":"planet"
		,"CONT":"continent"
		,"PCL":"country"
		,"TERR":"country"
		,"ADM1":"admin1"
		,"ADM2":"admin2"
		,"PPL":"city"
	}

	void function rebuildCollection(required MongoDB, required array languages, required array geonamesUsage, AlertBox){
		local.collection = MongoDB.getCollection(getNames().getCollectionName() & "_new");
		local.collection.drop()
		
		local.batchsize = 1000
		local.letters = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]

		local.searchargs = {
			 maxrows:local.batchsize
			,orderby:"population"
			,style:"FULL"
			,searchlang:"en"
		}

		// first, Earth
		local.earth = API.get(6295630)
		insertGeonames( local.collection, [local.earth], arguments.languages )
		AlertBox.log("Added 1 GeoNames document (Earth).")

		// next, continents
		local.imported = 0
		local.searchargs.featureCode = "CONT"
		local.offset = 0

		local.items = API.search(argumentCollection=local.searchargs);
		insertGeonames( local.collection, local.items, arguments.languages )
		local.imported += local.items.len();

		AlertBox.log("Added #numberformat(local.imported)# GeoNames documents (continents).")


		// next, countries
		local.imported = 0
		local.searchargs.featureCode = "PCL,PCLI,PCLD,PCLS,PCLF,PCLIX,TERR"
		local.offset = 0

		while (true) {
			local.searchargs.offset = local.offset;
			local.items = API.search(argumentCollection=local.searchargs);
			insertGeonames( local.collection, local.items, arguments.languages )
			
			local.offset += local.batchsize;
			local.imported += local.items.len();
			if (local.items.len() lt local.batchsize)
				break;
		}

		AlertBox.log("Added #numberformat(local.imported)# GeoNames documents (countries).")

		// next, Admin 1
		local.imported = 0
		local.searchargs.featureCode = "ADM1"
		local.offset = 0

		while (true) {
			local.searchargs.offset = local.offset;
			local.items = API.search(argumentCollection=local.searchargs);
			insertGeonames( local.collection, local.items, arguments.languages )
			
			local.offset += local.batchsize;
			local.imported += local.items.len();
			if (local.items.len() lt local.batchsize)
				break;
		}

		AlertBox.log("Added #numberformat(local.imported)# GeoNames documents (ADM1).")


		// next, Admin 2, incrementally by continent, so we don't reach the 25,000 offset limit
		for (local.cont in this.CONT) {
			local.imported = 0
			local.searchargs.featureCode = "ADM2"
			local.searchargs.continentCode = local.cont
			local.offset = 0

			while (true) {
				local.searchargs.offset = local.offset;
				local.items = API.search(argumentCollection=local.searchargs);

				insertGeonames( local.collection, local.items, arguments.languages )
				
				local.offset += local.batchsize;
				local.imported += local.items.len();

				if (local.items.len() lt local.batchsize)
					break;
			}
			
			Alertbox.log( "Processed #numberformat(local.imported)# Admin 2 locations in continent #local.cont#." )
		}

		// next, Cities5000, inrementally by letter of the alphabet, so we don't reach the 25,000 offset limit
		structdelete(local.searchargs,"featureCode")
		for (local.cont in this.CONT) {
			local.imported = 0
			local.searchargs.cities = "cities5000"
			local.searchargs.continentCode = local.cont
			local.offset = 0

			while (true) {
				local.searchargs.offset = local.offset;
				local.items = API.search(argumentCollection=local.searchargs);

				insertGeonames( local.collection, local.items, arguments.languages )
				
				local.offset += local.batchsize;
				local.imported += local.items.len();

				if (local.items.len() lt local.batchsize)
					break;
			}
			
			Alertbox.log( "Processed #numberformat(local.imported)# cities5000 locations in continent #local.cont#." )
		}

		// finally, do any geos for which the parent application has rules that are not covered by all of the above
		rebuildMissing( MongoDB, local.collection, arguments.languages, arguments.geonamesUsage, Alertbox )
		// expand the hierarchies
		expandPathNames( local.collection, arguments.languages, Alertbox )
		// find missing timezones
		updateMissingTZ( local.collection, AlertBox )
		// re-index!
		getNames().ensureIndexes(collection:local.collection);
		// update nearestSearchOption
		updateNearestSearchOption( local.collection, AlertBox );

		// finally replace.
		local.collection.renameCollection("geo_names", true);
	}

	void function rebuildMissing(required MongoDB, required collection, required array languages, required array geonamesUsage, Alertbox) {
		if (!arguments.geonamesUsage.len()){
			AlertBox.error("The framework setting <strong>geonamesUsage</strong> must be set in parent application for missing geos to be rebuilt.")
			return;
		}

		local.missingGeos = missingInUse(arguments.MongoDB, arguments.geonamesUsage, (getNames().getCollectionName() & "_new"), arguments.AlertBox);
		AlertBox.info("Found #numberformat(local.missingGeos.len())# missing geoIDs in use in parent application.");

		local.insertmissing = [];
		local.nolongervalid = [];
		for (local.geoID in local.missingGeos){
			try {
				local.geoname = API.get(local.geoID);
				local.insertmissing.append(local.geoname);
			} catch (GeoNamesException local.e) {
				if (local.e.code == 15 || local.e.code == 11)
					local.nolongervalid.append(local.geoID);
				else 
					rethrow; 
			}
		}

		if (local.nolongervalid.len())
			AlertBox.error("The following geo IDs are in use and no longer exists at GeoNames: #local.nolongervalid.toList()#");

		insertGeonames( arguments.collection, local.insertmissing, arguments.languages, false );
		AlertBox.info("Imported #numberformat(local.insertmissing.len())# missing geoIDs.");
	}

	void function expandPathNames(required collection, required array languages, AlertBox, numeric geoID){
		if (isnull(arguments.AlertBox)) {
			var AlertBox = { warn:function(){}, info:function(){}, marker:function(){} }
		}

		local.pathsCriteria = {}
		local.namesCriteria = {"pathNames":nullValue()}

		// expand just specific geoID
		if (!isnull(arguments.geoID)) {
			local.geo = arguments.collection.findOne({"_id":arguments.geoID});
			local.pathsCriteria = { "_id":{"$in":local.geo.path} };
			local.namesCriteria = { "_id":arguments.geoID };
		}

		local.namesmap = {}
		local.typesmap = {}
		local.geos = arguments.collection.find(local.pathsCriteria,{"name":1, "type":1});
		while (local.geos.hasNext()){
			local.geo = local.geos.next()
			local.namesmap[local.geo._id] = local.geo.name;
			local.typesmap[local.geo._id] = local.geo.type;
		}

		local.items = arguments.collection.find(local.namesCriteria)
		AlertBox.warn("Found #numberformat(local.items.size())# locations to expand.")
		while (local.items.hasNext()) {
			local.item = local.items.next();
			local.item["pathNames"] = {}
			for (local.lang in arguments.languages){
				local.item["pathNames"][local.lang] = []
				for (local.parent in local.item.path){
					local.item["pathNames"][local.lang].append( local.namesmap[local.parent][local.lang]?:nullValue() )
				}
			}
			local.item["pathTypes"] = []
			for (local.parent in local.item.path){
				local.item["pathTypes"].append( local.typesmap[local.parent]?:nullValue() )
				if (!structkeyexists(local.typesmap,local.parent))
					AlertBox.error("No parent record for hierarchy member #local.parent#!")
			}

			arguments.collection.save(local.item);
			if (!local.items.numSeen() mod 10000)
				AlertBox.marker("Expanded path names and types for #numberformat(local.items.numSeen())# geonames")
		}
	}

	void function insertGeonames(required collection, required array items, required array languages, boolean isSearchOption=true){
		local.buffer = []
		for (local.item in arguments.items){
			local.searchOption = arguments.isSearchOption;

			// don't include antarctica in search options
			if (local.item.geonameID==6255152)
				local.searchOption = false;
			
			if (!local.item.keyExists("fcode"))
				local.item["fcode"] = "000";

			local.geo = {
				 "_id":local.item.geonameID
				,"geopoint":{ "type":"Point", "coordinates":[ javacast("numeric",local.item.lng), javacast("numeric",local.item.lat) ] }
				,"population":local.item.population?:0
				,"fcode":local.item.fcode
				,"fcl":local.item.fcl
				,"isSearchOption":local.searchOption
			}

			if (structkeyexists(local.item,"countryCode"))
				local.geo["countryCode"] = local.item.countryCode;

			if (structkeyexists(this.FCODES, left(local.item.fcode,3)))
				local.geo["type"] = this.FCODES[left(local.item.fcode,3)]
			else
				local.geo["type"] = this.FCODES[local.item.fcode] ?: "region"

			if (local.geo["type"] == "country")
				local.geo["isocode"] = local.item.countryCode;
			if (local.geo["type"] == "admin1")
				local.geo["isocode"] = local.item.adminCode1;

			if (!isnull(local.item.bbox))
				local.geo["bbox"] = local.item.bbox
			if (!isnull(local.item.asciiname))
				local.geo["ascii"] = local.item.asciiname

			if (!isnull(local.item.timezone))
				local.geo["timezone"] = local.item.timezone

			local.altnames = {}
			for (local.altname in local.item.alternatenames?:[]){
				if (structkeyexists(local.altname,"lang") && (!structkeyexists(local.altnames,local.altname["lang"]) || !isnull(local.altname.isShortName) || !isnull(local.altname.isPreferredName)))
					local.altnames[local.altname["lang"]] = local.altname["name"]
			}

			local.geo["name"] = {}
			for (local.lang in arguments.languages){
				local.geo.name[local.lang] = local.altnames[local.lang] ?: local.item.name
			}

			if ((local.item.countryCode?:"") eq "US" && (local.item.adminTypeName?:"") eq "state")
				local.geo["abbr"] = local.item.adminCode1;
			if ((local.item.countryCode?:"") eq "CA" && (local.item.adminTypeName?:"") eq "province")
				local.geo["abbr"] = local.item.adminCodes1.ISO3166_2 ?: local.altnames["abbr"];
			if (local.item.geonameID eq 4138106)
				local.geo["abbr"] = "DC";

			local.geo["path"] = [this.EARTH]
			
			if (!isnull(local.item.continentcode)){
				local.geo.path.append( this.CONT[local.item.continentCode] ) 
				if (!isnull(local.item.countryID))
					local.geo.path.append( javacast("numeric",local.item.countryID) )
				if (!isnull(local.item.adminID1))
					local.geo.path.append( javacast("numeric",local.item.adminId1) )
				if (!isnull(local.item.adminId2))
					local.geo.path.append( javacast("numeric",local.item.adminId2) )
			}

			if (!local.geo.path.find(local.item.geonameId))
				local.geo.path.append( local.item.geonameId )

			// fix Monaco, Nepal, etc where there is a node below this node in heirarchy
			if (local.geo.path.last() != local.item.geonameId)
				local.geo.path.deleteAt(local.geo.path.len());

			local.geo["depth"] = local.geo.path.len()

			// local.buffer.append(local.geo)
			arguments.collection.save(local.geo)
		}

		// if (local.buffer.len())
		// 	arguments.collection.insert( local.buffer )
	}

	void function updateMissingTZ(required collection, AlertBox) {
		local.items = arguments.collection.find({"timezone":{"$exists":0}});
		AlertBox.warn("Found #numberformat(local.items.size())# geos with no timezone info");
		while (local.items.hasNext()) {
			local.item = local.items.next();
			local.tz = API.getTimezone(lat:local.item.geopoint.coordinates[2], lng:local.item.geopoint.coordinates[1], radius:50);
			if (isnull(local.tz.timezoneID))
				continue;

			local.item["timezone"]["timeZoneId"] = local.tz.timezoneID;
			arguments.collection.save(local.item);
		}
	}

	void function updateNearestSearchOption(required collection, AlertBox, numeric geoID) {
		if (isnull(arguments.AlertBox)) {
			var AlertBox = { warn:function(){}, info:function(){}, marker:function(){} }
		}

		if (isnull(arguments.geoID))
			local.items = arguments.collection.find({"isSearchOption":false});
		else 
			local.items = arguments.collection.find({"_id":arguments.geoID});
		
		AlertBox.warn("Found #numberformat(local.items.size())# geos needing nearestSearchOption");
		while (local.items.hasNext()) {
			local.item = local.items.next();
			local.criteria = {"type":"city", "isSearchOption":true, "geopoint":{"$near":{"$geometry":local.item.geopoint}}}
			if (local.item.pathTypes.find("admin1"))
				local.criteria["path"] = local.item.path[ local.item.pathTypes.find("admin1") ];
			local.nearest = arguments.collection.findOne(local.criteria);
			if (isnull(local.nearest))
				continue;

			local.item["nearestSearchOption"] = local.nearest._id;
			arguments.collection.save(local.item);
		
			if (!local.items.numSeen() mod 1000)
				AlertBox.marker("Processed #numberformat(local.items.numSeen())#");
		}
	}

	void function updateNeighbors(required Alertbox AlertBox, string type="admin1", array parents=[6252001,6251999,2635167]) {
	// currently Geonames only supports admin1 for US. 
		var Geos = getNames().getCollection();

		loop array="#arguments.parents#" item="local.parent" {
			local.parentName = Geos.findOne({"_id":local.parent});

			local.items = Geos.find({"type":arguments.type, "path":local.parent});
			AlertBox.info("Found #numberformat(local.items.size())# geos of type #arguments.type# in #local.parentName.ascii#.");

			while (local.items.hasNext()) {
				local.item = local.items.next();
				local.neighbors = API.getNeighbors( local.item._id );
				local.item["neighbors"] = [];
				for (local.geo in local.neighbors) {
					local.item["neighbors"].append( local.geo.geonameId );
				}

				if (local.item["neighbors"].len()) {
					Geos.save(local.item);
					AlertBox.log("Saved #local.item["neighbors"].len()# neighbors for #local.item.ascii#");
				}
			}
		}
	}

	void function updateNears(required Alertbox AlertBox) {
		var Geos = getNames().getCollection();
		var Nears = getNears().getCollection();

		// first do cities. near is other cities in 25 mi radius
		var cities = Geos.find({"type":"city"});
		AlertBox.info("Found #numberformat(cities.count())# cities to process.");

		while (cities.hasNext()) {
			local.city = cities.next();
			local.crit = {
				 "geopoint":{"$geoWithin":{"$centerSphere":[local.city.geopoint.coordinates, (25/3963.2)]}} // 25 miles 
				,"type":"city"
				,"_id":{"$ne":local.city._id}
			}
			local.near = Geos.find(local.crit,{"_id":1}).toArray().map((doc)=>doc._id);
			Nears.save(["_id":local.city._id, "nears":local.near, "type":"city"]);
			
			if (!cities.numSeen() mod 10000)
				AlertBox.marker("Processed #numberformat(cities.numSeen())#");
		}

		// now, admin2. near is neighbor admin2s
		var admin2s = Geos.find({"type":"admin2", "path":{"$in":[6252001,6251999,2635167]}});
		AlertBox.info("Found #numberformat(admin2s.count())# admin2s to process.");

		while (admin2s.hasNext()) {
			local.geo = admin2s.next();
			local.near = API.getNeighbors( local.geo._id ).map((doc)=>doc.geonameID);
			Nears.save(["_id":local.geo._id, "nears":local.near, "type":"admin2"]);

			if (!admin2s.numSeen() mod 100)
				AlertBox.marker("Processed #numberformat(admin2s.numSeen())#");
		}

	}

	array function missingInUse(required MongoDB, required array geonamesUsage, required string collectionName, required AlertBox) {
		if (!arguments.geonamesUsage.len()){
			AlertBox.error("The framework setting <strong>geonamesUsage</strong> must be set in parent application for missing geos to be rebuilt.")
			return;
		}

		local.missingGeos = [];
		for (local.usage in arguments.geonamesUsage){
			Alertbox.log("#local.missingGeos.len()# missing so far");
			Alertbox.log("Looking for geos in use in #local.usage.collection#.#local.usage.key#");
			local.pipe = [
				 {"$match":{"#local.usage.key#.id":{"$ne":nullValue()}}}
				,{"$lookup":{"from":arguments.collectionName, "localField":"#local.usage.key#.id", "foreignField":"_id", "as":"geo"}}
				,{"$unwind":{"path":"$geo", "preserveNullAndEmptyArrays":true}}
				,{"$match":{"geo":nullValue()}}
				,{"$group":{"_id":"$#local.usage.key#.id"}}			
			]
			local.geoIDs = MongoDB.getCollection(local.usage.collection).aggregate(local.pipe).results();
			for (local.geoID in local.geoIDs) {
				local.missingGeos.append( local.geoID["_id"] );
			}
		}

		return local.missingGeos;
	}
}