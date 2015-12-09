// 
// FCCSVDocument.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCCSVDocument.h"

@implementation FCCSVDocument {
	NSMutableArray *_content;
}

@synthesize headerNames = _headerNames;
@synthesize content = _content;

-(BOOL)_parseString:(NSString*)csv{
	_headerNames = [NSMutableArray array];
	_content = [NSMutableArray array];
	
	size_t len = [csv length];
	size_t ptr = 0;
	
	NSCharacterSet *importantChars = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"%C\"\n", _columnSeparator]];
	
	int column = 0;
	BOOL firstLine = YES;
	BOOL insideQuotes = NO;
	size_t startIndex = 0;
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	//Go through the CSV file
	while (ptr < len){
		unichar c = [csv characterAtIndex:ptr];
		if (![importantChars characterIsMember:c]){
			//Unimportant char -> skip
			++ptr;
			continue;
		}
		
		//It's either comma, newline or a quote
		if (c == _columnSeparator){
			if (insideQuotes){
				//Comma inside a quoted string -> all right
				++ptr;
				continue;
			}
			 //It's a comma and not inside quotes -> get the string
			NSString *field = [[csv substringWithRange:NSMakeRange(startIndex, ptr - startIndex)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if ([field hasPrefix:@"\""]){
				//The field begins with a quote -> remove quote at the beginning and at the end and replace double-quotes with single quotes
				field = [field substringFromIndex:1]; //Cutting the quote at the beginning
				field = [field substringToIndex:[field length] - 1]; //Cutting the quote at the end
				field = [field stringByReplacingOccurrencesOfString:@"\"\"" withString:@"\""]; //Replacing all double quotes with single quotes
			}
			if (firstLine){
				//It's the first line -> add the field into the _headerNames array
				[_headerNames addObject:field];
			}else{
				//Otherwise add it to current dictionary
				if (column >= 0 && column < [_headerNames count]){
					//There is a header name for this column
					[dict setObject:field forKey:[_headerNames objectAtIndex:column]];
					//[_content addObject:dict];
					//dict = [NSMutableDictionary dictionary];
				}else{
					//Wrong number of columns
					return NO;
				}
			}
			++column;
			++ptr;
			startIndex = ptr;
		}else if (c == '"'){
			//It's quotes - a few possibilities:
			if (insideQuotes){
				//a) next char is also quotes -> quotes don't end yet
				if (ptr < len - 1 && [csv characterAtIndex:ptr + 1] == '"'){
					ptr+=2;
					continue;
				}else{
					//b) either end of document on the quotes end
					if (ptr < len -1){
						//End of quotes
						insideQuotes = NO;
						++ptr;
					}else{
						//c) end of document
						++ptr;
						
						NSString *field = [[csv substringWithRange:NSMakeRange(startIndex, ptr - startIndex)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
						if ([field hasPrefix:@"\""]){
							//The field begins with a quote -> remove quote at the beginning and at the end and replace double-quotes with single quotes
							field = [field substringFromIndex:1]; //Cutting the quote at the beginning
							field = [field substringToIndex:[field length] - 1]; //Cutting the quote at the end
							field = [field stringByReplacingOccurrencesOfString:@"\"\"" withString:@"\""]; //Replacing all double quotes with single quotes
						}
						[dict setObject:field forKey:[_headerNames objectAtIndex:column]];
						[_content addObject:dict];
						dict = nil; //A stopper
					}
				}
			}else {
				//d) Start of quotes
				insideQuotes = YES;
				startIndex = ptr;
				++ptr;
			}
			
		}else if (c == '\n'){
			//New line
			if (insideQuotes){
				//Can be a new line inside quoted string
				++ptr;
				continue;
			}
			
			NSString *field = [[csv substringWithRange:NSMakeRange(startIndex, ptr - startIndex)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if ([field hasPrefix:@"\""]){
				//The field begins with a quote -> remove quote at the beginning and at the end and replace double-quotes with single quotes
				field = [field substringFromIndex:1]; //Cutting the quote at the beginning
				field = [field substringToIndex:[field length] - 1]; //Cutting the quote at the end
				field = [field stringByReplacingOccurrencesOfString:@"\"\"" withString:@"\""]; //Replacing all double quotes with single quotes
			}
			if (firstLine){
				//It's the first line -> add the field into the _headerNames array
				[_headerNames addObject:field];
			}else{
				//Otherwise add it to current dictionary
				if (column >= 0 && column < [_headerNames count]){
					//There is a header name for this column
					[dict setObject:field forKey:[_headerNames objectAtIndex:column]];
				}else{
					//Wrong number of columns
					return NO;
				}
			}
			
			if (!firstLine){
				[_content addObject:dict];
				dict = [NSMutableDictionary dictionary];
			}
			firstLine = NO;
			column = 0;
			++ptr;
			startIndex = ptr;
		}
	}
	if (dict != nil){
		//We need to add it
		[_content addObject:dict];
	}
	
	return YES;
}
-(void)addContentItem:(id)item{
	if (_content == nil){
		_content = [NSMutableArray array];
	}
	[_content addObject:item];
}
-(NSArray*)content{
	return _content;
}
-(void)setContent:(NSArray<NSDictionary<NSString *,NSString *> *> *)content{
	_content = [content mutableCopy];
}
-(NSArray*)headerNames{
	return _headerNames;
}
-(instancetype)initWithDictionaries:(NSArray<NSDictionary *> *)dictionaries{
	if ((self = [super init]) != nil) {
		_content = [dictionaries mutableCopy];
		_headerNames = [NSMutableArray array];
		for (NSDictionary *dict in dictionaries) {
			for (NSString *key in [dict allKeys]){
				if (![_headerNames containsObject:key]) {
					[_headerNames addObject:key];
				}
			}
		}
	}
	return self;
}
-(id)initWithFile:(NSString*)path{
	if ((self = [super init]) != nil){
		//Check if the file really exists
		if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
			//File doesn't exist -> NO
			self = nil;
			return nil;
		}
		
		NSError *err = nil;
		NSString *csv = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
		if (err != nil || csv == nil){
			//Couldn't open the file
			self = nil;
			return nil;
		}
		
		if (![self _parseString:csv]){
			self = nil;
			return nil;
		}
	}
	return self;
}
-(instancetype)initWithContentsOfURL:(NSURL *)fileURL{
	NSError *err = nil;
	NSString *csv = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&err];
	if (err != nil || csv == nil){
		//Couldn't open the file
		self = nil;
		return nil;
	}
	
	return [self initWithString:csv];
}
-(instancetype)initWithString:(NSString *)body{
	return [self initWithString:body andColumnSeparator:','];
}
-(id)initWithString:(NSString*)body andColumnSeparator:(unichar)columnSeparator{
	if ((self = [super init]) != nil){
		_columnSeparator = columnSeparator;
		
		if (![self _parseString:body]){
			//Could not parse string
			self = nil;
			return nil;
		}
	}
	return self;
}
-(void)setHeaderNames:(NSMutableArray*)headers{
	if (headers == _headerNames){
		return;
	}
	_headerNames = headers;
}
-(NSString*)stringRepresentation{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
	
	NSMutableString *string = [NSMutableString string];
	for (int i = 0; i < [_headerNames count]; ++i){
		//Adding a quoted string with replaced quotes as double-quotes
		id obj = [_headerNames objectAtIndex:i];
		if (obj == nil){
			obj = @"";
		}
		if ([obj isKindOfClass:[NSString class]]){
			obj = [obj stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
		}
		if ([obj isKindOfClass:[NSDate class]]){
			obj = [formatter stringFromDate:obj];
		}
		[string appendFormat:@"%@\"%@\"", (i==0) ? @"" : @",", obj];
	}
	//New line
	[string appendString:@"\n"];
	
	//Add all items in content
	for (int o = 0; o < [_content count]; ++o){
		NSDictionary *item = [_content objectAtIndex:o];
		
		for (int i = 0; i < [_headerNames count]; ++i){
			//Adding a quoted string with replaced quotes as double-quotes
			id obj = [item objectForKey:[_headerNames objectAtIndex:i]];
			if (obj == nil){
				obj = @"";
			}
			if ([obj isKindOfClass:[NSDecimalNumber class]]) {
				obj = [NSString stringWithFormat:@"%0.4f", [obj doubleValue]];
			}
			if ([obj isKindOfClass:[NSNumber class]]) {
				obj = [NSString stringWithFormat:@"%g", [obj doubleValue]];
			}
			if ([obj isKindOfClass:[NSDate class]]){
				obj = [formatter stringFromDate:obj];
			}
			if ([obj isKindOfClass:[NSDictionary class]]) {
				if ([obj count] == 0) {
					obj = @"";
				}else{
					FCCSVDocument *document = [[FCCSVDocument alloc] initWithDictionaries:@[ obj ]];
					obj = [document stringRepresentation];
				}
			}
			if ([obj isKindOfClass:[NSArray class]]) {
				if ([obj count] == 0) {
					obj = @"";
				}else{
					FCCSVDocument *document = [[FCCSVDocument alloc] initWithDictionaries:obj];
					obj = [document stringRepresentation];
				}
			}
			
			obj = [obj stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
			
			// We don't need to replace those
			// obj = [obj stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
			// obj = [obj stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
			
			[string appendFormat:@"%@\"%@\"", (i==0)?@"":@",", obj];
		}
		
		//Don't allow new line at the end of the file
		if (o != [_content count] - 1){
			//New line
			[string appendString:@"\n"];
		}
	}
	return string;
}
-(BOOL)writeToFile:(NSString*)path{
	return [[self stringRepresentation] writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}
-(BOOL)writeToURL:(NSURL *)url{
	return [[self stringRepresentation] writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
}
@end

