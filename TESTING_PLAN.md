# End-to-End CRUD Testing Plan

## Overview
This document outlines the comprehensive testing plan to validate the full CRUD (Create, Read, Update, Delete) flow for property listings with image management.

---

## Test Environment Setup

### Prerequisites
- Firebase project configured and running
- Flutter app dependencies installed (`flutter pub get`)
- Device/emulator ready (Android, iOS, or web)
- Test user accounts prepared for signup/login
- Image files available (at least 5 test images)

### Before Starting Tests
1. Clear app cache: `flutter clean && flutter pub get`
2. Run static analysis: `flutter analyze` (should show **0 errors**)
3. Rebuild app: `flutter run` or `flutter run -d <device_id>`
4. Verify Firebase connectivity (check Firestore console)

---

## Test Cases

### Phase 1: Authentication & Role Setup

#### Test 1.1: User Signup with Role Selection
**Objective:** Verify user signup persists all fields including role
**Steps:**
1. Open app, navigate to signup page
2. Fill in:
   - Email: `testowner@example.com`
   - Password: `Test@1234`
   - First Name: `Test`
   - Last Name: `Owner`
   - City: `Dakar`
   - Country: `Senegal`
   - Bio: `Property owner`
3. Select role: **Tenant** (default)
4. Click "Sign Up"

**Expected Results:**
- ✅ User account created in Firebase Auth
- ✅ User document in Firestore with fields:
  ```
  email: testowner@example.com
  firstName: Test
  lastName: Owner
  city: Dakar
  country: Senegal
  bio: Property owner
  role: tenant
  createdAt: <timestamp>
  ```
- ✅ User redirected to home page
- ✅ User profile shows "Test Owner" name

**Validation Command (Firebase Console):**
```
Navigate to: Firestore > users collection
Verify document has all fields above
```

---

#### Test 1.2: Promote User to Owner
**Objective:** Verify role promotion works
**Prerequisites:** Test 1.1 passed, user logged in
**Steps:**
1. Navigate to Account/Profile page
2. Locate "Promote to Owner" button (only visible for tenants)
3. Click "Promote to Owner"
4. Confirm action in dialog

**Expected Results:**
- ✅ Button disappears (user is now owner)
- ✅ User document in Firestore updated: `role: owner`
- ✅ "Create Listing" button now visible in MyListingsPage
- ✅ User can now create/edit/delete listings

**Validation Command (Firebase Console):**
```
Navigate to: Firestore > users > <userId>
Verify: role field changed from "tenant" to "owner"
```

---

### Phase 2: Create (Property Creation with Images)

#### Test 2.1: Create Property with Single Image
**Objective:** Verify property creation with image upload
**Prerequisites:** Test 1.2 passed (user is owner)
**Steps:**
1. Navigate to MyListingsPage
2. Click "Create New Listing" button
3. **Step 1 - Infos:**
   - Title: `Beautiful 2-Bedroom Apartment`
   - Description: `Spacious modern apartment in city center`
   - Type: `Apartment`
   - Bedrooms: `2`
   - Bathrooms: `1`
   - Price: `500`
   - Currency: `USD`
4. **Step 2 - Photos:**
   - Click "Pick Images"
   - Select 1 image from device
   - Verify image preview shows
5. **Step 3 - Localisation:**
   - Address: `123 Main Street`
   - District: `Downtown`
   - Latitude: `14.6928`
   - Longitude: `-17.0461`
   - Status: `Available`
6. **Step 4 - Résumé:**
   - Review all entered data
   - Click "Create Listing"

**Expected Results:**
- ✅ Loading indicator shows during upload
- ✅ Property created in Firestore with ID
- ✅ Image uploaded to Firebase Storage at `property_<id>/image_<timestamp>.jpg`
- ✅ `imageUrls` array in property document contains 1 URL
- ✅ User redirected to MyListingsPage
- ✅ New property appears in listing with image thumbnail

**Validation Commands (Firebase Console):**
```
// Firestore validation
Navigate to: Firestore > properties > <propertyId>
Verify:
- title: "Beautiful 2-Bedroom Apartment"
- price: 500
- imageUrls: [<storage_url>]
- ownerId: <userId>
- createdAt: <timestamp>
- status: "Available"
- isAvailable: true

// Storage validation
Navigate to: Storage > images/property_<propertyId>/image_*.jpg
Verify: File exists and is accessible
```

---

