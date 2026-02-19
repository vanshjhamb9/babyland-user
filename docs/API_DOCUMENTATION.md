# Baby Land - API Documentation

## Table of Contents
1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Authentication](#authentication)
4. [Base URL](#base-url)
5. [API Endpoints](#api-endpoints)
   - [Authentication](#authentication-endpoints)
   - [User Management](#user-management)
   - [Menstrual Tracking](#menstrual-tracking)
   - [Pregnancy Tracking](#pregnancy-tracking)
   - [Postpartum Tracking](#postpartum-tracking)
   - [Baby Growth Tracking](#baby-growth-tracking)
   - [Doctors & Consultations](#doctors--consultations)
   - [Bookings & Payments](#bookings--payments)
   - [Reviews](#reviews)
   - [AI Chat & Insights](#ai-chat--insights)
   - [Community](#community)
   - [Plans & Subscriptions](#plans--subscriptions)
   - [Medical Records](#medical-records)
   - [Prescriptions](#prescriptions)
   - [Sessions](#sessions)
   - [Agora Video/Audio](#agora-videoaudio)
   - [Admin Management](#admin-management)
   - [Roles & Permissions](#roles--permissions)
   - [Features](#features)
   - [Specializations](#specializations)
   - [Notifications](#notifications)
   - [Policies](#policies)
   - [File Upload](#file-upload)
6. [Response Format](#response-format)
7. [Error Handling](#error-handling)
8. [Status Codes](#status-codes)

---

## Overview

Baby Land is a comprehensive healthcare platform designed for women's health management. It provides features for tracking menstrual cycles, pregnancy, postpartum recovery, and baby growth. The platform includes consultation services with doctors, AI-powered insights, community support, and subscription-based premium features.

### Key Features
- 🩺 Menstrual cycle tracking with AI predictions
- 🤰 Pregnancy tracking with weekly insights
- 👶 Postpartum recovery monitoring
- 👨‍👧 Baby growth tracking
- 🏥 Doctor consultations with video/chat sessions
- 💬 AI-powered chat and insights
- 👥 Community forum for peer support
- 💳 Payment integration (Razorpay)
- 📚 Medical records management
- 📋 Prescription management
- 🎯 Role-based access control

---

## Getting Started

### Prerequisites
- Node.js >= 14
- MongoDB database
- Cloudinary account (for image storage)
- Firebase account (for authentication)
- Razorpay account (for payments)
- Agora account (for video/audio calls)

### Installation

```bash
# Install dependencies
npm install

# Create .env file with required variables
cp .env.example .env

# Start development server
npm run dev

# Start production server
npm start
```

### Environment Variables
```
PORT=5000
SERVER_URL=https://api-babyland.duckdns.org/
MONGODB_URI=your_mongodb_uri
JWT_SECRET=your_jwt_secret
FIREBASE_API_KEY=your_firebase_api_key
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_KEY_SECRET=your_razorpay_secret
CLOUDINARY_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_key
CLOUDINARY_API_SECRET=your_cloudinary_secret
AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERTIFICATE=your_agora_certificate
```

---

## Authentication

The API uses **JWT (JSON Web Token)** for authentication. 

### Getting a Token

1. Register a new user via the `/api/auths/request-verification` endpoint
2. Verify the code via `/api/auths/verify-code`
3. Complete login via `/api/auths/login` to receive JWT token
4. Include the token in the `Authorization` header for all protected endpoints

### Using the Token

```bash
curl -H "Authorization: Bearer <your_jwt_token>" \
     https://api.babyland.com/api/users/profile
```

### Token Expiration
Tokens are valid for **7 days** from creation. After expiration, users must re-authenticate.

---

## Base URL

```
Development:  https://api-babyland.duckdns.org/
Production:   https://api.babyland.com  (replace with actual domain)
```

All endpoints are prefixed with `/api/`

---

## API Endpoints

### Authentication Endpoints

#### 1. Request Verification Code
**POST** `/api/auths/request-verification`

Request a verification code for user registration.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "deviceToken": "firebase_device_token"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Verification code generated successfully",
  "data": {
    "_id": "652c6f5b8f1b9e1234567890",
    "email": "john@example.com",
    "verificationCode": "123456"
  }
}
```

---

#### 2. Verify Code
**POST** `/api/auths/verify-code`

Verify the code sent to user's email.

**Request Body:**
```json
{
  "email": "john@example.com",
  "verificationCode": "123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Code verified successfully"
}
```

---

#### 3. Complete Registration
**POST** `/api/auths/complete-signup`

Complete user registration after code verification.

**Request Body:**
```json
{
  "email": "john@example.com",
  "verificationCode": "123456",
  "password": "securePassword123",
  "role": "User"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "_id": "652c6f5b8f1b9e1234567890",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "User"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

#### 4. User Login
**POST** `/api/auths/login`

Authenticate user with email and password.

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securePassword123",
  "deviceToken": "firebase_device_token"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "User logged in successfully",
  "data": {
    "user": {
      "_id": "652c6f5b8f1b9e1234567890",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "User"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

#### 5. Refresh Token
**POST** `/api/auths/refresh-token`

Get a new access token using refresh token.

**Request Body:**
```json
{
  "refreshToken": "refresh_token_here"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### User Management

#### 1. Get User Profile
**GET** `/api/users/profile`

Retrieve authenticated user's profile.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "652c6f5b8f1b9e1234567890",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "User",
    "isVerified": true,
    "lastPeriodStartDate": "2025-09-28",
    "cycleType": "regular",
    "cycleLengthDays": 28,
    "conditions": {
      "PCOS": false,
      "PMS": true
    }
  }
}
```

---

#### 2. Update User Profile
**PUT** `/api/users/profile`

Update user profile information.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "name": "Jane Doe",
  "lastPeriodStartDate": "2025-09-28",
  "cycleType": "regular",
  "cycleLengthDays": 28,
  "averagePeriodLengthDays": 5,
  "conditions": {
    "PCOS": false,
    "PMS": true
  },
  "medicalHistory": "No major medical history"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": { /* updated user object */ }
}
```

---

#### 3. Complete Onboarding
**PUT** `/api/users/onboarding/complete`

Complete user onboarding process with menstrual cycle details.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "lastPeriodStartDate": "2025-09-28",
  "cycleType": "regular",
  "cycleLengthDays": 28,
  "averagePeriodLengthDays": 5,
  "conditions": {
    "PCOS": true,
    "PMS": false,
    "Endometriosis": false,
    "ThyroidIssues": true,
    "Diabetes": false,
    "Hypertension": false
  },
  "medicalHistory": "No major medical history."
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Onboarding completed successfully",
  "data": { /* user object with onboarding data */ }
}
```

---

#### 4. Change Password
**PUT** `/api/users/change-password`

Change user's account password.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "oldPassword": "currentPassword123",
  "newPassword": "newPassword456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

### Menstrual Tracking

#### 1. Add Menstrual Cycle
**POST** `/api/menstruals/add-cycle`

Record the start and end dates of a menstrual cycle.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "startDate": "2025-10-01",
  "endDate": "2025-10-05",
  "notes": "Heavy flow"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Cycle added successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6789",
    "startDate": "2025-10-01",
    "endDate": "2025-10-05",
    "notes": "Heavy flow"
  }
}
```

---

#### 2. Get Cycle by ID
**GET** `/api/menstruals/cycle/{cycleId}`

Retrieve details of a specific menstrual cycle.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Parameters:**
- `cycleId` (path): MongoDB ID of the cycle

**Response (200):**
```json
{
  "success": true,
  "data": { /* cycle object */ }
}
```

---

#### 3. Update Cycle
**PUT** `/api/menstruals/cycle/{cycleId}`

Update cycle information.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "startDate": "2025-10-01",
  "endDate": "2025-10-06",
  "notes": "Very heavy flow"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Cycle updated successfully",
  "data": { /* updated cycle object */ }
}
```

---

#### 4. Delete Cycle
**DELETE** `/api/menstruals/cycle/{cycleId}`

Delete a menstrual cycle record.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Cycle deleted successfully"
}
```

---

#### 5. Add Daily Log
**POST** `/api/menstruals/logs`

Log daily menstrual symptoms and mood.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "date": "2025-10-09",
  "mood": "Good",
  "stressLevel": 2,
  "anxietyLevel": 1,
  "symptoms": ["cramps", "fatigue"],
  "notes": "Felt slightly tired today"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Daily log added successfully",
  "data": { /* log object */ }
}
```

---

#### 6. Get All Daily Logs
**GET** `/api/menstruals/logs`

Retrieve all daily logs for the authenticated user.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6789",
      "date": "2025-10-09",
      "mood": "Good",
      "symptoms": ["cramps"]
    }
  ]
}
```

---

#### 7. Get Predicted Cycles
**GET** `/api/menstruals/predicted-cycles`

Get AI-predicted menstrual cycles for the user.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "startDate": "2025-11-01",
      "endDate": "2025-11-05",
      "ovulationDay": "2025-11-14",
      "fertilityWindow": ["2025-11-12", "2025-11-16"]
    }
  ]
}
```

---

### Pregnancy Tracking

#### 1. Start Pregnancy Tracking
**POST** `/api/pregnancys/start`

Begin pregnancy tracking with estimated due date.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "pregnancyStartDate": "2025-10-01",
  "expectedDueDate": "2026-06-30"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Pregnancy tracking started",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6789",
    "userId": "652c6f5b8f1b9e1234567890",
    "currentWeek": 5,
    "trimester": 1,
    "expectedDueDate": "2026-06-30"
  }
}
```

---

#### 2. Add Pregnancy Daily Log
**POST** `/api/pregnancys/logs`

Record daily pregnancy symptoms and well-being.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "date": "2025-10-09",
  "mood": "Good",
  "symptoms": ["nausea", "fatigue"],
  "stressLevel": 2,
  "anxietyLevel": 1,
  "sleepQuality": 4,
  "notes": "Felt slightly tired today"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Daily log added successfully",
  "data": { /* log object */ }
}
```

---

#### 3. Add Appointment
**POST** `/api/pregnancys/appointments`

Schedule a pregnancy appointment (OB-GYN checkup, etc.).

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "title": "OB-GYN Checkup",
  "date": "2025-10-15",
  "time": "10:30 AM",
  "reminder": true,
  "notes": "Bring previous test reports"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Appointment added successfully",
  "data": { /* appointment object */ }
}
```

---

#### 4. Get Pregnancy Status
**GET** `/api/pregnancys/status`

Get current pregnancy tracking status and insights.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6789",
    "currentWeek": 16,
    "trimester": 2,
    "expectedDueDate": "2026-06-30",
    "fetalGrowthStage": "Palm-sized fetus",
    "predictions": {
      "dueDate": "2026-06-30",
      "trimesterProgress": 33.33
    }
  }
}
```

---

### Postpartum Tracking

#### 1. Start Postpartum Tracking
**POST** `/api/postpartums/start`

Begin postpartum recovery tracking after delivery.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "deliveryDate": "2025-10-15",
  "deliveryType": "Normal",
  "babyDetails": {
    "name": "Baby Girl",
    "date": "2025-10-15",
    "gender": "Female",
    "weight": 3.2,
    "height": 50
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Postpartum tracking started",
  "data": { /* postpartum tracker object */ }
}
```

---

#### 2. Add Daily Log
**POST** `/api/postpartums/logs`

Log daily postpartum recovery status.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "date": "2025-10-20",
  "mood": "Good",
  "symptoms": ["discharge"],
  "stressLevel": 2,
  "anxietyLevel": 1,
  "sleepQuality": 3,
  "notes": "Feeling better today"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Daily log added successfully",
  "data": { /* log object */ }
}
```

---

#### 3. Log Feeding
**POST** `/api/postpartums/feedings`

Record baby feeding information.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "time": "2025-10-20T08:30:00Z",
  "type": "Breastfeeding",
  "side": "Left",
  "durationMinutes": 15,
  "quantity": "100ml",
  "notes": "Baby fed well"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Feeding recorded successfully",
  "data": { /* feeding object */ }
}
```

---

#### 4. Get Postpartum Status
**GET** `/api/postpartums/status`

Get postpartum recovery status and AI predictions.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6789",
    "deliveryDate": "2025-10-15",
    "daysPostPartum": 5,
    "predictions": {
      "recoveryScore": 75,
      "depressionRisk": "Low",
      "fatigueLevel": "Moderate"
    }
  }
}
```

---

### Baby Growth Tracking

#### 1. Add Growth Measurements
**POST** `/api/babygrowths/add-growth`

Record baby's height, weight, and head circumference.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "date": "2025-10-20",
  "height": 52.5,
  "weight": 4.2,
  "headCircumference": 37.5
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Growth record added successfully",
  "data": { /* growth record object */ }
}
```

---

#### 2. Add Milestone
**POST** `/api/babygrowths/milestones`

Record baby's developmental milestones.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "date": "2025-10-20",
  "title": "First Smile",
  "photo": "url_to_milestone_photo",
  "note": "Baby smiled at me today!"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Milestone added successfully",
  "data": { /* milestone object */ }
}
```

---

#### 3. Add Photo Journal
**POST** `/api/babygrowths/photo-journal`

Add a photo to the baby's photo journal.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data
```

**Request Body:**
```
date: 2025-10-20
caption: Baby at 2 months
photo: <file>
```

**Response (201):**
```json
{
  "success": true,
  "message": "Photo added successfully",
  "data": { /* photo journal object */ }
}
```

---

#### 4. Get Growth Chart
**GET** `/api/babygrowths/chart`

Get baby's growth chart and percentile information.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "measurements": [
      {
        "date": "2025-10-20",
        "height": 52.5,
        "weight": 4.2,
        "percentile": 50
      }
    ]
  }
}
```

---

#### 5. Add Vaccination
**POST** `/api/babygrowths/vaccinations`

Record baby's vaccinations.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "vaccine": "BCG",
  "dueDate": "2025-10-15",
  "status": "completed",
  "dateCompleted": "2025-10-15"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Vaccination recorded successfully",
  "data": { /* vaccination object */ }
}
```

---

### Doctors & Consultations

#### 1. Get All Doctors
**GET** `/api/doctors/all`

Retrieve list of all available doctors.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `specialization` (optional): Filter by specialization ID
- `search` (optional): Search by doctor name

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "652c6f5b8f1b9e1234567890",
      "name": "Dr. Ravi Kumar",
      "email": "ravi@example.com",
      "doctorDetails": {
        "speciality": ["Gynecology"],
        "profileBio": "Experienced gynecologist",
        "consultationFee": 500,
        "totalAvgRating": 4.6
      }
    }
  ]
}
```

---

#### 2. Get Doctor Profile
**GET** `/api/doctors/{doctorId}`

Get detailed profile of a specific doctor.

**Parameters:**
- `doctorId` (path): Doctor's MongoDB ID

**Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "652c6f5b8f1b9e1234567890",
    "name": "Dr. Ravi Kumar",
    "doctorDetails": {
      "speciality": ["Gynecology"],
      "profileBio": "Experienced cardiologist with 10+ years",
      "consultationFee": 500,
      "languages": ["English", "Hindi"],
      "weeklySlots": [
        {
          "day": "Monday",
          "startTime": "09:00 AM",
          "endTime": "05:00 PM"
        }
      ]
    },
    "location": {
      "latitude": 24.5854,
      "longitude": 73.9129
    }
  }
}
```

---

#### 3. Doctor Registration
**POST** `/api/doctors/register`

Register a new doctor account.

**Request Body:**
```json
{
  "name": "Dr. Ravi Kumar",
  "email": "ravi.kumar@example.com",
  "password": "securePassword123",
  "roleId": "66fabcd1234567890abc9999"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Doctor registered successfully",
  "data": { /* doctor object */ }
}
```

---

#### 4. Update Doctor Profile
**PUT** `/api/doctors/profile`

Update doctor's profile and consultation details.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "doctorDetails": {
    "firstName": "Ravi",
    "lastName": "Kumar",
    "speciality": ["66fabcd1234567890abc1234"],
    "profileBio": "Updated bio",
    "consultationFee": 600,
    "languages": ["English", "Hindi"],
    "weeklySlots": [
      {
        "day": "Monday",
        "startTime": "09:00 AM",
        "endTime": "05:00 PM"
      }
    ]
  }
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": { /* updated doctor object */ }
}
```

---

### Bookings & Payments

#### 1. Create Booking
**POST** `/api/bookings/add`

Create a doctor consultation booking.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "doctorId": "64f7c1a2b1234567890abcd",
  "date": "2025-10-12",
  "time": "09:30 AM",
  "consultationFee": 500,
  "currency": "INR",
  "paymentMethod": "Razorpay"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6789",
    "doctorId": "64f7c1a2b1234567890abcd",
    "userId": "652c6f5b8f1b9e1234567890",
    "date": "2025-10-12",
    "time": "09:30 AM",
    "status": "pending",
    "paymentStatus": "pending"
  }
}
```

---

#### 2. Get Upcoming Bookings
**GET** `/api/bookings/upcoming`

Get upcoming bookings for the authenticated user.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "bookings": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6789",
      "doctorName": "Dr. Ravi Kumar",
      "date": "2025-10-12",
      "time": "09:30 AM",
      "status": "confirmed"
    }
  ]
}
```

---

#### 3. Get Booking History
**GET** `/api/bookings/history`

Get past bookings for the authenticated user.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Items per page

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6789",
      "doctorName": "Dr. Ravi Kumar",
      "date": "2025-09-12",
      "status": "completed"
    }
  ]
}
```

---

#### 4. Cancel Booking
**PUT** `/api/bookings/cancel/{bookingId}`

Cancel a booking.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Booking canceled successfully"
}
```

---

#### 5. Verify Payment
**POST** `/api/bookings/verify-payment`

Verify Razorpay payment after checkout.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "razorpayOrderId": "order_NH8hX2a9n1J3yz",
  "razorpayPaymentId": "pay_NH8hX2a9n1J3yz",
  "razorpaySignature": "signature_hash"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Payment verified successfully",
  "data": { /* booking object */ }
}
```

---

### Reviews

#### 1. Add Doctor Review
**POST** `/api/reviews/add/{doctorId}`

Submit a review for a doctor.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Parameters:**
- `doctorId` (path): Doctor's MongoDB ID

**Request Body:**
```json
{
  "rating": 4.5,
  "comment": "Great doctor, very professional and caring"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Review added successfully",
  "data": { /* review object */ }
}
```

---

#### 2. Get Doctor Reviews
**GET** `/api/reviews/get-reviwes/{doctorId}`

Get all reviews for a specific doctor.

**Parameters:**
- `doctorId` (path): Doctor's MongoDB ID

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Items per page

**Response (200):**
```json
{
  "success": true,
  "reviews": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6789",
      "userId": "652c6f5b8f1b9e1234567890",
      "rating": 4.5,
      "comment": "Great doctor",
      "createdAt": "2025-10-01T10:30:00Z"
    }
  ]
}
```

---

#### 3. Update Review
**PUT** `/api/reviews/update`

Update your own review.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "reviewId": "625a4c8e7f1b2c3d4e5f6789",
  "rating": 5,
  "comment": "Excellent service!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Review updated successfully",
  "data": { /* updated review object */ }
}
```

---

### AI Chat & Insights

#### 1. Create Chat Conversation
**POST** `/api/aichats/create-chat`

Start a new AI chat conversation.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6789",
    "userId": "652c6f5b8f1b9e1234567890"
  }
}
```

---

#### 2. Send Message to AI
**POST** `/api/aichats/send-message`

Send a message to the AI and receive a response.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "conversationId": "625a4c8e7f1b2c3d4e5f6789",
  "chatInput": "What are safe exercises during pregnancy?"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "conversationId": "625a4c8e7f1b2c3d4e5f6789",
    "userMessage": "What are safe exercises during pregnancy?",
    "aiResponse": "Safe exercises during pregnancy include walking, swimming, prenatal yoga..."
  }
}
```

---

#### 3. Get All User Chats
**GET** `/api/aichats/my-chats`

Retrieve all chat conversations for the user.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Items per page

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6789",
      "userId": "652c6f5b8f1b9e1234567890",
      "lastMessage": "What are safe exercises...",
      "createdAt": "2025-10-01T10:30:00Z"
    }
  ]
}
```

---

#### 4. Get Full Chat History
**GET** `/api/aichats/chat/{chatId}`

Get a complete chat conversation with all messages.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Parameters:**
- `chatId` (path): Chat conversation ID

**Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6789",
    "messages": [
      {
        "_id": "msg_1",
        "sender": "user",
        "message": "What are safe exercises?",
        "timestamp": "2025-10-01T10:30:00Z"
      },
      {
        "_id": "msg_2",
        "sender": "ai",
        "message": "Safe exercises include...",
        "timestamp": "2025-10-01T10:31:00Z"
      }
    ]
  }
}
```

---

#### 5. Get AI Insights
**GET** `/api/ai/insights`

Get AI-powered insights for pregnancy or health.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `category` (required): nutrition | exercise | precautions | wellness
- `week` (optional): Week number (for pregnancy)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "source": "database",
    "data": {
      "_id": "625a4c8e7f1b2c3d4e5f6789",
      "week": 16,
      "category": "nutrition",
      "items": [
        {
          "title": "Iron Intake",
          "emoji": "🥩",
          "description": "Increase iron-rich foods..."
        }
      ],
      "quick_tip": {
        "emoji": "💡",
        "text": "Eat a balanced diet..."
      }
    }
  }
}
```

---

### Community

#### 1. Add Community Post
**POST** `/api/communities/add`

Create a new community post.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "message": "Felt my baby kick for the first time! #movement #trimester2"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Community post created successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6789",
    "userId": "652c6f5b8f1b9e1234567890",
    "message": "Felt my baby kick...",
    "hashtags": ["movement", "trimester2"],
    "likes": 0,
    "comments": 0
  }
}
```

---

#### 2. Get All Community Posts
**GET** `/api/communities/all`

Get all community posts with pagination and filtering.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `search` (optional): Search keyword
- `hashtag` (optional): Filter by hashtag

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6789",
      "userId": {
        "name": "Jane Doe",
        "profilePic": "url"
      },
      "message": "Felt my baby kick...",
      "hashtags": ["movement"],
      "likes": 45,
      "comments": 12,
      "createdAt": "2025-10-01T10:30:00Z"
    }
  ],
  "totalPosts": 156
}
```

---

#### 3. Add Comment to Post
**POST** `/api/communities/comment/{postId}`

Add a comment to a community post.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Parameters:**
- `postId` (path): Post ID

**Request Body:**
```json
{
  "comment": "This is a great post! Congratulations!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Comment added successfully",
  "data": { /* comment object */ }
}
```

---

#### 4. Like/Unlike Post
**POST** `/api/communities/like/{postId}`

Like or unlike a community post.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Parameters:**
- `postId` (path): Post ID

**Response (200):**
```json
{
  "success": true,
  "message": "Post liked successfully",
  "likeCount": 46
}
```

---

### Plans & Subscriptions

#### 1. Get All Plans
**GET** `/api/plans`

Retrieve all available subscription plans.

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "6719dd4b9371e7a5501fabb3",
      "name": "Premium Plan",
      "price": 499,
      "duration": 30,
      "features": ["AI Chat", "Unlimited Insights", "Priority Support"]
    }
  ]
}
```

