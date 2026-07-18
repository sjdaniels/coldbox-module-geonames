(function ($) {

	// Migrated from google.maps.places.Autocomplete (deprecated for new customers 2025-03-01)
	// to google.maps.places.PlaceAutocompleteElement.
	// Re-minify after editing:  npx terser autocompleteplaces.js -c -m -o autocompleteplaces.min.js

	var wrapper = $('#autocompleteplaces_wrapper');
	var valwrapper = $('#multiplacevalues_wrapper');
	var orig = document.getElementById('location_picker');

	if (!orig)
		return;

	var $orig = $(orig);
	var isMultiple = wrapper.data("multiple");
	var placeholder = orig.getAttribute("placeholder") || "";

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
		$orig.trigger("change");
	}

	function init(places) {
		var pac = new places.PlaceAutocompleteElement({
			// "(regions)" is the type collection that replaces the legacy {types:["(regions)"]}.
			includedPrimaryTypes: ["(regions)"]
		});
		pac.id = "location_picker";
		pac.className = "place-autocomplete-input";
		if (placeholder) pac.placeholder = placeholder;

		// The new element renders its own <input>, so it can't decorate the Bootstrap
		// input in place. Keep the original input as a hidden mirror -- it still posts
		// its value (single mode -> name="placeString") and keeps the geo hidden fields
		// intact -- and move the #location_picker id onto the new element so app-side
		// hooks that target #location_picker (navsearch show/hide, filters-bar delegated
		// event) keep working. Prefill the element from the mirror on edit forms.
		var saved = orig.value;
		orig.id = "location_picker_value";
		orig.type = "hidden";
		orig.parentNode.insertBefore(pac, orig.nextSibling);
		if (!isMultiple && saved) {
			try { pac.value = saved; } catch (e) {}
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
					// jQuery .val() doesn't fire events; emit change on the posting field so
					// host-form change/dirty detection sees it.
					$orig.trigger("change");
					$(pac).trigger("autocompleteplaces_placepicked");
				}
			});
		});

		// When the field is emptied, drop the stored selection so a stale place isn't
		// posted or re-prefilled on a form error.
		if (!isMultiple) {
			var clearGeoIfEmpty = function () {
				if (pac.value) return;
				$orig.val("");
				$("#location_country").val("");
				$("#location_countrycode").val("");
				$("#location_admin1").val("");
				$("#location_admin1code").val("");
				$("#location_admin2").val("");
				$("#location_city").val("");
				$orig.trigger("change");
			};
			// Manual delete fires input; the built-in clear (X) button does not, so
			// also re-check after any click inside the element.
			pac.addEventListener("input", clearGeoIfEmpty);
			pac.addEventListener("click", function () { setTimeout(clearGeoIfEmpty, 0); });
		}

		pac.addEventListener("keydown", function (e) {
			// Let the element own suggestion navigation AND Enter-to-select; just keep
			// the Bootstrap dropdown's keydown handler from hijacking those keys when
			// the picker is inside a menu. (Do NOT preventDefault Enter -- that blocks
			// the element's own keyboard selection.)
			if (e.key === "ArrowDown" || e.key === "ArrowUp" || e.key === "Enter") e.stopPropagation();
		});
	}

	// The Maps loader uses loading=async, so google.maps.importLibrary may not be
	// defined at the instant this deferred script runs. Wait for it rather than
	// silently bailing out.
	whenMapsReady(function () {
		google.maps.importLibrary("places").then(init);
	});

	function whenMapsReady(cb) {
		if (window.google && google.maps && google.maps.importLibrary) return cb();
		var waited = 0;
		var iv = setInterval(function () {
			if (window.google && google.maps && google.maps.importLibrary) {
				clearInterval(iv);
				cb();
			} else if ((waited += 50) >= 10000) {
				clearInterval(iv);
			}
		}, 50);
	}

	function removePlace(e) {
		$(this).closest('.multiplacevalues').remove();
		e.preventDefault();
		$orig.trigger("change");
	}

	$(document).on("click.autocompleteplacesremove", "a.removeable", removePlace);

})(window.jQuery);
