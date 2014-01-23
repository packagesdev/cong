/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMNSStringFormatUtilities.h"

@implementation BMNSStringFormatUtilities

+ (NSString *) localizedNameForFormat:(NSUInteger) inFormat
{
	// A COMPLETER

	return @"";
}

+ (BOOL) stringConformsToOSTypeFormat:(NSString *) inString
{
	BOOL tConforms=NO;
	
	if ([inString length]==4)
	{
		NSUInteger i;
		
		tConforms=YES;
		
		for(i=0;i<4;i++)
		{
			unichar tCharacter;
			
			tCharacter=[inString characterAtIndex:i];
			
			if (tCharacter>0xFF)
			{
				tConforms=NO;
				
				break;
			}
		}
	}
	
	return tConforms;
}

+ (BOOL) stringConformsToMajorMinorRevisionFormat:(NSString *) inString
{
	NSUInteger tIndex,tLength;
	NSUInteger tLastDotIndex=-1;
	
	tIndex=0;
	tLength=[inString length];
	
	while (tIndex<tLength)
	{
		unichar tCharacter;
		
		tCharacter=[inString characterAtIndex:tIndex];
		
		// Check that the character value is allowed
		
		if (tCharacter=='.')
		{
			if ((tIndex-1)==tLastDotIndex ||
				tIndex==(tLength-1))	// This also deals with the tIndex == 0 case
			{
				return NO;
			}
			
			tLastDotIndex=tIndex;
		}
		else
		{
			if (tCharacter<'0' || tCharacter>'9')
			{
				return NO;
			}
		}
		
		tIndex++;
	}
	
	return YES;
}	

+ (BOOL) stringConformsToUTIFormat:(NSString *) inString acceptUnicode:(BOOL) inAcceptUnicode
{
	NSUInteger tIndex,tLength;
	NSUInteger tLastDotIndex=-1;
	
	tIndex=0;
	tLength=[inString length];

	while (tIndex<tLength)
	{
		unichar tCharacter;
		
		tCharacter=[inString characterAtIndex:tIndex];
		
		// Check that the character value is allowed
		
		if (tCharacter=='.')
		{
			if ((tIndex-1)==tLastDotIndex ||
				tIndex==(tLength-1))	// This also deals with the tIndex == 0 case
			{
				return NO;
			}
			
			tLastDotIndex=tIndex;
		}
		else
		{
			if (tCharacter=='-' ||
				(tCharacter>='A' && tCharacter<='Z') ||
				(tCharacter>='a' && tCharacter<='z') || 
				(tCharacter>='0' && tCharacter<='9') ||
				(inAcceptUnicode==YES && tCharacter>0xFF))
			{
				
			}
			else
			{
				return NO;
			}
		}
		
		tIndex++;
	}
	
	return YES;
}

+ (BOOL) stringConformsToUTIFormat:(NSString *) inString
{
	return [BMNSStringFormatUtilities stringConformsToUTIFormat:inString acceptUnicode:YES];
}

+ (BOOL) stringConformsToBundleIdentifierFormat:(NSString *) inString
{
	return [BMNSStringFormatUtilities stringConformsToUTIFormat:inString acceptUnicode:NO];
}

#pragma mark -

+ (BOOL) object:(id) inObject conformsToFormat:(NSUInteger) inFormat
{
	switch(inFormat)
	{
		case BM_STRING_FORMAT_OS_TYPE:
			
			return [BMNSStringFormatUtilities stringConformsToOSTypeFormat:inObject];
			
		case BM_STRING_FORMAT_UTI:
			
			return [BMNSStringFormatUtilities stringConformsToUTIFormat:inObject];
			
		case BM_STRING_FORMAT_MAJOR_MINOR_REVISION_VERSION:
		
			return [BMNSStringFormatUtilities stringConformsToMajorMinorRevisionFormat:inObject];
		
		case BM_STRING_FORMAT_STRICT_KERNEL_VERSION:
			
			// A  COMPLETER
			
			break;
			
		case BM_STRING_FORMAT_BUNDLE_IDENTIFIER:
			
			return [BMNSStringFormatUtilities stringConformsToBundleIdentifierFormat:inObject];
	}
	
	return YES;
}

@end