---

#### 2. Create Plan (Admin)
**POST** `/api/plans/add`

Create a new subscription plan (admin only).

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "name": "Premium Plan",
  "price": 499,
  "features": ["Unlimited chats", "Priority support"],
  "duration": 30
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Plan created successfully",
  "data": { /* plan object */ }
}
```

---

#### 3. Update Plan (Admin)
**PUT** `/api/plans/update/{planId}`

Update a subscription plan.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Parameters:**
- `planId` (path): Plan ID

**Request Body:**
```json
{
  "name": "Updated Premium Plan",
  "price": 599,
  "features": ["AI Chat", "24/7 Support"],
  "duration": 45
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Plan updated successfully",
  "data": { /* updated plan object */ }
}
```

---

#### 4. Subscribe to Plan
**POST** `/api/subscriptions/add`

Subscribe to a plan using Razorpay or COD.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "planId": "6719dd4b9371e7a5501fabb3",
  "paymentMethod": "Razorpay"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Subscription created successfully",
  "data": {
    "_id": "672ff0b3c2e4126c90f27b9a",
    "userId": "671aad0cfaa1bb937ce0a94a",
    "planId": "6719dd4b9371e7a5501fabb3",
    "active": true,
    "razorpayOrderId": "order_NH8hX2a9n1J3yz"
  }
}
```

