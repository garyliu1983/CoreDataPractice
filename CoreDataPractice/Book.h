//
//  Book.h
//  CoreDataPractice
//
//  Created by Gary&Amanda on 3/10/15.
//  Copyright (c) 2015 uniqueu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Book : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * author;

@end
