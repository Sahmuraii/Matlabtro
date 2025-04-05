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
            if obj.ante_level < length(obj.ante_scores) && ...
               obj.score >= obj.ante_scores(obj.ante_level)
                obj.ante_level = obj.ante_level + 1;
                fprintf('\n=== REACHED ANTE %d ===\n', obj.ante_level);
            end
        end
                
        
        function run(obj)
            fprintf('=== MATLABTRO ===\n');
            obj.is_running = true;
            while obj.is_running
                obj.check_ante_progression();
                obj.logic.start_new_round();
                obj.hands_remaining = 4;
                obj.discards_remaining = 3;
                
                while ~obj.current_blind.disabled && obj.hands_remaining > 0
                    obj.logic.draw_hand(8);
                    
                    if isvalid(obj.fig_handle)
                        obj.waiting_for_input = true;
                        uiwait(obj.fig_handle);
                    else
                        break;
                    end
                    
                    if obj.current_blind.disabled
                        break;
                    end
                end
                
                if isempty(obj.blinds_pool)
                    fprintf('\n=== GAME COMPLETE ===\n');
                    fprintf('Final Score: $%d\n', obj.score);
                    break;
                end
                
                if obj.current_blind.disabled
                    cont = questdlg(sprintf('Defeated %s!\nContinue to next blind?', ...
                        obj.current_blind.name), 'Round Complete', 'Yes', 'No', 'Yes');
                    
                    if ~strcmp(cont, 'Yes')
                        fprintf('\nGame ended. Final Score: $%d\n', obj.score);
                        break;
                    end
                end
            end
            
            if isvalid(obj.fig_handle)
                close(obj.fig_handle);
            end
        end
    end
end