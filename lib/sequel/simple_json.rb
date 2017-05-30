require "sequel/simple_json/version"

module Sequel
  module Plugins
    module SimpleJson
      module ClassMethods
        Sequel::Plugins.inherited_instance_variables self, :@json_props => :dup, :@json_assocs => :dup
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
          if self.model._json_props.any?
            s  = self.model._json_props
            s << self.model.primary_key unless s.include?(self.model.primary_key)
            ds = ds.select{s.map{|c|`#{ds.model.table_name}.#{c}`}}
          else
            ds = ds.select{`#{ds.model.table_name}.*`}
          end
          if self.model._json_assocs.any?
            g = (s || self.columns).map{|c| "#{ds.model.table_name}.#{c}"}
            self.model._json_assocs.each do |assoc|
              r = ds.model.association_reflection(assoc)
              m = r[:class_name].split('::').inject(Object) {|o,c| o.const_get c}
              ds = ds.association_left_join(assoc)
              if r[:cartesian_product_number] == 0
                ds = ds.select_append{`\"#{assoc}\".\"#{m.primary_key}\"`.as(assoc)}
                g << "\"#{assoc}\".\"#{m.primary_key}\""
              else
                ds = ds.select_append{array_agg(`DISTINCT \"#{assoc}\".\"#{m.primary_key}\"`).as(assoc)}
              end
            end
            ds = ds.group{g.map{|c| `#{c}`}}
          end
          json = self.model.db[ds.sql].all.to_json
          return json ? json.gsub(/\[null(\,\s?null)*\]/,'[]') : '[]'
        end
      end
      module InstanceMethods
        def to_json opts={}
          vals = self.values
          vals = vals.select { |k| self.class._json_props.include?(k) }  if self.class._json_props.any?
          self.class._json_assocs.each do |assoc|
            obj = send(assoc)
            if obj.nil?
              vals[assoc] = nil
            else
              vals[assoc] = obj.is_a?(Array) ? obj.map{|m| m[m.primary_key]} : obj[obj.primary_key]
            end
          end
          vals.to_json
        end
      end
    end
  end
end
