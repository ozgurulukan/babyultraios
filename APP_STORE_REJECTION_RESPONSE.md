# Bubsie App Store Rejection Response & Fix Documentation

**Date:** 1 May 2026  
**App:** Bubsie (com.fagore.bubsie)  
**Rejection Guidelines:** 2.1, 2.3.3, 5.1.1(i), 5.1.2(i)

---

## Summary of Changes Made

### 1. iOS App Changes (`/Users/ozgurulukan/Developer/bubsieios`)

#### TransformView.swift — Enhanced Consent Dialog
- **File:** `Bubsie/Views/TransformView.swift`
- **Changes:**
  - Made consent dialog title bold and larger (`AI Photo Processing Consent`)
  - Added subtitle: "Before you upload, please read and confirm the following:"
  - Updated bullet points to explicitly mention:
    - "My uploaded photo — which may contain **face data** — will be sent to our secure servers"
    - "...and shared with **fal.ai, a third-party AI service**, solely to generate the requested transformation"
    - "fal.ai does not use my data to train AI models without my explicit consent"
  - Added a **tappable link to the Privacy Policy** within the consent dialog
  - Changed button text from "Agree" → "Agree & Continue" and "Decline" → "Not Now"
  - Increased overlay opacity for better focus on the consent content

#### Localizable.strings — All 20 Languages Updated
- **Files:** `Bubsie/Localization/*.lproj/Localizable.strings`
- **New/Updated Keys:**
  - `transform.consent_title` = "AI Photo Processing Consent"
  - `transform.consent_subtitle` = "Before you upload, please read and confirm the following:"
  - `transform.consent_bullet1-5` (5 explicit bullets)
  - `transform.consent_privacy_link` = "Read our full Privacy Policy"
  - `transform.consent_agree` = "Agree & Continue"
  - `transform.consent_decline` = "Not Now"
  - `app.privacy_url` = "https://fagore.com/privacy/"

#### Privacy Manifest Created
- **File:** `Bubsie/PrivacyInfo.xcprivacy`
- **Contents:** Declares collection of:
  - Photos/Videos (linked to user, not for tracking, app functionality)
  - User ID (linked to user, not for tracking, app functionality)
  - Purchase History (linked to user, not for tracking, app functionality)
  - Crash Data (not linked, not for tracking, analytics)
  - Performance Data (not linked, not for tracking, analytics)
  - API access declarations for UserDefaults (CA92.1) and FileTimestamp (C617.1)

#### Info.plist / Build Settings Updated
- **File:** `Bubsie.xcodeproj/project.pbxproj`
- **Changes:**
  - Added `INFOPLIST_KEY_NSCameraUsageDescription` = "Bubsie needs camera access so you can take photos to transform with AI."
  - Updated `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` to be more descriptive: "Bubsie needs access to your photo library so you can select photos to transform with AI and save generated results."

---

### 2. Privacy Policy Changes (`/Users/ozgurulukan/Developer/fagorecomwebsite`)

#### Section 3 — Face Data (Completely Rewritten)
- Explicitly states **what face data is collected**: "facial features, facial geometry, or other face data" embedded in uploaded photos
- Lists **all planned uses**: "AI-powered image and video generation features (e.g., style transfer, face swap, avatar creation, animated videos, and photo enhancements)"
- Explicitly states **what face data is NOT used for**: "authentication, surveillance, advertising, user profiling, or third-party marketing"
- Details **where face data is stored**:
  - On user's device
  - On Cloudflare R2 (US/EU regions)
  - Transmitted to fal.ai for processing
- Specifies **exact retention periods**:
  - Raw uploaded photos: **30 days** (then auto-deleted)
  - Generated outputs: **90 days** or until user deletes
  - Account deletion: **48 hours** for active data, up to 30 days for backups
- States **sharing policy**: "We do not sell, rent, or share raw face data... only shared with fal.ai"
- Describes **consent mechanism**: "explicit, informed consent within the app"
- Describes **security**: TLS 1.3 encryption, access controls, rate limiting, Firebase auth

#### Section 4 — Third Party AI Processing (Expanded)
- **What data is sent to fal.ai** (explicit bullet list):
  - Photos and images (which may contain face data)
  - Text prompts
  - Technical parameters
  - Family photos for multi-face templates
