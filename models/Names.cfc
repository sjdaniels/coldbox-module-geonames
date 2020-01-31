component output="false" entityname="GeoNames" collection="geo_names" extends="mongoentity.models.ActiveEntity"  {

	property name="id" type="numeric";
	property name="name" type="struct"; // en, zh
	property name="type" type="string";
	property name="path" type="array";
	property name="pathTypes" type="array";
	property name="pathNames" type="struct"; // en=[], zh=[]
	property name="geopoint" type="struct" index="geopoint" indexvalue="2dsphere"; // http://docs.mongodb.org/v3.0/reference/geojson/#geojson-point
	property name="rank" type="struct"; // { collection=count }
	property name="ascii" type="string"; 
	property name="abbr" type="string" default=""; 
	property name="bbox" type="struct"; 
	property name="fcl" type="string"; // feature class
	property name="fcode" type="string"; // feature code
	property name="isSearchOption" type="boolean"; 
	property name="population" type="numeric"; 
	property name="isocode" type="string"; // ISO code for countries (ISO 3166-1) and admin1 (ISO 3166-2) 
	property name="depth" type="numeric"; 
	property name="nearestSearchOption" type="numeric"; // if isSearchOption = false, nearest city in same ADM1 where isSearchOption = true 
	property name="neighbors" type="array"; // array of neighboring geoIDs, only available if added by GeoNamesService.updateNeighbors 
	property name="countryCode" type="string"; // iso country code 

	property name="i18n" inject="i18n@cbi18n" persist="false";

	public ActiveEntity function init(){
		super.init();
		this.getCollectionIndexes()
			.append({ name:"path_depth", unique:false, sparse:false, fields:["path","depth"] })
			.append({ name:"path_type", unique:false, sparse:false, fields:["path","type"] })
			.append({ name:"type_country", unique:false, sparse:false, fields:["type","countryCode"] })
		
		return this;
	}

	public any function get(required numeric id, boolean returnNew=true){
		arguments.id = javacast("numeric",arguments.id);
		return super.get( argumentCollection:arguments );
	}

	public string function getName(string lang=i18n.getFwLanguageCode()) {
		if (!structkeyexists(variables["name"],arguments.lang))
			return "{{" & variables["name"]["en"] & "}}";

		return variables["name"][arguments.lang];
	}

	public array function getPathNames(string lang=i18n.getFwLanguageCode()) {
		if (!structkeyexists(variables["pathNames"],arguments.lang)) {
			var result = []
			variables["pathNames"]["en"].each(function(name){
				result.append("{{#name#}}")
			})
			return result;
		}

		return variables["pathNames"][arguments.lang];
	}

	public numeric function getRank(required string collection){
		local.rank = super.getRank();
		if (isnull(local.rank))
			return 0;

		if (!structkeyexists(local.rank,arguments.collection))
			return 0;

		return local.rank[arguments.collection];
	}

	public void function updaterank(required array geonamesUsage, required AlertBox AlertBox){
		var MongoDB = getMongoDB()
		var Locations = getCollection()
		for (var usage in arguments.geonamesUsage) {
			Locations.update({},{"$set":{"rank.#usage.collection#":0}},false,true)

			AlertBox.info("Reset ranks for #usage.collection#");

			local.pipeline = [
				 {"$unwind":"$#usage.key#.tags"}
				,{"$group":{"_id":"$#usage.key#.tags","count":{"$sum":1}}}
			]

			if (!isnull(usage.match)) {
				local.pipeline.prepend( { "$match":usage.match } )
			}

			local.counts = MongoDB
							.getCollection( usage.collection )
							.aggregate(local.pipeline)
							.results()

			AlertBox.info("Found #numberformat(local.counts.len())# unique locations for #usage.collection# (#!isnull(usage.match)?serializeJSON(usage.match):'no criteria'#)")

			for (local.item in local.counts) {
				Locations.update({"_id":local.item["_id"]},{"$set":{ "rank.#usage.collection#":local.item["count"] }})
			}

			AlertBox.info("Updated location rankings for #usage.collection#")
		}
	}

	// required for selectRelated
	public array function getNodePath(numeric nodeID) {
		local.node = this.findWhere({ "_id":javacast("numeric",arguments.nodeID) });

		if ( isnull(local.node) ) 
			return [];

		var result = []
		// skip earth
		for (local.i=2; local.i lte local.node.getPath().len(); local.i++) {
			result.append(local.node.getPath()[i])
		}

		return result;
	}

	public string function getNameByType(required string type, string lang=i18n.getFwLanguageCode()) {
		local.pathtypes = this.getPathTypes();
		if (!local.pathtypes.find(arguments.type))
			return "";

		return this.getPathNames(arguments.lang)[ local.pathtypes.find(arguments.type) ];
	}

	// required for selectRelated
	public query function getChildren(numeric nodeID, numeric depth) {
		var criteria = {}
		var items = ""

		arguments.depth = javacast("numeric",arguments.depth);
		arguments.nodeID = javacast("numeric",arguments.nodeID);
		criteria = { "$and":[{"depth":arguments.depth+1},{"isSearchOption":true}]}
		if (arguments.nodeID) {
			arrayappend( criteria["$and"], { "path":arguments.nodeID } )
		}

		items = this.list( criteria:criteria, asQuery:false );

		var result = querynew("id,name,type");

		loop array="#items#" item="item" {
			queryaddrow(result);
			querySetCell(result, "id", item.getID())
			querySetCell(result, "name", item.getName())
			querySetCell(result, "type", "location")
		}

		querysort(result,"name");
		return result;
	}

	public struct function getFilterOptions(numeric geoID, numeric toplimit=10, numeric hardlimit=50, string topSort="population desc"){
		// returns { children:array, [topchildren:array], [adm2children:array], [geoname:model.Names] }
		var result = {}

		if (isnull(arguments.geoID)){
			// top tier
			result.children = this.list(criteria:{ "path":6295630, "depth":2, "isSearchOption":true }, asQuery:false)
			result.topchildren = result.children
		} else {
			local.geoID = javacast("numeric",arguments.geoID)
			result.geoname = this.get(local.geoID)
			local.path = result.geoname.getPath();
			local.pathsize = result.geoname.getDepth()

			if (result.geoname.getType()=="admin1") {
				local.toppathcriteria = { "$and":[{"isSearchOption":true},{"path":local.geoID},{"depth":{"$gt":local.pathsize}},{"fcode":{"$ne":"ADM2"}}] }
				local.nextpathcriteria = { "$and":[{"isSearchOption":true},{"path":local.geoID},{"depth":{"$gt":local.pathsize}},{"fcode":{"$ne":"ADM2"}}] }
				local.nextpathlimit = arguments.hardlimit
				local.adm2pathcriteria = { "$and":[{"isSearchOption":true},{"path":local.geoID},{"depth":local.pathsize+1},{"fcode":"ADM2"}] }
			} else {
				local.nextpathcriteria = { "$and":[{"isSearchOption":true},{"path":local.geoID},{"depth":local.pathsize+1}] }
				local.toppathcriteria = local.nextpathcriteria
				local.nextpathlimit = 0
			}

			result.children = this.list(criteria:local.nextpathcriteria, asQuery:false, limit:local.nextpathlimit, sortorder:"population desc")
			if (result.children.len() gt 10)
				result.topchildren = this.list(criteria:local.toppathcriteria, asQuery:false, sortorder:arguments.topSort, limit:arguments.toplimit)
		
			if (!isnull(local.adm2pathcriteria))
				result.adm2children = this.list(criteria:local.adm2pathcriteria, asQuery:false)
		}


		// sort by localized names
		result.children.sort(function(a,b){
			return compare( a.getName(), b.getName() )
		});

		if (!isnull(result.topchildren)) {
			result.topchildren.sort(function(a,b){
				return compare( a.getName(), b.getName() )
			})
		}

		if (!isnull(result.adm2children)) {
			result.adm2children.sort(function(a,b){
				return compare( a.getName(), b.getName() )
			})
		}

		return result;
	}

	public function getFullName(string lang=i18n.getFwLanguageCode()) {
		var result = this.getName(argumentCollection = arguments);
		// Continent: Continent name
		// Country: Country name, i.e. "Canada"
		if (["continent","country"].find(this.getType())) {
			return result;
		}
		// Admin1: Admin1 name if US, CA, UK, i.e. "Maine". Otherwise, "Admin1, Country"
		if (this.getType()=="admin1") {
			if (["US","CA"].find(this.getCountryCode())) {
				return result;
			}
			return result & ", " & this.getNameByType("country",arguments.lang);
		}
		// Admin2: Admin2 name, Admin1 Abbr if US, UK, CA, i.e., "York County, ME". Admin2 name, country name for all other.
		// City: Same as Admin2.		
		if (["admin2","city","region"].find(this.getType())) {
			if (arguments.lang=="en" && this.getType()=="admin2")
				result = this.getAscii(); // so we get the version with "County" appended

			if (["US","CA"].find(this.getCountryCode())) {
				local.parent = this.getCollection().findOne( {"_id":this.getPath()[4]} );
				return result & ", " & (local.parent.abbr ?: (local.parent.name[arguments.lang] ?: local.parent.name["en"]));
			}
			return result & ", " & this.getNameByType("country",arguments.lang);
		}

	}
}