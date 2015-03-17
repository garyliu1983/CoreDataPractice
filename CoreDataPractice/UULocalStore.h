//
//  UULocalStore.h
//  CoreDataPractice
//
//  Created by Gary&Amanda on 3/10/15.
//  Copyright (c) 2015 uniqueu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UULocalStore : NSObject

@property (nonatomic, strong) NSManagedObjectContext *mainContext;


+ (instancetype) sharedLocalStore;
- (void) loadBooks;

@end
