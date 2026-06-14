# Security Documentation

## Multi-Factor Authentication (MFA / 2FA) – Highest Priority
Relying solely on an email and password is a major security vulnerability for business accounts. BizEase must implement Multi-Factor Authentication (MFA), also known as Two-Factor Authentication (2FA), to protect business owners from unauthorized access.

### What it is: 
MFA requires the business owner to provide a second piece of evidence (a one-time code) in addition to their password when logging in.

### How it works in BizEase:

1. The business owner logs in using their email and password.
2. If MFA is not yet set up, the owner is prompted to enable it.
3. During setup, the owner registers their email address to receive verification codes.
4. On every subsequent login, after entering the correct password, a unique one-time code is sent to the owner's registered email address.
5. The owner must enter this code to complete the login process.

### Why this matters: 
Even if a hacker steals the business owner's password, they cannot access the account without also having access to the owner's email inbox. This adds a critical layer of security for all business accounts on BizEase.

### Implementation approach: 
Firebase Authentication natively supports MFA. BizEase can implement email-based OTP (one-time password) verification, which is simple, secure, and does not require phone numbers. For enhanced security, TOTP apps like Google Authenticator can also be supported in the future.
