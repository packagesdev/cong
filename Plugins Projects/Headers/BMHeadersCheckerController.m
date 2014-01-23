/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMHeadersCheckerController.h"

#import "BMReportingUtilities.h"

@implementation BMHeadersCheckerController

- (id) initWithBundle:(NSBundle *) inBundle
{
	self=[super initWithBundle:inBundle];
	
	if (self!=nil)
	{
		fileManager_=[NSFileManager defaultManager];
	}
	
	return self;
}

#pragma mark -

- (BOOL) canTestItemOfType:(NSUInteger) inType
{
	switch(inType)
	{
		case BM_BUNDLETYPE_APP_BUNDLE:
		case BM_BUNDLETYPE_FRAMEWORK:
		case BM_BUNDLETYPE_BUNDLE:
		case BM_BUNDLETYPE_PLUGIN:
		case BM_BUNDLETYPE_AUTOMATOR_ACTION:
		case BM_BUNDLETYPE_SPOTLIGHT_IMPORTER:
		case BM_BUNDLETYPE_PREFERENCES_PANE:
			return YES;
	}
	
	return NO;
}

- (void) checkFolderAtPath:(NSString *) inFolderPath isFramework:(BOOL) isFramework
{
	if (inFolderPath!=nil)
	{
		NSArray * tFolderContentsArray;
		NSUInteger i,tCount;
		NSString * tTitle;
		NSString * tDescription;
		
		tFolderContentsArray=[fileManager_ contentsOfDirectoryAtPath:inFolderPath error:NULL];
	
		tCount=[tFolderContentsArray count];
		
		for(i=0;i<tCount;i++)
		{
			NSString * tFileName;
			NSString * tExtension;
			NSUInteger tExtensionLength;
			
			tFileName=[tFolderContentsArray objectAtIndex:i];
			
			tExtension=[tFileName pathExtension];
			
			tExtensionLength=[tExtension length];
			
			if ((tExtensionLength>0 && tExtensionLength<3) &&
				([tExtension isEqualToString:@"h"]==YES || [tExtension isEqualToString:@"hh"]))
			{
				NSDictionary * tAttributesDictionary;
				NSString * tAbsolutePath;
				
				tAbsolutePath=[inFolderPath stringByAppendingPathComponent:tFileName];
				
				// Check if it's a file or a folder
				
				tAttributesDictionary=[fileManager_ attributesOfItemAtPath:tAbsolutePath error:NULL];
				
				if ([tAttributesDictionary fileType]==NSFileTypeRegular)
				{
					tTitle=NSLocalizedStringFromTableInBundle(@"Header file found",@"WarningsAndErrors",bundle_,@"");
					
					if (isFramework==YES)
					{
						tDescription=NSLocalizedStringFromTableInBundle(@"Header files in embedded frameworks are useless. Noone is going to use them.",@"WarningsAndErrors",bundle_,@"");
					}
					else
					{
						tDescription=@"";
					}
					
					BM_REPORT_WARNING(delegate,tAbsolutePath,tTitle,tDescription);
				}
			}
		}
	}
}

- (void) testItem:(id) inItem atPath:(NSString *) inPath ofType:(NSUInteger) inType withDelegate:(id) inDelegate
{
	[super testItem:inItem atPath:inPath ofType:inType withDelegate:inDelegate];
		
	if (inType==BM_BUNDLETYPE_FRAMEWORK)
	{
		NSString * tVersionsFolderPath;
		NSArray * tVersionsContentArray;
		NSUInteger i,tCount;
		
		// Check root level
		
		[self checkFolderAtPath:inPath isFramework:YES];
	
		// Check all versions
		
		tVersionsFolderPath=[inPath stringByAppendingPathComponent:@"Versions"];
		
		tVersionsContentArray=[fileManager_ contentsOfDirectoryAtPath:tVersionsFolderPath error:NULL];
		
		tCount=[tVersionsContentArray count];
		
		for(i=0;i<tCount;i++)
		{
			NSString * tFileName;
			NSString * tAbsolutePath;
			NSDictionary * tAttributesDictionary;
			
			tFileName=[tVersionsContentArray objectAtIndex:i];
			
			tAbsolutePath=[tVersionsFolderPath stringByAppendingPathComponent:tFileName];
			
			tAttributesDictionary=[fileManager_ attributesOfItemAtPath:tAbsolutePath error:NULL];
			
			if ([tAttributesDictionary fileType]==NSFileTypeDirectory)
			{
				NSString * tHeadersFolderPath;
				BOOL isDirectory;
				
				tHeadersFolderPath=[tAbsolutePath stringByAppendingPathComponent:@"Headers"];
				
				if ([fileManager_ fileExistsAtPath:tHeadersFolderPath isDirectory:&isDirectory]==YES && isDirectory==YES)
				{
					[self checkFolderAtPath:tHeadersFolderPath isFramework:YES];
				}
			}
		}
	}
	else
	{
		if (inType!=BM_BUNDLETYPE_IOS_APP_BUNDLE)
		{
			// Check first level of Frameworks
		
			[self checkFolderAtPath:[inPath stringByAppendingPathComponent:@"Contents/Frameworks"] isFramework:YES];
			
			// Check first level of Resources
			
			[self checkFolderAtPath:[inPath stringByAppendingPathComponent:@"Contents/Resources"] isFramework:NO];
		}
		else
		{
			// Check first level of Resources
			
			[self checkFolderAtPath:inPath isFramework:NO];
		}

	}
}

@end
