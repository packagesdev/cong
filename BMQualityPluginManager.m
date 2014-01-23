/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMQualityPluginManager.h"

@implementation BMQualityPluginManager

+ (BMQualityPluginManager *) sharedManager
{
	static BMQualityPluginManager * sPluginsManager=nil;
	
	if (sPluginsManager==nil)
	{
		sPluginsManager=[BMQualityPluginManager new];
	}
	
	return sPluginsManager;
}

#pragma mark -

- (id) init
{
	self=[super init];
	
	if (self!=nil)
	{
		NSBundle * tBundle;
		
		tBundle=[NSBundle mainBundle];
		
		if (tBundle!=nil)
		{
			NSString * tFolderPath;
			
			tFolderPath=[tBundle builtInPlugInsPath];
			
			if (tFolderPath!=nil)
			{
				NSFileManager * tFileManager;
				NSArray * tPluginsList;
				
				// Look for plugins
				
				tFileManager=[NSFileManager defaultManager];
				
				tPluginsList=[tFileManager contentsOfDirectoryAtPath:tFolderPath error:NULL];
				
				pluginControllersArray_=[[NSMutableArray alloc] initWithCapacity:20];
				
				for(NSString * tSubPath in tPluginsList)
				{
					if ([[tSubPath pathExtension] isEqualToString:@"checker"]==YES)
					{
						NSString * tPluginPath;
						NSBundle * tBundle;
						
						tPluginPath=[tFolderPath stringByAppendingPathComponent:tSubPath];
						
						tBundle=[NSBundle bundleWithPath:tPluginPath];
						
						if (tBundle!=nil)
						{
							Class tPrincipalClass;
				
							tPrincipalClass=[tBundle principalClass];
							
							if (tPrincipalClass!=nil)
							{
								id tInstance;
								
								tInstance=[[tPrincipalClass alloc] initWithBundle:tBundle];
								
								if (tInstance!=nil)
								{
									[pluginControllersArray_ addObject:tInstance];
									
									[tInstance release];
								}
							}
						}
					}
				}
			}
		}
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[pluginControllersArray_ release];

	[super dealloc];
}

#pragma mark -

- (void) testItem:(id) inItem atPath:(NSString *) inPath ofType:(NSUInteger) inType withDelegate:(id) inDelegate
{
	for(BMQualityPluginController * tPluginController in pluginControllersArray_)
	{
		if ([tPluginController isEnabled]==YES && [tPluginController canTestItemOfType:inType]==YES)
		{
			[tPluginController testItem:inItem atPath:inPath ofType:inType withDelegate:inDelegate];
		}
	}
}



@end
