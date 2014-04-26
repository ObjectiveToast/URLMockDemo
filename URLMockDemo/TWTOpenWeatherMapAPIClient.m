//
//  TWTOpenWeatherMapAPIClient.m
//  URLMockDemo
//
//  Created by Prachi Gauriar on 4/19/2014.
//  Copyright (c) 2014 Two Toasters.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "TWTOpenWeatherMapAPIClient.h"
#import <AFNetworking/AFNetworking.h>

static NSString *const kAPIBaseURLString = @"http://api.openweathermap.org/data/2.5";

@interface TWTOpenWeatherMapAPIClient ()
@property (nonatomic, strong) AFHTTPRequestOperationManager *operationManager;
@end


@implementation TWTOpenWeatherMapAPIClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:kAPIBaseURLString]];
        _operationManager.requestSerializer = [AFJSONRequestSerializer serializer];
    }

    return self;
}


- (void)dealloc
{
    [_operationManager.operationQueue cancelAllOperations];
}


- (NSOperation *)fetchTemperatureForLatitude:(NSNumber *)latitude
                                   longitude:(NSNumber *)longitude
                                     success:(void (^)(NSNumber *))successBlock
                                     failure:(void (^)(NSError *))failureBlock
{
    NSParameterAssert(latitude && ABS(latitude.doubleValue) <= 90.0);
    NSParameterAssert(longitude && ABS(longitude.doubleValue) <= 180.0);

    return [self.operationManager GET:@"weather"
                           parameters:@{ @"lat" : latitude, @"lon" : longitude }
                              success:^(AFHTTPRequestOperation *operation, id response) {
                                  if (successBlock) {
                                      successBlock([response valueForKeyPath:@"main.temp"]);
                                  }
                              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                  if (failureBlock) {
                                      failureBlock(error);
                                  }
                              }];
}


@end
