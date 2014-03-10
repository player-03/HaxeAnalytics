/**
 * AnalyticsEvent.hx - A collection of data representing a single event.
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

 package com.player03.analytics.base;
import com.player03.analytics.Timestamp;

class AnalyticsEvent {
	/**
	 * A standard property added to all events, indicating the time that
	 * the event was created.
	 */
	public static inline var EVENT_TIME:String = "event_time";
	
	/**
	 * The collection that this event will be submitted to.
	 */
	public var collectionName:String;
	
	/**
	 * The properties of this event, as an anonymous object. Values can be
	 * accessed and set via dot notation, or via the provided functions.
	 * All values should be JSON-appropriate data types, like strings,
	 * floats, ints, and bools.
	 */
	public var properties:Dynamic;
	
	public function new(collectionName:String) {
		this.collectionName = collectionName;
		
		properties = { };
		
		setProperty(EVENT_TIME, Timestamp.now());
	}
	
	public inline function getProperty(name:String):Dynamic {
		return Reflect.field(properties, name);
	}
	
	public inline function setProperty(name:String, value:Dynamic):Void {
		Reflect.setField(properties, name, value);
	}
	
	public function setProperties(newProperties:Map<String, Dynamic>, overwrite:Bool = false):Void {
		for(name in newProperties.keys()) {
			if(overwrite || !Reflect.hasField(properties, name)) {
				setProperty(name, newProperties.get(name));
			}
		}
	}
	
	public inline function removeProperty(name:String):Bool {
		return Reflect.deleteField(properties, name);
	}
}
