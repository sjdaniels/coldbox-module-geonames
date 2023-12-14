<cfscript>
	param name="args.geo" default="#getInstance('Geo@GeoNames').new()#";
	param name="args.label" default="#$('geo.label_location')#";
	param name="args.help" default="";
	param name="args.widthsplit" default="3/5";
	param name="args.subsetcountries" default="false";
	param name="args.countriesRequireAdmin" default="#[6252001,6251999,2635167]#";
	param name="args.withpreferred" default="false";

	args.widthsplit = args.widthsplit.listToArray("/");

	if (!event.privateValueExists( "geoSelectRegionAssetsAdded" )) {
		html.addAsset(asset:"#event.getModuleRoot('geonames')#/assets/js/selectregion.js", defer:true);
		prc.geoSelectRegionAssetsAdded = true;
	}

	selectedcountry = event.getValue("countryID",args.geo.getID()?:"");
	if (!event.valueExists("countryID") && !isnull(args.geo.getTags())) {
		for (country in args.countriesRequireAdmin) {
			if (args.geo.getTags().find(country))
				selectedcountry = country;
		}
	}
</cfscript>
<cfoutput>
<div class="row mb-3 geo-selectregion">
	<label for="region" class="col-form-label text-sm-end col-sm-#args.widthsplit[1]#">#args.label#</label>
	<div class="col-sm-#args.widthsplit[2]#">
		<div id="countries" class="mb-1">
			#renderview(view:"_form_bs/select", args:{widthsplit:"", name:"countryID", options:getInstance("RegionService@geonames").getCountryOptions(lang:getFwLang(), select:args.subsetcountries, withpreferred:args.withpreferred), default:selectedcountry})#
		</div>
		<cfloop array="#args.countriesRequireAdmin#" item="country">
			<div class="#selectedcountry==country?'':'inithidden'# row-space-1 geo-subselect geo-#country#">
				#renderview(view:"_form_bs/select", args:{widthsplit:"", name:"admin1_#country#", options:getInstance("RegionService@geonames").getAdminOptions(getFwLang(), country), default:event.getValue("admin1_#country#",args.geo.getID()?:"")})#
			</div>
		</cfloop>
		<cfif args.subsetcountries>
			<div class="#selectedcountry=='other'?'':'inithidden'# row-space-1 geo-subselect geo-other">
				#renderview(view:"_form_bs/select", args:{widthsplit:"", name:"continentID", options:getInstance("RegionService@geonames").getContinentOptions(getFwLang()), default:event.getValue("continentID",args.geo.getID()?:"")})#
			</div>
		</cfif>
	</div>
	<cfif len(trim(args.help))>
		<span class="help-block offset-sm-#args.widthsplit[1]# col-sm-#(12-args.widthsplit[1])#">#args.help#</span>
	</cfif>
	#renderview(view:"_form_bs/hidden", args:{name:"regionID", value:event.getValue("regionID",args.geo.getID()?:"")})#
</div>
</cfoutput>