---

#### 5. Get User Subscriptions
**GET** `/api/subscriptions`

Get all subscriptions (admin) or user's subscriptions.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "672ff0b3c2e4126c90f27b9a",
      "userId": "671aad0cfaa1bb937ce0a94a",
      "planName": "Premium Plan",
      "amount": 499,
      "active": true,
      "createdAt": "2025-02-16T12:45:22.123Z"
    }
  ]
}
```

---

#### 6. Cancel Subscription
**DELETE** `/api/subscriptions/{subscriptionId}`

Cancel an active subscription.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Subscription canceled successfully"
}
```

---

### Medical Records

#### 1. Upload Medical Record
**POST** `/api/medical-record/upload`

Upload a medical record file.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data
```

**Request Body:**
```
doctorId: 652c6f5b8f1b9e1234567890
file: <binary_file>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6789",
    "userId": "652c6f5b8f1b9e1234567890",
    "doctorId": "652c6f5b8f1b9e1234567890",
    "fileUrl": "https://cdn.example.com/medical-record.pdf",
    "uploadedAt": "2025-10-01T10:30:00Z"
  }
}
```

---

#### 2. Get All Medical Records
**GET** `/api/medical-record/gettall`

Retrieve all medical records of the authenticated user.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6789",
      "doctorName": "Dr. Ravi Kumar",
      "fileUrl": "https://cdn...",
      "uploadedAt": "2025-10-01T10:30:00Z"
    }
  ]
}
```

