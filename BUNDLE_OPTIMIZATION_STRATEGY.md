# 📦 BUNDLE OPTIMIZATION STRATEGY

**Project:** Weltenbibliothek Flutter App  
**Current Size:** 52MB  
**Target Size:** <15MB (realistic), <10MB (ideal)  
**Date:** January 20, 2026

---

## 📊 CURRENT BUNDLE BREAKDOWN

### **Total Size: 52MB**

| Category | Size | % of Total | Priority |
|----------|------|------------|----------|
| **CanvasKit (Flutter Engine)** | 26MB | 50% | ⚠️ Required |
| **Videos** | 12.6MB | 24% | 🔴 HIGH |
| **main.dart.js** | 5.4MB | 10% | 🟡 MEDIUM |
| **Images** | 1.8MB | 3.5% | 🟢 LOW |
| **Other Assets** | 6.2MB | 12.5% | 🟢 LOW |

---

## 🎯 OPTIMIZATION TARGETS

### **Phase 1: Video Optimization (HIGH PRIORITY)**

**Problem:** 12.6MB of video files in bundle

**Solution Options:**

**Option A: Remove Videos from Bundle (RECOMMENDED)**
- Move videos to external hosting (Cloudflare R2)
- Load videos on-demand
- **Savings:** -12.6MB (24% reduction)
- **Impact:** Bundle: 52MB → 39.4MB

**Option B: Optimize Video Files**
- Re-encode at lower bitrate
- Reduce resolution (720p → 480p)
- Use WebM format instead of MP4
- **Savings:** -8-10MB (16-20% reduction)

**Option C: Lazy Load Videos**
- Don't include in initial bundle
- Load when needed
- **Savings:** -12.6MB from initial load

**🎯 RECOMMENDED: Option A + Option C**

---

### **Phase 2: Code Splitting (MEDIUM PRIORITY)**

**Problem:** 5.4MB main.dart.js (single bundle)

**Solutions:**

**1. Deferred Loading for Routes**
```dart
// Instead of:
import 'package:app/screens/detail_screen.dart';

// Use:
import 'package:app/screens/detail_screen.dart' deferred as detail;

// Load when needed:
await detail.loadLibrary();
```

**Expected Savings:** -1-2MB (18-36% of main.dart.js)

**2. Remove Unused Dependencies**
- Analyze pubspec.yaml
- Remove unused packages
- **Expected Savings:** -0.5-1MB

**3. Tree Shaking Optimization**
- Enable aggressive tree shaking
- Remove debug code
- **Expected Savings:** -0.5-1MB

---

### **Phase 3: Asset Optimization (LOW PRIORITY)**

**Problem:** 1.8MB intro image

**Solutions:**

**1. Image Optimization**
- Convert PNG to WebP
- Compress images
- Use responsive images
- **Expected Savings:** -1-1.2MB (66% reduction)

**2. Font Subsetting**
- Include only used glyphs
- Remove unused font files
- **Expected Savings:** -0.2-0.5MB

---

## 📋 IMPLEMENTATION PLAN

### **Step 1: Video Externalization (Immediate Impact)**

**Actions:**
1. Upload videos to Cloudflare R2
2. Update video references to use CDN URLs
3. Implement lazy loading for videos
4. Remove videos from assets folder

**Files to Modify:**
- `pubspec.yaml` (remove video assets)
- Video player widgets (use network URLs)
- Asset loading logic

**Expected Result:**
- Bundle: 52MB → 39.4MB (-24%)
- Initial Load: Much faster
- Videos load on-demand

---

### **Step 2: Code Splitting Implementation**

**Actions:**
1. Identify large screens/features
2. Implement deferred imports
3. Add loading indicators
4. Test lazy loading

**Screens to Split:**
- Detail screens (Wissensbereiche)
- Settings screens
- Profile screens
- Admin features (if any)

**Expected Result:**
- main.dart.js: 5.4MB → 3.5-4MB (-25-35%)
- Faster initial load
- Progressive enhancement

---

### **Step 3: Dependency Cleanup**

**Actions:**
1. Run `flutter pub deps`
2. Identify unused packages
3. Remove from pubspec.yaml
4. Run `flutter pub get`
5. Rebuild

**Expected Result:**
- Cleaner dependencies
- Smaller bundle
- Faster builds

---

### **Step 4: Image Optimization**

**Actions:**
1. Convert PNG to WebP
2. Compress images (80% quality)
3. Generate responsive sizes
4. Update image references

