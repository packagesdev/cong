#import "BMCommandLineProcessor.h"

#import "BMReportingUtilities.h"

#import "BMBundleUtilities.h"

@implementation BMCommandLineProcessor

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[reportDictionary_ release];
	
	[pluginManager_ release];
	
	[super dealloc];
}

#pragma mark -

- (void) testItemAtPath:(NSString *) inPath ofType:(NSUInteger) inType
{
	// First check the integrity of the bundle structure
	
	if ([BMBundleUtilities checkStructureOfBundleAtPath:inPath withDelegate:self]==YES)
	{
		NSBundle * tBundle;
		NSString * tPath;
		NSArray * tArray;
		BOOL isDirectory;
		
		tBundle=[NSBundle bundleWithPath:inPath];
		
		[pluginManager_ testItem:tBundle atPath:inPath ofType:inType withDelegate:self];
		
		if (inType==BM_BUNDLETYPE_APP_BUNDLE)
		{
			// Login Items (10.6.6 and later)
			
			tPath=[inPath stringByAppendingPathComponent:@"Contents/Library/LoginItems"];
			
			if ([fileManager_ fileExistsAtPath:tPath isDirectory:&isDirectory]==YES && isDirectory==YES)
			{
				tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
				
				for(NSString * tFilePath in tArray)
				{
					if ([[tFilePath pathExtension] caseInsensitiveCompare:@"app"]==NSOrderedSame)
					{
						[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
									  ofType:BM_BUNDLETYPE_APP_BUNDLE];
					}
				}
			}
			
			// Automator Actions
			
			tPath=[inPath stringByAppendingPathComponent:@"Contents/Library/Automator"];
			
            if ([fileManager_ fileExistsAtPath:tPath isDirectory:&isDirectory]==YES && isDirectory==YES)
            {
                tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];

                for(NSString * tFilePath in tArray)
                {
                    if ([[tFilePath pathExtension] caseInsensitiveCompare:@"action"]==NSOrderedSame)
                    {
                        [self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath]
                                      ofType:BM_BUNDLETYPE_AUTOMATOR_ACTION];
                    }
                }
            }
			
			// Spotlight
			
			tPath=[inPath stringByAppendingPathComponent:@"Contents/Library/Spotlight"];
			
			if ([fileManager_ fileExistsAtPath:tPath isDirectory:&isDirectory]==YES && isDirectory==YES)
			{
				tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
				
				for(NSString * tFilePath in tArray)
                {
					
					if ([[tFilePath pathExtension] caseInsensitiveCompare:@"mdimporter"]==NSOrderedSame)
					{
						[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
									  ofType:BM_BUNDLETYPE_SPOTLIGHT_IMPORTER];
					}
				}
			}
			
			// PrivateFrameworks
			
			tPath=[inPath stringByAppendingPathComponent:@"Contents/PrivateFrameworks"];
			
			if ([fileManager_ fileExistsAtPath:tPath isDirectory:&isDirectory]==YES && isDirectory==YES)
			{
				tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
				
				for(NSString * tFilePath in tArray)
                {
					
					if ([[tFilePath pathExtension] caseInsensitiveCompare:@"framework"]==NSOrderedSame)
					{
						[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
									  ofType:BM_BUNDLETYPE_FRAMEWORK];
					}
				}
			}
		}
		
		if (inType!=BM_BUNDLETYPE_FRAMEWORK)
		{
			// Plugins
			
			tPath=[tBundle builtInPlugInsPath];
			
			if (tPath!=nil)
			{
				tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
				
				for(NSString * tFilePath in tArray)
                {
					
					if ([[tFilePath pathExtension] caseInsensitiveCompare:@"bundle"]==NSOrderedSame)
					{
						[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
									  ofType:BM_BUNDLETYPE_BUNDLE];
					}
					else if ([[tFilePath pathExtension] caseInsensitiveCompare:@"plugin"]==NSOrderedSame)
					{
						[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
									  ofType:BM_BUNDLETYPE_PLUGIN];
					}
					
				}
			}
			
			// Frameworks
			
			tPath=[tBundle privateFrameworksPath];
			
			if (tPath!=nil)
			{
				tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
				
				for(NSString * tFilePath in tArray)
                {
					
					if ([[tFilePath pathExtension] caseInsensitiveCompare:@"framework"]==NSOrderedSame)
					{
						[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath] 
									  ofType:BM_BUNDLETYPE_FRAMEWORK];
					}
				}
			}
		}
		
		// Apps in Resources
		
		tPath=[tBundle resourcePath];
		
		if (tPath!=nil)
		{
			tArray=[fileManager_ contentsOfDirectoryAtPath:tPath error:NULL];
			
			for(NSString * tFilePath in tArray)
            {
				
				if ([[tFilePath pathExtension] caseInsensitiveCompare:@"app"]==NSOrderedSame)
				{
					[self testItemAtPath:[tPath stringByAppendingPathComponent:tFilePath]
								  ofType:BM_BUNDLETYPE_APP_BUNDLE];
				}
			}
		}
	}
}

