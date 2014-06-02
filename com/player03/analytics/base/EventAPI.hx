/**
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

package com.player03.analytics.base;

import flash.errors.IllegalOperationError;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.Vector;

class EventAPI {
	private var url:String;
	
	private var queues:Map<String, Vector<AnalyticsEvent>>;
	private var eventsPending:Int = 0;
	
	private var requestHeaders:Array<URLRequestHeader>;
	
	public function new(url:String) {
		this.url = url;
		
		queues = new Map<String, Vector<AnalyticsEvent>>();
		
		requestHeaders = new Array<URLRequestHeader>();
	}
	
	public function queueEvent(event:AnalyticsEvent):Void {
		var queue:Vector<AnalyticsEvent> = queues.get(event.collectionName);
		if(queue == null) {
			queue = new Vector<AnalyticsEvent>();
			queues.set(event.collectionName, queue);
		}
		
		queue.push(event);
		eventsPending++;
	}
	
	public function queueEvents(events:Vector<AnalyticsEvent>):Void {
		for(event in events) {
			queueEvent(event);
		}
	}
	
	/**
	 * @return The queued events, in case they need to be retried, or null
	 * if there are no queued events.
	 */
	public function submitQueuedEvents(?commonProperties:Dynamic,
									?onComplete:Event -> Void,
									?onSecurityError:SecurityErrorEvent -> Void,
									?onIOError:IOErrorEvent -> Void,
									?onStatus:HTTPStatusEvent -> Void):Vector<AnalyticsEvent> {
		if(eventsPending <= 0) {
			return null;
		}
		
		//Remove any events that have already been submitted.
		for(queue in queues) {
			var keepCount:Int = 0;
			for(i in 0...queue.length) {
				if(i != keepCount) {
					queue[keepCount] = queue[i];
				}
				if(!queue[i].submittedSuccessfully) {
					keepCount++;
				}
			}
			queue.splice(keepCount, queue.length - keepCount);
		}
		
		//Apply the common properties to all remaining events.
		if(commonProperties != null) {
			for(queue in queues) {
				for(event in queue) {
					event.setProperties(commonProperties);
				}
			}
		}
		
		//Set up the request.
		var request:URLRequest = new URLRequest(url);
		request.method = URLRequestMethod.POST;
		request.requestHeaders = requestHeaders;
		applyRequestData(request);
		
		var loader:URLLoader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.TEXT;
		
		//Store the return values for later resubmission if necessary.
		var flattenedQueue:Vector<AnalyticsEvent> = null;
		for(queue in queues) {
			//Reuse the first vector in the map, because the map is about
			//to be disposed anyway.
			if(flattenedQueue == null) {
				flattenedQueue = queue;
			} else {
				for(event in queue) {
					flattenedQueue.push(event);
				}
			}
		}
		
		loader.addEventListener(Event.COMPLETE, successListener.bind(flattenedQueue, onComplete));
		loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus != null ? onStatus : defaultListener);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError != null ? onSecurityError : defaultListener);
		loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError != null ? onIOError : defaultListener);
		
		//Send the request.
		#if cpp
			//cpp.vm.Thread.create(function():Void {
				loader.load(request);
			//});
		#else
			loader.load(request);
		#end
		
		clearQueuedEvents();
		
		return flattenedQueue;
	}
	
	private function applyRequestData(request:URLRequest):Void {
		throw new IllegalOperationError("EventAPI.applyRequestData() must be overridden!");
	}
	
	/**
	 * @return Whether at least count events are queued.
	 */
	public function hasQueuedEvents(count:Int = 1):Bool {
		return eventsPending >= count;
	}
	
	public function clearQueuedEvents():Void {
		queues = new Map<String, Vector<AnalyticsEvent>>();
		eventsPending = 0;
	}
	
	private function defaultListener(e:Dynamic):Void {
	}
	
	private function successListener(events:Vector<AnalyticsEvent>, listener:Dynamic -> Void, e:Dynamic):Void {
		for(event in events) {
			event.submittedSuccessfully = true;
		}
		
		if(listener != null) {
			listener(e);
		}
	}
}
