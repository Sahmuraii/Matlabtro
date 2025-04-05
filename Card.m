classdef Card < handle
    properties
        suit
        rank
        value
    end
    
    methods
        function obj = Card(suit, rank)
            obj.suit = suit;
            obj.rank = rank;
            obj.value = obj.calculate_value();
        end
        
        function val = calculate_value(obj)
            switch obj.rank
                case 'A', val = 11;
                case {'K','Q','J'}, val = 10;
                otherwise, val = str2double(obj.rank);
            end
        end
    end
end