//
//  ViewController.m
//  YouTubeComments
//
//  Created by Dalton on 7/9/15.
//  Copyright (c) 2015 Dalton. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <NSXMLParserDelegate, UITableViewDataSource, UITableViewDelegate>


@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableArray *commentsDataArray;
@property (nonatomic, strong) NSMutableDictionary *dictTempDataStorage;
@property (nonatomic, strong) NSMutableString *foundValue;
@property (nonatomic, strong) NSString *currentElement;
@property (weak, nonatomic) IBOutlet UITableView *TableView;
@property (weak, nonatomic) IBOutlet UIButton *viewCommentsButton;
@property (weak, nonatomic) IBOutlet YTPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *hideCommentsButton;

@end

/*
 * Utils: Add this section before your class implementation
 */

/**
 This creates a new query parameters string from the given NSDictionary. For
 example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
 string will be @"day=Tuesday&month=January".
 @param queryParameters The input dictionary.
 @return The created parameters string.
 */
static NSString* NSStringFromQueryParameters(NSDictionary* queryParameters)
{
    NSMutableArray* parts = [NSMutableArray array];
    [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *part = [NSString stringWithFormat: @"%@=%@",
                          [key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
                          [value stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                          ];
        [parts addObject:part];
    }];
    return [parts componentsJoinedByString: @"&"];
}

/**
 Creates a new URL by adding the given query parameters.
 @param URL The input URL.
 @param queryParameters The query parameter dictionary to add.
 @return A new NSURL.
 */
static NSURL* NSURLByAppendingQueryParameters(NSURL* URL, NSDictionary* queryParameters)
{
    NSString* URLString = [NSString stringWithFormat:@"%@?%@",
                           [URL absoluteString],
                           NSStringFromQueryParameters(queryParameters)
                           ];
    return [NSURL URLWithString:URLString];
}


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.TableView.hidden = YES;
    self.viewCommentsButton.hidden = NO;
    self.playerView.hidden = NO;
    self.hideCommentsButton.hidden = YES;
    
    self.TableView.dataSource = self;
    self.TableView.delegate = self;
    
    self.view.backgroundColor = [UIColor colorWithRed:233/255.0 green:236/255.0 blue:243/255.0 alpha:1];
    
    // round corners on view comments button
    self.viewCommentsButton.clipsToBounds = YES;
    self.viewCommentsButton.layer.cornerRadius = 3/2.0f;
    
    // create drop shadow for view comments button
    self.viewCommentsButton.layer.shadowColor = [UIColor grayColor].CGColor;
    self.viewCommentsButton.layer.shadowOffset = CGSizeMake(0, 0.6);
    self.viewCommentsButton.layer.shadowOpacity = 1;
    self.viewCommentsButton.layer.shadowRadius = 0.6;
    self.viewCommentsButton.clipsToBounds = NO;

    // round corners on hide comments button
    self.hideCommentsButton.clipsToBounds = YES;
    self.hideCommentsButton.layer.cornerRadius = 3/2.0f;
    
    // create drop shadow for hide comments button
    self.hideCommentsButton.layer.shadowColor = [UIColor grayColor].CGColor;
    self.hideCommentsButton.layer.shadowOffset = CGSizeMake(0, 0.6);
    self.hideCommentsButton.layer.shadowOpacity = 1;
    self.hideCommentsButton.layer.shadowRadius = 0.6;
    self.hideCommentsButton.clipsToBounds = NO;
    
    [Appearance initializeAppearanceDefaults];
    
    // load video into player view
    [self.playerView loadWithVideoId:@"KYVdf5xyD8I"];
}


- (IBAction)sendRequest:(id)sender
{
    self.TableView.hidden = NO;
    self.viewCommentsButton.hidden = YES;
    self.hideCommentsButton.hidden = NO;

    self.title = @"Comments";
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    /* Create the Request:
     YouTubeComment API (GET https://gdata.youtube.com/feeds/api/videos/KYVdf5xyD8I/comments)
     */
    
    NSURL* URL = [NSURL URLWithString:@"https://gdata.youtube.com/feeds/api/videos/KYVdf5xyD8I/comments"];
    NSDictionary* URLParams = @{
                                @"orderby": @"published",
                                };
    URL = NSURLByAppendingQueryParameters(URL, URLParams);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            // Success
            NSLog(@"URL Session Task Succeeded: HTTP %ld", ((NSHTTPURLResponse*)response).statusCode);
            
            if (data != nil) {
                // initialize xml parser, set its delegate, and start parsing:
                self.xmlParser = [[NSXMLParser alloc] initWithData:data];
                self.xmlParser.delegate = self;
            
                self.foundValue = [[NSMutableString alloc] init];
            
            // Start parsing.
                [self.xmlParser parse];
            }
        
        }
        else {
            // Failure
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
    }];
    [task resume];
}


- (IBAction)hideCommentsButtonTapped:(id)sender {
    
    self.TableView.hidden = YES;
    self.playerView.hidden = NO;
    self.viewCommentsButton.hidden = NO;
    self.hideCommentsButton.hidden = YES;
}


#pragma mark - XML Parser Delegate Methods

-(void)parserDidStartDocument:(NSXMLParser *)parser{
    // Initialize the neighbours data array.
    self.commentsDataArray = [[NSMutableArray alloc] init];
}

-(void)parserDidEndDocument:(NSXMLParser *)parser{
    // when the parsing is finished, reload table view
    [self.TableView reloadData];
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    NSLog(@"%@", [parseError localizedDescription]);
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    
    // If the current element name is "feed" then initialize the temporary dictionary.
    if ([elementName isEqualToString:@"feed"]) {
        self.dictTempDataStorage = [[NSMutableDictionary alloc] init];
    }
    
    // store the current element.
    self.currentElement = elementName;
    
    [self.TableView reloadData];
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    
    if ([elementName isEqualToString:@"entry"]) {
        // If the closing element is equal to "entry" then the all the data of a comment has been parsed and the dictionary should be added to the comments data array.
        [self.commentsDataArray addObject:[[NSDictionary alloc] initWithDictionary:self.dictTempDataStorage]];
    }
    else if ([elementName isEqualToString:@"name"]){
        // If the "name" element was found then store it.
        [self.dictTempDataStorage setObject:[NSString stringWithString:self.foundValue] forKey:@"name"];
    }
    else if ([elementName isEqualToString:@"content"]){
        // If the "content" element was found then store it.
        [self.dictTempDataStorage setObject:[NSString stringWithString:self.foundValue] forKey:@"content"];
    }
    
    // Clear the mutable string.
    [self.foundValue setString:@""];
    
    [self.TableView reloadData];
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    // Store the found characters if the current element is one of the ones we want
    if ([self.currentElement isEqualToString:@"name"] ||
        [self.currentElement isEqualToString:@"content"]) {
        
        if (![string isEqualToString:@"\n"]) {
            [self.foundValue appendString:string];
        }
    }
    
    [self.TableView reloadData];
}

#pragma mark - table view delegate and datasource methods

// populate table view cells with parsed xml values


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.commentsDataArray.count;
}



-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    cell.textLabel.text = [[self.commentsDataArray objectAtIndex:indexPath.row] objectForKey:@"name"];    
    cell.detailTextLabel.text = [[self.commentsDataArray objectAtIndex:indexPath.row] objectForKey:@"content"];
    
    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 100;
}



@end
