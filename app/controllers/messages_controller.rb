class MessagesController < ApplicationController
  before_action :set_message, only: %i[ show edit update destroy ]
  before_action :authenticate_user!

  # GET /messages or /messages.json
  def index
    @messages = Message.all
  end

  # GET /messages/1 or /messages/1.json
  def show
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
        imap = Net::IMAP.new('mail.bluemail.pro', 993, true, nil, false)
        imap.login(session[:imapuser], session[:imappass])
        imap.append("Sent", email.to_s, [:Seen])
        imap.logout
        imap.disconnect

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
    def set_message
      @message = Message.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def message_params
      params.require(:message).permit(:to, :subject, :body, :content_type)
    end
end
