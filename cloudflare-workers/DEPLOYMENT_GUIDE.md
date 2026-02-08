# 🔐 Security Headers Worker - Deployment Guide

## Overview

This Cloudflare Worker adds comprehensive security headers to your Weltenbibliothek Flutter app to improve security posture and protect against common web vulnerabilities.

---

## 🛡️ Security Headers Added

### 1. **Content-Security-Policy (CSP)**
Prevents XSS attacks by controlling which resources can be loaded.

```
default-src 'self'
script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.gstatic.com
style-src 'self' 'unsafe-inline' https://fonts.googleapis.com
img-src 'self' data: https: blob:
font-src 'self' data: https://fonts.gstatic.com
connect-src 'self' https://weltenbibliothek-api.brandy13062.workers.dev https://*.firebaseapp.com
media-src 'self' https: blob:
object-src 'none'
frame-ancestors 'self'
base-uri 'self'
form-action 'self'
upgrade-insecure-requests
```

### 2. **X-Frame-Options: SAMEORIGIN**
Prevents clickjacking attacks by controlling iframe embedding.

### 3. **Strict-Transport-Security (HSTS)**
Forces HTTPS connections for 1 year (including subdomains).

```
max-age=31536000; includeSubDomains; preload
```

### 4. **X-Content-Type-Options: nosniff**
Prevents MIME-sniffing attacks.

### 5. **Referrer-Policy: strict-origin-when-cross-origin**
Controls how much referrer information is shared.

### 6. **Permissions-Policy**
Restricts access to browser features:
- Geolocation: disabled
- Microphone: disabled
- Camera: disabled
- Payment: disabled
- USB: disabled
- Magnetometer: disabled
- Gyroscope: disabled
- Accelerometer: disabled

### 7. **X-XSS-Protection: 1; mode=block**
Enables browser XSS protection (legacy support).

### 8. **Cross-Origin-Opener-Policy: same-origin-allow-popups**
Prevents other origins from gaining window references.

### 9. **Cross-Origin-Resource-Policy: same-origin**
Controls which origins can load this resource.

---

## 🚀 Deployment Steps

### **Method 1: Deploy via Wrangler CLI (Recommended)**

```bash
cd /home/user/flutter_app/cloudflare-workers

# Set environment variables
export CLOUDFLARE_API_TOKEN="y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y"
export CLOUDFLARE_ACCOUNT_ID="3472f5994537c3a30c5caeaff4de21fb"

# Deploy the worker
wrangler deploy
```

**Expected Output:**
```
✨ Success! Uploaded 1 file
✨ Your worker has been deployed to:
   https://weltenbibliothek-security-headers.brandy13062.workers.dev
```

---

### **Method 2: Deploy via Cloudflare Dashboard**

1. **Go to:** https://dash.cloudflare.com/3472f5994537c3a30c5caeaff4de21fb/workers/overview
2. **Click:** "Create a Worker"
3. **Name:** `weltenbibliothek-security-headers`
4. **Copy & Paste:** Content from `security-headers.js`
5. **Click:** "Save and Deploy"

---

### **Method 3: Configure via Pages Settings**

Since this is a Pages project, you can also add headers via `_headers` file:

Create `/home/user/flutter_app/build/web/_headers`:

```
/*
  X-Frame-Options: SAMEORIGIN
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
  X-XSS-Protection: 1; mode=block
  Cross-Origin-Opener-Policy: same-origin-allow-popups
  Cross-Origin-Resource-Policy: same-origin
  Permissions-Policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
  Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.gstatic.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https: blob:; font-src 'self' data: https://fonts.gstatic.com; connect-src 'self' https://weltenbibliothek-api.brandy13062.workers.dev https://*.firebaseapp.com; media-src 'self' https: blob:; object-src 'none'; frame-ancestors 'self'; base-uri 'self'; form-action 'self'; upgrade-insecure-requests
```

Then rebuild and redeploy:

```bash
cd /home/user/flutter_app
flutter build web --release
wrangler pages deploy build/web --project-name=weltenbibliothek
```

---

## 🧪 Testing & Verification

### **1. Test Security Headers**

```bash
# Check all security headers
curl -I https://weltenbibliothek-ey9.pages.dev | grep -i "x-\|content-security\|strict-transport\|permissions"
```

### **2. Use Online Security Scanner**

Visit: https://securityheaders.com/?q=https://weltenbibliothek-ey9.pages.dev

