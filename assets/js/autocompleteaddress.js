(function ($) {

	// Migrated from google.maps.places.Autocomplete (deprecated for new customers 2025-03-01)
	// to google.maps.places.PlaceAutocompleteElement.
	// Re-minify after editing:  npx terser autocompleteaddress.js -c -m -o autocompleteaddress.min.js

	var orig = document.getElementById('location_picker');

	if (!orig || !(window.google && google.maps && google.maps.importLibrary))
		return;

	var $orig = $(orig);
	var allowRegions = $orig.data("allowregions");
	var placeholder = orig.getAttribute("placeholder") || "";

	// Keep the Bootstrap input as a hidden mirror (still posts name="placeString")
	// and move #location_picker onto the new element -- see autocompleteplaces.js.
	orig.id = "location_picker_value";
	orig.type = "hidden";

	function apply(place) {
		$("#address_country").val('');
		$("#address_admin1").val('');
		$("#address_admin2").val('');
		$("#address_city").val('');
		$("#address_street").val('');

		var streetNumber = "", route = "";
		(place.addressComponents || []).forEach(function (c) {
			if (c.types.indexOf("country") !== -1) $("#address_country").val(c.longText);
			else if (c.types.indexOf("administrative_area_level_1") !== -1) $("#address_admin1").val(c.longText);
			else if (c.types.indexOf("administrative_area_level_2") !== -1) $("#address_admin2").val(c.longText);
			else if (c.types.indexOf("locality") !== -1) $("#address_city").val(c.longText);
			else if (c.types.indexOf("route") !== -1) route = c.longText;
			else if (c.types.indexOf("street_number") !== -1) streetNumber = c.longText;
		});

		var street = ((streetNumber ? streetNumber + " " : "") + route).trim();
		if (street) $("#address_street").val(street);

		if (place.location) {
			$("#address_lat").val(place.location.lat());
			$("#address_lng").val(place.location.lng());
		}

		$orig.val(place.formattedAddress || "");
	}

	google.maps.importLibrary("places").then(function (places) {
		var pac = new places.PlaceAutocompleteElement({
			// Legacy: {types:["geocode"]} for regions, {types:["address"]} otherwise.
			includedPrimaryTypes: allowRegions ? ["geocode"] : ["address"]
		});
		pac.id = "location_picker";
		pac.className = "place-autocomplete-input";
		pac.style.width = "100%";
		if (placeholder) pac.placeholder = placeholder;

		orig.parentNode.insertBefore(pac, orig.nextSibling);

		if (orig.value) {
			try { pac.value = orig.value; } catch (e) {}
		}

		pac.addEventListener("gmp-select", function (event) {
			var place = event.placePrediction.toPlace();
			place.fetchFields({ fields: ["addressComponents", "formattedAddress", "location"] }).then(function () {
				apply(place);
			});
		});

		pac.addEventListener("keydown", function (e) {
			if (e.keyCode === 13) e.preventDefault();
		});
	});

})(window.jQuery);
