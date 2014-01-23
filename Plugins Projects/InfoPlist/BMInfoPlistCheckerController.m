/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMInfoPlistCheckerController.h"

#import "BMFilesHierarchyUtilities.h"

#import "BMStringsFileChecker.h"

#import "BMPropertyListFileChecker.h"

#import "BMIconsUtilities.h"

#import "BMReportingUtilities.h"

#import "BMStringUtilities.h"

#import "BMNSStringFormatUtilities.h"

@implementation BMInfoPlistCheckerController

- (id) initWithBundle:(NSBundle *) inBundle
{
	self=[super initWithBundle:inBundle];
	
	if (self!=nil)
	{
		propertyListCheckersRepository_=[[NSMutableDictionary alloc] initWithCapacity:5];
		
		fileManager_=[NSFileManager defaultManager];
	}
	
	return self;
}

- (void) dealloc
{
	[propertyListCheckersRepository_ release];
	
	[itemPath_ release];

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

- (BMPropertyListFileChecker *) propertyListCheckForType:(NSUInteger) inType withCheckList:(NSString *) inCheckListName
{
	BMPropertyListFileChecker * tPropertyListFileChecker;
	
	tPropertyListFileChecker=[propertyListCheckersRepository_ objectForKey:[NSNumber numberWithInt:inType]];
	
	if (tPropertyListFileChecker==nil)
	{
		tPropertyListFileChecker=[[BMPropertyListFileChecker alloc] initWithCheckListAtPath:[bundle_ pathForResource:inCheckListName ofType:@"plist"]];
		
		 if (tPropertyListFileChecker!=nil)
		 {
			[propertyListCheckersRepository_ setObject:tPropertyListFileChecker forKey:[NSNumber numberWithInt:inType]];
			
			[tPropertyListFileChecker release];
		 }
	}
	
	return tPropertyListFileChecker;
}

- (void) testAppBundle
{
	BMPropertyListFileChecker * tPropertyListFileChecker;
	BMStringsFileChecker *tStringsFileChecker;
	NSDictionary * tInfoDictionary;
	NSArray * tArray;
	NSString * tString;
	NSString * tTitle;
	NSString * tDescription;
	NSArray * tTagsArray;
	BOOL tLocalizedShortVersionStringFound=NO;
	BOOL targetsMacAppStore=NO;
	NSString * tBundleVersionString;
	NSString * tInfoPlistPath;
	
	tInfoPlistPath=[itemPath_ stringByAppendingPathComponent:@"/Contents/Info.plist"];
	
	// Check the consistency of data
	
	tPropertyListFileChecker=[self propertyListCheckForType:BM_BUNDLETYPE_APP_BUNDLE withCheckList:@"App_InfoPlist_CheckList"];
	
	if (tPropertyListFileChecker!=nil)
	{
		if ([tPropertyListFileChecker checkPropertyListFileAtPath:tInfoPlistPath withDelegate:delegate]==NO)
		{
			if ([tPropertyListFileChecker problemLevel]==BM_PROBLEM_LEVEL_ERROR)
			{
				return;
			}
		}
	}
	
	tInfoDictionary=[NSDictionary dictionaryWithContentsOfFile:tInfoPlistPath];
	
	if ([tInfoDictionary objectForKey:@"LSApplicationCategoryType"]!=nil)
	{
		//if ([fileManager_ fileExistsAtPath:[itemPath_ stringByAppendingPathComponent:@"/Contents/_CodeSignature/CodeResources"]]==YES)
		
		//targetsMacAppStore=YES;
	}
	
	// Check for Empty InfoPlist.strings file
	
	tStringsFileChecker=[BMStringsFileChecker stringsFileChecker];
	
	if (tStringsFileChecker!=nil)
	{
		NSArray * tLocalizationFolderPathsArray;
		BOOL hasCFBundleDisplayNameKey=NO;
		
		hasCFBundleDisplayNameKey=([tInfoDictionary objectForKey:@"CFBundleDisplayName"]!=nil);
		
		tLocalizationFolderPathsArray=[BMFilesHierarchyUtilities allLocalizationFoldersAtPath:[itemPath_ stringByAppendingPathComponent:@"Contents/Resources"]];
		
		for(NSString * tLprojFolderPath in tLocalizationFolderPathsArray)
		{
			NSString * tInfoPListStringsPath;
			BOOL isDirectory;
			
			tInfoPListStringsPath=[tLprojFolderPath stringByAppendingPathComponent:@"InfoPlist.strings"];
			
			if ([fileManager_ fileExistsAtPath:tInfoPListStringsPath isDirectory:&isDirectory]==YES)
			{
				if (isDirectory==YES)
				{
					// A COMPLETER
				}
				else
				{
					// LSHasLocalizedDisplayName
					
					//if ([tStringsFileChecker checkStringsFileAtPath:tInfoPListStringsPath withDelegate:delegate]==YES)
					{
						NSDictionary * tLocalizedInfoDictionary;
						
						tLocalizedInfoDictionary=[NSDictionary dictionaryWithContentsOfFile:tInfoPListStringsPath];
						
						if ([tLocalizedInfoDictionary count]==0)
						{
							// No localizations provided
						
							tTitle=NSLocalizedStringFromTableInBundle(@"No localizations defined in file",@"WarningsAndErrors",bundle_,@"");
							
							tDescription=NSLocalizedStringFromTableInBundle(@"If no localizations are to be defined, consider removing this file.",@"WarningsAndErrors",bundle_,@"");
							
							tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,BM_PROBLEM_TAG_GENERIC_STRINGS,nil];
							
							BM_REPORT_WARNING_TAGS(delegate,tInfoPListStringsPath,tTitle,tDescription,tTagsArray);
						}
						else
						{
							if ([tLocalizedInfoDictionary objectForKey:@"CFBundleVersion"]!=nil)
							{
								tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The key %@ is not localizable",@"WarningsAndErrors",bundle_,@""),@"CFBundleVersion"];
								
								tDescription=@"";
								
								tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,nil];
								
								BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
							}
							
							if ([tLocalizedInfoDictionary objectForKey:@"CFBundleShortVersionString"]!=nil)
							{
								tLocalizedShortVersionStringFound=YES;
								
								tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Localized value defined for CFBundleShortVersionString",@"WarningsAndErrors",bundle_,@""),@"CFBundleVersion"];
								
								tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Localized values for CFBundleShortVersionString can cause receipt validation to fail",@"WarningsAndErrors",bundle_,@""),@"CFBundleVersion"];
								
								tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,BM_PROBLEM_TAG_GENERIC_MAC_APP_STORE,nil];
								
								BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
							}
							
							if ([tLocalizedInfoDictionary objectForKey:@"CFBundleDisplayName"]!=nil)
							{
								// Key should also be in the Info.plist file
								
								if (hasCFBundleDisplayNameKey==NO)
								{
									tTitle=NSLocalizedStringFromTableInBundle(@"Missing value for CFBundleDisplayName",@"WarningsAndErrors",bundle_,@"");
									
									tDescription=NSLocalizedStringFromTableInBundle(@"When a localized value is defined for the CFBundleDisplayName key, a value should be defined in the Info.plist file too.",@"WarningsAndErrors",bundle_,@"");
							
									tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,nil];
							
									BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
								}
								
								// Key CFBundleName should also be localized
								
								if ([tLocalizedInfoDictionary objectForKey:@"CFBundleName"]==nil)
								{
									tTitle=NSLocalizedStringFromTableInBundle(@"Missing localized value for CFBundleName",@"WarningsAndErrors",bundle_,@"");
									
									tDescription=NSLocalizedStringFromTableInBundle(@"When a localized value is defined for the CFBundleDisplayName key, a localized value should also be defined for the CFBundleName key.",@"WarningsAndErrors",bundle_,@"");
							
									tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,BM_PROBLEM_TAG_GENERIC_STRINGS,nil];
							
									BM_REPORT_WARNING_TAGS(delegate,tInfoPListStringsPath,tTitle,tDescription,tTagsArray);
								}
							}
							else
							{
								// Key CFBundleName should not be localized
								
								if ([tLocalizedInfoDictionary objectForKey:@"CFBundleName"]!=nil)
								{
									tTitle=NSLocalizedStringFromTableInBundle(@"Missing localized value for CFBundleDisplayName",@"WarningsAndErrors",bundle_,@"");
									
									tDescription=NSLocalizedStringFromTableInBundle(@"When a localized value is defined for the CFBundleName key, a localized value should also be defined for the CFBundleDisplayName key.",@"WarningsAndErrors",bundle_,@"");
							
									tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,BM_PROBLEM_TAG_GENERIC_STRINGS,nil];
							
									BM_REPORT_WARNING_TAGS(delegate,tInfoPListStringsPath,tTitle,tDescription,tTagsArray);
								}
							}
						}
					}
				}
			}
		}
	}
	else
	{
		
	}
	
	// Common checks
	
	/**** Core Foundation Keys ****/
	
	// CFAppleHelpAnchor
	
	tString=[tInfoDictionary objectForKey:@"CFAppleHelpAnchor"];
	
	if (tString!=nil)
	{
		// Check that at least one file + (html/htm) exists in 
		
		// A COMPLETER
	}
	
	// CFBundleShortVersion and CFBundleVersion
	
	tBundleVersionString=[tInfoDictionary objectForKey:@"CFBundleVersion"];
	
	if (targetsMacAppStore==YES)
	{
		if (tBundleVersionString!=nil)
		{
			if ([BMNSStringFormatUtilities object:tBundleVersionString conformsToFormat:BM_STRING_FORMAT_MAJOR_MINOR_REVISION_VERSION]==NO)
			{
				tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Non conforming object value for key \"%@\"",@"CommonPropertyList",@""),@"CFBundleVersion"];
				
				//tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The icon defined for the document type \"%@\" could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),[tDocumentDictionary objectForKey:@"CFBundleTypeName"],tIconPath];
				
				tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,BM_PROBLEM_TAG_GENERIC_MAC_APP_STORE,nil];
				
				BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,nil,tTagsArray);
			}
		}
	}
	
	tString=[tInfoDictionary objectForKey:@"CFBundleShortVersionString"];

	if ([tString length]>0)
	{
		if ([tBundleVersionString isEqualToString:tString]==YES)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"Values of CFBundleVersion and CFBundleShortVersionString are identical.",@"WarningsAndErrors",bundle_,@"");
					
			//tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The icon defined for the document type \"%@\" could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),[tDocumentDictionary objectForKey:@"CFBundleTypeName"],tIconPath];
					
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
			BM_REPORT_NOTE_TAGS(delegate,tInfoPlistPath,tTitle,nil,tTagsArray);
		}
	}
	else
	{
		if (tLocalizedShortVersionStringFound==NO)
		{
			if (tString==nil)
			{
				tTitle=NSLocalizedStringFromTableInBundle(@"CFBundleShortVersionString has not been set.",@"WarningsAndErrors",bundle_,@"");
				
				//tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The icon defined for the document type \"%@\" could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),[tDocumentDictionary objectForKey:@"CFBundleTypeName"],tIconPath];
				
				tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
				
				BM_REPORT_NOTE_TAGS(delegate,tInfoPlistPath,tTitle,nil,tTagsArray);
			}
			else
			{
				tTitle=NSLocalizedStringFromTableInBundle(@"CFBundleShortVersionString is an empty string.",@"WarningsAndErrors",bundle_,@"");
				
				//tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The icon defined for the document type \"%@\" could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),[tDocumentDictionary objectForKey:@"CFBundleTypeName"],tIconPath];
				
				tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
				
				BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,nil,tTagsArray);
			}
		}
	}

	
	// CFBundleDocumentTypes
	
	tArray=[tInfoDictionary objectForKey:@"CFBundleDocumentTypes"];
	
	if (tArray!=nil)
	{
		for(NSDictionary * tDocumentDictionary in tArray)
		{
			tString=[tDocumentDictionary objectForKey:@"CFBundleTypeIconFile"];
			
			if ([tString length]>0)
			{
				// Check that the file exists
				
				NSString * tIconPath;
				BOOL isDirectory;
				
				if ([[tString pathExtension] isEqualToString:@"icns"]==NO)
				{
					tString=[tString stringByAppendingPathExtension:@"icns"];
				} 
				
				tIconPath=[[itemPath_ stringByAppendingPathComponent:@"Contents/Resources"] stringByAppendingPathComponent:tString];
				
				// Check that the icon file is there
				
				if ([fileManager_ fileExistsAtPath:tIconPath isDirectory:&isDirectory]==NO)
				{
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Missing icon file \"%@\".",@"WarningsAndErrors",bundle_,@""),tString];
					
					tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The icon defined for the document type \"%@\" could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),[tDocumentDictionary objectForKey:@"CFBundleTypeName"],tIconPath];
					
					tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
					BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
				}
				else
				{
					if(isDirectory==YES)
					{
						// A COMPLETER
					}
					else
					{
						if ([BMIconsUtilities isIcnsFileAtPath:tIconPath]==NO)
						{
							tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"\"%@\" is not a valid .icns file.",@"WarningsAndErrors",bundle_,@""),tString];
							
							tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The icon file for the document type \"%@\" is not a valid .icns file.",@"WarningsAndErrors",bundle_,@""),[tDocumentDictionary objectForKey:@"CFBundleTypeName"],tIconPath];
							
							tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
							
							BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
						}
						else
						{
							NSArray * tArray;
							BOOL has512representation=NO;
							NSUInteger i,tCount;
							
							tArray=[BMIconsUtilities availableSizesForIcnsAtPath:tIconPath];
							
							tCount=[tArray count];
							
							for(i=0;i<tCount;i++)
							{
								NSUInteger tRepresentationSize;
								
								tRepresentationSize=[[tArray objectAtIndex:i] unsignedLongValue];
								
								if (tRepresentationSize==512)
								{
									has512representation=YES;
								}
							}
							
							if (has512representation==NO)
							{
								tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Missing %@ representation for the .icns file.",@"WarningsAndErrors",bundle_,@""), @"512x512"];
									
								tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The icon file for the document type \"%@\" misses a 512x512 representation.",@"WarningsAndErrors",bundle_,@""),[tDocumentDictionary objectForKey:@"CFBundleTypeName"],tIconPath];
								
								tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,nil];
								
								BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
								
								
							}
						}

					}
				}
			}
		}
	}
	
	// CFBundleIconFile
	
	tString=[tInfoDictionary objectForKey:@"CFBundleIconFile"];
	
	if (tString!=nil)
	{
		// Check that the file exists
		
		NSString * tIconPath;
		BOOL isDirectory;
		
		if ([[tString pathExtension] isEqualToString:@"icns"]==NO)
		{
			tString=[tString stringByAppendingPathExtension:@"icns"];
		} 
		
		tIconPath=[[itemPath_ stringByAppendingPathComponent:@"Contents/Resources"] stringByAppendingPathComponent:tString];
		
		// Check that the Dock tile plug-in is there
		
		if ([fileManager_ fileExistsAtPath:tIconPath isDirectory:&isDirectory]==NO)
		{
			tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Missing icon file \"%@\".",@"WarningsAndErrors",bundle_,@""),tString];
									
			tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The icon defined for the application could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),tIconPath];
	
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
			BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
		else
		{
			if(isDirectory==YES)
			{
				// A COMPLETER
			}
			else
			{
				if ([BMIconsUtilities isIcnsFileAtPath:tIconPath]==NO)
				{
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"\"%@\" is not a valid .icns file.",@"WarningsAndErrors",bundle_,@""),tString];
					
					tDescription=NSLocalizedStringFromTableInBundle(@"The icon file for the application is not a valid .icns file.",@"WarningsAndErrors",bundle_,@"");
					
					tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
					BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
				}
				else
				{
					NSArray * tArray;
					BOOL has128representation=NO;
					BOOL has512representation=NO;
					BOOL has1024representation=NO;
					NSUInteger i,tCount;
					
					tArray=[BMIconsUtilities availableSizesForIcnsAtPath:tIconPath];
					
					tCount=[tArray count];
					
					for(i=0;i<tCount;i++)
					{
						NSUInteger tRepresentationSize;
						
						tRepresentationSize=[[tArray objectAtIndex:i] unsignedLongValue];
						
						if (tRepresentationSize==128)
						{
							has128representation=YES;
						}
						else if (tRepresentationSize==512)
						{
							has512representation=YES;
						}
						else if (tRepresentationSize==1024)
						{
							has1024representation=YES;
						}
					}
					
					if (has1024representation==NO && targetsMacAppStore==YES)
					{
						tTitle=NSLocalizedStringFromTableInBundle(@"Missing 1024x1024 representation for the application icon.",@"WarningsAndErrors",bundle_,@"");
					
						tDescription=NSLocalizedStringFromTableInBundle(@"A 1024x1024 representation of the application icon is required to submit an application to the Mac App Store.",@"WarningsAndErrors",bundle_,@"");
					
						tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,BM_PROBLEM_TAG_GENERIC_MAC_APP_STORE,nil];
					
						BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
					}
					
					if (has128representation==NO || has512representation==NO)
					{
						if (has128representation==NO && has512representation==NO)
						{
							tTitle=NSLocalizedStringFromTableInBundle(@"Missing 128x128 and 512x512 representations for the application icon.",@"WarningsAndErrors",bundle_,@"");
						}
						else
						{
							tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Missing %@ representation for the application icon",@"WarningsAndErrors",bundle_,@""),(has128representation==NO) ? @"128x128" : @"512x512"];
							
						}
						
						tDescription=@"";//NSLocalizedStringFromTableInBundle(@"The icon file for the application is not a valid .icns file.",@"WarningsAndErrors",bundle_,@"");
						
						tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,BM_PROBLEM_TAG_GENERIC_MAC_APP_STORE,nil];
						
						BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
					}
				}
				
			}
		}
	}
	
	// CFBundleIdentifier
	
	tString=[tInfoDictionary objectForKey:@"CFBundleIdentifier"];
	
	if (tString!=nil)
	{
		if ([tString hasPrefix:@"com.yourcompany."]==YES)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"Default com.yourcompany. prefix used for CFBundleIdentifier.",@"WarningsAndErrors",bundle_,@"");
									
			tDescription=@"";
	
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
			BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
	}
	
	// CFBundleGetInfoVersionString
	
	tString=[tInfoDictionary objectForKey:@"CFBundleGetInfoVersionString"];
	
	if (tString!=nil)
	{
		// Look for Copyright information
		
		if ([tString rangeOfString:@"copyright" options:NSCaseInsensitiveSearch].location!=NSNotFound)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"Copyright dates used within the value of the CFBundleGetInfoVersionString key.",@"WarningsAndErrors",bundle_,@"");
									
			tDescription=@"";NSLocalizedStringFromTableInBundle(@"A COMPLETER",@"WarningsAndErrors",bundle_,@"");;
	
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
			BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
	}
	
	/**** Cocoa Keys ****/
	
	// NSDockTilePlugIn
	
	tString=[tInfoDictionary objectForKey:@"NSDockTilePlugIn"];
	
	if (tString!=nil)
	{
		NSString * tDockTilePath;
		BOOL isDirectory;
		
		if ([[tString pathExtension] isEqualToString:@"docktileplugin"]==NO)
		{
			// A COMPLETER
		}
		
		tDockTilePath=[[itemPath_ stringByAppendingPathComponent:@"Contents/PlugIns"] stringByAppendingPathComponent:tString];
		
		// Check that the Dock tile plug-in is there
		
		if ([fileManager_ fileExistsAtPath:tDockTilePath isDirectory:&isDirectory]==NO)
		{
			tDockTilePath=[[itemPath_ stringByAppendingPathComponent:@"Contents/PlugIns"] stringByAppendingPathComponent:tString];
			
			if ([fileManager_ fileExistsAtPath:tDockTilePath isDirectory:&isDirectory]==NO)
			{
				tTitle=NSLocalizedStringFromTableInBundle(@"Dock Tile plug-in found in Contents/Resources.",@"WarningsAndErrors",bundle_,@"");
				
				tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Dock tile plug-ins must be placed inside the Contents/PlugIns directory of applications' package.",@"WarningsAndErrors",bundle_,@""),tDockTilePath];
				
				tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
				
				BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
			}
			else
			{
				tTitle=NSLocalizedStringFromTableInBundle(@"Missing Dock tile plug-in",@"WarningsAndErrors",bundle_,@"");
									
				tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The Dock tile plugin could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),tDockTilePath];
		
				tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
						
				BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
			}
		}
		else
		{
			if(isDirectory==NO)
			{
				// A COMPLETER
			}
		}
	}
	
	if (targetsMacAppStore==YES)
	{
		// NSHumanReadableCopyright must be set
		
		tString=[tInfoDictionary objectForKey:@"NSHumanReadableCopyright"];
		
		if ([tString length]==0)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"No value set for NSHumanReadableCopyright.",@"WarningsAndErrors",bundle_,@"");
				
			tDescription=NSLocalizedStringFromTableInBundle(@"The NSHumanReadableCopyright has to be set for Mac App Store apps.",@"WarningsAndErrors",bundle_,@"");
				
			tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,BM_PROBLEM_TAG_GENERIC_MAC_APP_STORE,nil];
				
			BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
	}
	
	// NSMainNibFile
	
	tString=[tInfoDictionary objectForKey:@"NSMainNibFile"];
	
	if (tString!=nil)
	{
		BOOL tNibFileFound=YES;
		NSString * tResourcesFolderPath;
		NSString * tNibFilePath;
		
		if ([[tString pathExtension] caseInsensitiveCompare:@"nib"]==NSOrderedSame)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"Incorrect value for the NSMainNibFile key",@"WarningsAndErrors",bundle_,@"");
			
			tDescription=NSLocalizedStringFromTableInBundle(@"The name of the application’s main nib file should not include the .nib extension.",@"WarningsAndErrors",bundle_,@"");
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
			
			BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
			
			tString=[tString stringByDeletingPathExtension];
		}
		
		tResourcesFolderPath=[itemPath_ stringByAppendingPathComponent:@"Contents/Resources"];
		
		tNibFilePath=[[tResourcesFolderPath stringByAppendingPathComponent:tString] stringByAppendingPathExtension:@"nib"];
		
		if ([fileManager_ fileExistsAtPath:tNibFilePath]==NO)
		{
			NSArray * tLocalizationFolderPathsArray;
			NSUInteger i,tCount;
			
			tNibFileFound=NO;
			
			tLocalizationFolderPathsArray=[BMFilesHierarchyUtilities allLocalizationFoldersAtPath:tResourcesFolderPath];
			
			tCount=[tLocalizationFolderPathsArray count];
			
			for(i=0;i<tCount;i++)
			{
				NSString * tLprojFolderPath;
				
				tLprojFolderPath=[tLocalizationFolderPathsArray objectAtIndex:i];
				
				tNibFilePath=[[tLprojFolderPath stringByAppendingPathComponent:tString] stringByAppendingPathExtension:@"nib"];
				
				if ([fileManager_ fileExistsAtPath:tNibFilePath]==YES)
				{
					tNibFileFound=YES;
					
					break;
				}
			}
		}
		
		if (tNibFileFound==NO)
		{
			// Missing Main Nib File
			
			tTitle=NSLocalizedStringFromTableInBundle(@"Missing main nib file",@"WarningsAndErrors",bundle_,@"");
			
			tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The \"%@\" nib file could not be found in the Resources folder.",@"WarningsAndErrors",bundle_,@""),tString];
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
			
			BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
	}
	
	// Sparkle
	
	if (targetsMacAppStore==NO)
	{
		tString=[tInfoDictionary objectForKey:@"SUFeedURL"];
	
		if (tString!=nil)
		{
			if ([tString length]==0)
			{
				tTitle=NSLocalizedStringFromTableInBundle(@"No value set for SUFeedURL.",@"WarningsAndErrors",bundle_,@"");
				
				tDescription=@"";//[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The Dock tile plugin could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),tDockTilePath];
				
				tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
						
				BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
			}
			else
			{
				NSURL * tURL;
				
				tURL=[NSURL URLWithString:tString];
				
				if (tURL!=nil)
				{
					NSString * tScheme;
					
					tScheme=[tURL scheme];
					
					if ([tScheme isEqualToString:@"http"]==YES)
					{
						// Check that the SUPublicDSAKeyFile key is set
						
						tString=[tInfoDictionary objectForKey:@"SUPublicDSAKeyFile"];
						
						if (tString==nil)
						{
							tTitle=NSLocalizedStringFromTableInBundle(@"The SUPublicDSAKeyFile key must be set.",@"WarningsAndErrors",bundle_,@"");
							
							tDescription=@"";//[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The Dock tile plugin could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),tDockTilePath];
							
							tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
						
							BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
						}
						else
						{
							// Check that the file exists
							
							NSString * tDSAPath;
							BOOL isDirectory;
							
							tDSAPath=[[itemPath_ stringByAppendingPathComponent:@"Contents/Resources"] stringByAppendingPathComponent:tString];
							
							// Check that the Dock tile plug-in is there
							
							if ([fileManager_ fileExistsAtPath:tDSAPath isDirectory:&isDirectory]==NO)
							{
								tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Missing public DSA key file \"%@\".",@"WarningsAndErrors",bundle_,@""),tString];
								
								tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The DSA public key file that should be used by Sparkle could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),tDSAPath];
								
								tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
						
								BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
							}
							else
							{
								if(isDirectory==NO)
								{
									// A COMPLETER
								}
							}
						}

					}
					
					if ([BMStringUtilities isIPaddress:[tURL host]]==YES)
					{
						tTitle=NSLocalizedStringFromTableInBundle(@"IPv4 address used for host. Use a host name instead.",@"WarningsAndErrors",bundle_,@"");
						
						//tDescription=@"";//[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The Dock tile plugin could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),tDockTilePath];
						
						tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
						
						BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,[tURL absoluteString],tTagsArray);
					}
				}
				else
				{
					// A COMPLETER
				}
			}
		}
		else
		{
			tString=[tInfoDictionary objectForKey:@"SUPublicDSAKeyFile"];
			
			if (tString!=nil)
			{
				tTitle=NSLocalizedStringFromTableInBundle(@"SUPublicDSAKeyFile key used with no SUFeedURL value defined",@"WarningsAndErrors",bundle_,@"");
				
				tDescription=@"";//[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The Dock tile plugin could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),tDockTilePath];
				
				tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
						
				BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
			}
		}
	}
	else 
	{
		NSArray * tArray;
		NSString * tKey;
		
		tArray=[NSArray arrayWithObjects:@"SUFeedURL",
										 @"SUEnableAutomaticChecks",
										 @"SUEnableSystemProfiling",
										 @"SUShowReleaseNotes",
										 @"SUPublicDSAKeyFile",
										 @"SUScheduledCheckInterval",
										 @"SUAllowsAutomaticUpdates",
										 nil];
		
		for(tKey in tArray)
		{
			id tObject;
			
			tObject=[tInfoDictionary objectForKey:tKey];
			
			if (tObject!=nil)
			{
				tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Sparkle's %@ key used.",@"WarningsAndErrors",bundle_,@""),tKey];
				
				tDescription=NSLocalizedStringFromTableInBundle(@"The use of 3rd party update mechanism is not allowed for Mac App Store apps.",@"WarningsAndErrors",bundle_,@"");
				
				tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,BM_PROBLEM_TAG_GENERIC_MAC_APP_STORE,nil];
				
				BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
			}
		}
	}
}

