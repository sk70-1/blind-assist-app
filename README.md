# AI Accessibility Navigation Platform

This project is a full-stack starter for a voice-first accessibility assistant for visually impaired and blind users.

## Stack
- Frontend: Flutter (Dart)
- Backend: Django + Django REST Framework
- Auth: JWT (SimpleJWT)
- Database: SQLite by default, PostgreSQL/MySQL supported via environment variables

## Repository Structure
- `backend/`: Django APIs for auth, navigation, emergency, and AI memory/inference
- `frontend/`: Flutter app skeleton with voice-first screens and service layer

## Backend Setup
1. Create env file:
   - Copy `backend/.env.example` to `backend/.env`
2. Install dependencies:
   - `pip install -r backend/requirements.txt`
3. Run migrations:
   - `cd backend`
   - `python manage.py makemigrations`
   - `python manage.py migrate`
4. Run server:
   - `python manage.py runserver`

## Frontend Setup
1. Install Flutter SDK and add `flutter` to PATH.
2. From `frontend/`, run:
   - `flutter pub get`
   - `flutter run`

By default, Flutter API base URL is `http://10.0.2.2:8000` for Android emulator.

## Implemented Backend APIs
- `POST /api/auth/token/`
- `POST /api/auth/token/refresh/`
- `POST /api/accounts/register/`
- `GET|PATCH /api/accounts/profile/`
- `GET|POST /api/accounts/habits/`
- `GET|POST /api/accounts/frequent-places/`
- `GET|POST /api/navigation/saved-routes/`
- `GET|POST /api/navigation/sessions/`
- `GET|POST /api/navigation/dangerous-locations/`
- `GET|POST /api/emergency/contacts/`
- `GET|POST /api/emergency/events/`
- `POST /api/emergency/sos/`
- `GET|POST /api/ai/frames/`
- `GET|PATCH /api/ai/memory/`
- `POST /api/ai/inference/mock/`

## Notes
- Real-time camera processing, YOLOv8 inference, SLAM, beacon fusion, and production voice pipelines are scaffolded at API level and should be connected to dedicated AI microservices for deployment.
- Security hardening flags are environment-driven (HTTPS redirect, secure cookies, CORS).
