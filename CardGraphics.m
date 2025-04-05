classdef CardGraphics
    methods (Static)
        function varargout = create_game_window(game)
            fig = figure('Name', 'Matlabtro', 'NumberTitle', 'off', ...
                  'Position', [100 100 800 650], 'Color', [0.2 0.2 0.3], ...
                  'CloseRequestFcn', @(src,event) CardGraphics.handle_window_close(src));

            fig.UserData = struct('game', game);
           
            ax1 = subplot(3,1,[1 2]);  
            axis(ax1, 'equal');
            axis(ax1, 'off');
            title(ax1, 'Your Hand');
            
            ax2 = subplot(3,1,3);  
            axis(ax2, 'equal');
            axis(ax2, 'off');
            title(ax2, 'Current Blind');
            
            uicontrol(fig, 'Style', 'text', ...
                'String', 'Hands: 4', ...
                'Tag', 'hands_counter', ...
                'Position', [550 50 100 30], ...
                'FontSize', 12, ...
                'BackgroundColor', [0.2 0.2 0.3], ...
                'ForegroundColor', 'white');
            
            uicontrol(fig, 'Style', 'text', ...
                'String', 'Discards: 3', ...
                'Tag', 'discards_counter', ...
                'Position', [550 20 100 30], ...
                'FontSize', 12, ...
                'BackgroundColor', [0.2 0.2 0.3], ...
                'ForegroundColor', 'white');
            
            if nargout == 1
                varargout{1} = fig;
            elseif nargout == 2
                varargout{1} = fig;
                varargout{2} = [ax1, ax2];
            end
        end
        
        function update_counters(fig, hands, discards)
            hands_text = findobj(fig, 'Tag', 'hands_counter');
            discards_text = findobj(fig, 'Tag', 'discards_counter');
            
            if ~isempty(hands_text)
                set(hands_text, 'String', sprintf('Hands: %d', hands));
            end
            if ~isempty(discards_text)
                set(discards_text, 'String', sprintf('Discards: %d', discards));
            end
        end
        
        function display_hand(cards, ax, clickCallback)
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
                
                text(ax, x+0.3, 2.7, cards{i}.rank, 'FontSize', 14, 'Color', suit_color);
                text(ax, x+0.3, 2.4, cards{i}.suit(1), 'FontSize', 12, 'Color', suit_color);
                text(ax, x+0.2, 0.2, num2str(i), 'FontSize', 10, 'Color', 'blue');
            end
            hold(ax, 'off');
        end
        
        function display_blind(blind, ax)
            cla(ax);
            axis(ax, 'equal');
            axis(ax, 'off');
            
            rectangle(ax, 'Position', [0 0 6 4], 'FaceColor', [0.9 0.9 0.9], ...
                     'EdgeColor', 'black', 'LineWidth', 3, 'Curvature', 0.2);
            
            text(ax, 3, 3.5, blind.name, 'FontSize', 16, 'FontWeight', 'bold', ...
                 'HorizontalAlignment', 'center');
            
            text(ax, 3, 2.5, ['Target: ' num2str(blind.chips)], 'FontSize', 14, ...
                 'HorizontalAlignment', 'center');
            text(ax, 3, 2.0, ['Reward: $' num2str(blind.dollars)], 'FontSize', 14, ...
                 'HorizontalAlignment', 'center');
            text(ax, 3, 1.5, ['Multiplier: ' num2str(blind.mult)], 'FontSize', 14, ...
                 'HorizontalAlignment', 'center');
            
            if blind.boss
                text(ax, 3, 1.0, 'BOSS BLIND', 'FontSize', 16, 'Color', 'red', ...
                     'HorizontalAlignment', 'center');
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