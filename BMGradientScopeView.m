/*
 Copyright (c) 2004-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMGradientScopeView.h"

@implementation BMGradientScopeView

- (id) initWithFrame:(NSRect) inFrame
{
	self=[super initWithFrame:inFrame];
	
	if (self!=nil)
	{
		gradient_=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.8f alpha:1.0f] 
												endingColor:[NSColor colorWithDeviceWhite:0.9f alpha:1.0f]];
	}
	
	return self;
}

- (void) dealloc
{
	[gradient_ release];
	
	[super dealloc];
}

#pragma mark -

- (BOOL) isOpaque
{
	return YES;
}

- (void) drawRect:(NSRect) inRect
{
	NSRect tBounds;
	
	tBounds=[self bounds];
	
	[gradient_ drawInRect:inRect angle:90.0f];
	
	[[NSColor grayColor] set];
	
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(inRect), NSMaxY(tBounds)) toPoint:NSMakePoint(NSMaxX(inRect), NSMaxY(tBounds))];
	
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(inRect), NSMinY(tBounds)) toPoint:NSMakePoint(NSMaxX(inRect), NSMinY(tBounds))];
}

@end
