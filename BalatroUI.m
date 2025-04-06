classdef BalatroUI < handle
    properties
        game 
        card_objects = struct('rect', {}, 'rank_text', {}, 'suit_symbol', {}, 'rank_text_bottom', {})
    end
    
    methods
        function obj = BalatroUI(game)
            obj.game = game;
        end
        
        function create_game_window(obj)
            if isempty(obj.game.fig_handle) || ~isvalid(obj.game.fig_handle)
                [obj.game.fig_handle, obj.game.ax_handles] = CardGraphics.create_game_window(obj.game);
                obj.game.fig_handle.UserData.ax_handles = obj.game.ax_handles;
                obj.create_ui_buttons();
                obj.update_display();
            else
                if isfield(obj.game.fig_handle.UserData, 'ax_handles')
                    obj.game.ax_handles = obj.game.fig_handle.UserData.ax_handles;
                end
            end
        end
        
        function create_ui_buttons(obj)
            buttons = {'play_button', 'discard_button', 'clear_button'};
            for i = 1:length(buttons)
                if isfield(obj.game.ui_controls, buttons{i}) && isvalid(obj.game.ui_controls.(buttons{i}))
                    delete(obj.game.ui_controls.(buttons{i}));
                end
            end
            
            if strcmp(obj.game.current_mode, 'card_play') && isvalid(obj.game.fig_handle)
                obj.game.ui_controls.play_button = uicontrol(obj.game.fig_handle, ...
                    'Style', 'pushbutton', ...
                    'String', 'Play Selected Cards', ...
                    'Position', [20 20 150 30], ...
                    'Callback', @(~,~) obj.game.actions.play_selected_cards());
                
                obj.game.ui_controls.discard_button = uicontrol(obj.game.fig_handle, ...
                    'Style', 'pushbutton', ...
                    'String', sprintf('Discard (%d left)', obj.game.discards_remaining), ...
                    'Position', [190 20 150 30], ...
                    'Callback', @(~,~) obj.game.actions.discard_selected());
                
                obj.game.ui_controls.clear_button = uicontrol(obj.game.fig_handle, ...
                    'Style', 'pushbutton', ...
                    'String', 'Clear Selection', ...
                    'Position', [360 20 150 30], ...
                    'Callback', @(~,~) obj.game.actions.clear_selection());
            end
        end
        
        function card_clicked(obj, card_idx)
            if strcmp(obj.game.current_mode, 'card_play') && ...
               ~isempty(obj.game.ax_handles) && ...
               all(isvalid(obj.game.ax_handles))
               
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
        end
        
        function highlight_selected(obj)
            if strcmp(obj.game.current_mode, 'card_play') && ...
               ~isempty(obj.card_objects) && ...
               ishandle(obj.game.ax_handles(1))
               
                for i = 1:length(obj.card_objects)
                    if isfield(obj.card_objects(i), 'rect') && ishandle(obj.card_objects(i).rect)
                        card = obj.game.hand{i};
                        if any(strcmpi(card.suit, {'Hearts', 'Diamonds'}))
                            base_color = [1 0.8 0.8];
                        else
                            base_color = [0.9 0.9 0.95];
                        end
                        
                        if ismember(i, obj.game.selected_cards)
                            set(obj.card_objects(i).rect, ...
                                'FaceColor', [0.8 0.9 1], ...
                                'LineWidth', 3, ...
                                'EdgeColor', [0 0.5 1]);
                        else
                            set(obj.card_objects(i).rect, ...
                                'FaceColor', base_color, ...
                                'LineWidth', 2, ...
                                'EdgeColor', 'k');
                        end
                    end
                end
                drawnow;
            end
        end
        
        function display_hand(obj)
            if strcmp(obj.game.current_mode, 'card_play') && ...
               ~isempty(obj.game.ax_handles) && ...
               all(ishandle(obj.game.ax_handles))
               
                try
                    % Clear existing cards
                    if ~isempty(obj.card_objects)
                        for i = 1:length(obj.card_objects)
                            if isfield(obj.card_objects(i), 'rect') && ishandle(obj.card_objects(i).rect)
                                delete(obj.card_objects(i).rect);
                            end
                            if isfield(obj.card_objects(i), 'rank_text') && ishandle(obj.card_objects(i).rank_text)
                                delete(obj.card_objects(i).rank_text);
                            end
                            if isfield(obj.card_objects(i), 'suit_symbol') && ishandle(obj.card_objects(i).suit_symbol)
                                delete(obj.card_objects(i).suit_symbol);
                            end
                            if isfield(obj.card_objects(i), 'rank_text_bottom') && ishandle(obj.card_objects(i).rank_text_bottom)
                                delete(obj.card_objects(i).rank_text_bottom);
                            end
                        end
                    end
                    
                    % Card display parameters
                    num_cards = length(obj.game.hand);
                    card_aspect_ratio = 0.7; % Standard playing card ratio
                    card_height = 0.4; % Height of cards
                    card_width = card_height * card_aspect_ratio;
                    
                    % Spacing and layout
                    card_spacing = 0.015;
                    total_width = num_cards*card_width + (num_cards-1)*card_spacing;
                    margin = (1 - total_width)/2;
                    
                    obj.card_objects = struct('rect', {}, 'rank_text', {}, ...
                                             'suit_symbol', {}, 'rank_text_bottom', {});
                    
                    for i = 1:num_cards
                        % Calculate position with spacing
                        x_pos = margin + (i-1)*(card_width + card_spacing);
                        card = obj.game.hand{i};
                        
                        % Determine card appearance
                        if strcmpi(card.suit, 'Hearts')
                            symbol = '♥';
                            symbol_color = [0.7 0 0];
                            card_color = [1 0.8 0.8];
                            text_color = [0.7 0 0];
                        elseif strcmpi(card.suit, 'Diamonds')
                            symbol = '♦';
                            symbol_color = [0.9 0.5 0];
                            card_color = [1 0.95 0.9];
                            text_color = [0.9 0.5 0];
                        elseif strcmpi(card.suit, 'Clubs')
                            symbol = '♣';
                            symbol_color = [0 0.6 0];
                            card_color = [0.85 0.95 0.85];
                            text_color = [0 0.6 0];
                        elseif strcmpi(card.suit, 'Spades')
                            symbol = '♠';
                            symbol_color = [0 0 0];
                            card_color = [0.95 0.95 0.95];
                            text_color = [0 0 0];
                        else
                            symbol = card.suit(1);
                            symbol_color = [0 0 0];
                            card_color = [1 1 1];
                            text_color = [0 0 0];
                        end
                        
                        % Create card rectangle
                        obj.card_objects(i).rect = rectangle(...
                            'Position', [x_pos, 0.3, card_width, card_height], ...
                            'FaceColor', card_color, ...
                            'EdgeColor', 'k', ...
                            'LineWidth', 2, ...
                            'Curvature', [0.1 0.1], ...
                            'Parent', obj.game.ax_handles(1), ...
                            'ButtonDownFcn', @(~,~) obj.card_clicked(i));
                        
                        % Create rank text (top left)
                        obj.card_objects(i).rank_text = text(...
                            x_pos + 0.02, 0.3 + card_height - 0.05, ...
                            card.rank, ...
                            'Color', text_color, ...
                            'FontSize', 14, ...
                            'FontWeight', 'bold', ...
                            'HorizontalAlignment', 'left', ...
                            'Parent', obj.game.ax_handles(1));
                        
                        % Create suit symbol (center)
                        obj.card_objects(i).suit_symbol = text(...
                            x_pos + card_width/2, 0.3 + card_height/2, ...
                            symbol, ...
                            'Color', symbol_color, ...
                            'FontSize', 24, ...
                            'FontWeight', 'bold', ...
                            'HorizontalAlignment', 'center', ...
                            'Parent', obj.game.ax_handles(1));
                        
                        % Create rank text (bottom right, upside down)
                        obj.card_objects(i).rank_text_bottom = text(...
                            x_pos + card_width - 0.02, 0.3 + 0.07, ...
                            card.rank, ...
                            'Color', text_color, ...
                            'FontSize', 14, ...
                            'FontWeight', 'bold', ...
                            'HorizontalAlignment', 'left', ...
                            'Rotation', 180, ...
                            'Parent', obj.game.ax_handles(1), ...
                            'Margin', .5);
                    end
                    
                    % Update counters
                    if ishandle(obj.game.fig_handle)
                        CardGraphics.update_counters(...
                            obj.game.fig_handle, ...
                            obj.game.hands_remaining, ...
                            obj.game.discards_remaining);
                    end
                    
                    % Update highlights
                    obj.highlight_selected();
                    
                catch ME
                    fprintf('Error displaying hand: %s\n', ME.message);
                    obj.recover_axes();
                end
            end
        end
        
        function update_discard_display(obj, card_indices)
            if ~isempty(obj.card_objects)
                for idx = card_indices
                    if idx <= length(obj.card_objects) && isfield(obj.card_objects(idx), 'rect') && ishandle(obj.card_objects(idx).rect)
                        set(obj.card_objects(idx).rect, ...
                            'FaceColor', [1 0.7 0.7], ...
                            'LineWidth', 3);
                    end
                end
                drawnow;
                pause(0.3);
            end
        end
        
        function display_blind_selection(obj)
            if strcmp(obj.game.current_mode, 'blind_selection') && ...
               ~isempty(obj.game.ax_handles) && ...
               numel(obj.game.ax_handles) >= 2 && ...
               all(isvalid(obj.game.ax_handles(1:2)))
               
                try
                    CardGraphics.display_blind_selection(...
                        obj.game.current_blind, ...
                        obj.game.logic.future_blinds, ...
                        obj.game.ax_handles(1), ...
                        obj.game.ax_handles(2), ...
                        obj.game);
                catch ME
                    fprintf('Error displaying blind selection: %s\n', ME.message);
                    obj.recover_axes();
                end
            end
        end
        
        function recover_axes(obj)
            if isvalid(obj.game.fig_handle)
                ax = findobj(obj.game.fig_handle, 'Type', 'axes');
                if numel(ax) >= 2
                    obj.game.ax_handles = ax(1:2);
                    obj.game.fig_handle.UserData.ax_handles = obj.game.ax_handles;
                else
                    obj.create_game_window();
                end
            end
        end
        
        function update_display(obj)
            if ~isvalid(obj.game.fig_handle) || isempty(obj.game.ax_handles)
                obj.create_game_window();
                return;
            end
            
            if any(~isvalid(obj.game.ax_handles))
                obj.recover_axes();
                if isempty(obj.game.ax_handles) || any(~isvalid(obj.game.ax_handles))
                    return;
                end
            end
            
            try
                switch obj.game.current_mode
                    case 'card_play'
                        obj.display_hand();
                        if ~isempty(obj.game.current_blind)
                            CardGraphics.display_blind(obj.game.current_blind, obj.game.ax_handles(2));
                        end
                    case 'blind_selection'
                        obj.display_blind_selection();
                end
            catch ME
                fprintf('Error updating display: %s\n', ME.message);
                obj.recover_axes();
            end
            
            obj.create_ui_buttons();
        end
        
        function cleanup(obj)
            if isfield(obj.game.ui_controls, 'play_button') && isvalid(obj.game.ui_controls.play_button)
                delete(obj.game.ui_controls.play_button);
            end
            if isfield(obj.game.ui_controls, 'discard_button') && isvalid(obj.game.ui_controls.discard_button)
                delete(obj.game.ui_controls.discard_button);
            end
            if isfield(obj.game.ui_controls, 'clear_button') && isvalid(obj.game.ui_controls.clear_button)
                delete(obj.game.ui_controls.clear_button);
            end
        end
    end
end