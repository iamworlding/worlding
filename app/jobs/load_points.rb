class LoadPoints
    @queue = :load_operational_model

    def self.perform
      puts 'I like to sleep'
      sleep 2
    end
end