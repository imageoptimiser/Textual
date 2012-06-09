// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

#define NO_CLIENT					(PointerIsEmpty(u))
#define NO_CHANNEL					(PointerIsEmpty(c))
#define	NO_CLIENT_OR_CHANNEL		(PointerIsEmpty(u) || PointerIsEmpty(c))
#define IS_CLIENT					(c.isTalk == NO && c.isChannel == NO && c.isClient == YES)
#define IS_CHANNEL					(c.isTalk == NO && c.isChannel == YES && c.isClient == NO)
#define IS_QUERY					(c.isTalk == YES && c.isChannel == NO && c.isClient == NO)
#define CONNECTED					(u && u.isConnected && u.isLoggedIn)
#define NOT_CONNECTED				(u && u.isConnected == NO && u.isLoggedIn == NO && u.isConnecting == NO)
#define ACTIVE						(c && c.isActive)
#define NOT_ACTIVE					(c && c.isActive == NO)

@interface MenuController (Private)
- (LogView *)currentWebView;
@end

@implementation MenuController

@synthesize aboutPanel;
@synthesize channelSheet;
@synthesize closeWindowItem;
@synthesize currentSearchPhrase;
@synthesize highlightSheet;
@synthesize inviteSheet;
@synthesize isInFullScreenMode;
@synthesize master;
@synthesize memberList;
@synthesize modeSheet;
@synthesize nickSheet;
@synthesize pointedChannelName;
@synthesize pointedNick;
@synthesize pointedUrl;
@synthesize preferencesController;
@synthesize serverList;
@synthesize serverSheet;
@synthesize text;
@synthesize topicSheet;
@synthesize window;
@synthesize world;

- (id)init
{
	if ((self = [super init])) {
		self.currentSearchPhrase = NSNullObject;
	}
	
	return self;
}

- (void)terminate
{
	if (self.serverSheet) [self.serverSheet close];
	if (self.channelSheet) [self.channelSheet close];
	if (self.preferencesController) [self.preferencesController close];
}

