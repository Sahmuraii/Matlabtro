classdef BalatroUI < handle
    properties
        game 
    end
    
    methods
        function obj = BalatroUI(game)
            obj.game = game;
        end
        
        function create_game_window(obj)
            if isempty(obj.game.fig_handle) || ~isvalid(obj.game.fig_handle)
                [obj.game.fig_handle, obj.game.ax_handles] = CardGraphics.create_game_window(obj.game);
                obj.create_ui_buttons();
            end
        end
        
        function create_ui_buttons(obj)
            obj.game.ui_controls.play_button = uicontrol(obj.game.fig_handle, ...
                'Style', 'pushbutton', ...
                'String', 'Play Selected Cards', ...
                'Position', [20 20 150 30], ...
                'Callback', @(~,~) obj.game.actions.play_selected_cards());
            
            obj.game.ui_controls.discard_button = uicontrol(obj.game.fig_handle, ...
                'Style', 'pushbutton', ...
                'String', 'Discard Selected', ...
                'Position', [190 20 150 30], ...
                'Callback', @(~,~) obj.game.actions.discard_selected());
            
            obj.game.ui_controls.clear_button = uicontrol(obj.game.fig_handle, ...
                'Style', 'pushbutton', ...
                'String', 'Clear Selection', ...
                'Position', [360 20 150 30], ...
                'Callback', @(~,~) obj.game.actions.clear_selection());
        end
        
        function card_clicked(obj, card_idx)
            if ismember(card_idx, obj.game.selected_cards)
                obj.game.selected_cards(obj.game.selected_cards == card_idx) = [];
            else
                if length(obj.game.selected_cards) < 5
                    obj.game.selected_cards(end+1) = card_idx;
                else
                    fprintf('Maximum 5 cards can be selected\n');
                end
            end
            obj.highlight_selected();
        end
        
        function highlight_selected(obj)
            if ~isvalid(obj.game.ax_handles(1)), return; end
            ax = obj.game.ax_handles(1);
            cards = findobj(ax, 'Type', 'rectangle');
            
            for i = 1:length(cards)
                if ismember(str2double(cards(i).Tag), obj.game.selected_cards)
                    cards(i).FaceColor = [0.8 0.9 1];
                    cards(i).LineWidth = 3;
                else
                    cards(i).FaceColor = 'white';
                    cards(i).LineWidth = 2;
                end
            end
        end
        
         function display_hand(obj)
            if isvalid(obj.game.ax_handles(1))
                CardGraphics.display_hand(obj.game.hand, obj.game.ax_handles(1), @(idx) obj.card_clicked(idx));
            end
            
            if isvalid(obj.game.fig_handle)
                CardGraphics.update_counters(obj.game.fig_handle, ...
                    obj.game.hands_remaining, ...
                    obj.game.discards_remaining);
            end

            fprintf('\nCurrent Hand (%d cards):\n', length(obj.game.hand));
            fprintf('Hands remaining: %d | Discards remaining: %d\n', ...
                   obj.game.hands_remaining, obj.game.discards_remaining);
        end
    end
end