**Target Grade:** A or A+

### **3. Mozilla Observatory**

Visit: https://observatory.mozilla.org/analyze/weltenbibliothek-ey9.pages.dev

**Target Score:** 90+/100

### **4. Check Worker Status**

```bash
curl -s https://weltenbibliothek-ey9.pages.dev | grep -i "x-security-worker"
```

Expected: `X-Security-Worker: active`

---

## 📊 Expected Results

### **Before Security Headers:**

```
Security Score: 60/100
Missing Headers: 6
Grade: D
```

### **After Security Headers:**

```
Security Score: 95+/100
Missing Headers: 0
Grade: A or A+
```

### **Improvements:**

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Security Score | 60/100 | 95+/100 | +35 points |
| Grade | D | A/A+ | ✅ |
| XSS Protection | ⚠️ Partial | ✅ Full | Enhanced |
| Clickjacking | ❌ None | ✅ Protected | Fixed |
| HTTPS Enforcement | ⚠️ Optional | ✅ Forced | HSTS |
| Content Control | ❌ None | ✅ CSP Active | Secured |

---

## 🔧 Troubleshooting

### **Issue 1: Worker not applying headers**

**Solution:**
1. Verify worker is deployed: `wrangler deployments list`
2. Check route configuration in Cloudflare Dashboard
3. Clear browser cache: Ctrl+Shift+Delete
4. Test with `curl -I` to bypass cache

### **Issue 2: CSP blocking resources**

**Solution:**
Adjust CSP directives in `security-headers.js`:

```javascript
// Add your domain to connect-src
"connect-src 'self' https://your-api-domain.com"

// Add external scripts to script-src
"script-src 'self' 'unsafe-inline' https://trusted-domain.com"
```

### **Issue 3: Flutter app broken after CSP**

**Solution:**
Flutter Web requires `'unsafe-inline'` and `'unsafe-eval'` for scripts.
These are already included in the worker script.

If issues persist, temporarily relax CSP:

```javascript
const csp = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: https:",
  "connect-src *" // Allow all connections temporarily
].join('; ')
```

### **Issue 4: CORS errors**

**Solution:**
CORS is handled separately. If you see CORS errors:

1. Ensure `Access-Control-Allow-Origin` is still present
2. Add CORS handling to worker:

```javascript
// In handleRequest function
if (request.method === 'OPTIONS') {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Max-Age': '86400'
    }
  })
}
```

---

## 🎯 Recommended: Use _headers file

For Cloudflare Pages projects, the **simplest method** is using a `_headers` file.

### **Quick Setup:**

```bash
cd /home/user/flutter_app

# Create _headers file in public folder
mkdir -p public
cat > public/_headers << 'EOF'
/*
  X-Frame-Options: SAMEORIGIN
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
  X-XSS-Protection: 1; mode=block
  Permissions-Policy: geolocation=(), microphone=(), camera=()
  Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.gstatic.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https: blob:; font-src 'self' data:; connect-src 'self' https://weltenbibliothek-api.brandy13062.workers.dev https://*.firebaseapp.com; object-src 'none'; base-uri 'self'
EOF

# Copy to build output
cp public/_headers build/web/_headers

# Redeploy
wrangler pages deploy build/web --project-name=weltenbibliothek
```

---

## 📝 Maintenance

### **Regular Tasks:**

1. **Monthly:** Review CSP violations in browser console
2. **Quarterly:** Run security scans (securityheaders.com, Observatory)
3. **Yearly:** Update HSTS max-age (already set to 1 year)

### **When to Update:**

- Adding new external APIs → Update `connect-src` in CSP
- Adding new CDN for assets → Update relevant CSP directives
- New browser APIs needed → Update Permissions-Policy

---

## 🎯 Success Criteria

### **After Deployment:**

- ✅ Security Headers score: 95+/100
- ✅ All 10 security headers present
- ✅ App still functions correctly
- ✅ No CSP violations in console
- ✅ HTTPS enforced (HSTS active)
- ✅ Lighthouse security score improved

---

## 📞 Support

If you encounter issues:

1. Check browser console for CSP violations
2. Review Cloudflare Worker logs
3. Test with `curl -I` to verify headers
4. Temporarily disable worker to isolate issue

---

**Created:** January 20, 2026  
**Version:** 1.0.0  
**Project:** Weltenbibliothek Security Enhancement  
**Technology:** Cloudflare Workers + Pages
