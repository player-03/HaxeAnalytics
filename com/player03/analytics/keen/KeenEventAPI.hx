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

import flash.Vector;
import haxe.Http;
import haxe.Json;

class KeenEventAPI {
	private static var url:String;
	private static var writeKey:String;
	
	private static var queues:Map<String, Vector<KeenEvent>>;
	private static var eventsPending:Int = 0;
	
	public static function init(projectName:String, projectID:String, writeKey:String) {
		url = "https://api.keen.io/3.0/projects/" + projectID + "/events";
		KeenEventAPI.writeKey = writeKey;
		
		queues = new Map<String, Vector<KeenEvent>>();
	}
	
	public static function queueEvent(event:KeenEvent):Void {
		var queue:Vector<KeenEvent> = queues.get(event.collectionName);
		if(queue == null) {
			queue = new Vector<KeenEvent>();
			queues.set(event.collectionName, queue);
		}
		
		queue.push(event);
		eventsPending++;
	}
	
	/**
	 * @return The queued events, in case they need to be retried, or null
	 * if there are no queued events.
	 */
	public static function submitQueuedEvents(commonProperties:Map<String, Dynamic>,
											?onData:String -> Void,
											?onError:String -> Void,
											?onStatus:Int -> Void):Vector<KeenEvent> {
		if(eventsPending <= 0) {
			return null;
		}
		
		//Apply the common properties to all events.
		for(queue in queues) {
			for(event in queue) {
				event.applyCommonProperties(commonProperties);
			}
		}
		
		//Convert the events into an object that can be converted to JSON.
		//(It would be possible to store the events like this, but I
		//imagine this would make modifications less efficient.)
		var requestBody:Dynamic = { };
		var collection:Vector<Dynamic>;
		for(collectionName in queues.keys()) {
			collection = new Vector<Dynamic>();
			
			for(event in queues.get(collectionName)) {
				collection.push(event.toJsonSourceData());
			}
			
			Reflect.setField(requestBody, collectionName, collection);
		}
		
		var request:Http = new Http(url);
		
		request.setHeader("Content-Type", "application/json");
		request.setHeader("Authorization", writeKey);
		
		request.setPostData(Json.stringify(requestBody));
		
		if(onData != null) {
			request.onData = onData;
		}
		if(onError != null) {
			request.onError = onError;
		}
		if(onStatus != null) {
			request.onStatus = onStatus;
		}
		
		request.request(true);
		
		//Store the return values before clearing the queue.
		var flattenedQueue:Vector<KeenEvent> = null;
		for(queue in queues) {
			//Reuse the first vector in the map as the vector to return.
			if(flattenedQueue == null) {
				flattenedQueue = queue;
			} else {
				for(event in queue) {
					flattenedQueue.push(event);
				}
			}
		}
		
		clearQueuedEvents();
		
		return flattenedQueue;
	}
	
	/**
	 * @return Whether at least count events are queued.
	 */
	public static function hasQueuedEvents(count:Int = 1):Bool {
		return eventsPending >= count;
	}
	
	public static function clearQueuedEvents():Void {
		queues = new Map<String, Vector<KeenEvent>>();
		eventsPending = 0;
	}
}
