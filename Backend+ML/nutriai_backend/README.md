# NutriAI Backend — Django + MongoDB

## Project Structure

```
nutriai_backend/
├── manage.py
├── requirements.txt
├── nutriai/
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── accounts/              # Auth: register, login, profile
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   └── urls.py
└── reports/               # Health metrics + Report history
    ├── models.py
    ├── serializers.py
    ├── views.py
    └── urls.py
```

---

## Setup

### 1. Prerequisites
- Python 3.10+
- MongoDB running locally on port 27017

Start MongoDB:
```bash
# Windows
net start MongoDB

# macOS/Linux
sudo systemctl start mongod
```

### 2. Install dependencies
```bash
cd nutriai_backend
pip install -r requirements.txt
```

### 3. Run migrations
```bash
python manage.py makemigrations accounts reports
python manage.py migrate
```

### 4. Start the server
```bash
python manage.py runserver
```

Server runs at: `http://127.0.0.1:8000`

---

## API Reference

### Auth Endpoints — `/api/auth/`

| Method | URL | Auth | Description |
|--------|-----|------|-------------|
| POST | `/api/auth/register/` | ❌ | Register new user |
| POST | `/api/auth/login/` | ❌ | Login, get JWT tokens |
| GET/PATCH | `/api/auth/profile/` | ✅ | Get or update profile |
| POST | `/api/auth/token/refresh/` | ❌ | Refresh access token |

#### Register
```json
POST /api/auth/register/
{
  "email": "user@example.com",
  "name": "User",
  "password": "secret123"
}
```

#### Login
```json
POST /api/auth/login/
{
  "email": "user@example.com",
  "password": "secret123"
}
```
Response:
```json
{
  "user": { "id": 1, "email": "...", "name": "User", "plan": "free" },
  "tokens": { "access": "eyJ...", "refresh": "eyJ..." }
}
```

**Use the access token in all protected requests:**
```
Authorization: Bearer <access_token>
```

---

### Health Metrics — `/api/reports/metrics/`

| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/reports/metrics/` | Get dashboard metrics |
| PATCH | `/api/reports/metrics/` | Update any metric |

#### Update metrics
```json
PATCH /api/reports/metrics/
{
  "hydration_current": 2.4,
  "calories_consumed": 1850,
  "health_score": 88,
  "hemoglobin": 14.2,
  "blood_glucose": 85,
  "vitamin_d": 22,
  "heart_rate": 72,
  "blood_pressure": "120/80",
  "cholesterol": 185,
  "sleep_hours": 7.5
}
```

---

### Report History — `/api/reports/`

| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/reports/` | List all reports (paginated) |
| POST | `/api/reports/` | Upload new report |
| GET | `/api/reports/<id>/` | Get report detail |
| PATCH | `/api/reports/<id>/` | Update report |
| DELETE | `/api/reports/<id>/` | Delete report |
| GET | `/api/reports/stats/` | Report statistics |

#### Upload a report (multipart/form-data)
```
POST /api/reports/
Content-Type: multipart/form-data

title: "Blood Test - March 2026"
report_type: "blood_test"
file: <file>
notes: "Fasting blood test"
```

#### Filter & search
```
GET /api/reports/?type=blood_test
GET /api/reports/?status=processed
GET /api/reports/?search=march
GET /api/reports/?ordering=-created_at
```

#### Report types
- `blood_test` · `urine_test` · `xray` · `mri` · `ultrasound` · `other`

#### Stats response
```json
{
  "total": 12,
  "by_type": { "blood_test": 5, "xray": 3, "other": 4 },
  "by_status": { "pending": 2, "processed": 9, "failed": 1 },
  "recent": [...]
}
```

---

## Flutter Integration

In your Flutter app, set your base URL:
```dart
const String baseUrl = 'http://127.0.0.1:8000';

// Login
final res = await http.post(
  Uri.parse('$baseUrl/api/auth/login/'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'email': email, 'password': password}),
);

// Fetch metrics (with JWT)
final res = await http.get(
  Uri.parse('$baseUrl/api/reports/metrics/'),
  headers: {'Authorization': 'Bearer $accessToken'},
);

// Upload report
final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/reports/'));
request.headers['Authorization'] = 'Bearer $accessToken';
request.fields['title'] = 'Blood Test';
request.fields['report_type'] = 'blood_test';
request.files.add(await http.MultipartFile.fromPath('file', filePath));
```
