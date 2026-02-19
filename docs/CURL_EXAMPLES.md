# Baby Land API - cURL Examples & Response Guide

This document provides complete cURL examples with detailed response payloads for all Baby Land API endpoints.

## Table of Contents
1. [Authentication Examples](#authentication-examples)
2. [User Management Examples](#user-management-examples)
3. [Menstrual Tracking Examples](#menstrual-tracking-examples)
4. [Pregnancy Examples](#pregnancy-examples)
5. [Postpartum Examples](#postpartum-examples)
6. [Baby Growth Examples](#baby-growth-examples)
7. [Doctor & Booking Examples](#doctor--booking-examples)
8. [AI Chat Examples](#ai-chat-examples)
9. [Community Examples](#community-examples)
10. [Plans & Subscriptions Examples](#plans--subscriptions-examples)
11. [Medical Records Examples](#medical-records-examples)
12. [Sessions & Agora Examples](#sessions--agora-examples)
13. [Admin Examples](#admin-examples)

---

## Authentication Examples

### 1. Request Verification Code

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/auths/request-verification' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "deviceToken": "firebase_token_abc123xyz"
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Verification code generated successfully",
  "data": {
    "_id": "652c6f5b8f1b9e1234567890",
    "name": "John Doe",
    "email": "john@example.com",
    "verificationCode": "123456",
    "createdAt": "2025-10-01T10:30:00Z",
    "expiresAt": "2025-10-01T10:40:00Z"
  }
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "Email already exists",
  "error": {
    "code": "DUPLICATE_ENTRY",
    "details": "This email is already registered"
  }
}
```

---

### 2. Verify Code

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/auths/verify-code' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "john@example.com",
    "verificationCode": "123456"
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Code verified successfully",
  "data": {
    "verified": true,
    "expiresIn": 600
  }
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "Invalid or expired verification code",
  "error": {
    "code": "INVALID_CODE",
    "details": "The code you entered is incorrect or has expired"
  }
}
```

---

### 3. Complete Signup

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/auths/complete-signup' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "john@example.com",
    "verificationCode": "123456",
    "password": "SecurePassword@123",
    "role": "User"
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "_id": "652c6f5b8f1b9e1234567890",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "User",
      "isVerified": true,
      "approved": true,
      "createdAt": "2025-10-01T10:30:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NTJjNmY1YjhmMWI5ZTEyMzQ1Njc4OTAiLCJpYXQiOjE2OTU4MzA2MDB9.signature"
  }
}
```

---

### 4. User Login

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/auths/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "john@example.com",
    "password": "SecurePassword@123",
    "deviceToken": "firebase_token_abc123xyz"
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "User logged in successfully",
  "data": {
    "user": {
      "_id": "652c6f5b8f1b9e1234567890",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "User",
      "isVerified": true,
      "lastPeriodStartDate": "2025-09-28",
      "cycleType": "regular",
      "cycleLengthDays": 28
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NTJjNmY1YjhmMWI5ZTEyMzQ1Njc4OTAiLCJpYXQiOjE2OTU4MzA2MDB9.signature",
    "refreshToken": "refresh_token_xyz789"
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Invalid credentials",
  "error": {
    "code": "INVALID_CREDENTIALS",
    "details": "Email or password is incorrect"
  }
}
```

---

## User Management Examples

### 1. Get User Profile

**cURL Command:**
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/users/profile' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NTJjNmY1YjhmMWI5ZTEyMzQ1Njc4OTAiLCJpYXQiOjE2OTU4MzA2MDB9.signature'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "652c6f5b8f1b9e1234567890",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "User",
    "isVerified": true,
    "profilePic": "https://cloudinary.com/image.jpg",
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
    "medicalHistory": "No major medical history",
    "createdAt": "2025-10-01T10:30:00Z",
    "updatedAt": "2025-10-15T14:45:30Z"
  }
}
```

---

### 2. Complete Onboarding

**cURL Command:**
```bash
curl -X PUT 'https://api-babyland.duckdns.org/api/users/onboarding/complete' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
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
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Onboarding completed successfully",
  "data": {
    "_id": "652c6f5b8f1b9e1234567890",
    "name": "John Doe",
    "email": "john@example.com",
    "lastPeriodStartDate": "2025-09-28",
    "cycleType": "regular",
    "cycleLengthDays": 28,
    "averagePeriodLengthDays": 5,
    "conditions": {
      "PCOS": true,
      "PMS": false
    },
    "medicalHistory": "No major medical history.",
    "onboardingCompleted": true,
    "updatedAt": "2025-10-15T14:45:30Z"
  }
}
```

---

## Menstrual Tracking Examples

### 1. Add Menstrual Cycle

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/menstruals/add-cycle' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "startDate": "2025-10-01",
    "endDate": "2025-10-05",
    "notes": "Heavy flow, experienced cramps"
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Cycle added successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6789",
    "userId": "652c6f5b8f1b9e1234567890",
    "startDate": "2025-10-01",
    "endDate": "2025-10-05",
    "notes": "Heavy flow, experienced cramps",
    "duration": 5,
    "createdAt": "2025-10-01T10:30:00Z"
  }
}
```

---

### 2. Add Daily Log

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/menstruals/logs' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "date": "2025-10-09",
    "mood": "Good",
    "stressLevel": 2,
    "anxietyLevel": 1,
    "symptoms": ["cramps", "fatigue", "bloating"],
    "notes": "Felt slightly tired today"
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Daily log added successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6790",
    "userId": "652c6f5b8f1b9e1234567890",
    "date": "2025-10-09",
    "mood": "Good",
    "stressLevel": 2,
    "anxietyLevel": 1,
    "symptoms": ["cramps", "fatigue", "bloating"],
    "notes": "Felt slightly tired today",
    "createdAt": "2025-10-09T08:15:30Z"
  }
}
```

---

### 3. Get Predicted Cycles

**cURL Command:**
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/menstruals/predicted-cycles' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6791",
      "startDate": "2025-11-01",
      "endDate": "2025-11-05",
      "ovulationDay": "2025-11-14",
      "fertilityWindow": [
        "2025-11-12",
        "2025-11-13",
        "2025-11-14",
        "2025-11-15",
        "2025-11-16"
      ],
      "confidence": 0.92
    },
    {
      "_id": "625a4c8e7f1b2c3d4e5f6792",
      "startDate": "2025-11-29",
      "endDate": "2025-12-03",
      "ovulationDay": "2025-12-12",
      "fertilityWindow": [
        "2025-12-10",
        "2025-12-11",
        "2025-12-12",
        "2025-12-13",
        "2025-12-14"
      ],
      "confidence": 0.88
    }
  ]
}
```

---

## Pregnancy Examples

### 1. Start Pregnancy Tracking

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/pregnancys/start' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "pregnancyStartDate": "2025-10-01",
    "expectedDueDate": "2026-06-30"
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Pregnancy tracking started",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6793",
    "userId": "652c6f5b8f1b9e1234567890",
    "pregnancyStartDate": "2025-10-01",
    "expectedDueDate": "2026-06-30",
    "currentWeek": 5,
    "trimester": 1,
    "fetalGrowthStage": "Embryo stage - 2mm in length",
    "status": "active",
    "createdAt": "2025-10-01T10:30:00Z"
  }
}
```

---

### 2. Add Pregnancy Daily Log

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/pregnancys/logs' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "date": "2025-10-09",
    "mood": "Good",
    "symptoms": ["nausea", "breast_tenderness"],
    "stressLevel": 2,
    "anxietyLevel": 1,
    "sleepQuality": 4,
    "notes": "Feeling better today, nausea reduced"
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Daily log added successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6794",
    "pregnancyId": "625a4c8e7f1b2c3d4e5f6793",
    "date": "2025-10-09",
    "mood": "Good",
    "symptoms": ["nausea", "breast_tenderness"],
    "stressLevel": 2,
    "anxietyLevel": 1,
    "sleepQuality": 4,
    "notes": "Feeling better today, nausea reduced",
    "createdAt": "2025-10-09T08:20:00Z"
  }
}
```

---

### 3. Add Appointment

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/pregnancys/appointments' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "OB-GYN Checkup",
    "date": "2025-10-15",
    "time": "10:30 AM",
    "reminder": true,
    "notes": "Bring previous test reports"
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Appointment added successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6795",
    "pregnancyId": "625a4c8e7f1b2c3d4e5f6793",
    "title": "OB-GYN Checkup",
    "date": "2025-10-15",
    "time": "10:30 AM",
    "reminder": true,
    "notes": "Bring previous test reports",
    "createdAt": "2025-10-09T08:20:00Z"
  }
}
```

---

## Postpartum Examples

### 1. Start Postpartum Tracking

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/postpartums/start' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "deliveryDate": "2025-10-15",
    "deliveryType": "Normal",
    "babyDetails": {
      "name": "Baby Girl",
      "date": "2025-10-15",
      "gender": "Female",
      "weight": 3.2,
      "height": 50,
      "apgarScore": 9
    }
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Postpartum tracking started",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6796",
    "userId": "652c6f5b8f1b9e1234567890",
    "deliveryDate": "2025-10-15",
    "deliveryType": "Normal",
    "daysPostPartum": 5,
    "babyDetails": {
      "name": "Baby Girl",
      "date": "2025-10-15",
      "gender": "Female",
      "weight": 3.2,
      "height": 50,
      "apgarScore": 9
    },
    "status": "active",
    "createdAt": "2025-10-15T14:30:00Z"
  }
}
```

---

### 2. Add Feeding Log

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/postpartums/feedings' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "time": "2025-10-20T08:30:00Z",
    "type": "Breastfeeding",
    "side": "Left",
    "durationMinutes": 15,
    "quantity": null,
    "notes": "Baby fed well, good latch"
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Feeding recorded successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6797",
    "postpartumId": "625a4c8e7f1b2c3d4e5f6796",
    "time": "2025-10-20T08:30:00Z",
    "type": "Breastfeeding",
    "side": "Left",
    "durationMinutes": 15,
    "notes": "Baby fed well, good latch",
    "createdAt": "2025-10-20T08:30:00Z"
  }
}
```

---

## Baby Growth Examples

### 1. Add Growth Measurements

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/babygrowths/add-growth' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "date": "2025-10-20",
    "height": 52.5,
    "weight": 4.2,
    "headCircumference": 37.5
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Growth record added successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6798",
    "babyGrowthId": "625a4c8e7f1b2c3d4e5f6799",
    "date": "2025-10-20",
    "height": 52.5,
    "weight": 4.2,
    "headCircumference": 37.5,
    "heightPercentile": 50,
    "weightPercentile": 45,
    "createdAt": "2025-10-20T09:15:00Z"
  }
}
```

