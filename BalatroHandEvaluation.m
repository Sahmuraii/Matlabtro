classdef BalatroHandEvaluation < handle
    properties
        game
    end
    
    methods
        function obj = BalatroHandEvaluation(game)
            obj.game = game;
        end
        
        function [hand_type, hand_score] = evaluate_hand(obj)
            if isempty(obj.game.played_cards)
                error('No cards played');
            end
            
            ranks = cellfun(@(c) c.rank, obj.game.played_cards, 'UniformOutput', false);
            suits = cellfun(@(c) c.suit, obj.game.played_cards, 'UniformOutput', false);
            values = cellfun(@(c) c.value, obj.game.played_cards);
            
            unique_suits = unique(suits);
            unique_ranks = unique(ranks);
            num_suits = length(unique_suits);
            num_ranks = length(unique_ranks);
            counts = histcounts(categorical(ranks), categorical(unique_ranks));
            
            if num_suits == 1 && num_ranks == 5
                if ismember('A', ranks) && ismember('K', ranks) && ...
                   ismember('Q', ranks) && ismember('J', ranks) && ismember('10', ranks)
                    hand_type = 'Royal Flush';
                else
                    hand_type = 'Straight Flush';
                end
            elseif any(counts == 4)
                hand_type = 'Four of a Kind';
            elseif any(counts == 3) && any(counts == 2)
                hand_type = 'Full House';
            elseif num_suits == 1
                hand_type = 'Flush';
            elseif num_ranks == 5 && (max(values) - min(values)) == 4
                hand_type = 'Straight';
            elseif any(counts == 3)
                hand_type = 'Three of a Kind';
            elseif sum(counts == 2) == 2
                hand_type = 'Two Pair';
            elseif any(counts == 2)
                hand_type = 'Pair';
            else
                hand_type = 'High Card';
            end
            
            switch hand_type
                case 'Royal Flush', base_score = 100; base_mult = 8;
                case 'Straight Flush', base_score = 100; base_mult = 8;
                case 'Four of a Kind', base_score = 60; base_mult = 7;
                case 'Full House', base_score = 40; base_mult = 4;
                case 'Flush', base_score = 35; base_mult = 4;
                case 'Straight', base_score = 30; base_mult = 4;
                case 'Three of a Kind', base_score = 30; base_mult = 3;
                case 'Two Pair', base_score = 20; base_mult = 2;
                case 'Pair', base_score = 10; base_mult = 2;
                case 'High Card', base_score = 5; base_mult = 1;
            end
            
            hand_score = round(base_score + sum(values) * base_mult);
        end
        
        function play_hand(obj)
            if isempty(obj.game.played_cards)
                error('No cards selected to play');
            end
            
            [hand_type, hand_score] = obj.evaluate_hand();
            
            fprintf('\n=== HAND PLAYED ===\n');
            fprintf('Hand Type: %s\n', hand_type);
            fprintf('Hand Score: %d\n', hand_score);
            fprintf('Blind Target: %d\n', obj.game.current_blind.chips);
            
            if hand_score >= obj.game.current_blind.chips
                obj.game.score = obj.game.score + obj.game.current_blind.dollars;
                fprintf('SUCCESS! Defeated %s\n', obj.game.current_blind.name);
                fprintf('Earned $%d (Total: $%d)\n\n', ...
                       obj.game.current_blind.dollars, obj.game.score);
                obj.game.current_blind.defeat();
                
                if isvalid(obj.game.fig_handle)
                    close(obj.game.fig_handle);
                end
            else
                fprintf('FAILED! Need %d more points\n\n', ...
                       obj.game.current_blind.chips - hand_score);
            end
        end
    end
end