- (void)validateChannelMenuSubmenus:(NSMenuItem *)item
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (IS_CHANNEL) {
		[[[item menu] itemWithTag:936] setHidden:NO];
		[[[item menu] itemWithTag:937] setHidden:NO];
		
		[[[item menu] itemWithTag:5422] setHidden:NO];
		[[[item menu] itemWithTag:5422] setEnabled:YES];
		
		[[[[[item menu] itemWithTag:5422] submenu] itemWithTag:542] setEnabled:[Preferences logTranscript]];
	} else {
		[[[item menu] itemWithTag:936] setHidden:BOOLReverseValue(c.isTalk)];
		[[[item menu] itemWithTag:937] setHidden:BOOLReverseValue(c.isTalk)];
		
		[[[item menu] itemWithTag:5422] setEnabled:NO]; 
		[[[item menu] itemWithTag:5422] setHidden:YES]; 
	}	
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	IRCClient   *u = [self.world selectedClient];
	IRCChannel  *c = [self.world selectedChannel];
	
	NSInteger tag = item.tag;
	
	switch (tag) {
		case 313:	// paste
		{
			if (NSObjectIsEmpty([_NSPasteboard() stringContent])) {
				return NO;
			}
			
			NSWindow *win = [NSApp keyWindow];
			if (PointerIsEmpty(win)) return NO;
			
			id t = [win firstResponder];
			if (PointerIsEmpty(t)) return NO;
			
			if ([t respondsToSelector:@selector(paste:)]) {
				if ([t respondsToSelector:@selector(validateMenuItem:)]) {
					return [t validateMenuItem:item];
				}
				
				return YES;
			}
			
			break;
		}
		case 331:	// search in google
		{
			[self validateChannelMenuSubmenus:item];
			
			LogView *web = [self currentWebView];
			if (PointerIsEmpty(web)) return NO;
			
			return [web hasSelection];
			break;
		}
		case 501:	// connect
		{
			BOOL condition = (CONNECTED || u.isConnecting);
			
			[item setHidden:condition];
			
			return BOOLReverseValue(condition);
			break;
		}
		case 502:	// disconnect
		{
			BOOL condition = (u && (CONNECTED || u.isConnecting));
			
			[item setHidden:BOOLReverseValue(condition)];
			
			return condition;
			break;
		}
		case 503:	// cancel isReconnecting
		{
			BOOL condition = (u && [u isReconnecting]);
			
			[item setHidden:BOOLReverseValue(condition)];
			
			return condition;
			break;
		}
		case 511:	// nick
		case 519:	// channel list
		{
			return CONNECTED;
			break;
		}
		case 522:	// copy server
		{
			return BOOLValueFromObject(u);
			break;
		}
		case 523:	// delete server
		{
			return NOT_CONNECTED;
			break;
		}
		case 541:	// server property
		{
			return BOOLValueFromObject(u);
			break;
		}
		case 592:	// textual logs
		{
			return [Preferences logTranscript];
			break;
		}
		case 601:	// join
		{
			[self validateChannelMenuSubmenus:item];
			
			if (IS_QUERY) {
				[item setHidden:YES];
				
				return NO;
			} else {
				BOOL condition = (CONNECTED && NOT_ACTIVE && IS_CHANNEL);
				
				if (CONNECTED) {
					[item setHidden:BOOLReverseValue(condition)];
				} else {
					[item setHidden:NO];
				}
				
				return condition;
			}
			
			break;
		}
		case 602:	// leave
		{
			if (IS_QUERY) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:NOT_ACTIVE];
				
				return ACTIVE;
			}
			
			break;
		}
		case 611:	// mode
		{
			return ACTIVE;
			break;
		}
		case 612:	// topic
		{
			return ACTIVE;
			break;
		}
		case 651:	// add channel
		{
			if (IS_QUERY) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:NO];
				
				return BOOLValueFromObject(u);
			}
			
			break;
		}
		case 652:	// delete channel
		{
			if (IS_QUERY) {
				[item setTitle:TXTLS(@"DELETE_QUERY_MENU_ITEM")];
				
				return YES;
			} else {
				[item setTitle:TXTLS(@"DELETE_CHANNEL_MENU_ITEM")];
				
				return IS_CHANNEL;
			}
			
			break;
		}
		case 691:	// add channel - server menu
		{
			return BOOLValueFromObject(u);
			break;
		}
		case 2005:	// invite
		{
			if (NOT_CONNECTED || [self checkSelectedMembers:item] == NO) return NO;
			
			NSInteger count = 0;
			
			for (IRCChannel *e in u.channels) {
				if (NSDissimilarObjects(c, e) && e.isChannel) {
					++count;
				}
			}
			
			return (count > 0);
			break;
		}
		case 5421: // query logs
		{
			if (IS_QUERY) {
				[item setHidden:NO];
				
				[[[item menu] itemWithTag:935] setHidden:YES]; 
				
				return [Preferences logTranscript];
			} else {
				[item setHidden:YES];
				
				[[[item menu] itemWithTag:935] setHidden:NO];
				
				return NO;
			}
			
			break;
		}
		case 9631: // close window
		{
			if ([self.window isKeyWindow]) {
				IRCClient *u = [self.world selectedClient];
				IRCChannel *c = [self.world selectedChannel];
				
				if (NO_CLIENT_OR_CHANNEL) return YES;
				
				switch ([Preferences cmdWResponseType]) {
					case CMDWKEY_SHORTCUT_CLOSE:
					{
						[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_CLOSE_WINDOW")];
						break;
					}
					case CMDWKEY_SHORTCUT_PARTC:
					{
						if (IS_CLIENT) {
							[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_CLOSE_WINDOW")];
							return NO;
						} else {
							if (IS_CHANNEL) {
								[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_PART_CHANNEL")];
								
								if (NOT_ACTIVE) {
									return NO;
								}
							} else {
								[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_LEAVE_QUERY")];
							}
						}
						
						break;
					}
					case CMDWKEY_SHORTCUT_DISCT:
					{
						[item setTitle:TXTFLS(@"CMDWKEY_SHORTCUT_DISCONNECT", ((u.config.server) ?: u.config.name))];
						
						if (NOT_CONNECTED) return NO;
						
						break;
					}
					case CMDWKEY_SHORTCUT_QUITA:
					{
						[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_QUIT_APPLICATION")];
						break;
					}
				}
			} else {
				[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_CLOSE_WINDOW")];
			}
			
			return YES;
			break;
		}
		case 593: // Highlights
		{
			return ([Preferences logAllHighlightsToQuery] && CONNECTED);
			break;
		}
        case 54092: // Developer Mode
        {
            if ([_NSUserDefaults() boolForKey:DeveloperEnvironmentToken] == YES) {
                [item setState:NSOnState];
            } else {  
                [item setState:NSOffState];
            }
            
            return YES;
			break;
        }
		case 504910 ... 504912: // User, right click menu, + mode changes
		case 504810 ... 504812: // User, right click menu, - mode changes
		{
			NSArray *nicknames = [self selectedMembers:nil];
			
			if (NSObjectIsEmpty(nicknames) || nicknames.count > 1) {
				[item setHidden:NO];
				
				[[item.menu itemWithTag:504913] setHidden:YES];
				[[item.menu itemWithTag:504813] setHidden:YES];
				
				return YES;
			} else {
				IRCUser *m = [nicknames safeObjectAtIndex:0];
				
				switch (tag) {
					case 504910: [item setHidden:m.o]; break; // +o
					case 504911: [item setHidden:m.h]; break;  // +h
					case 504912: [item setHidden:m.v]; break;  // +v
					case 504810: [item setHidden:(m.o == NO)]; break; // -o
					case 504811: [item setHidden:(m.h == NO)]; break; // -h
					case 504812: [item setHidden:(m.v == NO)]; break; // -v
						
					default: break;
				}
				
				BOOL hideTakeSepItem = (m.o == NO || m.h == NO || m.v == NO);
				BOOL hideGiveSepItem = (m.o || m.h || m.v);
				
				[[item.menu itemWithTag:504913] setHidden:hideTakeSepItem];
				[[item.menu itemWithTag:504813] setHidden:hideGiveSepItem];
				
				return YES;
			}
			break;
		}
		case 990002: // Next Highlight
		{
			return [self.world.selected.log highlightAvailable:NO];
			break;
		}
		case 990003: // Previous Highlight
		{
			return [self.world.selected.log highlightAvailable:YES];
			break;
		}
		default:
		{
			return YES;
			break;
		}
	}
	
	return YES;
}

#pragma mark -
#pragma mark Utilities

- (LogView *)currentWebView
{
	return self.world.selected.log.view;
}

- (BOOL)checkSelectedMembers:(NSMenuItem *)item
{
	return ([self.memberList countSelectedRows] > 0);
}

- (NSArray *)selectedMembers:(NSMenuItem *)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	NSMutableArray *ary = [NSMutableArray array];
	
	if (NO_CLIENT_OR_CHANNEL || NOT_ACTIVE || NOT_CONNECTED || IS_CLIENT) {
		return ary;
	} else {
		NSIndexSet *indexes = [self.memberList selectedRowIndexes];
		
		if (NSObjectIsNotEmpty(indexes) && NSObjectIsEmpty(self.pointedNick)) {
			for (NSNumber *index in [indexes arrayFromIndexSet]) {
				NSUInteger nindex = [index unsignedIntegerValue];
				
				IRCUser *m = [c memberAtIndex:nindex];
				
				if (m) {
					[ary safeAddObject:m];
				}
			}
		} else {
			if (NSObjectIsNotEmpty(self.pointedNick)) {
				IRCUser *m = [c findMember:self.pointedNick];
				
				if (m) {
					[ary safeAddObject:m];
				} 
                
               self.pointedNick = nil;
			}
		}
	}
	
	return ary;
}

- (void)deselectMembers:(NSMenuItem *)sender
{
	self.pointedNick = nil;
	
	[self.memberList deselectAll:nil];
}

#pragma mark -
#pragma mark Menu Items

- (void)_onWantFindPanel:(id)sender
{
	NSString *newPhrase = [PopupPrompts dialogWindowWithInput:TXTLS(@"FIND_SEARCH_PHRASE_PROPMT_MESSAGE")
														title:TXTLS(@"FIND_SEARCH_PRHASE_PROMPT_TITLE")
												defaultButton:TXTLS(@"FIND_SEARCH_PHRASE_PROMPT_BUTTON")
											  alternateButton:TXTLS(@"CANCEL_BUTTON") 
												 defaultInput:self.currentSearchPhrase];
	
	if (NSObjectIsEmpty(newPhrase)) {
		self.currentSearchPhrase = NSNullObject;
	} else {
		if ([newPhrase isNotEqualTo:self.currentSearchPhrase]) {
			self.currentSearchPhrase = newPhrase;
		}
	}
	
	[[[self iomt] currentWebView] searchFor:self.currentSearchPhrase direction:YES caseSensitive:NO wrap:YES];
}

- (void)onWantFindPanel:(id)sender
{
	if ([sender tag] == 1 || NSObjectIsEmpty(self.currentSearchPhrase)) {
		[[self invokeInBackgroundThread] _onWantFindPanel:sender];
	} else {
		if ([sender tag] == 2) {
			[[self currentWebView] searchFor:self.currentSearchPhrase direction:YES caseSensitive:NO wrap:YES];
		} else {
			[[self currentWebView] searchFor:self.currentSearchPhrase direction:NO caseSensitive:NO wrap:YES];
		}
	}
}

- (void)commandWShortcutUsed:(id)sender
{
	NSWindow *currentWindow = [NSApp keyWindow];
	
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if ([self.window isKeyWindow]) {
		switch ([Preferences cmdWResponseType]) {
			case CMDWKEY_SHORTCUT_CLOSE:
			{
				[self.window close];
				break;
			}
			case CMDWKEY_SHORTCUT_PARTC:
			{
				if (NO_CLIENT_OR_CHANNEL || IS_CLIENT) return;
				
				if (IS_CHANNEL && ACTIVE) {
					[u partChannel:c];
				} else {
					if (IS_QUERY) {
						[self.world destroyChannel:c];
					}
				}
				
				break;
			}
			case CMDWKEY_SHORTCUT_DISCT:
			{
				if (NO_CLIENT || NOT_CONNECTED) return;
				
				[u quit];
				
				break;
			}
			case CMDWKEY_SHORTCUT_QUITA:
			{
				[NSApp terminate:nil];
				break;
			}
		}
	} else {
		[currentWindow performClose:nil];
	}
}

- (void)onPreferences:(id)sender
{
	if (self.preferencesController) {
		[self.preferencesController show];
		
		return;
	}
	
	PreferencesController *pc = [PreferencesController alloc];
	
	pc.delegate = self;
	pc.world = self.world;
	
	self.preferencesController = pc;

	(void)[self.preferencesController initWithWorldController:self.world];
	
	[self.preferencesController show];
}

- (void)preferencesDialogWillClose:(PreferencesController *)sender
{
	[self.world preferencesChanged];
	
	self.preferencesController = nil;
}

- (void)onCloseWindow:(id)sender
{
	[[NSApp keyWindow] performClose:nil];
}

- (void)onWantMainWindowCentered:(id)sender;
{
	[[NSApp mainWindow] exactlyCenterWindow];
}

- (void)onCloseCurrentPanel:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (c) {
		[self.world destroyChannel:c];
		[self.world save];
	}
}

- (void)onShowAcknowledgments:(id)sender
{
	[_NSWorkspace() openURL:[NSURL fileURLWithPath:[[Preferences whereResourcePath] stringByAppendingPathComponent:@"Acknowledgments.pdf"]]];
}

- (void)onShowContributors:(id)sender
{
	[_NSWorkspace() openURL:[NSURL fileURLWithPath:[[Preferences whereResourcePath] stringByAppendingPathComponent:@"Contributors.pdf"]]];
}

- (void)onPaste:(id)sender
{
	NSWindow *win = [NSApp keyWindow];
	if (PointerIsEmpty(win)) return;
	
	id t = [win firstResponder];
	if (PointerIsEmpty(t)) return;
	
    if ([t respondsToSelector:@selector(requriesSpecialPaste)]) {
        if ([self.window attachedSheet]) {
            [t paste:self];
        } else {
            [self.text focus];
            [self.text paste:self];
        }
    } else {
        if (self.window == [NSApp keyWindow]) {
            if (PointerIsEmpty([self.window attachedSheet])) {
                [self.text focus];
                [self.text paste:self];
                
                return;
            }
        }
        
        if ([t respondsToSelector:@selector(paste:)]) {
            BOOL validated = YES;
            
            if ([t respondsToSelector:@selector(validateMenuItem:)]) {
                validated = [t validateMenuItem:sender];
            }
            
            if (validated) {
                [t paste:sender];
            }
        }
    }
}

- (void)onSearchWeb:(id)sender
{
	LogView *web = [self currentWebView];
	if (PointerIsEmpty(web)) return;
	
	NSString *s = [web selection];
	
	if (NSObjectIsNotEmpty(s)) {
		s = [s gtm_stringByEscapingForURLArgument];
		
		NSString *urlStr = [NSString stringWithFormat:@"http://www.google.com/search?ie=UTF-8&q=%@", s];
		
		[URLOpener open:[NSURL URLWithString:urlStr]];
	}
}

- (void)onCopyLogAsHtml:(id)sender
{
	IRCTreeItem *sel = self.world.selected;
	
	if (PointerIsEmpty(sel)) return;
	
	[_NSPasteboard() setStringContent:[sel.log.view contentString]];
}

- (void)onMarkScrollback:(id)sender
{
	IRCTreeItem *sel = self.world.selected;
	
	if (PointerIsEmpty(sel)) return;
	
	[sel.log unmark];
	[sel.log mark];
}
- (void)onGotoScrollbackMark:(id)sender;
{
	IRCTreeItem *sel = self.world.selected;
	
	if (PointerIsEmpty(sel)) return;
	
	[sel.log goToMark];
}

- (void)onClearScrollback:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
    if (u) {
        if (c) {
            [self.world clearContentsOfChannel:c inClient:u];
            
			[c setDockUnreadCount:0];
			[c setTreeUnreadCount:0];
            [c setKeywordCount:0];
        } else {
            [self.world clearContentsOfClient:u];
            
			[u setDockUnreadCount:0];
			[u setTreeUnreadCount:0];
            [u setKeywordCount:0];
        }
        
        [self.world updateIcon];
    }
}

- (void)onIncreaseFontSize:(id)sender
{
	[self.world changeTextSize:YES];
}

- (void)onDecreaseFontSize:(id)sender
{
	[self.world changeTextSize:NO];
}

- (void)onMarkAllAsRead:(id)sender
{
	[self.world markAllAsRead];
}

- (void)onConnect:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (NO_CLIENT || CONNECTED) return;
	
	[u connect];
	
	[self.world expandClient:u];
}