---

### 2. Add Milestone

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/babygrowths/milestones' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "date": "2025-10-20",
    "title": "First Smile",
    "photo": "https://cloudinary.com/smile.jpg",
    "note": "Baby smiled at me today!"
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Milestone added successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6800",
    "babyGrowthId": "625a4c8e7f1b2c3d4e5f6799",
    "date": "2025-10-20",
    "title": "First Smile",
    "photo": "https://cloudinary.com/smile.jpg",
    "note": "Baby smiled at me today!",
    "ageInDays": 35,
    "createdAt": "2025-10-20T10:00:00Z"
  }
}
```

---

### 3. Add Vaccination

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/babygrowths/vaccinations' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "vaccine": "BCG",
    "dueDate": "2025-10-15",
    "status": "completed",
    "dateCompleted": "2025-10-15",
    "notes": "No side effects observed"
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Vaccination recorded successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6801",
    "babyGrowthId": "625a4c8e7f1b2c3d4e5f6799",
    "vaccine": "BCG",
    "dueDate": "2025-10-15",
    "status": "completed",
    "dateCompleted": "2025-10-15",
    "notes": "No side effects observed",
    "createdAt": "2025-10-15T14:30:00Z"
  }
}
```

---

## Doctor & Booking Examples

### 1. Get All Doctors

