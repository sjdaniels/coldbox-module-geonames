component output="false" {

	property name="GeoNames" inject="API@GeoNames";
	property name="Names" inject="Names@GeoNames";

	function admin1options(event,rc,prc) cache="true" cachetimeout="1440" {
		prc.contenttype = "HTML";
		local.collection = Names.getCollection();

		local.names = local.collection.find({"type":"admin1","countryCode":rc.countryCode}).toArray()
    	if (!local.names.len()){
    		prc.response = "";
    		return;
    	}

    	prc.options = extractOptions( local.names )
        prc.optionslabel = $("geo.select_admin1")
        prc.response = view(view:"geo/options",module:"geonames")
	}

	function admin2options(event,rc,prc) cache="true" cachetimeout="1440" {
		prc.contenttype = "HTML";
		local.collection = Names.getCollection();

		local.names = local.collection.find({"type":"admin2","countryCode":rc.countryCode,"admin1Code":rc.admin1Code}).toArray()

    	if (!local.names.len()){
    		prc.response = "";
    		return;
    	}

    	prc.options = extractOptions( local.names )
        prc.optionslabel = $("geo.select_admin2")
        prc.response = view(view:"geo/options",module:"geonames")
	}

	function countryoptions(event,rc,prc,renderOut=false) cache="true" cachetimeout="1440" {
		prc.contenttype = "HTML";
		local.collection = Names.getCollection();

		local.countries = local.collection.find({"type":"country"}).toArray()
    	prc.options = extractOptions( local.countries )
        prc.optionslabel = $("geo.select_country")
        prc.response = view(view:"geo/options",module:"geonames")
        if (renderOut) {
        	return prc.response;
        }
	}

	private array function extractOptions(required array geonames){
		var result = []
		var lang = getSetting(name:"lang",defaultValue:"en")

		arguments.geonames.each(function(geoname){
			local.name = geoname.name[lang]?:geoname.name["en"]
			if (structkeyexists(geoname,"admin1Name"))
				local.name &= ", " & (geoname.admin1Name[lang]?:geoname.admin1Name["en"])
			if (structkeyexists(geoname,"admin2Name"))
				local.name &= " (" & (geoname.admin2Name[lang]?:geoname.admin2Name["en"]) & ")"
			result.append({ "label":local.name, "name":geoname.name[lang]?:geoname.name["en"], "id":geoname._id, "countryCode":geoname.countryCode, "admin1Code":geoname.admin1Code?:nullValue(), "admin2Code":geoname.admin2Code?:nullValue() })
		})

		result.sort(function(a,b){
			return compare(a.name,b.name);
		})

		return result;
	}

    function autocompletecities(event,rc,prc) {
    	var cities = []
    	var AlertBox = getInstance("AlertBox@convertedplugins")

    	local.args = {
    		 "type":"city"
    		,"countryCode":rc.countryCode
    		,"alternates.lower":{"$regex":"^#lcase(rc.q)#"}
    		,"alternates.lang":getSetting("lang")
		}

		if (len(trim(event.getValue("admin1Code",""))))
			local.args["admin1Code"] = rc.admin1Code

		if (len(trim(event.getValue("admin2Code",""))))
			local.args["admin2Code"] = rc.admin2Code

		local.collection = Names.getCollection();
		
		AlertBox.marker("Sending query to MongoDB")
		local.results = local.collection.find(local.args,{"name":1,"countryCode":1,"admin1Code":1,"admin2Code":1,"admin1Name":1,"admin2Name":1}).limit(12).toArray()
		AlertBox.marker("Finished query: #serializeJSON(local.args)#")

		cities = extractOptions( local.results )

        prc.response = { "cities":cities }
    }

	function noauth(event,rc,prc) {
        prc.response = {"error":"Invalid security key #event.getValue('secretkey','[no key provided!]')#."}
    }

}