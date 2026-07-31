# Stock Market Monitoring App - Authentication System

## Overview
This document describes the Firebase authentication system for the Stock Market Monitoring App. The app now includes a complete authentication flow with login, sign-up, email verification, and guest access.

## Architecture

### Components

#### 1. **AuthService** (`Services/auth_service.dart`)
The core service handling all Firebase authentication operations:
- `signUpWithEmail()` - Creates a new user account and sends verification email
- `signInWithEmail()` - Authenticates user with email/password
- `signOut()` - Logs out current user
- `sendPasswordResetEmail()` - Sends password reset link
- Error handling with user-friendly messages

#### 2. **Login Page** (`UI/pages/auth/login_page.dart`)
Features:
- Email input field
- Password input field with show/hide toggle (checkbox)
- "Login" button with loading state
- "Continue as Guest" button (for future guest access)
- Link to Sign-up page
- Error message display
- Material Design UI with dark theme

#### 3. **Sign-up Page** (`UI/pages/auth/signup_page.dart`)
Features:
- Email input field
- Password input field with show/hide toggle
- Confirm password field with separate show/hide toggle
- Sign-up button with loading state
- Back arrow to return to Login page
- Password validation (min 6 characters, matching passwords)
- Success state showing verification email instructions
- Error handling with validation messages

#### 4. **Email Verification Page** (`UI/pages/auth/email_verification_page.dart`)
Features:
- Displays verification status
- Auto-checks email verification every 3 seconds
- "Resend Verification Email" button
- "Back to Login" button
- Automatic navigation to home after successful verification

#### 5. **Authentication Wrapper** (in `main.dart`)
Manages authentication state using `FirebaseAuth.authStateChanges()` stream:
- Shows loading spinner while checking auth state
- Displays Login page if no user is logged in
- Shows Email Verification page if email is not verified
- Shows Home screen (AppShell) if fully authenticated

## User Flow

### Sign-up Flow
```
Sign-up Page → Create Account → Email Verification Page → Check Email → 
Click Link in Email → Verified → Home Screen
```

### Login Flow
```
Login Page → Enter Credentials → (if not verified) Email Verification Page → 
(if verified) Home Screen
```

### Guest Flow
```
Login Page → Click "Continue as Guest" → Guest Home Screen (to be implemented)
```

## Security Features

1. **Password Validation**: Minimum 6 characters required
2. **Email Verification**: Users must verify email before accessing full features
3. **Error Handling**: User-friendly error messages without exposing sensitive data
4. **Secure Auth State**: Uses Firebase's secure session management
5. **Password Visibility**: Optional password visibility with clear toggle UI

## UI/UX Highlights

- **Dark Theme**: Consistent with app's financial dashboard aesthetic
- **Clear Typography**: Monospace-ready for financial data
- **Loading States**: Visual feedback during authentication operations
- **Error Messages**: Red containers with clear, actionable messages
- **Success Feedback**: Green containers confirming successful actions
- **Responsive Design**: Works on various screen sizes with proper scrolling

## Configuration

### Firebase Setup Required
Ensure your Firebase project has:
1. Email/Password authentication enabled in Firebase Console
2. SMTP configured for email verification
3. Email template customization (optional)

### Routes Available
- `/login` - Login page
- `/signup` - Sign-up page
- `/verify-email` - Email verification page
- `/home` - Main app (AppShell)

## Integration Notes

### For Guest Mode
The "Continue as Guest" button currently shows a placeholder. To implement:
1. Create a guest authentication handler
2. Pass guest flag through navigation
3. Conditionally restrict features based on guest status

### For Password Reset
Email verification page and auth service support password reset. To implement:
1. Add "Forgot Password?" link to login page
2. Create password reset page with email input
3. Create password reset confirmation page with new password fields

## Code Examples

### Using AuthService in Your Pages
```dart
final authService = AuthService();

// Sign up
await authService.signUpWithEmail(
  email: email,
  password: password,
);

// Sign in
await authService.signInWithEmail(
  email: email,
  password: password,
);

// Sign out
await authService.signOut();
```

### Checking User Authentication in Widgets
```dart
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final user = snapshot.data!;
      return Text('Logged in as: ${user.email}');
    }
    return Text('Not logged in');
  },
)
```

## Future Enhancements

1. **Social Sign-in**: Google, Apple, GitHub authentication
2. **Multi-factor Authentication**: SMS or TOTP
3. **Password Reset Flow**: Complete forgot password experience
4. **Guest Features**: Limited access mode for guest users
5. **Account Recovery**: Phone number backup for account recovery
6. **Biometric Auth**: Fingerprint/Face ID authentication

## Testing

### Manual Testing Checklist
- [ ] Create new account with valid email
- [ ] Verify email verification email is sent
- [ ] Click verification link and confirm access to home
- [ ] Login with existing verified account
- [ ] Try login with wrong password (error handling)
- [ ] Try sign-up with existing email (error handling)
- [ ] Test password visibility toggle
- [ ] Test confirm password validation
- [ ] Resend verification email
- [ ] Test guest mode button (when implemented)

## Troubleshooting

### "Operation not allowed" Error
- Check Firebase Console → Authentication → Sign-in method
- Ensure Email/Password is enabled

### Verification Email Not Received
- Check spam folder
- Resend using "Resend Verification Email" button
- Check Firebase SMTP configuration

### Session Persists After Sign-out
- Clear app cache
- Ensure `signOut()` is called on logout button

---

**Last Updated**: July 2026
