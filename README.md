# WardWatch

**Civic Issue Reporting & Resolution Platform**  
*A Flutter application connecting resident issue reporting with an administrative review and resolution workflow.*

WardWatch is a civic-tech application built with **Flutter, Dart and Supabase**. Residents can submit local issues with a description, photo and location details, then follow the status of their reports. Administrators can review incoming reports, update their status, add comments and view a summary of report status distribution.

---

## Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Application Flow](#application-flow)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Supabase Backend Setup](#supabase-backend-setup)
- [Permissions](#permissions)
- [Running Tests](#running-tests)
- [Implementation Notes](#implementation-notes)
- [Author](#author)

---

## Overview

WardWatch provides two role-based application experiences:

- **Resident Portal:** create and track civic issue reports, manage basic profile details and view report updates.
- **Admin Portal:** review the report queue, filter reports by status, update issue progress and view basic analytics.

The application uses Supabase for authentication, database operations and image storage. After authentication, the app reads the user's role from the `profiles` table and routes the user to the corresponding dashboard.

## Features

### Resident Portal

- Email/password sign-up and login, with a password-recovery entry point.
- Resident profile displaying contact and address information.
- Profile editing for phone number and ward address.
- Issue submission with a title, description and category.
- Photo capture for issue evidence.
- Location capture using device GPS, with a nearby-landmark field as an alternative location detail.
- Personal report list with total, pending and resolved counts.
- Report detail view showing the submitted information, evidence image, location details, current status and administrator comments when available.

### Admin Portal

- Separate dashboard for users whose profile role is `admin`.
- Master report queue with **All**, **Pending**, **In-Progress** and **Resolved** filters.
- Report details for reviewing the issue and its location information.
- Ability to update a report's status and add administrator comments.
- Status-change entries written to the `status_logs` table.
- Resolution timestamp recorded when a report is marked as resolved.
- Analytics view with status counts and a bar chart showing pending, in-progress and resolved reports.

## Technology Stack

| Area | Technologies |
|---|---|
| Application | Flutter, Dart, Material 3 |
| Authentication & backend | Supabase Auth, Supabase PostgreSQL, Supabase Storage |
| Image capture | `image_picker` |
| Location | `geolocator` |
| Charts | `fl_chart` |
| Date formatting | `intl` |
| Testing / linting | `flutter_test`, `flutter_lints` |

The current implementation uses Flutter's built-in state and asynchronous UI tools, including `setState`, `StreamBuilder` and `FutureBuilder`. Provider and BLoC are not currently used.

## Application Flow

```text
Launch WardWatch
      |
      v
Landing / Login / Sign-up
      |
      v
Supabase Authentication
      |
      v
Read role from profiles table
      |
      +--------------------------+
      |                          |
      v                          v
Resident Portal              Admin Portal
      |                          |
      v                          v
Submit / track reports       Review report queue
      |                          |
      v                          v
Supabase Storage + DB        Update status + comments
                                 |
                                 v
                         Status audit log + analytics
```

## Project Structure

```text
wardwatch/
├── android/                 # Android platform project
├── assets/
│   └── images/              # App logo and background assets
├── ios/                     # iOS platform project
├── lib/
│   ├── main.dart            # App entry point, Supabase init and role routing
│   ├── services/            # Authentication and database service logic
│   ├── views/
│   │   ├── landing_view.dart
│   │   ├── login_view.dart
│   │   ├── resident/         # Resident dashboard and report screens
│   │   └── admin/            # Admin dashboard and report review screens
│   └── widgets/              # Reusable UI components
├── test/                    # Flutter tests
├── web/                     # Web platform project
├── windows/                 # Windows platform project
├── linux/                   # Linux platform project
├── macos/                   # macOS platform project
├── pubspec.yaml             # Dependencies and assets
└── README.md
```

## Getting Started

### Prerequisites

- Flutter SDK installed and available on your `PATH`.
- A Dart SDK compatible with the constraint in `pubspec.yaml` (`^3.11.0` at the time this README was updated).
- Android Studio / an Android SDK, Xcode for iOS builds on macOS, or another configured Flutter target.
- Access to a Supabase project configured for this application (see [Supabase Backend Setup](#supabase-backend-setup)).

Check your local toolchain:

```bash
flutter --version
flutter doctor
```

### Clone and run

```bash
git clone https://github.com/minnieG12/WardWatch.git
cd WardWatch
flutter pub get
flutter run
```

Choose an available emulator, simulator or connected device when running the application.

## Supabase Backend Setup

WardWatch expects a Supabase project. The Flutter client is initialised in `lib/main.dart`; configure it with your Supabase project URL and a **client-side publishable key** (or the project's legacy `anon` key if the project has not migrated yet).

The current application code references the following database tables and fields. Your Supabase schema must match the queries and writes in the source code:

| Table | Fields referenced by the application |
|---|---|
| `profiles` | `id`, `role`, `full_name`, `email`, `phone_number`, `address` |
| `categories` | `id`, `category_name`, `default_priority` |
| `reports` | `id`, `user_id`, `category_id`, `title`, `description`, `priority_level`, `current_status`, `admin_comments`, `resolved_at`, `created_at` |
| `locations` | `report_id`, `latitude`, `longitude`, `landmark_details` |
| `media` | `report_id`, `url`, `media_type` |
| `status_logs` | `report_id`, `changed_by`, `status_from`, `status_to`, `remarks` |

Create a Supabase Storage bucket named **`issue-images`** for report evidence images. The application uploads captured images to this bucket and stores the resulting public URL in the `media` table.

> **Backend setup is not bundled here:** this repository currently contains the Flutter client, not a complete database migration or seed-data package. You must configure the tables, relationships, storage bucket, authentication settings and access policies in your own Supabase project before the application can work end-to-end.

### Security checklist

- Enable **Row Level Security (RLS)** on exposed tables and write least-privilege policies for resident and administrator actions.
- Restrict residents to the records they are authorised to access; grant administrator access only through a properly validated role and database policies.
- Apply appropriate access policies to the `issue-images` Storage bucket.
- Use a publishable/legacy `anon` key in the client. **Never put a Supabase `service_role` or secret key in Flutter code or any public repository.**
- Do not commit passwords, private tokens, signing keys or real user data.

A client-side key is visible in a mobile or web application by design; it is not a substitute for database and Storage access policies. See the [Supabase security guide](https://supabase.com/docs/guides/database/secure-data) and [Row Level Security documentation](https://supabase.com/docs/guides/database/postgres/row-level-security).

## Permissions

The report-submission flow uses the device camera and location services. Configure the relevant camera and location permissions for each platform you intend to run, following the Flutter plugin setup instructions:

- [`image_picker`](https://pub.dev/packages/image_picker)
- [`geolocator`](https://pub.dev/packages/geolocator)

Platform folders are present in the repository, but permissions and build settings should be checked for the specific target device and operating system.

## Running Tests

Run the Flutter test suite with:

```bash
flutter test
```

Run static analysis with:

```bash
flutter analyze
```

## Implementation Notes

- The resident report flow requires a category, title and evidence photo. It also requires GPS coordinates or a nearby landmark before submission.
- Report records, location details and media metadata are written to separate Supabase tables by the database service.
- The administrator dashboard listens to the reports data stream and refreshes its report queue and analytics from Supabase.
- The repository does not include production credentials, demo accounts or a bundled Supabase database schema. Configure a separate backend and test accounts before demonstrating the app.

## Author

**Asmita Guha**  
[GitHub](https://github.com/minnieG12)

---

*Built as a Flutter-based civic-tech application focused on making issue reporting and administrative follow-up easier to track.*
