require "sequel/simple_json/version"

module Sequel
  module Plugins
    module SimpleJson
      module ClassMethods
        def to_json opts={}
          self.dataset.to_json opts
        end
        def json_properties *props
          props.each do |prop|
            if prop.respond_to?(:to_sym) and prop = prop.to_sym and self.columns.include?(prop)
              _json_props << prop
            end
          end
        end
        def _json_props
          @json_props ||= []
        end
      end
      module DatasetMethods
        def to_json opts={}
          if self.model._json_props.any?
            self.select(*self.model._json_props).map(&:values).to_json
          else
            self.map(&:values).to_json
          end
        end
      end
      module InstanceMethods
        def to_json opts={}
          (self.class._json_props.any? ? self.values.select { |k| self.class._json_props.include?(k) } : self.values).to_json
        end
      end
    end
  end
end
