var GeoInput = {

	init:function(){

		$(document).on('change.country','select#country',GeoInput.onCountryChange);
		$(document).on('change.admin1','select#admin1',GeoInput.onAdmin1Change);
		$(document).on('change.admin2','select#admin2',GeoInput.onAdmin2Change);
		$(document).on('blur.city','input#city',GeoInput.onCityBlur);

		GeoInput.enableCity( $('select#country').find('option:selected').data('geoid') );
 
		//$(document).on('keyup.autocompleter','input#city',GeoInput.setIndicator)
	}

	,onCountryChange:function(e){
		var $selected 	= $(this).find('option:selected');
		var params 		= {
			 geoID:$selected.data('geoid')	
			,countryCode:$selected.data('countrycode')
		}
		var showAdmin1 	= true; //$selected.data('showAdmin1');
		var showAdmin2 	= true; //$selected.data('showAdmin2');

		// enable city
		GeoInput.enableCity(params.geoID);

		// enable admin 1 menu, when indicated
		if (showAdmin1 && params.geoID != '') {
			$('#indicator_country').show();
			$('kbd#admins_optional').addClass('hidden');
			$('select#admin1').html('').addClass('hidden').load('/admin1options',params,function(data){
				$('#indicator_country').hide();
				if (data.trim()!=''){
					$(this).removeClass('hidden').focus();
					$('kbd#admins_optional').removeClass('hidden');
				}
			});
		}
		else {
			$('select#admin1').html('').addClass('hidden');
			$('kbd#admins_optional').addClass('hidden');
		}
	
		// always reset/hide admin 2 on country change
		$('select#admin2').html('').addClass('hidden');
		$('input#city').val('')
		GeoInput.setGeoID();
	}
	
	,onAdmin1Change:function(e){
		var $selected 	= $(this).find('option:selected');
		var $country 	= $('select#country').find('option:selected');
		var params 		= {
			 geoID:$selected.data('geoid')	
			,countryCode:$selected.data('countrycode')
			,admin1Code:$selected.data('admin1code')
		}
		var showAdmin2 	= true; //$country.data('showAdmin2');
		if (showAdmin2) {
			if ($selected.val()!='') {
				$('#indicator_admin1').show();
				$('kbd#admins_optional').addClass('hidden');
				$('select#admin2').addClass('hidden').html('').load('/admin2options',params,function(data){
					$('#indicator_admin1').hide();
					$.log(data.trim());
					if (data.trim()!=''){
						$(this).removeClass('hidden').focus();
						$('kbd#admins_optional').removeClass('hidden');
					}
				});
			} else {
				$('select#admin2').html('').addClass('hidden');
			}
		}
		$('input#city').val('')
		GeoInput.setGeoID();
	}

	,onAdmin2Change:function(e){
		var $selected 	= $(this).find('option:selected');
		var $country 	= $('select#country').find('option:selected');
		var params 		= {
			 geoID:$selected.data('geoid')	
			,countryCode:$country.data('code')
		}
		$('input#city').val('');
		GeoInput.setGeoID();
	}

	,onCityChange:function(event,ui){		
		if (ui.item===null) {
			var attemptedCity = $('#'+event.target.id).val();
			$('#'+event.target.id).val('');
			$('#'+event.target.id).data('geoid',null);
			GeoInput.setGeoID()
			if (attemptedCity.trim()!='') {
				$('kbd#city_optional').hide();
				$('kbd#city_nomatch').show().find('strong').html(attemptedCity);
			} else {
				$('kbd#city_optional').show();
				$('kbd#city_nomatch').hide();
			}
			return;
		}
	}		

	,onCityBlur:function(e){		
		if ($(this).val()=='') {
			$(this).data('geoid',null);
			GeoInput.setGeoID()
			return;
		}
	}		

	,getCities:function(request,response){
		var params = {
			 countryCode : $('select#country').find('option:selected').data('countrycode')
			,admin1Code : $('select#admin1').find('option:selected').data('admin1code')
			,admin2Code : $('select#admin2').find('option:selected').data('admin2code')
			,q : request.term
		}

		$.ajax({ 
			url:"/autocompletecities", 
			dataType:"json", 
			data:params,
			success: function( data ) {
				response( $.map( data.cities, function( item ) {
					return { label:item.label, value:item.name, id:item.id, geoID:item.id }
				}));
			}
		});
	}

	,onMenuOpen:function(event,ui){
		$('#'+event.target.id).removeClass('loading');
		return true;
	}	

	,enableCity:function(geoID){
		if (geoID==''){
			$('input#city').prop('disabled',true).attr('placeholder', $('input#city').data('placeholder') ).val('');
		}
		else {
			$('input#city')
				.prop('disabled',false)
				.removeAttr('placeholder')
				.autocomplete({ 
					 autoFocus:true
					,minLength:1
					,delay:250
					,source:GeoInput.getCities
					,search:GeoInput.setIndicator
					,response:GeoInput.onMenuOpen
					,select:GeoInput.onSelect
					,change:GeoInput.onCityChange
				});
		}
	}

	,onSelect:function(event,ui){
		$(this).data('geoid', ui.item.geoID);
		GeoInput.setGeoID();
		return true;
	}

	,setIndicator:function(e){
		if (e.keyCode==13||e.keyCode==38||e.keyCode==40||e.keyCode==9||e.keyCode==27||e.keyCode==16||e.keyCode==39||e.keyCode==37)
			return;
 
		if ($(this).val() != '')
			$(this).addClass('loading')
		else 
			$(this).removeClass('loading')

		$('kbd#city_optional').show();
		$('kbd#city_nomatch').hide();
	}

	,setGeoID:function(){
		var bestID = $('input#city').data('geoid') || $('select#admin2').find('option:selected').data('geoid') || $('select#admin1').find('option:selected').data('geoid') || $('select#country').find('option:selected').data('geoid') || "";
		// set to best of
		$('input#geoID').val(bestID);
	}

}

$(function(){
	GeoInput.init();
})