<cfscript>
	param name="args.geo" default="#getModel('Geo@GeoNames')#";
	param name="args.widthsplit" default="3/5";
</cfscript>
<cfoutput>
	#renderview(view:"_form_bs/input",args:{widthsplit:args.widthsplit, help:$("geo.hint_country"),name:"country",id:"location_country",label:$('geo.label_country'),default:event.getValue("country",args.geo.getCountry()?:"")})#
	#renderview(view:"_form_bs/input",args:{widthsplit:args.widthsplit, help:$("geo.hint_admin1"),name:"admin1",id:"location_admin1",label:$('geo.label_admin1'),default:event.getValue("admin1",args.geo.getAdmin1()?:"")})#
	#renderview(view:"_form_bs/input",args:{widthsplit:args.widthsplit, help:$("geo.hint_admin2"),name:"admin2",id:"location_admin2",label:$('geo.label_admin2'),default:event.getValue("admin2",args.geo.getadmin2()?:"")})#
	#renderview(view:"_form_bs/input",args:{widthsplit:args.widthsplit, help:$("geo.hint_city"),name:"city",id:"location_city",label:$('geo.label_city'),default:event.getValue("city",args.geo.getcity()?:"")})#
</cfoutput>