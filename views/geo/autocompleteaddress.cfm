<cfscript>
	param name="args.geo" default="#getInstance('Geo@GeoNames').new()#";
	param name="args.label" default="#$('geo.label_address')#";
	param name="args.placeholder" default="#$('geo.placeholder_address')#";
	param name="args.help" default="";
	param name="args.widthsplit" default="3/5";
	param name="args.isrequired" default="false";
	param name="args.apiKey" default="#getSetting('googleapis').apiKey#";
</cfscript>
<cfoutput>
<div id="autocompleteaddress_wrapper">
	#renderview(view:"_form_bs/input",args:{widthsplit:args.widthsplit,name:"placeString",id:"address_picker", help:args.help, label:args.label, placeholder:args.placeholder,isrequired:args.isrequired,default:event.getValue("placeString",args.geo.getPlaceString()?:"")})#
	#renderview(view:"_form_bs/hidden",args:{name:"country",id:"address_country",value:event.getValue("country",args.geo.getCountry()?:"")})#
	#renderview(view:"_form_bs/hidden",args:{name:"admin1",id:"address_admin1",value:event.getValue("admin1",args.geo.getAdmin1()?:"")})#
	#renderview(view:"_form_bs/hidden",args:{name:"admin2",id:"address_admin2",value:event.getValue("admin2",args.geo.getAdmin2()?:"")})#
	#renderview(view:"_form_bs/hidden",args:{name:"city",id:"address_city",value:event.getValue("city",args.geo.getCity()?:"")})#
	#renderview(view:"_form_bs/hidden",args:{name:"street",id:"address_street",value:event.getValue("street",args.geo.getStreet()?:"")})#
	#renderview(view:"_form_bs/hidden",args:{name:"lat",id:"address_lat",value:event.getValue("lat","")})#
	#renderview(view:"_form_bs/hidden",args:{name:"lng",id:"address_lng",value:event.getValue("lng","")})#
</div>
<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key=#args.apiKey#&libraries=places" defer></script>
<cfif settingExists("appBuild")>
	<script type="text/javascript" src="#event.getModuleRoot('geonames')#/assets/js/autocompleteaddress.#getSetting('appBuild')#.js" defer></script>
<cfelse>
	<script type="text/javascript" src="#event.getModuleRoot('geonames')#/assets/js/autocompleteaddress.js" defer></script>
</cfif>
</cfoutput>