- (void) testiOSAppBundle
{
	BMPropertyListFileChecker * tPropertyListFileChecker;
	NSDictionary * tInfoDictionary;
	NSArray * tArray;
	NSDictionary * tDictionary;
	NSString * tString;
	NSString * tTitle;
	NSString * tDescription;
	NSArray * tTagsArray;
	id tObject;
	
	NSString * tInfoPlistPath;
	
	tInfoPlistPath=[itemPath_ stringByAppendingPathComponent:@"/Info.plist"];
	
	// Check the consistency of data
	
	tPropertyListFileChecker=[self propertyListCheckForType:BM_BUNDLETYPE_IOS_APP_BUNDLE withCheckList:@"iOSApp_InfoPlist_CheckList"];
	
	if (tPropertyListFileChecker!=nil)
	{
		if ([tPropertyListFileChecker checkPropertyListFileAtPath:tInfoPlistPath withDelegate:delegate supportDeviceSpecificKey:YES]==NO)
		{
			/*if ([tPropertyListFileChecker problemLevel]==BM_PROBLEM_LEVEL_CRITICAL)
			 {
			 return;
			 }*/
		}
	}
	
	tInfoDictionary=[NSDictionary dictionaryWithContentsOfFile:tInfoPlistPath];
	
	// A COMPLETER
	
	// CFBundleIdentifier
	
	tString=[tInfoDictionary objectForKey:@"CFBundleIdentifier"];
	
	if (tString!=nil)
	{
		if ([tString hasPrefix:@"com.yourcompany."]==YES)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"Default com.yourcompany. prefix used for CFBundleIdentifier.",@"WarningsAndErrors",bundle_,@"");
			
			tDescription=@"";
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
			
			BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
	}
	
	/*** Cocoa Keys ***/
	
	// NSMainNibFile
	
	tString=[tInfoDictionary objectForKey:@"NSMainNibFile"];
	
	if (tString!=nil)
	{
		if ([tString length]==0)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"No value set for NSMainNibFile.",@"WarningsAndErrors",bundle_,@"");
			
			tDescription=@"";
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
			
			BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
		else
		{
			BOOL tNibFileFound=YES;
			NSString * tResourcesFolderPath;
			NSString * tNibFilePath;
			
			if ([[tString pathExtension] caseInsensitiveCompare:@"nib"]==NSOrderedSame)
			{
				tTitle=NSLocalizedStringFromTableInBundle(@"Incorrect value for the NSMainNibFile key",@"WarningsAndErrors",bundle_,@"");
				
				tDescription=NSLocalizedStringFromTableInBundle(@"The name of the application’s main nib file should not include the .nib extension.",@"WarningsAndErrors",bundle_,@"");
				
				tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
				
				BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
				
				tString=[tString stringByDeletingPathExtension];
			}
			
			tResourcesFolderPath=itemPath_;
			
			tNibFilePath=[[tResourcesFolderPath stringByAppendingPathComponent:tString] stringByAppendingPathExtension:@"nib"];
			
			if ([fileManager_ fileExistsAtPath:tNibFilePath]==NO)
			{
				NSArray * tLocalizationFolderPathsArray;
				NSUInteger i,tCount;
				
				tNibFileFound=NO;
				
				tLocalizationFolderPathsArray=[BMFilesHierarchyUtilities allLocalizationFoldersAtPath:tResourcesFolderPath];
				
				tCount=[tLocalizationFolderPathsArray count];
				
				for(i=0;i<tCount;i++)
				{
					NSString * tLprojFolderPath;
					
					tLprojFolderPath=[tLocalizationFolderPathsArray objectAtIndex:i];
					
					tNibFilePath=[[tLprojFolderPath stringByAppendingPathComponent:tString] stringByAppendingPathExtension:@"nib"];
					
					if ([fileManager_ fileExistsAtPath:tNibFilePath]==YES)
					{
						tNibFileFound=YES;
						
						break;
					}
				}
			}
			
			if (tNibFileFound==NO)
			{
				// Missing Main Nib File
				
				tTitle=NSLocalizedStringFromTableInBundle(@"Missing main nib file",@"WarningsAndErrors",bundle_,@"");
				
				tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The \"%@\" nib file could not be found in the Resources folder.",@"WarningsAndErrors",bundle_,@""),tString];
				
				tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
				
				BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
			}
		}
	}
	
	/*** UIKit Keys ***/
	
	// UIDeviceFamily
	
	tObject=[tInfoDictionary objectForKey:@"UIDeviceFamily"];
	
	if (tObject!=nil)
	{
		if ([tObject isKindOfClass:[NSArray class]]==YES)
		{
			// A COMPLETER
		}
		else if ([tObject isKindOfClass:[NSNumber class]]==YES)
		{
			// A COMPLETER
		}
		else
		{
			tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Invalid object type for key \"%@\"",@"CommonPropertyList",@""),@"UIDeviceFamily"];
			
			tDescription=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Object is a %@ but should be either a %@ or a %@",@"CommonPropertyList",@""),NSStringFromClass([tObject class]),@"NSNumber",@"NSArray"];
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
			
			BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}

	}
	
	// UIRequiredDeviceCapabilities
	
	tObject=[tInfoDictionary objectForKey:@"UIRequiredDeviceCapabilities"];
	
	if (tObject!=nil)
	{
		static NSArray * sRequiredDeviceCapabilities=nil;
		
		if (sRequiredDeviceCapabilities==nil)
		{
			sRequiredDeviceCapabilities=[[NSArray alloc] initWithObjects:@"telephony",
																		 @"wifi",
																		 @"sms",
																		 @"still-camera",
																		 @"auto-focus-camera",
																		 @"front-facing-camera",
																		 @"camera-flash",
																		 @"video-camera",
																		 @"accelerometer",
																		 @"gyroscope",
																		 @"location-services",
																		 @"gps",
																		 @"magnetometer",
																		 @"gamekit",
																		 @"microphone",
																		 @"opengles-1",
																		 @"opengles-2",
																		 @"armv6",
																		 @"armv7",
																		 @"peer-peer",
																		 nil];
		}
		
		if ([tObject isKindOfClass:[NSArray class]]==YES)
		{
			Class tStringClass;
			
			tStringClass=[NSString class];
			
			tArray=(NSArray *) tObject;
			
			for (id tChild in tArray)
			{
				if ([tChild isKindOfClass:tStringClass]==NO)
				{
					tTitle=NSLocalizedStringFromTableInBundle(@"Invalid object type for capability",@"WarningsAndErrors",bundle_,@"");
					
					tDescription=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Object is a %@ but should be a %@",@"CommonPropertyList",@""),NSStringFromClass([tChild class]),@"NSString"];
					
					tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
					BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
				}
				else if ([sRequiredDeviceCapabilities containsObject:tChild]==NO)
				{
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Unknown device capability \"%@\"",@"WarningsAndErrors",bundle_,@""),tChild];
					
					tDescription=@"";
					
					tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
					BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
				}
			}
		}
		else if ([tObject isKindOfClass:[NSDictionary class]]==YES)
		{
			Class tNumberClass;
			
			tNumberClass=[NSString class];
			
			tDictionary=(NSDictionary *) tObject;
			
			for (NSString * tKey in tDictionary)
			{
				if ([sRequiredDeviceCapabilities containsObject:tKey]==NO)
				{
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Unknown device capability \"%@\"",@"WarningsAndErrors",bundle_,@""),tKey];
					
					tDescription=@"";
					
					tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
					BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
				}
				else if ([[tDictionary objectForKey:tKey] isKindOfClass:tNumberClass]==NO)
				{
					// A COMPLETER
				}
			}
		}
		else
		{
			tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Invalid object type for key \"%@\"",@"CommonPropertyList",@""),@"UIRequiredDeviceCapabilities"];
			
			tDescription=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Object is a %@ but should be either a %@ or a %@",@"CommonPropertyList",@""),NSStringFromClass([tObject class]),@"NSDictionary",@"NSArray"];
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
			
			BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
	}
}