- (void)onDisconnect:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (NO_CLIENT || NOT_CONNECTED) return;
	
	[u quit];
	[u cancelReconnect];
}

- (void)onCancelReconnecting:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (NO_CLIENT) return;
	
	[u cancelReconnect];
}

- (void)onNick:(id)sender
{
	if (self.nickSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	
	if (NO_CLIENT || NOT_CONNECTED) return;
	
	self.nickSheet = [NickSheet new];
	self.nickSheet.delegate = self;
	self.nickSheet.window = self.window;
	self.nickSheet.uid = u.uid;
	
	[self.nickSheet start:u.myNick];
}

- (void)nickSheet:(NickSheet *)sender didInputNick:(NSString *)newNick
{
	IRCClient *u = [self.world findClientById:sender.uid];
	
	if (NO_CLIENT || NOT_CONNECTED) return;
	
	[u changeNick:newNick];
}

- (void)nickSheetWillClose:(NickSheet *)sender
{
	self.nickSheet = nil;
}

- (void)onChannelList:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (NO_CLIENT || NOT_CONNECTED) return;
	
	[u createChannelListDialog];
	[u send:IRCCI_LIST, nil];
}

- (void)onAddServer:(id)sender
{
	if (self.serverSheet) return;
	
	ServerSheet *d = [ServerSheet new];
	
	d.delegate = self;
	d.window = self.window;
	d.config = [[IRCClientConfig alloc] init];
	d.uid = -1;
	
	[d startWithIgnoreTab:NSNullObject];
	
	self.serverSheet = d;
}

