HaxeAnalytics
=============

A simple API for Keen.io, written in Haxe.

Sample usage
------------

	//You can get these values from Keen, once you set up a project:
    KeenEventAPI.init("projectName", "projectID", "writeKey");
	
	//Later, when you have something to record:
	var event:KeenEvent = new KeenEvent("event_type");
    event.addProperty("propertyName", "propertyValue");
    KeenEventAPI.queueEvent(event);
	
	//Every so often, call this:
	KeenEventAPI.submitQueuedEvents();