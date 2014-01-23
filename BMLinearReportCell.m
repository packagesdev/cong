/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMLinearReportCell.h"

@implementation BMLinearReportCell

+ (NSDictionary *) attributesDictionary
{
	static NSDictionary * sAttributesDictionary=nil;
	
	if (sAttributesDictionary==nil)
	{
		sAttributesDictionary=[[NSDictionary alloc] initWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica Bold" size:12.0],NSFontAttributeName,
																		   [NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSForegroundColorAttributeName,
																		   nil];
	}
	
	return sAttributesDictionary;
}

+ (NSString *) formattedNumber:(NSUInteger) inValue
{
	NSString * tString=nil;
	
	if (inValue>0)
	{
		NSNumber * tNumber;
		
		tNumber=[NSNumber numberWithUnsignedInteger:inValue];
		
		if (tNumber!=nil)
		{
			static NSNumberFormatter * sNumberFormatter=nil;
			
			if (sNumberFormatter==nil)
			{
				sNumberFormatter=[NSNumberFormatter new];
				
				[sNumberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
				
				[sNumberFormatter setFormat:@"#,##0;0;-#,##0"];
			}
			
			if (sNumberFormatter!=nil)
			{
				return [sNumberFormatter stringForObjectValue:tNumber];
			}
		}
	}
	
	return tString;
}

+ (NSImage *) noteIcon
{
	static NSImage * sNoteIcon=nil;
	
	if (sNoteIcon==nil)
	{
		NSString * tPath;
		
		tPath=[[NSBundle bundleForClass:[BMLinearReportCell class]] pathForResource:@"Note12" ofType:@"png"];
		
		if (tPath!=nil)
		{
			sNoteIcon=[[NSImage alloc] initWithContentsOfFile:tPath];
		}
	}
	
	return sNoteIcon;
}

+ (NSImage *) warningIcon
{
	static NSImage * sWarningIcon=nil;
	
	if (sWarningIcon==nil)
	{
		NSString * tPath;
		
		tPath=[[NSBundle bundleForClass:[BMLinearReportCell class]] pathForResource:@"Warning12" ofType:@"png"];
		
		if (tPath!=nil)
		{
			sWarningIcon=[[NSImage alloc] initWithContentsOfFile:tPath];
		}
	}
	
	return sWarningIcon;
}

+ (NSImage *) errorIcon
{
	static NSImage * sErrorIcon=nil;
	
	if (sErrorIcon==nil)
	{
		NSString * tPath;
		
		tPath=[[NSBundle bundleForClass:[BMLinearReportCell class]] pathForResource:@"Error12" ofType:@"png"];
		
		if (tPath!=nil)
		{
			sErrorIcon=[[NSImage alloc] initWithContentsOfFile:tPath];
		}
	}
	
	return sErrorIcon;
}

+ (NSDictionary *) fileTitleAttributes
{
	static NSDictionary * sFileTitleAttributes=nil;
	
	if (sFileTitleAttributes==nil)
	{
		NSMutableParagraphStyle * tMutableParagraphStyle;
		
		tMutableParagraphStyle=[[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		
		[tMutableParagraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
		
		
		
		sFileTitleAttributes=[[NSDictionary alloc] initWithObjectsAndKeys:[NSColor colorWithCalibratedWhite:0.15f alpha:1.0f],NSForegroundColorAttributeName,
																		  [NSFont boldSystemFontOfSize:11.0f],NSFontAttributeName,
																		  tMutableParagraphStyle,NSParagraphStyleAttributeName,
																		  nil]; 
																		  
		
	}
	
	return sFileTitleAttributes;
}

+ (NSDictionary *) titleAttributes
{
	static NSDictionary * sTitleAttributes=nil;
	
	if (sTitleAttributes==nil)
	{
		//NSMutableParagraphStyle * tMutableParagraphStyle;
		
		//tMutableParagraphStyle=[[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		
		//[tMutableParagraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
		
		sTitleAttributes=[[NSDictionary alloc] initWithObjectsAndKeys:[NSColor colorWithCalibratedWhite:0.0f alpha:1.0f],NSForegroundColorAttributeName,
																	  [NSFont systemFontOfSize:11.0f],NSFontAttributeName,
																	  //tMutableParagraphStyle,NSParagraphStyleAttributeName,
																	  nil]; 
	}
	
	return sTitleAttributes;
}

+ (NSDictionary *) descriptionAttributes
{
	static NSDictionary * sDescriptionAttributes=nil;
	
	if (sDescriptionAttributes==nil)
	{
		//NSMutableParagraphStyle * tMutableParagraphStyle;
		
		//tMutableParagraphStyle=[[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		
		//[tMutableParagraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
		
		sDescriptionAttributes=[[NSDictionary alloc] initWithObjectsAndKeys:[NSColor colorWithCalibratedWhite:0.4f alpha:1.0f],NSForegroundColorAttributeName,
						  [NSFont systemFontOfSize:10.0f],NSFontAttributeName,
						  //tMutableParagraphStyle,NSParagraphStyleAttributeName,
						  nil]; 
	}
	
	return sDescriptionAttributes;
}

+ (NSDictionary *) whiteDescriptionAttributes
{
	static NSDictionary * sWhiteDescriptionAttributes=nil;
	
	if (sWhiteDescriptionAttributes==nil)
	{
		//NSMutableParagraphStyle * tMutableParagraphStyle;
		
		//tMutableParagraphStyle=[[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		
		//[tMutableParagraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
		
		sWhiteDescriptionAttributes=[[NSDictionary alloc] initWithObjectsAndKeys:[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f],NSForegroundColorAttributeName,
								[NSFont systemFontOfSize:10.0f],NSFontAttributeName,
								//tMutableParagraphStyle,NSParagraphStyleAttributeName,
								nil]; 
	}
	
	return sWhiteDescriptionAttributes;
}


+ (NSDictionary *) whiteFileTitleAttributes
{
	static NSDictionary * sWhiteFileTitleAttributes=nil;
	
	if (sWhiteFileTitleAttributes==nil)
	{
		NSMutableParagraphStyle * tMutableParagraphStyle;
		
		tMutableParagraphStyle=[[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		
		[tMutableParagraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
		
		sWhiteFileTitleAttributes=[[NSDictionary alloc] initWithObjectsAndKeys:[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f],NSForegroundColorAttributeName,
																		   [NSFont boldSystemFontOfSize:11.0f],NSFontAttributeName,
																		   tMutableParagraphStyle,NSParagraphStyleAttributeName,
																		   nil]; 
	}
	
	return sWhiteFileTitleAttributes;
}

+ (NSDictionary *) whiteTitleAttributes
{
	static NSDictionary * sWhiteTitleAttributes=nil;
	
	if (sWhiteTitleAttributes==nil)
	{
		//NSMutableParagraphStyle * tMutableParagraphStyle;
		
		//tMutableParagraphStyle=[[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		
		//[tMutableParagraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
		
		sWhiteTitleAttributes=[[NSDictionary alloc] initWithObjectsAndKeys:[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f],NSForegroundColorAttributeName,
																		   [NSFont systemFontOfSize:11.0f],NSFontAttributeName,
																		   //tMutableParagraphStyle,NSParagraphStyleAttributeName,
																		   nil]; 
	}
	
	return sWhiteTitleAttributes;
}

- (id) initTextCell:(NSString *) inString
{
	self=[super initTextCell:inString];
	
	if (self!=nil)
	{
		highlightRange_.location=NSNotFound;
	}
	
	return self;
}

- (void) dealloc
{
    [icon_ release];
	
    icon_ = nil;
	
	[title_ release];
	
	title_=nil;
	
	[description_ release];
	
    description_ = nil;
	
    [super dealloc];
}

- (id) copyWithZone:(NSZone *)zone
{
	BMLinearReportCell * tCell;
	
	tCell = (BMLinearReportCell *)[super copyWithZone:zone];
   
	tCell->icon_ = [icon_ retain];
	
	tCell->title_ = [title_ retain];
	
	tCell->description_ = [description_ retain];
    
	return tCell;
}

#pragma mark -

- (void) setHighlightRange:(NSRange) inRange
{
	highlightRange_=inRange;
}

- (void) setType:(int) inType
{
	type_=inType;
}

- (void) setIcon:(NSImage *) inIcon
{
	if (inIcon != icon_)
	{
        [icon_ release];
		
        icon_ = [inIcon retain];
    }
}

- (void) setTitle:(NSString *) inTitle
{
	if (title_ != inTitle)
	{
        [title_ release];
		
        title_ = [inTitle retain];
    }
}

- (void) setDescription:(NSString *) inDescription
{
	if (description_ != inDescription)
	{
        [description_ release];
		
        description_ = [inDescription retain];
    }
}

- (void) setNotes:(NSUInteger) inNotes warnings:(NSUInteger) inWarnings errors:(NSUInteger) inErrors
{
	notes_=inNotes;
	
	warnings_=inWarnings;
	
	errors_=inErrors;
}

#pragma mark -

- (void) drawWithFrame:(NSRect) inFrame inView:(NSView *) inView
{
    if (type_==BM_LINEAR_CELL_TYPE_FILE)
	{
		NSRect tFrame;
		NSString * tWarningString=nil;
		NSString * tErrorsString=nil;
		NSString * tNotesString=nil;
		CGFloat tCapsuleLength;
		NSBezierPath * tBezierPath;
		NSUInteger tErrorTypes;
		
		if ([self isHighlighted]==NO)
		{
			NSRect tRowFrame;
			
			/*if (errors_>0)
			{
				[[NSColor colorWithCalibratedRed:0.9647f green:0.8471f blue:0.8510f alpha:1.0f] set];
			}
			else if (warnings_>0)
			{
				[[NSColor colorWithCalibratedRed:245.0/255.0 green:216.0/255.0 blue:160.0/255.0 alpha:1.0f] set];
			}
			else*/ /*if (notes_>0)*/
			{
				[[NSColor colorWithCalibratedWhite:0.95f alpha:1.0f] set];
			}
			
			tRowFrame=NSMakeRect(0.0f,NSMinY(inFrame),NSWidth([inView bounds]),NSHeight(inFrame));
		
			NSRectFill(tRowFrame);
			
			/*if (errors_>0 || warnings_>0)
			{
				if (errors_>0)
				{
					[[NSColor colorWithCalibratedRed:0.7882f green:0.1647f blue:0.0902f alpha:1.0f] set];
				}
				else
				{
					[[NSColor colorWithCalibratedRed:247.0/255.0 green:190.0/255.0 blue:92.0/255.0 alpha:1.0f] set];
				}
			
				[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(tRowFrame),NSMinY(tRowFrame)-0.5f) toPoint:NSMakePoint(NSMaxX(tRowFrame),NSMinY(tRowFrame)-0.5f)];
			
				[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(tRowFrame),NSMaxY(tRowFrame)+0.5f) toPoint:NSMakePoint(NSMaxX(tRowFrame),NSMaxY(tRowFrame)+0.5f)];
			}*/
		}
		
		// Icon
		
		if (icon_!=nil)
		{
			tFrame.size=NSMakeSize(32.0,32.0);
			
			tFrame.origin.y=NSMinY(inFrame);
			
			tFrame.origin.x=NSMinX(inFrame)+2.0;
			
			if ([inView isFlipped])
				tFrame.origin.y += ceil((NSHeight(inFrame) + NSHeight(tFrame)) / 2);
			else
				tFrame.origin.y += ceil((NSHeight(inFrame) - NSHeight(tFrame)) / 2);
			
			[icon_ compositeToPoint:tFrame.origin operation:NSCompositeSourceOver];
		}
		
		// Text
		
		if (title_!=nil)
		{
			NSRect tTitleFrame;
			NSSize tSize;
			
			tSize=inFrame.size;
			
			tSize.width-=43.0;
			
			tTitleFrame=[title_ boundingRectWithSize:tSize options:0 attributes:[BMLinearReportCell fileTitleAttributes]];
			
			tTitleFrame.origin=NSMakePoint(NSMinX(inFrame)+39.0f,NSMinY(inFrame)+2.0f);
			
			if ([self isHighlighted]==NO)
			{
				[title_ drawInRect:tTitleFrame withAttributes:[BMLinearReportCell fileTitleAttributes]];
			}
			else
			{
				[title_ drawInRect:tTitleFrame withAttributes:[BMLinearReportCell whiteFileTitleAttributes]];
			}
		}
		
		// Notes, Errors, Warnings

#define CAPSULE_LEFT_MARGIN		1.0
		
#define CAPSULE_MIDDLE_MARGIN	5.0f
		
#define CAPSULE_RIGHT_MARGIN	1.0

#define CAPSULE_HEIGHT			14.0
		
		NSMutableArray * tArray;
		CGFloat tPartLength;
		BOOL tLeftRounded=NO;
		BOOL tRightRounded=NO;
		NSUInteger tCount;
		NSDictionary * tAttributesDictionary;
		
		tArray=[NSMutableArray array];
		
		tAttributesDictionary=[BMLinearReportCell attributesDictionary];
		
		tErrorTypes=0;
		
		tErrorsString=[BMLinearReportCell formattedNumber:errors_];
		
		tWarningString=[BMLinearReportCell formattedNumber:warnings_];
		
		tNotesString=[BMLinearReportCell formattedNumber:notes_];
		
		tCapsuleLength=CAPSULE_HEIGHT+CAPSULE_LEFT_MARGIN+CAPSULE_RIGHT_MARGIN;
		
		
		if (tErrorsString!=nil)
		{
			tPartLength=[tErrorsString sizeWithAttributes:tAttributesDictionary].width;
			
			[tArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:tErrorsString,@"String",
							   [NSNumber numberWithDouble:tPartLength],@"Length",
							   [NSColor colorWithCalibratedRed:1.0 green:31.0/255.0 blue:19.0/255.0 alpha:0.9f],@"Color",
							   nil]];
			
			tCapsuleLength+=(tPartLength+2*CAPSULE_MIDDLE_MARGIN);
		}
		
		if (tWarningString!=nil)
		{
			tPartLength=[tWarningString sizeWithAttributes:tAttributesDictionary].width;
			
			[tArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:tWarningString,@"String",
							   [NSNumber numberWithDouble:tPartLength],@"Length",
							   [NSColor colorWithCalibratedRed:1.0 green:152.0/255.0 blue:12.0/255.0 alpha:1.0f],@"Color",
							   nil]];
		
			tCapsuleLength+=(tPartLength+2*CAPSULE_MIDDLE_MARGIN);
		}
		
		if (tNotesString!=nil)
		{
			tPartLength=[tNotesString sizeWithAttributes:tAttributesDictionary].width;
			
			[tArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:tNotesString,@"String",
							   [NSNumber numberWithDouble:tPartLength],@"Length",
							   [NSColor colorWithCalibratedRed:83.0/255.0 green:137.0/255.0 blue:255.0/255.0 alpha:1.0f],@"Color",
							   nil]];
		
			tCapsuleLength+=(tPartLength+2*CAPSULE_MIDDLE_MARGIN);
		}
		
		tCapsuleLength-=2*CAPSULE_MIDDLE_MARGIN;
							 
		tFrame=NSMakeRect(NSMinX(inFrame)+44.0,NSMaxY(inFrame)-2.5-CAPSULE_HEIGHT,tCapsuleLength,CAPSULE_HEIGHT);
		
		tCount=[tArray count];
		
		if (tCount>0)
		{
			NSUInteger i=0;
			CGFloat tStartX;
			CGFloat tEndX;
			
			tEndX=NSMinX(inFrame)+44.0;
			
			for(NSDictionary * tSectionDictionary in tArray)
			{
				CGFloat tStringLength;
				NSString * tSectionString;
				NSColor * tColor;
				NSRect tStringRect;
				
				tSectionString=[tSectionDictionary objectForKey:@"String"];
				
				tStringLength=[[tSectionDictionary objectForKey:@"Length"] doubleValue];
				
				tColor=[tSectionDictionary objectForKey:@"Color"];
				
				tLeftRounded=(i==0);
				
				tRightRounded=(i==(tCount-1));
				
				tBezierPath=[NSBezierPath bezierPath];
				
				tStartX=tEndX;
				
				if (tLeftRounded==YES)
				{
					[tBezierPath moveToPoint:NSMakePoint(tStartX+CAPSULE_HEIGHT/2,NSMaxY(inFrame)-2.5-CAPSULE_HEIGHT)];
					
					[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tStartX+CAPSULE_HEIGHT/2,NSMaxY(inFrame)-2.5-CAPSULE_HEIGHT/2)
															radius:CAPSULE_HEIGHT/2
														startAngle:270
														  endAngle:90
														 clockwise:YES];
				
					tEndX+=(CAPSULE_HEIGHT/2+tStringLength+CAPSULE_LEFT_MARGIN);
					
					tStringRect=NSMakeRect(tStartX+CAPSULE_HEIGHT/2+CAPSULE_LEFT_MARGIN,NSMaxY(inFrame)-2.5-CAPSULE_HEIGHT,tStringLength,CAPSULE_HEIGHT);
				}
				else
				{
					[tBezierPath moveToPoint:NSMakePoint(tStartX,NSMaxY(inFrame)-2.5-CAPSULE_HEIGHT)];
					
					[tBezierPath lineToPoint:NSMakePoint(tStartX,NSMaxY(inFrame)-2.5)];
					
					tEndX+=(tStringLength+CAPSULE_MIDDLE_MARGIN);
					
					tStringRect=NSMakeRect(tStartX+CAPSULE_MIDDLE_MARGIN,NSMaxY(inFrame)-2.5-CAPSULE_HEIGHT,tStringLength,CAPSULE_HEIGHT);
				}
	
				if (tRightRounded==NO)
				{
					tEndX+=CAPSULE_MIDDLE_MARGIN;
					
					[tBezierPath lineToPoint:NSMakePoint(tEndX,NSMaxY(inFrame)-2.5)];
					
					[tBezierPath lineToPoint:NSMakePoint(tEndX,NSMaxY(inFrame)-2.5-CAPSULE_HEIGHT)];
				}
				else
				{
					tEndX+=CAPSULE_RIGHT_MARGIN;
					
					[tBezierPath lineToPoint:NSMakePoint(tEndX,NSMaxY(inFrame)-2.5)];
					
					[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tEndX,NSMaxY(inFrame)-2.5-CAPSULE_HEIGHT/2)
															radius:CAPSULE_HEIGHT/2
														startAngle:90
														  endAngle:-90
														 clockwise:YES];
				}
					
				[tBezierPath closePath];

				[tColor set];
				
				[tBezierPath fill];
				
				[tSectionString drawInRect:tStringRect withAttributes:tAttributesDictionary];
                
                i++;
			}
		}
		
		[[NSColor colorWithCalibratedWhite:0.65 alpha:1.0] set];
		
		tBezierPath=[NSBezierPath bezierPathWithRoundedRect:tFrame xRadius:CAPSULE_HEIGHT/2 yRadius:CAPSULE_HEIGHT/2];
		
		[tBezierPath stroke];
							 
							 
		/*tImage=[BMLinearReportCell errorIcon];
		
		if (tImage!=nil)
		{
			tFrame.size=NSMakeSize(12.0,12.0);
		
			tFrame.origin.x=NSMinX(inFrame)+44.0;
		
			tFrame.origin.y = NSMaxY(inFrame)-2.0;
		
			[tImage compositeToPoint:tFrame.origin operation:NSCompositeSourceOver];
		}*/
	}
	else
	{
		NSRect tFrame;
		
		if (icon_!=nil)
		{
			tFrame.size=NSMakeSize(12.0,12.0);
			
			tFrame.origin.y=NSMinY(inFrame);
			
			tFrame.origin.x=NSMinX(inFrame)+2.0;
			
			tFrame.origin.y = NSMinY(inFrame)+tFrame.size.height+2.0;//ceil((NSHeight(inFrame) + NSHeight(tFrame)) / 2);
			
			[icon_ compositeToPoint:tFrame.origin operation:NSCompositeSourceOver];
		}
		
		// Text
		
		if (title_!=nil)
		{
			NSRect tTitleFrame;
			
			tTitleFrame=inFrame;
			
			tTitleFrame.size.width-=22.0;
			
			tTitleFrame.size.height=NSHeight([title_ boundingRectWithSize:tTitleFrame.size options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:[BMLinearReportCell titleAttributes]]);
			
			//[BMLinearReportCell heightOfString:title_ forFont:[[BMLinearReportCell titleAttributes] objectForKey:NSFontAttributeName] andMaxWidth:NSWidth(inFrame)];
			
			tTitleFrame.origin=NSMakePoint(NSMinX(inFrame)+18.0,NSMinY(inFrame)+1.0);
			
			if ([self isHighlighted]==NO)
			{
				[title_ drawInRect:tTitleFrame withAttributes:[BMLinearReportCell titleAttributes]];
			}
			else
			{
				[title_ drawInRect:tTitleFrame withAttributes:[BMLinearReportCell whiteTitleAttributes]];
			}
			
			/*[[NSColor redColor] set];
			
			NSFrameRect(tTitleFrame);*/
		}
		
		// Description
		
		if (description_!=nil)
		{
			NSRect tDescriptionFrame;
			
			tDescriptionFrame=inFrame;
			
			tDescriptionFrame.size.width-=22.0;
			
			tDescriptionFrame.size.height=NSHeight([description_ boundingRectWithSize:tDescriptionFrame.size options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:[BMLinearReportCell descriptionAttributes]]);
			
			//[BMLinearReportCell heightOfString:description_ forFont:[[BMLinearReportCell titleAttributes] objectForKey:NSFontAttributeName] andMaxWidth:NSWidth(inFrame)];
			
			tDescriptionFrame.origin=NSMakePoint(NSMinX(inFrame)+18.0,NSMaxY(inFrame)-NSHeight(tDescriptionFrame)-2.0);
			
			if ([self isHighlighted]==NO)
			{
				if (highlightRange_.location==NSNotFound)
				{
					[description_ drawInRect:tDescriptionFrame withAttributes:[BMLinearReportCell descriptionAttributes]];
				}
				else
				{
					NSMutableAttributedString * tMutableAttributedDescription;
					
					tMutableAttributedDescription=[[NSMutableAttributedString alloc] initWithString:description_ attributes:[BMLinearReportCell descriptionAttributes]];
					
					if (tMutableAttributedDescription!=nil)
					{
						[tMutableAttributedDescription addAttribute:NSBackgroundColorAttributeName value:[NSColor colorWithCalibratedRed:0.5 green:1.0 blue:1.0 alpha:1.0] range:highlightRange_];
					
						[tMutableAttributedDescription drawInRect:tDescriptionFrame];
						
						[tMutableAttributedDescription release];
					}
				}

			}
			else
			{
				[description_ drawInRect:tDescriptionFrame withAttributes:[BMLinearReportCell whiteDescriptionAttributes]];
			}
			
			/*[[NSColor redColor] set];
			
			NSFrameRect(tDescriptionFrame);*/
		}
	}
}

+ (CGFloat) heightOfCellWithTitle:(NSString *) inTitle description:(NSString *) inDescription frameSize:(NSSize) inFrameSize
{
	CGFloat tHeight=2.0;
	
	inFrameSize.width-=22.0f;
	
	if (inTitle!=nil)
	{
		tHeight+=NSHeight([inTitle boundingRectWithSize:inFrameSize options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:[BMLinearReportCell titleAttributes]]);
		
		//tHeight+=[BMLinearReportCell heightOfString:inTitle forFont:[[BMLinearReportCell titleAttributes] objectForKey:NSFontAttributeName] andMaxWidth:inFrameSize.width];
	}
	
	if ([inDescription length]>0)
	{
		tHeight+=2.0;
		
		tHeight+=NSHeight([inDescription boundingRectWithSize:inFrameSize options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:[BMLinearReportCell descriptionAttributes]]);
		
		
		//tHeight+=[BMLinearReportCell heightOfString:inDescription forFont:[[BMLinearReportCell titleAttributes] objectForKey:NSFontAttributeName] andMaxWidth:inFrameSize.width];
	}
	
	tHeight+=2.0;
	
	return tHeight;
}

@end