- (void) testFrameworkBundleVersion:(NSString *) inPath
{
	BMPropertyListFileChecker * tPropertyListFileChecker;
	NSDictionary * tInfoDictionary;
	NSString * tString;
	NSString * tTitle;
	NSString * tDescription;
	NSString * tFrameworkFolderName;
	NSArray * tTagsArray;
	
	// Check the consistency of data
	
	tPropertyListFileChecker=[self propertyListCheckForType:BM_BUNDLETYPE_FRAMEWORK withCheckList:@"Framework_InfoPlist_CheckList"];
	
	if (tPropertyListFileChecker!=nil)
	{
		if ([tPropertyListFileChecker checkPropertyListFileAtPath:inPath withDelegate:delegate]==NO)
		{
			/*if ([tPropertyListFileChecker problemLevel]==BM_PROBLEM_LEVEL_CRITICAL)
			{
				return;
			}*/
		}
	}
	
	tInfoDictionary=[NSDictionary dictionaryWithContentsOfFile:[itemPath_ stringByAppendingPathComponent:@"Resources/Info.plist"]];
	
	tFrameworkFolderName=[[itemPath_ lastPathComponent] stringByDeletingPathExtension];
	
	if ([tFrameworkFolderName rangeOfString:@"framework" options:NSCaseInsensitiveSearch].location!=NSNotFound)
	{
		tTitle=NSLocalizedStringFromTableInBundle(@"Strange name for a framework.",@"WarningsAndErrors",bundle_,@"");
							
		tDescription=NSLocalizedStringFromTableInBundle(@"It is not really useful to include the word \"framework\" in the name of a framework. The .framework extension is clear enough.",@"WarningsAndErrors",bundle_,@"");
		
		tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
		BM_REPORT_WARNING_TAGS(delegate,itemPath_,tTitle,tDescription,tTagsArray);
	}
	
	// CFBundleIdentifier
	
	tString=[tInfoDictionary objectForKey:@"CFBundleIdentifier"];
	
	if (tString!=nil)
	{
		if ([tString hasPrefix:@"com.yourcompany."]==YES)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"Default com.yourcompany. prefix used for CFBundleIdentifier.",@"WarningsAndErrors",bundle_,@"");
			
			tDescription=@"";
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
			
			BM_REPORT_WARNING_TAGS(delegate,inPath,tTitle,tDescription,tTagsArray);
		}
	}
	
	// CFBundleExecutable
	
	tString=[tInfoDictionary objectForKey:@"CFBundleExecutable"];
	
	if (tString!=nil)
	{
		// CFBundleExecutable should be the same as the name of the .framework bundle
		
		if ([tString isEqualToString:tFrameworkFolderName]==NO)
		{
			tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Incorrect object value for key \"%@\".",@"CommonPropertyList",@""),@"CFBundleExecutable"];
							
			tDescription=NSLocalizedStringFromTableInBundle(@"The value for the CFBundleExecutable key should match the name of the framework folder minus the .framework extension",@"WarningsAndErrors",bundle_,@"");;
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
			BM_REPORT_ERROR_TAGS(delegate,itemPath_,tTitle,tDescription,tTagsArray);
		}
	}
}

