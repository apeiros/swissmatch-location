    class ZipCodeEnumerator < Enumerator
      def active
        return ZipCodeEnumerator.new(self, __method__) unless block_given?
        now = Time.now
        each do |zip_code|
          yield(zip_code) if zip_code.valid_from.nil? || zip_code.valid_from <= now
        end
      end
    end

    def self.each(&block)
      block_given? ? @all.each(&Proc.new) : ZipCodeEnumerator.new(@all, __method__)
    end
