/**
 * KeenEvent.hx - A collection of data representing a single Keen IO event.
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

class KeenEvent {
	/**
	 * The collection that this event will be submitted to.
	 */
	public var collectionName:String;
	
	/**
	 * The properties of this event. All values should be JSON-appropriate
	 * data types, like strings, floats, ints, and bools.
	 */
	public var properties:Map<String, Dynamic>;
	
	public function new(collectionName:String) {
		this.collectionName = collectionName;
		properties = new Map<String, Dynamic>();
		
		properties.set("keen", {timestamp:Timestamp.now()});
	}
	
	public function addProperty(name:String, value:Dynamic):Void {
		properties.set(name, value);
	}
	
	public function applyCommonProperties(commonProperties:Map<String, Dynamic>):Void {
		for(name in commonProperties.keys()) {
			if(!properties.exists(name)) {
				properties.set(name, commonProperties.get(name));
			}
		}
	}
	
	public function toJsonSourceData():Dynamic {
		var result:Dynamic = { };
		for(name in properties.keys()) {
			Reflect.setField(result, name, properties.get(name));
		}
		return result;
	}
}