- (int) processBundleAtPath:(NSString *) inPath printDescription:(BOOL) inPrintDescription
{
	NSUInteger tBundleType;
	NSUInteger tCount;
	fileManager_=[NSFileManager defaultManager];
	
	pluginManager_=[BMQualityPluginManager new];
	
	reportDictionary_=[[NSMutableDictionary alloc] initWithCapacity:10];
	
	printDescription_=inPrintDescription;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveExternalReport:) name:BM_NOTIFICATION_DID_REPORT_PROBLEM object:self];
	
	
	
	tBundleType=[BMBundleUtilities bundleTypeAtPath:inPath];
	
	[self testItemAtPath:inPath ofType:tBundleType];
	
	// Print the output
	
	tCount=[reportDictionary_ count];
	
	if (tCount>0)
	{
		NSMutableArray * tAllKeys;
		
		tAllKeys=[[reportDictionary_ allKeys] mutableCopy];
		
		[tAllKeys sortUsingSelector:@selector(caseInsensitiveCompare:)];
		
		if (tAllKeys!=nil)
		{
			NSUInteger i;
			
			for(i=0;i<tCount;i++)
			{
				NSString * tFilePath;
				NSDictionary * tLevelsDictionary;
				
				
				tFilePath=[tAllKeys objectAtIndex:i];
				
				tLevelsDictionary=[reportDictionary_ objectForKey:tFilePath];
				
				if (tLevelsDictionary!=nil)
				{
					NSArray * tReportsArray;
					NSUInteger tReportsCount;
					NSDictionary * tReportDictionary;
					NSString * tTitle;
					NSString * tDescription;
					
					// Errors
					
					tReportsArray=[tLevelsDictionary objectForKey:[NSNumber numberWithUnsignedInteger:BM_PROBLEM_LEVEL_ERROR]];
					
					tReportsCount=[tReportsArray count];
					
					if (tReportsCount>0)
					{
						NSUInteger j;
						
						//(void)fprintf(stdout, "Errors(%lu)\n",(unsigned long) tReportsCount);
					
						for(j=0;j<tReportsCount;j++)
						{
							NSMutableString * tReportLineStart;
							
							tReportLineStart=[NSMutableString new];
							
							if (tReportLineStart!=nil)
							{
								NSDictionary * tExtrasDictionary;
								id tExtraData;
								
								[tReportLineStart appendString:tFilePath];
								
								tReportDictionary=[tReportsArray objectAtIndex:j];
								
								tExtrasDictionary=[tReportDictionary objectForKey:BM_PROBLEM_EXTRAS];
								
								tExtraData=[tExtrasDictionary objectForKey:BM_PROBLEM_EXTRA_LINE_NUMBER];
								
								if (tExtraData != nil)
									[tReportLineStart appendFormat:@":%u", [tExtraData unsignedIntValue]];
                                else
                                    [tReportLineStart appendString:@":1"];
								
								[tReportLineStart appendString:@": error:"];
								
								(void)fprintf(stdout, "%s",[tReportLineStart UTF8String]);
								
								tTitle=[tReportDictionary objectForKey:BM_PROBLEM_TITLE];
								
								if (tTitle!=nil)
								{
									(void)fprintf(stdout, " %s\n",[tTitle UTF8String]);
								}
								
								/*tExtraData=[tExtrasDictionary objectForKey:BM_PROBLEM_EXTRA_KEY];
								
								if (tExtraData!=nil)
								{
									(void)fprintf(stdout, "\"%s\"\n",[(NSString *) tExtraData UTF8String]);
								}*/
								
								/*if (printDescription_==YES)*/
								{
									tDescription=[tReportDictionary objectForKey:BM_PROBLEM_DESCRIPTION];
									
									if (tDescription!=nil)
									{
										(void)fprintf(stdout, "%s",[tReportLineStart UTF8String]);
										
										(void)fprintf(stdout, " %s\n",[tDescription UTF8String]);
									}
								}
								
								[tReportLineStart release];
							}
						}
					}
					
					// Warnings
					
					tReportsArray=[tLevelsDictionary objectForKey:[NSNumber numberWithUnsignedInteger:BM_PROBLEM_LEVEL_WARNING]];
					
					tReportsCount=[tReportsArray count];
					
					if (tReportsCount>0)
					{
						NSUInteger j;
						
						//(void)fprintf(stdout, "Warnings(%lu)\n",(unsigned long) tReportsCount);
						
						for(j=0;j<tReportsCount;j++)
						{
							NSMutableString * tReportLineStart;
							
							tReportLineStart=[NSMutableString new];
							
							if (tReportLineStart!=nil)
							{
								NSDictionary * tExtrasDictionary;
								id tExtraData;
								
								[tReportLineStart appendString:tFilePath];
								
								tReportDictionary=[tReportsArray objectAtIndex:j];
								
								tExtrasDictionary=[tReportDictionary objectForKey:BM_PROBLEM_EXTRAS];
								
								tExtraData=[tExtrasDictionary objectForKey:BM_PROBLEM_EXTRA_LINE_NUMBER];

                                if (tExtraData != nil)
									[tReportLineStart appendFormat:@":%u", [tExtraData unsignedIntValue]];
                                else
                                    [tReportLineStart appendString:@":1"];
								
								[tReportLineStart appendString:@": warning:"];
								
								(void)fprintf(stdout, "%s",[tReportLineStart UTF8String]);
								
								tTitle=[tReportDictionary objectForKey:BM_PROBLEM_TITLE];
								
								if (tTitle!=nil)
								{
									(void)fprintf(stdout, " %s\n",[tTitle UTF8String]);
								}
								
								/*tExtraData=[tExtrasDictionary objectForKey:BM_PROBLEM_EXTRA_KEY];
								 
								 if (tExtraData!=nil)
								 {
								 (void)fprintf(stdout, "\"%s\"\n",[(NSString *) tExtraData UTF8String]);
								 }*/
								
								/*if (printDescription_==YES)*/
								{
									tDescription=[tReportDictionary objectForKey:BM_PROBLEM_DESCRIPTION];
									
									if (tDescription!=nil)
									{
										(void)fprintf(stdout, "%s",[tReportLineStart UTF8String]);
										
										(void)fprintf(stdout, " %s\n",[tDescription UTF8String]);
									}
								}
								
								[tReportLineStart release];
							}
						}
					}
					
					// Notes
					
					tReportsArray=[tLevelsDictionary objectForKey:[NSNumber numberWithUnsignedInteger:BM_PROBLEM_LEVEL_NOTE]];
					
					tReportsCount=[tReportsArray count];
					
					if (tReportsCount>0)
					{
						NSUInteger j;
						
						//(void)fprintf(stdout, "Notes(%lu)\n",(unsigned long) tReportsCount);
						
						for(j=0;j<tReportsCount;j++)
						{
							NSMutableString * tReportLineStart;
							
							tReportLineStart=[NSMutableString new];
							
							if (tReportLineStart!=nil)
							{
								NSDictionary * tExtrasDictionary;
								id tExtraData;
							
								[tReportLineStart appendString:tFilePath];
								
								tReportDictionary=[tReportsArray objectAtIndex:j];
								
								tExtrasDictionary=[tReportDictionary objectForKey:BM_PROBLEM_EXTRAS];
								
								tExtraData=[tExtrasDictionary objectForKey:BM_PROBLEM_EXTRA_LINE_NUMBER];

                                if (tExtraData != nil)
									[tReportLineStart appendFormat:@":%u", [tExtraData unsignedIntValue]];
                                else
                                    [tReportLineStart appendString:@":1"];
								
								[tReportLineStart appendString:@": note:"];
								
								(void)fprintf(stdout, "%s",[tReportLineStart UTF8String]);
								
								tTitle=[tReportDictionary objectForKey:BM_PROBLEM_TITLE];
								
								if (tTitle!=nil)
								{
									(void)fprintf(stdout, " %s\n",[tTitle UTF8String]);
								}
								
								/*tExtraData=[tExtrasDictionary objectForKey:BM_PROBLEM_EXTRA_KEY];
								 
								 if (tExtraData!=nil)
								 {
								 (void)fprintf(stdout, "\"%s\"\n",[(NSString *) tExtraData UTF8String]);
								 }*/
								
								/*if (printDescription_==YES)*/
								{
									tDescription=[tReportDictionary objectForKey:BM_PROBLEM_DESCRIPTION];
									
									if (tDescription!=nil)
									{
										(void)fprintf(stdout, "%s",[tReportLineStart UTF8String]);
										
										(void)fprintf(stdout, " %s\n",[tDescription UTF8String]);
									}
								}
								
								[tReportLineStart release];
							}
						}
					}
				}
			}
			
			// Print the number of warnings, errors and notes
			
			[tAllKeys release];
		}
	}
	else
	{
		(void)fprintf(stdout, "No glitches found\n");
	}
	
	return 0;
}

