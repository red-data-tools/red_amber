# frozen_string_literal: true

module RedAmber
  # Mix-in for class Vector
  #   Methods for string-like related function
  module VectorStringFunction
    using RefineArray
    using RefineArrayLike

    # For each string in self, emit true if it contains a given pattern.
    #
    # @overload match_substring(string, ignore_case: nil)
    #   Emit true if it contains `string`.
    #
    #   @param string [String]
    #     string pattern to match.
    #   @param ignore_case [boolean]
    #     switch whether to ignore case. Ignore case if true.
    #   @return [Vector]
    #     boolean Vector to show if elements contain a given pattern.
    #     nil inputs emit nil.
    #   @example Match with string.
    #     vector = Vector.new('array', 'Arrow', 'carrot', nil, 'window')
    #     vector.match_substring('arr')
    #     # =>
    #     #<RedAmber::Vector(:boolean, size=5):0x000000000005a208>
    #     [true, false, true, nil, false]
    #
    # @overload match_substring(regexp, ignore_case: nil)
    #   Emit true if it contains substring matching with `regexp`.
    #   It calls `match_substring_regex` in Arrow compute function and
    #   uses re2 library.
    #
    #   @param regexp [Regexp]
    #     regular expression pattern to match. Ruby's Regexp is given and
    #     it will passed to Arrow's kernel by its source.
    #   @param ignore_case [boolean]
    #     switch whether to ignore case. Ignore case if true.
    #     When `ignore_case` is false, casefolding option in regexp is priortized.
    #   @return [Vector]
    #     boolean Vector to show if elements contain a given pattern.
    #     nil inputs emit nil.
    #   @example Match with regexp.
    #     vector.match_substring(/arr/)
    #     # =>
    #     #<RedAmber::Vector(:boolean, size=5):0x0000000000014b68>
    #     [true, false, true, nil, false]
    #
    # @since 0.5.0
    #
    def match_substring(pattern, ignore_case: nil)
      options = Arrow::MatchSubstringOptions.new
      datum =
        case pattern
        when String
          options.ignore_case = (ignore_case || false)
          options.pattern = pattern
          find(:match_substring).execute([data], options)
        when Regexp
          options.ignore_case = (pattern.casefold? || ignore_case || false)
          options.pattern = pattern.source
          find(:match_substring_regex).execute([data], options)
        else
          message =
            "pattern must be either String or Regexp: #{pattern.inspect}"
          raise VectorArgumentError, message
        end
      Vector.create(datum.value)
    end
    alias_method :match_substring?, :match_substring

    # Check if elements in self end with a literal pattern.
    #
    # @param string [String]
    #   string pattern to match.
    # @param ignore_case [boolean]
    #   switch whether to ignore case. Ignore case if true.
    # @return [Vector]
    #   boolean Vector to show if elements end with a given pattern.
    #   nil inputs emit nil.
    # @example Check if end with?.
    #   vector = Vector.new('array', 'Arrow', 'carrot', nil, 'window')
    #   vector.end_with('ow')
    #   # =>
    #   #<RedAmber::Vector(:boolean, size=5):0x00000000000108ec>
    #   [false, true, false, nil, true]
    # @since 0.5.0
    #
    def end_with(string, ignore_case: nil)
      options = Arrow::MatchSubstringOptions.new
      options.ignore_case = (ignore_case || false)
      options.pattern = string
      datum = find(:ends_with).execute([data], options)
      Vector.create(datum.value)
    end
    alias_method :end_with?, :end_with

    # Check if elements in self start with a literal pattern.
    #
    # @param string [String]
    #   string pattern to match.
    # @param ignore_case [boolean]
    #   switch whether to ignore case. Ignore case if true.
    # @return [Vector]
    #   boolean Vector to show if elements start with a given pattern.
    #   nil inputs emit nil.
    # @example Check if start with?.
    #   vector = Vector.new('array', 'Arrow', 'carrot', nil, 'window')
    #   vector.start_with('arr')
    #   # =>
    #   #<RedAmber::Vector(:boolean, size=5):0x00000000000193fc>
    #   [true, false, false, nil, false]
    # @since 0.5.0
    #
    def start_with(string, ignore_case: nil)
      options = Arrow::MatchSubstringOptions.new
      options.ignore_case = (ignore_case || false)
      options.pattern = string
      datum = find(:starts_with).execute([data], options)
      Vector.create(datum.value)
    end
    alias_method :start_with?, :start_with

    # Match elements of self against SQL-style LIKE pattern.
    #   The pattern matches a given pattern at any position.
    #   '%' will match any number of characters,
    #   '_' will match exactly one character,
    #   and any other character matches itself.
    #   To match a literal '%', '_', or '\', precede the character with a backslash.
    #
    # @param string [String]
    #   string pattern to match.
    # @param ignore_case [boolean]
    #   switch whether to ignore case. Ignore case if true.
    # @return [Vector]
    #   boolean Vector to show if elements start with a given pattern.
    #   nil inputs emit nil.
    # @example Check with match_like?.
    #   vector = Vector.new('array', 'Arrow', 'carrot', nil, 'window')
    #   vector.match_like('_rr%')
    #   # =>
    # @since 0.5.0
    #
    def match_like(string, ignore_case: nil)
      options = Arrow::MatchSubstringOptions.new
      options.ignore_case = (ignore_case || false)
      options.pattern = string
      datum = find(:match_like).execute([data], options)
      Vector.create(datum.value)
    end
    alias_method :match_like?, :match_like

    # For each string in self, count occuerences of substring in given pattern.
    #
    # @overload count_substring(string, ignore_case: nil)
    #   Count if it contains `string`.
    #
    #   @param string [String]
    #     string pattern to count.
    #   @param ignore_case [boolean]
    #     switch whether to ignore case. Ignore case if true.
    #   @return [Vector]
    #     int32 or int64 Vector to show if elements contain a given pattern.
    #     nil inputs emit nil.
    #   @example Count with string.
    #     vector2 = Vector.new('amber', 'Amazon', 'banana', nil)
    #     vector2.count_substring('an')
    #     # =>
    #     #<RedAmber::Vector(:int32, size=4):0x000000000003db30>
    #     [0, 0, 2, nil]
    #
    # @overload count_substring(regexp, ignore_case: nil)
    #   Count if it contains substring matching with `regexp`.
    #   It calls `count_substring_regex` in Arrow compute function and
    #   uses re2 library.
    #
    #   @param regexp [Regexp]
    #     regular expression pattern to count. Ruby's Regexp is given and
    #     it will passed to Arrow's kernel by its source.
    #   @param ignore_case [boolean]
    #     switch whether to ignore case. Ignore case if true.
    #     When `ignore_case` is false, casefolding option in regexp is priortized.
    #   @return [Vector]
    #     int32 or int64 Vector to show the counts in given pattern.
    #     nil inputs emit nil.
    #   @example Count with regexp with case ignored.
    #     vector2.count_substring(/a[mn]/i)
    #     # =>
    #     #<RedAmber::Vector(:int32, size=4):0x0000000000051298>
    #     [1, 1, 2, nil]
    #     # it is same result as `vector2.count_substring(/a[mn]/, ignore_case: true)`
    #
    # @since 0.5.0
    #
    def count_substring(pattern, ignore_case: nil)
      options = Arrow::MatchSubstringOptions.new
      datum =
        case pattern
        when String
          options.ignore_case = (ignore_case || false)
          options.pattern = pattern
          find(:count_substring).execute([data], options)
        when Regexp
          options.ignore_case = (pattern.casefold? || ignore_case || false)
          options.pattern = pattern.source
          find(:count_substring_regex).execute([data], options)
        else
          message =
            "pattern must be either String or Regexp: #{pattern.inspect}"
          raise VectorArgumentError, message
        end
      Vector.create(datum.value)
    end

    # Find first occurrence of substring in string Vector.
    #
    # @overload find_substring(string, ignore_case: nil)
    #   Emit the index in bytes of the first occurrence of the given
    #     literal pattern, or -1 if not found.
    #
    #   @param string [String]
    #     string pattern to match.
    #   @param ignore_case [boolean]
    #     switch whether to ignore case. Ignore case if true.
    #   @return [Vector]
    #     index Vector of occurences.
    #     nil inputs emit nil.
    #   @example Match with string.
    #     vector = Vector['array', 'Arrow', 'carrot', nil, 'window']
    #     vector.find_substring('arr')
    #     # =>
    #     #<RedAmber::Vector(:boolean, size=5):0x00000000000161e8>
    #     [0, -1, 1, nil, -1]
    #
    # @overload find_substring(regexp, ignore_case: nil)
    #   Emit the index in bytes of the first occurrence of the given
    #     regexp pattern, or -1 if not found.
    #   It calls `find_substring_regex` in Arrow compute function and
    #   uses re2 library.
    #
    #   @param regexp [Regexp]
    #     regular expression pattern to match. Ruby's Regexp is given and
    #     it will passed to Arrow's kernel by its source.
    #   @param ignore_case [boolean]
    #     switch whether to ignore case. Ignore case if true.
    #     When `ignore_case` is false, casefolding option in regexp is priortized.
    #   @return [Vector]
    #     index Vector of occurences.
    #     nil inputs emit nil.
    #   @example Match with regexp.
    #     vector.find_substring(/arr/i)
    #     # or vector.find_substring(/arr/, ignore_case: true)
    #     # =>
    #     #<RedAmber::Vector(:boolean, size=5):0x000000000001b74c>
    #     [0, 0, 1, nil, -1]
    #
    # @since 0.5.1
    #
    def find_substring(pattern, ignore_case: nil)
      options = Arrow::MatchSubstringOptions.new
      datum =
        case pattern
        when String
          options.ignore_case = (ignore_case || false)
          options.pattern = pattern
          find(:find_substring).execute([data], options)
        when Regexp
          options.ignore_case = (pattern.casefold? || ignore_case || false)
          options.pattern = pattern.source
          find(:find_substring_regex).execute([data], options)
        else
          message =
            "pattern must be either String or Regexp: #{pattern.inspect}"
          raise VectorArgumentError, message
        end
      Vector.create(datum.value)
    end
  end
end