- (void)onCopyServer:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (NO_CLIENT) return;
	
	IRCClientConfig *config = u.storedConfig;
	
	config.name  = [config.name stringByAppendingString:@"_"];
	config.guid  = [NSString stringWithUUID];
	config.cuid += 1;
	
	IRCClient *n = [self.world createClient:config reload:YES];
	
	[self.world save];
	
	if (u.isExpanded) {
		[self.world expandClient:n];
	}
}

- (void)onDeleteServer:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (NO_CLIENT || CONNECTED) return;
	
	BOOL result = [PopupPrompts dialogWindowWithQuestion:TXTLS(@"WANT_SERVER_DELETE_MESSAGE")
												   title:TXTLS(@"WANT_SERVER_DELETE_TITLE")
										   defaultButton:TXTLS(@"OK_BUTTON") 
										 alternateButton:TXTLS(@"CANCEL_BUTTON")
											 otherButton:nil
										  suppressionKey:@"delete_server"
										 suppressionText:nil];
	
	if (result == NO) {
		return;
	}
	
	[u.config destroyKeychains];
	
	[_NSUserDefaults() removeObjectForKey:[@"Preferences.prompts.cert_trust_error." stringByAppendingString:u.config.guid]];
	
	[self.world destroyClient:u];
	[self.world save];
}

