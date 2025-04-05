classdef Blind < handle
    properties
        name
        dollars
        chips
        mult
        disabled
        boss
        config
    end
    
    methods
        function obj = Blind(name, dollars, mult, isBoss)
            obj.name = name;
            obj.dollars = dollars;
            obj.mult = mult;
            obj.boss = isBoss;
            obj.disabled = false;
            obj.chips = 0;
            obj.config = struct();
            obj.update_chips();
        end
        
        function update_chips(obj)
            ante = 1;
            ante_scaling = 1;
            obj.chips = round(ante * obj.mult * ante_scaling);
        end
        
        function set_blind(obj, blind_config)
            obj.config = blind_config;
            if isfield(blind_config, 'mult')
                obj.mult = blind_config.mult;
            end
            obj.update_chips();
        end
        
        function disable(obj)
            obj.disabled = true;
        end
        
        function defeat(obj)
            obj.dollars = 0;
            obj.chips = 0;
            obj.disabled = true;
        end
    end
end
