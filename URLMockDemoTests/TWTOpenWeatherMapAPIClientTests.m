//
//  TWTOpenWeatherMapAPIClientTests.m
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

@import XCTest;

#import <URLMock/URLMock.h>
#import "TWTOpenWeatherMapAPIClient.h"


@interface TWTOpenWeatherMapAPIClientTests : XCTestCase

@property (nonatomic, strong) TWTOpenWeatherMapAPIClient *APIClient;

- (NSURL *)temperatureURLWithLatitude:(NSNumber *)latitude longitude:(NSNumber *)longitude;

- (void)testFetchTemperatureForLatitudeLongitude;

- (void)testFetchTemperatureForLatitudeLongitudeCorrectData;
- (void)testFetchTemperatureForLatitudeLongitudeError;
- (void)testFetchTemperatureForLatitudeLongitudeMalformedData;

@end


@implementation TWTOpenWeatherMapAPIClientTests

+ (void)setUp
{
    [super setUp];
    [UMKMockURLProtocol enable];
    [UMKMockURLProtocol setVerificationEnabled:YES];
}


+ (void)tearDown
{
    [UMKMockURLProtocol setVerificationEnabled:NO];
    [UMKMockURLProtocol disable];
    [super tearDown];
}


- (void)setUp
{
    [super setUp];
    [UMKMockURLProtocol reset];
    self.APIClient = [[TWTOpenWeatherMapAPIClient alloc] init];
}


- (NSURL *)temperatureURLWithLatitude:(NSNumber *)latitude longitude:(NSNumber *)longitude
{
    return [NSURL umk_URLWithString:@"http://api.openweathermap.org/data/2.5/weather"
                         parameters:@{ @"lat" : latitude, @"lon" : longitude }];
}


- (NSError *)randomError
{
    return [NSError errorWithDomain:UMKRandomAlphanumericString()
                               code:random()
                           userInfo:UMKRandomDictionaryOfStringsWithElementCount(10)];
}


#pragma mark - Bad Tests

- (void)testFetchTemperatureForLatitudeLongitude
{
    [UMKMockURLProtocol disable];

    __block NSNumber *temperature = nil;
    [self.APIClient fetchTemperatureForLatitude:@35.99
                                      longitude:@-78.9
                                        success:^(NSNumber *kelvins) {
                                            temperature = kelvins;
                                        }
                                        failure:nil];

    // Assert that temperature != nil before 2 seconds elapse
    UMKAssertTrueBeforeTimeout(2.0, temperature != nil, @"temperature isn't set in time");

    [UMKMockURLProtocol enable];
}


#pragma mark - Good Tests

- (void)testFetchTemperatureForLatitudeLongitudeCorrectData
{
    NSNumber *latitude = @12.34;
    NSNumber *longitude = @-45.67;
    NSNumber *temperature = @289.82;

    NSURL *temperatureURL = [self temperatureURLWithLatitude:latitude longitude:longitude];
    UMKMockHTTPRequest *mockRequest = [UMKMockHTTPRequest mockHTTPGetRequestWithURL:temperatureURL];
    UMKMockHTTPResponder *mockResponder = [UMKMockHTTPResponder mockHTTPResponderWithStatusCode:200];
    [mockResponder setBodyWithJSONObject:@{ @"main" : @{ @"temp" : temperature } }];
    mockRequest.responder = mockResponder;

    [UMKMockURLProtocol expectMockRequest:mockRequest];

    __block BOOL succeeded = NO;
    __block BOOL failed = NO;
    __block NSNumber *kelvins = nil;
    [self.APIClient fetchTemperatureForLatitude:latitude
                                      longitude:longitude
                                        success:^(NSNumber *temperatureInKelvins) {
                                            succeeded = YES;
                                            kelvins = temperatureInKelvins;
                                        }
                                        failure:^(NSError *error) {
                                            failed = YES;
                                        }];

    UMKAssertTrueBeforeTimeout(1.0, succeeded, @"success block is not called");
    UMKAssertTrueBeforeTimeout(1.0, !failed, @"failure block is called");
    UMKAssertTrueBeforeTimeout(1.0, [kelvins isEqualToNumber:temperature], @"incorrect temperature");

    NSError *verificationError = nil;
    XCTAssertTrue([UMKMockURLProtocol verifyWithError:&verificationError], @"verification failed");
}


- (void)testFetchTemperatureForLatitudeLongitudeError
{
    NSNumber *latitude = @12.34;
    NSNumber *longitude = @-45.67;

    NSURL *temperatureURL = [self temperatureURLWithLatitude:latitude longitude:longitude];
    [UMKMockURLProtocol expectMockHTTPGetRequestWithURL:temperatureURL responseError:[self randomError]];

    __block BOOL succeeded = NO;
    __block BOOL failed = NO;
    [self.APIClient fetchTemperatureForLatitude:latitude
                                      longitude:longitude
                                        success:^(NSNumber *temperature) {
                                            succeeded = YES;
                                        }
                                        failure:^(NSError *error) {
                                            failed = YES;
                                        }];

    UMKAssertTrueBeforeTimeout(1.0, !succeeded, @"success block is called");
    UMKAssertTrueBeforeTimeout(1.0, failed, @"failure block is not called");

    NSError *verificationError = nil;
    XCTAssertTrue([UMKMockURLProtocol verifyWithError:&verificationError], @"verification failed");
}


- (void)testFetchTemperatureForLatitudeLongitudeMalformedData
{
    NSNumber *latitude = @12.34;
    NSNumber *longitude = @-45.67;

    NSURL *temperatureURL = [self temperatureURLWithLatitude:latitude longitude:longitude];
    [UMKMockURLProtocol expectMockHTTPGetRequestWithURL:temperatureURL
                                     responseStatusCode:200
                                           responseJSON:UMKRandomJSONObject(3, 3)];

    __block BOOL succeeded = NO;
    __block BOOL failed = NO;
    [self.APIClient fetchTemperatureForLatitude:latitude
                                      longitude:longitude
                                        success:^(NSNumber *temperature) {
                                            succeeded = YES;
                                        }
                                        failure:^(NSError *error) {
                                            failed = YES;
                                        }];

    UMKAssertTrueBeforeTimeout(1.0, !succeeded, @"success block is called");
    UMKAssertTrueBeforeTimeout(1.0, failed, @"failure block is not called");
}

@end
