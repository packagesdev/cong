/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMNibCheckerController.h"

#import "BMReportingUtilities.h"

#import "BM_OSX_NSIBObjectData.h"
#import "BM_OSX_NSCustomObject.h"
#import "BM_OSX_ArchivedObject.h"
#import "BM_OSX_NSMenu.h"
#import "BM_OSX_NSMenuItem.h"

#import "BMNibMenuCheckerManager.h"

#import "BMNibKeyedUnarchiver.h"

NSString * const BM_NIB_INTERNATIONAL_LANGUAGE=@"International";



@implementation BMNibCheckerController

- (id) initWithBundle:(NSBundle *) inBundle
{
	self=[super initWithBundle:inBundle];
	
	if (self!=nil)
	{
		fileManager_=[NSFileManager defaultManager];
	}
	
	return self;
}

- (void) dealloc
{
	[menuCheckerManager_ release];
	
	[super dealloc];
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
		case BM_BUNDLETYPE_IOS_APP_BUNDLE:
			return YES;
	}
	
	return NO;
}

- (void) analyzeNibFileAtPath:(NSString *) inPath forLanguage:(NSString *) inLanguage
{
	if (inPath!=nil && inLanguage!=nil)
	{
		BOOL isDirectory;
		
		if ([fileManager_ fileExistsAtPath:inPath isDirectory:&isDirectory]==YES)
		{
			NSKeyedUnarchiver * tUnarchiver;
			NSData * tData;
			unsigned char tBuffer[11];
			
			if (isDirectory==YES)
			{
				NSString * tPath;
				
				tPath=[inPath stringByAppendingPathComponent:@"keyedobjects.nib"];
				
				if ([fileManager_ fileExistsAtPath:tPath isDirectory:&isDirectory]==NO || isDirectory==YES)
				{
					return;
				}
				
				inPath=tPath;
			}
			
			// Check that it's not a iOS nib file (starts with NIBArchive)
			
			tData=[NSData dataWithContentsOfFile:inPath];
			
			memset(tBuffer, 0, 11);
			
			[tData getBytes:tBuffer length:10];
			
			if (memcmp("NIBArchive",tBuffer,11)==0)
			{
				if (type_!=BM_BUNDLETYPE_IOS_APP_BUNDLE)
				{
					NSString * tTitle;
					NSString * tDescription;
					
					tTitle=NSLocalizedStringFromTableInBundle(@"This is an iOS nib file inside a Mac OS X application.",@"WarningsAndErrors",bundle_,@"");
					
					tDescription=NSLocalizedStringFromTableInBundle(@"If you try to load this nib, it will not work as expected.",@"WarningsAndErrors",bundle_,@"");
					
					[BMReportingUtilities reportProblemTo:delegate
													 file:inPath
													level:BM_PROBLEM_LEVEL_WARNING
													title:tTitle
											  description:tDescription
													 tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
												   extras:nil];
				}

				return;
			}
			
			tUnarchiver=[[BMNibKeyedUnarchiver alloc] initForReadingWithData:tData];
			
			if (tUnarchiver!=nil)
			{
				if ([tUnarchiver containsValueForKey:@"IB.objectdata"]==YES)
				{
					BM_OSX_NSIBObjectData * tObjectData;
					
					tObjectData=[tUnarchiver decodeObjectForKey:@"IB.objectdata"];
					
					if (tObjectData!=nil)
					{
						// Check Menus
						
						if (menuCheckerManager_==nil)
						{
							menuCheckerManager_=[BMNibMenuCheckerManager new];
							
							if (menuCheckerManager_!=nil)
							{
								[menuCheckerManager_ setDelegate:delegate];
								
								[menuCheckerManager_ setBundle:bundle_];
							}
						}
						
						if (menuCheckerManager_!=nil)
						{
							[menuCheckerManager_ checkObjectsWithObjectData:tObjectData ofFile:inPath forLanguage:inLanguage];
						}
						
						// Check Buttons
						
						if (buttonCheckerManager_==nil)
						{
							buttonCheckerManager_=[BMNibButtonCheckerManager new];
							
							if (buttonCheckerManager_!=nil)
							{
								[buttonCheckerManager_ setDelegate:delegate];
								
								[buttonCheckerManager_ setBundle:bundle_];
							}
						}
						
						if (buttonCheckerManager_!=nil)
						{
							[buttonCheckerManager_ checkObjectsWithObjectData:tObjectData ofFile:inPath forLanguage:inLanguage];
						}
						
						// A COMPLETER
					}
				}
				
				[tUnarchiver finishDecoding];
				
				[tUnarchiver release];
			}
		}
	}
}

