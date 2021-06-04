<cfscript>
	param name="args.geo" default="#getInstance('Geo@GeoNames')#";
	countryoptions = runEvent(event:"geonames:Main.countryoptions",eventArguments:{renderOut:true})
</cfscript>
<cfoutput>
<cfsavecontent variable="prc.inlinejavascript" append=true>
	<script type="text/javascript" src="#event.getModuleRoot('geonames')#/assets/js/geoinput.js"></script>
</cfsavecontent>
	#renderview(view:"_form/hidden",args:{ name:"geoID", value:"" })#
	<!--- #renderview(view:"_form/input",args:{ name:"geoID", label:"GeoNames ID Debug", value:"", disabled:true })# --->
	
	<label class="required">#$('geo.label_location')#</label>
	<fieldset class="selectRelated">
		<select name="country" id="country" required>#countryoptions#</select>
		<img src="/assets/images/indicator_arrows_circle.gif" class="hidden" id="indicator_country">
		<select name="admin1" id="admin1" class="hidden"></select>
		<img src="/assets/images/indicator_arrows_circle.gif" class="hidden" id="indicator_admin1">
		<select name="admin2" id="admin2" class="hidden"></select>
		<kbd id="admins_optional" class="hidden">#$('global.optional')#</kbd>
	</fieldset>
	
	<label for="city">#$("geo.label_city")#</label>
	<input type="text" name="city" id="city" data-placeholder="#$('geo.selectcountryfirst')#" value="#event.getValue("city",args.geo.getCity()?:"")#" autocomplete="off">
	<kbd id="city_optional">#$('global.optional')#</kbd>
	<kbd id="city_nomatch" class="error hidden"><span class="icon-attention-circled"></span> #$('geo.nocitymatch')# <strong></strong></kbd>
</cfoutput>