**cURL Command:**
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/doctors/all?page=1&limit=10&search=gynecology' \
  -H 'Content-Type: application/json'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "652c6f5b8f1b9e1234567890",
      "name": "Dr. Ravi Kumar",
      "email": "ravi.kumar@example.com",
      "doctorDetails": {
        "firstName": "Ravi",
        "lastName": "Kumar",
        "speciality": ["Gynecology", "Obstetrics"],
        "profileBio": "Experienced gynecologist with 15+ years of practice",
        "consultationFee": 500,
        "currency": "INR",
        "languages": ["English", "Hindi"],
        "totalReviewCount": 45,
        "totalAvgRating": 4.7,
        "weeklySlots": [
          {
            "day": "Monday",
            "startTime": "09:00 AM",
            "endTime": "05:00 PM"
          },
          {
            "day": "Wednesday",
            "startTime": "10:00 AM",
            "endTime": "03:00 PM"
          }
        ]
      },
      "location": {
        "latitude": 24.5854,
        "longitude": 73.9129
      }
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 5,
    "totalItems": 45,
    "hasNextPage": true
  }
}
```

---

### 2. Create Booking

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/bookings/add' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "doctorId": "652c6f5b8f1b9e1234567890",
    "date": "2025-10-12",
    "time": "09:30 AM",
    "consultationFee": 500,
    "currency": "INR",
    "paymentMethod": "Razorpay"
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6802",
    "doctorId": "652c6f5b8f1b9e1234567890",
    "userId": "652c6f5b8f1b9e1234567891",
    "doctorName": "Dr. Ravi Kumar",
    "date": "2025-10-12",
    "time": "09:30 AM",
    "consultationFee": 500,
    "currency": "INR",
    "status": "pending",
    "paymentStatus": "pending",
    "paymentMethod": "Razorpay",
    "razorpayOrderId": "order_NH8hX2a9n1J3yz",
    "createdAt": "2025-10-01T10:30:00Z"
  }
}
```

