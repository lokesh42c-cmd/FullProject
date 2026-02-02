"""
Complete Database Cleanup Script - SQLite Compatible
Cleans up invoicing and financials tables
Run: python cleanup_invoices.py
"""

import os
import django
import sqlite3

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db import connection
from django.db.migrations.recorder import MigrationRecorder

print("🗑️  COMPLETE DATABASE CLEANUP (SQLite)")
print("=" * 60)
print("\nThis will:")
print("  1. Delete migration records for invoicing & financials")
print("  2. Drop all invoicing tables")
print("  3. Drop all financials tables")
print("  4. Reset migration history")
print("\n⚠️  WARNING: This will delete ALL data in these tables!")
print("=" * 60)

confirm = input("\nType 'yes' to confirm: ")
if confirm.lower() != 'yes':
    print("❌ Cleanup cancelled")
    exit()

print("\n🔄 Starting cleanup...\n")

try:
    # For SQLite, we need to disable foreign key checks first
    with connection.cursor() as cursor:
        # Disable foreign key checks (SQLite specific)
        cursor.execute("PRAGMA foreign_keys = OFF;")
        
        # List of tables to delete (order matters for SQLite)
        tables = [
            # Delete child tables first (those with foreign keys)
            'financials_payment',
            'financials_refundvoucher',
            'invoicing_invoiceitem',
            
            # Then parent tables
            'financials_receiptvoucher',
            'invoicing_invoice',
            
            # Other tables
            'financials_expense',
            'financials_vendor',
        ]
        
        # Delete tables
        for table in tables:
            try:
                cursor.execute(f"DROP TABLE IF EXISTS {table};")
                print(f"✅ Dropped table: {table}")
            except sqlite3.OperationalError as e:
                print(f"⚠️  Skipped {table}: {e}")
        
        # Re-enable foreign key checks
        cursor.execute("PRAGMA foreign_keys = ON;")
    
    print("\n✅ All tables dropped successfully!")
    
    # Delete migration records from django_migrations table
    print("\n🔄 Cleaning migration records...")
    
    try:
        deleted_invoicing = MigrationRecorder.Migration.objects.filter(app='invoicing').delete()
        print(f"✅ Deleted {deleted_invoicing[0]} invoicing migration records")
    except Exception as e:
        print(f"⚠️  No invoicing migrations to delete: {e}")
    
    try:
        deleted_financials = MigrationRecorder.Migration.objects.filter(app='financials').delete()
        print(f"✅ Deleted {deleted_financials[0]} financials migration records")
    except Exception as e:
        print(f"⚠️  No financials migrations to delete: {e}")
    
    print("\n" + "=" * 60)
    print("🎉 Database cleanup complete!")
    print("=" * 60)
    
    print("\n📝 Next steps:")
    print("  1. Delete migration files:")
    print("     Remove-Item 'invoicing\\migrations\\0*.py'")
    print("     Remove-Item 'financials\\migrations\\0*.py'")
    print()
    print("  2. Update your models.py files with discount field")
    print()
    print("  3. Create fresh migrations:")
    print("     python manage.py makemigrations invoicing")
    print("     python manage.py makemigrations financials")
    print()
    print("  4. Apply migrations:")
    print("     python manage.py migrate invoicing")
    print("     python manage.py migrate financials")
    print()
    print("  5. Restart your server:")
    print("     python manage.py runserver")
    print()

except Exception as e:
    print(f"\n❌ Error during cleanup: {e}")
    print("\nFull error details:")
    import traceback
    traceback.print_exc()