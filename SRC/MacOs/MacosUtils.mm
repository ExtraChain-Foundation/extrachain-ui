#include "MacosUtils.h"
#include <QPointer>

//#import <AppKit/AppKit.h>
#include <Foundation/Foundation.h>
#include <LocalAuthentication/LocalAuthentication.h>

#ifdef Q_OS_IOS
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#include <QDebug>
#endif

#if defined(Q_OS_MACOS) && !defined(QT_DEBUG) && !defined(RACCOON_RELEASE_WITH_DEBUG_INFO)
#import <Sparkle/Sparkle.h>
#endif

ApplePlatformUtils::ApplePlatformUtils(QObject *parent)
    : QObject(parent) {
}

void ApplePlatformUtils::clipboard(const QString &text) {
    //    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    //    [pasteboard clearContents];
    //
    //    NSString *nsText = [NSString stringWithUTF8String:text.toUtf8().constData()];
    //    NSArray *objectsToPaste = @[ nsText ];
    //    [pasteboard writeObjects:objectsToPaste];
}

#if defined(Q_OS_MACOS) && !defined(QT_DEBUG) && !defined(RACCOON_RELEASE_WITH_DEBUG_INFO)
@interface UpdaterDelegate : NSObject <SPUUpdaterDelegate, SPUStandardUserDriverDelegate>
@end

@implementation UpdaterDelegate

- (NSString *)feedURLStringForUpdater:(SPUUpdater *)updater {
    return @"https://raccoonline.com/api/assets/apps/appcast_rl_vpn.xml";
}

- (BOOL)allowsSkippingUpdates:(SPUUpdater *)updater {
    return NO;
}

- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SPUUpdater *)updater {
    return NO;
}

- (BOOL)standardUserDriverShouldShowUpdateAlertForItem:(SUAppcastItem *)item {
    return YES;
}

- (NSSet<NSString *> *)standardUserDriverAllowedSystemVersionRequirementKeys:(SPUStandardUserDriver *)userDriver {
    return [NSSet set];
}

- (BOOL)standardUserDriverShouldHandleInformationalUpdatesOnly:(SPUStandardUserDriver *)userDriver {
    return NO;
}

- (SPUUserUpdateChoice)standardUserDriverWillHandleStandardUserUpdateRequest:(SPUStandardUserDriver *)userDriver forItem:(SUAppcastItem *)item {
    return SPUUserUpdateChoiceInstall;
}

- (NSTimeInterval)standardUserDriverRemindMeLaterInterval:(SPUStandardUserDriver *)userDriver forItem:(SUAppcastItem *)item {
    return 24 * 60 * 60;
}

@end

void ApplePlatformUtils::init_sparkle() {
    UpdaterDelegate *delegate = [[UpdaterDelegate alloc] init];
    SPUStandardUpdaterController *updaterController = [[SPUStandardUpdaterController alloc]
        initWithStartingUpdater:YES
                updaterDelegate:delegate
             userDriverDelegate:delegate];
    [updaterController checkForUpdates:nil];
}
#else
void ApplePlatformUtils::init_sparkle() {
}
#endif

#ifdef Q_OS_IOS
void ApplePlatformUtils::authenticateWithFaceID(std::function<void(bool, const char*)> callback) {
    LAContext *context = [[LAContext alloc] init];
    NSError *error = nil;
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:@"This app uses Face ID for authentication."
                          reply:^(BOOL success, NSError * _Nullable authError) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  if (callback) {
                                      if (success) {
                                          callback(true, "");
                                      } else {
                                          NSString *errorString = authError ? authError.localizedDescription : @"Unknown error";
                                          NSInteger code = authError.code;

                                          switch (code) {
                                          case LAErrorUserCancel:
                                              errorString = @"User cancelled";
                                              break;
                                          case LAErrorUserFallback:
                                              errorString = @"User chose to enter password";
                                              requestPasscodeFallback(callback);
                                              return;
                                          case LAErrorAuthenticationFailed:
                                              errorString = @"Authentication failed";
                                              break;
                                          case LAErrorSystemCancel:
                                              errorString = @"System cancelled";
                                              break;
                                          case LAErrorAppCancel:
                                              errorString = @"App cancelled authentication";
                                              break;
                                          case LAErrorBiometryLockout:
                                              errorString = @"Biometry locked out; requires passcode";
                                              break;
                                          default:
                                              break;
                                          }

                                          callback(false, errorString.UTF8String);
                                      }
                                  }
                              });

                          }];
    } else {
        if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(false, error.localizedDescription.UTF8String);
            });
        }
    }
}

void ApplePlatformUtils::requestPasscodeFallback(std::function<void(bool, const char*)> callback) {
    LAContext *context = [[LAContext alloc] init];
    NSError *error = nil;

    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error]) {
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
                localizedReason:@"Please authenticate to continue."
                          reply:^(BOOL success, NSError * _Nullable authError) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  if (callback) {
                                      if (success) {
                                          callback(true, "");
                                      } else {
                                          NSString *msg = authError ? authError.localizedDescription : @"Unknown error";
                                          callback(false, msg.UTF8String);
                                      }
                                  }
                              });
                          }];
    } else {
        if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(false, error.localizedDescription.UTF8String);
            });
        }
    }
}

void ApplePlatformUtils::triggerFaceID() {
    QPointer<ApplePlatformUtils> safeSelf = this;
    authenticateWithFaceID([safeSelf](bool success, const char *errorMessage) {
        qDebug() << "Inside callback, success:" << success << " error:" << errorMessage;
        emit safeSelf->resultFaceId(success);
    });
}

bool ApplePlatformUtils::isFaceIDAvailable() {
    LAContext *context = [[LAContext alloc] init];
    NSError *error = nil;

    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        if (@available(iOS 11.0, *)) {
            return context.biometryType == LABiometryTypeFaceID;
        } else {
            return false;
        }
    }

    return false;
}

void ApplePlatformUtils::vibrate() {
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator =
            [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [generator prepare];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(200 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [generator impactOccurred];
        });
    }
}

#endif
