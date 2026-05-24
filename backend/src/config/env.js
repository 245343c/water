/**
 * Central environment configuration.
 *
 * APP_ENV=local     → disk uploads, OTP in API response (dev)
 * APP_ENV=production → GCP uploads + SMS OTP (never expose OTP in JSON)
 */
const APP_ENV = (process.env.APP_ENV || process.env.NODE_ENV || 'development').toLowerCase();
const isProduction = APP_ENV === 'production' || APP_ENV === 'prod';

const storageMode = (process.env.STORAGE_MODE || (isProduction ? 'gcp' : 'local')).toLowerCase();

const otpMode = (process.env.OTP_MODE || (isProduction ? 'sms' : 'local')).toLowerCase();

module.exports = {
  appEnv: isProduction ? 'production' : 'local',
  isProduction,
  storageMode, // 'local' | 'gcp'
  otpMode, // 'local' | 'sms' | 'email'
  publicBaseUrl: process.env.PUBLIC_BASE_URL || '',
  gcs: {
    bucket: process.env.GCS_BUCKET || '',
    projectId: process.env.GCP_PROJECT_ID || '',
  },
  sms: {
    provider: process.env.SMS_PROVIDER || 'twilio', // twilio | msg91
    twilioAccountSid: process.env.TWILIO_ACCOUNT_SID || '',
    twilioAuthToken: process.env.TWILIO_AUTH_TOKEN || '',
    twilioFrom: process.env.TWILIO_FROM_NUMBER || '',
    msg91AuthKey: process.env.MSG91_AUTH_KEY || '',
    msg91SenderId: process.env.MSG91_SENDER_ID || 'SRSAI',
  },
  email: {
    from: process.env.EMAIL_FROM || 'noreply@srisai.com',
    // Plug SendGrid/SES in dispatchEmail when needed
  },
  jwtSecret: process.env.JWT_SECRET || '',
  customerDemoOtp: process.env.CUSTOMER_DEMO_OTP || '123456',
};
