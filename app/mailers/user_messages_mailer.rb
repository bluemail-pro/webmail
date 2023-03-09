class UserMessagesMailer < ApplicationMailer
  def send_message(sender, recipient, message)
    mail(
      to: recipient,
      from: sender,
      subject: message[:subject],
      body: message[:body]
    )
  end
end
