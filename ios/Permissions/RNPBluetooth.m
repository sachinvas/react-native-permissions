//
//  RNPBluetooth.m
//  ReactNativePermissions
//
//  Created by Yonah Forst on 11/07/16.
//  Copyright © 2016 Yonah Forst. All rights reserved.
//

#import "RNPBluetooth.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface RNPBluetooth() <CBCentralManagerDelegate>
@property (class) CBCentralManager* centralManager;
@property (copy) void (^completionHandler)(NSString *);
@end

@implementation RNPBluetooth

static CBCentralManager * _centralManager;

+ (CBCentralManager *)centralManager {
    return _centralManager;
}

+ (void)setCentralManager:(CBCentralManager *)centralManager {
    _centralManager = centralManager;
}

+ (NSString *)getStatus
{
    int status = self.centralManager.state;
    switch (status) {
        case CBCentralManagerStatePoweredOn:
            return RNPStatusAuthorized;
        case CBCentralManagerStatePoweredOff:
            return RNPStatusDenied;
        case CBCentralManagerStateUnauthorized:
            return RNPStatusRestricted;
        default:
            return RNPStatusUndetermined;
    }
}

- (void)request:(void (^)(NSString *))completionHandler
{
    NSString *status = [RNPBluetooth getStatus];
    
    if (status == RNPStatusUndetermined) {
        self.completionHandler = completionHandler;
        self.class.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    } else {
        completionHandler(status);
    }
}

- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    if (self.class.centralManager && [self.class getStatus] != RNPStatusUndetermined) {
        self.class.centralManager.delegate = nil;
        self.class.centralManager = nil;
    }
    
    if (self.completionHandler) {
        //for some reason, checking permission right away returns denied. need to wait a tiny bit
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.completionHandler([self.class getStatus]);
            self.completionHandler = nil;
        });
    }
}

@end
