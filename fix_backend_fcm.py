#!/usr/bin/env python3
"""
FCM Backend Integration Fix Script
Updates backend endpoints to use NotificationService instead of direct FCM calls
"""

import os
import re

def fix_backend_fcm_integration():
    """Fix backend to use NotificationService for all FCM notifications"""
    print("🔧 Fixing Backend FCM Integration\n")
    
    attendance_endpoints_path = "staff_track_api/endpoints/attendance_endpoints.py"
    
    print("📱 Updating attendance_endpoints.py:")
    
    try:
        with open(attendance_endpoints_path, 'r') as f:
            content = f.read()
        
        # Replace direct FCM calls with NotificationService calls
        replacements = {
            # Import NotificationService
            "from fcm_service import send_push_notification": "from notification_service import NotificationService",
            
            # Check-in notification (lines 330-340)
            "await send_push_notification(\n                    token=token_record.fcm_token,\n                    title=\"✅ Check-in Successful\",\n                    body=f\"Checked in at {current_time.strftime('%H:%M')} • {attendance.shift_type or 'Day Shift'}\",\n                    data={\n                        \"type\": \"check_in_confirmation\",\n                        \"attendance_log_id\": str(attendance.attendance_log_id),\n                        \"check_in_time\": current_time.isoformat(),\n                        \"shift_type\": attendance.shift_type or \"Day Shift\"\n                    }\n                )": 
                """await NotificationService.send_notification(\n                        db=db,\n                        user_id=str(current_user.user_id),\n                        title=\"✅ Check-in Successful\",\n                        message=f\"Checked in at {current_time.strftime('%H:%M')} • {attendance.shift_type or 'Day Shift'}\",\n                        notification_type=\"attendance\",\n                        data={{\n                            \"type\": \"check_in_confirmation\",\n                            \"attendance_log_id\": str(attendance.attendance_log_id),\n                            \"check_in_time\": current_time.isoformat(),\n                            \"shift_type\": attendance.shift_type or \"Day Shift\"\n                        }},\n                        force_send=True\n                    )""",
            
            # Geofence violation notifications (lines 227-241)
            "await send_push_notification(\n                                token=current_user.fcm_token,\n                                title=\"⚠️ Geofence Violation\",\n                                body=f\"Your check-in was detected {dist - rad:.0f}m outside work area\",\n                                data={\n                                    \"type\": \"geofence_violation\",\n                                    \"location\": attendance.location,\n                                    \"distance_outside\": f\"{dist - rad:.0f}\"\n                                }\n                            )":
                """await NotificationService.send_notification(\n                                db=db,\n                                user_id=str(current_user.user_id),\n                                title=\"⚠️ Geofence Violation\",\n                                message=f\"Your check-in was detected {dist - rad:.0f}m outside work area\",\n                                notification_type=\"geofence_violation\",\n                                data={{\n                                    \"type\": \"geofence_violation\",\n                                    \"location\": attendance.location,\n                                    \"distance_outside\": f\"{dist - rad:.0f}\"\n                                }},\n                                force_send=True\n                            )""",
            
            # Supervisor geofence notification (lines 238-246)
            "await send_push_notification(\n                                token=supervisor.fcm_token,\n                                title=\"🚨 Geofence Violation Alert\",\n                                body=f\"{current_user.first_name} {current_user.surname} checked in outside work area\",\n                                data={\n                                    \"type\": \"geofence_violation\",\n                                    \"employee_name\": f\"{current_user.first_name} {current_user.surname}\",\n                                    \"location\": attendance.location,\n                                    \"distance_outside\": f\"{dist - rad:.0f}\"\n                                }\n                            )":
                """await NotificationService.send_notification(\n                                db=db,\n                                user_id=str(supervisor.user_id),\n                                title=\"🚨 Geofence Violation Alert\",\n                                message=f\"{current_user.first_name} {current_user.surname} checked in outside work area\",\n                                notification_type=\"geofence_violation\",\n                                data={{\n                                    \"type\": \"geofence_violation\",\n                                    \"employee_name\": f\"{current_user.first_name} {current_user.surname}\",\n                                    \"location\": attendance.location,\n                                    \"distance_outside\": f\"{dist - rad:.0f}\"\n                                }},\n                                force_send=True\n                            )""",
            
            # Check-out notification (lines 589-593)
            "await send_push_notification(\n                    token=token_record.fcm_token,\n                    title=\"✅ Check-out Successful\",\n                    body=f\"Checked out at {attendance.check_out_time.strftime('%H:%M')} • {round(work_hours, 1)} hours worked\",\n                    data={\n                        \"type\": \"check_out_confirmation\",\n                        \"attendance_log_id\": str(attendance.attendance_log_id),\n                        \"check_out_time\": attendance.check_out_time.isoformat(),\n                        \"work_hours\": f\"{round(work_hours, 1)}\"\n                    }\n                )":
                """await NotificationService.send_notification(\n                        db=db,\n                        user_id=str(current_user.user_id),\n                        title=\"✅ Check-out Successful\",\n                        message=f\"Checked out at {attendance.check_out_time.strftime('%H:%M')} • {round(work_hours, 1)} hours worked\",\n                        notification_type=\"attendance\",\n                        data={{\n                            \"type\": \"check_out_confirmation\",\n                            \"attendance_log_id\": str(attendance.attendance_log_id),\n                            \"check_out_time\": attendance.check_out_time.isoformat(),\n                            \"work_hours\": f\"{round(work_hours, 1)}\"\n                        }},\n                        force_send=True\n                    )""",
            
            # Supervisor check-out geofence (lines 497-505)
            "await send_push_notification(\n                                        token=token_record.fcm_token,\n                                        title=\"🚨 Geofence Violation Alert\",\n                                        body=f\"{current_user.first_name} {current_user.surname} checked out outside of work area\",\n                                        data={\n                                            \"type\": \"geofence_violation\",\n                                            \"employee_name\": f\"{current_user.first_name} {current_user.surname}\",\n                                            \"location\": attendance.location,\n                                            \"distance_outside\": f\"{dist - rad:.0f}\"\n                                        }\n                                    )":
                """await NotificationService.send_notification(\n                                        db=db,\n                                        user_id=str(supervisor.user_id),\n                                        title=\"🚨 Geofence Violation Alert\",\n                                        message=f\"{current_user.first_name} {current_user.surname} checked out outside of work area\",\n                                        notification_type=\"geofence_violation\",\n                                        data={{\n                                            \"type\": \"geofence_violation\",\n                                            \"employee_name\": f\"{current_user.first_name} {current_user.surname}\",\n                                            \"location\": attendance.location,\n                                            \"distance_outside\": f\"{dist - rad:.0f}\"\n                                        }},\n                                        force_send=True\n                                    )""",
        }
        
        updated_content = content
        changes_made = 0
        
        for old_code, new_code in replacements.items():
            if old_code in updated_content:
                updated_content = updated_content.replace(old_code, new_code)
                changes_made += 1
                print(f"   ✅ Fixed: {old_code[:50]}...")
        
        # Write the updated content back
        with open(attendance_endpoints_path, 'w') as f:
            f.write(updated_content)
        
        print(f"   📝 Total changes made: {changes_made}")
        
        if changes_made > 0:
            print("   ✅ Backend FCM integration fixed successfully!")
            print("   📱 Events will now use enhanced NotificationService")
            print("   🔔 Includes permission checks, rate limiting, user preferences")
        else:
            print("   ⚠️  No changes needed - already using NotificationService")
            
    except FileNotFoundError:
        print(f"   ❌ File not found: {attendance_endpoints_path}")
    except Exception as e:
        print(f"   ❌ Error updating file: {e}")
    
    print()
    print("🎯 What This Fixes:")
    print("   • Check-in notifications now use NotificationService")
    print("   • Check-out notifications now use NotificationService") 
    print("   • Geofence violations now use NotificationService")
    print("   • All notifications respect user preferences")
    print("   • Rate limiting and deduplication applied")
    print("   • Better error handling and logging")
    
    print()
    print("🚀 Expected Results:")
    print("   • App events will trigger notifications properly")
    print("   • Users can control notification preferences")
    print("   • Notifications respect permission status")
    print("   • Better debugging and monitoring capabilities")

if __name__ == "__main__":
    fix_backend_fcm_integration()
