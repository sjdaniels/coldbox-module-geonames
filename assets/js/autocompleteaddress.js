(function($){
    (async function(){
        await google.maps.importLibrary("places");
        var input = $('#location_picker');
        var types = $('#location_picker').data("allowregions") ? ["geocode"] : ["address"];
        var autocomplete = new google.maps.places.PlaceAutocompleteElement({inputElement: input.get(0), types: types});

        function onPlaceChange(e){
            $("#address_country").val('');
            $("#address_admin1").val('');
            $("#address_admin2").val('');
            $("#address_city").val('');
            $("#address_street").val('');
            var place = (e && e.place) || autocomplete.getPlace();
            if(place && place.address_components != undefined){
                place.address_components.reverse().forEach(function(component){
                    if(component.types.includes("country")){
                        $("#address_country").val(component.long_name);
                        $.log("Country: " + component.long_name);
                    }
                    else if(component.types.includes("administrative_area_level_1")){
                        $("#address_admin1").val(component.long_name);
                        $.log("State/Province: " + component.long_name);
                    }
                    else if(component.types.includes("administrative_area_level_2")){
                        $("#address_admin2").val(component.long_name);
                        $.log("County: " + component.long_name);
                    }
                    else if(component.types.includes("locality")){
                        $("#address_city").val(component.long_name);
                        $.log("City: " + component.long_name);
                    }
                    else if(component.types.includes("route")){
                        $("#address_street").val(component.long_name);
                        $.log("Street: " + component.long_name);
                    }
                    else if(component.types.includes("street_number")){
                        $("#address_street").val(component.long_name + ' ' + $("#address_street").val());
                        $.log("Street Number: " + component.long_name);
                    }
                });
                $("#address_lat").val(place.geometry.location.lat());
                $("#address_lng").val(place.geometry.location.lng());
            }
        }

        function validate(e){
            if(!$("#address_country").val().length){
                input.val('');
            }
        }

        autocomplete.addListener('gmp-placeselect', onPlaceChange);

        $(document).on("keydown.autocompleteaddress", "#location_picker", function(e){
            if(e.keyCode == 13){
                e.preventDefault();
                return false;
            }
        });

        $(document).on("blur.autocompleteplaces", "#location_picker", validate);
    })();
})(window.jQuery);