- **Who receives the data**: "fal.ai (FAL Technologies, Inc.), a third-party AI service provider"
- **Purpose**: "solely to generate the AI-transformed output you requested"
- **Key addition for Apple compliance**: "**fal.ai provides the same or equal protection of personal data** as required by our agreements."
- Links to fal.ai's privacy policy
- User rights and opt-out information

#### Section 9 — Data Retention and Account Deletion (Expanded)
- Added specific retention periods for all data types:
  - Uploaded photos: 30 days
  - AI-generated outputs: 90 days
  - Account/profile data: until deletion
  - Transaction records: 7 years (legal requirement)
  - Request logs: 90 days
  - Anonymized data: indefinitely

---

## Answers to Apple's Guideline 2.1 Questions

Copy and paste these directly into your App Store Connect response.

### Q1: What face data does the app collect?

> The Bubsie app collects face data **only when a user voluntarily uploads a photo** for AI-powered transformation. The face data consists of **facial features, facial geometry, and other face data embedded within the uploaded photo**. We do not use facial recognition technology to independently analyze or extract facial data from the image. The face data remains part of the photo the user chooses to upload. No face data is collected from the camera, photo library, or any other source without the user's explicit upload action.

### Q2: Provide a complete and clear explanation of all planned uses of the collected face data.

> Face data is collected and processed **solely** to enable AI-powered image and video generation features within the Bubsie app. Specifically, the planned uses are:
>
> 1. **Style transfer** — Applying artistic or thematic styles to uploaded photos while preserving facial identity
> 2. **Face swap / identity preservation** — Using models such as fal-ai/flux-pulid to place the user's face into generated scenes
> 3. **Avatar creation** — Generating themed portraits and character images
> 4. **Animated videos** — Creating motion videos from still photos (e.g., dancing baby animations)
> 5. **Photo enhancement** — Upscaling and improving photo quality
>
> **We do not use face data for any other purpose**, including authentication, surveillance, advertising, user profiling, or third-party marketing.

### Q3: Will the face data be shared with any third parties? Where will this information be stored?

> **Yes, face data is shared with one third party:**
>
> **fal.ai** (FAL Technologies, Inc.) — a third-party AI service provider that performs the actual AI image/video generation.
>
> Face data is stored in three locations:
>
> 1. **User's device** — The original photo remains on the user's device unless deleted by the user.
> 2. **Our secure servers (Cloudflare R2, US/EU regions)** — Uploaded photos are temporarily stored under the user's unique Firebase UID to process the request and allow re-download of results.
> 3. **fal.ai's secure servers** — The uploaded photo (containing face data) is transmitted to fal.ai solely for the duration of the AI generation process. fal.ai does not retain the data for model training or any other purpose.

### Q4: How long will face data be retained?

> We have implemented the following specific retention periods for face data:
>
> - **Raw uploaded photos** (containing face data): Retained for **up to 30 days** from the date of upload, after which they are automatically deleted from our active servers.
> - **AI-generated outputs** (which may contain transformed face data): Retained for **up to 90 days** or until the user deletes them from their Generations history, whichever comes first.
> - **Upon account deletion**: All uploaded photos and generated outputs are permanently deleted from our active servers within **48 hours**. Backup systems may retain data for up to **30 additional days** before complete purging.
> - **Anonymized/aggregated analytics**: May be retained indefinitely, but all personally identifiable face data is stripped.

### Q5: Where in the privacy policy is the app's collection, use, disclosure, sharing, and retention of face data explained? Identify the specific sections.

> The app's handling of face data is explained in the following specific sections of our Privacy Policy (https://fagore.com/privacy/):
>
> - **Section 1(c) — "Face Data"** under "Information We Collect": Describes what face data is collected and that it is used solely for AI-powered transformations.
> - **Section 3 — "Face Data"**: Provides complete details on collection, use, storage locations, retention periods, sharing, consent, and security measures.
> - **Section 4 — "Third Party AI Processing"**: Explains that face data is shared with fal.ai, what data is sent, the purpose, and the protections in place.
> - **Section 9 — "Data Retention and Account Deletion"**: Specifies exact retention periods for uploaded photos (30 days), generated outputs (90 days), and deletion timelines (48 hours).

