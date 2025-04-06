classdef CardGraphics
    methods (Static)
        function update_counters(fig, hands_remaining, discards_remaining)
            if isfield(fig.UserData, 'mode') && strcmp(fig.UserData.mode, 'card_play')
                hands_text = findobj(fig, 'Tag', 'hands_counter');
                discards_text = findobj(fig, 'Tag', 'discards_counter');
                
                if isvalid(hands_text)
                    hands_text.String = ['Hands: ' num2str(hands_remaining)];
                end
                if isvalid(discards_text)
                    discards_text.String = ['Discards: ' num2str(discards_remaining)];
                end
            end
        end

        
        function varargout = create_game_window(game)
            fig = figure('Name', 'Matlabtro', 'NumberTitle', 'off', ...
                  'Position', [100 100 800 650], 'Color', [0.2 0.2 0.3], ...
                  'CloseRequestFcn', @(src,event) CardGraphics.handle_window_close(src));
        
            fig.UserData = struct('game', game, 'mode', 'card_play');
           
            ax_container = uipanel(fig, 'Position', [0.05 0.05 0.9 0.9], 'BorderType', 'none');
            
            ax1 = subplot(2,1,1, 'Parent', ax_container);  
            axis(ax1, 'equal');
            axis(ax1, 'off');
            
            ax2 = subplot(2,1,2, 'Parent', ax_container);  
            axis(ax2, 'equal');
            axis(ax2, 'off');
            
            fig.UserData.ax_handles = [ax1, ax2];
                        
            if nargout == 1
                varargout{1} = fig;
            elseif nargout == 2
                varargout{1} = fig;
                varargout{2} = [ax1, ax2];
            end
        end
        
        function switch_mode(fig, new_mode)
            if ~isvalid(fig) || ~ismember(new_mode, {'card_play', 'blind_selection'})
                return;
            end
            
            fig.UserData.mode = new_mode;
            
            if ~isfield(fig.UserData, 'ax_handles') || isempty(fig.UserData.ax_handles)
                ax1 = subplot(2,1,1);  
                ax2 = subplot(2,1,2);
                fig.UserData.ax_handles = [ax1, ax2];
            else
                ax1 = fig.UserData.ax_handles(1);
                ax2 = fig.UserData.ax_handles(2);
            end
            
            cla(ax1);
            cla(ax2);
            
            axis(ax1, 'equal');
            axis(ax1, 'off');
            axis(ax2, 'equal');
            axis(ax2, 'off');
            
            delete(findobj(fig, 'Type', 'uicontrol', '-and', 'Style', 'pushbutton'));
            delete(findobj(fig, 'Tag', 'hands_counter'));
            delete(findobj(fig, 'Tag', 'discards_counter'));
            
            game = fig.UserData.game;
            
            if strcmp(new_mode, 'card_play')
                uicontrol(fig, 'Style', 'pushbutton', ...
                    'String', 'Play Selected Cards', ...
                    'Position', [20 20 150 30], ...
                    'Callback', @(~,~) game.actions.play_selected_cards());
                
                uicontrol(fig, 'Style', 'pushbutton', ...
                    'String', 'Discard Selected', ...
                    'Position', [190 20 150 30], ...
                    'Callback', @(~,~) game.actions.discard_selected());
                
                uicontrol(fig, 'Style', 'pushbutton', ...
                    'String', 'Clear Selection', ...
                    'Position', [360 20 150 30], ...
                    'Callback', @(~,~) game.actions.clear_selection());
                
                uicontrol(fig, 'Style', 'text', ...
                    'String', sprintf('Hands: %d', game.hands_remaining), ...
                    'Tag', 'hands_counter', ...
                    'Position', [550 50 100 30], ...
                    'FontSize', 12, ...
                    'BackgroundColor', [0.2 0.2 0.3], ...
                    'ForegroundColor', 'white');
                
                uicontrol(fig, 'Style', 'text', ...
                    'String', sprintf('Discards: %d', game.discards_remaining), ...
                    'Tag', 'discards_counter', ...
                    'Position', [550 20 100 30], ...
                    'FontSize', 12, ...
                    'BackgroundColor', [0.2 0.2 0.3], ...
                    'ForegroundColor', 'white');
                title(ax1, 'Your Hand');
                title(ax2, 'Current Blind');
                
            elseif strcmp(new_mode, 'blind_selection')
                CardGraphics.display_blind(game.current_blind, ax1);
                btn_width = 0.15;  
                btn_height = 0.05;
                btn_y = 0.35;      
                
                uicontrol(fig, 'Style', 'pushbutton', ...
                    'Units', 'normalized', ...
                    'String', 'Select', ...
                    'Position', [0.3 btn_y btn_width btn_height], ...
                    'BackgroundColor', [0.4 0.8 0.4], ...
                    'ForegroundColor', 'white', ...
                    'FontWeight', 'bold', ...
                    'Callback', @(src,evt) game.logic.select_blind());
                
                uicontrol(fig, 'Style', 'pushbutton', ...
                    'Units', 'normalized', ...
                    'String', 'Skip (-$1)', ...
                    'Position', [0.5 btn_y btn_width btn_height], ...
                    'BackgroundColor', [0.9 0.8 0.2], ...
                    'ForegroundColor', 'black', ...
                    'FontWeight', 'bold', ...
                    'Callback', @(src,evt) game.logic.skip_blind());
                
                uicontrol(fig, 'Style', 'pushbutton', ...
                    'Units', 'normalized', ...
                    'String', 'Tag', ...
                    'Position', [0.7 btn_y btn_width btn_height], ...
                    'BackgroundColor', [0.3 0.6 0.9], ...
                    'ForegroundColor', 'white', ...
                    'FontWeight', 'bold', ...
                    'Callback', @(src,evt) game.logic.tag_blind());
                
                title(ax1, 'Blind Selection');
                title(ax2, 'Future Blinds');
            end
            
            drawnow;
        end
        
        function display_blind(blind, ax)
            if nargin < 2 || ~isa(blind, 'Blind') || ~isvalid(ax)
                error('Invalid inputs for display_blind');
            end
            
            try
                cla(ax);
                axis(ax, 'equal');
                axis(ax, 'off');
                
                rectangle(ax, 'Position', [0 0 6 4], ...
                    'FaceColor', [0.9 0.9 0.9], ...
                    'EdgeColor', 'black', ...
                    'LineWidth', 3, ...
                    'Curvature', 0.2);
                
                text(ax, 3, 3.5, blind.name, ...
                    'FontSize', 16, 'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center');
                
                text(ax, 3, 2.5, ['Target: ' num2str(blind.chips)], ...
                    'FontSize', 14, 'HorizontalAlignment', 'center');
                
                text(ax, 3, 2.0, ['Reward: $' num2str(blind.dollars)], ...
                    'FontSize', 14, 'HorizontalAlignment', 'center');
                
                text(ax, 3, 1.5, ['Multiplier: ' num2str(blind.mult)], ...
                    'FontSize', 14, 'HorizontalAlignment', 'center');
                
                if blind.boss
                    text(ax, 3, 1.0, 'BOSS BLIND', ...
                        'FontSize', 16, 'Color', 'red', ...
                        'HorizontalAlignment', 'center');
                end
            catch ME
                fprintf('Error displaying blind: %s\n', ME.message);
                rethrow(ME);
            end
        end

       function display_blind_selection(current_blind, future_blinds, ax1, ax2, game)
            fprintf('Debug - Validating inputs for display_blind_selection...\n');
            
            if isempty(current_blind)
                error('current_blind is empty');
            elseif ~isa(current_blind, 'Blind')
                fprintf('Invalid current_blind type: %s\n', class(current_blind));
                error('current_blind must be a Blind object');
            end
            
            if ~iscell(future_blinds)
                error('future_blinds must be a cell array');
            end
            
            if ~isvalid(ax1) || ~isvalid(ax2)
                error('Invalid axes handles');
            end
            
            try
                fprintf('Displaying blind: %s\n', current_blind.name);

                cla(ax1);
                axis(ax1, 'equal');
                axis(ax1, 'off');
                
                rectangle(ax1, 'Position', [0 0 6 4], ...
                        'FaceColor', [0.9 0.9 0.9], ...
                        'EdgeColor', 'black', ...
                        'LineWidth', 3, ...
                        'Curvature', 0.2);
                
                text(ax1, 3, 3.5, current_blind.name, ...
                    'FontSize', 16, 'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center');
                
                text(ax1, 3, 2.5, ['Target: ' num2str(current_blind.chips)], ...
                    'FontSize', 14, 'HorizontalAlignment', 'center');
                
                text(ax1, 3, 2.0, ['Reward: $' num2str(current_blind.dollars)], ...
                    'FontSize', 14, 'HorizontalAlignment', 'center');
                
                text(ax1, 3, 1.5, ['Multiplier: ' num2str(current_blind.mult)], ...
                    'FontSize', 14, 'HorizontalAlignment', 'center');
                
                if current_blind.boss
                    text(ax1, 3, 1.0, 'BOSS BLIND', ...
                        'FontSize', 16, 'Color', 'red', ...
                        'HorizontalAlignment', 'center');
                end
                
                cla(ax2);
                axis(ax2, 'equal');
                axis(ax2, 'off');
                hold(ax2, 'on');
                
                valid_future = cellfun(@(x) isa(x, 'Blind'), future_blinds);
                valid_blinds = future_blinds(valid_future);
                
                for i = 1:min(2, length(valid_blinds))
                    x_pos = (i-1)*3.5;
                    rectangle(ax2, 'Position', [x_pos 0 3 2.5], ...
                            'FaceColor', [0.8 0.8 0.8], ...
                            'EdgeColor', 'black', ...
                            'LineWidth', 2, ...
                            'Curvature', 0.2);
                    
                    text(ax2, x_pos+1.5, 1.7, valid_blinds{i}.name, ...
                        'FontSize', 12, 'HorizontalAlignment', 'center');
                    
                    text(ax2, x_pos+1.5, 1.2, ['Target: ' num2str(valid_blinds{i}.chips)], ...
                        'FontSize', 10, 'HorizontalAlignment', 'center');
                end
                hold(ax2, 'off');
                
                fig = ancestor(ax1, 'figure');
                
                delete(findobj(fig, 'Type', 'uicontrol', '-and', 'Style', 'pushbutton'));
                
                uicontrol(fig, 'Style', 'pushbutton', ...
                    'String', 'Select', ...
                    'Position', [150 50 100 30], ...
                    'BackgroundColor', [0.4 0.8 0.4], ...
                    'ForegroundColor', 'white', ...
                    'FontWeight', 'bold', ...
                    'Callback', @(src,evt) game.logic.select_blind());
                
                uicontrol(fig, 'Style', 'pushbutton', ...
                    'String', 'Skip (-$1)', ...
                    'Position', [300 50 100 30], ...
                    'BackgroundColor', [0.9 0.8 0.2], ...
                    'ForegroundColor', 'black', ...
                    'FontWeight', 'bold', ...
                    'Callback', @(src,evt) game.logic.skip_blind());
                
                uicontrol(fig, 'Style', 'pushbutton', ...
                    'String', 'Tag', ...
                    'Position', [450 50 100 30], ...
                    'BackgroundColor', [0.3 0.6 0.9], ...
                    'ForegroundColor', 'white', ...
                    'FontWeight', 'bold', ...
                    'Callback', @(src,evt) game.logic.tag_blind());
                
            catch ME
                fprintf('Error in display_blind_selection:\n');
                fprintf('Message: %s\n', ME.message);
                fprintf('Blind object dump:\n');
                disp(current_blind);
                rethrow(ME);
            end
        end

        function display_hand(cards, ax, clickCallback)
            if nargin < 3 || ~isvalid(ax)
                error('Invalid inputs for display_hand');
            end
            
            try
                cla(ax);
                axis(ax, 'equal');
                axis(ax, 'off');
                hold(ax, 'on');
                
                for i = 1:length(cards)
                    x = (i-1)*2.5;
                    
                    rectangle(ax, 'Position', [x 0 2 3], ...
                        'FaceColor', 'white', ...
                        'EdgeColor', 'black', ...
                        'LineWidth', 2, ...
                        'Curvature', 0.1, ...
                        'ButtonDownFcn', @(src,evt) clickCallback(i), ...
                        'Tag', num2str(i));
                    
                    if any(strcmp(cards{i}.suit, {'Hearts', 'Diamonds'}))
                        suit_color = 'red';
                    else
                        suit_color = 'black';
                    end
                    
                    text(ax, x+0.3, 2.7, cards{i}.rank, ...
                        'FontSize', 14, 'Color', suit_color);
                    text(ax, x+0.3, 2.4, cards{i}.suit(1), ...
                        'FontSize', 12, 'Color', suit_color);
                    text(ax, x+0.2, 0.2, num2str(i), ...
                        'FontSize', 10, 'Color', 'blue');
                end
                hold(ax, 'off');
            catch ME
                fprintf('Error in display_hand: %s\n', ME.message);
                rethrow(ME);
            end
        end
        
        function handle_window_close(fig)
            if isprop(fig, 'UserData') && isfield(fig.UserData, 'game')
                game = fig.UserData.game;
                game.quit_game();
            else 
                delete(fig);
            end 
        end
    end
end