**Tools:**
- `cwebp` (WebP conversion)
- ImageMagick (batch processing)
- Online tools (squoosh.app)

**Expected Result:**
- Images: 1.8MB → 0.6-0.8MB (-66%)

---

## 🎯 EXPECTED RESULTS

### **After All Optimizations:**

| Item | Before | After | Savings |
|------|--------|-------|---------|
| **Videos** | 12.6MB | 0MB | -12.6MB |
| **main.dart.js** | 5.4MB | 3.5MB | -1.9MB |
| **Images** | 1.8MB | 0.6MB | -1.2MB |
| **Dependencies** | - | - | -0.5MB |
| **Total Bundle** | 52MB | ~24MB | -28MB (54%) |
| **CanvasKit** | 26MB | 26MB | 0 (required) |

### **Realistic Target: 24-26MB total**
- CanvasKit: 26MB (required for Flutter Web)
- App Code: 3.5MB (optimized)
- Assets: 1MB (optimized)
- Other: 1-2MB

**Note:** CanvasKit (26MB) is required for Flutter Web rendering and cannot be reduced.

---

## ⚡ QUICK WINS (Implement First)

### **1. Remove Videos from Bundle**

**Edit pubspec.yaml:**
```yaml
# Remove these lines:
# - assets/videos/weltenbibliothek_intro.mp4
# - assets/videos/transition_energie_to_materie.mp4
# - assets/videos/transition_materie_to_energie.mp4
```

**Update video player widgets:**
```dart
// Instead of:
VideoPlayerController.asset('assets/videos/intro.mp4')

// Use:
VideoPlayerController.network('https://your-cdn.com/videos/intro.mp4')
```

**Savings:** -12.6MB immediately

---

### **2. Convert Images to WebP**

**Command:**
```bash
# Convert PNG to WebP (80% quality)
for img in assets/images/*.png; do
  cwebp -q 80 "$img" -o "${img%.png}.webp"
done
```

**Update Flutter code:**
```dart
// Instead of:
Image.asset('assets/images/intro.png')

// Use:
Image.asset('assets/images/intro.webp')
```

**Savings:** -1.2MB

---

### **3. Enable Aggressive Tree Shaking**

**Build command:**
```bash
flutter build web --release --tree-shake-icons
```

**Savings:** -0.5MB

---

## 🚀 PERFORMANCE IMPACT

### **Before Optimization:**
- Bundle: 52MB
- Load Time: ~3-5s (slow connection)
- Lighthouse Performance: 90/100

### **After Optimization:**
- Bundle: ~24MB (-54%)
- Load Time: ~1-2s
- Lighthouse Performance: 95-100/100 ⭐

---

## 📝 IMPLEMENTATION PRIORITY

### **🔴 HIGH PRIORITY (Do First):**
1. ✅ Remove videos from bundle
2. ✅ Upload videos to CDN
3. ✅ Update video references

### **🟡 MEDIUM PRIORITY (Do Next):**
4. ✅ Implement code splitting
5. ✅ Remove unused dependencies
6. ✅ Enable tree shaking

### **🟢 LOW PRIORITY (Nice to Have):**
7. ✅ Convert images to WebP
8. ✅ Compress remaining assets
9. ✅ Font subsetting

---

## 🎯 SUCCESS CRITERIA

### **Minimum Goals:**
- ✅ Bundle < 30MB (-42%)
- ✅ main.dart.js < 4MB (-26%)
- ✅ Videos externalized
- ✅ Lighthouse Performance: 92+ → 95+

### **Stretch Goals:**
- ✅ Bundle < 25MB (-52%)
- ✅ main.dart.js < 3.5MB (-35%)
- ✅ Images < 1MB
- ✅ Lighthouse Performance: 95-100

---

## ⚠️ IMPORTANT NOTES

### **CanvasKit Size:**
- **Cannot be reduced** (Flutter Web requirement)
- 26MB is normal for Flutter Web apps
- Alternative: Use HTML renderer (loses quality)
- **Recommendation:** Keep CanvasKit, optimize everything else

### **Trade-offs:**
- Videos on CDN: Requires network connection
- Code splitting: Slightly more complex code
- Image optimization: Minor quality loss (barely noticeable)

---

**Created:** January 20, 2026  
**Author:** AI Development Assistant  
**Project:** Weltenbibliothek Bundle Optimization