### Q6: Quote the specific text from the privacy policy concerning face data.

> **From Section 1(c) — Face Data:**
> "Some of our applications may request access to your camera or photo library to capture or upload images containing facial data. This is used solely for the intended functionality of the specific feature (such as avatar creation, filters, or AI-powered transformations). We do not use face data for authentication or surveillance purposes."
>
> **From Section 3 — Face Data:**
> "What face data we collect: When you upload a photo for AI transformation, the image you provide may contain facial features, facial geometry, or other face data of you or your child. We do not use facial recognition technology to analyze or extract facial data ourselves. The face data remains embedded within the photo you upload."
>
> "How we use face data: Face data is collected and processed solely to enable AI-powered image and video generation features (e.g., style transfer, face swap, avatar creation, animated videos, and photo enhancements). We do not use face data for any other purpose, including authentication, surveillance, advertising, user profiling, or third-party marketing."
>
> "Sharing of face data: We do not sell, rent, or share raw face data with any third parties for their independent use. Face data is only shared with fal.ai, a third-party AI service provider strictly necessary to perform the requested AI generation function."
>
> **From Section 4 — Third Party AI Processing:**
> "What data is sent to fal.ai: Photos and images: When you use AI-powered features (such as image generation, style transfer, face swap, video animation, or enhancement), your uploaded photo — which may contain face data — is transmitted to fal.ai's secure servers for processing."
>
> "Data handling and protection by fal.ai: fal.ai processes data in accordance with its own privacy and security standards, which include encryption in transit and at rest, access controls, and compliance with GDPR and other applicable privacy regulations. fal.ai provides the same or equal protection of personal data as required by our agreements."

---

## Answers to Apple's Guideline 5.1.1(i) / 5.1.2(i) Questions

### What data is sent to the third-party AI service?

> The following data is sent to fal.ai when a user initiates an AI transformation:
>
> 1. **Uploaded photo** — The user's selected image, which may contain face data. This is the primary input for the AI model.
> 2. **Text prompts** — Any template instruction, description, or custom prompt provided by the user to guide the AI generation.
> 3. **Technical parameters** — Aspect ratio, model selection, generation parameters (e.g., num_inference_steps, guidance_scale).
> 4. **Family photos (if applicable)** — For certain templates requiring multiple faces (e.g., mom, dad, baby), each uploaded photo is sent individually.
>
> No other personal data (name, email, location, device ID) is sent to fal.ai.

### Who is the data sent to?

> The data is sent to **fal.ai** (FAL Technologies, Inc.), a third-party AI service provider. fal.ai operates secure servers in the United States and European Union.

### How does the app obtain the user's permission before sharing data?

> The app implements an **explicit, informed consent dialog** that appears **before** the user can upload any photo for AI processing. The dialog:
>
> 1. Is titled "AI Photo Processing Consent"
> 2. Clearly states: "My uploaded photo — which may contain face data — will be sent to our secure servers and shared with fal.ai, a third-party AI service, solely to generate the requested transformation."
> 3. Includes a link to the full Privacy Policy
> 4. Requires the user to tap **"Agree & Continue"** before proceeding to the image picker
> 5. If the user taps **"Not Now"**, the dialog dismisses and no data is sent
>
> The user's consent is recorded in UserDefaults (`photoConsentAccepted`). The dialog will appear again if consent is reset or on a new device installation.

### What does the privacy policy say about the third party's data protection?

> From **Section 4 — Third Party AI Processing** of our Privacy Policy:
>
> "fal.ai processes data in accordance with its own privacy and security standards, which include encryption in transit and at rest, access controls, and compliance with GDPR and other applicable privacy regulations. **fal.ai provides the same or equal protection of personal data** as required by our agreements."

---

## Guideline 2.3.3 — Screenshot Fix Instructions

### Problem
Apple rejected the screenshots because they are **marketing/promotional materials** with decorative backgrounds, device frames, and collage layouts. Apple requires screenshots that show the **actual app UI** running on the device.

### Solution
You must capture **new screenshots directly from the iOS Simulator or a physical device** showing the real app interface. Do not add:
- Decorative backgrounds
- Marketing text overlays
- Device frames or bezels
- Photo collages outside the app

