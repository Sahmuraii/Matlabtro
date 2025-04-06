classdef BalatroPlayerActions < handle
    properties
        game 
    end
    
    methods
        function obj = BalatroPlayerActions(game)
            obj.game = game;
        end
        
        function play_selected_cards(obj)
            if isempty(obj.game.selected_cards)
                fprintf('No cards selected\n');
                return;
            end
            
            valid_indices = obj.game.selected_cards(obj.game.selected_cards <= length(obj.game.hand));
            if isempty(valid_indices)
                fprintf('No valid cards selected\n');
                return;
            end
            
            obj.game.played_cards = obj.game.hand(valid_indices);
            
            obj.game.hand(valid_indices) = [];
            
            for i = 1:length(valid_indices)
                if ~isempty(obj.game.deck)
                    obj.game.hand{end+1} = obj.game.deck{1};
                    obj.game.deck(1) = [];
                end
            end
            
            obj.game.selected_cards = [];
            
            obj.game.hands_remaining = obj.game.hands_remaining - 1;
            
            obj.game.evaluator.play_hand();
            
            obj.game.ui.display_hand();
            
            if isempty(obj.game.deck)
                obj.game.logic.initialize_deck();
            end
        end
        
        function discard_selected(obj)
            if isempty(obj.game.selected_cards)
                fprintf('No cards selected\n');
                return;
            end
            
            if obj.game.discards_remaining <= 0
                fprintf('No discards remaining\n');
                return;
            end
            
            valid_indices = obj.game.selected_cards(obj.game.selected_cards <= length(obj.game.hand));
            if ~isempty(valid_indices)
                obj.game.logic.discard_cards(valid_indices);
                
                obj.game.selected_cards = [];
                obj.game.ui.highlight_selected();
            end
            
            if isvalid(obj.game.fig_handle) && obj.game.waiting_for_input
                obj.game.waiting_for_input = false;
                uiresume(obj.game.fig_handle);
            end
        end
        
        function clear_selection(obj)
            obj.game.selected_cards = [];
            obj.game.ui.highlight_selected();
        end
    end
end