- (Class) unarchiver:(NSKeyedUnarchiver *) inUnarchiver cannotDecodeObjectOfClassName:(NSString *) inClassName originalClasses:(NSArray *) classNames
{
	NSLog(@"Can not decode: %@",inClassName);
	
	return [BM_OSX_ArchivedObject class];
}
				
#pragma mark -
				
- (NSMutableDictionary *) checkFolderAtPath:(NSString *) inFolderPath
{
	NSMutableDictionary * tMutableDictionary=nil;
	
	if (inFolderPath!=nil)
	{
		NSArray * tFolderContentsArray;
		NSUInteger tCount;
		NSString * tLocalizationName;
		
		tLocalizationName=[inFolderPath lastPathComponent];
		
		if ([tLocalizationName isEqualToString:@"Resources"]==YES)
		{
			tLocalizationName=BM_NIB_INTERNATIONAL_LANGUAGE;
		}
		else
		{
			tLocalizationName=[tLocalizationName stringByDeletingPathExtension];
		}
		
		tFolderContentsArray=[fileManager_ contentsOfDirectoryAtPath:inFolderPath error:NULL];
	
		tCount=[tFolderContentsArray count];
		
		if (tCount>0)
		{
			tMutableDictionary=[NSMutableDictionary dictionary];
		
			for(NSString * tFileName in tFolderContentsArray)
			{
				NSString * tExtension;
				
				tExtension=[tFileName pathExtension];
				
				if ([tExtension isEqualToString:@"nib"]==YES)
				{
					NSString * tAbsolutePath;
					
					tAbsolutePath=[inFolderPath stringByAppendingPathComponent:tFileName];
					
					if (type_!=BM_BUNDLETYPE_IOS_APP_BUNDLE)
					{
						[self analyzeNibFileAtPath:tAbsolutePath forLanguage:tLocalizationName];
					}
					
					[tMutableDictionary setObject:[NSMutableArray arrayWithObject:tLocalizationName] forKey:tFileName];
				}
			}
		}
	}
	
	return tMutableDictionary;
}