---

#### 3. Get Specific Medical Record
**GET** `/api/medical-record/gettall/{recordId}`

Get details of a specific medical record.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Parameters:**
- `recordId` (path): Medical record ID

**Response (200):**
```json
{
  "success": true,
  "data": { /* record details */ }
}
```

---

#### 4. Delete Medical Record
**DELETE** `/api/medical-record/{recordId}`

Delete a medical record.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Medical record deleted successfully"
}
```

---

### Prescriptions

#### 1. Create Prescription (Doctor)
**POST** `/api/prescriptions/add`

Create a new prescription for a patient.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "patientId": "6741babb81bd7a6d9c73a3e9",
  "doctorId": "6741cacb18abcf32109a45e1",
  "primaryDiagnosis": "Acute viral fever",
  "clinicalNotes": "Patient has high fever and weakness for 2 days.",
  "medicines": [
    {
      "name": "Paracetamol",
      "dosage": "500mg",
      "schedule": "1-1-1",
      "instructions": "After meals"
    }
  ],
  "recommendations": "Drink warm water, take proper rest.",
  "nextAppointment": "2025-12-20",
  "followUpInstructions": "Follow prescription for 3 days..."
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Prescription created successfully",
  "data": { /* prescription object */ }
}
```

---

#### 2. Get User Prescriptions
**GET** `/api/prescriptions`

