//
//  GCCalendarEvent.m
//  GCCalendar
//
//	GUI Cocoa Common Code Library
//
//  Created by Caleb Davenport on 1/23/10.
//  Copyright GUI Cocoa Software 2010. All rights reserved.
//

#import "GCCalendarEvent.h"

@implementation GCCalendarEvent {
@private
    CGFloat _startOffset;
    CGFloat _width;
}


@synthesize eventName;
@synthesize eventDescription;
@synthesize startDate;
@synthesize endDate;
@synthesize allDayEvent;
@synthesize color;
@synthesize userInfo;
@synthesize startOffset = _startOffset;
@synthesize width = _width;


- (id)init {
	if (self = [super init]) {
		self.color = @"GREY";
	}
	
	return self;
}


@end
