"""
Management command to seed system-wide categories and measurement fields
Usage: python manage.py seed_masters
"""
from django.core.management.base import BaseCommand
from masters.models import ItemCategory, Unit, MeasurementField


class Command(BaseCommand):
    help = 'Seed system-wide categories, units, and measurement fields'
    
    def handle(self, *args, **kwargs):
        self.stdout.write('🌱 Seeding master data...\n')
        
        # Seed Units
        self.seed_units()
        
        # Seed Garment Categories
        self.seed_garment_categories()
        
        # Seed Fabric Categories
        self.seed_fabric_categories()
        
        # Seed Accessory Categories
        self.seed_accessory_categories()
        
        # Seed Measurement Fields for Lehenga
        self.seed_lehenga_measurements()
        
        # Seed Measurement Fields for Saree
        self.seed_saree_measurements()
        
        # Seed Measurement Fields for Blouse
        self.seed_blouse_measurements()
        
        # Seed Measurement Fields for Shirt
        self.seed_shirt_measurements()
        
        self.stdout.write(self.style.SUCCESS('\n✅ Master data seeding completed!'))
    
    def seed_units(self):
        """Seed measurement units"""
        self.stdout.write('📏 Seeding units...')
        
        units_data = [
            {'name': 'Inches', 'symbol': 'in', 'display_order': 1},
            {'name': 'Centimeters', 'symbol': 'cm', 'display_order': 2},
            {'name': 'Meters', 'symbol': 'm', 'display_order': 3},
            {'name': 'Feet', 'symbol': 'ft', 'display_order': 4},
        ]
        
        created_count = 0
        for unit_data in units_data:
            unit, created = Unit.objects.get_or_create(
                name=unit_data['name'],
                defaults=unit_data
            )
            if created:
                created_count += 1
                self.stdout.write(f'  ✓ Created unit: {unit.name}')
        
        self.stdout.write(f'  Units: {created_count} created\n')
    
    def seed_garment_categories(self):
        """Seed garment categories"""
        self.stdout.write('👗 Seeding garment categories...')
        
        garments = [
            {'name': 'Lehenga', 'display_order': 1, 'hsn': '6204'},
        {'name': 'Saree', 'display_order': 2, 'hsn': '6206'},
        {'name': 'Blouse', 'display_order': 3, 'hsn': '6206'},
        {'name': 'Shirt', 'display_order': 4, 'hsn': '6205'},
        {'name': 'Kurta', 'display_order': 5, 'hsn': '6206'},
        {'name': 'Salwar Kameez', 'display_order': 6, 'hsn': '6204'},
        {'name': 'Gown', 'display_order': 7, 'hsn': '6204'},
        {'name': 'Skirt', 'display_order': 8, 'hsn': '6204'},
        {'name': 'Dress', 'display_order': 9, 'hsn': '6204'},
        {'name': 'Pant', 'display_order': 10, 'hsn': '6203'},
        {'name': 'Sherwani', 'display_order': 11, 'hsn': '6203'},
        {'name': 'Suit', 'display_order': 12, 'hsn': '6203'},
        ]
        
        created_count = 0
        for garment_data in garments:
            category, created = ItemCategory.objects.get_or_create(
                name=garment_data['name'],
                category_type='GARMENT',
                tenant=None,
                defaults={
                    'is_system_wide': True,
                    'is_active': True,
                    'display_order': garment_data['display_order'],
                    'default_hsn_code': garment_data['hsn'],
                    'description': f'System-wide {garment_data["name"]} category'
                }
            )
            if created:
                created_count += 1
                self.stdout.write(f'  ✓ Created category: {category.name} (HSN: {garment_data["hsn"]})')
            else:
                # Update existing with HSN
                category.default_hsn_code = garment_data['hsn']
                category.save()
                self.stdout.write(f'  ✓ Updated category: {category.name} (HSN: {garment_data["hsn"]})')
        self.stdout.write(f'  Garments: {created_count} created\n')
    
    def seed_fabric_categories(self):
        """Seed fabric categories"""
        self.stdout.write('🧵 Seeding fabric categories...')
        
        fabrics = [
            {'name': 'Silk', 'display_order': 1 , 'hsn': '5007'},
            {'name': 'Cotton', 'display_order': 2, 'hsn': '5007'},
            {'name': 'Chiffon', 'display_order': 3, 'hsn': '5007'},
            {'name': 'Georgette', 'display_order': 4, 'hsn': '5007'},
            {'name': 'Velvet', 'display_order': 5, 'hsn': '5007'},
            {'name': 'Linen', 'display_order': 6, 'hsn': '5007'},
            {'name': 'Satin', 'display_order': 7, 'hsn': '5007'},
            {'name': 'Brocade', 'display_order': 8, 'hsn': '5007'},
        ]
        
        created_count = 0
        for fabric_data in fabrics:
            category, created = ItemCategory.objects.get_or_create(
                name=fabric_data['name'],
                category_type='FABRIC',
                tenant=None,
                defaults={
                    'is_system_wide': True,
                    'is_active': True,
                    'display_order': fabric_data['display_order'],
                    'default_hsn_code': fabric_data['hsn'], 
                    'description': f'System-wide {fabric_data["name"]} fabric'
                }
            )
            if created:
                created_count += 1
                self.stdout.write(f'  ✓ Created fabric: {category.name}')
                self.stdout.write(f'  ✓ Created category: {category.name} (HSN: {fabric_data["hsn"]})')
        
        self.stdout.write(f'  Fabrics: {created_count} created\n')
    
    def seed_accessory_categories(self):
        """Seed accessory categories"""
        self.stdout.write('🎀 Seeding accessory categories...')
        
        accessories = [
            {'name': 'Buttons', 'display_order': 1 ,'hsn': '6206'},
            {'name': 'Zippers', 'display_order': 2,'hsn': '6206'},
            {'name': 'Threads', 'display_order': 3,'hsn': '6206'},
            {'name': 'Laces', 'display_order': 4,'hsn': '6206'},
            {'name': 'Borders', 'display_order': 5,'hsn': '6206'},
            {'name': 'Beads', 'display_order': 6,'hsn': '6206'},
            {'name': 'Sequins', 'display_order': 7,'hsn': '6206'},
        ]
        
        created_count = 0
        for accessory_data in accessories:
            category, created = ItemCategory.objects.get_or_create(
                name=accessory_data['name'],
                category_type='ACCESSORY',
                tenant=None,
                defaults={
                    'is_system_wide': True,
                    'is_active': True,
                    'display_order': accessory_data['display_order'],
                    'default_hsn_code': accessory_data['hsn'], 
                    'description': f'System-wide {accessory_data["name"]} accessory'
                }
            )
            if created:
                created_count += 1
                self.stdout.write(f'  ✓ Created category: {category.name} (HSN: {accessory_data["hsn"]})')
            else:
            # Update existing with HSN
                category.default_hsn_code = accessory_data['hsn']
                category.save()
                self.stdout.write(f'  ✓ Updated category: {category.name} (HSN: {accessory_data["hsn"]})')
        self.stdout.write(f'  Accessories: {created_count} created\n')
    
    def seed_lehenga_measurements(self):
        """Seed measurement fields for Lehenga"""
        self.stdout.write('📐 Seeding Lehenga measurements...')
        
        # Get Lehenga category
        try:
            lehenga = ItemCategory.objects.get(name='Lehenga', category_type='GARMENT', is_system_wide=True)
        except ItemCategory.DoesNotExist:
            self.stdout.write(self.style.WARNING('  ⚠ Lehenga category not found, skipping'))
            return
        
        measurements = [
            {
                'field_name': 'bust',
                'field_label': 'Bust',
                'field_type': 'NUMBER',
                'unit_options': 'inches,cm',
                'default_unit': 'inches',
                'is_required': True,
                'display_order': 1,
                'help_text': 'Measure around the fullest part of bust'
            },
            {
                'field_name': 'waist',
                'field_label': 'Waist',
                'field_type': 'NUMBER',
                'unit_options': 'inches,cm',
                'default_unit': 'inches',
                'is_required': True,
                'display_order': 2,
                'help_text': 'Measure at natural waistline'
            },
            {
                'field_name': 'hip',
                'field_label': 'Hip',
                'field_type': 'NUMBER',
                'unit_options': 'inches,cm',
                'default_unit': 'inches',
                'is_required': True,
                'display_order': 3,
                'help_text': 'Measure around the fullest part of hips'
            },
            {
                'field_name': 'lehenga_length',
                'field_label': 'Lehenga Length',
                'field_type': 'NUMBER',
                'unit_options': 'inches,cm',
                'default_unit': 'inches',
                'is_required': True,
                'display_order': 4,
                'help_text': 'Length from waist to floor'
            },
            {
                'field_name': 'shoulder_width',
                'field_label': 'Shoulder Width',
                'field_type': 'NUMBER',
                'unit_options': 'inches,cm',
                'default_unit': 'inches',
                'is_required': False,
                'display_order': 5,
                'help_text': 'Width across shoulders'
            },
            {
                'field_name': 'blouse_length',
                'field_label': 'Blouse Length',
                'field_type': 'NUMBER',
                'unit_options': 'inches,cm',
                'default_unit': 'inches',
                'is_required': True,
                'display_order': 6,
                'help_text': 'Length of blouse from shoulder'
            },
            {
                'field_name': 'sleeve_length',
                'field_label': 'Sleeve Length',
                'field_type': 'NUMBER',
                'unit_options': 'inches,cm',
                'default_unit': 'inches',
                'is_required': False,
                'display_order': 7,
                'help_text': 'Length of sleeve'
            },
            {
                'field_name': 'back_depth',
                'field_label': 'Back Depth',
                'field_type': 'NUMBER',
                'unit_options': 'inches,cm',
                'default_unit': 'inches',
                'is_required': False,
                'display_order': 8,
                'help_text': 'Depth of back neckline'
            },
        ]
        
        created_count = 0
        for measurement_data in measurements:
            field, created = MeasurementField.objects.get_or_create(
                category=lehenga,
                field_name=measurement_data['field_name'],
                tenant=None,
                defaults={
                    **measurement_data,
                    'is_system_wide': True,
                    'is_active': True
                }
            )
            if created:
                created_count += 1
                self.stdout.write(f'  ✓ Created field: {field.field_label}')
        
        self.stdout.write(f'  Lehenga measurements: {created_count} created\n')
    
    def seed_saree_measurements(self):
        """Seed measurement fields for Saree"""
        self.stdout.write('📐 Seeding Saree measurements...')
        
        try:
            saree = ItemCategory.objects.get(name='Saree', category_type='GARMENT', is_system_wide=True)
        except ItemCategory.DoesNotExist:
            self.stdout.write(self.style.WARNING('  ⚠ Saree category not found, skipping'))
            return
        
        measurements = [
            {
                'field_name': 'bust',
                'field_label': 'Bust',
                'field_type': 'NUMBER',
                'unit_options': 'inches,cm',
                'default_unit': 'inches',
                'is_required': True,
                'display_order': 1,
                'help_text': 'Measure around the fullest part of bust'
            },
            {
                'field_name': 'waist',
                'field_label': 'Waist',
                'field_type': 'NUMBER',
                'unit_options': 'inches,cm',
                'default_unit': 'inches',
                'is_required': True,
                'display_order': 2,
                'help_text': 'Measure at natural waistline'
            },
            {
                'field_name': 'saree_length',
                'field_label': 'Saree Length',
                'field_type': 'NUMBER',
                'unit_options': 'meters,feet',
                'default_unit': 'meters',
                'is_required': True,
                'display_order': 3,
                'help_text': 'Total length of saree'
            },
            {
                'field_name': 'blouse_length',
                'field_label': 'Blouse Length',
                'field_type': 'NUMBER',
                'unit_options': 'inches,cm',
                'default_unit': 'inches',
                'is_required': True,
                'display_order': 4,
                'help_text': 'Length of blouse'
            },
        ]
        
        created_count = 0
        for measurement_data in measurements:
            field, created = MeasurementField.objects.get_or_create(
                category=saree,
                field_name=measurement_data['field_name'],
                tenant=None,
                defaults={
                    **measurement_data,
                    'is_system_wide': True,
                    'is_active': True
                }
            )
            if created:
                created_count += 1
        
        self.stdout.write(f'  Saree measurements: {created_count} created\n')
    
    def seed_blouse_measurements(self):
        """Seed measurement fields for Blouse"""
        self.stdout.write('📐 Seeding Blouse measurements...')
        
        try:
            blouse = ItemCategory.objects.get(name='Blouse', category_type='GARMENT', is_system_wide=True)
        except ItemCategory.DoesNotExist:
            self.stdout.write(self.style.WARNING('  ⚠ Blouse category not found, skipping'))
            return
        
        measurements = [
            {'field_name': 'bust', 'field_label': 'Bust', 'display_order': 1, 'is_required': True},
            {'field_name': 'waist', 'field_label': 'Waist', 'display_order': 2, 'is_required': True},
            {'field_name': 'shoulder_width', 'field_label': 'Shoulder Width', 'display_order': 3, 'is_required': False},
            {'field_name': 'blouse_length', 'field_label': 'Blouse Length', 'display_order': 4, 'is_required': True},
            {'field_name': 'sleeve_length', 'field_label': 'Sleeve Length', 'display_order': 5, 'is_required': False},
        ]
        
        created_count = 0
        for measurement_data in measurements:
            field, created = MeasurementField.objects.get_or_create(
                category=blouse,
                field_name=measurement_data['field_name'],
                tenant=None,
                defaults={
                    **measurement_data,
                    'field_type': 'NUMBER',
                    'unit_options': 'inches,cm',
                    'default_unit': 'inches',
                    'is_system_wide': True,
                    'is_active': True
                }
            )
            if created:
                created_count += 1
        
        self.stdout.write(f'  Blouse measurements: {created_count} created\n')
    
    def seed_shirt_measurements(self):
        """Seed measurement fields for Shirt"""
        self.stdout.write('📐 Seeding Shirt measurements...')
        
        try:
            shirt = ItemCategory.objects.get(name='Shirt', category_type='GARMENT', is_system_wide=True)
        except ItemCategory.DoesNotExist:
            self.stdout.write(self.style.WARNING('  ⚠ Shirt category not found, skipping'))
            return
        
        measurements = [
            {'field_name': 'chest', 'field_label': 'Chest', 'display_order': 1, 'is_required': True},
            {'field_name': 'waist', 'field_label': 'Waist', 'display_order': 2, 'is_required': True},
            {'field_name': 'shoulder_width', 'field_label': 'Shoulder Width', 'display_order': 3, 'is_required': True},
            {'field_name': 'shirt_length', 'field_label': 'Shirt Length', 'display_order': 4, 'is_required': True},
            {'field_name': 'sleeve_length', 'field_label': 'Sleeve Length', 'display_order': 5, 'is_required': True},
            {'field_name': 'neck', 'field_label': 'Neck', 'display_order': 6, 'is_required': True},
        ]
        
        created_count = 0
        for measurement_data in measurements:
            field, created = MeasurementField.objects.get_or_create(
                category=shirt,
                field_name=measurement_data['field_name'],
                tenant=None,
                defaults={
                    **measurement_data,
                    'field_type': 'NUMBER',
                    'unit_options': 'inches,cm',
                    'default_unit': 'inches',
                    'is_system_wide': True,
                    'is_active': True
                }
            )
            if created:
                created_count += 1
        
        self.stdout.write(f'  Shirt measurements: {created_count} created\n')