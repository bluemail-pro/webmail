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
      message = @imap.fetch(message_id, 'ALL')[0]
      @messages << message if !message.attr['FLAGS'].include?(:Deleted)
    end

    @sort = params["sort"] || "date"
    @sort_reverse = params["sort_reverse"] == "true"


    if @sort == "date"
      @messages = @messages.sort_by do
        |m|
        m.attr['INTERNALDATE'].to_datetime
      end
    elsif @sort == "subject"
      @messages = @messages.sort_by do
        |m|
        m.attr['ENVELOPE'].subject.to_s.downcase
      end
    end

    @messages = @messages.reverse if !@sort_reverse
    @messages = @messages.reverse if @sort == "subject"

    @mailboxes = @imap.list("", "*").map {|f| f.name}

    @imap.logout
    @imap.disconnect
  end

  # GET /messages/1 or /messages/1.json
  def show
    @selected_mailbox = params[:mailbox]
    @imap.select(@selected_mailbox)
    message_id = @imap.search(['HEADER', 'Message-ID', Base64.decode64(params[:msgid])])[0]
    @imap_message = @imap.fetch(message_id, 'ALL')
    message_rfc822 = @imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
    @rawmsg = message_rfc822

    @message = Mail.read_from_string(message_rfc822)

    @multipart = @message.multipart?

    if @multipart
      @part_num = params[:part].to_i || 0
      @part = @message.parts[@part_num]
      @parts = @message.parts
      @body = @part.body.to_s
      @content_type = @part.content_type.split("; ")[0] || "text/html"
      @charset = @part.content_type.split("; ")[1] || "utf-8"
    else
      @body = @message.body.to_s
      @content_type = @message.content_type.split("; ")[0] || "text/html"
      @charset = @message.content_type.split("; ")[1] || "utf-8"
    end

    from = @imap_message[0].attr['ENVELOPE'].from[0]

      @reply_text = Base64.strict_encode64("\n\nOn " \
        "#{@imap_message[0].attr['INTERNALDATE'].to_datetime.in_time_zone(ActiveSupport::TimeZone.new("Pacific Time (US & Canada)")).strftime("%a. %b %e, %Y %l:%M %p %Z")} " \
        "#{from.name} <#{from.mailbox}@#{from.host}> wrote:\n#{"<blockquote>" if @content_type == "text/html"}" \
        "#{@body.split("\n").map{|l| "#{"> " if @content_type == "text/plain"}#{l}"}.join("\n")}#{"</blockquote>" if @content_type == "text/html"}"
      )

    @imap.logout
    @imap.disconnect
  end

  # GET /messages/new
  def new
    @to = params[:to]
    @body = Base64.decode64(params[:body]) if params[:body]
    @subject = params[:subject]
    @message = Message.new

    @imap.logout
    @imap.disconnect
  end

  # POST /messages or /messages.json
  def create
    @message = Message.new(message_params.except(:content_type, :bcc))
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

    email=UserMessagesMailer.send_message(@message.from, message_params[:to], message_data, content_type: content_type, bcc: message_params[:bcc])

    respond_to do |format|
      if email.deliver
        @imap.append("Sent", email.to_s, [:Seen])
        @imap.logout
        @imap.disconnect

        format.html { redirect_to messages_path, notice: "Message sent" }
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
      params.require(:message).permit(:to, :bcc, :subject, :body, :content_type)
    end
end
