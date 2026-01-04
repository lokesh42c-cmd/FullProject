# Tailoring SaaS - Multi-Tenant Order Management System

A comprehensive SaaS platform for tailoring shops with complete order management, inventory tracking, customer management, and subscription-based access control.

## 🎯 Features

### Phase 1 - Foundation (Completed)
- ✅ Multi-tenant architecture with complete data isolation
- ✅ Subscription system (FREE, STARTER, PROFESSIONAL, ENTERPRISE)
- ✅ Role-based access control (OWNER, MANAGER, STAFF, TAILOR)
- ✅ JWT authentication with refresh tokens
- ✅ Auto-subscription on tenant registration (14-day free trial)
- ✅ Resource limits per subscription plan
- ✅ Feature flags for controlled access

### Coming Soon
- 📦 Master data management (Categories, Measurements)
- 👥 Customer management
- 📦 Inventory management
- 📋 Order management with measurements
- 💰 Payment tracking
- 📄 GST-compliant invoicing
- 💸 Expense management
- 📊 Dashboard and reports

## 🚀 Quick Start

### Prerequisites
- Python 3.10 or higher
- pip (Python package manager)
- Git

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd tailoring_saas
```

2. **Create virtual environment**
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Mac/Linux
python3 -m venv venv
source venv/bin/activate
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Set up environment variables**
```bash
# Copy the example file
cp .env.example .env

# Edit .env and set your SECRET_KEY
# For development, the defaults are fine
```

5. **Run migrations**
```bash
python manage.py makemigrations
python manage.py migrate
```

6. **Seed subscription plans**
```bash
python manage.py seed_plans
```

7. **Create superuser (for Django admin)**
```bash
python manage.py createsuperuser
# Email: admin@example.com
# Name: Admin User
# Password: (your secure password)
```

8. **Run development server**
```bash
python manage.py runserver
```

The API will be available at: `http://127.0.0.1:8000/`

Django Admin Panel: `http://127.0.0.1:8000/admin/`

## 📚 API Documentation

### Base URL
```
Development: http://127.0.0.1:8000/api/
Production: https://your-domain.com/api/
```

### Authentication Endpoints

#### 1. Register Shop
```http
POST /api/auth/register/
Content-Type: application/json

{
  "shop_name": "Ram Tailors",
  "shop_email": "shop@ramtailors.com",
  "shop_phone": "9876543210",
  "city": "Bangalore",
  "state": "Karnataka",
  "owner_name": "Rajesh Kumar",
  "owner_email": "rajesh@ramtailors.com",
  "owner_phone": "9876543211",
  "password": "SecurePass123!",
  "password_confirm": "SecurePass123!"
}
```

**Response (201 Created):**
```json
{
  "message": "Shop registered successfully",
  "tenant": {
    "id": 1,
    "name": "Ram Tailors",
    "slug": "ram-tailors",
    "email": "shop@ramtailors.com",
    ...
  },
  "user": {
    "id": 1,
    "name": "Rajesh Kumar",
    "email": "rajesh@ramtailors.com",
    "role": "OWNER",
    ...
  },
  "subscription": {
    "plan": {
      "name": "Free Trial",
      "plan_type": "FREE",
      ...
    },
    "status": "TRIAL",
    "trial_ends_at": "2025-11-05T10:30:00Z",
    ...
  },
  "tokens": {
    "refresh": "eyJ0eXAiOiJKV1QiLC...",
    "access": "eyJ0eXAiOiJKV1QiLC..."
  }
}
```

#### 2. Login
```http
POST /api/auth/login/
Content-Type: application/json

{
  "email": "rajesh@ramtailors.com",
  "password": "SecurePass123!"
}
```

**Response (200 OK):**
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "name": "Rajesh Kumar",
    "email": "rajesh@ramtailors.com",
    "role": "OWNER",
    "tenant": {
      "id": 1,
      "name": "Ram Tailors",
      ...
    }
  },
  "subscription": {
    "plan": {...},
    "status": "TRIAL",
    ...
  },
  "tokens": {
    "refresh": "eyJ0eXAiOiJKV1QiLC...",
    "access": "eyJ0eXAiOiJKV1QiLC..."
  }
}
```

#### 3. Get Current User
```http
GET /api/auth/me/
Authorization: Bearer <access_token>
```

#### 4. Refresh Token
```http
POST /api/auth/token/refresh/
Content-Type: application/json

