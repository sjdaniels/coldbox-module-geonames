component output="false" {

	property name="GeoNamesService" inject="GeoNamesService@GeoNames";
	property name="AlertBox" inject="AlertBox@convertedplugins";
	property name="MongoDB" inject="id";

	function import(event,rc,prc){
		AlertBox.warn("Rebuilding GeoNames collection...");
		GeoNamesService.rebuildCollection(MongoDB, prc.supportedlangs, getSetting("geonamesUsage",false,[]), AlertBox);
	}

	function neighbors(event,rc,prc){
		AlertBox.warn("Updating GeoNames neighbors...");
		GeoNamesService.updateNeighbors(AlertBox);
	}

	function nears(event,rc,prc){
		AlertBox.warn("Updating GeoNames nears collection...");
		GeoNamesService.updateNears(AlertBox);
	}

}