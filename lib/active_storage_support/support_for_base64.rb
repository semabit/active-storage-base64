require 'active_support/concern'
require 'active_storage/attached'

module ActiveStorageSupport
  module SupportForBase64
    extend ActiveSupport::Concern
    class_methods do
      def has_one_base64_attached(name, dependent: :purge_later)
        has_one_attached name, dependent: dependent

        add_helper_method(ActiveStorageSupport::Base64One, name)
      end

      def has_many_base64_attached(name, dependent: :purge_later)
        has_many_attached name, dependent: dependent

        add_helper_method(ActiveStorageSupport::Base64Many, name)
      end

      def add_helper_method(type, name)
        class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}
            @active_storage_attached_#{name} ||=
              #{type}.new("#{name}", self)
          end

          def #{name}=(attachable)
            return if attachable.is_a?(Hash) && attachable.blank?
            attachment_changes["#{name}"] =
              if attachable.nil? || (attachable.is_a?(Hash) && attachable.symbolize_keys.fetch(:remove, false))
                ActiveStorage::Attached::Changes::DeleteOne.new("#{name}", self)
              else
                ActiveStorage::Attached::Changes::CreateOne.new("#{name}", self, ActiveStorageSupport::Base64Attach.attachment_from_data(attachable))
              end
          end
        CODE
      end
    end
  end
end
