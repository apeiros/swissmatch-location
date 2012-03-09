# encoding: utf-8



module SwissMatch

  # Represents a swiss address. Used by directory service interfaces to return search
  # results.
  Address = Struct.new(:gender, :first_name, :last_name, :street_name, :street_number, :zip_code, :city) do
    def street
      [street_name,street_number].compact.join(" ")
    end
  end
end
