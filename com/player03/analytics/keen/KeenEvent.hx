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

import com.player03.analytics.base.AnalyticsEvent;

class KeenEvent extends AnalyticsEvent {
	public function new(collectionName:String) {
		super(collectionName);
		
		setProperty("keen", {timestamp:getProperty(AnalyticsEvent.EVENT_TIME)});
	}
}
