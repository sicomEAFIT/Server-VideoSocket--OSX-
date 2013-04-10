//
//  AppDelegate.m
//  Camera
//
//  Created by Mateo Olaya Bernal on 23/03/13.
//  Copyright (c) 2013 Mateo Olaya Bernal. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	// Cierra la aplicacion al cerrar del boton rojo, no es necerario quitar la applicacion
	[[NSApplication sharedApplication] terminate:self];
	return YES;
}


@end