- (void)showServerPropertyDialog:(IRCClient *)u ignore:(NSString *)imask
{
	if (NO_CLIENT) return;
	if (self.serverSheet) return;
	
	ServerSheet *d = [ServerSheet new];
	
	d.delegate = self;
	d.window = self.window;
	d.config = u.storedConfig;
	d.uid = u.uid;
	d.client = u;
	
	[d startWithIgnoreTab:imask];
	
	self.serverSheet = d;
}

- (void)onServerProperties:(id)sender
{
	[self showServerPropertyDialog:[self.world selectedClient] ignore:NSNullObject];
}

- (void)ServerSheetOnOK:(ServerSheet *)sender
{
	if (sender.uid < 0) {
		[self.world createClient:sender.config reload:YES];
	} else {
		IRCClient *u = [self.world findClientById:sender.uid];
		
		if (NO_CLIENT) return;
		
		[u updateConfig:sender.config];
	}
	
	[self.world save];
}

- (void)ServerSheetWillClose:(ServerSheet *)sender
{
	self.serverSheet = nil;
}

- (void)onJoin:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT || IS_QUERY || ACTIVE || NOT_CONNECTED) return;
	
	[u joinChannel:c];
}

- (void)onLeave:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || NOT_ACTIVE || NOT_CONNECTED) return;
	
	if (IS_CHANNEL) {
		[u partChannel:c];
	} else {
		[self.world destroyChannel:c];
	}
}

- (void)showHighlightSheet:(id)sender
{
	if (self.highlightSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	
	if (NO_CLIENT) return;
	
	HighlightSheet *d = [HighlightSheet new];
	
	d.delegate = self;
	d.window = self.window;
	d.list = u.highlights;
	
	[self.window closeExistingSheet];
	
	[d show];
	
	self.highlightSheet = d;
}

- (void)highlightSheetWillClose:(HighlightSheet *)sender
{
	self.highlightSheet = nil;
}

- (void)onTopic:(id)sender
{
	if (self.topicSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	TopicSheet *t = [TopicSheet new];
	
	t.delegate = self;
	t.window = self.window;
	t.uid = u.uid;
	t.cid = c.uid;
	
	[t start:c.topic];
	
	self.topicSheet = t;
}

- (void)topicSheet:(TopicSheet *)sender onOK:(NSString *)topic
{
	IRCChannel *c = [self.world findChannelByClientId:sender.uid channelId:sender.cid];
	IRCClient *u = c.client;
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	if ([u encryptOutgoingMessage:&topic channel:c] == YES) {
		[u send:IRCCI_TOPIC, c.name, topic, nil];
	}
}

- (void)topicSheetWillClose:(TopicSheet *)sender
{
	self.topicSheet = nil;
}

- (void)onMode:(id)sender
{
	if (self.modeSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	ModeSheet *m = [ModeSheet new];
	
	m.delegate = self;
	m.window = self.window;
	m.uid = u.uid;
	m.cid = c.uid;
	m.channelName = c.name;
	m.mode = c.mode;
	
	[m start];
	
	self.modeSheet = m;
}

- (void)modeSheetOnOK:(ModeSheet *)sender
{
	IRCChannel *c = [self.world findChannelByClientId:sender.uid channelId:sender.cid];
	IRCClient *u = c.client;
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	NSString *changeStr = [c.mode getChangeCommand:sender.mode];
	
	if (NSObjectIsNotEmpty(changeStr)) {
		[u sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, c.name, changeStr]];
	}
}

- (void)modeSheetWillClose:(ModeSheet *)sender
{
	self.modeSheet = nil;
}

- (void)onAddChannel:(id)sender
{
	if (self.channelSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	
	if (NO_CLIENT) return;
	
	ChannelSheet *d = [ChannelSheet new];
	
	d.delegate = self;
	d.window = self.window;
	d.config = [[IRCChannelConfig alloc] init];
	d.uid = u.uid;
	d.cid = -1;
	
	[d start];
	
	self.channelSheet = d;
}

- (void)onDeleteChannel:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CHANNEL || IS_CLIENT) return;
	
	if (IS_CHANNEL) {
		BOOL result = [PopupPrompts dialogWindowWithQuestion:TXTLS(@"WANT_CHANNEL_DELETE_MESSAGE") 
													   title:TXTLS(@"WANT_CHANNEL_DELETE_TITLE") 
											   defaultButton:TXTLS(@"OK_BUTTON") 
											 alternateButton:TXTLS(@"CANCEL_BUTTON") 
												 otherButton:nil
											  suppressionKey:@"delete_channel"
											 suppressionText:nil];
		
		if (result == NO) {
			return;
		}
	}
	
	[self.world destroyChannel:c];
	[self.world save];
}

- (void)onChannelProperties:(id)sender
{
	if (self.channelSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	ChannelSheet *d = [ChannelSheet new];
	
	d.delegate = self;
	d.window = self.window;
	d.config = [c.config mutableCopy];
	d.uid = u.uid;
	d.cid = c.uid;
	
	[d start];
	
	self.channelSheet = d;
}

- (void)ChannelSheetOnOK:(ChannelSheet *)sender
{
	if (sender.cid < 0) {
		IRCClient *u = [self.world findClientById:sender.uid];
		
		if (NO_CLIENT) return;
		
		[self.world createChannel:sender.config client:u reload:YES adjust:YES];
		[self.world expandClient:u];
	} else {
		IRCChannel *c = [self.world findChannelByClientId:sender.uid channelId:sender.cid];
		
		if (NO_CHANNEL) return;
		
		if (NSObjectIsEmpty(c.config.encryptionKey) && NSObjectIsNotEmpty(sender.config.encryptionKey)) {
			[c.client printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_STARTED") channel:c];
		} else if (NSObjectIsNotEmpty(c.config.encryptionKey) && NSObjectIsEmpty(sender.config.encryptionKey)) {
			[c.client printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_STOPPED") channel:c];
		} else if (NSObjectIsNotEmpty(c.config.encryptionKey) && NSObjectIsNotEmpty(sender.config.encryptionKey)) {
			if ([c.config.encryptionKey isEqualToString:sender.config.encryptionKey] == NO) {
				[c.client printDebugInformation:TXTLS(@"BLOWFISH_ENCRYPTION_KEY_CHANGED") channel:c];
			}
		}
		
		[c updateConfig:sender.config];
	}
	
	[self.world save];
}

- (void)ChannelSheetWillClose:(ChannelSheet *)sender
{
	self.channelSheet = nil;
}

- (void)whoisSelectedMembers:(id)sender deselect:(BOOL)deselect
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT || IS_CLIENT) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendWhois:m.nick];
	}
	
	if (deselect) {
		[self deselectMembers:sender];
	}
}

