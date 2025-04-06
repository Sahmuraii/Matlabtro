classdef BalatroGameLogic < handle
    properties
        game 
        boss_blinds
        round_counter
        future_blinds
    end
    
    methods
        function obj = BalatroGameLogic(game)
            obj.game = game;
            obj.round_counter = 0;
            obj.initialize_blinds();
            obj.generate_future_blinds(3); 
        end
        
        function initialize_blinds(obj)
            obj.game.blinds_pool = {
                struct('name', 'Small Blind', 'dollars', 1, 'mult', 1, 'boss', false, 'description', 'Basic blind'), ...
                struct('name', 'Big Blind', 'dollars', 2, 'mult', 1.5, 'boss', false, 'description', 'Stronger blind'), ...
            };
            obj.boss_blinds = {
                struct('name', 'The Hook', 'dollars', 5, 'mult', 4, 'boss', true, 'description', 'Forces discard of 2 cards'), ...
                struct('name', 'The Fish', 'dollars', 8, 'mult', 5, 'boss', true, 'description', 'All cards must be of same suit'), ...
                struct('name', 'The Ox', 'dollars', 10, 'mult', 6, 'boss', true, 'description', 'No pairs allowed')
            };
        end
        
        function generate_future_blinds(obj, num_blinds)
            obj.future_blinds = {};
            for i = 1:num_blinds
                if i <= 2 && obj.round_counter + i <= 2
                    blind_config = obj.game.blinds_pool{obj.round_counter + i};
                else
                    blind_idx = randi(length(obj.boss_blinds));
                    blind_config = obj.boss_blinds{blind_idx};
                end
                
                fprintf('Creating blind: %s\n', blind_config.name);
                new_blind = Blind(blind_config.name, blind_config.dollars, ...
                                blind_config.mult, blind_config.boss);
                
                if ~isa(new_blind, 'Blind') || isempty(new_blind.name)
                    error('Failed to create valid Blind object');
                end
                
                new_blind.set_config(obj.game.ante_level, obj.game.stake_level);
                
                obj.future_blinds{end+1} = new_blind;
            end
        end
        
        function start_new_round(obj)
            obj.round_counter = obj.round_counter + 1;
            
            if isempty(obj.future_blinds)
                obj.generate_future_blinds(3);
            end
            
            obj.game.current_blind = obj.future_blinds{1};
            obj.future_blinds(1) = [];
            
            obj.game.current_blind.set_config(obj.game.ante_level, obj.game.stake_level);
            
            if length(obj.future_blinds) < 3
                obj.generate_future_blinds(3 - length(obj.future_blinds));
            end
            
            fprintf('\n=== ROUND %d ===\n', obj.round_counter);
            fprintf('Current Blind: %s\n', obj.game.current_blind.name);
            fprintf('Target Score: %d\n', obj.game.current_blind.chips);
            fprintf('Reward: $%d\n\n', obj.game.current_blind.dollars);
        end
        
        function select_blind(obj)
            obj.game.switch_mode('card_play');
            
            obj.game.hands_remaining = 4;
            obj.game.discards_remaining = 3;
            obj.game.selected_cards = [];
            obj.game.cumulative_score = 0;  
            
            obj.game.waiting_for_input = false;
            if isvalid(obj.game.fig_handle)
                uiresume(obj.game.fig_handle);
            end
        end
        
        function skip_blind(obj)
            if ~isempty(obj.future_blinds)
                obj.future_blinds{end+1} = obj.game.current_blind;
                obj.game.current_blind = obj.future_blinds{1};
                obj.future_blinds(1) = [];
                obj.game.score = max(0, obj.game.score - 1);
                fprintf('Skipped blind! Lost $1 (Total: $%d)\n', obj.game.score);
            end
            
            obj.game.switch_mode('card_play');
            
            obj.game.hands_remaining = 4;
            obj.game.discards_remaining = 3;
            obj.game.selected_cards = [];
            
            obj.game.waiting_for_input = false;
            if isvalid(obj.game.fig_handle)
                uiresume(obj.game.fig_handle);
            end
        end
        
        function tag_blind(obj)
            if ~isempty(obj.future_blinds)
                temp = obj.game.current_blind;
                obj.game.current_blind = obj.future_blinds{1};
                obj.future_blinds{1} = temp;
                
                fprintf('Tagged blind! Will face %s next\n', obj.game.current_blind.name);
            end
            
            obj.game.switch_mode('card_play');
            
            obj.game.hands_remaining = 4;
            obj.game.discards_remaining = 3;
            obj.game.selected_cards = [];
            
            obj.game.waiting_for_input = false;
            if isvalid(obj.game.fig_handle)
                uiresume(obj.game.fig_handle);
            end
        end

        function discard_cards(obj, card_indices)
            if obj.game.discards_remaining <= 0
                fprintf('No discards remaining!\n');
                return;
            end
            
            card_indices = unique(card_indices);
            valid_indices = card_indices(card_indices >= 1 & card_indices <= length(obj.game.hand));
            
            if isempty(valid_indices)
                fprintf('No valid cards selected to discard!\n');
                return;
            end
            
            discarded_cards = obj.game.hand(valid_indices);
            obj.game.deck(end+1:end+length(discarded_cards)) = discarded_cards;
            
            obj.game.hand(valid_indices) = [];
            
            for i = 1:length(valid_indices)
                if ~isempty(obj.game.deck)
                    obj.game.hand{end+1} = obj.game.deck{1};
                    obj.game.deck(1) = [];
                end
            end
            
            obj.game.discards_remaining = obj.game.discards_remaining - 1;
            obj.game.selected_cards = [];
            
            obj.game.ui.update_discard_display(valid_indices);
            obj.game.ui.display_hand();
            
            if isempty(obj.game.deck)
                obj.initialize_deck();
            end
        end
        
        function initialize_deck(obj)
            suits = {'Hearts', 'Diamonds', 'Clubs', 'Spades'};
            ranks = {'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'};
            
            obj.game.deck = {};
            for s = 1:length(suits)
                for r = 1:length(ranks)
                    obj.game.deck{end+1} = Card(suits{s}, ranks{r});
                end
            end
            obj.shuffle_deck();
        end
        
        function shuffle_deck(obj)
            obj.game.deck = obj.game.deck(randperm(length(obj.game.deck)));
        end

        function draw_new_hand(obj)
            obj.game.hand = {};
            obj.game.played_cards = {};
            obj.game.selected_cards = [];

            for i = 1:min(8, length(obj.game.deck))
                obj.game.hand{end+1} = obj.game.deck{1};
                obj.game.deck(1) = [];
            end
            
            if isempty(obj.game.deck)
                obj.initialize_deck();
            end
            
            obj.game.ui.display_hand();
        end
        
        function draw_hand(obj, num_cards)
            if nargin < 2 || isempty(num_cards)
                num_cards = 8; 
            end
            
            obj.game.played_cards = {};
            obj.game.selected_cards = [];
            
            if length(obj.game.deck) < num_cards
                obj.initialize_deck();
            end
            
            obj.game.hand = {}; 
            for i = 1:num_cards
                obj.game.hand{end+1} = obj.game.deck{1};
                obj.game.deck(1) = [];
            end
            
            if ~strcmp(obj.game.current_mode, 'card_play')
                obj.game.switch_mode('card_play');
            end
            
            obj.game.ui.display_hand();
        end
    end
end