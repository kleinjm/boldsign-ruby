module Boldsign
  # Converts arbitrary Ruby hash keys (snake_case, camelCase, or PascalCase;
  # Symbol or String) to camelCase string keys recursively, matching the
  # casing the BoldSign REST API expects in request bodies. Non-Hash and
  # non-Array values — including binary IO objects, FilePart instances,
  # scalars, dates, etc. — pass through untouched.
  module CaseConvert
    module_function

    # Recursively camelCase every Hash key reachable from `obj`.
    # @param obj [Object]
    # @return [Object] new object with the same shape and camelCase keys
    def camelize(obj)
      case obj
      when Hash
        obj.each_with_object({}) { |(k, v), acc| acc[camelize_key(k)] = camelize(v) }
      when Array
        obj.map { |v| camelize(v) }
      else
        obj
      end
    end

    # @param key [String, Symbol]
    # @return [String] camelCase string
    def camelize_key(key)
      str = key.to_s
      return str if str.empty?

      if str.include?("_")
        parts = str.split("_").reject(&:empty?)
        return str if parts.empty?

        ([parts.first.downcase] + parts.drop(1).map { |part| capitalize_word(part) }).join
      else
        lowercase_first(str)
      end
    end

    def capitalize_word(str)
      return str if str.empty?

      str[0].upcase + str[1..]
    end

    def lowercase_first(str)
      return str if str.empty?

      str[0].downcase + str[1..]
    end
  end
end
