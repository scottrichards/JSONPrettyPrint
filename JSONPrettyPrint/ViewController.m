//
//  ViewController.m
//  JSONPrettyPrint
//
//  Created by Scott Richards on 7/22/15.
//  Copyright (c) 2015 Scott Richards. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) NSString *prettyString;
@property (weak, nonatomic) IBOutlet UITextField *jsonURLField;
@property (weak, nonatomic) IBOutlet UIButton *prettyPrintButton;
@property (weak, nonatomic) IBOutlet UITextView *resultsTextView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self requestJSON:@"http://plickers-interview.herokuapp.com/polls"];
}

// make the async request for the JSON data at specified url
// urlAsString -> the url to make the request for JSON data
- (void)requestJSON:(NSString *)urlAsString
{
    NSURL *url = [[NSURL alloc] initWithString:urlAsString];
    NSLog(@"%@", urlAsString);
    
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:url] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            NSLog(@"Received an error: %@",error.description);
 //           _resultsTextView.text = @"Received an ERROR.  Make sure it is a valid url and you have an interent connection.";
        } else {
            [self parseJSONData:data];
        }
    }];
}

- (void)parseJSONData:(NSData *)data
{
    NSError *error = nil;
    _prettyString = @"";
    NSJSONReadingOptions options = NSJSONReadingMutableContainers;
    id object = [NSJSONSerialization JSONObjectWithData:data options:options error:&error];
    if (error) {
        NSLog(@"Error Parsing JSON Data");
    } else {
        if ([object isKindOfClass:[NSDictionary class]]) {
            [self parseJSONDictionary:(NSDictionary *)object depth:0];
        } else if ([object isKindOfClass:[NSArray class]]) {
            [self parseJSONArray:(NSArray *)object depth:0];
        }
        [self performSelectorOnMainThread:@selector(outputResults:) withObject:_prettyString waitUntilDone:0];
        NSLog(@"%@",_prettyString);
    }
}

// pretty print all of the items in the dictionary
// dictionary -> the dictionary of items to be printed
// depth -> increment when called to indicate how deeply we have recursed print this many tabs before outputing the items
- (void)parseJSONDictionary:(NSDictionary *)dictionary depth:(uint)depth
{
    [self parseJSONDictionary:dictionary depth:depth key:nil];
}


// pretty print all of the items in the dictionary
// dictionary -> the dictionary of items to be printed
// depth -> increment when called to indicate how deeply we have recursed print this many tabs before outputing the items
// key -> if specified this is the key corresponding to this dictionary print it before printing the dictionary as its value pair
- (void)parseJSONDictionary:(NSDictionary *)dictionary depth:(uint)depth key:(NSString *)key
{
    [self formatString:@"{" depth:depth];
    for (NSString *key in dictionary) {
        id value = dictionary[key];
        if ([value isKindOfClass:[NSString class]]) {
            NSString *outputStr = [NSString stringWithFormat:@"\"%@\" : \"%@\"",key,value];
            [self formatString:outputStr depth:depth];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber *number = value;
            NSString *outputStr = [NSString stringWithFormat:@"\"%@\" : %ld",key,(long)[number integerValue]];
            [self formatString:outputStr depth:depth];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            [self parseJSONDictionary:(NSDictionary *)value depth:depth+1 key:key];
        }  else if ([value isKindOfClass:[NSArray class]]) {
            [self parseJSONArray:(NSArray *)value depth:depth+1];
        }
    }
    [self formatString:@"}" depth:depth];
}


// pretty print all of the items in the array
// array -> the array of items to be printed
// depth -> increment when called to indicate how deeply we have recursed print this many tabs before outputing the items
- (void)parseJSONArray:(NSArray *)array depth:(uint)depth
{
    [self formatString:@"[" depth:depth];
    for (id object in array) {
        if ([object isKindOfClass:[NSString class]]) {
            NSString *outputStr = [NSString stringWithFormat:@"Value = %@",object];
            [self formatString:outputStr depth:depth];
        } else if ([object isKindOfClass:[NSNumber class]]) {
            NSNumber *number = object;
            NSString *outputStr = [NSString stringWithFormat:@"Value = %ld",(long)[number integerValue]];
            [self formatString:outputStr depth:depth];
        } else if ([object isKindOfClass:[NSDictionary class]]) {
            [self parseJSONDictionary:(NSDictionary *)object depth:depth+1];
        } else if ([object isKindOfClass:[NSArray class]]) {
            [self parseJSONArray:(NSArray *)object depth:depth+1];
        }
    }
    [self formatString:@"]" depth:depth];
}

- (NSString *)formatString:(NSString *)string depth:(uint)depth
{
    return [self formatString:string depth:depth key:nil];
}

- (NSString *)formatString:(NSString *)string depth:(uint)depth key:(NSString *)key
{
    NSString *tabs = @"";
    for (uint i=0;i<depth;i++) {
        tabs = [tabs stringByAppendingString:@"\t"];
    }
    NSString *formattedString;
    if (key!=nil)
        formattedString = [NSString stringWithFormat:@"%@ %@ : %@\n",tabs,key,string];
    else
        formattedString = [NSString stringWithFormat:@"%@%@\n",tabs,string];

    _prettyString = [_prettyString stringByAppendingString:formattedString];
    return formattedString;
}

- (void)outputResults:(NSString *)results
{
    [_resultsTextView setText:results];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
