# Cloudflare API Configuration

## Environment Variables

### CLOUDFLARE_API_TOKEN
**Required**: Yes  
**Purpose**: Authentication token for Cloudflare API access  
**Security Level**: CRITICAL - Do NOT commit this value

### Setup Instructions

#### Development Build
```bash
flutter run --dart-define=CLOUDFLARE_API_TOKEN=your_token_here
```

#### Release Build (APK)
```bash
flutter build apk --release --dart-define=CLOUDFLARE_API_TOKEN=your_token_here
```

#### Release Build (Web)
```bash
flutter build web --release --dart-define=CLOUDFLARE_API_TOKEN=your_token_here
```

### CI/CD Integration
Add the token as a secret environment variable in your CI/CD pipeline:
- GitHub Actions: Repository Settings → Secrets → CLOUDFLARE_API_TOKEN
- GitLab CI: Settings → CI/CD → Variables → CLOUDFLARE_API_TOKEN
- Jenkins: Credentials → Secret text → CLOUDFLARE_API_TOKEN

### Security Best Practices
1. ✅ NEVER commit the actual token to git
2. ✅ Use different tokens for dev/staging/production
3. ✅ Rotate tokens regularly (every 90 days)
4. ✅ Limit token permissions to minimum required scope
5. ✅ Monitor token usage in Cloudflare Dashboard

### Obtaining a Token
1. Go to Cloudflare Dashboard
2. Navigate to: Profile → API Tokens
3. Create Token → Custom Token
4. Set permissions:
   - D1 Database: Edit
   - Workers: Edit
   - R2 Storage: Edit
5. Copy token and store securely

### Troubleshooting
**Error**: "API Token is empty"  
**Solution**: Ensure you're passing --dart-define=CLOUDFLARE_API_TOKEN when building

**Error**: "Unauthorized (401)"  
**Solution**: Verify token is correct and has required permissions

**Error**: "Token expired"  
**Solution**: Generate a new token and update environment variable

---

**Last Updated**: 2026-01-20  
**Security Level**: CRITICAL
