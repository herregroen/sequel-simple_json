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
        def json_associations *assocs
          assocs.each do |assoc|
            if assoc.respond_to?(:to_sym) and assoc = assoc.to_sym and self.associations.include?(assoc)
              _json_assocs << assoc
            end
          end
        end
        def _json_props
          @json_props ||= []
        end
        def _json_assocs
          @json_assocs ||= []
        end
      end
      module DatasetMethods
        def to_json opts={}
          ds = self
          self.model._json_assocs.each do |assoc|
            r = ds.model.association_reflection(assoc)
            m = r[:class_name].split('::').inject(Object) {|o,c| o.const_get c}
            s = [m.primary_key]
            s.push(r[:key])  if r[:key] and m.columns.include?(r[:key])
            ds = ds.eager_graph(assoc => proc{|ads| ads.select(*s) })
          end
          if self.model._json_props.any?
            s  = self.model._json_props
            s << self.model.primary_key unless s.include?(self.model.primary_key)
            ds = ds.select{s.map{|c|`#{ds.model.table_name}.#{c}`}}
          else
            ds = ds.select{`#{ds.model.table_name}.*`}
          end
          g = (s || self.columns).map{|c| "#{ds.model.table_name}.#{c}"}
          self.model._json_assocs.each do |assoc|
            r = ds.model.association_reflection(assoc)
            m = r[:class_name].split('::').inject(Object) {|o,c| o.const_get c}
            if r[:cartesian_product_number] == 0
              ds = ds.select_append{`\"#{assoc}\".\"#{m.primary_key}\"`.as(assoc)}
              g << "\"#{assoc}\".\"#{m.primary_key}\""
            else
              ds = ds.select_append{array_agg(`\"#{assoc}\".\"#{m.primary_key}\"`).as(assoc)}
            end
          end
          ds = ds.group{g.map{|c| `#{c}`}}
          ds.map(&:values).to_json
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
