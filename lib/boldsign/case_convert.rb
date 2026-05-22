module Boldsign
  # Converts arbitrary Ruby hash keys (snake_case or camelCase, Symbol or
  # String) to PascalCase string keys recursively, matching the casing the
  # BoldSign REST API expects in request bodies. Non-Hash and non-Array values
  # — including binary IO objects, FilePart instances, scalars, dates, etc. —
  # pass through untouched.
  module CaseConvert
    module_function

    # Recursively PascalCase every Hash key reachable from `obj`.
    # @param obj [Object]
    # @return [Object] new object with the same shape and PascalCase keys
    def pascalize(obj)
      case obj
      when Hash
        obj.each_with_object({}) { |(k, v), acc| acc[pascalize_key(k)] = pascalize(v) }
      when Array
        obj.map { |v| pascalize(v) }
      else
        obj
      end
    end

    # @param key [String, Symbol]
    # @return [String] PascalCase string
    def pascalize_key(key)
      str = key.to_s
      return str if str.empty?

      if str.include?("_")
        str.split("_").map { |part| capitalize_word(part) }.join
      else
        capitalize_word(str)
      end
    end

    def capitalize_word(str)
      return str if str.empty?

      str[0].upcase + str[1..]
    end
  end
end
