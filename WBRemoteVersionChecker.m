/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WBRemoteVersionChecker.h"

#define WBREMOTEVERSIONREMINDER_PERIOD	(24*3600)		// Every day
#define WBREMOTEVERSIONCHECK_PERIOD		(3*24*3600)		// Every 3 days

NSString * const WBRemoteCheckEnabledKey=@"WBRemoteCheckEnabled";
NSString * const WBRemoteLastCheckDateKey=@"WBRemoteLastCheckDate";
NSString * const WBLastReminderDateKey=@"WBLastReminderDate";
NSString * const WBRemoteAvailableVersionKey=@"WBRemoteAvailableVersion";
NSString * const WBRemoteAvailableVersionURLKey=@"WBRemoteAvailableVersionURL";


NSString * const WBSkipRemoteAvailableVersionKey=@"WBSkipRemoteAvailableVersion";


NSString * const WBVersionCheckURL=@"WBVersionCheckURL";

@implementation WBRemoteVersionChecker

+ (WBRemoteVersionChecker *) sharedChecker
{
	static WBRemoteVersionChecker * sRemoteVersionChecker=nil;
	
	if (sRemoteVersionChecker==nil)
	{
		sRemoteVersionChecker=[WBRemoteVersionChecker new];
	}
	
	return sRemoteVersionChecker;
}

#pragma mark -