#pragma mark -

- (void) didReceiveExternalReport:(NSNotification *) inNotification
{
	NSDictionary * tUserInfo;
	
	tUserInfo=[inNotification userInfo];
	
	if (tUserInfo!=nil)
	{
		NSString * tFilePath;
		NSMutableDictionary * tFileReportMutableDictionary;
		
		tFilePath=[tUserInfo objectForKey:BM_PROBLEM_FILE];
		
		tFileReportMutableDictionary=[reportDictionary_ objectForKey:tFilePath];
		
		if (tFileReportMutableDictionary==nil)
		{
			tFileReportMutableDictionary=[NSMutableDictionary dictionary];
			
			if (tFileReportMutableDictionary!=nil)
			{
				[reportDictionary_ setObject:tFileReportMutableDictionary forKey:tFilePath];
			}
			else
			{
				// Low Memory
				
				// A COMPLETER
			}
		}
		
		if (tFileReportMutableDictionary!=nil)
		{
			NSNumber * tLevelNumber;
			NSMutableArray * tLevelReportMutableArray;
			NSUInteger tLevelValue;
			
			tLevelNumber=[tUserInfo objectForKey:BM_PROBLEM_LEVEL];
			
			tLevelValue=[tLevelNumber unsignedIntegerValue];
			
			switch(tLevelValue)
			{
				case BM_PROBLEM_LEVEL_NOTE:
					
					notesCount_++;
					
					break;
					
				case BM_PROBLEM_LEVEL_WARNING:
					
					warningsCount_++;
					
					break;
					
				case BM_PROBLEM_LEVEL_ERROR:
					
					errorsCount_++;
					
					break;
			}
			
			tLevelReportMutableArray=[tFileReportMutableDictionary objectForKey:tLevelNumber];
			
			if (tLevelReportMutableArray==nil)
			{
				tLevelReportMutableArray=[NSMutableArray array];
				
				if (tLevelReportMutableArray!=nil)
				{
					[tFileReportMutableDictionary setObject:tLevelReportMutableArray forKey:tLevelNumber];
				}
				else
				{
					// Low Memory
					
					// A COMPLETER
				}
			}
			
			if (tLevelReportMutableArray!=nil)
			{
				NSMutableDictionary * tReportMutableDictionary;
				
				tReportMutableDictionary=[tUserInfo mutableCopy];
				
				if (tReportMutableDictionary!=nil)
				{
					[tReportMutableDictionary removeObjectForKey:BM_PROBLEM_LEVEL];
					
					[tReportMutableDictionary removeObjectForKey:BM_PROBLEM_FILE];
					
					[tLevelReportMutableArray addObject:tReportMutableDictionary];
					
					[tReportMutableDictionary release];
				}
				else
				{
					// Low Memory
					
					// A COMPLETER
				}
			}
		}
	}
}

@end
