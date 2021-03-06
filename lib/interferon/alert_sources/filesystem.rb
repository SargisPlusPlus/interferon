# frozen_string_literal: true

include ::Interferon::Logging

module Interferon::AlertSources
  class Filesystem
    def initialize(options)
      alert_types = options['alert_types']
      raise ArgumentError, 'missing alert_types for loading alerts from filesystem' \
        unless alert_types

      alert_types.each do |alert_type|
        raise ArgumentError, '"missing path for loading alerts from filesystem' \
          unless alert_type['path']
        alert_type['extension'] ||= '*.rb'
        alert_type['class'] ||= 'Alert'
      end

      @alert_types = alert_types
    end

    def list_alerts
      alerts = []
      failed = 0

      @alert_types.each do |alert_type|
        # validate that alerts path exists
        alert_type_count = 0
        path = File.expand_path(alert_type['path'])
        log.warn("No such directory #{path} for reading alert files") unless Dir.exist?(path)

        alert_class = Interferon.const_get(alert_type['class'])
        Dir.glob(File.join(path, alert_type['extension'])).each do |alert_file|
          break if @request_shutdown
          begin
            alert = alert_class.new(path, alert_file)
          rescue StandardError => e
            log.warn("Error reading alert file #{alert_file}: #{e}")
            failed += 1
          else
            alert_type_count += 1
            alerts << alert
          end
        end

        log.info("Read #{alert_type_count} alerts files from #{path}")
      end

      { alerts: alerts, failed: failed }
    end
  end
end
