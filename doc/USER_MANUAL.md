# FR3DiVi Attendance System - User Manual

Version: 1.0  
Last updated: 2026-03-31

## 1. Purpose
This manual explains how to use the FR3DiVi Attendance System application for:
- Daily attendance check-in/check-out (employee/user)
- Admin login and monitoring
- Member management
- Settings configuration

## 2. Who Should Read This
- Employees who record attendance using face scan
- Administrators who manage users, attendance data, and system settings

## 3. Basic Requirements
Before using the app, make sure:
- Device camera permission is enabled
- Face image is already registered for each employee
- Device has good lighting for face detection
- Admin knows valid API login credentials

Default values used by the system (first setup):
- Default admin PIN: 123456
- Default check-in max time: 09:00
- Check-out time is auto-calculated to +1 minute from check-in max time

## 4. Start the App
1. Open the app.
2. Wait for the Initializing screen.
3. When initialization is complete, the Home page appears.
4. Choose one menu:
- Mark Attendance
- Admin Panel

If initialization fails:
- Tap Retry for general initialization errors.
- If Face SDK license error appears, verify SDK assets/license and restart app.

## 5. Employee Guide (Mark Attendance)

### 5.1 Open Attendance Screen
1. On Home page, tap Mark Attendance.
2. Read the instructions shown on Attendance Check-in page.
3. Tap Start Face Scan.

### 5.2 Face Scan Best Practices
For best results:
- Keep face centered in camera frame
- Look directly at camera
- Avoid very dark or very bright lighting
- Keep only one face visible in frame
- Hold still for a moment during matching

### 5.3 During Scanning
On scan screen, user will see:
- Live camera preview
- Top status banner (success/error info)
- Matched user card (name, employee ID, score, liveness)
- Flash toggle (back camera only)
- Switch camera

### 5.4 Attendance Recording Rules
Attendance type is determined by current time and admin settings:
- Check-In allowed from 00:00 until check-in max time
- Check-Out allowed from check-out time onward
- Between those two windows: attendance is rejected

Example with default settings:
- Check-In: until 09:00
- Check-Out: from 09:01

After successful scan:
- Success dialog is shown with employee info and timestamp
- Record is stored in local database

### 5.5 Common User Errors
- "No camera found on this device": use a supported physical device
- "Attendance not allowed at this time": wait for valid check-in/check-out window
- Liveness or quality failure: improve lighting and keep face steady
- Wrong person detected: retry with single face in frame

## 6. Admin Guide

### 6.1 Admin Login
1. From Home page, tap Admin Panel.
2. Enter Username and Password (API credentials).
3. Tap Login.
4. On success, app opens Admin Dashboard.

Notes:
- If login fails, check credentials or API endpoint.
- IP Settings button opens settings to configure API server.

### 6.2 Dashboard Overview
Dashboard provides:
- Quick actions
- Overview cards (Total Members, Present Today, Absent Today)

Quick actions:
- Members List
- Attendance
- Upload Templates
- Upload Attendance
- Settings

### 6.3 Members List
1. Open Members List from dashboard.
2. Search by employee name or employee ID.
3. Tap a member to open Member Details.

Member Details page can show:
- Employee ID, name, department
- Last attendance info
- Account status
- Face template status

### 6.4 Attendance Records (Admin)
1. Open Attendance from dashboard.
2. Select date on calendar strip.
3. Review list with status labels:
- Check-In
- Check-Out
- Absent

### 6.5 Upload Operations
From dashboard:
- Upload Templates: sends stored face templates to server
- Upload Attendance: uploads today attendance data

Expected behavior:
- Success snackbar on completion
- Error snackbar/dialog if failed
- Partial template upload failure may prompt retry

### 6.6 Settings
Open Settings from dashboard (or from login page using IP Settings).

Available configuration:
- API Configuration (IP:Port)
- Check-in max hour and minute
- Auto-calculated check-out time (+1 minute)
- Attendance code and unattendance code fields
- Admin PIN update

Recommended admin actions after first setup:
1. Set correct API IP:Port
2. Verify check-in/out timing policy
3. Change default admin PIN

## 7. Troubleshooting

### 7.1 Camera Issues
Symptoms:
- Camera not opening
- Flash not working

Actions:
1. Confirm camera permission is granted
2. Try switch camera button
3. Restart app
4. Test on physical device

### 7.2 Face Recognition Issues
Symptoms:
- Face not detected
- Liveness says fake
- Frequent mismatch

Actions:
1. Improve lighting
2. Keep only one person in frame
3. Face the camera frontally
4. Ensure user has valid registered template

### 7.3 Attendance Not Recorded
Symptoms:
- Scan succeeds but no expected result

Actions:
1. Check current time against configured check-in/check-out windows
2. Verify user exists in member list
3. Retry scan with stable pose and clear face

### 7.4 API/Upload Issues
Symptoms:
- Admin login error
- Template/attendance upload failed

Actions:
1. Check API IP:Port in Settings
2. Confirm server is reachable on same network
3. Retry upload from dashboard

## 8. Data Notes
- Attendance and user data are stored locally (Hive)
- App may continue local operations even when upload/API is unavailable
- Sync actions are triggered manually from Admin Dashboard

## 9. Screenshot Plan (to be completed)
Add screenshots to this path:
- doc/screenshots/

Recommended file names:
1. 01-home-page.png
2. 02-user-attendance-instructions.png
3. 03-user-scan-live-camera.png
4. 04-user-scan-success-dialog.png
5. 05-admin-login.png
6. 06-admin-dashboard.png
7. 07-members-list.png
8. 08-member-detail.png
9. 09-admin-attendance-calendar.png
10. 10-admin-settings-api-time.png
11. 11-upload-success-message.png
12. 12-upload-error-or-retry-dialog.png

Screenshot insertion template:

## Home Page
![Home Page](screenshots/01-home-page.png)

## User Attendance Instructions
![User Attendance Instructions](screenshots/02-user-attendance-instructions.png)

## User Scan Screen
![User Scan Screen](screenshots/03-user-scan-live-camera.png)

## User Scan Success Dialog
![User Scan Success Dialog](screenshots/04-user-scan-success-dialog.png)

## Admin Login
![Admin Login](screenshots/05-admin-login.png)

## Admin Dashboard
![Admin Dashboard](screenshots/06-admin-dashboard.png)

## Members List
![Members List](screenshots/07-members-list.png)

## Member Detail
![Member Detail](screenshots/08-member-detail.png)

## Admin Attendance
![Admin Attendance](screenshots/09-admin-attendance-calendar.png)

## Admin Settings
![Admin Settings](screenshots/10-admin-settings-api-time.png)

## Upload Success Message
![Upload Success Message](screenshots/11-upload-success-message.png)

## Upload Error or Retry Dialog
![Upload Error or Retry Dialog](screenshots/12-upload-error-or-retry-dialog.png)

## 10. Revision History
- v1.0 (2026-03-31): Initial user manual draft with workflow and screenshot checklist.
