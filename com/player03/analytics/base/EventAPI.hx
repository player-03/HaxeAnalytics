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
	public function submitQueuedEvents(?commonProperties:Map<String, Dynamic>,
									?onComplete:Event -> Void,
									?onSecurityError:SecurityErrorEvent -> Void,
									?onIOError:IOErrorEvent -> Void,
									?onStatus:HTTPStatusEvent -> Void):Vector<AnalyticsEvent> {
		if(eventsPending <= 0) {
			return null;
		}
		
		//Apply the common properties to all events.
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
		
		loader.addEventListener(Event.COMPLETE, onComplete != null ? onComplete : defaultListener);
		loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus != null ? onStatus : defaultListener);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError != null ? onSecurityError : defaultListener);
		loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError != null ? onIOError : defaultListener);
		
		//Send the request.
		#if cpp
			cpp.vm.Thread.create(function():Void {
				loader.load(request);
			});
		#else
			loader.load(request);
		#end
		
		//Store the return values before clearing the queue.
		var flattenedQueue:Vector<AnalyticsEvent> = null;
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
	
	private function defaultListener(e:Event):Void {
	}
}
