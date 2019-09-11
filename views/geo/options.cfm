<cfoutput>
	<option value="" data-geoid="" data-code="">#prc.optionslabel#</option>
	<cfloop array="#prc.options#" item="option">
		<option value="#option.label#" data-geoid="#option.id#" data-countrycode="#option.countryCode#"<cfif !isnull(option.admin1Code)> data-admin1code="#option.admin1Code#"</cfif><cfif !isnull(option.admin2Code)> data-admin2code="#option.admin2Code#"</cfif>>#option.label#</option></cfloop>
</cfoutput>