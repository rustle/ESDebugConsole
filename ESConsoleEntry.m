//
//  ESConsoleEntry.m
//
//  Copyright Doug Russell 2012. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ESConsoleEntry.h"
#import <asl.h>

@implementation ESConsoleEntry

#pragma mark -

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
	self = [super init];
	if (self)
	{
		if (dictionary == nil)
		{
			return nil;
		}
		_message = [dictionary objectForKey:[NSString stringWithCString:ASL_KEY_MSG encoding:NSUTF8StringEncoding]];
		if (_message.length > 200)
		{
			_shortMessage = [_message substringToIndex:200];
		}
		else
		{
			_shortMessage = self.message;
		}
		_applicationIdentifier = [dictionary objectForKey:[NSString stringWithCString:ASL_KEY_FACILITY encoding:NSUTF8StringEncoding]];
		if (_applicationIdentifier == nil)
		{
			_applicationIdentifier = [dictionary objectForKey:[NSString stringWithCString:ASL_KEY_SENDER encoding:NSUTF8StringEncoding]];
		}
		_date = [NSDate dateWithTimeIntervalSince1970:[[dictionary objectForKey:[NSString stringWithCString:ASL_KEY_TIME encoding:NSUTF8StringEncoding]] doubleValue]];
	}
	return self;
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"Application Identifier: %@\n\nConsole Message: %@\n\nTime: %@", self.applicationIdentifier, self.message, self.date];
}

@end
