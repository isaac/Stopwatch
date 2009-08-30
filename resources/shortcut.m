// shortcut.m
// 
// compile:
// gcc shortcut.m -o shortcut.bundle -g -framework Foundation -framework Carbon -dynamiclib -fobjc-gc -arch i386 -arch x86_64

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface Shortcut : NSObject
{
    id delegate;
}
@property (assign) id delegate;
- (void) addShortcut;
- (void) hotkeyWasPressed;
@end
OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData);


@implementation Shortcut
@synthesize delegate;

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData)
{    
    if ( userData != NULL ) {
        id delegate = (id)userData;
        if ( delegate && [delegate respondsToSelector:@selector(hotkeyWasPressed)] ) {
          [delegate hotkeyWasPressed];
        }
    }
    return noErr;
}

- (void) addShortcut
{
    EventHotKeyRef myHotKeyRef;
    EventHotKeyID myHotKeyID;
    EventTypeSpec eventType;
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
    if ( delegate == nil )
      delegate = self;
    EventTargetRef eventTarget = (EventTargetRef) GetEventMonitorTarget();
    InstallEventHandler(eventTarget, &myHotKeyHandler, 1, &eventType, (void *)delegate, NULL);
    myHotKeyID.signature='mhk1';
    myHotKeyID.id=1;
    RegisterEventHotKey(49, controlKey+optionKey, myHotKeyID, eventTarget, 0, &myHotKeyRef);
}

- (void) hotkeyWasPressed {};

@end

void Init_shortcut(void) {}