#### Test 2.2: Create Property with Multiple Images
**Objective:** Verify batch image upload
**Prerequisites:** Test 2.1 passed
**Steps:**
1. Click "Create New Listing" again
2. Fill Step 1-2 as before but:
   - Title: `Modern Studio with Balcony`
   - In Step 2, select **3 images**
3. Complete remaining steps and submit

**Expected Results:**
- ✅ All 3 images upload (may show progress)
- ✅ All 3 image URLs stored in `imageUrls` array
- ✅ Property doc contains all 3 URLs: `imageUrls: [url1, url2, url3]`
- ✅ Gallery shows all 3 images on property details

**Validation:**
```
Firebase Console: Properties > <propertyId>
Verify: imageUrls array has 3 entries
Storage: Check all 3 files exist
```

---

### Phase 3: Read (Property Retrieval)

#### Test 3.1: View Own Listings in MyListingsPage
**Objective:** Verify user sees only their properties
**Prerequisites:** Test 2.2 passed (user has 2 properties)
**Steps:**
1. Navigate to MyListingsPage
2. Verify list displays

**Expected Results:**
- ✅ Both properties created in Tests 2.1 & 2.2 displayed
- ✅ Each property shows:
  - Thumbnail (first image)
  - Title
  - Price
  - Address
  - Edit button
  - Delete button
  - View analytics button
- ✅ No properties from other users visible

**Validation:**
```
Firestore query validation:
- getHostProperties(userId) returns 2 properties
- Each has ownerId == userId
```

---

#### Test 3.2: Discover Properties on Home Page
**Objective:** Verify all available properties appear in discovery
**Prerequisites:** Other users have also created listings
**Steps:**
1. Navigate to Home/Discovery page
2. View property list

**Expected Results:**
- ✅ All available properties from all users displayed
- ✅ Properties ordered by `createdAt` (newest first)
- ✅ User's own properties also visible (with edit/delete buttons)
- ✅ Other users' properties visible (no edit/delete buttons)

**Validation:**
```
Firestore: getAllProperties() should return all where isAvailable: true
Verify each property has ownerId set correctly
```

---