---

### 3. Get Upcoming Bookings

**cURL Command:**
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/bookings/upcoming' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

**Success Response (200):**
```json
{
  "success": true,
  "bookings": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6802",
      "doctorId": "652c6f5b8f1b9e1234567890",
      "doctorName": "Dr. Ravi Kumar",
      "doctorImage": "https://cloudinary.com/doctor.jpg",
      "date": "2025-10-12",
      "time": "09:30 AM",
      "status": "confirmed",
      "paymentStatus": "completed",
      "consultationFee": 500,
      "consultationType": "Video",
      "createdAt": "2025-10-01T10:30:00Z"
    }
  ]
}
```

---

## AI Chat Examples

### 1. Create Chat Conversation

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/aichats/create-chat' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json'
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6803",
    "userId": "652c6f5b8f1b9e1234567891",
    "title": "New Conversation",
    "createdAt": "2025-10-01T10:30:00Z"
  }
}
```

---

### 2. Send Message to AI

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/aichats/send-message' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "conversationId": "625a4c8e7f1b2c3d4e5f6803",
    "chatInput": "What are safe exercises during pregnancy?"
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "conversationId": "625a4c8e7f1b2c3d4e5f6803",
    "userMessage": "What are safe exercises during pregnancy?",
    "aiResponse": "Safe exercises during pregnancy include:\n\n1. **Walking** - 30 minutes daily is ideal\n2. **Swimming** - Low impact, excellent for all trimesters\n3. **Prenatal Yoga** - Improves flexibility and breathing\n4. **Modified Pilates** - Core strengthening\n5. **Stationary Cycling** - Low impact cardio\n\nAlways consult your OB-GYN before starting any exercise program. Avoid activities with fall risk or abdominal impact.",
    "timestamp": "2025-10-01T10:35:00Z"
  }
}
```