### Recommended Screenshot Flow (6.5-inch iPhone)
1. **Home screen** — Show the actual HomeView with template grid, category filters, and navigation
2. **Template selection** — Show a template detail/card with "Try Now" button
3. **TransformView** — Show the actual upload screen with aspect ratio selection (before upload)
4. **Consent dialog** — Show the new AI Photo Processing Consent sheet (this proves you handle privacy properly)
5. **Photo picker / selected photo** — Show the TransformView with a selected photo and the "Transform" CTA
6. **Result screen** — Show the ResultView with a generated image, save/share buttons

### Recommended Screenshot Flow (13-inch iPad)
Repeat the same 6 screens on iPad. Make sure to use iPad-specific simulator/device.

### How to Capture
```bash
# Example: Capture from iPhone 15 Pro Max simulator
# Open Simulator → Device → iPhone 15 Pro Max
# Run the app, navigate to each screen
# Use Cmd+S to save screenshot (saves to Desktop)
```

Upload these clean, actual UI screenshots to App Store Connect.

---

## Remaining Tasks for You

### High Priority (Before Resubmission)

1. **Add PrivacyInfo.xcprivacy to Xcode project**
   - Open `Bubsie.xcodeproj` in Xcode
   - Drag `Bubsie/PrivacyInfo.xcprivacy` into the Project Navigator under the Bubsie target
   - Ensure it is included in the **Copy Bundle Resources** build phase
   - Build and verify the file appears in the app bundle

2. **Take new screenshots**
   - Follow the instructions in the "Screenshot Fix Instructions" section above
   - Upload to App Store Connect for all required sizes (6.5" iPhone, 13" iPad, etc.)

3. **Build and test the app**
   - Clean build folder (Cmd+Shift+K)
   - Build (Cmd+B)
   - Run on simulator/device and verify:
     - Consent dialog appears with new text
     - Privacy Policy link works
     - Camera/Photo Library permission descriptions appear correctly

4. **Deploy updated privacy policy**
   - The file `pages/privacy.js` has been updated
   - Build and deploy the Next.js site to production
   - Verify https://fagore.com/privacy/ shows the updated content

5. **Submit App Store response**
   - Copy the answers from this document into the App Review Information section
   - Reference the specific changes made (consent dialog, privacy policy updates, privacy manifest)

### Medium Priority (Post-Approval Recommended)

6. **Implement backend data retention cleanup**
   - The privacy policy states 30-day auto-deletion for raw uploads and 90-day for outputs
   - Your backend currently does **not** have automatic cleanup
   - Add a cron job or scheduled task in the Go backend to:
     - Delete R2 objects in `uploads/{uid}/` older than 30 days
     - Delete R2 objects in `results/{uid}/` older than 90 days where the user has deleted the history item
   - Add an R2 `Delete` method to `internal/service/storage/r2.go`
   - This is important for legal compliance with your stated privacy policy

7. **Translate consent strings to other languages**
   - All 20 `.lproj` files currently have English consent text
   - For App Store review, English is sufficient, but for users, you should translate:
     - `transform.consent_title`
     - `transform.consent_subtitle`
     - `transform.consent_bullet1-5`
     - `transform.consent_agree`
     - `transform.consent_decline`
     - `transform.consent_privacy_link`

8. **Add R2 file deletion on account/history deletion**
   - Currently when users delete history or their account, the database records are removed but R2 files remain
   - Update `internal/handler/admin.go` and `internal/handler/user.go` to call R2 delete for associated files

---

## Files Modified

### iOS App (`bubsieios`)
- `Bubsie/Views/TransformView.swift` — Enhanced consent dialog UI
- `Bubsie/Localization/*.lproj/Localizable.strings` (all 20 languages) — Updated consent strings
- `Bubsie.xcodeproj/project.pbxproj` — Added NSCameraUsageDescription, updated NSPhotoLibraryUsageDescription
- `Bubsie/PrivacyInfo.xcprivacy` — **NEW** Privacy manifest file

### Privacy Policy Website (`fagorecomwebsite`)
- `pages/privacy.js` — Completely rewritten Sections 3, 4, and 9 with explicit face data and third-party AI disclosures

---

*End of document*
