/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMNibObjectCheckerManager.h"

@implementation BMNibObjectCheckerManager

- (void) dealloc
{
	[bundle_ release];
	
	[filePath_ release];
	
	[language_ release];
	
	
	[super dealloc];
}

#pragma mark -

- (void) setBundle:(NSBundle *) inBundle
{
	if (bundle_!=inBundle)
	{
		[bundle_ autorelease];
		
		bundle_=[inBundle retain];
	}
}

- (void) setDelegate:(id) inDelegate
{
	delegate=inDelegate;
}

- (void) setFilePath:(NSString *) inPath
{
	if (filePath_!=inPath)
	{
		[filePath_ release];
		
		filePath_=[inPath copy];
	}
}

- (void) setLanguage:(NSString *) inLanguage
{
	if (language_!=inLanguage)
	{
		[language_ release];
		
		language_=[inLanguage copy];
		
		isFrench_=NO;
		isEnglish_=NO;
		isGerman_=NO;
		isJapanese_=NO;
		
		if ([language_ isEqualToString:@"fr"]==YES ||
			[language_ isEqualToString:@"French"]==YES)
		{
			isFrench_=YES;
		}
		else if ([language_ isEqualToString:@"en"]==YES ||
				 [language_ isEqualToString:@"English"]==YES)
		{
			isEnglish_=YES;
		}
		else if ([language_ isEqualToString:@"de"]==YES ||
				 [language_ isEqualToString:@"German"]==YES)
		{
			isGerman_=YES;
		}
		else if ([language_ isEqualToString:@"ja"]==YES ||
				 [language_ isEqualToString:@"Japanese"]==YES)
		{
			isJapanese_=YES;
		}
	}
}

- (void) checkObjectsWithObjectData:(BM_OSX_NSIBObjectData *) inObjectData ofFile:(NSString *) inPath forLanguage:(NSString *) inLanguage
{
	[self setFilePath:inPath];
		
	[self setLanguage:inLanguage];
}

@end
