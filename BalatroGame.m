classdef BalatroGame < handle
    properties
        ui BalatroUI
        logic BalatroGameLogic
        evaluator BalatroHandEvaluation
        actions BalatroPlayerActions
        
        G
        current_blind   
        blinds_pool     
        score           
        hand            
        deck            
        played_cards    
        hands_remaining 
        discards_remaining 
        ante            
        fig_handle 
        ax_handles
        selected_cards  
        waiting_for_input 
        ui_controls
        is_running = true
        ante_level = 1
        ante_scores = [300, 800, 2000, 5000, 11000, 20000, 35000, 50000]
        current_mode 
        stake_level = 1
        stake_names = {'White', 'Red', 'Green', 'Black', 'Gold'}
        cumulative_score = 0
    end
    
    methods
        function obj = BalatroGame()
            obj.G = BalatroGlobals();
            obj.ui = BalatroUI(obj);
            obj.logic = BalatroGameLogic(obj);
            obj.evaluator = BalatroHandEvaluation(obj);
            obj.actions = BalatroPlayerActions(obj);
            
            obj.score = 0;
            obj.logic.initialize_blinds();
            obj.current_blind = [];
            obj.hands_remaining = 4;
            obj.discards_remaining = 3;
            obj.selected_cards = [];
            obj.waiting_for_input = false;
            obj.ui_controls = struct();
            obj.logic.initialize_deck();
            obj.ante_level = 1;
            obj.current_mode = 'blind_selection'; 
            
            obj.ui.create_game_window();
            obj.fig_handle.UserData.game = obj;
        end

        function quit_game(obj)
            obj.is_running = false;
            if isvalid(obj.fig_handle)
                delete(obj.fig_handle);
            end
            fprintf('\nGame closed by user. Final Score: $%d\n', obj.score);
        end
        
        function check_ante_progression(obj)
            ante_thresholds = [300, 800, 2000, 5000, 11000, 20000, 35000, 50000];
            if obj.ante_level < length(ante_thresholds) && ...
               obj.score >= ante_thresholds(obj.ante_level)
                obj.ante_level = obj.ante_level + 1;
                fprintf('\n=== REACHED ANTE %d (%s Stake) ===\n', ...
                    obj.ante_level, obj.stake_names{obj.stake_level});
            end
        end
        
        function switch_mode(obj, new_mode)
            if ~ismember(new_mode, {'blind_selection', 'card_play'})
                error('Invalid game mode: %s', new_mode);
            end
            
            if ~isvalid(obj.fig_handle)
                obj.ui.create_game_window();
            end
            
            obj.current_mode = new_mode;
            
            CardGraphics.switch_mode(obj.fig_handle, new_mode);
            
            if strcmp(new_mode, 'card_play')
                obj.ui.display_hand();
                if ~isempty(obj.current_blind)
                    CardGraphics.display_blind(obj.current_blind, obj.ax_handles(2));
                end
            else
                if ~isempty(obj.current_blind) && ~isempty(obj.logic.future_blinds)
                    CardGraphics.display_blind_selection(...
                        obj.current_blind, obj.logic.future_blinds, ...
                        obj.ax_handles(1), obj.ax_handles(2), obj);
                end
            end
        end
                
        function run(obj)
            fprintf('=== MATLABTRO ===\n');
            obj.is_running = true;
            
            while obj.is_running
                obj.check_ante_progression();
                
                obj.logic.start_new_round();
                obj.switch_mode('blind_selection');
                obj.cumulative_score = 0; 
                
                if isvalid(obj.fig_handle)
                    obj.waiting_for_input = true;
                    uiwait(obj.fig_handle);
                    
                    if ~obj.is_running || ~isvalid(obj.fig_handle)
                        break;
                    end
                end
                
                obj.switch_mode('card_play');
                obj.hands_remaining = 4;
                obj.discards_remaining = 3;
                obj.logic.draw_hand(8); 
                
                blind_defeated = false;
                while ~blind_defeated && obj.hands_remaining > 0 && obj.is_running
                    if isvalid(obj.fig_handle)
                        obj.waiting_for_input = true;
                        uiwait(obj.fig_handle);
                        
                        if ~obj.is_running || ~isvalid(obj.fig_handle)
                            break;
                        end
                    end
                    
                    if obj.cumulative_score >= obj.current_blind.chips
                        blind_defeated = true;
                        obj.score = obj.score + obj.current_blind.dollars;
                        fprintf('\n=== BLIND DEFEATED ===\n');
                        fprintf('Total Score: %d/%d\n', obj.cumulative_score, obj.current_blind.chips);
                        fprintf('Defeated %s! Earned $%d\n', ...
                            obj.current_blind.name, obj.current_blind.dollars);
                        fprintf('Current Total: $%d\n\n', obj.score);
                        obj.current_blind.defeat();
                    elseif obj.hands_remaining <= 0
                        fprintf('\n=== ROUND FAILED ===\n');
                        fprintf('Failed to defeat %s!\n', obj.current_blind.name);
                        fprintf('Final Total Score: %d/%d\n', obj.cumulative_score, obj.current_blind.chips);
                        obj.is_running = false;
                    end
                end

                if isempty(obj.logic.future_blinds) && blind_defeated
                    fprintf('\n=== GAME COMPLETE ===\n');
                    fprintf('All blinds defeated! Final Score: $%d\n', obj.score);
                    obj.is_running = false;
                end
            end
            
            if isvalid(obj.fig_handle)
                close(obj.fig_handle);
            end
        end
    end
end