---

### 3. Get All User Chats

**cURL Command:**
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/aichats/my-chats?page=1&limit=10' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6803",
      "userId": "652c6f5b8f1b9e1234567891",
      "title": "Exercise Questions",
      "lastMessage": "What are safe exercises during pregnancy?",
      "messageCount": 5,
      "createdAt": "2025-10-01T10:30:00Z",
      "updatedAt": "2025-10-01T10:35:00Z"
    }
  ]
}
```

---

### 4. Get AI Insights

**cURL Command:**
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/ai/insights?category=nutrition&week=16' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "source": "database",
    "data": {
      "_id": "625a4c8e7f1b2c3d4e5f6804",
      "userId": "652c6f5b8f1b9e1234567891",
      "week": 16,
      "category": "nutrition",
      "items": [
        {
          "title": "Iron Intake",
          "emoji": "🥩",
          "description": "Increase iron-rich foods like spinach, red meat, and legumes. Iron is crucial for blood production during pregnancy."
        },
        {
          "title": "Calcium & Dairy",
          "emoji": "🥛",
          "description": "Consume 1000mg daily. Include milk, yogurt, cheese, and fortified plant-based alternatives."
        },
        {
          "title": "Folate Foods",
          "emoji": "🥬",
          "description": "Leafy greens, asparagus, and Brussels sprouts help prevent neural tube defects."
        }
      ],
      "quick_tip": {
        "emoji": "💡",
        "text": "Eat a balanced diet with plenty of vegetables, fruits, whole grains, and protein sources."
      },
      "createdAt": "2025-10-01T10:30:00Z",
      "updatedAt": "2025-10-01T10:30:00Z"
    }
  }
}
```

---

## Community Examples

### 1. Add Community Post

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/communities/add' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "Felt my baby kick for the first time! #movement #trimester2 #babyboy"
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Community post created successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6805",
    "userId": "652c6f5b8f1b9e1234567891",
    "userName": "John Doe",
    "userImage": "https://cloudinary.com/user.jpg",
    "message": "Felt my baby kick for the first time! #movement #trimester2 #babyboy",
    "hashtags": ["movement", "trimester2", "babyboy"],
    "likes": 0,
    "comments": 0,
    "createdAt": "2025-10-01T10:30:00Z"
  }
}
```

---

### 2. Get All Community Posts

**cURL Command:**
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/communities/all?page=1&limit=10&hashtag=pregnancy' \
  -H 'Content-Type: application/json'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6805",
      "userId": {
        "_id": "652c6f5b8f1b9e1234567891",
        "name": "Jane Doe",
        "profilePic": "https://cloudinary.com/jane.jpg"
      },
      "message": "Felt my baby kick for the first time!",
      "hashtags": ["movement", "trimester2"],
      "likes": 45,
      "comments": 12,
      "likedByUser": false,
      "createdAt": "2025-10-01T10:30:00Z"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 8,
    "totalItems": 75
  }
}
```

---

