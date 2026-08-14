# Security Policy - RoomMate Match

## Reporting Security Vulnerabilities

We take the security of RoomMatematch seriously. If you discover a security vulnerability, please report it responsibly.

### How to Report

**Email:** security@roommatematch.com

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Proof of concept (if applicable)

### Response Time

We aim to respond within **48 hours** and provide regular updates on the remediation progress.

### Disclosure Policy

We follow responsible disclosure:
- Confirm the vulnerability
- Develop and test a fix
- Deploy the fix
- Public disclosure after fix is deployed

## Security Features

### Authentication & Authorization
- **Firebase Authentication:** OAuth 2.0, Google Sign-In, Apple Sign-In
- **Two-Factor Authentication:** SMS verification
- **Session Management:** Secure token handling
- **Role-Based Access Control:** User permissions

### Data Protection
- **Encryption:** AES-256 for data at rest
- **TLS 1.3:** Encryption in transit
- **Hashed Passwords:** bcrypt with salt
- **PII Protection:** Minimal data collection

### API Security
- **Rate Limiting:** Request throttling
- **Input Validation:** Strict type checking
- **SQL Injection Prevention:** Parameterized queries
- **XSS Protection:** Content sanitization
- **CSRF Protection:** Token validation

### Network Security
- **HTTPS Only:** Enforced SSL/TLS
- **CORS Policy:** Restricted origins
- **API Key Management:** Secure storage
- **WebSocket Security:** WSS with authentication

### Mobile Security
- **Code Obfuscation:** ProGuard/R8
- **Root/Jailbreak Detection:** Device integrity checks
- **Certificate Pinning:** SSL certificate validation
- **Secure Storage:** Encrypted local storage

## Security Best Practices

### Development
- Regular security audits
- Code review process
- Dependency scanning
- Static analysis (SAST)
- Dynamic analysis (DAST)

### Deployment
- CI/CD security gates
- Automated security testing
- Container scanning
- Infrastructure as Code security
- Secrets management

### Operations
- Log monitoring and alerting
- Intrusion detection system
- Regular backups
- Incident response plan
- Security training

## Compliance

### GDPR Compliance
- Data minimization
- Right to be forgotten
- Data portability
- Consent management
- Data breach notification

### CCPA Compliance
- Do not sell my personal information
- Data disclosure transparency
- Opt-out mechanisms
- Data deletion rights

### Payment Security
- PCI DSS compliance
- Secure payment processing
- Tokenization
- Fraud detection

## Known Security Considerations

### Third-Party Dependencies
We use the following third-party services:
- **Firebase:** Google Cloud Platform security
- **Socket.io:** WebSocket security
- **Stripe:** Payment processing security
- **Google Maps:** Location data security

### Data Retention
- User data: 30 days after account deletion
- Chat logs: 90 days (encrypted)
- Analytics data: 2 years (anonymized)
- Payment data: 7 years (legal requirement)

## Security Updates

### Patch Management
- Critical vulnerabilities: Within 24 hours
- High severity: Within 72 hours
- Medium severity: Within 1 week
- Low severity: Next release

### Notification
Users will be notified of security updates via:
- In-app notifications
- Email alerts
- Security bulletins

## Security Team

For security-related inquiries:
- **Email:** security@roommatematch.com
- **Contact:** Victor Garcia Caballero
- **Phone:** +34 616 438 869
- **Address:** Carrer Llunas, Barcelona, España
- **PGP Key:** [Available on request]

## Acknowledgments

We thank security researchers who help us keep RoomMate Match secure.

---

Last updated: July 2026
