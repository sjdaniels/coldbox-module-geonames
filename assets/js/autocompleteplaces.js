(function($) {

	var wrapper = $('#autocompleteplaces_wrapper');
	var valwrapper = $('#multiplacevalues_wrapper');
	var input = $('#location_picker');
	var autocomplete = new google.maps.places.Autocomplete(input.get(0), {types: ["(regions)"] });
	var isMultiple = wrapper.data("multiple");

	function onPlaceChange() {
		$("#location_country").val('');
		$("#location_admin1").val('');
		$("#location_admin2").val('');
		$("#location_city").val('');
		var place = autocomplete.getPlace();
		input.data( "clearedvalue", input.val() );
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
	}

	function onPlaceAdd() {
		var placeString = $('<input type="hidden" name="placeString[]">');
		var country = $('<input type="hidden" name="country[]">');
		var admin1 = $('<input type="hidden" name="admin1[]">');
		var admin2 = $('<input type="hidden" name="admin2[]">');
		var city = $('<input type="hidden" name="city[]">');
		var place = autocomplete.getPlace();
		placeString.val( input.val() );
		if (place.address_components != undefined) {
			place.address_components.forEach(function(component){
				if (component.types.includes("country")) {
					country.val(component.long_name);
				}
				else if (component.types.includes("administrative_area_level_1")) {
					admin1.val(component.long_name);
				}
				else if (component.types.includes("administrative_area_level_2")) {
					admin2.val(component.long_name);
				}
				else if (component.types.includes("locality")) {
					city.val(component.long_name);
				}
			});
		}

		var addHTML = $('<div class="multiplacevalues list-group-item"><a href="#" class="removeable float-end"><i class="fas fa-times-square"></i></a><i class="fas fa-fw fa-map-marker-alt"></i> ' + placeString.val() + '</div>');
		addHTML.append(placeString).append(country).append(admin1).append(admin2).append(city);
		valwrapper.append(addHTML);
		input.val('');
	}

	function removePlace(e) {
		var $thisvaluewrapper = $(this).parent('.multiplacevalues');
		$thisvaluewrapper.remove();
		e.preventDefault();
	}

	function validate(e) {
		if (isMultiple)
			return;

		if (!$("#location_country").val().length) {
			input.val('');
		}
		else if (input.data('clearedvalue').length) {
			input.val( input.data('clearedvalue') );
		}
	}

	function clearentry(e) {
		if (isMultiple)
			return;

		input
			.data("clearedvalue",input.val())
			.val('');
	}

	// Avoid paying for data that you don't need by restricting the set of
	// place fields that are returned to just the address components.
	autocomplete.setFields(['address_component','place_id','geometry']);

	// When the user selects an address from the drop-down, populate the
	// address fields in the form.
	autocomplete.addListener('place_changed', isMultiple ? onPlaceAdd : onPlaceChange);

	$(document).on("keydown.autocompleteplaces","#location_picker",function(e){
		if(e.keyCode == 13) {
			e.preventDefault();
			return false;
		}
	});

	$(document).on("click.autocompleteplacesremove","a.removeable",removePlace);
	$(document).on("blur.autocompleteplaces","#location_picker",validate);
	$(document).on("focus.autocompleteplaces","#location_picker",clearentry);

})(window.jQuery);