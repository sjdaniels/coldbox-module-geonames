<cfscript>
	param name="args.geo" default="#getInstance('Geo@GeoNames').new()#";
	param name="args.label" default="#$('geo.label_location')#";
	param name="args.placeholder" default="#$('geo.placeholder_location')#";
	param name="args.help" default="";
	param name="args.widthsplit" default="3/5";
	param name="args.apiKey" default="#getSetting('googleapis').apiKey#";
</cfscript>
<cfoutput>
#renderview(view:"_form_bs/input",args:{widthsplit:args.widthsplit,name:"placeString",id:"location_picker", help:args.help, label:args.label, placeholder:args.placeholder,default:event.getValue("placeString",args.geo.getPlaceString()?:"")})#
#renderview(view:"_form_bs/hidden",args:{name:"country",id:"location_country",value:event.getValue("country",args.geo.getCountry()?:"")})#
#renderview(view:"_form_bs/hidden",args:{name:"admin1",id:"location_admin1",value:event.getValue("admin1",args.geo.getAdmin1()?:"")})#
#renderview(view:"_form_bs/hidden",args:{name:"admin2",id:"location_admin2",value:event.getValue("admin2",args.geo.getAdmin2()?:"")})#
#renderview(view:"_form_bs/hidden",args:{name:"city",id:"location_city",value:event.getValue("city",args.geo.getCity()?:"")})#
<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key=#args.apiKey#&libraries=places" defer></script>
<cfif settingExists("appBuild")>
	<script type="text/javascript" src="#event.getModuleRoot('geonames')#/assets/js/autocompleteplaces.#getSetting('appBuild')#.js" defer></script>
<cfelse>
	<script type="text/javascript" src="#event.getModuleRoot('geonames')#/assets/js/autocompleteplaces.js" defer></script>
</cfif>
</cfoutput>
