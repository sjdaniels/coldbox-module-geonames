(function($) {

	var input = $('#location_picker');
	var autocomplete = new google.maps.places.Autocomplete(input.get(0), {types: ["(regions)"] });

	// Avoid paying for data that you don't need by restricting the set of
	// place fields that are returned to just the address components.
	autocomplete.setFields(['address_component','place_id','geometry']);

	// When the user selects an address from the drop-down, populate the
	// address fields in the form.
	autocomplete.addListener('place_changed', function(){
		$("#location_country").val('');
		$("#location_admin1").val('');
		$("#location_admin2").val('');
		$("#location_city").val('');
		var place = autocomplete.getPlace();
		if (place.address_components != undefined) {
			place.address_components.forEach(function(component){
				if (component.types.includes("country")) {
					$("#location_country").val(component.long_name);
					$.log("Country: " + component.long_name);
				}
				else if (component.types.includes("administrative_area_level_1")) {
					$("#location_admin1").val(component.long_name);
					$.log("State/Province: " + component.long_name);
				}
				else if (component.types.includes("administrative_area_level_2")) {
					$("#location_admin2").val(component.long_name);
					$.log("County: " + component.long_name);
				}
				else if (component.types.includes("locality")) {
					$("#location_city").val(component.long_name);
					$.log("City: " + component.long_name);
				}
			});
		}
	});

	$(document).on("keydown.autocompleteplaces","#location_picker",function(e){
		if(e.keyCode == 13) {
			e.preventDefault();
			return false;
		}
	});

})(window.jQuery);