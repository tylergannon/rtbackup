require 'slack-notifier'

module ServerBackups
    class Notifier
        attr_reader :config

        def initialize(config_path)
            @config = Config.new(config_path)
        end

        def notify_success
            return unless config.slack_webhook && config.notify_on_success

            notifier = Slack::Notifier.new config.slack_webhook
            message = "Backups at `#{config.prefix}` succeeded. "
            message += config.slack_mention_on_success.map{|t| "<@#{t}>"}.to_sentence
            notifier.post text: message, icon_emoji: ':100:'
        end

        def notify_failure(errors)
            return unless config.slack_webhook

            notifier = Slack::Notifier.new config.slack_webhook
            message = "Backups at `#{config.prefix}` failed. "
            message += config.slack_mention_on_failure.map{|t| "<@#{t}>"}.to_sentence
            attachments = []
            for error in errors do
                attachments << {text: error.message + "\n" + error.backtrace.join("\n")}
            end
            notifier.post text: message, icon_emoji: ':bomb:', attachments: attachments
        end
    end
end
