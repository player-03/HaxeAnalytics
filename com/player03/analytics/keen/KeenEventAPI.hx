/**
 * KeenEventAPI.hx - Provides functions for submitting events to Keen IO.
 * 
 * Copyright 2014 Joseph Cloutier
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.player03.analytics.keen;

import com.player03.analytics.base.EventAPI;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.Vector;
import haxe.Json;

class KeenEventAPI extends EventAPI {
	public function new(projectName:String, projectID:String, writeKey:String) {
		super("http://api.keen.io/3.0/projects/" + projectID + "/events");
		
		requestHeaders.push(new URLRequestHeader("Authorization", writeKey));
	}
	
	private override function applyRequestData(request:URLRequest):Void {
		//Convert the events into an object that can be converted to JSON.
		//(It would be possible to store the events like this, but I
		//imagine this would make modifications less efficient.)
		var data:Dynamic = { };
		var collection:Vector<Dynamic>;
		for(collectionName in queues.keys()) {
			collection = new Vector<Dynamic>();
			
			for(event in queues.get(collectionName)) {
				collection.push(event.properties);
			}
			
			Reflect.setField(data, collectionName, collection);
		}
		
		request.contentType = "application/json";
		request.data = Json.stringify(data);
	}
}
