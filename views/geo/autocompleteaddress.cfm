<cfscript>
	param name="args.geo" default="#getInstance('Geo@GeoNames').new()#";
	param name="args.label" default="#$('geo.label_address')#";
	param name="args.placeholder" default="#$('geo.placeholder_address')#";
	param name="args.help" default="";
	param name="args.widthsplit" default="3/5";
	param name="args.isrequired" default="false";
	param name="args.apiKey" default="#getSetting('googleapis').apiKey#";
	param name="args.allowregions" default="false";
	param name="args.fallback" default="true";

	// Google Maps Platform Prohibited Territories 
	// https://cloud.google.com/maps-platform/terms/maps-prohibited-territories
	blockedCountries = [
		 1814991 // China
		,703883 // Crimea
		,3562981 // Cuba
		,130758 // Iran
		,1873107 // North Korea
		,163843 // Syria
		,1562822 // Vietnam
		// ,6252001 // Test USA
	];

	if (blockedCountries.find(getInstance("geoIP2@geoIP").lookup(cgi.remote_addr).getCountryGeoID()?:6252001)) {
		if (!args.fallback)
			return;

		echo(view(view:"geo/form.simple.separated", module:"geonames", args:args));
		return;
	}
</cfscript>
<cfoutput>
<div id="autocompleteaddress_wrapper">
	#view(view:"_form_bs/input",args:{widthsplit:args.widthsplit,name:"placeString",id:"location_picker", help:args.help, label:args.label, data:{allowregions:args.allowregions}, placeholder:args.placeholder,isrequired:args.isrequired,default:event.getValue("placeString",args.geo.getPlaceString()?:"")})#
	#view(view:"_form_bs/hidden",args:{name:"country",id:"address_country",value:event.getValue("country",args.geo.getCountry()?:"")})#
	#view(view:"_form_bs/hidden",args:{name:"admin1",id:"address_admin1",value:event.getValue("admin1",args.geo.getAdmin1()?:"")})#
	#view(view:"_form_bs/hidden",args:{name:"admin2",id:"address_admin2",value:event.getValue("admin2",args.geo.getAdmin2()?:"")})#
	#view(view:"_form_bs/hidden",args:{name:"city",id:"address_city",value:event.getValue("city",args.geo.getCity()?:"")})#
	#view(view:"_form_bs/hidden",args:{name:"street",id:"address_street",value:event.getValue("street",args.geo.getStreet()?:"")})#
	#view(view:"_form_bs/hidden",args:{name:"lat",id:"address_lat",value:event.getValue("lat","")})#
	#view(view:"_form_bs/hidden",args:{name:"lng",id:"address_lng",value:event.getValue("lng","")})#
</div>
<script type="text/javascript">
	initMap = function() {
		return;
	}
</script>
<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key=#args.apiKey#&libraries=places&callback=initMap" defer></script>
<cfif settingExists("appBuild")>
	<script type="text/javascript" src="#event.getModuleRoot('geonames')#/assets/js/autocompleteaddress.min.#getSetting('appBuild')#.js" defer></script>
<cfelse>
	<script type="text/javascript" src="#event.getModuleRoot('geonames')#/assets/js/autocompleteaddress.min.js" defer></script>
</cfif>
</cfoutput>
