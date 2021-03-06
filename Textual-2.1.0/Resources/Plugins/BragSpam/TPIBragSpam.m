// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPIBragSpam.h"

@implementation TPIBragSpam

- (void)messageSentByUser:(IRCClient*)client
				  message:(NSString*)messageString
				  command:(NSString*)commandString
{
	if ([commandString isEqualToString:@"BRAG"]) {
		if (client.world.selectedChannel.isChannel == NO) return;
		
		NSInteger operCount      = 0;
		NSInteger chanOpCount    = 0;
		NSInteger chanHopCount   = 0;
		NSInteger chanVopCount   = 0;
		NSInteger channelCount   = 0;
		NSInteger networkCount   = 0;
		NSInteger powerOverCount = 0;
		
		for (IRCClient *c in [client.world clients]) {
			if (c.isConnected == NO) continue;
			
			networkCount++;
			
			if (c.hasIRCopAccess == YES) {
				operCount++;
			}
			
			BOOL addUser = NO;
			
			NSMutableArray *trackedUsers = [NSMutableArray new];
			
			for (IRCChannel *ch in c.channels) {
				if ([ch isActive] == NO || [ch isChannel] == NO) continue;

				channelCount += 1;
				
				IRCUser *myself = [ch findMember:c.myNick];
				
				if (myself.q || myself.a || myself.o) {
					chanOpCount++;
				} else if (myself.h) {
					chanHopCount++;
				} else if (myself.v) {
					chanVopCount++;
				}
				
				for (IRCUser *m in ch.members) {
					if ([m isEqual:myself]) continue;
					
					if (myself.q && m.q == NO) {
						addUser = YES;
					} else if (myself.a && m.q == NO && m.a == NO) {
						addUser = YES;
					} else if (myself.o && m.q == NO && m.a == NO && m.o == NO) {
						addUser = YES;
					} else if (myself.h && m.q == NO && m.a == NO && m.o == NO && m.h == NO) {
						addUser = YES;	
					}
					
					if (addUser == YES) {
						if ([trackedUsers containsObject:m.nick] == NO) {
							powerOverCount++;
							
							[trackedUsers addObject:m.nick];	
						}
					}
				}
			}
			
			[trackedUsers release];
		}
		
		NSString *result = TXTFLS(@"BRAGSPAM_PLUGIN_NORMAL_RESULT", channelCount, networkCount, operCount, 
								  chanOpCount, chanHopCount, chanVopCount, powerOverCount);
		
		[[client iomt] sendPrivmsgToSelectedChannel:result];
	} else if ([commandString isEqualToString:@"CBRAG"]) {
		IRCChannel *cc;
		
		NSMutableArray *chanlist = [client.channels mutableCopy];
		
		for (IRCChannel *c in client.channels) {
			IRCChannelMode *modes = c.mode;
			
			if (c.isTalk || [modes modeInfoFor:@"p"].plus || [modes modeInfoFor:@"s"].plus) {
				[chanlist removeObject:c];
			}
		}
		
		NSMutableString *result = [NSMutableString string];
		
		if (NSObjectIsEmpty(chanlist)) {	
			[result appendString:TXTFLS(@"BRAGSPAM_PLUGIN_CHANNEL_RESULT_NONE", client.config.network)];
		} else {
			cc = [chanlist objectAtIndex:0];
			
			if (chanlist.count == 1) {	
				[result appendString:TXTFLS(@"BRAGSPAM_PLUGIN_CHANNEL_RESULT_SINGLE", cc.name, client.config.network)];
			} else {
				[result appendString:TXTFLS(@"BRAGSPAM_PLUGIN_CHANNEL_RESULT", cc.name)];
				
				[chanlist removeObjectAtIndex:0];
				
				for (cc in chanlist) {
					if (NSDissimilarObjects(cc, [chanlist lastObject])) {
						[result appendString:TXTFLS(@"BRAGSPAM_PLUGIN_CHANNEL_RESULT_MIDITEM", cc.name)];
					} else {
						[result appendString:TXTFLS(@"BRAGSPAM_PLUGIN_CHANNEL_RESULT_ENDITEM", cc.name, client.config.network)];
					}
				}
			}
		}		
		
		[[client iomt] sendPrivmsgToSelectedChannel:result];
		
		[chanlist drain];
	}
}

- (NSArray*)pluginSupportsUserInputCommands
{
	return [NSArray arrayWithObjects:@"brag", @"cbrag", nil];
}	

@end
