# Match the existing WebSocket class names during eager loading.
ActiveSupport::Inflector.inflections(:en) { |inflect| inflect.acronym 'WebSocket' }
