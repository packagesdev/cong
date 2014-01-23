/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMCheckAgainButton.h"

@implementation BMCheckAgainButtonCell

- (void) dealloc
{
	[arrowImage_ release];
	
	[super dealloc];
}

- (void) drawWithFrame:(NSRect) inFrame inView:(NSView *) inView
{
	NSBezierPath * tBezierPath;
	NSGradient * tGradient;
	NSRect tFrame;
	
	if (arrowImage_==nil)
	{
		arrowImage_=[[NSImage imageNamed:@"RecheckArrow"] copy];
		
		if (arrowImage_!=nil)
		{
			NSSize tSize;
			
			[arrowImage_ setFlipped:YES];
			
			tSize=[arrowImage_ size];
		
			targetRect_=NSMakeRect(round(NSMidX(inFrame)-tSize.width*0.5),round(NSMidY(inFrame)-tSize.height*0.5)-3,tSize.width,tSize.height);
		}
	}
	
	tFrame=NSInsetRect(inFrame, 1.0f, 1.0);
	
	tBezierPath=[NSBezierPath bezierPathWithOvalInRect:tFrame];
	
	if (tBezierPath!=nil)
	{
		if ([self isEnabled]==YES)
		{
			if ([self isHighlighted]==NO)
			{
				tFrame.origin.y-=1.0;
				
				tGradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.91 alpha:1.0] 
														endingColor:[NSColor colorWithDeviceWhite:0.82 alpha:1.0]];
			}
			else
			{
				tFrame.origin.y+=1.5;
				
				tGradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.81 alpha:1.0] 
														endingColor:[NSColor colorWithDeviceWhite:0.69 alpha:1.0]];
			}
			
			[tGradient drawInBezierPath:tBezierPath angle:90];
			
			[tGradient release];
		}
		else
		{
			tFrame.origin.y-=1.0;
			
			[[NSColor colorWithDeviceWhite:0.92 alpha:1.0] set];
			 
			[tBezierPath stroke];
		}
	}
	
	tFrame=NSInsetRect(tFrame, 1.5, 1.5);
	
	
	
	tBezierPath=[NSBezierPath bezierPathWithOvalInRect:tFrame];
	
	if (tBezierPath!=nil)
	{
		if ([self isEnabled]==YES)
		{
			if ([self isHighlighted]==NO)
			{
				tGradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.999 alpha:1.0] 
														endingColor:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
			}
			else
			{
				tGradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.98 alpha:1.0] 
														endingColor:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
			}
			
			[tGradient drawInBezierPath:tBezierPath angle:90];
			
			[tGradient release];
		}
	}
	
	if (arrowImage_!=nil)
	{
		CGFloat tAlpha;
		
		if ([self isEnabled]==YES)
		{
			if ([self isHighlighted]==NO)
			{
				tAlpha=0.54;
			}
			else
			{
				tAlpha=1.0;
			}
		}
		else
		{
			tAlpha=0.075;
		}
		
		[arrowImage_ drawInRect:targetRect_ fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:tAlpha];
		
	}
	//[self drawInteriorWithFrame:inFrame inView:inView];
}

@end

@implementation BMCheckAgainButton

+ (Class) cellClass
{
	return [BMCheckAgainButtonCell class];
}

@end