Get all prescriptions for the authenticated user.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6789",
      "doctorName": "Dr. Ravi Kumar",
      "primaryDiagnosis": "Viral fever",
      "medicines": [ /* array of medicines */ ],
      "createdAt": "2025-10-01T10:30:00Z"
    }
  ]
}
```

---

#### 3. Get Prescription Details
**GET** `/api/prescriptions/{prescriptionId}`

Get complete details of a prescription.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": { /* full prescription details */ }
}
```

---

### Sessions

#### 1. Invite for Session
**POST** `/api/sessions/invite`

Invite a user or doctor for a consultation session.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "userId": "652c6f5b8f1b9e1234567890",
  "doctorId": "652c6f5b8f1b9e1234567800",
  "type": "video",
  "senderType": "user"
}
```

**Response (200):**
```json
{
  "success": true,
  "sessionId": "64fabc12345",
  "message": "Session invitation sent"
}
```

---

#### 2. Accept Session
**POST** `/api/sessions/accept`

Accept a session invitation.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "sessionId": "64fabc12345"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Session accepted",
  "data": { /* session object */ }
}
```

---

#### 3. Decline Session
**POST** `/api/sessions/decline`

Decline a session invitation.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "sessionId": "64fabc12345"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Session declined"
}
```

---

#### 4. End Session
**POST** `/api/sessions/end`

End an active session.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "sessionId": "64fabc12345"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Session ended successfully"
}
```

