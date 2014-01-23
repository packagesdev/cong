/*
Copyright (c) 2004-2009, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BMVersionSwitchView.h"

@implementation BMVersionSwitchView

- (id) initWithFrame:(NSRect) aFrame
{
    self=[super initWithFrame:aFrame];
    
    if (self!=nil)
    {
		_attributes=[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSColor colorWithDeviceWhite:0.498f alpha:1.0f],NSForegroundColorAttributeName,
																		[NSFont systemFontOfSize:13.0f],NSFontAttributeName,
																		nil];
    }
    
    return self;
}

- (void) dealloc
{
    [title_ release];
    
    [alternateTitle_ release];
    
    [_attributes release];
    
    [super dealloc];
}

#pragma mark -

- (NSString *) title
{
    return [[title_ retain] autorelease];
}

- (void) setTitle:(NSString *) inTitle
{
    if (title_!=inTitle)
    {
        [title_ release];
    
        title_=[inTitle copy];
    }
}

- (NSString *) alternateTitle
{
    return [[alternateTitle_ retain] autorelease];
}

- (void) setAlternateTitle:(NSString *) inAlternateTitle
{
    if (alternateTitle_!=inAlternateTitle)
    {
        [alternateTitle_ release];
    
        alternateTitle_=[inAlternateTitle copy];
    }
}

- (NSFont *) font
{
    return nil;
}

- (void) setFont:(NSFont *) inFont
{
	if (_attributes!=nil && inFont!=nil)
	{
		[_attributes setObject:inFont forKey:NSFontAttributeName];
	}
}

#pragma mark -

- (void)drawRect:(NSRect)rect
{
    NSString * tString;
	
    tString=title_;

    if ((state_==YES && _isPushed==NO) ||
        (_isPushed==YES && state_==NO))
    {
        tString=alternateTitle_;
    }
    
    if (tString!=nil)
    {
        NSSize tSize;
        
        tSize=[tString sizeWithAttributes:_attributes];
        
        if (tSize.width>0 && tSize.height>0)
        {
            NSPoint tPoint;
            
            tPoint.x=0.0f;
            tPoint.y=(NSHeight([self bounds])-tSize.height)*0.5f;
            
            // Draw String
            
            [tString drawAtPoint:tPoint withAttributes:_attributes];
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    _isPushed=YES;
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint tMouseLoc=[self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect tBounds=[self bounds];
    
    if (NSMouseInRect(tMouseLoc,tBounds,[self isFlipped])==YES)
    {
        if (_isPushed==NO)
        {
            _isPushed=YES;
            
            [self setNeedsDisplay:YES];
        }
    }
    else
    {
        if (_isPushed==YES)
        {
            _isPushed=NO;
            
            [self setNeedsDisplay:YES];
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint tMouseLoc=[self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect tBounds=[self bounds];
    
    _isPushed=NO;
    
    if (NSMouseInRect(tMouseLoc,tBounds,[self isFlipped])==YES)
    {
        state_=!state_;
        
        [self setNeedsDisplay:YES];
    }
}

@end
