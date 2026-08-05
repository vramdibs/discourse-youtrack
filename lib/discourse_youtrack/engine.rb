# frozen_string_literal: true

module ::DiscourseYoutrack
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseYoutrack
  end
end