- (id) init
{
	self=[super init];
	
	if (self!=nil)
	{
		NSBundle * tBundle=[NSBundle mainBundle];
		
		productName_=[[tBundle objectForInfoDictionaryKey:@"CFBundleName"] retain];
		productLocalVersion_=[[tBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] retain];
		productCheckURL_=[[tBundle objectForInfoDictionaryKey:WBVersionCheckURL] retain];
		
		defaults_=[NSUserDefaults standardUserDefaults];
		
		if ([productLocalVersion_ length]>0)
		{
			BOOL tSkipRemoteAvailableVersion;
			NSDate * tCurrentDate;
			
			tCurrentDate=[NSDate date];
			
			tSkipRemoteAvailableVersion=[defaults_ boolForKey:WBSkipRemoteAvailableVersionKey];
		
			if (tSkipRemoteAvailableVersion==NO)
			{
				NSString * tRemoteVersion;
				
				tRemoteVersion=[defaults_ objectForKey:WBRemoteAvailableVersionKey];
				
				if (tRemoteVersion!=nil)
				{
					if ([tRemoteVersion compare:productLocalVersion_ options:NSNumericSearch]==NSOrderedDescending)
					{
						NSDate * tLastReminderDate;
						
						tLastReminderDate=[defaults_ objectForKey:WBLastReminderDateKey];
						
						if (tLastReminderDate==nil || [tCurrentDate timeIntervalSinceDate:tLastReminderDate]>WBREMOTEVERSIONREMINDER_PERIOD)
						{
							NSString * tDownloadURL;
							
							tDownloadURL=[defaults_ objectForKey:WBRemoteAvailableVersionURLKey];
							
							if (tDownloadURL!=nil)
							{
								// Display dialog
								
								NSString * tTitle;
								NSString * tMessage;
								NSInteger tReturnCode;
								
								tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"A new version of %@ is available.",@"RemoteCheck",@""),productName_];
								
								tMessage=[NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ %@ is now available - you have %@. Would you like to download it now?",@"RemoteCheck",@""),productName_,tRemoteVersion,productLocalVersion_];
								
								tReturnCode=NSRunAlertPanel(tTitle, 
															tMessage, 
															NSLocalizedStringFromTable(@"Download",@"RemoteCheck",@""), 
															NSLocalizedStringFromTable(@"Skip This Version",@"RemoteCheck",@""),
															NSLocalizedStringFromTable(@"Remind Me Later",@"RemoteCheck",@""));
								
								switch(tReturnCode)
								{
									case NSAlertDefaultReturn:
										
										// Download
										
										[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:tDownloadURL]];
										
										[defaults_ setObject:[NSDate date] forKey:WBLastReminderDateKey];
										
										break;
										
									case NSAlertAlternateReturn:
										
										// Skip
										
										[defaults_ setBool:YES forKey:WBSkipRemoteAvailableVersionKey];
										
										break;
										
									case NSAlertOtherReturn:
										
										// Remind me later
									
										[defaults_ setObject:[NSDate date] forKey:WBLastReminderDateKey];
										
										break;
										
									default:
										
										break;
								}
							}
						}
					}
				}
			}
		
			if ([productCheckURL_ length]>0)
			{
				id tObject;
				
				// Check whether it's time to check for a newer version
				
				tObject=[defaults_ objectForKey:WBRemoteCheckEnabledKey];
				
				if (tObject==nil || [defaults_ boolForKey:WBRemoteCheckEnabledKey]==YES)
				{
					NSDate * tLastCheckDate;
					
					tLastCheckDate=[defaults_ objectForKey:WBRemoteLastCheckDateKey];
					
					if (tLastCheckDate==nil || ([tCurrentDate timeIntervalSinceDate:tLastCheckDate]>WBREMOTEVERSIONCHECK_PERIOD))
					{
						// Perform Remote Check
						
						NSURLRequest * tRequest;
						
						[_data release];
						
						_data=nil;
						
						tRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:productCheckURL_]];
						
						if (tRequest!=nil)
						{
							NSURLConnection * tURLConnection;
							
							tURLConnection=[[NSURLConnection alloc] initWithRequest:tRequest delegate:self];
							
							if (tURLConnection==nil)
							{
								NSLog(@"Could not allocate NSURLConnection");
							}
						}
						else
						{
							NSLog(@"Could not allocate NSURLRequest");
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
	[productName_ release];
	
	[productLocalVersion_ release];
	
	[productCheckURL_ release];
	
	[super dealloc];
}

#pragma mark -

- (BOOL) isCheckEnabled
{
	id tObject;
	
	tObject=[defaults_ objectForKey:WBRemoteCheckEnabledKey];
	
	if (tObject==nil || [defaults_ boolForKey:WBRemoteCheckEnabledKey]==YES)
	{
		return YES;
	}
	
	return NO;
}

- (void) setCheckEnabled:(BOOL)inBool
{
	[defaults_ setBool:inBool forKey:WBRemoteCheckEnabledKey];
}

#pragma mark -

- (void) connection:(NSURLConnection *) inConnection didReceiveResponse:(NSURLResponse *) inResponse
{
	if (inConnection!=nil)
	{
		NSHTTPURLResponse * tHTTPResponse=(NSHTTPURLResponse *) inResponse;
		
		switch ([tHTTPResponse statusCode])
		{
			case 200:
				
				break;
				
			default:
				
				[inConnection cancel];
				
				[inConnection release];
				
				break;
		}
	}
}

- (void) connection:(NSURLConnection *) inConnection didReceiveData:(NSData *) inData
{
    if (inConnection!=nil && inData!=nil)
	{
        if (_data==nil)
        {
            _data=[inData mutableCopy];
        }
        else
        {
            [_data appendData:inData];
        }
    }
}

- (void) connection:(NSURLConnection *) inConnection didFailWithError:(NSError *) inError
{
	if (inConnection!=nil)
	{
        [_data release];
        _data=nil;
        
        [inConnection release];
    }
}

- (void) connectionDidFinishLoading:(NSURLConnection *) inConnection
{
	if (inConnection!=nil)
	{
        [inConnection release];
        
		if (_data!=nil)
		{
			NSDictionary * tDictionary;
			NSPropertyListFormat tPropertyListFormat;
			
			[defaults_ setObject:[NSDate date] forKey:WBRemoteLastCheckDateKey];
			
			tDictionary=[NSPropertyListSerialization propertyListFromData:_data 
														 mutabilityOption:NSPropertyListImmutable 
																   format:&tPropertyListFormat
														 errorDescription:NULL];
			
			if (tDictionary!=nil)
			{
				NSString * tRemoteVersion;
				NSString * tLocalRemoteVersion;
				
				tRemoteVersion=[tDictionary objectForKey:WBRemoteAvailableVersionKey];
				
				tLocalRemoteVersion=[defaults_ objectForKey:WBRemoteAvailableVersionKey];
				
				if (tLocalRemoteVersion!=nil)
				{
					if ([tRemoteVersion compare:tLocalRemoteVersion options:NSNumericSearch]!=NSOrderedDescending)
					{
						goto bail;
					}
				}
				
				if (productLocalVersion_!=nil)
				{
					if ([tRemoteVersion compare:productLocalVersion_ options:NSNumericSearch]==NSOrderedDescending)
					{
						NSString * tRemoteURL;
						
						tRemoteURL=[tDictionary objectForKey:WBRemoteAvailableVersionURLKey];
						
						if (tRemoteURL!=nil)
						{
							[defaults_ setObject:tRemoteURL forKey:WBRemoteAvailableVersionURLKey];
							[defaults_ setObject:tRemoteVersion forKey:WBRemoteAvailableVersionKey];
							[defaults_ setBool:NO forKey:WBSkipRemoteAvailableVersionKey];
						}
					}
				}
			}
		}
																		   
bail:
																		   
		[_data release];
        _data=nil;
    }
}

@end