- (void) testFrameworkBundle
{
	NSString * tVersionsPath;
	BOOL isDirectory;
	
	tVersionsPath=[itemPath_ stringByAppendingPathComponent:@"Versions"];
	
	if ([fileManager_ fileExistsAtPath:tVersionsPath isDirectory:&isDirectory]==YES && isDirectory==YES)
	{
		NSArray * tArray;
		
		tArray=[fileManager_ contentsOfDirectoryAtPath:tVersionsPath error:NULL];
		
		for(NSString * tFileName in tArray)
        {
			NSString * tAbsolutePath;
			NSDictionary * tAttributesDictionary;
			
			tAbsolutePath=[tVersionsPath stringByAppendingPathComponent:tFileName];
			
			tAttributesDictionary=[fileManager_ attributesOfItemAtPath:tAbsolutePath error:NULL];
			
			if ([[tAttributesDictionary fileType] isEqualToString:NSFileTypeDirectory]==YES)
			{
				// We don't want to inspect the current version twice
				
				NSString * tInfoPlistPath;
				
				tInfoPlistPath=[tAbsolutePath stringByAppendingPathComponent:@"Resources/Info.plist"];
				
				if ([fileManager_ fileExistsAtPath:tInfoPlistPath]==YES)
				{
					[self testFrameworkBundleVersion:tInfoPlistPath];
				}
				else
				{
					NSString * tTitle;
					NSString * tDescription=nil;
					NSArray * tTagsArray;
					
					tTitle=NSLocalizedStringFromTable(@"File not found",@"Common",@"");
							
					//tDescription=NSLocalizedStringFromTableInBundle(@"If no localizations are to be defined, consider removing this file.",@"WarningsAndErrors",bundle_,@"");
					
					tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
					BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
				}
			}
		}
	}
}

