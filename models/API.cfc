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
			 "username":api.username
			,"token":api.token
			,"orderby":arguments.orderby
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

		// AlertBox.marker("Calling #getUrl()#/searchJSON?#local.querystring#")
		http url="#getUrl()#/searchJSON?#local.querystring#" result="local.cfhttp" {}

		try {
			local.response = deserializeJSON(local.cfhttp.filecontent)
		} catch (any e) {
			throwAPIException(local.cfhttp)
		}

		if (!structkeyexists(local.response,"geonames"))
			throwAPIException(local.response)

		if (local.response.geonames.len())
			result = local.response.geonames;

		return result;
	}

	public array function getHierarchy(required numeric geoID, string lang, string style="MEDIUM") {
		http url="#getUrl()#/hierarchyJSON" result="local.cfhttp" {
			httpparam name="username" value="#api.username#" type="url";
			httpparam name="token" value="#api.token#" type="url";
			httpparam name="geonameId" value="#arguments.geoID#" type="url";
			httpparam name="style" value="#arguments.style#" type="url";
			if (!isnull(arguments.lang))
				httpparam name="lang" value="#arguments.lang#" type="url";
		}

		try {
			local.response = deserializeJSON(local.cfhttp.filecontent)
		} catch (any local.e) {
			throwAPIException(local.cfhttp)
		}

		if (isnull(local.response.geonames)) {
			throwAPIException(local.response)
		}
		return local.response.geonames;
	}

	public any function findNearbyPlaceName(required numeric lat, required numeric lng, string lang, string style="FULL", string cities, boolean localCountry=true, numeric radius=25, numeric maxrows=10){
		http url="#getUrl()#/findNearbyPlaceNameJSON" result="local.cfhttp" {
			httpparam name="username" value="#api.username#" type="url";
			httpparam name="token" value="#api.token#" type="url";
			httpparam name="style" value="#arguments.style#" type="url";
			httpparam name="lat" value="#arguments.lat#" type="url";
			httpparam name="lng" value="#arguments.lng#" type="url";
			httpparam name="radius" value="#arguments.radius*1.609#" type="url"; // arguments.radius * 1.609 converted to km
			httpparam name="maxRows" value="#arguments.maxrows#" type="url";
			httpparam name="localCountry" value="#arguments.localCountry#" type="url";
			if (!isnull(arguments.cities))
				httpparam name="cities" value="#arguments.cities#" type="url";
		}

		local.response = deserializeJSON(local.cfhttp.filecontent)

		try {
			if (!local.response.geonames.len())
				return;
		} catch (any local.e) {
			throwAPIException(local.response);
		}

		return local.response;
	}

	public array function getChildren(required numeric geoID){
		http url="#getUrl()#/childrenJSON" result="local.cfhttp" {
			httpparam name="username" value="#api.username#" type="url";
			httpparam name="token" value="#api.token#" type="url";
			httpparam name="geonameId" value="#arguments.geoID#" type="url";
		}

		local.response = deserializeJSON(local.cfhttp.filecontent)
		return local.response.geonames;
	}

	public array function getNeighbors(required numeric geoID){
		var staticResult = getStaticNeighbors( arguments.geoID );
		if (!isnull(staticResult))
			return staticResult;

		http url="#getUrl()#/neighboursJSON" result="local.cfhttp" {
			httpparam name="username" value="#api.username#" type="url";
			httpparam name="token" value="#api.token#" type="url";
			httpparam name="geonameId" value="#arguments.geoID#" type="url";
		}

		local.response = deserializeJSON(local.cfhttp.filecontent)
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
		http url="#getUrl()#/getJSON" result="local.cfhttp" {
			httpparam name="username" value="#api.username#" type="url";
			httpparam name="token" value="#api.token#" type="url";
			httpparam name="geonameId" value="#arguments.geoID#" type="url";
			httpparam name="style" value="#arguments.style#" type="url";
			if (!isnull(arguments.lang))
				httpparam name="lang" value="#arguments.lang#" type="url";
		}

		local.response = deserializeJSON(local.cfhttp.filecontent);

		if (!local.response.keyExists("geonameID")) {
			local.response["geonameID"] = arguments.geoID;
			throwAPIException(local.response);
		}

		return local.response;
	}

	public any function getByPostalCode(required string postalcode, string lang, string style="FULL", string country) {
		http url="#getUrl()#/postalCodeSearchJSON" result="local.cfhttp" {
			httpparam name="username" value="#api.username#" type="url";
			httpparam name="token" value="#api.token#" type="url";
			httpparam name="postalcode" value="#arguments.postalcode#" type="url";
			httpparam name="style" value="#arguments.style#" type="url";
			if (isnull(arguments.country))
				httpparam name="countryBias" value="US" type="url";
			else 
				httpparam name="country" value="#arguments.country#" type="url";
			if (!isnull(arguments.lang))
				httpparam name="lang" value="#arguments.lang#" type="url";
		}

		local.response = deserializeJSON(local.cfhttp.filecontent)

		try {
			if (!local.response.postalcodes.len())
				return;
		} catch (any local.e) {
			throwAPIException(local.response);
		}

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
		http url="#getUrl()#/timezoneJSON" result="local.cfhttp" {
			httpparam name="username" value="#api.username#" type="url";
			httpparam name="token" value="#api.token#" type="url";
			httpparam name="lat" value="#arguments.lat#" type="url";
			httpparam name="lng" value="#arguments.lng#" type="url";
			if (!isnull(arguments.radius))
				httpparam name="radius" value="#arguments.radius#" type="url";
			if (!isnull(arguments.lang))
				httpparam name="lang" value="#arguments.lang#" type="url";
		}

		local.response = deserializeJSON(local.cfhttp.filecontent)
		// if (isnull(local.response.geonames)) {
		// 	throwAPIException(local.response)
		// }
		return local.response;
	}

	public array function getCountries(){
		var result = []
		
		http url="#getUrl()#/countryInfoJSON" result="local.cfhttp" {
			httpparam name="username" value="#api.username#" type="url";
			httpparam name="token" value="#api.token#" type="url";
			httpparam name="style" value="FULL" type="url";
		}

		local.response = deserializeJSON(local.cfhttp.filecontent)
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

			http url="#api.premiumUrl#/viewAccount" result="local.cfhttp" {
				httpparam name="username" value="#api.username#" type="url";
				httpparam name="token" value="#api.token#" type="url";
			}

			var result = {}

			try{
				var resultXML = XmlParse(local.cfhttp.filecontent)
			} catch (any local.e) {
				throwAPIException(local.cfhttp.filecontent)
			}

			resultXML.XmlRoot.XmlChildren.each(function(element){ result[element.XmlName] = element.XmlText })

			result["isPremium"] = ( result.creditsTotalUsed lt result.creditsTotal && datecompare(now(),result.validTillDate) lt 0 )

			// cache for 2 hours
			cache.set(cachekey,result,120)
		}

		return cache.get(cachekey);
	}

}