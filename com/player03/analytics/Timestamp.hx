/**
 * Timestamp.hx - Provides the current time as an ISO 8601-conforming timestamp.
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

class Timestamp {
	public static inline function now():String {
		return fromLocal(Date.now());
	}
	
	public static function fromLocal(localDate:Date):String {
		//I must be using makeUtc() wrong, because it shifts the date in
		//the wrong direction. However, it shifts it by the right amount,
		//so I can can still get the correct time by moving the same amount
		//in the opposite direction.
		var inverseDate:Date = Date.fromTime(DateTools.makeUtc(
											localDate.getFullYear(),
											localDate.getMonth(),
											localDate.getDate(),
											localDate.getHours(),
											localDate.getMinutes(),
											localDate.getSeconds()));
		
		var offset:Float = inverseDate.getTime() - localDate.getTime();
		var utcDate:Date = Date.fromTime(localDate.getTime() - offset);
		
		return DateTools.format(utcDate, "%Y-%m-%dT%H:%M:%SZ");
	}
}
