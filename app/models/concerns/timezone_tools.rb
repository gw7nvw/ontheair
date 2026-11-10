module TimezoneTools
  extend ActiveSupport::Concern

    def parse_local_time(time_string, timezone_name)
      return nil if time_string.blank?

      tz = TZInfo::Timezone.get(timezone_name)
      parsed = DateTime.strptime(time_string, "%Y-%m-%d %H:%M")
      
      tz.local_datetime(
        parsed.year, parsed.month, parsed.day, 
        parsed.hour, parsed.min, parsed.sec
      )
    end
end
