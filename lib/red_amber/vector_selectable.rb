# frozen_string_literal: true

# Available functions in Arrow are shown by `Arrow::Function.all.map(&:name)`
# reference: https://arrow.apache.org/docs/cpp/compute.html

module RedAmber
  # mix-ins for class Vector
  # Functions to select some data.
  module VectorSelectable
    def drop_nil
      datum = find(:drop_null).execute([data])
      take_out_element_wise(datum)
    end
  end
end
