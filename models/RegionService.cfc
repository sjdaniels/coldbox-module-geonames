component {

	property name="ResourceService" inject="resourceService@cbi18n";

	// from spec spreadsheet
	this.SELECT_COUNTRIES = [
		 6252001
		,6251999
		,1269750
		,2635167
		,2510769
		,1814991
		,2328926
		,290557
		,2077456
		,2658434
		,1880251
		,2921044
		,953987
		,2300660
		,1819730
		,2017370
		,1733045
		,3017382
		,3573591
		,1562822
		,298795
		,1605651
		,2750405
		,3996063
		,2542007
		,192950
		,294640
		,2264397
		,1694008
		,3469034
		,1227603
		,1168579
		,146669
		,3175395
		,2464461
		,6290252
		,690791
		,390903
		,2802361
		,1210997
		,1643084
		,3624060
		,719819
		,798549
		,3865483
		,3582678
		,357994
		,289688
		,614540
		,2233387
		,3625428
		,3686110
		,3572887
		,2562770
		,3439705
		,4566966
		,2782113
		,1282988
		,2411586
		,3703430
		,2623032
		,1831722
		,3355338
		,2186224
		,149590
		,2661886
		,226074
		,798544
		,3580718
		,290291
		,934292
		,102358
		,1861060
	];

	this.SHOW_ADMIN1 = [
		 2635167 // UK
		,6252001 // USA
		,6251999 // Canada
	]

	// provider injection
	function getNames() provider="Names@geonames" {};

	public array function getCountryOptions(required string lang, boolean select=false, boolean withpreferred=false) {
		var result = [];
		var lang = arguments.lang;
		var criteria = {"depth":3};
		var name;

		if (arguments.select)
			criteria = {"_id":{"$in":this.SELECT_COUNTRIES}};

		local.cursor = getNames().list(criteria:criteria, asQuery:false, iterator:true, withRowCount:false)
		while (local.cursor.hasNext()) {
			name = local.cursor.next();
			result.append({label:name.getName(lang), value:name.getID()});
		}

		result.sort(function(a,b){
			return compareNoCase(a.label, b.label);
		});

		if (arguments.select)
			result.append({label:ResourceService.getResource(resource:"geo.other_country", locale:arguments.lang, default:"Other Country..."),value:"other"});
		
		if (arguments.withpreferred) {
			result.prepend({label:"", value:""});
			loop array="#duplicate(result).reverse()#" item="local.opt" {
				if (this.SHOW_ADMIN1.find(local.opt.value))
					result.prepend( local.opt );
			}
			result.prepend({label:"", value:""});
		}

		result.prepend({label:ResourceService.getResource(resource:"geo.select_country", locale:arguments.lang, default:"Select Country..."),value:""});

		return result;
	}

	public array function getContinentOptions(required string lang) {
		var result = [];
		var lang = arguments.lang;
		var name;
		

		local.cursor = getNames().list(criteria:{"type":"continent", "_id":{"$ne":6255152}}, asQuery:false, iterator:true, withRowCount:false)
		while (local.cursor.hasNext()) {
			name = local.cursor.next();
			result.append({label:name.getName(lang), value:name.getID()});
		}

		result.sort(function(a,b){
			return compareNoCase(a.label, b.label);
		});

		result.prepend({label:ResourceService.getResource(resource:"geo.select_continent", locale:arguments.lang, default:"Select Region..."),value:""});
		return result;
	}

	public array function getUSAdminOptions(required string lang) {
		var result = [];
		var lang = arguments.lang;
		var name;
		
		local.cursor = getNames().list(criteria:{"path":6252001, "type":"admin1"}, asQuery:false, iterator:true, withRowCount:false)
		while (local.cursor.hasNext()) {
			name = local.cursor.next();
			result.append({label:name.getName(lang), value:name.getID()});
		}

		result.sort(function(a,b){
			return compareNoCase(a.label, b.label);
		});

		result.prepend({label:ResourceService.getResource(resource:"geo.select_state", locale:arguments.lang, default:"Select State..."),value:""});
		return result;
	}

	public array function getCAAdminOptions(required string lang) {
		var result = [];
		var lang = arguments.lang;
		var name;
		
		local.cursor = getNames().list(criteria:{"path":6251999, "type":"admin1"}, asQuery:false, iterator:true, withRowCount:false)
		while (local.cursor.hasNext()) {
			name = local.cursor.next();
			result.append({label:name.getName(lang), value:name.getID()});
		}

		result.sort(function(a,b){
			return compareNoCase(a.label, b.label);
		});

		result.prepend({label:ResourceService.getResource(resource:"geo.select_province", locale:arguments.lang, default:"Select Province..."),value:""});
		return result;
	}

	public array function getUKAdminOptions(required string lang) {
		var result = [];
		var lang = arguments.lang;
		var name;
		
		local.cursor = getNames().list(criteria:{"path":2635167, "type":"admin1"}, asQuery:false, iterator:true, withRowCount:false)
		while (local.cursor.hasNext()) {
			name = local.cursor.next();
			result.append({label:name.getName(lang), value:name.getID()});
		}

		result.sort(function(a,b){
			return compareNoCase(a.label, b.label);
		});

		result.prepend({label:ResourceService.getResource(resource:"geo.select_country", locale:arguments.lang, default:"Select Country..."),value:""});
		return result;
	}

	public array function getAdminOptions(required string lang, required numeric countryID) {
		var result = [];
		var lang = arguments.lang;
		var name;
		
		local.cursor = getNames().list(criteria:{"path":arguments.countryID, "type":"admin1"}, asQuery:false, iterator:true, withRowCount:false)
		while (local.cursor.hasNext()) {
			name = local.cursor.next();
			result.append({label:name.getName(lang), value:name.getID()});
		}

		result.sort(function(a,b){
			return compareNoCase(a.label, b.label);
		});

		result.prepend({label:ResourceService.getResource(resource:"geo.select_admin_#arguments.countryID#", locale:arguments.lang, default:"Select Region..."),value:""});
		return result;
	}

	public array function getAdHocRegions() {
		var result = [
			 {"_id":"us-territories", "type":"usregion", "geoID":[4796775,4566966,5880801,4043988], "label":"US Territories"}
			,{"_id":"southwest", "type":"usregion", "geoID":[4736286,5551752,5481136,5509151], "label":"Southwest States"}
			,{"_id":"southeast", "type":"usregion", "geoID":[4197000,4482348,4155751,6254928,4597040], "label":"Southeast States"}
			,{"_id":"plains", "type":"usregion", "geoID":[4544379,4273857,5769223,5073708,5690763], "label":"Plains States"}
			,{"_id":"pacific", "type":"usregion", "geoID":[5815135,5744337,5332921,5879092,5855797], "label":"Pacific States"}
			,{"_id":"new-england", "type":"usregion", "geoID":[6254926,4831725,4971068,5090174,5224323,5242283], "label":"New England States"}
			,{"_id":"mountain", "type":"usregion", "geoID":[5549030,5417618,5596512,5667009,5843591], "label":"Mountain States"}
			,{"_id":"midwest", "type":"usregion", "geoID":[5165418,5001836,4921868,5279468,5037779,4896861,4862182], "label":"Midwest States"}
			,{"_id":"midsouth", "type":"usregion", "geoID":[4662168,4099753,4398678,4829764,4331987,6254925,4436296], "label":"Midsouth States"}
			,{"_id":"middle-atlantic", "type":"usregion", "geoID":[5101760,4361885,4826850,4142224,5128638,6254927], "label":"Middle Atlantic States"}
			,{"_id":"central-america", "type":"other", "geoID":[3582678,3624060,3585968,3595528,3608932,3617476,3703430], "label":"Central America"}
			,{"_id":"baltic", "type":"other", "geoID":[597427,458258,453733], "label":"Baltic"}
			,{"_id":"east-asia", "type":"other", "geoID":[1814991,1861060,1873107,1835841,1668284,1819730,1821275], "label":"East Asia"}
			,{"_id":"scandinavia", "type":"other", "geoID":[2661886,3144096,660013,2629691,2623032], "label":"Scandinavia"}
			,{"_id":"southeast-asia", "type":"other", "geoID":[1820814,1831722,1643084,1655842,1733045,1327865,1694008,1880251,1605651,1562822,1966436], "label":"Southeast Asia"}
			,{"_id":"maritimes", "type":"other", "geoID":[6087430,6091530,6113358], "label":"Maritimes"}
			,{"_id":"research-triangle", "type":"other", "geoID":[4497286,4464374,4483525], "label":"Research Triangle"}
			,{"_id":"far-east", "type":"other", "geoID":[1814991,1819730,1821275,1861060,1873107,1835841,2029969,1668284,1820814,1831722,1966436,1733045,1655842,1643084,1327865,1880251,1694008,1605651,1562822], "label":"Far East"}
			,{"_id":"valley", "type":"other", "geoID":[5368381], "label":"Valley"}
			,{"_id":"middle-east", "type":"other", "geoID":[290291,146669,357994,130758,99237,294640,248816,285570,272103,146669,286963,6254930,289688,102358,163843,298795,290557,69543], "label":"Middle East"}
			,{"_id":"caribbean", "type":"other", "geoID":[3562981,3489940,3723988,3508796,4566966,4796775,3577718,3573511,3575174,3576468,3576396,3578097,3579143,3575830,3570311,3577815,3374084,3580239,3573591,7626836,7626844], "label":"Caribbean"}
			,{"_id":"east-coast", "type":"other", "geoID":[4971068,5090174,6254926,5224323,4831725,5128638,5101760,4142224,4361885,6254928,4482348,4597040,4197000,4155751], "label":"East Coast"}
			,{"_id":"gulf-coast", "type":"other", "geoID":[4736286,4331987,4436296,4829764,4155751], "label":"Gulf Coast"}
			,{"_id":"west-coast", "type":"other", "geoID":[5332921,5744337,5815135], "label":"West Coast"}
			,{"_id":"north-africa", "type":"other", "geoID":[2589581,357994,2215636,2542007,7909807,366755,2464461,2461445], "label":"North Africa"}
			,{"_id":"northern-california", "type":"other", "geoID":[5323414,5322745,5323622,5332191,5332628,5338872,5339268,5562484,5345659,5350964,5352462,5565500,5359604,5363385,5364466,5566544,5369578,5370468,5370594,5372163,5372259,5568120,5374091,5374376,5376101,5376509,5383537,5383832,5389519,5391692,5391997,5392126,5392427,5393021,5393068,5571096,5395582,5571369,5396987,5397100,5398597,5400390,5572575,5553701,5403789,5403973,5410882,5411026], "label":"Northern California"}
			,{"_id":"southern-california", "type":"other", "geoID":[5359067,5362932,5368381,5379524,5387890,5391726,5391832,5392329,5392967,5405889], "label":"Southern California"}
			,{"_id":"great-lakes", "type":"other", "geoID":[6093943,4896861,4921868,5001836,5037779,5128638,5165418,6254927,5279468], "label":"Great Lakes"}
			,{"_id":"tri-state", "type":"other", "geoID":[5128638,5101760,4831725], "label":"Tri-State"}
			,{"_id":"bay-area", "type":"other", "geoID":[5322745,5339268,5370468,5376101,5391997,5392427,5393021,5396987,5397100], "label":"Bay Area"}
			,{"_id":"silicon-valley", "type":"other", "geoID":[5393021], "label":"Silicon Valley"}
			,{"_id":"mid-atlantic", "type":"other", "geoID":[5101760,4361885,4826850,4142224,5128638,6254927,6254928,4138106], "label":"Mid-Atlantic"}
			,{"_id":"texas-panhandle", "type":"other", "geoID":[5516441,5517598,5518353,5518431,5518760,5519229,5519868,5520004,5520330,5522430,5522740,5522806,5522887,5523019,5523630,5525131,5526589,5527543,5527746,5528077,5528613,5528909,5529403,5530618,5531988,5533544], "label":"Texas Panhandle"}
			,{"_id":"florida-panhandle", "type":"other", "geoID":[4146810,4149608,4154550,4157652,4158961,4159990,4166818,4172096], "label":"Florida Panhandle"}
			,{"_id":"twin-cities", "type":"other", "geoID":[5021070,5029877,5042563,5023752,5016452,5051936,5046749,5053485,5020499,5047121,5031493,5034327,5037515,5047260,5266878,5270199], "label":"Twin Cities"}
			,{"_id":"dfw", "type":"other", "geoID":[4682500,4684904,4685912,4688864,4698632,4699487,4701348,4702735,4717644,4723410,4732807,4735638,4742676], "label":"DFW"}
			,{"_id":"upper-peninsula", "type":"other", "geoID":[4983956,4984903,4988755,4990662,4990845,4994090,4996573,4997220,4998067,5000297,5000447,5000950,5001670,5004521,5009187], "label":"Upper Peninsula"}
			,{"_id":"puget-sound", "type":"other", "geoID":[5798453,5798663,5799783,5799853,5802584,5806769,5810608,5810982,5813521], "label":"Puget Sound"}
			,{"_id":"upstate-ny", "type":"other", "geoID":[5116642,5127305,5129867,5106841,5129832,5136325,5128734,5110365,5141784,5133668,5136456,5112358,5130076,5122581,5135484,5129891,5141153,5139656,5143455,5112392,5112977,5111846,5111868,5140135,5125630,5143268,5124928,5120548,5143303,5113366,5130111,5118380,5118116,5117867,5141045,5112398,5127354,5113792,5119355,5106997,5114810,5129995,5145163,5116680,5137620,5136495,5124290,5145190,5137368,5119847], "label":"Upstate NY"}
			,{"_id":"inland-empire", "type":"other", "geoID":[5387890,5391726], "label":"Inland Empire"}
		];

		return result;
	}
}