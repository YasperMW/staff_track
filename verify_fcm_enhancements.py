#!/usr/bin/env python3
"""
FCM Enhancement Verification Script
Verifies that all FCM enhancements are properly implemented
"""

import os
import re

def verify_fcm_enhancements():
    """Verify all FCM enhancements are correctly implemented"""
    print("🔍 FCM Enhancement Verification\n")
    
    # Check FCM service enhancements
    fcm_service_path = "lib/services/fcm_service.dart"
    
    print("📱 Checking FCM Service Enhancements:")
    
    try:
        with open(fcm_service_path, 'r') as f:
            content = f.read()
            
        enhancements = {
            "NotificationPermissionStatus enum": "enum NotificationPermissionStatus" in content,
            "getNotificationPermissionStatus method": "getNotificationPermissionStatus()" in content,
            "requestNotificationPermissions method": "requestNotificationPermissions(" in content,
            "Permission rationale dialog": "_showPermissionRationaleDialog()" in content,
            "Open app settings": "_openAppSettings()" in content,
            "Retry initialization": "retryInitialization()" in content,
            "Check and request permissions": "checkAndRequestPermissions(" in content,
            "Test notification setup": "testNotificationSetup()" in content,
            "Get notification settings": "getNotificationSettings()" in content,
            "Enhanced initialize method": "permissionStatus == NotificationPermissionStatus.granted" in content,
        }
        
        for feature, status in enhancements.items():
            print(f"   {'✅' if status else '❌'} {feature:<40} {status}")
            
    except FileNotFoundError:
        print(f"   ❌ FCM service file not found: {fcm_service_path}")
    
    print()
    
    # Check notification settings screen
    notification_settings_path = "lib/screens/SharedScreens/notification_settings_screen.dart"
    
    print("📱 Checking Notification Settings Screen:")
    
    try:
        with open(notification_settings_path, 'r') as f:
            content = f.read()
            
        settings_features = {
            "NotificationSettingsScreen class": "class NotificationSettingsScreen" in content,
            "Permission status card": "_buildPermissionStatusCard()" in content,
            "Test results card": "_buildTestResultsCard()" in content,
            "Request permissions button": "Request Permissions" in content,
            "Test notifications button": "Test Notifications" in content,
            "Troubleshooting guide": "Troubleshooting" in content,
            "Loading states": "_isLoading" in content,
            "SnackBar feedback": "ScaffoldMessenger.of(context).showSnackBar" in content,
        }
        
        for feature, status in settings_features.items():
            print(f"   {'✅' if status else '❌'} {feature:<40} {status}")
            
        # Check for color fixes
        color_issues = []
        if "AppTheme.successColor" in content:
            color_issues.append("AppTheme.successColor still present")
        if "AppTheme.errorColor" in content:
            color_issues.append("AppTheme.errorColor still present")
        if "AppTheme.primaryColor" in content:
            color_issues.append("AppTheme.primaryColor still present")
        if "AppTheme.secondaryColor" in content:
            color_issues.append("AppTheme.secondaryColor still present")
        if "Icons.test" in content:
            color_issues.append("Icons.test still present")
            
        if color_issues:
            print(f"\n   ⚠️  Color/Icon Issues Found:")
            for issue in color_issues:
                print(f"      • {issue}")
        else:
            print(f"   ✅ All color/icon references fixed")
            
    except FileNotFoundError:
        print(f"   ❌ Notification settings file not found: {notification_settings_path}")
    
    print()
    
    # Check profile screen integration
    profile_screen_path = "lib/screens/SharedScreens/profile_screen.dart"
    
    print("📱 Checking Profile Screen Integration:")
    
    try:
        with open(profile_screen_path, 'r') as f:
            content = f.read()
            
        profile_features = {
            "Notification settings import": "import 'notification_settings_screen.dart'" in content,
            "Navigate to notification settings": "_navigateToNotificationSettings(" in content,
            "Enhanced buildOptionTile": "VoidCallback? onTap" in content,
            "Notifications tile with onTap": "Notifications" in content and "onTap:" in content,
        }
        
        for feature, status in profile_features.items():
            print(f"   {'✅' if status else '❌'} {feature:<40} {status}")
            
    except FileNotFoundError:
        print(f"   ❌ Profile screen file not found: {profile_screen_path}")
    
    print()
    
    # Check main.dart cleanup
    main_dart_path = "lib/main.dart"
    
    print("📱 Checking Main.dart Cleanup:")
    
    try:
        with open(main_dart_path, 'r') as f:
            content = f.read()
            
        main_features = {
            "FCM import removed": "import 'services/fcm_service.dart'" not in content,
            "Firebase core present": "import 'package:firebase_core/firebase_core.dart'" in content,
        }
        
        for feature, status in main_features.items():
            print(f"   {'✅' if status else '❌'} {feature:<40} {status}")
            
    except FileNotFoundError:
        print(f"   ❌ Main.dart file not found: {main_dart_path}")
    
    print()
    
    # Summary
    print("📊 Enhancement Summary:")
    print("=" * 50)
    
    all_checks = []
    
    # Count all successful checks
    try:
        with open(fcm_service_path, 'r') as f:
            all_checks.extend([enhancements[feature] for feature, status in enhancements.items() if status])
    except:
        pass
    
    try:
        with open(notification_settings_path, 'r') as f:
            all_checks.extend([settings_features[feature] for feature, status in settings_features.items() if status])
            # Check color fixes
            if not any(issue in f.read() for issue in ["AppTheme.successColor", "AppTheme.errorColor", "AppTheme.primaryColor", "AppTheme.secondaryColor", "Icons.test"]):
                all_checks.append("Color/icon fixes applied")
    except:
        pass
    
    try:
        with open(profile_screen_path, 'r') as f:
            all_checks.extend([profile_features[feature] for feature, status in profile_features.items() if status])
    except:
        pass
    
    try:
        with open(main_dart_path, 'r') as f:
            all_checks.extend([main_features[feature] for feature, status in main_features.items() if status])
    except:
        pass
    
    success_count = len(all_checks)
    total_expected = 25  # Approximate number of expected enhancements
    
    print(f"✅ Successful Enhancements: {success_count}")
    print(f"📈 Implementation Rate: {(success_count/total_expected)*100:.1f}%")
    
    if success_count >= total_expected * 0.9:  # 90% success rate
        print("🎉 FCM Enhancement Implementation: EXCELLENT")
        print("   All major features implemented successfully")
    elif success_count >= total_expected * 0.7:  # 70% success rate
        print("👍 FCM Enhancement Implementation: GOOD")
        print("   Most features implemented, minor issues may remain")
    else:
        print("⚠️  FCM Enhancement Implementation: NEEDS ATTENTION")
        print("   Some critical features may be missing")
    
    print("\n🚀 Ready for Testing:")
    print("   1. Run 'flutter clean && flutter pub get'")
    print("   2. Test on Android 13+ device")
    print("   3. Test permission flow (deny → allow)")
    print("   4. Test notification settings screen")
    print("   5. Verify FCM token registration")

if __name__ == "__main__":
    verify_fcm_enhancements()
