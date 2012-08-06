//
//  GCCalendarDayView.m
//  GCCalendar
//
//	GUI Cocoa Common Code Library
//
//  Created by Caleb Davenport on 1/23/10.
//  Copyright GUI Cocoa Software 2010. All rights reserved.
//

#import "GCCalendarDayView.h"
#import "GCCalendarTile.h"
#import "GCCalendarView.h"
#import "GCCalendarEvent.h"
#import "GCCalendar.h"
#import "DateRange.h"

#define kTileLeftSide 52.0f
#define kTileRightSide 10.0f

#define kTopLineBuffer 11.0
#define kSideLineBuffer 50.0
#define kHalfHourDiff 22.0

static NSArray *timeStrings;

@interface GCCalendarAllDayView : UIView {
	NSArray *events;
}

- (id)initWithEvents:(NSArray *)a;
- (BOOL)hasEvents;

@end

@implementation GCCalendarAllDayView
- (id)initWithEvents:(NSArray *)a {
	if (self = [super init]) {
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"allDayEvent == YES"];
		events = [a filteredArrayUsingPredicate:pred];
		
		NSInteger eventCount = 0;
		for (GCCalendarEvent *e in events) {
			if (eventCount < 5) {
				GCCalendarTile *tile = [[GCCalendarTile alloc] init];
				tile.event = e;
				[self addSubview:tile];
				
				eventCount++;
			}
		}
	}
	
	return self;
}
- (BOOL)hasEvents {
	return ([events count] != 0);
}
- (CGSize)sizeThatFits:(CGSize)size {
	CGSize toReturn = CGSizeMake(0, 0);
	
	if ([self hasEvents]) {
		NSInteger eventsCount = ([events count] > 5) ? 5 : [events count];
		toReturn.height = (5 * 2) + (27 * eventsCount) + (eventsCount - 1);
	}
	
	return toReturn;
}
- (void)layoutSubviews {
	CGFloat start_y = 5.0f;
	CGFloat height = 27.0f;
	
	for (UIView *view in self.subviews) {
		// get calendar tile and associated event
		GCCalendarTile *tile = (GCCalendarTile *)view;
		
		tile.frame = CGRectMake(kTileLeftSide,
								start_y,
								self.frame.size.width - kTileLeftSide - kTileRightSide,
								height);
		
		start_y += (height + 1);
	}
}
- (void)drawRect:(CGRect)rect {
	// grab current graphics context
	CGContextRef g = UIGraphicsGetCurrentContext();
	
	// fill white background
	CGContextSetRGBFillColor(g, 1.0, 1.0, 1.0, 1.0);
	CGContextFillRect(g, self.frame);
	
	// draw border line
	CGContextMoveToPoint(g, 0, self.frame.size.height);
	CGContextAddLineToPoint(g, self.frame.size.width, self.frame.size.height);
	
	// draw all day text
	UIFont *numberFont = [UIFont boldSystemFontOfSize:12.0];
	[[UIColor blackColor] set];
	NSString *text = [[NSBundle mainBundle] localizedStringForKey:@"ALL_DAY" value:@"" table:@"GCCalendar"];
	CGRect textRect = CGRectMake(6, 10, 40, [text sizeWithFont:numberFont].height);
	[text drawInRect:textRect withFont:numberFont];
	
	// stroke the path
	CGContextStrokePath(g);
}
@end

@interface GCCalendarTodayView : UIView {
	NSArray *events;
}

@property (nonatomic, strong) DateRange* prevRange;

- (id)initWithEvents:(NSArray *)a;
- (BOOL)hasEvents;
+ (CGFloat)yValueForTime:(CGFloat)time;

@end

@implementation GCCalendarTodayView {
@private
    DateRange* _prevRange;
}

@synthesize prevRange = _prevRange;

- (id)initWithEvents:(NSArray *)a {
	if (self = [super init]) {
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"allDayEvent == NO"];
		events = [a filteredArrayUsingPredicate:pred];
		
		for (GCCalendarEvent *e in events) {
			GCCalendarTile *tile = [[GCCalendarTile alloc] init];
			tile.event = e;
			[self addSubview:tile];
		}
	}
	
	return self;
}
- (BOOL)hasEvents {
	return ([events count] != 0);
}

NSComparisonResult dateSortForTiles(UIView* view1, UIView*  view2, void *context) {

    GCCalendarTile *tile1 = (GCCalendarTile *)view1;
    GCCalendarTile *tile2 = (GCCalendarTile *)view2;

    NSDate *d1 = tile1.event.startDate;
    NSDate *d2 = tile2.event.startDate;
    return [d1 compare:d2];
}