- (void)memberListDoubleClicked:(id)sender
{
    MemberList *view = sender;
    
    NSPoint pt;
    NSInteger n;
    
    pt = [self.window mouseLocationOutsideOfEventStream];
    pt = [view convertPoint:pt fromView:nil];
    
    n = [view rowAtPoint:pt];
    
    if (n >= 0) {
        if (NSObjectIsNotEmpty([view selectedRowIndexes])) {
            [view selectItemAtIndex:n];
        }
        
        switch ([Preferences userDoubleClickOption]) {
            case USERDC_ACTION_WHOIS: [self whoisSelectedMembers:nil deselect:NO]; break;
            case USERDC_ACTION_QUERY: [self onMemberTalk:nil]; break;
        }
    }
}

- (void)onMemberWhois:(id)sender
{
	[self whoisSelectedMembers:sender deselect:YES];
}

- (void)onMemberTalk:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT || IS_CLIENT) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		IRCChannel *c = [u findChannel:m.nick];
		
		if (NO_CHANNEL) {
			c = [self.world createTalk:m.nick client:u];
		}
		
		[self.world select:c];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberInvite:(id)sender
{
	if (self.inviteSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || NOT_CONNECTED) return;
	
	NSMutableArray *nicks = [NSMutableArray array];
	NSMutableArray *channels = [NSMutableArray array];
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[nicks safeAddObject:m.nick];
	}
	
	for (IRCChannel *e in u.channels) {
		if (NSDissimilarObjects(c, e) && e.isChannel) {
			[channels safeAddObject:e.name];
		}
	}
	
	if (NSObjectIsEmpty(channels)) return;
	
	self.inviteSheet = [InviteSheet new];
	self.inviteSheet.delegate = self;
	self.inviteSheet.window = self.window;
	self.inviteSheet.nicks = nicks;
	self.inviteSheet.uid = u.uid;
	
	[self.inviteSheet startWithChannels:channels];
}

- (void)inviteSheet:(InviteSheet *)sender onSelectChannel:(NSString *)channelName
{
	IRCClient *u = [self.world findClientById:sender.uid];
	
	if (u && NSObjectIsNotEmpty(channelName)) {
		for (NSString *nick in sender.nicks) {
			[u send:IRCCI_INVITE, nick, channelName, nil];
		}
	}
}

- (void)inviteSheetWillClose:(InviteSheet *)sender
{
	self.inviteSheet = nil;
}

- (void)onMemberPing:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT || IS_CLIENT) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPPing:m.nick];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberTime:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT || IS_CLIENT) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCCI_TIME text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberVersion:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT || IS_CLIENT) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCCI_VERSION text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberUserInfo:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT || IS_CLIENT) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCCI_USERINFO text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberClientInfo:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT || IS_CLIENT) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCCI_CLIENTINFO text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)onCopyUrl:(id)sender
{
	if (NSObjectIsNotEmpty(self.pointedUrl)) {
		[_NSPasteboard() setStringContent:self.pointedUrl];
		
		self.pointedUrl = nil;
	}
}

- (void)onJoinChannel:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (NO_CLIENT || NOT_CONNECTED) return;
	
	if (NSObjectIsNotEmpty(self.pointedChannelName)) {
		[u joinUnlistedChannel:self.pointedChannelName];
		
        self.pointedChannelName = nil;
	}
}

- (void)onWantIgnoreListShown:(id)sender
{
	[self showServerPropertyDialog:[self.world selectedClient] ignore:@"-"];
}

- (void)onWantAboutWindowShown:(id)sender
{
	if (self.aboutPanel) {
		[self.aboutPanel show];
		return;
	}
	
	self.aboutPanel = [AboutPanel new];
	self.aboutPanel.delegate = self;
	[self.aboutPanel show];
}

- (void)aboutPanelWillClose:(AboutPanel *)sender
{
	self.aboutPanel = nil;
}

