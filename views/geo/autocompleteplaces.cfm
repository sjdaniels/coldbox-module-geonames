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
</cfscript>
<cfoutput>
<div id="autocompleteplaces_wrapper" data-multiple="#args.multiple#">
	#renderview(view:"_form_bs/input",args:{widthsplit:args.widthsplit,name:"#args.multiple?'placeTextEntry':'placeString'#",id:"location_picker", help:args.help, label:args.label, placeholder:args.placeholder,isrequired:args.isrequired,default:args.multiple?"":event.getValue("placeString",args.geo.getPlaceString()?:"")})#
	<cfif args.multiple>
		<div class="row">
			<div class="col-sm-#listlast(args.widthsplit,'/')# col-sm-offset-#listfirst(args.widthsplit,'/')#" id="multiplacevalues_wrapper">
				<cfloop array="#args.geos#" item="geo" index="ii">
					<div class="multiplacevalues row-space-1">
						<a href="##" class="removeable pull-right"><i class="fas fa-times-square"></i></a>
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
	<cfelse>
		#renderview(view:"_form_bs/hidden",args:{name:"country",id:"location_country",value:event.getValue("country",args.geo.getCountry()?:"")})#
		#renderview(view:"_form_bs/hidden",args:{name:"admin1",id:"location_admin1",value:event.getValue("admin1",args.geo.getAdmin1()?:"")})#
		#renderview(view:"_form_bs/hidden",args:{name:"admin2",id:"location_admin2",value:event.getValue("admin2",args.geo.getAdmin2()?:"")})#
		#renderview(view:"_form_bs/hidden",args:{name:"city",id:"location_city",value:event.getValue("city",args.geo.getCity()?:"")})#
	</cfif>
</div>
<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key=#args.apiKey#&libraries=places" defer></script>
<cfif settingExists("appBuild")>
	<script type="text/javascript" src="#event.getModuleRoot('geonames')#/assets/js/autocompleteplaces.#getSetting('appBuild')#.js" defer></script>
<cfelse>
	<script type="text/javascript" src="#event.getModuleRoot('geonames')#/assets/js/autocompleteplaces.js" defer></script>
</cfif>
</cfoutput>
