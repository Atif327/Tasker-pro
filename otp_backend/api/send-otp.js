import nodemailer from 'nodemailer';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';

const required = (name) => {
  const v = process.env[name];
  if (!v) throw new Error(`Missing environment variable: ${name}`);
  return v;
};

const EMAIL_FROM = () => required('EMAIL_FROM');
const JWT_SECRET = () => required('OTP_JWT_SECRET');

function createTransport() {
  // Generic SMTP (works with Gmail app password, Mailgun SMTP, etc.)
  const host = required('SMTP_HOST');
  const port = parseInt(required('SMTP_PORT'), 10);
  const user = required('SMTP_USER');
  const pass = required('SMTP_PASS');

  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
  });
}

function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function otpHash(email, otp) {
  return crypto
    .createHmac('sha256', JWT_SECRET())
    .update(`${email}:${otp}`)
    .digest('hex');
}

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  try {
    const { email } = req.body || {};
    if (!email || typeof email !== 'string') {
      return res.status(400).json({ error: 'Email is required' });
    }

    const otp = generateOTP();
    const hash = otpHash(email, otp);

    // 5-minute signed token (stateless, no DB required)
    const token = jwt.sign({ email, hash }, JWT_SECRET(), { expiresIn: '5m' });

    const transporter = createTransport();
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px; }
          .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 10px; padding: 30px; }
          .header { text-align: center; color: #2196F3; }
          .otp-box { background: #E3F2FD; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0; }
          .otp-code { font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #1976D2; }
          .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1 class="header">📋 Tasker Pro</h1>
          <h2>Email Verification</h2>
          <p>Please use the following verification code to complete your registration:</p>
          <div class="otp-box">
            <div class="otp-code">${otp}</div>
          </div>
          <p><strong>This code will expire in 5 minutes.</strong></p>
          <div class="footer">
            <p>This is an automated message, please do not reply.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    await transporter.sendMail({
      from: EMAIL_FROM(),
      to: email,
      subject: 'Your Tasker Pro verification code',
      html,
    });

    return res.status(200).json({ success: true, token });
  } catch (err) {
    console.error('send-otp error:', err);
    return res.status(500).json({ 
      success: false, 
      error: 'Failed to send OTP',
      details: err.message,
      code: err.code
    });
  }
}
