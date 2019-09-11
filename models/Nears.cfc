component entityname="Nears" collection="geo_nears" extends="mongoentity.models.ActiveEntity" {

	// stores array of geo IDs that are "near" the primary ID.
	// for ADM2, this is  neighbors
	// for cities, it's other cities within 25 mi radius, population > 5000

	property name="id" type="numeric";
	property name="nears" type="array";

}