### 3. Add Comment to Post

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/communities/comment/625a4c8e7f1b2c3d4e5f6805' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "comment": "Congratulations! This is such a beautiful moment!"
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Comment added successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6806",
    "postId": "625a4c8e7f1b2c3d4e5f6805",
    "userId": "652c6f5b8f1b9e1234567892",
    "userName": "Alice Smith",
    "userImage": "https://cloudinary.com/alice.jpg",
    "comment": "Congratulations! This is such a beautiful moment!",
    "likes": 0,
    "createdAt": "2025-10-01T11:00:00Z"
  }
}
```

---

## Plans & Subscriptions Examples

### 1. Get All Plans

**cURL Command:**
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/plans' \
  -H 'Content-Type: application/json'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "6719dd4b9371e7a5501fabb3",
      "name": "Free Plan",
      "price": 0,
      "duration": 999,
      "features": [
        "Basic cycle tracking",
        "Community access",
        "Limited AI insights"
      ],
      "active": true,
      "createdAt": "2025-10-01T00:00:00Z"
    },
    {
      "_id": "6719dd4b9371e7a5501fabb4",
      "name": "Premium Plan",
      "price": 499,
      "duration": 30,
      "features": [
        "Unlimited AI Chat",
        "Advanced insights",
        "Priority support",
        "Doctor consultations discount"
      ],
      "active": true,
      "createdAt": "2025-10-01T00:00:00Z"
    }
  ]
}
```

---

### 2. Subscribe to Plan

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/subscriptions/add' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "planId": "6719dd4b9371e7a5501fabb4",
    "paymentMethod": "Razorpay"
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Subscription created successfully",
  "data": {
    "_id": "672ff0b3c2e4126c90f27b9a",
    "userId": "671aad0cfaa1bb937ce0a94a",
    "planId": "6719dd4b9371e7a5501fabb4",
    "planName": "Premium Plan",
    "paymentMethod": "Razorpay",
    "amount": 499,
    "currency": "INR",
    "razorpayOrderId": "order_NH8hX2a9n1J3yz",
    "active": false,
    "status": "pending",
    "expiresAt": "2025-11-16T12:45:22.123Z",
    "createdAt": "2025-10-16T12:45:22.123Z"
  }
}
```

---

## Medical Records Examples

### 1. Upload Medical Record

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/medical-record/upload' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -F 'doctorId=652c6f5b8f1b9e1234567890' \
  -F 'file=@/path/to/medical_record.pdf'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6807",
    "userId": "652c6f5b8f1b9e1234567891",
    "doctorId": "652c6f5b8f1b9e1234567890",
    "doctorName": "Dr. Ravi Kumar",
    "fileName": "medical_record.pdf",
    "fileUrl": "https://res.cloudinary.com/babyland/image/upload/v1696089000/medical_record.pdf",
    "fileSize": 2048000,
    "uploadedAt": "2025-10-01T10:30:00Z"
  }
}
```

---

### 2. Get All Medical Records

**cURL Command:**
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/medical-record/gettall' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "625a4c8e7f1b2c3d4e5f6807",
      "doctorId": "652c6f5b8f1b9e1234567890",
      "doctorName": "Dr. Ravi Kumar",
      "fileName": "medical_record.pdf",
      "fileUrl": "https://res.cloudinary.com/babyland/image/upload/v1696089000/medical_record.pdf",
      "uploadedAt": "2025-10-01T10:30:00Z"
    }
  ]
}
```

---

## Sessions & Agora Examples

### 1. Invite for Session

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/sessions/invite' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "userId": "652c6f5b8f1b9e1234567891",
    "doctorId": "652c6f5b8f1b9e1234567890",
    "type": "video",
    "senderType": "user"
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Session invitation sent",
  "data": {
    "sessionId": "625a4c8e7f1b2c3d4e5f6808",
    "userId": "652c6f5b8f1b9e1234567891",
    "doctorId": "652c6f5b8f1b9e1234567890",
    "type": "video",
    "status": "pending",
    "createdAt": "2025-10-01T10:30:00Z"
  }
}
```

---

