component entityname="GeoCountries" collection="geo_countries" extends="mongoentity.models.ActiveEntity" {

	property name="id" type="string";
	property name="geoID" type="numeric" index="geoID" unique="true";
	property name="showAdmin1" type="boolean";
	property name="showAdmin2" type="boolean";

	public Countries function init(){
		super.init();
		arrayappend(this.getCollectionIndexes(),{ name:"alternames", unique:false, sparse:false, fields:["names.name"] })
		return this;
	}

	public void function updateFromGeoNames() {
		var Deployments = getWirebox().getInstance("Deployments")
		var GeoNames = getWirebox().getInstance("API@geonames")
		var Resources = getWirebox().getInstance("Resources")
		var CSV = getWirebox().getInstance("csv@convertedplugins")

		local.countriesmap = CSV.toArray( fileread(expandpath("/assets/src/subdivisions.csv")) )
		local.countriesmap.deleteAt(1)
		var subdivisions = {}
		local.countriesmap.each(function(country){
			subdivisions[country[1]] = {}
			if (len(trim(country[3])))
				subdivisions[country[1]]["Admin1"] = country[3]
			if (len(trim(country[4])))
				subdivisions[country[1]]["Admin2"] = country[4]
		})

		for (local.country in GeoNames.getCountries()) {
			
			local.geocountry = this.get(local.country.countryCode,true)
			local.geocountry
				.setID(local.country.countryCode)
				.setGeoID(local.country.geonameID)
				.setShowAdmin1( structkeyexists(subdivisions[local.country.countryCode],"Admin1") ? true : nullValue() )
				.setShowAdmin2( structkeyexists(subdivisions[local.country.countryCode],"Admin2") ? true : nullValue() )
				.save()

			local.translations = { "en":local.country.countryName }
			for (var lang in Deployments.getSupportedLangs()) {
				if (lang == "en") 
					continue;

				local.translations[lang] = GeoNames.get(geoID:local.country.geonameID, lang:lang, style:"SHORT").name
			}

			// country name resource bundle
			local.rbID = "codes.Countries.#local.country.countryCode#"
			local.resource = Resources.findWhere({"rbID":local.rbID},true)
			local.resource
				.setRbID(local.rbID)
				.setTranslations(local.translations)
				.save()

			// country admin 1 label resource bundle
			if (structkeyexists(subdivisions[local.country.countryCode],"Admin1")){
				local.rbID = "geo.label_admin1.#local.country.countryCode#"
				local.resource = Resources.findWhere({"rbID":local.rbID},true)
				local.translations = local.resource.getTranslations()
				local.translations["en"] = "Select " & subdivisions[local.country.countryCode]["Admin1"] & "..."
				local.resource
					.setRbID(local.rbID)
					.setTranslations(local.translations)
					.save()
			}
			
			// country admin 2 label resource bundle
			if (structkeyexists(subdivisions[local.country.countryCode],"Admin2")){
				local.rbID = "geo.label_admin2.#local.country.countryCode#"
				local.resource = Resources.findWhere({"rbID":local.rbID},true)
				local.translations = local.resource.getTranslations()
				local.translations["en"] = "Select " & subdivisions[local.country.countryCode]["Admin2"] & "..."
				local.resource
					.setRbID(local.rbID)
					.setTranslations(local.translations)
					.save()
			}
		
		}
	}

	public boolean function isShowAdmin1(){
		return this.getShowAdmin1()?:false;
	}

	public boolean function isShowAdmin2(){
		return this.getShowAdmin2()?:false;
	}

}