- (void) checkFolderAtPath:(NSString *) inFolderPath isFramework:(BOOL) isFramework
{
	if (inFolderPath!=nil)
	{
		NSMutableDictionary * tLocalizedNibFilesDictionary;
		NSMutableDictionary * tMutableDictionary;
		NSArray * tFolderContentsArray;
		
		tLocalizedNibFilesDictionary=[NSMutableDictionary dictionary];
		
		// Look for the non-localized nib
		
		tMutableDictionary=[self checkFolderAtPath:inFolderPath];
		
		if (tMutableDictionary!=nil)
		{
			[tLocalizedNibFilesDictionary addEntriesFromDictionary:tMutableDictionary];
		}
		
		// Look for localized nib
		
		tFolderContentsArray=[fileManager_ contentsOfDirectoryAtPath:inFolderPath error:NULL];
		
		for(NSString * tFileName in tFolderContentsArray)
		{
			NSString * tExtension;
			
			tExtension=[tFileName pathExtension];
			
			if ([tExtension isEqualToString:@"lproj"]==YES)
			{
				NSDictionary * tAttributesDictionary;
				NSString * tAbsolutePath;
				
				tAbsolutePath=[inFolderPath stringByAppendingPathComponent:tFileName];
				
				// Verify that it's a folder
				
				tAttributesDictionary=[fileManager_ attributesOfItemAtPath:tAbsolutePath error:NULL];
				
				if ([tAttributesDictionary fileType]==NSFileTypeDirectory)
				{
					tMutableDictionary=[self checkFolderAtPath:tAbsolutePath];
					
					if (tMutableDictionary!=nil)
					{
						NSEnumerator * tKeyEnumerator;
						
						// Merge the data
						
						tKeyEnumerator=[tMutableDictionary keyEnumerator];
						
						if (tKeyEnumerator!=nil)
						{
							NSString * tKeyPath;
							
							while (tKeyPath=[tKeyEnumerator nextObject])
							{
								NSMutableArray * tMergedArray;
								NSMutableArray * tLocalizedLanguageArray;
								
								tLocalizedLanguageArray=[tMutableDictionary objectForKey:tKeyPath];
								
								tMergedArray=[tLocalizedNibFilesDictionary objectForKey:tKeyPath];
								
								if (tMergedArray==nil)
								{
									[tLocalizedNibFilesDictionary setObject:tLocalizedLanguageArray forKey:tKeyPath];
								}
								else
								{
									NSString * tLanguage;
									
									tLanguage=[tLocalizedLanguageArray objectAtIndex:0];
									
									[tMergedArray addObject:tLanguage];
								}
								
							}
						}
					}
				}
			}
		}
		
        for (NSString * tFileRelativePath in tLocalizedNibFilesDictionary)
        {
            NSArray * tLanguagesArray;

            tLanguagesArray=[tLocalizedNibFilesDictionary objectForKey:tFileRelativePath];

            if ([tLanguagesArray count]>1)
            {
                if ([tLanguagesArray containsObject:BM_NIB_INTERNATIONAL_LANGUAGE]==YES)
                {
                    NSString * tTitle;
                    NSString * tDescription;

                    tTitle=NSLocalizedStringFromTableInBundle(@"There are both non-localized and localized versions of this file.",@"WarningsAndErrors",bundle_,@"");

                    tDescription=NSLocalizedStringFromTableInBundle(@"This can produce unwanted results.",@"WarningsAndErrors",bundle_,@"");

                    [BMReportingUtilities reportProblemTo:delegate
                                                     file:[inFolderPath stringByAppendingPathComponent:tFileRelativePath]
                                                    level:BM_PROBLEM_LEVEL_WARNING
                                                    title:tTitle
                                              description:tDescription
                                                     tags:[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_NIB,nil]
                                                   extras:nil];
                }
            }
		}
		
		// Analyse the data
		
		//NSLog(@"%@",tLocalizedStringsFilesDictionary);
	}
}

- (void) testItem:(id) inItem atPath:(NSString *) inPath ofType:(NSUInteger) inType withDelegate:(id) inDelegate
{	
	//NSLog(@"%@",inPath);
	
	[super testItem:inItem atPath:inPath ofType:inType withDelegate:inDelegate];
		
	type_=inType;
	
	if (inType==BM_BUNDLETYPE_FRAMEWORK)
	{
		NSString * tVersionsFolderPath;
		NSArray * tVersionsContentArray;
		
		// Check all versions
		
		tVersionsFolderPath=[inPath stringByAppendingPathComponent:@"Versions"];
		
		tVersionsContentArray=[fileManager_ contentsOfDirectoryAtPath:tVersionsFolderPath error:NULL];
		
		for(NSString * tFileName in tVersionsContentArray)
		{
			NSString * tAbsolutePath;
			NSDictionary * tAttributesDictionary;
			
			tAbsolutePath=[tVersionsFolderPath stringByAppendingPathComponent:tFileName];
			
			tAttributesDictionary=[fileManager_ attributesOfItemAtPath:tAbsolutePath error:NULL];
			
			if ([tAttributesDictionary fileType]==NSFileTypeDirectory)
			{
				NSString * tResourcesFolderPath;
				BOOL isDirectory;
				
				tResourcesFolderPath=[tAbsolutePath stringByAppendingPathComponent:@"Resources"];
				
				if ([fileManager_ fileExistsAtPath:tResourcesFolderPath isDirectory:&isDirectory]==YES && isDirectory==YES)
				{
					[self checkFolderAtPath:tResourcesFolderPath isFramework:YES];
				}
			}
		}
	}
	else
	{
		NSString * tResourcesFolderPath;
		
		if (inType==BM_BUNDLETYPE_IOS_APP_BUNDLE)
		{
			tResourcesFolderPath=inPath;
		}
		else
		{
			tResourcesFolderPath=[inPath stringByAppendingPathComponent:@"Contents/Resources"];
		}
		
		// Check first level of Resources
		
		[self checkFolderAtPath:tResourcesFolderPath isFramework:NO];
	}
}

@end