{
  "refresh": "eyJ0eXAiOiJKV1QiLC..."
}
```

#### 5. Logout
```http
POST /api/auth/logout/
Authorization: Bearer <access_token>
```

#### 6. Get Subscription Info
```http
GET /api/auth/subscription/
Authorization: Bearer <access_token>
```

#### 7. Get All Plans
```http
GET /api/auth/plans/
```

## 🗄️ Database Models

### Core Models

#### Tenant (Shop)
- Multi-tenant isolation
- Shop details (name, email, phone, address)
- Business details (GSTIN, PAN, bank info)
- Logo upload support

#### User
- Custom user model with email as username
- Linked to tenant
- Role-based (OWNER, MANAGER, STAFF, TAILOR)
- JWT authentication

#### SubscriptionPlan
- 4 tiers: FREE, STARTER, PROFESSIONAL, ENTERPRISE
- Resource limits (orders, customers, staff, inventory)
- Feature flags (7 features)
- Pricing (monthly/yearly)

#### TenantSubscription
- Links tenant to plan
- Tracks usage (orders, customers, staff, inventory)
- Status tracking (TRIAL, ACTIVE, EXPIRED, etc.)
- Automatic FREE trial on registration

## 🔐 Permission System

### Decorators

```python
from core.permissions import require_subscription, require_role, check_feature_access, check_resource_limit

# Check active subscription
@require_subscription
def my_view(request):
    pass

# Check user role
@require_role('OWNER', 'MANAGER')
def manage_staff(request):
    pass

# Check feature access
@check_feature_access('has_inventory')
def inventory_view(request):
    pass

# Check resource limits
@check_resource_limit('order')
def create_order(request):
    pass
```

## 🧪 Testing

### Manual Testing with Thunder Client / Postman

1. **Register a shop**
2. **Login and save access token**
3. **Use token in Authorization header**: `Bearer <access_token>`
4. **Test protected endpoints**

## 🌐 Deployment

### Switching to PostgreSQL (Production)

1. Install PostgreSQL
2. Create database
3. Update `.env`:
```env
DATABASE_URL=postgresql://user:password@localhost:5432/tailoring_db
```

4. Update `config/settings.py`:
```python
import dj_database_url

DATABASES = {
    'default': dj_database_url.config(
        default='sqlite:///db.sqlite3',
        conn_max_age=600
    )
}
```

5. Run migrations:
```bash
python manage.py migrate
python manage.py seed_plans
python manage.py createsuperuser
```

## 📁 Project Structure

```
tailoring_saas/
├── config/                   # Django settings
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── core/                     # Core app (authentication, subscriptions)
│   ├── models.py            # Tenant, User, Subscription models
│   ├── views.py             # Authentication APIs
│   ├── serializers.py       # DRF serializers
│   ├── permissions.py       # Permission decorators
│   ├── signals.py           # Auto-subscription signal
│   ├── admin.py             # Django admin
│   └── management/
│       └── commands/
│           └── seed_plans.py
├── manage.py
├── requirements.txt
├── .env
├── .gitignore
└── README.md
```

## 🔧 Development Commands

```bash
# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Run server
python manage.py runserver

# Create superuser
python manage.py createsuperuser

# Seed subscription plans
python manage.py seed_plans

# Django shell
python manage.py shell
```

## 📝 Git Workflow

```bash
# Initialize git (first time only)
git init
git add .
git commit -m "Initial commit: Django foundation"

# Daily workflow
git add .
git commit -m "Completed feature X"
git push origin main
```

## 🎯 Next Steps

1. ✅ Foundation completed
2. 📦 Build Masters app (Categories, Measurements)
3. 👥 Build Customers app
4. 📦 Build Inventory app
5. 📋 Build Orders app
6. 💰 Build Payments app
7. 📄 Build Invoices app
8. 💸 Build Expenses app
9. 📊 Build Reports/Dashboard
10. 📱 Build Flutter app

## 📞 Support

For issues or questions, please open an issue on GitHub.

## 📄 License

This project is proprietary and confidential.

---

**Built with ❤️ for tailoring businesses**
