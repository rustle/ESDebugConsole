//
//  ESDebugConsole.m
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

#import "ESDebugConsole.h"
#import <asl.h>
#import "ESConsoleEntry.h"

//#define ASL_KEY_TIME      "Time"
//#define ASL_KEY_HOST      "Host"
//#define ASL_KEY_SENDER    "Sender"
//#define ASL_KEY_FACILITY  "Facility"
//#define ASL_KEY_PID       "PID"
//#define ASL_KEY_UID       "UID"
//#define ASL_KEY_GID       "GID"
//#define ASL_KEY_LEVEL     "Level"
//#define ASL_KEY_MSG       "Message"

NSString *const kESDebugConsoleAllLogsKey = @"ESDebugConsoleAllLogsKey";

@interface ESDebugConsole ()
@end

@implementation ESDebugConsole

#pragma mark - 

+ (id)sharedDebugConsole
{
	static ESDebugConsole *sharedConsole;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedConsole = [ESDebugConsole new];
	});
	return sharedConsole;
}

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		if ([self respondsToSelector:@selector(iOSInit)])
		{
			[self performSelector:@selector(iOSInit)];
		}
	}
	return self;
}

- (void)dealloc
{
	if ([self respondsToSelector:@selector(iOSDealloc)])
	{
		[self performSelector:@selector(iOSDealloc)];
	}
}

#pragma mark -

//http://www.cocoanetics.com/2011/03/accessing-the-ios-system-log/
//http://developer.apple.com/library/ios/#documentation/System/Conceptual/ManPages_iPhoneOS/man3/asl.3.html#//apple_ref/doc/man/3/asl
+ (NSDictionary *)getConsole
{
	aslmsg q, m;
	int i;
	const char *key, *val;
	NSMutableDictionary *consoleLog = [NSMutableDictionary new];
	@autoreleasepool {
		q = asl_new(ASL_TYPE_QUERY);
		NSMutableArray *allLogs = [NSMutableArray new];
		aslresponse r = asl_search(NULL, q);
		while (NULL != (m = aslresponse_next(r)))
		{
			NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
			for (i = 0; (NULL != (key = asl_key(m, i))); i++)
			{
				NSString *keyString = [NSString stringWithUTF8String:(char *)key];
				val = asl_get(m, key);
				if (val != NULL)
				{
					NSString *string = [NSString stringWithUTF8String:val];
					if (string != nil)
					{
						[tmpDict setObject:string forKey:keyString];
					}
				}
			}
			ESConsoleEntry *entry = [[ESConsoleEntry alloc] initWithDictionary:tmpDict];
			if (entry != nil)
			{
				NSMutableArray *logEntries = [consoleLog objectForKey:entry.applicationIdentifier];
				if (logEntries == nil)
				{
					logEntries = [NSMutableArray new];
					consoleLog[entry.applicationIdentifier] = logEntries;
				}
				[logEntries addObject:entry];
				[allLogs addObject:entry];
			}
		}
		aslresponse_free(r);
		for (NSMutableArray *logEntries in [consoleLog allValues])
		{
			[logEntries sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO], nil]];
		}
		consoleLog[kESDebugConsoleAllLogsKey] = allLogs;
	}
	NSDictionary *retVal = [consoleLog copy];
	return retVal;
}

@end

@implementation NSArray (ConsoleFormatting)

- (NSString *)esdebug_formattedConsoleString
{
	NSMutableString *logs = [NSMutableString stringWithString:@"Console Logs: (\n"];
	for (ESConsoleEntry *entry in self)
	{
		[logs appendString:@"---------------\n"];
		[logs appendString:[entry description]];
		[logs appendString:@"\n"];
	}
	[logs appendString:@"\n)"];
	return logs;
}

@end