const EmailTemplates = {
  verifyEmail: ({ username, verificationLink }) => `
    <h1>Hello ${username}!</h1>
    <p>Thank you for signing up. Please verify your email by clicking the link below:</p>
    <a href="${verificationLink}">Verify Email</a>
    <p>If you didn't request this, ignore this email.</p>
  `,

  forgotPassword: ({ username, resetLink }) => `
    <h1>Hi ${username},</h1>
    <p>We received a request to reset your password. Click the link below to reset it:</p>
    <a href="${resetLink}">Reset Password</a>
    <p>If you didn't request this, ignore this email.</p>
  `,
};

module.exports = EmailTemplates;


// exports.getPasswordResetTemplate = (userName, resetURL) => {
//   return `
// <div style="font-family: Arial, sans-serif; max-width: 600px; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
//   <h2 style="color: #212121;">Password Reset Request</h2>
//   <p>Hello ${userName},</p>
//   <p>We received a request to reset your password. Click the button below to proceed:</p>
//   <p style="margin: 30px 0;">
//     <a href="${resetURL}" style="background-color: #007bff; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">
//       Reset Password
//     </a>
//   </p>
//   <p style="color: #666; font-size: 14px;">This link will expire in 1 hour.</p>
//   <p style="color: #666; font-size: 14px;">If you didn't request this, please ignore this email.</p>
//   <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
//   <p style="color: #888; font-size: 12px;">© ${new Date().getFullYear()} Temheed Team</p>
// </div>`;
// };

// exports.getWelcomeTemplate = (userName, travellerCode) => {
//   return `
// <div style="font-family: Arial, sans-serif; max-width: 600px; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
//   <h2 style="color: #212121;">Welcome to Temheed!</h2>
//   <p>Hello ${userName},</p>
//   <p>Thank you for signing up! We are excited to have you on board.</p>
//   <p>Your unique Traveller Code is:</p>

//   <div style="margin: 30px 0; text-align: center;">
//     <span style="display: inline-block; background-color: #f4f4f4; padding: 15px 25px; font-size: 24px; letter-spacing: 2px; font-weight: bold; border-radius: 8px; color: #007bff;">
//       ${travellerCode}
//     </span>
//   </div>

//   <p style="color: #666; font-size: 14px;">Use this code at the time of log in</p>

//   <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
//   <p style="color: #888; font-size: 12px;">© ${new Date().getFullYear()} Temheed Team</p>
// </div>`;
// };

// exports.getForgotPasswordOTPTemplate = (userName, otp) => {
//   return `
// <div style="font-family: Arial, sans-serif; max-width: 600px; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
//   <h2 style="color: #212121;">Password Reset OTP</h2>
//   <p>Hello ${userName},</p>
//   <p>We received a request to reset your password. Use the One-Time Password (OTP) below to continue:</p>

//   <div style="margin: 30px 0; text-align: center;">
//     <span style="display: inline-block; background-color: #f4f4f4; padding: 15px 25px; font-size: 24px; letter-spacing: 8px; font-weight: bold; border-radius: 8px;">
//       ${otp}
//     </span>
//   </div>

//   <p style="color: #666; font-size: 14px;"><strong>This OTP is valid for 10 minutes.</strong></p>
//   <p style="color: #666; font-size: 14px;">For security reasons, do not share this code with anyone.</p>
//   <p style="color: #666; font-size: 14px;">If you didn't request a password reset, you can safely ignore this email.</p>

//   <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
//   <p style="color: #888; font-size: 12px;">© ${new Date().getFullYear()} Temheed Team</p>
// </div>`;
// };

// exports.getChangeEmailOTPTemplate = (userName, otp) => {
//   return `
// <div style="font-family: Arial, sans-serif; max-width: 600px; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
//   <h2 style="color: #212121;">Email Change Verification</h2>
//   <p>Hello ${userName},</p>
//   <p>We received a request to change your email address. Use the One-Time Password (OTP) below to verify this new email:</p>

//   <div style="margin: 30px 0; text-align: center;">
//     <span style="display: inline-block; background-color: #f4f4f4; padding: 15px 25px; font-size: 24px; letter-spacing: 8px; font-weight: bold; border-radius: 8px;">
//       ${otp}
//     </span>
//   </div>

//   <p style="color: #666; font-size: 14px;"><strong>This OTP is valid for 10 minutes.</strong></p>
//   <p style="color: #666; font-size: 14px;">For security reasons, do not share this code with anyone.</p>
//   <p style="color: #666; font-size: 14px;">If you didn't request this change, you can safely ignore this email.</p>

//   <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
//   <p style="color: #888; font-size: 12px;">© ${new Date().getFullYear()} Temheed Team</p>
// </div>`;
// };

