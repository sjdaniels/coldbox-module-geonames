<cfscript>
	param name="args.geo" default="#getInstance('Geo@GeoNames').new()#";
	param name="args.geos" default="#[]#";
	param name="args.label" default="#$('geo.label_location')#";
	param name="args.placeholder" default="#$('geo.placeholder_location')#";
	param name="args.help" default="";
	param name="args.widthsplit" default="3/5";
	param name="args.isrequired" default="false";
	param name="args.apiKey" default="#getSetting('googleapis').apiKey#";
	param name="args.multiple" default="false";
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
	];

	if (args.fallback && blockedCountries.find(getInstance("geoIP2@geoIP").lookup(cgi.remote_addr).getCountryGeoID()?:6252001)) {
		if (!args.fallback)
			return;

		echo(view(view:"geo/form.simple.separated", module:"geonames", args:args));
		return;
	}
</cfscript>
<cfoutput>
<cfif args.multiple>
	<div id="autocompleteplaces_wrapper" data-multiple="#args.multiple#">
</cfif>
	#view(view:"_form_bs/input",args:{widthsplit:args.widthsplit,name:"#args.multiple?'placeTextEntry':'placeString'#",id:"location_picker", help:args.help, label:args.label, placeholder:args.placeholder,isrequired:args.isrequired,default:args.multiple?"":event.getValue("placeString",args.geo.getPlaceString()?:"")})#
	<cfif args.multiple>
		<div class="row">
			<div class="col-sm-#listlast(args.widthsplit,'/')# offset-sm-#listfirst(args.widthsplit,'/')#">
				<div class="list-group" id="multiplacevalues_wrapper">
					<cfloop array="#args.geos#" item="geo" index="ii">
						<div class="multiplacevalues list-group-item">
							<a href="##" class="removeable float-end"><i class="fas fa-times-square"></i></a>
							<i class="fas fa-fw fa-map-marker-alt"></i> #geo.getPlaceString()#
							<input type="hidden" name="placeString[]" value="#geo.getPlaceString()?:""#">
							<input type="hidden" name="country[]" value="#geo.getCountry()?:""#">
							<input type="hidden" name="admin1[]" value="#geo.getAdmin1()?:""#">
							<input type="hidden" name="admin2[]" value="#geo.getAdmin2()?:""#">
							<input type="hidden" name="city[]" value="#geo.getCity()?:""#">
						</div>
					</cfloop>
				</div>
			</div>
		</div>
	<cfelse>
		#view(view:"_form_bs/hidden",args:{name:"country",id:"location_country",value:event.getValue("country",args.geo.getCountry()?:"")})#
		#view(view:"_form_bs/hidden",args:{name:"admin1",id:"location_admin1",value:event.getValue("admin1",args.geo.getAdmin1()?:"")})#
		#view(view:"_form_bs/hidden",args:{name:"admin2",id:"location_admin2",value:event.getValue("admin2",args.geo.getAdmin2()?:"")})#
		#view(view:"_form_bs/hidden",args:{name:"city",id:"location_city",value:event.getValue("city",args.geo.getCity()?:"")})#
		#view(view:"_form_bs/hidden",args:{name:"countrycode",id:"location_countrycode",value:event.getValue("countrycode","")})#
		#view(view:"_form_bs/hidden",args:{name:"admin1code",id:"location_admin1code",value:event.getValue("admin1code","")})#
	</cfif>
<cfif args.multiple>
	</div>
</cfif>
<script type="text/javascript">
	initMap = function() {
		return;
	}
</script>
<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key=#args.apiKey#&libraries=places&callback=initMap" defer></script>
<cfif settingExists("appBuild")>
	<script type="text/javascript" src="#event.getModuleRoot('geonames')#/assets/js/autocompleteplaces.min.#getSetting('appBuild')#.js" defer></script>
<cfelse>
	<script type="text/javascript" src="#event.getModuleRoot('geonames')#/assets/js/autocompleteplaces.min.js" defer></script>
</cfif>
</cfoutput>
