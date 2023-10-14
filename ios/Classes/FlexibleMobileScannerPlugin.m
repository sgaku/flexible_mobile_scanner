#import "FlexibleMobileScannerPlugin.h"
#if __has_include(<flexible_mobile_scanner/flexible_mobile_scanner-Swift.h>)
#import <flexible_mobile_scanner/flexible_mobile_scanner-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "mobile_scanner-Swift.h"
#endif

@implementation FlexibleMobileScannerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlexibleMobileScannerPlugin registerWithRegistrar:registrar];
}
@end
