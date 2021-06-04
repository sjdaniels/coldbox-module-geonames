<cfscript>
	param name="args.geo" default="#getInstance('Geo@GeoNames')#";
	param name="args.widthsplit" default="3/5";
</cfscript>
<cfoutput>
	<label class="required" for="location">#$('geo.label_location')#</label>
	<fieldset class="inputgroup">
		<input type="text" name="country" id="location_country" placeholder="#$('geo.label_country')#" value="#event.getValue("country",args.geo.getCountry()?:"")#" required>
		<input type="text" name="admin1" id="admin1" placeholder="#$('geo.label_admin1')#" value="#event.getValue("admin1",args.geo.getAdmin1()?:"")#">
		<input type="text" name="admin2" id="admin2" placeholder="#$('geo.label_admin2')#" value="#event.getValue("admin2",args.geo.getAdmin2()?:"")#">
		<input type="text" name="city" id="city" placeholder="#$('geo.label_city')#" value="#event.getValue("city",args.geo.getCity()?:"")#">
	</fieldset>
</cfoutput>