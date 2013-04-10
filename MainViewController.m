//
//  MainViewController.m
//  Camera
//
//  Created by Mateo Olaya Bernal on 23/03/13.
//  Copyright (c) 2013 Mateo Olaya Bernal. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController
@synthesize datagramActivity, datagramLabel, serverActivity, serverLabel, cameraPreview, portLabel, addressLabel, bytesPerFrameLabel, conectedTable, resolutionMatrix, compressMatrix;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Istanciar los el socket
		socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
		clients = [[NSMutableArray alloc] initWithCapacity:kMAX_SOCKET_CLIENTS];
		session = [[QTCaptureSession alloc] init];
		
		isConected = NO;
    }
    
    return self;
}

- (IBAction)kernel:(NSButton *)sender {
	if (!isConected) {
		// Conectar el socket
		if ([[portLabel stringValue] integerValue] > 1024 && [[portLabel stringValue] integerValue] < 65535) {
			NSError *error;
			[socket acceptOnPort:[[portLabel stringValue] integerValue] error:&error];
			
			if (!error) {
				[portLabel setEditable:NO];
				[addressLabel setStringValue:[[[NSHost currentHost] addresses] objectAtIndex:1]];
				[sender setTitle:@"Detener socket"];
				
				[serverLabel setStringValue:@"Servidor [ON]"];
				[self statusFromIndicator:serverActivity status:ACOnline];
				isConected = YES;
			} else {
				[[NSAlert alertWithError:error] runModal];
				[sender setTitle:@"Iniciar socket"];
				
				[serverLabel setStringValue:@"Servidor [OFF]"];
				[self statusFromIndicator:serverActivity status:ACOffline];
				isConected = NO;
			}

		} else {
			[[NSAlert alertWithMessageText:@"Advertencia: Puerto no valido"
							 defaultButton:@"OK"
						   alternateButton:nil
							   otherButton:nil
				 informativeTextWithFormat:@"Puerto no valido, elija un puerto entre el 1024 y el 65535. Puertos menores a 1024 estan reservados por el sistema."]
			 runModal];
		}
	} else {
		// Deconectar server
		for (GCDAsyncSocket *sock in clients) {
			[sock disconnect];
		}
		[clients removeAllObjects];
		[socket disconnect];
		[sender setTitle:@"Iniciar socket"];
		
		[serverLabel setStringValue:@"Servidor [OFF]"];
		[self statusFromIndicator:serverActivity status:ACOffline];
		isConected = NO;
	}
	[self cameraEngineStart];
}

#pragma mark - Camera engine

- (void)cameraEngineStart
{
	if ([[session inputs] count] == 0) {
		QTCaptureDevice	*device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
		[device open:nil];
		
		QTCaptureDeviceInput *input = [QTCaptureDeviceInput deviceInputWithDevice:device];
		QTCaptureMovieFileOutput *output = [[QTCaptureMovieFileOutput alloc] init];
		
		[output setDelegate:self];
		
		QTCaptureDecompressedVideoOutput *raw = [[QTCaptureDecompressedVideoOutput alloc] init];
		[raw setDelegate:self];
		
		[session addOutput:raw error:nil];
		[session addOutput:output error:nil];
		[session addInput:input error:nil];
		[cameraPreview setCaptureSession:session];
	}
	
	if (![session isRunning]) {
		[session startRunning];
	} else {
		[session stopRunning];
	}
}

#pragma marl - Camera delgate

- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
	NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:videoFrame]];
	
	NSImage *image = [[NSImage alloc] initWithSize:[imageRep size]];
	[image addRepresentation:imageRep];
	
	//NSImage *sourceImage = anImage;
	[image setScalesWhenResized:YES];
	
	// Report an error if the source isn't a valid image
	//Redimencionar a 480 × 320
	NSSize resolution;
	switch ([resolutionMatrix selectedColumn]) {
		case 0:
			resolution = NSMakeSize(1280, 720);
			break;
		case 1:
			resolution = NSMakeSize(960, 640);
			break;
		case 2:
			resolution = NSMakeSize(480, 320);
			break;
		case 3:
		default:
			resolution = NSMakeSize(320, 240);
			break;
	}
	
	NSImage *smallImage = [[NSImage alloc] initWithSize:resolution];
	[smallImage lockFocus];
	[image setSize:resolution];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[image compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	[smallImage unlockFocus];
	
	float compress = 0;
	switch ([compressMatrix selectedColumn]) {
		case 0:
			compress = 0;
			break;
		case 1:
			compress = 0.40;
			break;
		case 2:
		default:
			compress = 0.80;
			break;
	}
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:compress] forKey:NSImageCompressionFactor];
	
	NSData *bitmapData = [smallImage TIFFRepresentation];
	NSBitmapImageRep *bitmapRep = [NSBitmapImageRep imageRepWithData:bitmapData];
	
	imageData = [bitmapRep representationUsingType:NSJPEGFileType
										properties:([compressMatrix selectedColumn] != 3) ? options : nil];
}

#pragma mark - Socket delegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	[clients addObject:newSocket];
	[newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	[self statusFromIndicator:datagramActivity status:ACOffline];
	[datagramLabel setStringValue:@"Datagrama [ENTREGADO]"];
	[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(resetDatagramIndicator:) userInfo:nil repeats:NO];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	if ([clients count] > 0) {
		[[clients objectAtIndex:0] writeData:imageData withTimeout:-1 tag:0];
		[self statusFromIndicator:datagramActivity status:ACOff];
		[datagramLabel setStringValue:@"Datagrama [EN ESPERA]"];
		
		[bytesPerFrameLabel setStringValue:[NSString stringWithFormat:@"%.4f KiB por Frame", (float)[imageData length] / 1000]];
	}
	[sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	for (GCDAsyncSocket *sock in clients) {
		[sock disconnect];
	}
	[clients removeAllObjects];
}

#pragma mark - Status indicator

- (void)resetDatagramIndicator:(NSTimer *)timer
{
	[self statusFromIndicator:datagramActivity status:ACOff];
	[datagramLabel setStringValue:@"Datagrama [EN ESPERA]"];
}

- (void)statusFromIndicator:(NSImageView *)indicator status:(NSUInteger)status;
{
	NSString *path;
	switch (status) {
		case 0:
			path = @"online.png";
			break;
		case 1:
			path = @"offline.png";
			break;
		case 2:
		default:
			path = @"off.png";
			break;
	}
	
	[indicator setImage:[NSImage imageNamed:path]];
}

@end