- (void) testPluginBundle
{
	BMPropertyListFileChecker * tPropertyListFileChecker;
	NSString * tInfoPlistPath;
	
	tInfoPlistPath=[itemPath_ stringByAppendingPathComponent:@"/Contents/Info.plist"];
	
	// Check the consistency of data
	
	tPropertyListFileChecker=[self propertyListCheckForType:BM_BUNDLETYPE_PLUGIN withCheckList:@"Plugin_InfoPlist_CheckList"];
	
	if (tPropertyListFileChecker!=nil)
	{
		if ([tPropertyListFileChecker checkPropertyListFileAtPath:tInfoPlistPath withDelegate:delegate]==NO)
		{
			/*if ([tPropertyListFileChecker problemLevel]==BM_PROBLEM_LEVEL_CRITICAL)
			{
				return;
			}*/
		}
	}
}

- (void) testPrefPaneBundle
{
	BMPropertyListFileChecker * tPropertyListFileChecker;
	BMStringsFileChecker *tStringsFileChecker;
	NSDictionary * tInfoDictionary;
	NSString * tString;
	NSString * tTitle;
	NSString * tDescription;
	NSArray * tLocalizationFolderPathsArray;
	NSString * tInfoPlistPath;
	NSArray * tTagsArray;
	
	tInfoPlistPath=[itemPath_ stringByAppendingPathComponent:@"/Contents/Info.plist"];
	
	// Check the consistency of data
	
	tPropertyListFileChecker=[self propertyListCheckForType:BM_BUNDLETYPE_PREFERENCES_PANE withCheckList:@"PrefPane_InfoPlist_CheckList"];
	
	if (tPropertyListFileChecker!=nil)
	{
		if ([tPropertyListFileChecker checkPropertyListFileAtPath:tInfoPlistPath withDelegate:delegate]==NO)
		{
			/*if ([tPropertyListFileChecker problemLevel]==BM_PROBLEM_LEVEL_CRITICAL)
			{
				return;
			}*/
		}
	}
	
	tInfoDictionary=[NSDictionary dictionaryWithContentsOfFile:tInfoPlistPath];
	
	tLocalizationFolderPathsArray=[BMFilesHierarchyUtilities allLocalizationFoldersAtPath:[itemPath_ stringByAppendingPathComponent:@"Contents/Resources"]];
	
	// Check for Empty InfoPlist.strings file
	
	tStringsFileChecker=[BMStringsFileChecker stringsFileChecker];
	
	if (tStringsFileChecker!=nil)
	{
		NSUInteger i,tCount;
		
		tCount=[tLocalizationFolderPathsArray count];
		
		for(i=0;i<tCount;i++)
		{
			NSString * tLprojFolderPath;
			NSString * tInfoPListStringsPath;
			BOOL isDirectory;
			
			tLprojFolderPath=[tLocalizationFolderPathsArray objectAtIndex:i];
			
			tInfoPListStringsPath=[tLprojFolderPath stringByAppendingPathComponent:@"InfoPlist.strings"];
			
			if ([fileManager_ fileExistsAtPath:tInfoPListStringsPath isDirectory:&isDirectory]==YES)
			{
				if (isDirectory==YES)
				{
					// A COMPLETER
				}
				else
				{
					if ([tStringsFileChecker checkStringsFileAtPath:tInfoPListStringsPath withDelegate:delegate]==YES)
					{
						NSDictionary * tLocalizedInfoDictionary;
						
						tLocalizedInfoDictionary=[NSDictionary dictionaryWithContentsOfFile:tInfoPListStringsPath];
						
						if ([tLocalizedInfoDictionary count]==0)
						{
							// No localizations provided
						
							tTitle=NSLocalizedStringFromTableInBundle(@"No localizations defined in file",@"WarningsAndErrors",bundle_,@"");
							
							tDescription=NSLocalizedStringFromTableInBundle(@"If no localizations are to be defined, consider removing this file.",@"WarningsAndErrors",bundle_,@"");
							
							tTagsArray=[NSArray arrayWithObjects:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST,BM_PROBLEM_TAG_GENERIC_STRINGS,nil];
					
							BM_REPORT_WARNING_TAGS(delegate,tInfoPListStringsPath,tTitle,tDescription,tTagsArray);
						}
					}
				}
			}
		}
	}
	else
	{
		
	}
	
	// CFBundleIdentifier
	
	tString=[tInfoDictionary objectForKey:@"CFBundleIdentifier"];
	
	if (tString!=nil)
	{
		if ([tString hasPrefix:@"com.yourcompany."]==YES)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"Default com.yourcompany. prefix used for CFBundleIdentifier.",@"WarningsAndErrors",bundle_,@"");
			
			tDescription=@"";
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
			
			BM_REPORT_WARNING_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
	}
	
	// CFBundleShortVersionString
	
	tString=[tInfoDictionary objectForKey:@"CFBundleShortVersionString"];
	
	if ([tString length]>0)
	{
		NSString * tBundleVersionString;
		
		tBundleVersionString=[tInfoDictionary objectForKey:@"CFBundleVersion"];
		
		if ([tBundleVersionString isEqualToString:tString]==YES)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"Values of CFBundleVersion and CFBundleShortVersionString are identical",@"WarningsAndErrors",bundle_,@"");
			
			//tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The icon defined for the document type \"%@\" could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),[tDocumentDictionary objectForKey:@"CFBundleTypeName"],tIconPath];
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
			
			BM_REPORT_NOTE_TAGS(delegate,tInfoPlistPath,tTitle,nil,tTagsArray);
		}
	}
	
	// NSPrincipalClass
	
	tString=[tInfoDictionary objectForKey:@"NSPrincipalClass"];
	
	if (tString!=nil)
	{
		if ([tString length]==0)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"No value set for NSPrincipalClass.",@"WarningsAndErrors",bundle_,@"");
			
			tDescription=@"";
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
			
			BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
	}
	
	// NSMainNibFile
	
	tString=[tInfoDictionary objectForKey:@"NSMainNibFile"];
	
	if (tString!=nil)
	{
		if ([tString length]==0)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"No value set for NSMainNibFile.",@"WarningsAndErrors",bundle_,@"");
			
			tDescription=@"";
			
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
			
			BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
		else
		{
			BOOL tNibFileFound=YES;
			NSString * tResourcesFolderPath;
			NSString * tNibFilePath;
			
			tResourcesFolderPath=[itemPath_ stringByAppendingPathComponent:@"Contents/Resources"];
			
			tNibFilePath=[[tResourcesFolderPath stringByAppendingPathComponent:tString] stringByAppendingPathExtension:@"nib"];
			
			if ([fileManager_ fileExistsAtPath:tNibFilePath]==NO)
			{
				NSArray * tLocalizationFolderPathsArray;
				NSUInteger i,tCount;
				
				tNibFileFound=NO;
				
				tLocalizationFolderPathsArray=[BMFilesHierarchyUtilities allLocalizationFoldersAtPath:tResourcesFolderPath];
				
				tCount=[tLocalizationFolderPathsArray count];
				
				for(i=0;i<tCount;i++)
				{
					NSString * tLprojFolderPath;
					
					tLprojFolderPath=[tLocalizationFolderPathsArray objectAtIndex:i];
					
					tNibFilePath=[[tLprojFolderPath stringByAppendingPathComponent:tString] stringByAppendingPathExtension:@"nib"];
					
					if ([fileManager_ fileExistsAtPath:tNibFilePath]==YES)
					{
						tNibFileFound=YES;
						
						break;
					}
				}
			}
			
			if (tNibFileFound==NO)
			{
				// Missing Main Nib File
				
				tTitle=NSLocalizedStringFromTableInBundle(@"Missing main nib file",@"WarningsAndErrors",bundle_,@"");
				
				tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The \"%@\" nib file could not be found in the Resources folder.",@"WarningsAndErrors",bundle_,@""),tString];
				
				tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
				
				BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
			}
		}
	}

	
	// NSPrefPaneIconFile
	
	tString=[tInfoDictionary objectForKey:@"NSPrefPaneIconFile"];
	
	if (tString!=nil)
	{
		// Check that the file exists
		
		NSString * tIconPath;
		BOOL isDirectory;
		
		tIconPath=[[itemPath_ stringByAppendingPathComponent:@"Contents/Resources"] stringByAppendingPathComponent:tString];
		
		// Check that the Dock tile plug-in is there
		
		if ([fileManager_ fileExistsAtPath:tIconPath isDirectory:&isDirectory]==NO)
		{
			tTitle=NSLocalizedStringFromTableInBundle(@"Missing icon file",@"WarningsAndErrors",bundle_,@"");
									
			tDescription=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The icon defined for the preference pane could not be found at path \"%@\".",@"WarningsAndErrors",bundle_,@""),tIconPath];
	
			tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
			BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
		}
		else
		{
			if(isDirectory==NO)
			{
				// A COMPLETER
			}
		}
	}
	
	// NSPrefPaneSearchParameters
	
	tString=[tInfoDictionary objectForKey:@"NSPrefPaneSearchParameters"];
	
	if (tString!=nil)
	{
		NSString * tSearchTermsPath;
		NSString * tFileName;
		BOOL isDirectory;
		
		tFileName=[tString stringByAppendingPathExtension:@"searchTerms"];
		
		tSearchTermsPath=[[itemPath_ stringByAppendingPathComponent:@"Contents/Resources"] stringByAppendingPathComponent:tFileName];
		
		if ([fileManager_ fileExistsAtPath:tSearchTermsPath isDirectory:&isDirectory]==NO || isDirectory==YES)
		{
			NSUInteger i,tCount;
		
			tCount=[tLocalizationFolderPathsArray count];
			
			for(i=0;i<tCount;i++)
			{
				NSString * tLprojFolderPath;
				
				tLprojFolderPath=[tLocalizationFolderPathsArray objectAtIndex:i];
				
				tSearchTermsPath=[tLprojFolderPath stringByAppendingPathComponent:tFileName];
				
				if ([fileManager_ fileExistsAtPath:tSearchTermsPath isDirectory:&isDirectory]==YES)
				{
					if (isDirectory==YES)
					{
						// A COMPLETER
					}
					else
					{
						break;
					}
				}
			}
			
			if (i==tCount)
			{
				// No localizations provided
						
				tTitle=[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"File not found (%@)",@"WarningsAndErrors",bundle_,@""),tFileName];
				
				tDescription=@"";
				
				tTagsArray=[NSArray arrayWithObject:BM_PROBLEM_TAG_GENERIC_PROPERTYLIST];
					
				BM_REPORT_ERROR_TAGS(delegate,tInfoPlistPath,tTitle,tDescription,tTagsArray);
			}
		}
		else
		{
			// A COMPLETER
		}
	}
}