---

### Agora Video/Audio

#### 1. Generate RTC Token (GET)
**GET** `/api/agoras/rtc/{channelName}/role/{role}/uid/{uid}`

Generate a Realtime Communication (RTC) token for Agora.

**Parameters:**
- `channelName` (path): Agora channel name
- `role` (path): publisher | subscriber
- `uid` (path): Unique user ID

**Response (200):**
```json
{
  "token": "007eJxTYGD2/8/A...",
  "expireIn": 3600
}
```

---

#### 2. Generate RTC Token (POST)
**POST** `/api/agoras/rtc`

Generate RTC token using POST method.

**Request Body:**
```json
{
  "channelName": "testChannel",
  "uid": "user123",
  "role": "publisher"
}
```

**Response (200):**
```json
{
  "token": "007eJxTYGD2/8/A...",
  "expireIn": 3600
}
```

---

#### 3. Generate RTM Token
**POST** `/api/agoras/rtm`

Generate Real-time Messaging (RTM) token.

**Request Body:**
```json
{
  "uid": "user123"
}
```

**Response (200):**
```json
{
  "token": "007eJxTYGD2/8/A..."
}
```

---

### Admin Management

#### 1. Admin Login
**POST** `/api/admins/login`

Login to admin dashboard.

**Request Body:**
```json
{
  "email": "admin@example.com",
  "password": "admin123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Admin logged in successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

#### 2. Add Staff Member
**POST** `/api/admins/staff/add`

Add a new staff member (doctor, nurse, etc.).

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "123456",
  "roleId": "66fabcd1234567890abc1234"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Staff created successfully",
  "data": { /* staff object */ }
}
```

