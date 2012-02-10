//
//  GCCalendarView.h
//  iBeautify
//
//  Created by Caleb Davenport on 2/27/10.
//  Copyright 2010 GUI Cocoa Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GCCalendarProtocols.h"

@interface GCCalendarView : UIViewController {
	// data source
	id<GCCalendarDataSource> __unsafe_unretained dataSource;
	
	// delegate
	id<GCCalendarDelegate> __unsafe_unretained delegate;
}

@property (nonatomic, unsafe_unretained) id<GCCalendarDataSource> dataSource;
@property (nonatomic, unsafe_unretained) id<GCCalendarDelegate> delegate;

@end
