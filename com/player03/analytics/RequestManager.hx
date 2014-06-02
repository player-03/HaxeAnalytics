/**
 * RequestManager.hx - Submits events at regular intervals, and retries
 * events that failed. Using this class is optional.
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

package com.player03.analytics;

import com.player03.analytics.base.AnalyticsEvent;
import com.player03.analytics.base.EventAPI;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.Lib;
import flash.Vector;
import haxe.Json;
import haxe.Timer;

class RequestManager {
	public var api:EventAPI;
	
	private var commonProperties:AnalyticsEvent;
	
	/**
	 * The number of seconds between request attempts. It's safe to change
	 * this every frame, based on whether or not the game is paused.
	 */
	public var requestDelay:Float;
	
	/**
	 * When the last request was started.
	 */
	private var lastRequestTime:Float = 0;
	
	private static inline var BASE_ERROR_DELAY:Float = 2;
	
	/**
	 * An exponentially-increasing delay between attempts. This will be
	 * reset when the attempts stop failing.
	 */
	private var errorDelay:Float = BASE_ERROR_DELAY;
	
	/**
	 * The time of the most recent request failure.
	 */
	private var lastErrorTime:Float = 0;
	
	/**
	 * Whether there's currently a request that has not succeeded or
	 * failed. I don't trust the listeners 100%, so this only blocks
	 * events for a set time.
	 */
	private var requestOngoing:Bool;
	
	public function new(api:EventAPI, requestDelay:Float) {
		this.api = api;
		this.requestDelay = requestDelay;
		
		commonProperties = new AnalyticsEvent("");
		commonProperties.removeProperty(AnalyticsEvent.EVENT_TIME);
		
		Lib.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	private function onSuccess(e:Event):Void {
		errorDelay = BASE_ERROR_DELAY;
		
		requestOngoing = false;
	}
	
	private function onError(requestData:RequestData, e:IOErrorEvent):Void {
		errorDelay *= 2;
		lastErrorTime = Timer.stamp();
		
		api.queueEvents(requestData.events);
		
		requestOngoing = false;
	}
	
	private function onEnterFrame(e:Event):Void {
		var now:Float = Timer.stamp();
		
		if(api.hasQueuedEvents()
				&& now > lastRequestTime + requestDelay
				&& now > lastErrorTime + errorDelay
				&& (!requestOngoing || now > lastRequestTime + 60)) {
			requestOngoing = true;
			lastRequestTime = now;
			
			submitEvents();
		}
	}
	
	public inline function setCommonProperty(name:String, value:Dynamic):Void {
		commonProperties.setProperty(name, value);
	}
	public inline function commonPropertiesToJSON():String {
		return Json.stringify(commonProperties.properties);
	}
	
	/**
	 * Starts a request immediately.
	 */
	public function submitEvents():Void {
		//I'd prefer just to pass a pointer to onError(), then update the
		//data the pointer points to, but Haxe doesn't support that. This
		//is the closest equivalent I could come up with.
		var requestData:RequestData = new RequestData();
		requestData.events = api.submitQueuedEvents(
											commonProperties.properties,
											onSuccess,
											null,
											onError.bind(requestData));
	}
	
	public function dispose():Void {
		Lib.current.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
}

class RequestData {
	public var events:Vector<AnalyticsEvent>;
	
	public function new() {
	}
}
