//
//  MainViewController.h
//  Camera
//
//  Created by Mateo Olaya Bernal on 23/03/13.
//  Copyright (c) 2013 Mateo Olaya Bernal. All rights reserved.
//

#define kMAX_SOCKET_CLIENTS 10

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "GCDAsyncSocket.h"

enum ACStatus {
	ACOnline = 0,
	ACOffline = 1,
	ACOff = 2
};

@interface MainViewController : NSViewController <GCDAsyncSocketDelegate>
{
	BOOL isConected;
	GCDAsyncSocket *socket;
	QTCaptureSession *session;
	NSMutableArray *clients;
	NSData *imageData;
}
@property (unsafe_unretained) IBOutlet NSImageView *datagramActivity;
@property (unsafe_unretained) IBOutlet NSImageView *serverActivity;
@property (unsafe_unretained) IBOutlet NSTextField *portLabel;
@property (unsafe_unretained) IBOutlet NSTextField *addressLabel;
@property (unsafe_unretained) IBOutlet QTCaptureView *cameraPreview;
@property (unsafe_unretained) IBOutlet NSTextField *datagramLabel;
@property (unsafe_unretained) IBOutlet NSTextField *serverLabel;
@property (unsafe_unretained) IBOutlet NSTextField *bytesPerFrameLabel;
@property (unsafe_unretained) IBOutlet NSTableView *conectedTable;
@property (unsafe_unretained) IBOutlet NSMatrix *resolutionMatrix;
@property (unsafe_unretained) IBOutlet NSMatrix *compressMatrix;

- (IBAction)kernel:(NSButton *)sender;

@end
