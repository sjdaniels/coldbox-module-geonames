(function ($) {

	// Migrated from google.maps.places.Autocomplete (deprecated for new customers 2025-03-01)
	// to google.maps.places.PlaceAutocompleteElement.
	// Re-minify after editing:  npx terser autocompleteplaces.js -c -m -o autocompleteplaces.min.js

	var wrapper = $('#autocompleteplaces_wrapper');
	var valwrapper = $('#multiplacevalues_wrapper');
	var orig = document.getElementById('location_picker');

	if (!orig || !(window.google && google.maps && google.maps.importLibrary))
		return;

	var $orig = $(orig);
	var isMultiple = wrapper.data("multiple");

	// The new element renders its own <input>, so it can't decorate the Bootstrap
	// input in place. We keep the original input as a hidden mirror -- it still
	// posts its value (single mode -> name="placeString") and keeps the geo hidden
	// fields intact -- and move the #location_picker id onto the new element so the
	// app-side hooks that target #location_picker (navsearch show/hide, filters-bar
	// delegated event) keep working.
	var placeholder = orig.getAttribute("placeholder") || "";
	orig.id = "location_picker_value";
	orig.type = "hidden";

	function mapComponents(components) {
		var f = { country: "", countrycode: "", admin1: "", admin1code: "", admin2: "", city: "" };
		(components || []).forEach(function (c) {
			if (c.types.indexOf("country") !== -1) { f.country = c.longText; f.countrycode = c.shortText; }
			else if (c.types.indexOf("administrative_area_level_1") !== -1) { f.admin1 = c.longText; f.admin1code = c.shortText; }
			else if (c.types.indexOf("administrative_area_level_2") !== -1) { f.admin2 = c.longText; }
			else if (c.types.indexOf("locality") !== -1) { f.city = c.longText; }
		});
		return f;
	}

	function addPlaceRow(text, f) {
		var row = $('<div class="multiplacevalues list-group-item"><a href="#" class="removeable float-end"><i class="fas fa-times-square"></i></a><i class="fas fa-fw fa-map-marker-alt"></i> ' + text + '</div>');
		row
			.append($('<input type="hidden" name="placeString[]">').val(text))
			.append($('<input type="hidden" name="country[]">').val(f.country))
			.append($('<input type="hidden" name="admin1[]">').val(f.admin1))
			.append($('<input type="hidden" name="admin2[]">').val(f.admin2))
			.append($('<input type="hidden" name="city[]">').val(f.city));
		valwrapper.append(row);
	}

	google.maps.importLibrary("places").then(function (places) {
		var pac = new places.PlaceAutocompleteElement({
			// "(regions)" is the type collection that replaces the legacy {types:["(regions)"]}.
			includedPrimaryTypes: ["(regions)"]
		});
		pac.id = "location_picker";
		pac.className = "place-autocomplete-input";
		pac.style.width = "100%";
		if (placeholder) pac.placeholder = placeholder;

		orig.parentNode.insertBefore(pac, orig.nextSibling);

		// Prefill the visible element on edit forms from the mirror's saved value.
		if (!isMultiple && orig.value) {
			try { pac.value = orig.value; } catch (e) {}
		}

		pac.addEventListener("gmp-select", function (event) {
			var place = event.placePrediction.toPlace();
			place.fetchFields({ fields: ["addressComponents", "formattedAddress", "displayName"] }).then(function () {
				var text = place.formattedAddress || place.displayName || "";
				var f = mapComponents(place.addressComponents);

				if (isMultiple) {
					addPlaceRow(text, f);
					try { pac.value = ""; } catch (e) {}
				} else {
					$orig.val(text);
					$("#location_country").val(f.country);
					$("#location_countrycode").val(f.countrycode);
					$("#location_admin1").val(f.admin1);
					$("#location_admin1code").val(f.admin1code);
					$("#location_admin2").val(f.admin2);
					$("#location_city").val(f.city);
					$(pac).trigger("autocompleteplaces_placepicked");
				}
			});
		});

		// Keep the legacy behaviour of not letting Enter submit the surrounding form.
		pac.addEventListener("keydown", function (e) {
			if (e.keyCode === 13) e.preventDefault();
		});
	});

	function removePlace(e) {
		$(this).closest('.multiplacevalues').remove();
		e.preventDefault();
	}

	$(document).on("click.autocompleteplacesremove", "a.removeable", removePlace);

})(window.jQuery);
