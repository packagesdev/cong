/*
Copyright (c) 2007-2010, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "ICArchitectureUtilities.h"

#include <mach-o/loader.h>
#include <mach-o/fat.h>

#include <CoreServices/CoreServices.h>

#ifdef __LP64__

typedef OSType                          CFragArchitecture;
enum {
	/* Values for type CFragArchitecture.*/
	kPowerPCCFragArch             = 'pwpc',
	kMotorola68KCFragArch         = 'm68k',
	kAnyCFragArch                 = 0x3F3F3F3F
};

#endif

@implementation ICArchitectureUtilities

+ (NSArray *) architecturesOfFile:(NSString *) inPath
{
	NSArray * tArray=nil;
	
	if (inPath!=nil)
	{
		FILE * tFile;
	
		tFile=fopen([inPath fileSystemRepresentation],"r");
		
		if (tFile!=NULL)
		{
			uint32_t tMagicCookie;
			size_t tSize;
			
			tSize=sizeof(uint32_t);
			
			if (fread(&tMagicCookie,tSize,1,tFile)==1)
			{
				
#if BYTE_ORDER==LITTLE_ENDIAN
				tMagicCookie=CFSwapInt32(tMagicCookie);
#endif
				
				fseek(tFile,0,SEEK_SET);
				
				// PEF
					
				if (tMagicCookie==kPEFTag1)
				{
					PEFContainerHeader tContainerHeader;
					
					tSize=sizeof(PEFContainerHeader);
					
					if (fread(&tContainerHeader,tSize,1,tFile)==1)
					{
						
#if BYTE_ORDER==LITTLE_ENDIAN
						tContainerHeader.tag2=CFSwapInt32(tContainerHeader.tag2);
						tContainerHeader.architecture=CFSwapInt32(tContainerHeader.architecture);
#endif

						if (tContainerHeader.tag2==kPEFTag2 &&
							tContainerHeader.architecture==kPowerPCCFragArch)
						{
							tArray=[NSArray arrayWithObject:@"ppc"];
						}
					}
				}
				else
				{
					// mach-o
					
					if (tMagicCookie==FAT_MAGIC || tMagicCookie==FAT_CIGAM)
					{
						struct fat_header tFatHeader;
						
						tSize=sizeof(struct fat_header);
					
						if (fread(&tFatHeader,tSize,1,tFile)==1)
						{
							NSMutableArray * tMutableArray;
							
							tMutableArray=[NSMutableArray array];
							
							if (tMutableArray!=nil)
							{
								uint32_t i;
								
#if BYTE_ORDER==LITTLE_ENDIAN
								tFatHeader.nfat_arch=CFSwapInt32(tFatHeader.nfat_arch);
#endif

								for(i=0;i<tFatHeader.nfat_arch;i++)
								{
									struct fat_arch tFatArch;
								
									tSize=sizeof(struct fat_arch);
					
									if (fread(&tFatArch,tSize,1,tFile)==1)
									{
#if BYTE_ORDER==LITTLE_ENDIAN
										tFatArch.cputype=CFSwapInt32(tFatArch.cputype);
#endif										
									
										switch(tFatArch.cputype)
										{
											case CPU_TYPE_X86:
											
												[tMutableArray addObject:@"i386"];
												
												break;
												
											case CPU_TYPE_X86_64:
											
												[tMutableArray addObject:@"x86_64"];
												
												break;
												
											case CPU_TYPE_POWERPC:
											
												[tMutableArray addObject:@"ppc"];
												
												break;
												
											case CPU_TYPE_POWERPC64:
											
												[tMutableArray addObject:@"ppc64"];
												
												break;
												
											case CPU_TYPE_ARM:
												
												if (tMagicCookie==MH_CIGAM)
												{
#if BYTE_ORDER==BIG_ENDIAN
													tFatArch.cpusubtype=CFSwapInt32(tFatArch.cpusubtype);
#endif
												}
												else
												{
#if BYTE_ORDER==LITTLE_ENDIAN
													tFatArch.cpusubtype=CFSwapInt32(tFatArch.cpusubtype);
#endif
												}
												
												switch(tFatArch.cpusubtype)
												{
													case CPU_SUBTYPE_ARM_V6:
														
														[tMutableArray addObject:@"armv6"];
														
														break;
	
#ifndef CPU_SUBTYPE_ARM_V7
	#define CPU_SUBTYPE_ARM_V7		((cpu_subtype_t) 9)
#endif
														
													case CPU_SUBTYPE_ARM_V7:
														
														[tMutableArray addObject:@"armv7"];
														
														break;
													
													default:
														
														[tMutableArray addObject:@"arm"];
														
														break;
												}
												
												break;
										}
									}
								}
								
								[tMutableArray sortUsingSelector:@selector(compare:)];
								
								tArray=tMutableArray;
							}
						}
					}
					else if (tMagicCookie==MH_MAGIC || tMagicCookie==MH_CIGAM)
					{
						struct mach_header tMachHeader;
						
						tSize=sizeof(struct mach_header);
					
						if (fread(&tMachHeader,tSize,1,tFile)==1)
						{
							if (tMagicCookie==MH_CIGAM)
							{
#if BYTE_ORDER==BIG_ENDIAN
								tMachHeader.cputype=CFSwapInt32(tMachHeader.cputype);
#endif
							}
							else
							{
#if BYTE_ORDER==LITTLE_ENDIAN
								tMachHeader.cputype=CFSwapInt32(tMachHeader.cputype);
#endif
							}

							switch(tMachHeader.cputype)
							{
								case CPU_TYPE_X86:
								
									tArray=[NSArray arrayWithObject:@"i386"];
									
									break;
									
								case CPU_TYPE_POWERPC:
								
									tArray=[NSArray arrayWithObject:@"ppc"];
									
									break;
									
								case CPU_TYPE_ARM:
									
									if (tMagicCookie==MH_CIGAM)
									{
#if BYTE_ORDER==BIG_ENDIAN
										tMachHeader.cpusubtype=CFSwapInt32(tMachHeader.cpusubtype);
#endif
									}
									else
									{
#if BYTE_ORDER==LITTLE_ENDIAN
										tMachHeader.cpusubtype=CFSwapInt32(tMachHeader.cpusubtype);
#endif
									}
									
									switch(tMachHeader.cpusubtype)
									{
										case CPU_SUBTYPE_ARM_V6:
											
											tArray=[NSArray arrayWithObject:@"armv6"];
											
											break;
											
										case CPU_SUBTYPE_ARM_V7:
											
											tArray=[NSArray arrayWithObject:@"armv7"];
											
											break;
											
										default:
											
											tArray=[NSArray arrayWithObject:@"arm"];
											
											break;
											
									}
									
									break;
							}
						}
					}
					else if (tMagicCookie==MH_MAGIC_64 || tMagicCookie==MH_CIGAM_64)
					{
						struct mach_header_64 tMachHeader64;
						
						tSize=sizeof(struct mach_header_64);
					
						if (fread(&tMachHeader64,tSize,1,tFile)==1)
						{
							if (tMagicCookie==MH_CIGAM_64)
							{
#if BYTE_ORDER==BIG_ENDIAN
								tMachHeader64.cputype=CFSwapInt32(tMachHeader64.cputype);
#endif
							}
							else
							{
#if BYTE_ORDER==LITTLE_ENDIAN
								tMachHeader64.cputype=CFSwapInt32(tMachHeader64.cputype);
#endif
							}
							
							switch(tMachHeader64.cputype)
							{
								case CPU_TYPE_X86_64:
								
									tArray=[NSArray arrayWithObject:@"x86_64"];
									
									break;
									
								case CPU_TYPE_POWERPC64:
								
									tArray=[NSArray arrayWithObject:@"ppc64"];
									
									break;
							}
						}
					}
				}
			}
			
			fclose(tFile);
		}
	}
	
	return tArray;
}

@end