### 2. Generate Agora RTC Token

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/agoras/rtc' \
  -H 'Content-Type: application/json' \
  -d '{
    "channelName": "consultation_652c6f5b",
    "uid": "user123",
    "role": "publisher"
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "007eJxTYPj/r80hJzG1pLg0r6AoNzkvxdAwzySxJDU1p7golqQkr7hUKSml5GxqcXmxUXFZUVJpSUlRUWFecVFpSVFBUWFRYWFBUWlJUWFJSWlhUVlxSUFRSUlpQVFJQWlheWFBUWlhUWlpUWphQWFBUUlxaWFJSXFpcWlxSWlhUUlpUXlpSXFBSWlxaWlpaURqZV1pSmlmSmlWSllyLiU=",
    "expireTime": 3600
  }
}
```

---

## Admin Examples

### 1. Admin Login

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/admins/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Admin logged in successfully",
  "data": {
    "admin": {
      "_id": "652c6f5b8f1b9e1234567880",
      "name": "Admin User",
      "email": "admin@example.com",
      "role": "Admin"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### 2. Add Plan (Admin)

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/plans/add' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Gold Plan",
    "price": 999,
    "duration": 90,
    "features": [
      "Unlimited AI Chat",
      "Video consultations",
      "24/7 Priority support",
      "Personalized insights",
      "Community premium features"
    ]
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Plan created successfully",
  "data": {
    "_id": "625a4c8e7f1b2c3d4e5f6809",
    "name": "Gold Plan",
    "price": 999,
    "duration": 90,
    "features": [
      "Unlimited AI Chat",
      "Video consultations",
      "24/7 Priority support"
    ],
    "active": true,
    "createdAt": "2025-10-01T10:30:00Z"
  }
}
```

---

## Error Response Examples

### Session/Token Expired

**cURL Command:**
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/users/profile' \
  -H 'Authorization: Bearer expired_token_xyz'
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Token expired",
  "error": {
    "code": "TOKEN_EXPIRED",
    "details": "Your session has expired. Please login again."
  }
}
```

---

### Validation Error

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/bookings/add' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \
  -H 'Content-Type: application/json' \
  -d '{
    "doctorId": "",
    "date": "invalid-date"
  }'
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "Validation failed",
  "error": {
    "code": "VALIDATION_ERROR",
    "details": "doctorId is required, date must be a valid date format (YYYY-MM-DD)"
  }
}
```

---

### Not Found

**cURL Command:**
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/doctors/invalid_id' \
  -H 'Content-Type: application/json'
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Doctor not found",
  "error": {
    "code": "NOT_FOUND",
    "details": "The requested doctor does not exist"
  }
}
```

---

### Insufficient Permissions

**cURL Command:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/plans/add' \
  -H 'Authorization: Bearer user_token' \
  -H 'Content-Type: application/json' \
  -d '{"name": "New Plan", "price": 499}'
```

**Error Response (403):**
```json
{
  "success": false,
  "message": "Access denied",
  "error": {
    "code": "FORBIDDEN",
    "details": "You do not have permission to create plans. Admin access required."
  }
}
```

---

## Testing Tips

### 1. Save Token to Environment Variable
```bash
TOKEN=$(curl -s -X POST 'https://api-babyland.duckdns.org/api/auths/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }' | jq -r '.data.token')

echo $TOKEN
```

### 2. Use Token in Subsequent Requests
```bash
curl -H "Authorization: Bearer $TOKEN" \
  'https://api-babyland.duckdns.org/api/users/profile'
```

### 3. Pretty Print JSON Responses
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/doctors/all' | jq .
```

### 4. Save Response to File
```bash
curl -X GET 'https://api-babyland.duckdns.org/api/plans' \
  -H 'Content-Type: application/json' > response.json
```

### 5. Using Different Content Types

**Form Data:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/fileuploads/single' \
  -F 'file=@/path/to/image.jpg'
```

**URL Encoded:**
```bash
curl -X POST 'https://api-babyland.duckdns.org/api/endpoint' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'param1=value1&param2=value2'
```

---

**Last Updated**: February 19, 2026
**API Version**: 1.0.0