- (NSArray* ) groupedEvents{

    CGFloat width = self.bounds.size.width - kTileLeftSide - kTileRightSide;

    int groupKey = 0;
    NSMutableDictionary* dicGroups = [NSMutableDictionary dictionary];
    NSMutableArray* currentGroupEvents = [NSMutableArray array];

    NSMutableArray *sortedSubviews = [[NSMutableArray alloc] initWithArray:[self.subviews sortedArrayUsingFunction:dateSortForTiles context:nil]];

    for (UIView *view in sortedSubviews) {
        GCCalendarTile *tile = (GCCalendarTile *)view;
        DateRange* currentRange = [[DateRange alloc] init];
        currentRange.fromDate = tile.event.startDate;
        currentRange.toDate = tile.event.endDate;

        if ([self.prevRange intersectsRange:currentRange]) {
            [currentGroupEvents addObject:tile];
        }
        else {
            if (self.prevRange != nil) {
                [dicGroups setObject:currentGroupEvents forKey:[NSNumber numberWithInt:groupKey]];
                currentGroupEvents = [NSMutableArray array];
                [currentGroupEvents addObject:tile];
                groupKey++;
            }
            else {
                [currentGroupEvents addObject:tile];
            }
        }

        self.prevRange = currentRange;

        if ([view isEqual:[sortedSubviews lastObject]]){
            [dicGroups setObject:currentGroupEvents forKey:[NSNumber numberWithInt:groupKey]];
        }
    }

    NSMutableArray* result = [NSMutableArray array];
    for (int i = 0; i < [dicGroups count]; i++) {
        NSMutableArray* currGroupEvents = [dicGroups objectForKey:[NSNumber numberWithInt:i]];
        for (int j = 0; j < [currGroupEvents count]; j++) {
            GCCalendarTile* currTile = [currGroupEvents objectAtIndex:j];
            currTile.event.width = width/[currGroupEvents count];
            currTile.event.startOffset = currTile.event.width*j;
            [result addObject:currTile];
        }
    }
    return result;
};


- (void)layoutSubviews {

    for (GCCalendarTile* tile in [self groupedEvents]) {

		NSDateComponents *components;
		components = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:tile.event.startDate];
		NSInteger startHour = [components hour];
		NSInteger startMinute = [components minute];
		
		components = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:tile.event.endDate];
		NSInteger endHour = [components hour];
		NSInteger endMinute = [components minute];

		CGFloat startPos = kTopLineBuffer + startHour * 2 * kHalfHourDiff - 2;
		startPos += (startMinute / 60.0) * (kHalfHourDiff * 2.0);
		startPos = floor(startPos);

		CGFloat endPos = kTopLineBuffer + endHour * 2 * kHalfHourDiff + 3;
		endPos += (endMinute / 60.0) * (kHalfHourDiff * 2.0);
		endPos = floor(endPos);

		tile.frame = CGRectMake(kTileLeftSide + tile.event.startOffset, startPos, tile.event.width, endPos - startPos);
	}
}

