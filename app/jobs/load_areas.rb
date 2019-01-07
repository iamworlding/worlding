class LoadAreas

    @queue = :load_operational_model

    def self.perform(name, state, country, language, initial_latitude, final_latitude, initial_longitude, final_longitude)
            
        puts ""
        puts "  --- Start executing LoadAreas Job => " + Time.new.inspect + " ---"
        puts ""
        puts "      >> Area name: " + name
        puts "      >> Language: " + language
        puts ""

        puts "      || ETL execution ||"

        # Log starting
        OperationalLog.create(source: "jobs/load_areas", event: "load_operational_model - starting job", 
                    comment: "Name: " + name + 
                    " | Language: " + language + 
                    " | Max Latitude: " + initial_latitude.to_s + 
                    " | Min Latitude: " + final_latitude.to_s + 
                    " | Max Longitude: " + initial_longitude.to_s + 
                    " | Min Latitude: " + final_longitude.to_s
                        )

        puts "      --> Load: Create Area and AreaDetail"
        loadData(name, state, country, language, initial_latitude, final_latitude, initial_longitude, final_longitude)

        # Log ending
        OperationalLog.create(source: "jobs/load_areas", event: "load_operational_model - ending job") 

        puts ""
        puts "  --- End executing LoadAreas Job => " + Time.new.inspect + " ---"
        puts ""
        
    end

    def self.loadData(name, state, country, language, initial_latitude, final_latitude, initial_longitude, final_longitude)
        
        # TODO: switch with languages
        area = Area.create(
            initial_latitude: initial_latitude,
            final_latitude: final_latitude,
            initial_longitude: initial_longitude,
            final_longitude: final_longitude, 
            es: true,
            en: false
        )

        # TOOD: request to Nominatim
        AreaDetail.create(
            areas_id: area.id,
            name: name,
            state: state,
            country: country,
            language: language
        )   

    end
    
end