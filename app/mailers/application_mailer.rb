class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM_EMAIL", "no-reply@nucleoforlife.com.br")
  layout "mailer"
end
