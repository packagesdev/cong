/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMIconsUtilities.h"

@implementation BMIconsUtilities

+ (BOOL) isIcnsFileAtPath:(NSString *) inPath
{
	BOOL isIcns=NO;
	
	if (inPath!=nil)
	{
		FILE * fp;
		
		fp=fopen([inPath fileSystemRepresentation],"r");
		
		if (fp!=NULL)
		{
			uint32_t tMagicCookie;
			
			if (fread(&tMagicCookie,sizeof(uint32_t),1,fp)==1)
			{
				tMagicCookie=CFSwapInt32BigToHost(tMagicCookie);
				
				if (tMagicCookie==0x69636e73)
				{
					isIcns=YES;
				}
			}
		
			fclose(fp);
		}
	}
	
	return isIcns;
}

+ (NSArray *) availableSizesForIcnsAtPath:(NSString *) inPath
{
	NSMutableArray * tMutableArray=nil;
	
	if (inPath!=nil)
	{
		FILE * fp;
		
		fp=fopen([inPath fileSystemRepresentation],"r");
		
		if (fp!=NULL)
		{
			tMutableArray=[NSMutableArray array];
			
			if (tMutableArray!=nil)
			{
				static NSDictionary * sIconSizeIndex=nil;
				
				if (sIconSizeIndex==nil)
				{
					sIconSizeIndex=[[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:32],@"ICON",
																				[NSNumber numberWithInt:32],@"ICN#",
																				[NSNumber numberWithInt:16],@"icm#",
																				[NSNumber numberWithInt:16],@"icm4",
																				[NSNumber numberWithInt:16],@"icm8",
																				[NSNumber numberWithInt:16],@"ics#",
																				[NSNumber numberWithInt:16],@"ics4",
																				[NSNumber numberWithInt:16],@"ics8",
																				[NSNumber numberWithInt:16],@"is32",
																				[NSNumber numberWithInt:16],@"s8mk",
																				[NSNumber numberWithInt:16],@"ipc4",
																				[NSNumber numberWithInt:16],@"ic11",		// 16@2x
																				[NSNumber numberWithInt:32],@"icl4",
																				[NSNumber numberWithInt:32],@"icl8",
																				[NSNumber numberWithInt:32],@"il32",
																				[NSNumber numberWithInt:32],@"l8mk",
																				[NSNumber numberWithInt:32],@"ipc5",
																				[NSNumber numberWithInt:32],@"ic12",		// 32@2x
																				[NSNumber numberWithInt:48],@"ich#",
																				[NSNumber numberWithInt:48],@"ich4",
																				[NSNumber numberWithInt:48],@"ich8",
																				[NSNumber numberWithInt:48],@"ih32",
																				[NSNumber numberWithInt:48],@"h8mk",
																				[NSNumber numberWithInt:128],@"it32",
																				[NSNumber numberWithInt:128],@"t8mk",
																				[NSNumber numberWithInt:128],@"ic07",
																				[NSNumber numberWithInt:128],@"ic13",		// 128@2x
																				[NSNumber numberWithInt:256],@"ic08",
																				[NSNumber numberWithInt:512],@"ic09",
																				[NSNumber numberWithInt:512],@"ic14",		// 256@2x
																				[NSNumber numberWithInt:1024],@"ic10",		// 512@2x (10.8)
																				nil];
				}
				
				if (sIconSizeIndex!=nil)
				{
					long tOffset;
				
					tOffset=8;
				
					while (fseek(fp,tOffset,SEEK_CUR)==0)
					{
						char tOSType[5];
						
						// Read the Type
					
						if (fread(tOSType,sizeof(char),4,fp)==4)
						{
							NSString * tOSTypeString;
							
							
							tOSType[4]=0;
							
							tOSTypeString=[NSString stringWithCString:tOSType encoding:NSASCIIStringEncoding];
							
							if (tOSTypeString!=nil)
							{
								uint32_t tDataLength;
								NSNumber * tNumber;
								
								tNumber=[sIconSizeIndex objectForKey:tOSTypeString];
								
								if (tNumber!=nil)
								{
									[tMutableArray addObject:tNumber];
								}
								else
								{
									// A COMPLETER
								}
								
								// Read the length
							
								if (fread(&tDataLength,sizeof(uint32_t),1,fp)==1)
								{
									tDataLength=CFSwapInt32BigToHost(tDataLength);
									
									tOffset=tDataLength-8;
								}
								else
								{
									break;
								}
							}
						}
						else
						{
							break;
						}
					}
				}
			}
		}
	}
	
	return tMutableArray;
}

@end
