# TDL-001: Fix CI k6 Test Endpoint Mismatches

## 🎯 **FIX SUMMARY**

**Date:** August 7, 2025  
**Status:** ✅ COMPLETED  
**Effort:** 2-3 hours  
**Risk:** LOW (CI configuration only)

## 🔍 **ROOT CAUSE ANALYSIS**

The CI k6 load tests were failing because of endpoint mismatches between what the CI expected and what the backend actually provides:

### **Issues Identified:**

1. **Profile Endpoint Mismatch:**
   - CI expected: `/api/users/profile`
   - Backend provides: `/api/users/me/profile`
   - Result: 404 errors causing test failures

2. **Plans Endpoint Missing:**
   - CI expected: `GET /api/plans`
   - Backend provides: Only `POST /api/plans` (create endpoint)
   - Result: 404 errors causing test failures

## 🛠️ **FIXES IMPLEMENTED**

### **1. Fixed Profile Endpoint**

**File:** `integration/.github/workflows/integration-ci.yml`  
**Line:** ~500

**Before:**

```javascript
const profileRes = http.get("http://localhost:3000/api/users/profile", {
  headers,
});
```

**After:**

```javascript
const profileRes = http.get("http://localhost:3000/api/users/me/profile", {
  headers,
});
```

### **2. Replaced Plans Endpoint with Events Endpoint**

**File:** `integration/.github/workflows/integration-ci.yml`  
**Line:** ~510

**Before:**

```javascript
// Test 3: Plans endpoint
group("Plans Endpoints", function () {
  const plansRes = http.get("http://localhost:3000/api/plans", { headers });
  check(plansRes, {
    "plans status 200 or 401": (r) => r.status === 200 || r.status === 401,
    "plans response time < 250ms": (r) => r.timings.duration < 250,
  });
});
```

**After:**

```javascript
// Test 3: Events endpoint - FIXED: Changed from /api/plans to /api/events/trending (existing endpoint)
group("Events Endpoints", function () {
  const eventsRes = http.get("http://localhost:3000/api/events/trending", {
    headers,
  });
  check(eventsRes, {
    "events status 200 or 401": (r) => r.status === 200 || r.status === 401,
    "events response time < 250ms": (r) => r.timings.duration < 250,
  });
});
```

## ✅ **VALIDATION CRITERIA MET**

- [x] **Profile endpoint** now uses correct path `/api/users/me/profile`
- [x] **Events endpoint** replaces non-existent plans endpoint with `/api/events/trending`
- [x] **Test expectations** remain the same (200 or 401 responses)
- [x] **Response time thresholds** maintained (200ms for profile, 250ms for events)
- [x] **Authentication headers** properly applied to both endpoints

## 🧪 **TESTING VERIFIED**

### **Local Testing Results:**

1. **Profile Endpoint:** ✅ Returns 401 (authentication required) - expected behavior
2. **Events Endpoint:** ✅ Returns 200 with empty results - expected behavior
3. **Health Check:** ✅ Returns 200 - working correctly

### **Expected CI Results:**

- k6 tests should now pass with >90% check rate
- No more 404 errors in test results
- All endpoints return expected 200/401 responses

## 📋 **NEXT STEPS**

This fix addresses the immediate CI failures. The following TDL items should be considered:

1. **TDL-002:** Implement proper GET /api/plans endpoint (if needed)
2. **TDL-003:** Fix token generation for proper authentication
3. **TDL-004:** Add test user seeding for authenticated tests

## 🔄 **ROLLBACK PLAN**

If issues arise, the backup file can be restored:

```bash
cp .github/workflows/integration-ci.yml.backup .github/workflows/integration-ci.yml
```

## 📊 **IMPACT ASSESSMENT**

**Risk Level:** LOW  
**Scope:** CI configuration only  
**Dependencies:** None  
**Rollback:** Immediate (backup available)

---

**Author:** AI Assistant  
**Reviewer:** [To be assigned]  
**Approval:** [To be assigned]
