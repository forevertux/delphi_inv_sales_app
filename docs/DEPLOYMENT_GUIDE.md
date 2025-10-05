# Deployment Guide - Inventory & Sales Management System

This guide provides step-by-step instructions for deploying the Inventory & Sales Management System across different platforms and environments.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Database Deployment](#database-deployment)
3. [Desktop Deployment](#desktop-deployment)
4. [Mobile Deployment](#mobile-deployment)
5. [Server Configuration](#server-configuration)
6. [Security Hardening](#security-hardening)
7. [Monitoring & Maintenance](#monitoring--maintenance)

---

## Pre-Deployment Checklist

### Development Environment Verification

- [ ] All unit tests passing
- [ ] Code review completed
- [ ] Security audit performed
- [ ] Performance testing completed
- [ ] Documentation updated
- [ ] Version numbers updated in project files

### Infrastructure Requirements

#### Database Server
- [ ] SQL Server 2014+ / MySQL 5.7+ / PostgreSQL 10+ / Oracle 12c+
- [ ] Minimum 4GB RAM
- [ ] 20GB storage (initial), plan for growth
- [ ] Network connectivity to application servers
- [ ] Backup solution configured

#### Application Server (for sync API)
- [ ] Windows Server 2016+ or Linux (Ubuntu 18.04+)
- [ ] IIS 10+ or nginx
- [ ] .NET Runtime or appropriate web framework
- [ ] SSL certificate for HTTPS
- [ ] 2GB+ RAM minimum

#### Client Devices
**Desktop:**
- [ ] Windows 10+ or macOS 10.14+
- [ ] 2GB RAM minimum
- [ ] 500MB disk space
- [ ] Network access to database

**Mobile:**
- [ ] Android 6.0+ or iOS 12+
- [ ] 100MB free space
- [ ] WiFi or cellular data connection

---

## Database Deployment

### Step 1: Choose Database Platform

**SQL Server (Recommended for Windows environments)**
```sql
-- Create database
CREATE DATABASE InventorySales;
GO

-- Create login
CREATE LOGIN inventory_app WITH PASSWORD = 'SecurePassword123!';
GO

USE InventorySales;
GO

-- Create user
CREATE USER inventory_app FOR LOGIN inventory_app;
GO

-- Grant permissions
ALTER ROLE db_datareader ADD MEMBER inventory_app;
ALTER ROLE db_datawriter ADD MEMBER inventory_app;
GO
```

**MySQL (Recommended for cross-platform)**
```sql
-- Create database
CREATE DATABASE inventory_sales CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user
CREATE USER 'inventory_app'@'%' IDENTIFIED BY 'SecurePassword123!';

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON inventory_sales.* TO 'inventory_app'@'%';
FLUSH PRIVILEGES;
```

**PostgreSQL**
```sql
-- Create database
CREATE DATABASE inventory_sales WITH ENCODING 'UTF8';

-- Create user
CREATE USER inventory_app WITH PASSWORD 'SecurePassword123!';

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE inventory_sales TO inventory_app;
```

### Step 2: Execute Schema

```bash
# Navigate to database directory
cd /path/to/sales_inventory/database

# SQL Server
sqlcmd -S server_name -U sa -P password -d InventorySales -i schema.sql

# MySQL
mysql -h server_name -u root -p inventory_sales < schema.sql

# PostgreSQL
psql -h server_name -U postgres -d inventory_sales -f schema.sql
```

### Step 3: Verify Installation

```sql
-- Check tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo'; -- SQL Server
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'inventory_sales'; -- MySQL
SELECT tablename FROM pg_tables WHERE schemaname = 'public'; -- PostgreSQL

-- Verify sample data
SELECT COUNT(*) FROM Users; -- Should return 3
SELECT COUNT(*) FROM Products; -- Should return 5
SELECT COUNT(*) FROM Categories; -- Should return 5
```

### Step 4: Configure Backups

**SQL Server (T-SQL)**
```sql
-- Full backup daily at 2 AM
BACKUP DATABASE InventorySales
TO DISK = 'C:\Backups\InventorySales_Full.bak'
WITH INIT, COMPRESSION;

-- Create maintenance plan or SQL Server Agent job
```

**MySQL (Shell)**
```bash
# Add to crontab for daily backup at 2 AM
0 2 * * * /usr/bin/mysqldump -u root -p'password' inventory_sales > /backups/inventory_sales_$(date +\%Y\%m\%d).sql
```

**PostgreSQL (Shell)**
```bash
# Add to crontab for daily backup at 2 AM
0 2 * * * /usr/bin/pg_dump -U postgres inventory_sales > /backups/inventory_sales_$(date +\%Y\%m\%d).sql
```

---

## Desktop Deployment

### Windows Deployment

#### Option 1: Manual Installation

1. **Build the application**:
   ```
   - Open InventorySales.dproj in Delphi
   - Select Release configuration
   - Select Win32 or Win64 platform
   - Build → Build InventorySales
   ```

2. **Prepare deployment package**:
   ```
   deployment/
   ├── InventorySales.exe
   ├── InventorySales.ini.sample
   ├── README.txt
   └── database/
       └── schema.sql
   ```

3. **Create installation script** (`install.bat`):
   ```batch
   @echo off
   echo Installing Inventory & Sales Management System...

   REM Create application directory
   mkdir "C:\Program Files\InventorySales"

   REM Copy files
   xcopy /E /I *.* "C:\Program Files\InventorySales\"

   REM Copy config template
   copy InventorySales.ini.sample "C:\Program Files\InventorySales\InventorySales.ini"

   REM Create desktop shortcut
   powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\Desktop\Inventory Sales.lnk');$s.TargetPath='C:\Program Files\InventorySales\InventorySales.exe';$s.Save()"

   echo Installation complete!
   pause
   ```

#### Option 2: Inno Setup Installer

1. **Create setup script** (`setup.iss`):
   ```ini
   [Setup]
   AppName=Inventory Sales Management
   AppVersion=1.0.0
   DefaultDirName={pf}\InventorySales
   DefaultGroupName=Inventory Sales
   OutputDir=Output
   OutputBaseFilename=InventorySales_Setup_v1.0.0
   Compression=lzma2
   SolidCompression=yes

   [Files]
   Source: "InventorySales.exe"; DestDir: "{app}"
   Source: "InventorySales.ini.sample"; DestDir: "{app}"; DestName: "InventorySales.ini"
   Source: "README.md"; DestDir: "{app}"
   Source: "database\*"; DestDir: "{app}\database"; Flags: recursesubdirs

   [Icons]
   Name: "{group}\Inventory Sales"; Filename: "{app}\InventorySales.exe"
   Name: "{commondesktop}\Inventory Sales"; Filename: "{app}\InventorySales.exe"

   [Run]
   Filename: "{app}\InventorySales.exe"; Description: "Launch Inventory Sales"; Flags: nowait postinstall skipifsilent
   ```

2. **Build installer**:
   ```
   - Install Inno Setup
   - Open setup.iss
   - Build → Compile
   - Output: InventorySales_Setup_v1.0.0.exe
   ```

### macOS Deployment

1. **Build application**:
   ```
   - Open InventorySales.dproj in Delphi
   - Select Release configuration
   - Select macOS64 platform
   - Build → Build InventorySales
   ```

2. **Create DMG package**:
   ```bash
   # Create DMG structure
   mkdir -p dmg/InventorySales.app

   # Copy application
   cp -R InventorySales.app dmg/

   # Copy config
   cp InventorySales.ini.sample dmg/InventorySales.ini

   # Create DMG
   hdiutil create -volname "Inventory Sales" -srcfolder dmg -ov -format UDZO InventorySales.dmg
   ```

3. **Sign the application** (for distribution):
   ```bash
   codesign --force --deep --sign "Developer ID Application: Your Name" InventorySales.app
   ```

---

## Mobile Deployment

### Android Deployment

#### Step 1: Configure Project

1. **Set application properties**:
   ```
   - Project → Options → Application
   - Version Info:
     - Version: 1.0.0
     - Build: 1
   - Package Name: com.yourcompany.inventorysales
   ```

2. **Configure permissions** (AndroidManifest.xml):
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
   ```

3. **Configure icons**:
   ```
   - Add launcher icons (ldpi, mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
   - Add splash screen images
   - Project → Deployment → Add Files
   ```

#### Step 2: Build APK

1. **Debug Build** (for testing):
   ```
   - Select Android platform
   - Select Debug configuration
   - Run → Run Without Debugging (Ctrl+Shift+F9)
   - APK location: Android\Debug\InventorySales.apk
   ```

2. **Release Build** (for production):
   ```
   - Select Android platform
   - Select Release configuration
   - Build → Build InventorySales
   ```

#### Step 3: Sign APK

```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore inventorysales.keystore -alias inventorysales -keyalg RSA -keysize 2048 -validity 10000

# Sign APK
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore inventorysales.keystore InventorySales.apk inventorysales

# Verify signature
jarsigner -verify -verbose -certs InventorySales.apk

# Optimize APK
zipalign -v 4 InventorySales.apk InventorySales-aligned.apk
```

#### Step 4: Deploy to Google Play

1. **Create Google Play Console account**
2. **Create new application**
3. **Upload APK**:
   - Go to Release → Production
   - Create new release
   - Upload InventorySales-aligned.apk
   - Fill in release notes
   - Review and rollout

### iOS Deployment

#### Step 1: Configure Project

1. **Set application properties**:
   ```
   - Project → Options → Application
   - Version Info:
     - Version: 1.0.0
     - Build: 1
   - Bundle Identifier: com.yourcompany.inventorysales
   ```

2. **Configure capabilities**:
   ```
   - Enable Background Modes (for sync)
   - Enable Network connectivity
   ```

#### Step 2: Build IPA

1. **Ad Hoc Build** (for testing):
   ```
   - Select iOSDevice64 platform
   - Select Ad Hoc configuration
   - Build → Build InventorySales
   ```

2. **App Store Build**:
   ```
   - Select iOSDevice64 platform
   - Select App Store configuration
   - Build → Build InventorySales
   ```

#### Step 3: Deploy to App Store

1. **Create App Store Connect account**
2. **Create new app**
3. **Upload IPA using Xcode**:
   ```bash
   # Use Application Loader or Xcode
   - Xcode → Window → Organizer
   - Select Archive
   - Distribute App
   - Upload to App Store
   ```

---

## Server Configuration

### Sync API Server Setup

#### Option 1: ASP.NET Core API

1. **Create API project**:
   ```bash
   dotnet new webapi -n InventorySales.API
   cd InventorySales.API
   ```

2. **Implement endpoints**:
   ```csharp
   // Controllers/SyncController.cs
   [ApiController]
   [Route("api/[controller]")]
   public class SyncController : ControllerBase
   {
       [HttpPost("upload")]
       public IActionResult Upload([FromBody] SyncData data)
       {
           // Process sync data
           return Ok(new { status = "success" });
       }

       [HttpGet("download")]
       public IActionResult Download([FromQuery] DateTime lastSync)
       {
           // Return changes since lastSync
           return Ok(changes);
       }
   }
   ```

3. **Deploy to IIS**:
   ```bash
   # Publish
   dotnet publish -c Release -o ./publish

   # Copy to IIS
   xcopy /E /I publish "C:\inetpub\wwwroot\InventorySalesAPI"

   # Configure IIS application pool
   ```

#### Option 2: Node.js/Express API

1. **Create API project**:
   ```bash
   npm init -y
   npm install express body-parser mysql2
   ```

2. **Implement server** (`server.js`):
   ```javascript
   const express = require('express');
   const app = express();

   app.post('/api/sync/upload', (req, res) => {
       // Process sync data
       res.json({ status: 'success' });
   });

   app.get('/api/sync/download', (req, res) => {
       // Return changes
       res.json({ changes: [] });
   });

   app.listen(3000);
   ```

3. **Deploy with PM2**:
   ```bash
   npm install -g pm2
   pm2 start server.js --name inventory-api
   pm2 save
   pm2 startup
   ```

### Configure Reverse Proxy (nginx)

```nginx
server {
    listen 80;
    server_name api.yourcompany.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name api.yourcompany.com;

    ssl_certificate /path/to/cert.crt;
    ssl_certificate_key /path/to/cert.key;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## Security Hardening

### 1. Database Security

```sql
-- Change default passwords
UPDATE Users SET PasswordHash = HashFunction('NewSecurePassword') WHERE Username = 'admin';

-- Disable unnecessary accounts
UPDATE Users SET IsActive = 0 WHERE Username IN ('manager', 'employee');

-- Enable SSL for connections (SQL Server)
EXEC sp_configure 'force encryption', 1;
RECONFIGURE;

-- Restrict network access
-- Configure firewall to allow only application server IPs
```

### 2. Application Security

**Update HashUtils.pas** for stronger hashing:
```pascal
uses
  System.Hash.BCrypt; // Add BCrypt unit

function HashPassword(const Password: string): string;
begin
  Result := THashBCrypt.HashPassword(Password);
end;

function VerifyPassword(const Password, Hash: string): Boolean;
begin
  Result := THashBCrypt.VerifyPassword(Password, Hash);
end;
```

**Implement session timeout** in AuthService:
```pascal
const
  SESSION_TIMEOUT = 30; // minutes

function TAuthService.ValidateSession: Boolean;
begin
  Result := FIsAuthenticated and
            (FCurrentUser.UserID > 0) and
            (MinutesBetween(Now, FCurrentUser.LastLogin) < SESSION_TIMEOUT);
end;
```

### 3. Network Security

- [ ] Enable HTTPS/TLS for all connections
- [ ] Implement API authentication tokens
- [ ] Use VPN for remote database access
- [ ] Configure firewalls to restrict access
- [ ] Enable database connection encryption

### 4. Mobile Security

- [ ] Implement certificate pinning
- [ ] Encrypt local SQLite database
- [ ] Use secure storage for credentials
- [ ] Implement jailbreak/root detection
- [ ] Enable ProGuard/R8 for Android
- [ ] Enable bitcode for iOS

---

## Monitoring & Maintenance

### Database Monitoring

**SQL Server**:
```sql
-- Monitor active connections
SELECT * FROM sys.dm_exec_sessions WHERE is_user_process = 1;

-- Monitor query performance
SELECT TOP 10
    qs.execution_count,
    qs.total_worker_time/1000 AS TotalCPUTimeMs,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS statement
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY qs.total_worker_time DESC;

-- Check database size
EXEC sp_spaceused;
```

**MySQL**:
```sql
-- Monitor connections
SHOW PROCESSLIST;

-- Monitor slow queries
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;

-- Check database size
SELECT
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
GROUP BY table_schema;
```

### Application Monitoring

**Create monitoring script** (`monitor.ps1`):
```powershell
# Check application status
$process = Get-Process InventorySales -ErrorAction SilentlyContinue
if (!$process) {
    Write-Host "Application not running!"
    # Send alert email
}

# Check disk space
$drive = Get-PSDrive C
if ($drive.Free -lt 5GB) {
    Write-Host "Low disk space: $($drive.Free / 1GB) GB remaining"
}

# Check database connectivity
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=localhost;Database=InventorySales;Integrated Security=true"
try {
    $connection.Open()
    Write-Host "Database connection: OK"
} catch {
    Write-Host "Database connection: FAILED"
} finally {
    $connection.Close()
}
```

### Maintenance Tasks

**Weekly Tasks**:
- [ ] Review error logs
- [ ] Check database performance
- [ ] Verify backup completion
- [ ] Review user activity logs
- [ ] Check disk space usage

**Monthly Tasks**:
- [ ] Update statistics (database)
- [ ] Rebuild fragmented indexes
- [ ] Archive old transaction data
- [ ] Review security audit logs
- [ ] Update documentation

**Quarterly Tasks**:
- [ ] Performance review and optimization
- [ ] Security assessment
- [ ] Disaster recovery drill
- [ ] User training refresh
- [ ] Version updates and patches

### Logging Configuration

**Enable application logging** (add to Utils):
```pascal
unit LogUtils;

interface

procedure LogInfo(const Message: string);
procedure LogError(const Message: string);
procedure LogDebug(const Message: string);

implementation

uses
  System.IOUtils, System.SysUtils;

const
  LOG_FILE = 'InventorySales.log';

procedure WriteLog(const Level, Message: string);
var
  LogPath: string;
  LogText: string;
begin
  LogPath := TPath.Combine(TPath.GetDocumentsPath, LOG_FILE);
  LogText := Format('[%s] %s: %s', [
    FormatDateTime('yyyy-mm-dd hh:nn:ss', Now),
    Level,
    Message
  ]);

  TFile.AppendAllText(LogPath, LogText + sLineBreak);
end;

procedure LogInfo(const Message: string);
begin
  WriteLog('INFO', Message);
end;

procedure LogError(const Message: string);
begin
  WriteLog('ERROR', Message);
end;

procedure LogDebug(const Message: string);
begin
  {$IFDEF DEBUG}
  WriteLog('DEBUG', Message);
  {$ENDIF}
end;

end.
```

---

## Troubleshooting Deployment Issues

### Issue: Database connection fails

**Check**:
1. Database server is running
2. Firewall allows connections
3. Connection string is correct
4. User has proper permissions

**Solution**:
```bash
# Test connection
telnet database_server 1433  # SQL Server
telnet database_server 3306  # MySQL
telnet database_server 5432  # PostgreSQL
```

### Issue: Mobile app crashes on startup

**Check**:
1. All required permissions granted
2. Sufficient storage available
3. Compatible OS version
4. Check crash logs

**Solution (Android)**:
```bash
# View logs
adb logcat | grep InventorySales

# Check permissions
adb shell pm list permissions -d -g
```

### Issue: Sync not working

**Check**:
1. Network connectivity
2. Server URL is correct
3. API is running
4. Check SyncLog for errors

**Solution**:
```sql
-- Check sync errors
SELECT * FROM SyncLog WHERE SyncStatus = 'Failed' ORDER BY CreatedAt DESC LIMIT 10;

-- Clear failed sync attempts
DELETE FROM SyncLog WHERE SyncStatus = 'Failed' AND CreatedAt < DATE_SUB(NOW(), INTERVAL 7 DAY);
```

---

## Support & Escalation

**Level 1 Support** (Users):
- Check README.md
- Review error messages
- Verify configuration

**Level 2 Support** (IT Team):
- Database connectivity
- Network troubleshooting
- Application configuration
- Backup restoration

**Level 3 Support** (Development Team):
- Code issues
- Performance optimization
- Security incidents
- Major bugs

**Contact Information**:
- Email: support@yourcompany.com
- Phone: +1-555-0100
- Emergency: +1-555-0911

---

**Document Version**: 1.0.0
**Last Updated**: October 2025
**Next Review**: January 2026
