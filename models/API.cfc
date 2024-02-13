component output="false" {

	property name="lang" inject="coldbox:setting:lang";
	property name="AlertBox" inject="AlertBox@convertedplugins";
	property name="cachebox" inject="cachebox";

	/**
	 * Constructor
	 *
	 * @settings The module settings struct
	 * @settings.inject coldbox:moduleSettings:geonames
	 */
	public function init( required settings ){	
		variables.api = {
			 url     	:settings.url
			,premiumUrl	:settings.premiumUrl
			,username	:settings.username
			,token 		:settings.apiKey
		};
		
		return this;
	}

	private string function getUrl(){
		var result =  getAccountInfo().isPremium ? api.premiumUrl : api.url
		return result;
	}

	public array function search(string q, string name, string nameEquals, string startsWith, numeric maxRows, numeric offset=0, any featureClass, any featureCode, numeric fuzzy, any continentCode, any countryCode, any admin1Code, any admin2Code, any cities, string lang=lang, string searchlang, string charset, boolean isNameRequired=false, string style="MEDIUM", string orderby="relevance") {
		var result = []
		if (!isnull(arguments.featureClass) && !isArray(arguments.featureClass))
			arguments.featureClass = listtoarray(arguments.featureClass)
		
		if (!isnull(arguments.featureCode) && !isArray(arguments.featureCode))
			arguments.featureCode = listtoarray(arguments.featureCode)
		
		if (!isnull(arguments.countryCode) && !isArray(arguments.countryCode))
			arguments.countryCode = listtoarray(arguments.countryCode)

		local.params = {
			 "orderby":arguments.orderby
			,"lang":arguments.lang
			,"style":arguments.style
		}

		if (isnull(arguments.nameEquals) && arguments.isNameRequired)
			local.params["isNameRequired"] = true
		if (!isnull(arguments.q))
			local.params["q"] = arguments.q
		if (!isnull(arguments.startsWith))
			local.params["name_startsWith"] = arguments.startsWith
		if (!isnull(arguments.name)) 
			local.params["name"] = arguments.name
		if (!isnull(arguments.nameEquals)) 
			local.params["name_equals"] = arguments.nameEquals
		if (!isnull(arguments.maxrows))
			local.params["maxRows"] = arguments.maxRows
		if (!isnull(arguments.offset))
			local.params["startRow"] = arguments.offset
		if (!isnull(arguments.featureClass))
			local.params["featureClass"] = arguments.featureClass
		if (!isnull(arguments.featureCode))
			local.params["featureCode"] = arguments.featureCode
		if (!isnull(arguments.cities))
			local.params["cities"] = arguments.cities
		if (!isnull(arguments.continentCode))
			local.params["continentCode"] = arguments.continentCode
		if (!isnull(arguments.countryCode))
			local.params["country"] = arguments.countryCode
		if (!isnull(arguments.admin1Code))
			local.params["adminCode1"] = arguments.admin1Code
		if (!isnull(arguments.admin2Code))
			local.params["adminCode2"] = arguments.admin2Code
		if (!isnull(arguments.fuzzy))
			local.params["fuzzy"] = arguments.fuzzy
		if (!isnull(arguments.searchlang))
			local.params["searchlang"] = arguments.searchlang
		if (!isnull(arguments.charset))
			local.params["charset"] = arguments.charset

		local.querystring = ""
		for (local.key in local.params){
			if (isArray(local.params[local.key])){
				for (local.item in local.params[local.key]){
					local.querystring &= "#local.key#=#local.item#&"
				}
			} else {
				local.querystring &= "#local.key#=#local.params[local.key]#&"
			}
		}

		local.response = call("/searchJSON",local.params);

		if (!structkeyexists(local.response,"geonames"))
			throwAPIException(local.response)

		if (local.response.geonames.len())
			result = local.response.geonames;

		return result;
	}

	public array function getHierarchy(required numeric geoID, string lang, string style="MEDIUM") {
		local.params = {
			 "geonameId":arguments.geoID
			,"style":arguments.style
		}

		if (!isnull(arguments.lang))
			local.params["lang"] = arguments.lang;

		local.response = call("/hierarchyJSON", local.params);

		if (isnull(local.response.geonames)) {
			throwAPIException(local.response)
		}
		return local.response.geonames;
	}

	public any function findNearbyPlaceName(required numeric lat, required numeric lng, string lang, string style="FULL", string cities, boolean localCountry=true, numeric radius=25, numeric maxrows=10){
		local.params = {
			 "style":arguments.style
			,"lat":arguments.lat
			,"lng":arguments.lng
			,"radius":arguments.radius*1.609
			,"maxRows":arguments.maxrows
			,"localCountry":arguments.localCountry
		}
		if (!isnull(arguments.cities))
			local.params["cities"] = arguments.cities;

		local.response = call("/findNearbyPlaceNameJSON",local.params);
		return local.response;
	}

	public array function getChildren(required numeric geoID){
		local.params = {
			"geonameId":arguments.geoID
		}

		local.response = call("/childrenJSON", local.params);
		return local.response.geonames;
	}

	public array function getNeighbors(required numeric geoID){
		var staticResult = getStaticNeighbors( arguments.geoID );
		if (!isnull(staticResult))
			return staticResult;

		local.params = {
			"geonameId":arguments.geoID
		}

		local.response = call("/neighboursJSON", local.params);
		return local.response.geonames;
	}

	private any function getStaticNeighbors(required numeric geoID) {
		var geos = [
			 // UK
			 6269131: [2638360,2634895,2641364] // "England"
			,2638360: [6269131,2634895,2641364] // "Scotland"
			,2634895: [6269131,2638360,2641364] // "Wales"
			,2641364: [6269131,2638360,2634895] // "Northern Ireland"
			 // Canada
			,6093943: [6065171,6115047,6091732] // "Ontario"
			,6115047: [6093943,6087430,6354959,6091732,6113358,6091530] // "Quebec"
			,5909050: [6185811,6091069,5883102] // "British Columbia"
			,5883102: [5909050,6091069,6141242] // "Alberta"
			,6065171: [6141242,6091732,6093943] // "Manitoba"
			,6141242: [5883102,6091069,6091732,6065171] // "Saskatchewan"
			,6091530: [6087430,6113358,6115047,6354959] // "Nova Scotia"
			,6087430: [6113358,6091530,6115047,6354959] // "New Brunswick/Nouveau-Brunswick"
			,6354959: [6091732,6087430,6113358,6091530,6115047] // "Newfoundland and Labrador"
			,6113358: [6091530,6115047,6354959,6087430] // "Prince Edward Island"
			,6185811: [6091069,5909050] // "Yukon"
			,6091069: [6185811,5909050,5883102,6141242,6065171,6091732] // "Northwest Territories"
			,6091732: [6091069,6141242,6065171,6093943,6115047,6354959] // "Nunavut"
		];

		if (structKeyExists(geos, arguments.geoID)) {
			local.result = [];
			for (local.geo in geos[arguments.geoID]) {
				local.result.append({"geonameID":local.geo});
			}

			return local.result;
		}

		return;
	}

	public struct function get(required numeric geoID, string lang, string style="FULL"){
		local.params = {
			 "geonameId":arguments.geoID
			,"style":arguments.style
		}
		if (!isnull(arguments.lang))
			local.params["lang"] = arguments.lang;

		local.response = call("/getJSON", local.params);
		
		if (!local.response.keyExists("geonameID")) {
			local.response["geonameID"] = arguments.geoID;
			throwAPIException(local.response);
		}

		return local.response;
	}

	public any function getByPostalCode(required string postalcode, string lang, string style="FULL", string country) {
		local.params = {
			 "postalcode":arguments.postalcode
			,"style":arguments.style
		}

		if (!isnull(arguments.lang))
			local.params["lang"] = arguments.lang;

		if (isnull(arguments.country))
			local.params["countryBias"] = "US";
		else 
			local.params["country"] = arguments.country;

		local.response = call("/postalCodeSearchJSON",local.params);

		local.postalcode = local.response.postalcodes[1]

		if (!isnull(arguments.country) && arguments.country eq "US")
			local.result = search(nameEquals:local.postalcode.placeName, featureClass:"P", countryCode:local.postalcode.countryCode, admin1Code:local.postalcode.adminCode1, admin2Code:local.postalcode.adminCode2?:nullValue(), style:arguments.style);
		else {
			local.nearby = findNearbyPlaceName(local.postalcode.lat, local.postalcode.lng, arguments.lang?:nullValue(), arguments.style, "cities1000");
			if (isnull(local.nearby))
				return;
				
			local.result = local.nearby.geonames;
		}

		if (!local.result.len())
			return;

		return local.result[1];
	}

	public any function getTimezone(required numeric lat, required numeric lng, numeric radius, string lang) {
		local.params = {
			 "lat":arguments.lat
			,"lng":arguments.lng
		}

		if (!isnull(arguments.radius))
			local.params["radius"] = arguments.radius;
		if (!isnull(arguments.lang))
			local.params["lang"] = arguments.lang;

		local.response = call("/timezoneJSON",local.params);
		return local.response;
	}

	public array function getCountries(){
		var result = []

		local.response = call("/countryInfoJSON",{ "style":"FULL" });	

		if (!structkeyexists(local.response,"geonames"))
			throwAPIException(local.response)

		if (local.response.geonames.len())
			result = local.response.geonames;

		return result;
	}

	public array function getAlternateNames(required numeric geoID){
		local.geo = get(arguments.geoID)
		return local.geo.alternatenames;
	}

	private struct function call( required string path, struct params={}, numeric attempt=1 ){
		var params = arguments.params;
		http url="#getURL()##arguments.path#" method="get" result="local.cfhttp" {
			httpparam name="username" value="#api.username#" type="url";
			httpparam name="token" value="#api.token#" type="url";
			loop collection="#params#" item="local.val" index="local.key" {
				if (isArray(local.val)) {
					loop array="#local.val#" item="local.subval" {
						httpparam type="url" name="#local.key#" value="#local.subval#";
					}
				}
				else 
					httpparam type="url" name="#local.key#" value="#local.val#";
			}
		}

		if (local.cfhttp.status_code != 200) {
			local.retry = retryCall( local.cfhttp.status_code, arguments.attempt );
			if (local.retry.shouldretry) {
				AlertBox.marker( "Retrying GeoNames API Call #arguments.path# - attempt #local.retry.nextattempt# - delaying #local.retry.delay#" );
				sleep(local.retry.delay);
				return call( arguments.path, arguments.params, local.retry.nextattempt );
			}
		}

		var result = parseResponse( local.cfhttp );
		return result;
	}

	private any function parseResponse(required struct response) {		
		try {
			var apiResult = deserializeJSON(arguments.response.filecontent);
		} 
		catch (Any local.e) {
			throwAPIException(arguments.response);
		}

		return apiResult;
	}	

	private struct function retryCall( required numeric statusCode, required numeric attempt ) {
		local.retrydelays = [
			 100
			,200
			,300
			,400
			,500
			,1000
			,5000
		];

		var result = { shouldretry:arguments.attempt lte local.retrydelays.len(), nextattempt:arguments.attempt+1 };
		if (result.shouldretry)
			result.delay = local.retrydelays[arguments.attempt];

		return result;
	}

	private void function throwAPIException(required any response){
		throw(type:"GeoNamesException",message:"GeoNames API Exception.",detail:serializeJSON(arguments.response),errorcode:arguments.response.status.value?:0);
	}

	public string function getGeoNameLabel(required struct geoname) {
		var output = []

		if (isnull(arguments.geoname.fcode))
			arguments.geoname.fcode = ""		

		if ((["PCLI","PCLD","PCLIX"]).contains(arguments.geoname.fcode)) {
			output.append(arguments.geoname.name)
		}

		if (arguments.geoname.fcode == "ADM1") {
			output.append(arguments.geoname.name)
			output.append(arguments.geoname.countryname)
		}
		
		if (!output.len()) {
			output.append(arguments.geoname.name)
			output.append(arguments.geoname.adminname1)
			output.append(arguments.geoname.countryname)
		}

		return output.toList(", ");
	}

	public function getAccountInfo(){
		var cache = cachebox.getDefaultCache()
		var cachekey = "geonames-account-info"
		if (!cache.lookup(cachekey)){
			AlertBox.marker("Calling for GeoNames account information...")

			http url="#api.premiumUrl#/viewAccountJSON" result="local.cfhttp" {
				httpparam name="username" value="#api.username#" type="url";
				httpparam name="token" value="#api.token#" type="url";
			}

			var result = {}

			try{
				result = deserializeJSON(local.cfhttp.filecontent)
			} catch (any local.e) {
				throwAPIException(local.cfhttp.filecontent)
			}

			result["isPremium"] = ( result.creditsTotalUsed lt result.creditsTotal && datecompare(now(),result.validTillDate) lt 0 )

			// cache for 2 hours
			cache.set(cachekey,result,120)
		}

		return cache.get(cachekey);
	}
}