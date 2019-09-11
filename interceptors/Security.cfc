component extends="coldbox.system.Interceptor" {

	function configure(){
		return this;
	}

	function preProcess() eventpattern="^geonames:" {
		// logbox.getLogger(this).info("START: #event.getCurrentEvent()#@#getSetting('frontEndURL')#")
        if (event.getValue("secretkey","") != getSetting("geonamesKey")) 
            event.overrideevent("geonames:main.noauth");
	}

	function preLayout() eventpattern="^geonames:" {
        event.renderData(type:event.getValue(name:"contenttype",defaultValue:"JSON",private:true),data:event.getValue(name:"response",private:true))
	}

}