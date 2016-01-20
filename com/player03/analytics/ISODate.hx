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

class ISODate {
	//Captures year, month, day, hour, minute, second, and an optional time zone value.
	//Milliseconds are optional, and are not captured.
	private static var DATE_PARSER:EReg = ~/(\d\d\d\d)-?(\d\d)-?(\d\d)[T ](\d\d):(\d\d):(\d\d)(?:\.\d+)?(Z|[+\-]\d\d(?::?\d\d)?|)/;
	
	public static function fromString(string:String):Date {
		if(!DATE_PARSER.match(string)) {
			return null;
		}
		
		var year:Int = Std.parseInt(DATE_PARSER.matched(1));
		var month:Int = Std.parseInt(DATE_PARSER.matched(2));
		var day:Int = Std.parseInt(DATE_PARSER.matched(3));
		var hour:Int = Std.parseInt(DATE_PARSER.matched(4));
		var minute:Int = Std.parseInt(DATE_PARSER.matched(5));
		var second:Int = Std.parseInt(DATE_PARSER.matched(6));
		
		//Retrieve the local time zone.
		var timeZoneOffset:Float = new Date(1970, 0, 1, 0, 0, 0).getTime();
		
		var timeZoneString:String = DATE_PARSER.matched(7);
		if(timeZoneString != "" && timeZoneString != "Z") {
			timeZoneOffset += Std.parseInt(timeZoneString) * 60 * 60 * 1000;
			
			if(timeZoneString.indexOf(":") > 0) {
				timeZoneString = timeZoneString.substr(timeZoneString.indexOf(":") + 1);
				timeZoneOffset += Std.parseInt(timeZoneString) * 60 * 1000;
			}
		}
		
		//Month needs to be 0-indexed.
		var date:Date = new Date(year, month - 1, day, hour, minute, second);
		
		date = Date.fromTime(date.getTime() - timeZoneOffset);
		
		return date;
	}
	
	public static function toString(date:Date):String {
		var timeZoneOffset:Float = new Date(1970, 0, 1, 0, 0, 0).getTime();
		date = Date.fromTime(date.getTime() + timeZoneOffset);
		
		return DateTools.format(date, "%Y-%m-%dT%H:%M:%SZ");
	}
	
	public static inline function now():String {
		return toString(Date.now());
	}
}
