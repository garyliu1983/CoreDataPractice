//
//  UULocalStore.m
//  CoreDataPractice
//
//  Created by Gary&Amanda on 3/10/15.
//  Copyright (c) 2015 uniqueu. All rights reserved.
//

#import "UULocalStore.h"
#import "Book.h"

@interface UULocalStore()

@property (nonatomic, strong) NSManagedObjectContext *workContext;
@property (nonatomic, strong) NSManagedObjectContext *storeContext;

@end

@implementation UULocalStore {
    NSPersistentStoreCoordinator *_psc;
    NSManagedObjectModel *_model;
}

+ (instancetype) sharedLocalStore {
    static UULocalStore *sharedLocalStore;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLocalStore = [[UULocalStore alloc] init];
    });
    
    return sharedLocalStore;
}

- (instancetype) init {
    self = [super init];
    if(self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mocDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) mocDidSave:(NSNotification *)notification {
    NSManagedObjectContext *sender = (NSManagedObjectContext *)notification.object;
    if(sender == [self storeContext]) return;
    if(sender == [self workContext]) {
        NSError *error = nil;
        [[self mainContext] save:&error];
        if(error) {
            NSLog(@"main context save error %@",error);
        }
        [[self storeContext] save:&error];
        if(error) {
            NSLog(@"store context save error %@",error);
        }
    }
    if(sender == [self mainContext]) {
        NSError *error = nil;
        [[self storeContext] save:&error];
        if(error) {
            NSLog(@"store context save error %@",error);
        }
    }
    
}

- (void) loadBooks {
    if([[NSThread currentThread] isMainThread] == YES) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self loadBooks];
        });
        return;
    }
    
    NSURL *booksURL = [[NSBundle mainBundle] URLForResource:@"Books" withExtension:@"json"];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:booksURL] options:0 error:nil];
    NSArray *books = dic[@"Books"];
    for(NSDictionary *book in books) {
        NSString *title = book[@"Title"];
        NSString *author = book[@"Author"];
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Book"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"author = %@ and title = %@",author,title];
        
        NSArray *results = [[self workContext] executeFetchRequest:fetchRequest error:nil];
        Book *bookMO = nil;
        if(results.count > 0) {
            //update
            bookMO = results.lastObject;

        }else {
            bookMO = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:[self workContext]];
            
        }
        bookMO.author = author;
        bookMO.title = title;
        
        
    }
    [[self workContext] save:nil];
}


- (NSManagedObjectContext *) workContext {
    if(_workContext == nil) {
        _workContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _workContext.parentContext = [self mainContext];
    }
    return _workContext;
}

- (NSManagedObjectContext *) mainContext {
    if(_mainContext == nil) {
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainContext.parentContext = [self storeContext];
        
    }
    return _mainContext;
}

- (NSManagedObjectContext *) storeContext {
    if(_storeContext == nil) {
        _storeContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _storeContext.persistentStoreCoordinator = [self persistentStoreCoodinator];
    }
    return _storeContext;
}

- (NSPersistentStoreCoordinator *) persistentStoreCoodinator {
    if(_psc == nil) {
        _psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self dataModel]];
        NSError *error = nil;
        NSURL *storeURL = [[self docDirectory] URLByAppendingPathComponent:@"Library.sqlite"];
        [_psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
    }
    return _psc;
}

- (NSManagedObjectModel *) dataModel {
    if(_model == nil) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Library" withExtension:@"momd"];
        _model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _model;
}

- (NSURL *) docDirectory {
   return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
