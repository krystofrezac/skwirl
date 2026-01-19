# Skwirl - Vision & Goals

## Problem

Users storing data in cloud services (Google Drive, iCloud, etc.) face multiple risks:

- **Data loss** from provider issues or account termination
- **Silent modification** of files by large organizations or bad actors
- **No unified solution** to backup and verify data across multiple cloud platforms

## Solution

A self-hosted web application that:

- **Backs up data** from multiple cloud platforms to user-chosen storage destinations
- **Verifies integrity** on a schedule to detect unauthorized changes
- **Alerts users** when changes are detected, allowing them to approve (accept the new version) or deny (keep the backup as truth, ignore cloud change)

## Target Users

- Privacy-conscious individuals
- Technical users comfortable with self-hosting

## Key Differentiator

**Lua-based plugin system** with a distributed marketplace - users install integrations by pointing to a GitHub repo or file URL. The app downloads the plugin and checks for updates automatically.

This approach allows:
- Sandboxed, safe execution of third-party code
- Dynamic loading without preinstalled binaries
- Community-driven ecosystem of integrations
- Easy contribution from developers

## Initial Scope

- Google Drive and iCloud integrations (first-party)
- Web dashboard interface
- Scheduled backups and integrity checks
- Notification system with approve/deny workflow

## Explicitly Out of Scope

- Real-time sync (scheduled snapshots only)
- File editing/viewing within the app
- Mobile native apps
- Encryption at rest
- Non-file data (contacts, calendars, emails)
- Disaster recovery automation
- Backup-to-backup transfers / cloud migration

## Success Criteria

Users can sleep at night knowing their data is safe and unchanged.
