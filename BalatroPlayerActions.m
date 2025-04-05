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
            
            obj.game.logic.select_cards(obj.game.selected_cards);
            obj.game.evaluator.play_hand();
            
            if isvalid(obj.game.fig_handle) && obj.game.waiting_for_input
                obj.game.waiting_for_input = false;
                uiresume(obj.game.fig_handle);
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
            
            obj.game.logic.discard_cards(obj.game.selected_cards);
            obj.game.discards_remaining = obj.game.discards_remaining - 1;
            obj.game.logic.draw_hand(8); 
            
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