#### Test 3.3: View Property Details
**Objective:** Verify full property information displays
**Prerequisites:** Test 3.1 or 3.2 passed
**Steps:**
1. Click on a property (either own or another user's)
2. Navigate to PropertyDetailsPage

**Expected Results:**
- ✅ All property fields display:
  - Title, description, images (gallery/carousel)
  - Type, bedrooms, bathrooms, price, currency
  - Address, district, location coordinates
  - Owner info (name, rating)
  - Status, availability
  - Conditions/features
- ✅ Images load correctly and can be scrolled
- ✅ Favorites button works (toggle)
- ✅ For own property: Edit button available
- ✅ For other's property: Book button available

**Validation:**
```
Firestore: Property doc loaded correctly with all fields
Images: All URLs resolve to actual images
```

---

#### Test 3.4: Search by City
**Objective:** Verify property search by city works
**Prerequisites:** Multiple properties in different cities created
**Steps:**
1. Navigate to Search page
2. Enter city: `Dakar`
3. Click Search

**Expected Results:**
- ✅ Only properties with city == `Dakar` displayed
- ✅ Properties ordered by `createdAt` descending
- ✅ All matching properties shown

**Validation:**
```
Firestore query: searchPropertiesByCity("Dakar")
Verify all returned properties have: city == "Dakar" && isAvailable: true
```

---

#### Test 3.5: Search by Price Range
**Objective:** Verify property search by price works
**Prerequisites:** Properties with various prices created
**Steps:**
1. Navigate to Search page
2. Enter price range: Min `400`, Max `600`
3. Click Search

**Expected Results:**
- ✅ Only properties with `400 <= price <= 600` displayed
- ✅ All matching properties returned

**Validation:**
```
Firestore query: searchByPriceRange(400, 600)
Verify all returned properties: 400 <= price <= 600 && isAvailable: true
```

---

### Phase 4: Update (Property Editing)

#### Test 4.1: Edit Property Basic Fields
**Objective:** Verify property fields can be updated without changing images
**Prerequisites:** Test 2.1 passed (property with 1 image created)
**Steps:**
1. Navigate to MyListingsPage
2. Click "Edit" on the first property created
3. EditPropertyPage opens with pre-filled data
4. **Step 1 - Infos:**
   - Change Title to: `Luxurious 2-Bedroom with Sea View`
   - Change Description to: `Updated description with more details`
   - Change Price to: `550`
5. **Step 2 - Photos:**
   - Verify existing image shows
   - **Do NOT** add new images or remove existing
6. **Step 3 - Localisation:**
   - Change address to: `456 New Street`
7. **Step 4 - Résumé:**
   - Review changes
   - Click "Save Property"

**Expected Results:**
- ✅ Property document updated with new title, description, price, address
- ✅ **Original image URL preserved** (not replaced)
- ✅ `imageUrls` still contains 1 URL (same as before)
- ✅ `updatedAt` timestamp updated
- ✅ User redirected to MyListingsPage
- ✅ List shows updated data (title, price)

**Validation (Firebase Console):**
```
Firestore > properties > <propertyId>
Verify:
- title: "Luxurious 2-Bedroom with Sea View"
- price: 550
- address: "456 New Street"
- imageUrls: [<same_original_url>]  ← SAME URL!
- updatedAt: <new_timestamp>
```

---

#### Test 4.2: Edit Property - Add New Images
**Objective:** Verify new images can be added to existing property
**Prerequisites:** Test 4.1 passed (property has 1 image)
**Steps:**
1. Click "Edit" on the property again
2. **Step 2 - Photos:**
   - Verify 1 existing image shows
   - Click "Add Images"
   - Select **2 new images**
   - Verify 2 new images appear in list
   - Verify total now shows 3 image previews (1 existing + 2 new)
3. Complete remaining steps and save

**Expected Results:**
- ✅ 2 new images uploaded to Storage
- ✅ `imageUrls` now contains **3 URLs** (1 original + 2 new)
- ✅ All 3 images visible in property details
- ✅ Gallery shows all 3 in correct order

**Validation:**
```
Firestore > properties > <propertyId>
Verify: imageUrls has 3 entries, all valid URLs

Storage:
Verify: 3 files exist in property_<id>/ directory
```

---

#### Test 4.3: Edit Property - Remove Existing Images
**Objective:** Verify images can be removed
**Prerequisites:** Test 4.2 passed (property has 3 images)
**Steps:**
1. Click "Edit" on the property
2. **Step 2 - Photos:**
   - Verify 3 image previews show
   - Click delete button (X) on 1st image
   - Verify 1st image disappears from preview
   - Verify now shows 2 image previews
3. Complete steps and save

**Expected Results:**
- ✅ `imageUrls` updated to contain **2 URLs** (original 3 minus 1)
- ✅ Gallery displays only 2 images
- ✅ Storage: Old file still exists (not deleted from Storage)
- ✅ Property doc shows correct 2 URLs

**Validation:**
```
Firestore > properties > <propertyId>
Verify: imageUrls has 2 entries

Note: Files in Storage are NOT deleted (cleanup would need scheduled task)
```

---

#### Test 4.4: Edit Property - Replace All Images
**Objective:** Verify entire image gallery can be replaced
**Prerequisites:** Test 4.3 passed (property has 2 images)
**Steps:**
1. Click "Edit"
2. **Step 2 - Photos:**
   - Delete both existing images
   - Add 3 completely new images
3. Save

**Expected Results:**
- ✅ All old image URLs removed from `imageUrls`
- ✅ 3 new URLs added
- ✅ Gallery displays only new 3 images
- ✅ Original images still in Storage (not deleted)

**Validation:**
```
Firestore: imageUrls has 3 completely different URLs
```

---

### Phase 5: Delete (Property Deletion)

#### Test 5.1: Delete Property with Confirmation
**Objective:** Verify property can be deleted
**Prerequisites:** Test 4.4 passed
**Steps:**
1. Navigate to MyListingsPage
2. Click "Delete" button on a property
3. Confirmation dialog appears: "Are you sure you want to delete this listing?"
4. Click "Delete"

**Expected Results:**
- ✅ Property disappears from MyListingsPage immediately
- ✅ Property document deleted from Firestore
- ✅ Property removed from Discovery page (`getAllProperties`)
- ✅ Images still exist in Storage (no automatic cleanup)

**Validation:**
```
Firestore > properties > <propertyId>
Verify: Document no longer exists

Discovery/Home page:
Verify: Deleted property no longer appears in list
```

---

#### Test 5.2: Delete Property - Cancel Confirmation
**Objective:** Verify deletion can be cancelled
**Prerequisites:** At least 1 property available
**Steps:**
1. Click "Delete" on a property
2. Dialog appears
3. Click "Cancel" (or dismiss dialog)

**Expected Results:**
- ✅ Dialog closes
- ✅ Property remains in list
- ✅ Property still visible in Firestore
- ✅ No changes to property data

**Validation:**
```
Property still exists in Firestore and UI
```

---

#### Test 5.3: Delete All Properties
**Objective:** Verify multiple deletions work
**Prerequisites:** User has 2+ properties
**Steps:**
1. Delete property #1, confirm
2. Delete property #2, confirm
3. Verify MyListingsPage now empty or shows "No listings" message

**Expected Results:**
- ✅ Both properties deleted from Firestore
- ✅ MyListingsPage shows empty state
- ✅ Both removed from Discovery page
- ✅ User can create new properties again

---

### Phase 6: Edge Cases & Error Handling

#### Test 6.1: Network Disconnection During Image Upload
**Objective:** Verify graceful error handling
**Steps:**
1. Start creating property with multiple images
2. During upload, disable network (airplane mode / disconnect WiFi)
3. Observe behavior

**Expected Results:**
- ✅ Upload fails gracefully
- ✅ Error message shown to user
- ✅ User can retry or cancel
- ✅ App doesn't crash
- ✅ Partial uploads cleaned up (no orphaned Storage files)

---

#### Test 6.2: Very Large Images
**Objective:** Verify handling of large image files
**Steps:**
1. Create property with 5 high-resolution images (5MB+ each)
2. Attempt upload

**Expected Results:**
- ✅ Images eventually upload (may take time)
- ✅ URLs correctly stored in Firestore
- ✅ No timeout errors
- ✅ Progress indication shown

---

#### Test 6.3: Rapid Sequential Operations
**Objective:** Verify app handles rapid CRUD operations
**Steps:**
1. Create 3 properties rapidly (back-to-back)
2. Edit 1st property while others upload
3. Delete property while editing another

**Expected Results:**
- ✅ All operations complete without conflicts
- ✅ Firestore documents consistent
- ✅ UI state remains synchronized
- ✅ No duplicate documents
- ✅ No lost changes

---

#### Test 6.4: Edit Non-Existent Property
**Objective:** Verify error handling for deleted property
**Steps:**
1. Create property and note its ID
2. Delete property in Firestore (directly or via UI)
3. Try to edit property via back button/cached reference
4. Observe error handling

**Expected Results:**
- ✅ Error message shown
- ✅ User redirected to appropriate page
- ✅ App doesn't crash
- ✅ UI remains responsive

---

## Test Execution Checklist

### Before Testing
- [ ] `flutter clean && flutter pub get`
- [ ] `flutter analyze` → 0 errors
- [ ] Device/emulator ready
- [ ] Firebase project accessible
- [ ] Test images prepared (5+ images)

### Phase 1: Authentication
- [ ] Test 1.1: Signup with role selection
- [ ] Test 1.2: Promote to owner

### Phase 2: Create
- [ ] Test 2.1: Create with 1 image
- [ ] Test 2.2: Create with 3 images

### Phase 3: Read
- [ ] Test 3.1: View own listings
- [ ] Test 3.2: Discover all properties
- [ ] Test 3.3: View property details
- [ ] Test 3.4: Search by city
- [ ] Test 3.5: Search by price

### Phase 4: Update
- [ ] Test 4.1: Edit basic fields (keep images)
- [ ] Test 4.2: Add new images
- [ ] Test 4.3: Remove images
- [ ] Test 4.4: Replace all images

### Phase 5: Delete
- [ ] Test 5.1: Delete with confirmation
- [ ] Test 5.2: Cancel deletion
- [ ] Test 5.3: Delete all properties

### Phase 6: Edge Cases
- [ ] Test 6.1: Network disconnection
- [ ] Test 6.2: Large images
- [ ] Test 6.3: Rapid operations
- [ ] Test 6.4: Non-existent property

---

## Troubleshooting

### Issue: Properties not appearing in discovery
**Solution:**
- Check Firebase Rules: `isAvailable` must be `true`
- Verify `createdAt` timestamp is set
- Run query in Firebase Console manually

### Issue: Images not uploading
**Solution:**
- Verify Firebase Storage rules allow write
- Check network connectivity
- Verify image file format (JPG/PNG)

### Issue: "Property not found" on edit
**Solution:**
- Verify property ID exists in Firestore
- Check user permissions (ownerId matches)
- Refresh property list

### Issue: Firestore query returns no results
**Solution:**
- Check query filters (isAvailable, city, price range)
- Verify document fields match query criteria
- Run query in Firebase Console

---

## Success Criteria

✅ **All tests MUST pass before marking CRUD complete:**
1. Properties create with correct Firestore structure
2. Images upload and URLs persist
3. All CRUD operations work without errors
4. Firestore data matches UI state
5. No orphaned/duplicate documents
6. Error handling graceful

**Current Status:** Ready for testing

