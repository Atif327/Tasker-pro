import jwt from 'jsonwebtoken';
import crypto from 'crypto';

const required = (name) => {
  const v = process.env[name];
  if (!v) throw new Error(`Missing environment variable: ${name}`);
  return v;
};

const JWT_SECRET = () => required('OTP_JWT_SECRET');

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
    const { email, otp, token } = req.body || {};
    if (!email || !otp || !token) {
      return res.status(400).json({ error: 'Email, OTP, and token are required' });
    }

    let payload;
    try {
      payload = jwt.verify(token, JWT_SECRET()); // verifies signature and expiry
    } catch (e) {
      return res.status(400).json({ success: false, error: 'OTP expired or invalid token' });
    }

    if (payload.email !== email) {
      return res.status(400).json({ success: false, error: 'Invalid email' });
    }

    const expected = payload.hash;
    const actual = otpHash(email, otp);

    if (expected !== actual) {
      return res.status(400).json({ success: false, error: 'Invalid OTP' });
    }

    return res.status(200).json({ success: true, message: 'OTP verified successfully' });
  } catch (err) {
    console.error('verify-otp error:', err);
    return res.status(500).json({ success: false, error: 'Verification failed' });
  }
}
