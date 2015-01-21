class SpamMailer < ApplicationMailer
  def introduction()
    mail(to: 'quinn@qutek.net', subject: 'Test')
  end
end
