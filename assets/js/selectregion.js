(function($) {

	function onCountryChange(e) {
		$select = $(this);
		$(".geo-subselect").hide();
		$(".geo-"+$select.val()).show();
	}

	function onAnyChange(e) {
		$select = $(this);
		$("#regionID").val( $select.val() );
	}

	// DATA API
	$(document)
		.on('change.geoselectcountry','.geo-selectregion #countries select',onCountryChange)
		.on('change.geoselect','.geo-selectregion select',onAnyChange);

})(window.jQuery);