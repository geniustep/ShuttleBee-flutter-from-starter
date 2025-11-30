# 🗺️ Mapbox Setup Guide for ShuttleBee

## ⚠️ Important: You need to configure your Mapbox Access Token

The ShuttleBee app uses Mapbox for maps functionality. To run the app, you **must** provide a valid Mapbox access token.

---

## 📝 Step-by-Step Setup

### Step 1: Get a Mapbox Access Token

1. **Create a Mapbox account** (if you don't have one):
   - Go to: https://account.mapbox.com/auth/signup/
   - Sign up for a free account

2. **Get your access token**:
   - After signing in, go to: https://account.mapbox.com/access-tokens/
   - Copy your **Default Public Token** (it starts with `pk.`)
   - Or create a new token with the following scopes:
     - ✅ `styles:read`
     - ✅ `fonts:read`
     - ✅ `downloads:read`

### Step 2: Configure the Token for Android

Open the file: `android/app/src/main/res/values/strings.xml`

Replace `YOUR_MAPBOX_ACCESS_TOKEN_HERE` with your actual token:

```xml
<string name="mapbox_access_token" translatable="false">pk.YOUR_ACTUAL_TOKEN_HERE</string>
```

**Example:**
```xml
<string name="mapbox_access_token" translatable="false">pk.eyJ1Ijoiam9obmRvZSIsImEiOiJjazZ2...</string>
```

### Step 3: Configure the Token for iOS (if needed)

If you plan to run on iOS, you also need to add the token to iOS:

1. Open `ios/Runner/Info.plist`
2. Add the following before the last `</dict>`:

```xml
<key>MBXAccessToken</key>
<string>YOUR_MAPBOX_ACCESS_TOKEN_HERE</string>
```

---

## 🔒 Security Best Practices

### Option 1: Using strings.xml (Current Setup) ✅
- ✅ Simple and works out of the box
- ⚠️ Token is included in the app (but this is fine for public tokens)
- Mapbox public tokens (starting with `pk.`) are **designed** to be included in apps

### Option 2: Using .env file (Alternative)
If you prefer to use environment variables:

1. Create a `.env` file in the project root:
```env
MAPBOX_ACCESS_TOKEN=pk.your_token_here
```

2. Add `.env` to `.gitignore` (already done)

3. The app loads this automatically via `flutter_dotenv` in `bootstrap.dart`

---

## 💰 Pricing Information

Mapbox offers a **generous free tier**:
- ✅ **50,000 Monthly Active Users (MAU)** - FREE
- ✅ Unlimited map loads
- ✅ Unlimited API calls within MAU limit

**After free tier:**
- $5 per 1,000 additional MAU

For a school bus tracking app, the free tier should be sufficient for most cases.

---

## ✅ Verification

After setting up the token:

1. **Clean and rebuild** the app:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Run on Android**:
   ```bash
   flutter run
   ```

3. **Check for errors**: 
   - If you see `MapboxConfigurationException`, the token is not configured correctly
   - If the map loads successfully, you're all set! ✨

---

## 🆘 Troubleshooting

### Error: "MapboxConfigurationException: Using MapView... requires providing a valid access token"

**Solution:** 
- Make sure you replaced `YOUR_MAPBOX_ACCESS_TOKEN_HERE` in `strings.xml` with your actual token
- The token should start with `pk.`
- Run `flutter clean` and rebuild

### Error: "Failed assertion... RenderBox was not laid out"

**This is related to the Mapbox token issue.** Once you configure the token correctly, this error will be resolved.

### Map shows but is blank or has errors

**Solution:**
- Check that your token has the correct scopes (see Step 1)
- Verify your internet connection
- Check Mapbox status: https://status.mapbox.com/

---

## 📚 Additional Resources

- **Mapbox Flutter SDK Documentation**: https://docs.mapbox.com/flutter/
- **Mapbox Access Tokens Guide**: https://docs.mapbox.com/help/getting-started/access-tokens/
- **ShuttleBee Maps Integration Guide**: See `MAPS_INTEGRATION_GUIDE.md` in this project

---

## 🎯 Quick Reference

**Files to modify:**
1. ✅ `android/app/src/main/res/values/strings.xml` - Add your Mapbox token here
2. (Optional) `ios/Runner/Info.plist` - For iOS support
3. (Optional) `.env` - If using environment variables

**Token format:** `pk.eyJ1IjoiZXhhbXBsZSIsImEiOiJja...` (starts with `pk.`)

**Where to get token:** https://account.mapbox.com/access-tokens/

---

**Good luck with ShuttleBee! 🚌✨**

