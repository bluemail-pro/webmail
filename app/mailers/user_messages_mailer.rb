class UserMessagesMailer < ApplicationMailer
  def test(recipient)
    mail(
      to: 'matthias@matthiasclee.com',
      from: 'matthias@bluemail.pro',
      subject: 'asd',
      body: 'hi'
    )
  end
end
