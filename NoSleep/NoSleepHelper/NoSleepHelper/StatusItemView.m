//
//  StatusItemView.m
//  nosleep
//
//  Created by Pavel Prokofiev on 4/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StatusItemView.h"

#define StatusItemViewPaddingWidth 4
#define StatusItemViewPaddingHeight 3
#define StatusItemViewPaddingIconToText 3

@implementation StatusItemView

@synthesize inactiveImage;
@synthesize activeImage;
@synthesize isBWIconEnabled;
@synthesize statusItem;
@synthesize target;
@synthesize mouseDownSelector;
@synthesize rightMouseDownSelector;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        statusItem = nil;
        title = nil;
        //icon=nil;
        isMenuVisible = NO;
        
        imageState = NO;
        buttonCell = [[NSButtonCell alloc] init];
        [buttonCell setBezelStyle:NSTexturedSquareBezelStyle];
        [buttonCell setButtonType:NSToggleButton];
        
        inactiveImage = nil;
        activeImage = nil;
        isBWIconEnabled = YES;
    }
    return self;
}

- (void)dealloc {
    //[icon release];
    [buttonCell release];
    [statusItem release];
    [title release];
    [super dealloc];
}

- (void)mouseDown:(NSEvent *)event {
    if(mouseDownSelector != nil)
    {
        [target performSelector:mouseDownSelector withObject:event];
    }
}

- (void)rightMouseDown:(NSEvent *)event {
    if(rightMouseDownSelector != nil)
    {
        [target performSelector:rightMouseDownSelector withObject:event];
    }
    
    [[self menu] setDelegate:self];
    [statusItem popUpStatusItemMenu:[self menu]];
    [self setNeedsDisplay:YES];
}

- (void) setEnabled:(BOOL)newEnabled
{
    isEnabled=newEnabled;
    [self setNeedsDisplay:YES];
}

- (BOOL)enabled
{
    return isEnabled;
}

- (void) setTarget:(id)newTarget
{
    if (![newTarget isEqual:target])
    {
        [newTarget retain];
        [target release];
        target=newTarget;
    }
}

- (void)menuWillOpen:(NSMenu *)menu {
    isMenuVisible = YES;
    [self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
    isMenuVisible = NO;
    [menu setDelegate:nil];
    [self setNeedsDisplay:YES];
}

- (NSColor *)titleForegroundColor {
    if (isMenuVisible) {
        return [NSColor whiteColor];
    }
    else {
        return [NSColor blackColor];
    }
}

- (NSDictionary *)titleAttributes {
    // Use default menu bar font size
    NSFont *font = [NSFont menuBarFontOfSize:0];
    
    NSColor *foregroundColor = [self titleForegroundColor];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            font, NSFontAttributeName,
            foregroundColor, NSForegroundColorAttributeName,
            nil];
}

- (NSRect)titleBoundingRect {
    return [title boundingRectWithSize:NSMakeSize(1e100, 1e100)
                               options:0
                            attributes:[self titleAttributes]];
}

- (void) calculateWidth
{
    int newWidth= 0;
    
    if ((title != NULL) || ([buttonCell image] != NULL))
        newWidth += (2 * StatusItemViewPaddingWidth);
    if ((title != NULL) && ([buttonCell image] != NULL))
        newWidth += StatusItemViewPaddingIconToText;
    
    if (title != NULL)
    {
        // Update status item size (which will also update this view's bounds)
        NSRect titleBounds = [self titleBoundingRect];
        newWidth += titleBounds.size.width;
    }
    if ([buttonCell image]!=NULL)
    {
        NSRect iconRect = [[buttonCell image] alignmentRect];
        newWidth += iconRect.size.width;// + 8
    }
    [statusItem setLength:newWidth];
}

- (void)setTitle:(NSString *)newTitle {
    if (![title isEqual:newTitle]) {
        [newTitle retain];
        [title release];
        title = newTitle;
        [self calculateWidth];
        [self setNeedsDisplay:YES];
    }
}

- (NSString *)title {
    return title;
}

- (void)setImage:(NSImage*)newIcon
{
    if (![newIcon isEqual:[buttonCell image]])
    {
        //[newIcon retain];
        //[icon release];
        //icon=newIcon;
        [buttonCell setImage:newIcon];
        [self calculateWidth];
        [self setNeedsDisplay:YES];
    }
}

- (NSImage *)image {
    return [buttonCell image];
}

- (void)setImageState:(BOOL)state
{
    NSInteger newState;
    if(state)
    {
        newState = NSOnState;
    }
    else
    {
        newState = NSOffState;
    }
    
    if([buttonCell state] != newState)
    {
        [buttonCell setState:newState];
        [self calculateWidth];
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)imageState
{
    return [buttonCell state] == NSOnState;
}

- (void)drawRect:(NSRect)rect {
    // Draw status bar background, highlighted if menu is showing
    [statusItem drawStatusBarBackgroundInRect:[self bounds]
                                withHighlight:isMenuVisible];
    
    int x=0;
    
    NSImage *image;
    if(isBWIconEnabled) {
        image = [buttonCell state] ? activeImage : inactiveImage;
    } else {
        image = [buttonCell image];
    }
    
    if ((image != NULL) || (title != NULL))
    {
        x += StatusItemViewPaddingWidth;
    }
    if (image != NULL)
    {
        if(isBWIconEnabled) {
            NSPoint origin = NSMakePoint(x, StatusItemViewPaddingHeight);
            [image drawAtPoint:origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];            
        } else {
            NSRect rect = [[buttonCell image] alignmentRect];
            rect.size.width += 8;
            rect.size.height += StatusItemViewPaddingHeight;
            [buttonCell drawInteriorWithFrame:rect inView:self];
        }
        x += rect.size.width;
    }
    if ((image != NULL) && (title != NULL))
    {
        x += StatusItemViewPaddingIconToText;
    }
    
    if (title != NULL)
    {
        // Draw title string
        NSPoint origin = NSMakePoint(x, StatusItemViewPaddingHeight);
        [title drawAtPoint:origin withAttributes:[self titleAttributes]];
    }
}

@end
