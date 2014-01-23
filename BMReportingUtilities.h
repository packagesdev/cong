/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "BMReportingConstants.h"

#define BM_REPORT_NOTE(inObject,inPath,inTitle,inDescription) [BMReportingUtilities reportProblemTo:inObject file:inPath level:BM_PROBLEM_LEVEL_NOTE title:inTitle description:inDescription]

#define BM_REPORT_NOTE_TAGS(inObject,inPath,inTitle,inDescription,inTags) [BMReportingUtilities reportProblemTo:inObject file:inPath level:BM_PROBLEM_LEVEL_NOTE title:inTitle description:inDescription tags:inTags extras:nil]


#define BM_REPORT_WARNING(inObject,inPath,inTitle,inDescription) [BMReportingUtilities reportProblemTo:inObject file:inPath level:BM_PROBLEM_LEVEL_WARNING title:inTitle description:inDescription]

#define BM_REPORT_WARNING_TAGS(inObject,inPath,inTitle,inDescription,inTags) [BMReportingUtilities reportProblemTo:inObject file:inPath level:BM_PROBLEM_LEVEL_WARNING title:inTitle description:inDescription tags:inTags extras:nil]

#define BM_REPORT_ERROR(inObject,inPath,inTitle,inDescription) [BMReportingUtilities reportProblemTo:inObject file:inPath level:BM_PROBLEM_LEVEL_ERROR title:inTitle description:inDescription]

#define BM_REPORT_ERROR_TAGS(inObject,inPath,inTitle,inDescription,inTags) [BMReportingUtilities reportProblemTo:inObject file:inPath level:BM_PROBLEM_LEVEL_ERROR title:inTitle description:inDescription tags:inTags extras:nil]


extern NSString * const BM_NOTIFICATION_DID_REPORT_PROBLEM;

@interface BMReportingUtilities : NSObject
{

}

+ (void) reportProblemTo:(id) inObject file:(NSString *) inPath level:(NSInteger) inLevel title:(NSString *) inTitle description:(NSString *) inDescription tags:(NSArray *) inTags extras:(NSDictionary *) inDictionary;

+ (void) reportProblemTo:(id) inObject file:(NSString *) inPath level:(NSInteger) inLevel title:(NSString *) inTitle description:(NSString *) inDescription;

@end
