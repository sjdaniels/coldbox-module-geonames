component entityName="Geo" output="false" extends="mongoentity.models.ActiveEntity"  {

	// inputs
	property name="country" type="string";
	property name="admin1" type="string";
	property name="admin2" type="string";
	property name="city" type="string";
	property name="placeString" type="string"; // string in Places API autocomplete field
	property name="ruleID" type="string";
	property name="debug" type="struct";

	// calculated by rules_locations based on inputs 
	property name="id" type="numeric";		// the geoID
	property name="tags" type="array";		// array of geoIDs in the hierarchy + add nearest city if isSearchOption=false
	property name="geopoint" type="struct";		// http://docs.mongodb.org/v3.0/reference/geojson/#geojson-point
	property name="aggregator" type="numeric";	// the geoID to aggregate by (admin1 for US,CA,UK; country for all others)

	property name="NameResolver" inject="NameResolver@geonames" persist="false";

	this.EARTH = 6295630;
	this.EMPTY_HASH = "2EDF2958166561C5C08CD228E53BBCDC"; // all inputs are empty
	this.ADMIN_AGGREGATOR_COUNTRIES = [6252001,6251999,2635167];

	this.constraints = {
		"country":{ required:true }
	}

	Geo function set(required string country, required string admin1, required string admin2, required string city, string placeString){
		var originalHash = this.getHash()

		this
			.setCountry(arguments.country)
			.setAdmin1(arguments.admin1)
			.setAdmin2(arguments.admin2)
			.setCity(arguments.city)
			.setRuleID( getHash() )

		if (!isnull(arguments.placeString))
			this.setPlaceString(arguments.placeString);

		if (this.getHash() != originalHash) {
			this
				.setID(nullValue())
				.setTags(nullValue())
				.setGeoPoint(nullValue())
		}

		if (this.getHash() == this.EMPTY_HASH) {
			this
				.setID(this.EARTH)
				.setGeoPoint(nullValue())
		}

		return this;
	}

	Geo function setRegion(required any geoID) {
		if (isnumeric(arguments.geoID))
			this.setID( arguments.geoID );
		else
			this.setID(nullValue()).setTags(nullValue());

		return this;
	}

	boolean function isValidRegion() {
		if (isnull(this.getID()))
			return false;
		if (isnull(this.getTags()))
			return false;

		// for US, need state
		// for CA, need province
		// for UK, need country
		for (local.countryID in this.ADMIN_AGGREGATOR_COUNTRIES) {
			if (this.getTags().find(local.countryID) && this.getID()==local.countryID)
				return false;			
		}
	
		return true;
	}

	string function getPlaceString() {
		var result = super.getPlaceString();
		if (!isnull(result) && len(result))
			return result;

		result = getLabel();
		if (result == "" && !isnull(this.getID())) {
			local.path = NameResolver.getPath(this.getID(),"en");
			if (local.path.types.find("country"))
				this.setCountry(local.path.names[local.path.types.find("country")]);
			if (local.path.types.find("admin1"))
				this.setAdmin1(local.path.names[local.path.types.find("admin1")]);
			if (local.path.types.find("admin2"))
				this.setAdmin2(local.path.names[local.path.types.find("admin2")]);
			if (local.path.types.find("city"))
				this.setCity(local.path.names[local.path.types.find("city")]);
			
			result = getLabel();
		}

		return result;
	}

	string function getHash(){
		return hash( lcase( getConcatenated() ) );
	}

	string function getQuery(){
		return listtoarray( getConcatenated(), "|").reverse().toList(", ");
	}

	string function getConcatenated(){
		return "#this.getCountry()#|#this.getAdmin1()#|#this.getAdmin2()#|#this.getCity()#";
	}

	string function getLabel(){
		return listtoarray(getConcatenated(),"|").reverse().toList(", ");
	}

	Geo function setLatLong(required numeric lat, required numeric lng) {
		arguments.lat = javacast("numeric",arguments.lat);
		arguments.lng = javacast("numeric",arguments.lng);
		return this.setGeoPoint( {"type":"Point", "coordinates":[ arguments.lng, arguments.lat ]} );
	}

	Geo function setID(id){
		super.setID(argumentCollection=arguments)

		if (!isnull(this.getID())){
			// set geoJSON and tags based on GeoNames document
			try {
				if (this.isCity())
					local.geopoint = NameResolver.getGeoPoint(this.getID());

				this.setGeoPoint( local.geopoint?:nullValue() )
					.setTags( NameResolver.getTags(this.getID()) )
					.setAggregator( getAggregatorFromTags() );

			} catch (GeoNamesException local.e) {
				if (local.e.code neq 15) {
					rethrow;
				}

				// invalid GeoNames ID, remove it
				super.setID(nullValue());
			}
		}

		return this;
	}

	any function getAggregatorFromTags(array tags=this.getTags()) {
		var tags = arguments.tags;
		if (this.ADMIN_AGGREGATOR_COUNTRIES.some(function(countryID){ return tags.find(countryID) })) {
			if (arguments.tags.len() gt 3) {
				local.result = arguments.tags[4];
			}
		}
		else { 
			if (arguments.tags.len() gt 2) {
				local.result = arguments.tags[3];
			}
		}

		return local.result ?: nullValue();
	}

	string function getName(){
		var result = NameResolver.getName( this.getID() );
		return result;
	}

	string function getFullName(){
		var result = NameResolver.getFullName( this.getID() );
		return result;
	}

	array function getAltNames(){
		var result = NameResolver.getNearNames( this.getID() );
		return result;
	}

	string function getCountryCode(){
		var result = NameResolver.getCountryCode( this.getID() );
		return result;
	}

	struct function getPath(numeric offset=2, numeric maxdepth=0){
		var result = NameResolver.getPath( this.getID() );
		while (arguments.offset) {
			result.names.deleteAt(1)
			result.ids.deleteAt(1)
			result.types.deleteAt(1)
			arguments.offset--
			if (!result.ids.len())
				break;
		}

		if (arguments.maxdepth) {
			while (result.names.len() gt arguments.maxdepth) {
				result.names.deleteAt( result.names.len() )
				result.ids.deleteAt( result.ids.len() )
				result.types.deleteAt( result.types.len() )
			}
		}

		return result;
	}

	function getAddress(string countrydelim=" - ", boolean adminOnly=false){
		if (isnull(this.getID()))
			return;

		// Change the format for location as follows: 

		var result = "";
		try {
			var path = this.getPath()
		}
		catch (GeoNamesException var e) {
			if (!structkeyexists(e,"code") || e.code != 15)
				rethrow;

			// return null if the GeoName no longer exists.
			return;
		}
		// If we have the city: "Orlando, Florida - United States" 
		if (path.types.find("city") && !arguments.adminOnly){
			result  = '<span class="text-nowrap">#path.names[path.types.find('city')]#'
			if (path.types.find('admin1'))
				result &= ", #path.names[path.types.find('admin1')]#"
			result &=  '</span>#arguments.countrydelim#<span class="text-nowrap">#path.names[path.types.find('country')]#</span>'
			return result;
		}
		// If we have county and no city: "Palm Beach County, Florida - United States" 
		if (path.types.find("admin2") && !arguments.adminOnly){
			result = '<span class="text-nowrap">#path.names[path.types.find('admin2')]#'
			if (path.types.find('admin1'))
				result &= ", #path.names[path.types.find('admin1')]#"
			result &= '</span>#arguments.countrydelim#<span class="text-nowrap">#path.names[path.types.find('country')]#</span>'
			return result;
		}
		// If we have state and no county or city: "Florida - United States" 
		if (path.types.find("admin1")){
			result = "#path.names[path.types.find('admin1')]##arguments.countrydelim##path.names[path.types.find('country')]#"
			return result;
		}
		// If we have only have country: "United States"
		if (path.types.find("country")){
			result = "#path.names[path.types.find('country')]#"
			return result;
		}

		return;
	}

	boolean function isCity() {
		return this.getPath().types.find("city");
	}

	boolean function isEarth(){
		return (this.getID()==this.EARTH);
	}
}