- (void)drawRect:(CGRect)rect {
    // grab current graphics context
	CGContextRef g = UIGraphicsGetCurrentContext();
	
	CGContextSetRGBFillColor(g, (242.0 / 255.0), (242.0 / 255.0), (242.0 / 255.0), 1.0);
	
	// fill morning hours light grey
	CGFloat morningHourMax = [GCCalendarTodayView yValueForTime:(CGFloat)8];
	CGRect morningHours = CGRectMake(0, 0, self.frame.size.width, morningHourMax - 1);	
	CGContextFillRect(g, morningHours);

	// fill evening hours light grey
	CGFloat eveningHourMax = [GCCalendarTodayView yValueForTime:(CGFloat)20];
	CGRect eveningHours = CGRectMake(0, eveningHourMax - 1, self.frame.size.width, self.frame.size.height - eveningHourMax + 1);
	CGContextFillRect(g, eveningHours);
	
	// fill day hours white
	CGContextSetRGBFillColor(g, 1.0, 1.0, 1.0, 1.0);
	CGRect dayHours = CGRectMake(0, morningHourMax - 1, self.frame.size.width, eveningHourMax - morningHourMax);
	CGContextFillRect(g, dayHours);
	
	// draw hour lines
	CGContextSetShouldAntialias(g, NO);
	const CGFloat solidPattern[2] = {1.0, 0.0};
	CGContextSetRGBStrokeColor(g, 0.0, 0.0, 0.0, .3);
	CGContextSetLineDash(g, 0, solidPattern, 2);
	for (NSInteger i = 0; i < 25; i++) {
		CGFloat yVal = [GCCalendarTodayView yValueForTime:(CGFloat)i];
		CGContextMoveToPoint(g, kSideLineBuffer, yVal);
		CGContextAddLineToPoint(g, self.frame.size.width, yVal);
	}
	CGContextStrokePath(g);
	
	// draw half hour lines
	CGContextSetShouldAntialias(g, NO);
	const CGFloat dashPattern[2] = {1.0, 1.0};
	CGContextSetRGBStrokeColor(g, 0.0, 0.0, 0.0, .2);
	CGContextSetLineDash(g, 0, dashPattern, 2);
	for (NSInteger i = 0; i < 24; i++) {
		CGFloat time = (CGFloat)i + 0.5f;
		CGFloat yVal = [GCCalendarTodayView yValueForTime:time];
		CGContextMoveToPoint(g, kSideLineBuffer, yVal);
		CGContextAddLineToPoint(g, self.frame.size.width, yVal);
	}
	CGContextStrokePath(g);
	
	// draw hour numbers
	CGContextSetShouldAntialias(g, YES);
	[[UIColor blackColor] set];
	UIFont *numberFont = [UIFont boldSystemFontOfSize:14.0];
	for (NSInteger i = 0; i < 25; i++) {
		CGFloat yVal = [GCCalendarTodayView yValueForTime:(CGFloat)i];
		NSString *number = [timeStrings objectAtIndex:i];
		CGSize numberSize = [number sizeWithFont:numberFont];
		if(i == 12) {
			[number drawInRect:CGRectMake(kSideLineBuffer - 7 - numberSize.width, 
										  yVal - floor(numberSize.height / 2) - 1,
										  numberSize.width,
										  numberSize.height)
					  withFont:numberFont
				 lineBreakMode:UILineBreakModeTailTruncation
					 alignment:UITextAlignmentRight];
		} else {
			[number drawInRect:CGRectMake(0, 
										  yVal - floor(numberSize.height / 2) - 1,
										  kSideLineBuffer - 18 - 10,
										  numberSize.height)
					  withFont:numberFont
				 lineBreakMode:UILineBreakModeTailTruncation
					 alignment:UITextAlignmentRight];
		}
	}
	
	// draw am / pm text
	CGContextSetShouldAntialias(g, YES);
	[[UIColor grayColor] set];
	UIFont *textFont = [UIFont systemFontOfSize:12.0];
	for (NSInteger i = 0; i < 25; i++) {
		NSString *text = nil;
		if (i < 12) {
			text = @"AM";
		}
		else if (i > 12) {
			text = @"PM";
		}
		if (i != 12) {
			CGFloat yVal = [GCCalendarTodayView yValueForTime:(CGFloat)i];
			CGSize textSize = [text sizeWithFont:textFont];
			[text drawInRect:CGRectMake(kSideLineBuffer - 7 - textSize.width,
										yVal - (textSize.height / 2),
										textSize.width, 
										textSize.height)
					withFont:textFont];
		}
	}
}
+ (CGFloat)yValueForTime:(CGFloat)time {
	return kTopLineBuffer + (44.0f * time);;
}
@end

@implementation GCCalendarDayView

@synthesize date;

#pragma mark create and destroy view
+ (void)initialize {
	if(self == [GCCalendarDayView class]) {
		timeStrings = [NSArray arrayWithObjects:@"12",
						@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11",
						[[NSBundle mainBundle] localizedStringForKey:@"NOON" value:@"" table:@"GCCalendar"],
						@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", nil];
	}
}
- (id)initWithCalendarView:(GCCalendarView *)view {
	if (self = [super init]) {
		dataSource = view.dataSource;
	}
	
	return self;
}
- (void)reloadData {
	// get new events for date
	events = [dataSource calendarEventsForDate:date];
	
	// drop all subviews
	[self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	
	// create all day view
	allDayView = [[GCCalendarAllDayView alloc] initWithEvents:events];
	[allDayView sizeToFit];
	allDayView.frame = CGRectMake(0, 0, self.frame.size.width, allDayView.frame.size.height);
	allDayView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self addSubview:(UIView *)allDayView];
	
	// create scroll view
	scrollView = [[UIScrollView alloc] init];
	scrollView.backgroundColor = [UIColor colorWithRed:(242.0 / 255.0) green:(242.0 / 255.0) blue:(242.0 / 255.0) alpha:1.0];
	scrollView.frame = CGRectMake(0, allDayView.frame.size.height, self.frame.size.width,
								  self.frame.size.height - allDayView.frame.size.height);
	scrollView.contentSize = CGSizeMake(self.frame.size.width, 1078);
	scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	[self addSubview:scrollView];
	
	// create today view
	todayView = [[GCCalendarTodayView alloc] initWithEvents:events];
	todayView.frame = CGRectMake(0, 0, self.frame.size.width, 1078);
	todayView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[scrollView addSubview:todayView];
}
- (void)setContentOffset:(CGPoint)p {
	scrollView.contentOffset = p;
}
- (CGPoint)contentOffset {
	return scrollView.contentOffset;
}

@end