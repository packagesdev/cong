/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMReportingUtilities.h"

NSString * const BM_NOTIFICATION_DID_REPORT_PROBLEM=@"BM_NOTIFICATTION_DID_REPORT_PROBLEM";

@implementation BMReportingUtilities

+ (void) reportProblemTo:(id) inObject file:(NSString *) inPath level:(NSInteger) inLevel title:(NSString *) inTitle description:(NSString *) inDescription tags:(NSArray *) inTags extras:(NSDictionary *) inDictionary
{
	if (inPath!=nil && inTitle!=nil)
	{
		NSMutableDictionary * tReportDictionary;
	
		tReportDictionary=[NSMutableDictionary dictionaryWithObjectsAndKeys:inPath,BM_PROBLEM_FILE,
																			[NSNumber numberWithLong:inLevel],BM_PROBLEM_LEVEL,
																			inTitle,BM_PROBLEM_TITLE,
																			nil];
		if (inDescription!=nil)
		{
			[tReportDictionary setObject:inDescription forKey:BM_PROBLEM_DESCRIPTION];
		}
		
		if (inTags!=nil)
		{
			[tReportDictionary setObject:inTags forKey:BM_PROBLEM_TAGS];
		}
		
		if (inDictionary!=nil)
		{
			[tReportDictionary setObject:inDictionary forKey:BM_PROBLEM_EXTRAS];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:BM_NOTIFICATION_DID_REPORT_PROBLEM object:inObject userInfo:tReportDictionary];
	}
}

+ (void) reportProblemTo:(id) inObject file:(NSString *) inPath level:(NSInteger) inLevel title:(NSString *) inTitle description:(NSString *) inDescription
{
	[BMReportingUtilities reportProblemTo:inObject file:inPath level:inLevel title:inTitle description:inDescription tags:nil extras:nil];
}

@end
