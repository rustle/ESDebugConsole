//
//  ESDebugConsole+iOS_Mail.m
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

#import "ESDebugConsole+iOS_Mail.h"
#import "ESDebugConsole+iOS_GUI.h"
#import <MessageUI/MessageUI.h>

@implementation ESDebugConsole (iOS_Mail)

#pragma mark - Accessors

- (NSArray *)recipients
{
	return _recipients;
}

- (void)setRecipients:(NSArray *)recipients
{
	if (_recipients != recipients)
	{
		_recipients = recipients;
	}
}

- (NSString *)subject
{
	return _subject;
}

- (void)setSubject:(NSString *)subject
{
	if (_subject != subject)
	{
		_subject = subject;
	}
}

- (NSString *)message
{
	return _message;
}

- (void)setMessage:(NSString *)message
{
	if (_message != message)
	{
		_message = message;
	}
}

- (NSData *)attachment
{
	return _attachment;
}

- (void)setAttachment:(NSData *)attachment
{
	if (_attachment != attachment)
	{
		_attachment = attachment;
	}
}

#pragma mark - 

- (void)sendConsoleAsEmail
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = (id<MFMailComposeViewControllerDelegate>)self;
	[picker setToRecipients:self.recipients];
	[picker setSubject:self.subject];
	if (self.attachment)
		[picker addAttachmentData:self.attachment mimeType:@"octet/stream" fileName:@"console.log"];
	if (self.message)
		[picker setMessageBody:self.message isHTML:NO];
	[self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error 
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
            break;
        case MFMailComposeResultFailed:
            break;
        default:
            break;
    }
	controller.delegate = nil;
	[controller dismissViewControllerAnimated:YES completion:nil];
}

@end
