class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :login_imap

  # GET /messages or /messages.json
  def index
    @mailboxes = @imap.list("", "*").map{|mbox| mbox.name}

    @selected_mailbox = params[:mailbox] || "INBOX"
    @imap.select(@selected_mailbox)

    @messages = []
    @imap.search(['ALL']).each do |message_id|
      @messages << @imap.fetch(message_id, 'ALL')[0]
    end

    @imap.logout
    @imap.disconnect
  end

  # GET /messages/1 or /messages/1.json
  def show
    @imap.select(params[:mailbox])
    message_id = @imap.search(['HEADER', 'Message-ID', Base64.decode64(params[:msgid])])[0]
    @message = @imap.fetch(message_id, 'ALL')
    message_rfc822 = @imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
    part = 0 || params[:part].to_i
    @message_contents = Mail.read_from_string(message_rfc822).part[part].body.to_s.gsub("\n", "<br>").gsub("<script", "&#60;script").gsub("</script>", "&#60;/script>")

    @imap.logout
    @imap.disconnect
  end

  # GET /messages/new
  def new
    @message = Message.new
  end

  # POST /messages or /messages.json
  def create
    @message = Message.new(message_params.except(:content_type))
    @message.user = current_user
    @message.from = "#{current_user.name} <#{current_user.email}>"

    message_data = {
      subject: message_params[:subject],
      body: message_params[:body]
    }

    content_types = {
      "Text" => "text/plain",
      "HTML" => "text/html"
    }

    content_type = content_types[message_params[:content_type]]

    email=UserMessagesMailer.send_message(@message.from, message_params[:to], message_data, content_type: content_type)

    respond_to do |format|
      if email.deliver
        @imap.append("Sent", email.to_s, [:Seen])
        @imap.logout
        @imap.disconnect

        format.html { redirect_to message_url(@message), notice: "Message sent" }
        format.json { render :show, status: :created, location: @message }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def login_imap
      @imap = Net::IMAP.new('mail.bluemail.pro', 993, true, nil, false)
      @imap.login(session[:imapuser], session[:imappass])
    end
    # Only allow a list of trusted parameters through.
    def message_params
      params.require(:message).permit(:to, :subject, :body, :content_type)
    end
end
