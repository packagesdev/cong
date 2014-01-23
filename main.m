/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

#import "BMCommandLineProcessor.h"

void usage(void);

void usage(void)
{
    (void)fprintf(stderr, "%s\n","usage: Cong -t file");
    
    exit(1);
}

int main(int argc, char *argv[])
{
    if (argc>=2)
	{
		char * tArgument;
		
		tArgument=argv[1];
		
		if (strncmp(tArgument, "-t", 2)==0 ||
			strncmp(tArgument, "-?", 2)==0)
		{
			int ch;
			BOOL isCommandLineRequest=NO;
			BOOL shouldPrintDescription=NO;
			BOOL shouldShowUsage=NO;
			
			// Check if we were not called as a command line tool
			
			while ((ch = getopt(argc,(char **) argv,"t?")) != -1)
			{
				switch(ch)
				{
					/*case 'd':
						 
						shouldPrintDescription=YES;
						 
						break;*/
						
					case 't':
						
						isCommandLineRequest=YES;
						
						break;
						
					case '?':
						
						usage();
						
						return 0;
				}
			}
			
			if (isCommandLineRequest==YES)
			{
				NSAutoreleasePool * tPool;
				int tExitCode=1;
				
				tPool=[NSAutoreleasePool new];
				
				if (shouldShowUsage==YES)
				{
					usage();
				}
				else
				{
					BMCommandLineProcessor * tCommandLineProcessor;
					
					tCommandLineProcessor=[BMCommandLineProcessor new];
					
					if (tCommandLineProcessor!=nil)
					{
						NSString * tBundlePath;
						NSFileManager * tFileManager;
						
						tFileManager=[NSFileManager defaultManager];
						
						argv+=optind;
						
						tBundlePath=[[NSString stringWithUTF8String:argv[0]] stringByStandardizingPath];
						
						if ([tBundlePath characterAtIndex:0]!='/')
						{
							tBundlePath=[[tFileManager currentDirectoryPath] stringByAppendingPathComponent:tBundlePath];
						}
						
						if ([tFileManager fileExistsAtPath:tBundlePath]==YES)
						{
							tExitCode=[tCommandLineProcessor processBundleAtPath:tBundlePath printDescription:shouldPrintDescription];
						}
						else
						{
							(void)fprintf(stderr, "No such file or directory (%s)\n",argv[0]);
						}
						
						[tCommandLineProcessor release];
					}
					
					[tPool release];
					
					return tExitCode;
				}
				
				[tPool release];
			}
		}
	}
	
	return NSApplicationMain(argc, (const char **) argv);
}
