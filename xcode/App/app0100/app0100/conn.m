//
//  conn.m
//  app0100
//
//  Created by encuadro on 2/25/13.
//
//

#import "conn.h"

@implementation conn
-(conn*)initconFunc:(NSString *)string{
    NSString *soapMessage = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
                             "<soap:Body>\n"
                             "<%@ xmlns=\"http://10.0.2.109/server_php/server_php.php/%@\">\n"
                             "</%@>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n",string,string,string];
	//NSLog(@"%@",soapMessage);
    NSMutableString *u = [NSMutableString stringWithString:kPostURL];
	[u setString:[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:u];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
	NSString *msgLength = [NSString stringWithFormat:@"%d", [soapMessage length]];
	[theRequest addValue: @"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    NSString *s = [NSString stringWithFormat:@"http://10.0.2.109/server_php/server_php.php/%@", string];
	[theRequest addValue: s  forHTTPHeaderField:@"SOAPAction"];
	[theRequest addValue: msgLength forHTTPHeaderField:@"Content-Length"];
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
	NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if( theConnection ){
        webData = [[NSMutableData data] retain];
        NSLog(@"entro");
        
    }
	else{
		NSLog(@"no entro");
    }
    return self;
    
}

-(conn*)initconFunc:(NSString *)string yNomParam:(NSString *)string2 yParam:(NSString*)inti{
    NSString *soapMessage = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
                             "<soap:Body>\n"
                             "<%@ xmlns=\"http://10.0.2.109/server_php/server_php.php/%@\">\n"
                             "<%@>%@</%@>"
                             "</%@>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n",string,string,string2,inti,string2,string];
	//NSLog(@"%@",soapMessage);
    NSMutableString *u = [NSMutableString stringWithString:kPostURL];
	[u setString:[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:u];
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
	NSString *msgLength = [NSString stringWithFormat:@"%d", [soapMessage length]];
	[theRequest addValue: @"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    NSString *s = [NSString stringWithFormat:@"http://10.0.2.109/server_php/server_php.php/%@", string];
	[theRequest addValue: s  forHTTPHeaderField:@"SOAPAction"];
	[theRequest addValue: msgLength forHTTPHeaderField:@"Content-Length"];
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if( theConnection ){
        webData = [[NSMutableData data] retain];
        NSLog(@"entro");
        
    }
	else{
		NSLog(@"no entro");
    }
    return self;
}

-(conn*)initConFuncion:(NSString *)nomFuncion NombreParametro:(NSString *)nombreParametro yNombreIma:(NSString *)nombreDato yNombreSegParam:(NSString *)nombreParam2 yIdSala:(NSString*)nombreDato2{
    NSString *soapMessage = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
                             "<soap:Body>\n"
                             "<%@ xmlns=\"http://10.0.2.109/server_php/server_php.php/%@\">\n"
                             "<%@>%@</%@>"
                             "<%@>%@</%@>"
                             "</%@>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n",nomFuncion,nomFuncion,nombreParam2,nombreDato2,nombreParam2,nombreParametro,nombreDato,nombreParametro,nomFuncion];
	//NSLog(@"%@",soapMessage);
    NSMutableString *u = [NSMutableString stringWithString:kPostURL];
	[u setString:[u stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:u];
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
	NSString *msgLength = [NSString stringWithFormat:@"%d", [soapMessage length]];
	[theRequest addValue: @"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    NSString *s = [NSString stringWithFormat:@"http://10.0.2.109/server_php/server_php.php/%@", nomFuncion];
	[theRequest addValue: s  forHTTPHeaderField:@"SOAPAction"];
	[theRequest addValue: msgLength forHTTPHeaderField:@"Content-Length"];
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
    [theRequest setTimeoutInterval:80];
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if( theConnection ){
        webData = [[NSMutableData data] retain];
        NSLog(@"entro");
        
    }
	else{
		NSLog(@"no entro");
    }
    return self;
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	[webData setLength: 0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	[webData appendData:data];
}

-(void)connection:(NSURLConnection *) connection didFailWithError:(NSError *)error{
	NSLog(@"%@", error);
	[connection release];
	[webData release];
}

-(conn *)connectionDidFinishLoading:(NSURLConnection *)connection{
	NSLog(@"DONE. Received Bytes: %d", [webData length]);
	NSString *theXML = [[NSString alloc] initWithBytes: [webData mutableBytes] length:[webData length] encoding:NSUTF8StringEncoding];
    [theXML release];
	if (xmlParser){
        [xmlParser release];
    }
    xmlParser = [[NSXMLParser alloc] initWithData: webData];
    [xmlParser setDelegate: self];
    [xmlParser setShouldResolveExternalEntities:YES];
    [xmlParser parse];
	[connection release];
	[webData release];
}

-(void) parser:(NSXMLParser *) parser didStartElement:(NSString *) elementName namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *) qName attributes:(NSDictionary *) attributeDict {
    if( [elementName isEqualToString:@"return"]){
        if (!soapResults){
            soapResults = [[NSMutableString alloc] init];
        }
        elementFound = YES;
    }
}

-(void)parser:(NSXMLParser *) parser foundCharacters:(NSString *)string{
    if (elementFound){
        [soapResults appendString: string];
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if ([elementName isEqualToString:@"return"]){
        //---displays the country---
        //[soapResults setString:@""];
        //elementFound = FALSE;
    }
}

-(NSMutableString *)getSoap{
    return soapResults;
}

@end