---

#### 3. Get All Users (Admin)
**GET** `/api/admins/users`

Retrieve all users (admin only).

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Items per page
- `role` (optional): Filter by role

**Response (200):**
```json
{
  "success": true,
  "data": [ /* array of users */ ],
  "total": 1250
}
```

---

#### 4. Get Dashboard Statistics
**GET** `/api/admins/statistics`

Get dashboard statistics and analytics.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "totalUsers": 5230,
    "totalDoctors": 45,
    "totalBookings": 2150,
    "totalRevenue": 1543250,
    "activeSubscriptions": 823
  }
}
```

---

### Roles & Permissions

#### 1. Add Role
**POST** `/api/roles/add`

Create a new role with permissions.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "name": "Moderator",
  "permissions": ["view_posts", "delete_comments", "ban_users"],
  "active": true
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Role created successfully",
  "data": { /* role object */ }
}
```

---

#### 2. Get All Roles
**GET** `/api/roles`

Retrieve all available roles.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "66fabcd1234567890abc1234",
      "name": "Admin",
      "permissions": ["create_user", "delete_user", "view_reports"],
      "active": true
    }
  ]
}
```

---

#### 3. Update Role
**PUT** `/api/roles/update/{roleId}`

Update role details and permissions.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Parameters:**
- `roleId` (path): Role ID

**Request Body:**
```json
{
  "name": "Super Moderator",
  "permissions": ["view_posts", "delete_comments", "ban_users", "edit_posts"]
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Role updated successfully",
  "data": { /* updated role object */ }
}
```

---

#### 4. Delete Role
**DELETE** `/api/roles/delete/{roleId}`

Delete a role.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Role deleted successfully"
}
```

---

### Features

#### 1. Get All Features
**GET** `/api/features/get-all`

Get all available features in the system.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "66fabcd1234567890abc1234",
      "name": "AI Symptom Tracker",
      "key": "ai_symptom_cycle_tracker",
      "description": "AI-powered symptom and cycle tracking"
    }
  ]
}
```

---

### Specializations

#### 1. Add Specialization
**POST** `/api/specializations/add`

Add a new medical specialization.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "name": "Gynecology",
  "description": "Women's reproductive health"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Specialization added successfully",
  "data": { /* specialization object */ }
}
```

---

#### 2. Get All Specializations
**GET** `/api/specializations/getallspecility`

Get all medical specializations.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "66fabcd1234567890abc1234",
      "name": "Gynecology",
      "description": "Women's reproductive health"
    }
  ]
}
```

---

#### 3. Update Specialization
**PUT** `/api/specializations/update/{specilityId}`

Update specialization details.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Request Body:**
```json
{
  "name": "Clinical Gynecology",
  "description": "Advanced women's healthcare"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Specialization updated successfully",
  "data": { /* updated specialization object */ }
}
```

---

#### 4. Delete Specialization
**DELETE** `/api/specializations/delete/{specilityId}`

Delete a specialization.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Specialization deleted successfully"
}
```

---

### Notifications

#### 1. Get All Notifications
**GET** `/api/notification/getAll/{userId}`

Get all notifications for a user.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Parameters:**
- `userId` (path): User ID

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6789",
      "userId": "652c6f5b8f1b9e1234567890",
      "title": "New Booking Confirmation",
      "message": "Your booking with Dr. Ravi Kumar is confirmed",
      "type": "booking",
      "read": false,
      "createdAt": "2025-10-01T10:30:00Z"
    }
  ]
}
```

---

#### 2. Mark Notification as Read
**PUT** `/api/notification/mark-read/{notificationId}`

Mark a notification as read.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

---

#### 3. Delete Notification
**DELETE** `/api/notification/delete/{id}`

Delete a notification.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Parameters:**
- `id` (path): Notification ID

**Response (200):**
```json
{
  "success": true,
  "message": "Notification deleted successfully"
}
```

---

### Policies

#### 1. Add Policy
**POST** `/api/policies/add`

Add a new policy (privacy, terms, etc.).

**Request Body:**
```json
{
  "type": "privacy",
  "content": "<p>This is the privacy policy...</p>"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Policy added successfully",
  "data": { /* policy object */ }
}
```

---

#### 2. Get Policy by Type
**GET** `/api/policies/{type}`

Retrieve a policy by type.

**Parameters:**
- `type` (path): Policy type (privacy, terms, return, etc.)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6789",
    "type": "privacy",
    "content": "<p>This is the privacy policy...</p>",
    "updatedAt": "2025-10-01T10:30:00Z"
  }
}
```