- (void)processModeChange:(id)sender mode:(NSString *)tmode 
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	NSString *opString = NSNullObject;
	
	NSInteger currentIndex = 0;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		opString = [opString stringByAppendingFormat:@"%@ ", m.nick];
		
		currentIndex++;
		
		if (currentIndex == MAXIMUM_SETS_PER_MODE) {
			[u sendCommand:[NSString stringWithFormat:@"%@ %@", tmode, opString] completeTarget:YES target:c.name];
			
			opString = NSNullObject;
			
			currentIndex = 0;
		}
	}
	
	if (opString) {	
		[u sendCommand:[NSString stringWithFormat:@"%@ %@", tmode, opString] completeTarget:YES target:c.name];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberOp:(id)sender 
{ 
	[self processModeChange:sender mode:@"OP"]; 
}

- (void)onMemberDeOp:(id)sender 
{ 
	[self processModeChange:sender mode:@"DEOP"]; 
}

- (void)onMemberHalfOp:(id)sender 
{ 
	[self processModeChange:sender mode:@"HALFOP"]; 
}

- (void)onMemberDeHalfOp:(id)sender 
{ 
	[self processModeChange:sender mode:@"DEHALFOP"]; 
}

- (void)onMemberVoice:(id)sender 
{ 
	[self processModeChange:sender mode:@"VOICE"]; 
}

- (void)onMemberDeVoice:(id)sender 
{ 
	[self processModeChange:sender mode:@"DEVOICE"]; 
}

- (void)onMemberKick:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u kick:c target:m.nick];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberBan:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"BAN %@", m.nick] completeTarget:YES target:c.name];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberBanKick:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"KICKBAN %@ %@", m.nick, [Preferences defaultKickMessage]]
		completeTarget:YES target:c.name];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberKill:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"KILL %@ %@", m.nick, [Preferences IRCopDefaultKillMessage]]];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberGline:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
        if ([m.nick isEqualNoCase:u.myNick]) {
            [u printDebugInformation:TXTFLS(@"SELF_BAN_DETECTED_MESSAGE", u.serverHostname) channel:c];
        } else {
            [u sendCommand:[NSString stringWithFormat:@"GLINE %@ %@", m.nick, [Preferences IRCopDefaultGlineMessage]]];
        }
    }
	
	[self deselectMembers:sender];
}

- (void)onMemberShun:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"SHUN %@ %@", m.nick, [Preferences IRCopDefaultShunMessage]]];
	}
	
	[self deselectMembers:sender];
}

- (void)onWantToReadTextualLogs:(id)sender
{	
	NSString *path = [Preferences transcriptFolder];
	
	if ([_NSFileManager() fileExistsAtPath:path]) {
		[_NSWorkspace() openURL:[NSURL fileURLWithPath:path]];
	} else {
		[PopupPrompts dialogWindowWithQuestion:TXTLS(@"LOG_PATH_DOESNT_EXIST_MESSAGE")
										 title:TXTLS(@"LOG_PATH_DOESNT_EXIST_TITLE")
								 defaultButton:TXTLS(@"OK_BUTTON") 
							   alternateButton:nil 
								   otherButton:nil
								suppressionKey:nil
							   suppressionText:nil];
	}
}

- (void)onWantToReadChannelLogs:(id)sender;
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CLIENT_OR_CHANNEL || IS_CLIENT) return;
	
	NSString *path = [c.logFile buildPath];
	
	if ([_NSFileManager() fileExistsAtPath:path]) {
		[_NSWorkspace() openURL:[NSURL fileURLWithPath:path]];
	} else {
		[PopupPrompts dialogWindowWithQuestion:TXTLS(@"LOG_PATH_DOESNT_EXIST_MESSAGE")
										 title:TXTLS(@"LOG_PATH_DOESNT_EXIST_TITLE")
								 defaultButton:TXTLS(@"OK_BUTTON")
							   alternateButton:nil
								   otherButton:nil
								suppressionKey:nil
							   suppressionText:nil];
	}
}

- (void)onWantTextualConnnectToHelp:(id)sender 
{
	[self.world createConnection:@"chat.freenode.net +6697" chan:@"#textual"];
}

- (void)__onWantHostServVhostSet:(id)sender andVhost:(NSString *)vhost
{
	if (NSObjectIsNotEmpty(vhost)) {
		IRCClient *u = [self.world selectedClient];
		IRCChannel *c = [self.world selectedChannel];
		
		if (NO_CLIENT || IS_CLIENT) return;
		
		NSArray *nicknames = [self selectedMembers:sender];
		
		for (IRCUser *m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"hs setall %@ %@", m.nick, vhost] completeTarget:NO target:nil];
		}
	}
	
	[self deselectMembers:sender];
}

- (void)_onWantHostServVhostSet:(id)sender
{
	NSString *vhost = [PopupPrompts dialogWindowWithInput:TXTLS(@"SET_USER_VHOST_PROMPT_MESSAGE")
													title:TXTLS(@"SET_USER_VHOST_PROMPT_TITLE") 
											defaultButton:TXTLS(@"OK_BUTTON")  
										  alternateButton:TXTLS(@"CANCEL_BUTTON") 
											 defaultInput:nil];
	
	[[self iomt] __onWantHostServVhostSet:sender andVhost:vhost];
}

- (void)onWantHostServVhostSet:(id)sender
{
	[[self invokeInBackgroundThread] _onWantHostServVhostSet:sender];
}

