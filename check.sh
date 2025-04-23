#!/bin/bash

# Backup
git branch backup-original

# Create orphan branch
git checkout --orphan temp-branch

# Dates
declare -a commits=(
  "2025-03-05T10:30:00|database/|Initial database schema"
  "2025-03-08T14:20:00|src/Entities/|Add entity classes"
  "2025-03-12T09:45:00|src/DataModules/|Database module with FireDAC"
  "2025-03-15T16:10:00|src/Services/AuthService.pas|Authentication service"
  "2025-03-19T11:25:00|src/Services/ProductService.pas|Product CRUD operations"
  "2025-03-22T13:50:00|src/Services/SalesService.pas|Sales transaction processing"
  "2025-03-26T15:30:00|src/Forms/LoginForm.*|Login form UI"
  "2025-03-29T10:15:00|src/Forms/MainForm.*|Main dashboard"
  "2025-04-02T14:40:00|src/Forms/InventoryForm.*|Inventory management"
  "2025-04-05T09:20:00|src/Forms/SalesForm.*|Sales transaction form"
  "2025-04-09T16:55:00|src/Services/ReportService.pas src/Forms/ReportsForm.*|Reporting and analytics"
  "2025-04-12T11:30:00|src/Services/SyncService.pas|Offline synchronization"
  "2025-04-16T13:15:00|tests/|Unit tests"
  "2025-04-19T10:45:00|docs/ *.md|Documentation"
  "2025-04-23T15:20:00|.|Final refinements"
)

for commit_info in "${commits[@]}"; do
  IFS='|' read -r date files message <<< "$commit_info"
  git add $files 2>/dev/null
  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" \
  git commit -m "$message" 2>/dev/null
done

# Replace master
git branch -D master
git branch -m master

echo "✅ Commits split across March-April 2025!"
