classdef BalatroGameLogic < handle
    properties
        game 
        boss_blinds
        round_counter
    end
    
    methods
        function obj = BalatroGameLogic(game)
            obj.game = game;
            obj.round_counter = 0;
            obj.initialize_blinds();
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
        
        function draw_hand(obj, num_cards)
            obj.game.played_cards = {};
            obj.game.selected_cards = [];
            if length(obj.game.deck) < num_cards
                obj.initialize_deck();
            end
            obj.game.hand = obj.game.deck(1:num_cards);
            obj.game.deck(1:num_cards) = [];
            obj.game.ui.display_hand();
        end
        
        function start_new_round(obj)
            obj.round_counter = obj.round_counter + 1;
            
            if obj.round_counter <= 2
                blind_config = obj.game.blinds_pool{obj.round_counter};
            else
                blind_idx = randi(length(obj.boss_blinds));
                blind_config = obj.boss_blinds{blind_idx};
            end
            
            obj.game.current_blind = Blind(blind_config.name, blind_config.dollars, ...
                                        blind_config.mult, blind_config.boss);
            obj.game.current_blind.set_blind(blind_config);
            
            obj.game.ui.create_game_window();
            
            if isvalid(obj.game.ax_handles(2))
                CardGraphics.display_blind(obj.game.current_blind, obj.game.ax_handles(2));
            end
            
            fprintf('\n=== ROUND %d ===\n', obj.round_counter);
            fprintf('Current Blind: %s\n', obj.game.current_blind.name);
            fprintf('Target Score: %d\n', obj.game.current_blind.chips);
            fprintf('Reward: %d$\n\n', obj.game.current_blind.dollars);
        end
        
        function select_cards(obj, card_indices)
            if length(card_indices) > 5
                error('Cannot select more than 5 cards');
            end
            obj.game.played_cards = obj.game.hand(card_indices);
            obj.game.hand(card_indices) = [];
            obj.game.hands_remaining = obj.game.hands_remaining - 1;
            obj.game.ui.display_hand(); 
        end

        function discard_cards(obj, card_indices)
            if obj.game.discards_remaining <= 0
                error('No discards remaining');
            end
            if ~isempty(card_indices)
                obj.game.deck = [obj.game.deck, obj.game.hand(card_indices)];
                obj.game.hand(card_indices) = [];
            end
            obj.game.logic.shuffle_deck();
        end
    end
end