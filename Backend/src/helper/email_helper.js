const axios = require("axios");

/**
 * Send an email using EmailJS API
 *
 * IMPORTANT: In your EmailJS dashboard -> Email Templates -> Content:
 * Make sure your email body looks exactly like this to render the HTML properly:
 * {{{message}}}  
 */
exports.sendMail = async function (mailOptions) {
  const data = {
    service_id: process.env.EMAILJS_SERVICE_ID,
    template_id: process.env.EMAILJS_TEMPLATE_ID,
    user_id: process.env.EMAILJS_USER_ID,
    accessToken: process.env.EMAILJS_ACCESS_TOKEN,
    template_params: {
      to_email: mailOptions.to,
      from_name: "Anon Chat",
      subject: mailOptions.subject,
      message: mailOptions.html,      
      message_html: mailOptions.html, 
    },
  };

  try {
    const response = await axios.post(
      "https://api.emailjs.com/api/v1.0/email/send",
      data
    );
    return response.data;
  } catch (error) {
    console.error(
      "EmailJS Error:",
      error.response ? error.response.data : error.message
    );
    throw error;
  }
};
