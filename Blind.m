classdef Blind < handle
    properties
        name
        dollars
        chips
        mult
        disabled
        boss
        config
        is_small_blind
        is_big_blind
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
            
            obj.is_small_blind = false;
            obj.is_big_blind = false;
            
            if strcmp(name, 'Small Blind')
                obj.is_small_blind = true;
            elseif strcmp(name, 'Big Blind')
                obj.is_big_blind = true;
            end
            
            obj.update_chips();
        end
        
        function update_chips(obj)
            if ~isfield(obj.config, 'ante_level') || ~isfield(obj.config, 'stake_level')
                return; 
            end
            
            base_chips = [300, 800, 2000, 5000, 11000, 20000, 35000, 50000];
            ante = min(obj.config.ante_level, length(base_chips));
            
            if obj.is_small_blind
                base_requirement = base_chips(ante);
            elseif obj.is_big_blind
                base_requirement = base_chips(ante) * 1.5;
            else 
                base_requirement = base_chips(ante) * obj.mult;
            end
            
            stake_mult = [1, 1.5, 2, 2.5, 3]; 
            stake = min(obj.config.stake_level, length(stake_mult));
            obj.chips = round(base_requirement * stake_mult(stake));
            
            if stake >= 2 && obj.is_small_blind 
                obj.dollars = 0;
            end
        end
        
        function set_config(obj, ante_level, stake_level)
            obj.config.ante_level = ante_level;
            obj.config.stake_level = stake_level;
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