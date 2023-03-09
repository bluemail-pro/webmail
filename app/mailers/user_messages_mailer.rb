class UserMessagesMailer < ApplicationMailer
  def send_message(sender, recipient, message, content_type: "text/plain")
    mail(
      to: recipient,
      from: sender,
      subject: message[:subject],
      body: message[:body],
      content_type: content_type
    )
  end
end
