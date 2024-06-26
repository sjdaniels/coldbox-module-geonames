(function ($) {

	var input = $('#location_picker');
	var types = $('#location_picker').data("allowregions") ? ["geocode"] : ["address"];
	var autocomplete = new google.maps.places.Autocomplete(input.get(0), { types: types });

	function onPlaceChange() {
		$("#address_country").val('');
		$("#address_admin1").val('');
		$("#address_admin2").val('');
		$("#address_city").val('');
		$("#address_street").val('');
		var place = autocomplete.getPlace();
		if (place.address_components != undefined) {
			place.address_components.reverse().forEach(function (component) {
				if (component.types.includes("country")) {
					$("#address_country").val(component.long_name);
					$.log("Country: " + component.long_name);
				}
				else if (component.types.includes("administrative_area_level_1")) {
					$("#address_admin1").val(component.long_name);
					$.log("State/Province: " + component.long_name);
				}
				else if (component.types.includes("administrative_area_level_2")) {
					$("#address_admin2").val(component.long_name);
					$.log("County: " + component.long_name);
				}
				else if (component.types.includes("locality")) {
					$("#address_city").val(component.long_name);
					$.log("City: " + component.long_name);
				}
				else if (component.types.includes("route")) {
					$("#address_street").val(component.long_name);
					$.log("Street: " + component.long_name);
				}
				else if (component.types.includes("street_number")) {
					$("#address_street").val(component.long_name + ' ' + $("#address_street").val());
					$.log("Street Number: " + component.long_name);
				}
			});

			$("#address_lat").val(place.geometry.location.lat());
			$("#address_lng").val(place.geometry.location.lng());
		}
	}

	function validate(e) {
		if (!$("#address_country").val().length) {
			input.val('');
		}
	}

	// Avoid paying for data that you don't need by restricting the set of
	// place fields that are returned to just the address components.
	autocomplete.setFields(['address_component', 'place_id', 'geometry']);

	// When the user selects an address from the drop-down, populate the
	// address fields in the form.
	autocomplete.addListener('place_changed', onPlaceChange);

	$(document).on("keydown.autocompleteaddress", "#location_picker", function (e) {
		if (e.keyCode == 13) {
			e.preventDefault();
			return false;
		}
	});

	$(document).on("blur.autocompleteplaces", "#location_picker", validate);

})(window.jQuery);