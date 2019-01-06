//
//  IVBaseDataModel.m
//  iVisit 3D
//
//  Created by Bob on 05/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVBaseDataModel.h"

@interface IVBaseDataModel ()

@property (nonatomic, strong) NSMutableDictionary *internalKeyValues;

@end

@implementation IVBaseDataModel

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _internalKeyValues = [[decoder decodeObjectForKey:@"internalKeyValues"] mutableCopy];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_internalKeyValues forKey:@"internalKeyValues"];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _internalKeyValues = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - KeyValueCoding

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    [self.internalKeyValues setValue:value forKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key {
    return [self.internalKeyValues valueForKey:key];
}

#pragma mark - NSDictionary Subclass

- (NSUInteger)count {
    return [self.internalKeyValues count];
}

- (id)objectForKey:(id)aKey {
    return [self.internalKeyValues objectForKey:aKey];
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key {
    return [self.internalKeyValues objectForKeyedSubscript:key];
}

- (NSEnumerator *)keyEnumerator {
    return [self.internalKeyValues keyEnumerator];
}

#pragma mark - NSMutableDictionary Subclass

- (void)setObject:(id)anObject forKey:(id < NSCopying >)aKey {
    [self.internalKeyValues setObject:anObject forKey:aKey];
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key {
    [self.internalKeyValues setObject:obj forKeyedSubscript:key];
}

- (void)removeObjectForKey:(id)aKey {
    [self.internalKeyValues removeObjectForKey:aKey];
}

@end