---

#### 3. Update Policy
**PUT** `/api/policies/update/{type}`

Update a policy.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Parameters:**
- `type` (path): Policy type

**Request Body:**
```json
{
  "content": "<p>Updated policy content...</p>"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Policy updated successfully",
  "data": { /* updated policy object */ }
}
```

---

#### 4. Delete Policy
**DELETE** `/api/policies/delete/{type}`

Delete a policy.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Policy deleted successfully"
}
```

---

### File Upload

#### 1. Single File Upload
**POST** `/api/fileuploads/single`

Upload a single file.

**Request Body:**
```
Content-Type: multipart/form-data
file: <binary_file>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "url": "https://cdn.example.com/file-123.jpg",
    "publicId": "baby-land/file-123"
  }
}
```

---

#### 2. Multiple Files Upload
**POST** `/api/fileuploads/multiple`

Upload multiple files at once.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data
```

**Request Body:**
```
Content-Type: multipart/form-data
files: <multiple_files>
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "url": "https://cdn.example.com/file-1.jpg",
      "publicId": "baby-land/file-1"
    },
    {
      "url": "https://cdn.example.com/file-2.jpg",
      "publicId": "baby-land/file-2"
    }
  ]
}
```

---

## Response Format

All API responses follow a consistent format:

### Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    /* Response data */
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message description",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional error details"
  }
}
```

### Paginated Response
```json
{
  "success": true,
  "data": [ /* array of items */ ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 10,
    "totalItems": 95,
    "hasNextPage": true,
    "hasPrevPage": false
  }
}
```

---

## Error Handling

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| INVALID_TOKEN | 401 | JWT token is invalid or expired |
| UNAUTHORIZED | 401 | User is not authenticated |
| FORBIDDEN | 403 | User lacks required permissions |
| NOT_FOUND | 404 | Requested resource not found |
| VALIDATION_ERROR | 400 | Request validation failed |
| DUPLICATE_ENTRY | 409 | Resource already exists |
| INTERNAL_ERROR | 500 | Internal server error |
| RATE_LIMITED | 429 | Too many requests |

### Example Error Response
```json
{
  "success": false,
  "message": "Invalid authentication token",
  "error": {
    "code": "INVALID_TOKEN",
    "details": "Token has expired. Please login again."
  }
}
```

---

## Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request successful |
| 201 | Created - Resource created successfully |
| 204 | No Content - Success with no response body |
| 400 | Bad Request - Invalid request parameters |
| 401 | Unauthorized - Authentication required |
| 403 | Forbidden - Permission denied |
| 404 | Not Found - Resource not found |
| 409 | Conflict - Resource already exists |
| 429 | Too Many Requests - Rate limit exceeded |
| 500 | Internal Server Error - Server error |
| 503 | Service Unavailable - Server temporarily unavailable |

---

## Pagination

For endpoints that return lists, pagination is available via query parameters:

```bash
GET /api/users?page=2&limit=20
```

**Query Parameters:**
- `page` (optional, default: 1): Page number
- `limit` (optional, default: 10): Items per page (max: 100)

**Response includes:**
```json
{
  "data": [ /* array of items */ ],
  "pagination": {
    "currentPage": 2,
    "totalPages": 10,
    "totalItems": 195,
    "hasNextPage": true,
    "hasPrevPage": true
  }
}
```

---

## Rate Limiting

The API implements rate limiting to prevent abuse:

- **Limit**: 100 requests per minute per user
- **Header**: `X-RateLimit-Remaining` shows remaining requests
- **Reset**: Limits reset every minute

When rate limited, you'll receive a 429 status:
```json
{
  "success": false,
  "message": "Too many requests. Please try again later.",
  "error": {
    "code": "RATE_LIMITED",
    "retryAfter": 45
  }
}
```

---

## Security Considerations

1. **Always use HTTPS** in production
2. **Keep tokens secure** - store in secure cookies or secure storage
3. **Use strong passwords** - minimum 8 characters with mixed case
4. **Never expose API keys** in client-side code
5. **Validate input** - sanitize all user inputs
6. **Update tokens regularly** - refresh tokens before expiration
7. **Use role-based access** - implement proper authorization checks
8. **Enable CORS** only for trusted domains

---

## Support

For API support and issues:
- Email: support@babyland.com
- Documentation: https://docs.babyland.com
- GitHub Issues: https://github.com/babyland/issues

---

**Last Updated**: February 19, 2026
**API Version**: 1.0.0
**Status**: Stable