- (void)onWantChannelBanList:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	[[self.world selectedClient] createChanBanListDialog];
	[[self.world selectedClient] send:IRCCI_MODE, [c name], @"+b", nil];
}

- (void)onWantChannelBanExceptionList:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	[[self.world selectedClient] createChanBanExceptionListDialog];
	[[self.world selectedClient] send:IRCCI_MODE, [c name], @"+e", nil];
}

- (void)onWantChannelInviteExceptionList:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	[[self.world selectedClient] createChanInviteExceptionListDialog];
	[[self.world selectedClient] send:IRCCI_MODE, [c name], @"+I", nil];
}

- (void)openHelpMenuLinkItem:(id)sender
{
	switch ([sender tag]) {
		case 101: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/"]]; break;
		case 103: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/text-formatting"]]; break;
		case 104: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/command-reference"]]; break;
		case 105: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/memory-management"]]; break;
		case 106: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/styles"]]; break;
		case 108: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/feature-requests"]]; break;
		case 110: [_NSWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/forum/"]]; break;
	}
}

- (void)processNavigationItem:(NSMenuItem *)sender
{
	switch ([sender tag]) {
		case 50001: [self.master selectNextServer:nil]; break;
		case 50002: [self.master selectPreviousServer:nil]; break;
		case 50003: [self.master selectNextActiveServer:nil]; break;
		case 50004: [self.master selectPreviousActiveServer:nil]; break;
		case 50005: [self.master selectNextChannel:nil]; break;
		case 50006: [self.master selectPreviousChannel:nil]; break;
		case 50007: [self.master selectNextActiveChannel:nil]; break;
		case 50008: [self.master selectPreviousActiveChannel:nil]; break;
		case 50009: [self.master selectNextUnreadChannel:nil]; break;
		case 50010: [self.master selectPreviousUnreadChannel:nil]; break;
		case 50011: [self.master selectPreviousSelection:nil]; break;
		case 50012: [self.master selectNextSelection:nil]; break;
	}
}

- (void)onWantMainWindowShown:(id)sender 
{
	[self.window makeKeyAndOrderFront:nil];
}

- (void)wantsFullScreenModeToggled:(id)sender
{
#ifdef _MAC_OS_LION_OR_NEWER
	if ([Preferences featureAvailableToOSXLion]) {
		if (self.isInFullScreenMode) {
			[self.window toggleFullScreen:sender];
			[self.master loadWindowState];
		} else {
			[self.master saveWindowState];
			[self.window toggleFullScreen:sender];
		}
	} else {
#endif
		
		if (self.isInFullScreenMode == NO) {
			[self.master saveWindowState];
			
			[NSApp setPresentationOptions:(NSApplicationPresentationHideDock | NSApplicationPresentationAutoHideMenuBar)];
			
			[[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
			[[self.window standardWindowButton:NSWindowCloseButton] setHidden:YES];
			[[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
			
			[self.window setShowsResizeIndicator:NO];
			
			[self.window setFrame:[self.window frameRectForContentRect:[[self.window screen] frame]]
						  display:YES animate:YES];
		} else {
			[[self.window standardWindowButton:NSWindowZoomButton] setHidden:NO];
			[[self.window standardWindowButton:NSWindowCloseButton] setHidden:NO];
			[[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:NO];
			
			[self.window setShowsResizeIndicator:YES];
			[self.master loadWindowState];
			
			[NSApp setPresentationOptions:NSApplicationPresentationDefault];
		}
		
#ifdef _MAC_OS_LION_OR_NEWER
	}
#endif
	
	self.isInFullScreenMode = BOOLReverseValue(self.isInFullScreenMode);
}

- (void)onWantChannelListSorted:(id)sender
{
	for (IRCClient *u in [self.world clients]) {
		NSArray *clientChannels = [u.channels sortedArrayUsingFunction:channelDataSort context:nil];
		
		[u.channels removeAllObjects];
		
		for (IRCChannel *c in clientChannels) {
			[u.channels safeAddObject:c];
		}
		
		[u updateConfig:[u storedConfig]];
	}
	
	[self.world save];
}

- (void)onWantThemeForceReloaded:(id)sender
{
	[_NSNotificationCenter() postNotificationName:ThemeStyleDidChangeNotification object:nil userInfo:nil];
}

- (void)onWantChannelModerated:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	[[self.world selectedClient] sendCommand:[NSString stringWithFormat:@"MODE %@ %@", [c name], (([sender tag] == 1) ? @"-m" : @"+m")]];
}

- (void)onWantChannelVoiceOnly:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (NO_CHANNEL || IS_CLIENT || IS_QUERY) return;
	
	[[self.world selectedClient] sendCommand:[NSString stringWithFormat:@"MODE %@ %@", [c name], (([sender tag] == 1) ? @"-i" : @"+i")]];
}

- (void)toggleDeveloperMode:(id)sender
{
    if ([sender state] == NSOnState) {
        [_NSUserDefaults() setBool:NO   forKey:DeveloperEnvironmentToken];
        
        [sender setState:NSOffState];
    } else {
        [_NSUserDefaults() setBool:YES  forKey:DeveloperEnvironmentToken];
        
        [sender setState:NSOnState];
    }
}

- (void)onNextHighlight:(id)sender
{
	[self.world.selected.log nextHighlight];
}

- (void)onPreviousHighlight:(id)sender
{
	[self.world.selected.log previousHighlight];
}

@end
