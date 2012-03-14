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
#import "ARCLogic.h"

@implementation ESConsoleEntry
@synthesize message=_message;
@synthesize shortMessage=_shortMessage;
@synthesize applicationIdentifier=_applicationIdentifier;
@synthesize date=_date;

#pragma mark -

- (id)initWithDictionary:(NSDictionary *)dictionary
{
	self = [super init];
	if (self != nil)
	{
		if (dictionary == nil)
		{
			NO_ARC([self release];)
			self = nil;
			return nil;
		}
		
		self.message = [dictionary objectForKey:[NSString stringWithCString:ASL_KEY_MSG encoding:NSUTF8StringEncoding]];
		if (self.message.length > 200)
			self.shortMessage = [self.message substringToIndex:200];
		else
			self.shortMessage = self.message;
		self.applicationIdentifier = [dictionary objectForKey:[NSString stringWithCString:ASL_KEY_FACILITY encoding:NSUTF8StringEncoding]];
		if (self.applicationIdentifier == nil)
			self.applicationIdentifier = [dictionary objectForKey:[NSString stringWithCString:ASL_KEY_SENDER encoding:NSUTF8StringEncoding]];
		self.date = [NSDate dateWithTimeIntervalSince1970:[[dictionary objectForKey:[NSString stringWithCString:ASL_KEY_TIME encoding:NSUTF8StringEncoding]] doubleValue]];
	}
	return self;
}

- (void)dealloc
{
	NO_ARC(
		   [_message release];
		   [_shortMessage release];
		   [_applicationIdentifier release];
		   [_date release];
		   [super dealloc];
		   )
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"Application Identifier: %@\n\nConsole Message: %@\n\nTime: %@", self.applicationIdentifier, self.message, self.date];
}

@end
