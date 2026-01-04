#!/bin/bash

# Setup script for Tailoring SaaS project
echo "🚀 Setting up Tailoring SaaS..."
echo ""

# Check Python version
echo "Checking Python version..."
python3 --version || { echo "❌ Python 3 is required"; exit 1; }
echo "✓ Python found"
echo ""

# Create virtual environment
echo "Creating virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi
echo ""

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate || { echo "❌ Failed to activate venv"; exit 1; }
echo "✓ Virtual environment activated"
echo ""

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip > /dev/null 2>&1
echo "✓ Pip upgraded"
echo ""

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt
echo "✓ Dependencies installed"
echo ""

# Copy .env if not exists
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cp .env.example .env
    echo "✓ .env file created"
    echo "⚠️  Please update SECRET_KEY in .env for production"
else
    echo "✓ .env file already exists"
fi
echo ""

# Run migrations
echo "Running database migrations..."
python manage.py makemigrations
python manage.py migrate
echo "✓ Migrations completed"
echo ""

# Seed subscription plans
echo "Seeding subscription plans..."
python manage.py seed_plans
echo "✓ Plans seeded"
echo ""

# Create superuser prompt
echo ""
echo "📝 Would you like to create a superuser? (y/n)"
read -r answer
if [ "$answer" = "y" ]; then
    python manage.py createsuperuser
fi
echo ""

# Success message
echo "✅ Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Activate virtual environment: source venv/bin/activate"
echo "2. Run server: python manage.py runserver"
echo "3. Access admin panel: http://127.0.0.1:8000/admin/"
echo "4. API base URL: http://127.0.0.1:8000/api/"
echo ""
echo "Happy coding! 🎉"