#pragma mark -

- (void) testItem:(id) inItem atPath:(NSString *) inPath ofType:(NSUInteger) inType withDelegate:(id) inDelegate
{
	[super testItem:inItem atPath:inPath ofType:inType withDelegate:inDelegate];
			
	itemPath_=[inPath retain];
			
	switch(inType)
	{
		case BM_BUNDLETYPE_APP_BUNDLE:
		
			[self testAppBundle];
			
			break;
		
		case BM_BUNDLETYPE_FRAMEWORK:
		
			// A COMPLETER
			
			[self testFrameworkBundle];
		
			break;
			
		case BM_BUNDLETYPE_BUNDLE:
		
			// A COMPLETER
		
			break;
		
		case BM_BUNDLETYPE_PLUGIN:
			
			[self testPluginBundle];
			
			break;
			
		case BM_BUNDLETYPE_AUTOMATOR_ACTION:
		
			// A COMPLETER
		
			break;
			
		case BM_BUNDLETYPE_SPOTLIGHT_IMPORTER:
		
			// A COMPLETER
		
			break;
			
		case BM_BUNDLETYPE_PREFERENCES_PANE:
			
			[self testPrefPaneBundle];
		
			break;
			
		case BM_BUNDLETYPE_IOS_APP_BUNDLE:
			
			[self testiOSAppBundle];
			
			break;
	}
}

@end
