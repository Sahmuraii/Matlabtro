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
            
            num_cards = length(obj.game.played_cards);
            ranks = cellfun(@(c) c.rank, obj.game.played_cards, 'UniformOutput', false);
            suits = cellfun(@(c) c.suit, obj.game.played_cards, 'UniformOutput', false);
            values = cellfun(@(c) c.value, obj.game.played_cards);
            
            unique_suits = unique(suits);
            unique_ranks = unique(ranks);
            num_suits = length(unique_suits);
            counts = histcounts(categorical(ranks), categorical(unique_ranks));
            
            if num_cards == 5
                if any(counts == 5)
                    hand_type = 'Five of a Kind';
                elseif num_suits == 1 && ...
                       ismember('A', ranks) && ismember('K', ranks) && ...
                       ismember('Q', ranks) && ismember('J', ranks) && ismember('10', ranks)
                    hand_type = 'Royal Flush';
                elseif num_suits == 1 && ...
                       (max(values) - min(values) == 4 || ...  
                       (ismember('A', ranks) && ismember('2', ranks) && ...  
                       ismember('3', ranks) && ismember('4', ranks) && ismember('5', ranks)))
                    hand_type = 'Straight Flush';
                elseif num_suits == 1 && any(counts == 5)
                    hand_type = 'Flush Five';
                elseif num_suits == 1 && any(counts == 3) && any(counts == 2)
                    hand_type = 'Flush House';
                elseif any(counts == 4)
                    hand_type = 'Four of a Kind';
                elseif any(counts == 3) && any(counts == 2)
                    hand_type = 'Full House';
                elseif num_suits == 1
                    hand_type = 'Flush';
                elseif (max(values) - min(values) == 4 || ...  
                       (ismember('A', ranks) && ismember('2', ranks) && ...  
                       ismember('3', ranks) && ismember('4', ranks) && ismember('5', ranks)))
                    hand_type = 'Straight';
                end
            end
            
            if ~exist('hand_type', 'var') 
                if any(counts == 5)
                    hand_type = 'Five of a Kind';
                elseif any(counts == 4)
                    hand_type = 'Four of a Kind';
                elseif any(counts == 3) && any(counts == 2)
                    hand_type = 'Full House';
                elseif any(counts == 3)
                    hand_type = 'Three of a Kind';
                elseif sum(counts == 2) == 2
                    hand_type = 'Two Pair';
                elseif any(counts == 2)
                    hand_type = 'Pair';
                else
                    hand_type = 'High Card';
                end
            end
            
            switch hand_type
                case 'Royal Flush', base_score = 100; base_mult = 8;
                case 'Straight Flush', base_score = 100; base_mult = 8;
                case 'Five of a Kind', base_score = 120; base_mult = 12;
                case 'Flush Five', base_score = 80; base_mult = 8;
                case 'Four of a Kind', base_score = 60; base_mult = 7;
                case 'Flush House', base_score = 50; base_mult = 5;
                case 'Full House', base_score = 40; base_mult = 4;
                case 'Flush', base_score = 35; base_mult = 4;
                case 'Straight', base_score = 30; base_mult = 4;
                case 'Three of a Kind', base_score = 30; base_mult = 3;
                case 'Two Pair', base_score = 20; base_mult = 2;
                case 'Pair', base_score = 10; base_mult = 2;
                case 'High Card', base_score = 5; base_mult = 1;
            end
            
            hand_score = round((base_score + sum(values)) * base_mult);
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
            
            obj.game.cumulative_score = obj.game.cumulative_score + hand_score;
            fprintf('Total Score So Far: %d\n', obj.game.cumulative_score);
            
            if obj.game.cumulative_score >= obj.game.current_blind.chips
                obj.game.score = obj.game.score + obj.game.current_blind.dollars;
                fprintf('SUCCESS! Defeated %s\n', obj.game.current_blind.name);
                obj.game.current_blind.defeat();
            else
                fprintf('Need %d more points\n\n', ...
                    obj.game.current_blind.chips - obj.game.cumulative_score);
            end
            
            obj.game.waiting_for_input = false;
            if isvalid(obj.game.fig_handle)
                uiresume(obj.game.fig_handle);
            end
        end
    end
end