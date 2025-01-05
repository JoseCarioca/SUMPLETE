function sumplete_game
    % Create the main figure window
    fig = uifigure('Name', 'Sumplete Game', 'Position', [100 100 550 550]);
    
    % Create initial buttons panel
    initial_panel = uipanel(fig, 'Position', [25 250 500 200]);
    
    % Create game start buttons
    generate_btn3 = uibutton(initial_panel, 'Text', 'Generate 3x3 game', ...
        'Position', [20 120 150 40], ...,
        'ButtonPushedFcn', @(src,event) generateGame(3));
    generate_btn6 = uibutton(initial_panel, 'Text', 'Generate 6x6 game', ...
        'Position', [175 120 150 40], ...,
        'ButtonPushedFcn', @(src,event) generateGame(6));
    generate_btn9 = uibutton(initial_panel, 'Text', 'Generate 9x9 game', ...
        'Position', [330 120 150 40], ...,
        'ButtonPushedFcn', @(src,event) generateGame(9));
    
    webcam_btn = uibutton(initial_panel, 'Text', 'Read from Webcam', ...
        'Position', [100 60 300 40], ...
        'ButtonPushedFcn', @readFromWebcam);
    
    % Variables to store game state
    game_data.board = [];
    game_data.crossed = [];
    game_data.N = 0;
    game_data.game_panel = [];
    game_data.cell_buttons = {};
    game_data.solution = [];
    
    function generateGame(n)
        % Assuming you have a function that generates a valid game matrix
        matrix = generateGameBoard(n); % This function should be provided
        startGame(matrix);
    end
    
    function readFromWebcam(~,~)
        % Clear initial buttons
        delete(initial_panel);
        
        % Create verification panel
        verify_panel = uipanel(fig, 'Position', [50 150 500 200]);
        
        % Create label to show status
        status_label = uilabel(verify_panel, ...
            'Position', [100 140 300 30], ...
            'Text', 'Reading board from webcam...', ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 14);
        
        % Read the board
        matrix = READ_BOARD();
        status_label.Text = 'Board detected. Please verify:';
        
        % Create verification buttons
        accept_btn = uibutton(verify_panel, ...
            'Text', 'Accept Board', ...
            'Position', [100 80 300 40], ...
            'ButtonPushedFcn', @(~,~)acceptBoard(matrix, verify_panel));
        
        retry_btn = uibutton(verify_panel, ...
            'Text', 'Try Again', ...
            'Position', [100 20 300 40], ...
            'ButtonPushedFcn', @(~,~)retryRead(verify_panel, status_label));
    end
    
    function acceptBoard(matrix, panel_to_delete)
        delete(panel_to_delete);
        startGame(matrix);
    end
    
    function retryRead(panel, status_label)
        status_label.Text = 'Reading board from webcam...';
        matrix = READ_BOARD();
        status_label.Text = 'Board detected. Please verify:';
    end
    
    function startGame(matrix)
        % Clear initial panel
        delete(initial_panel);

        % Use GA for solution
        game_data.solution = solveGenetic(matrix);
        game_data.solution
        
        % Initialize game state
        game_data.N = size(matrix, 1);
        game_data.board = matrix;
        game_data.crossed = false(game_data.N-1, game_data.N-1);
        
        % Create game panel
        game_data.game_panel = uipanel(fig, 'Position', [25 25 500 500]);
        
        % Calculate cell size based on panel size
        cell_size = min(500/(game_data.N+1), 100);
        start_x = 50;
        start_y = 500-cell_size;
        
        % Create grid of buttons for the game board
        game_data.cell_buttons = cell(game_data.N-1, game_data.N-1);
        
        % Get the original board values (excluding sums)
        original_board = matrix(1:end-1, 1:end-1);
        
        for i = 1:(game_data.N-1)
            for j = 1:(game_data.N-1)
                % Create layered button with number and potential cross
                btn = uibutton(game_data.game_panel, ...
                    'Position', [start_x+(j-1)*cell_size start_y-(i-1)*cell_size cell_size cell_size], ...
                    'Text', sprintf('%d', original_board(i,j)), ...  % Display the number directly
                    'HorizontalAlignment', 'center', ...  % Center the text
                    'FontSize', 14, ...  % Larger font size
                    'BackgroundColor', 'white', ...
                    'Tag', sprintf('%d,%d', i, j));
                btn.ButtonPushedFcn = @(btn,event)cellClicked(i, j);
                game_data.cell_buttons{i,j} = btn;
            end
            
            % Add row sums
            uilabel(game_data.game_panel, ...
                'Position', [start_x+((game_data.N-1))*cell_size start_y-(i-1)*cell_size cell_size cell_size], ...
                'Text', num2str(matrix(i,end)), ...
                'HorizontalAlignment', 'center', ...
                'FontWeight', 'bold', ...
                'FontSize', 14);
        end
        
        % Add column sums below the grid
        for j = 1:(game_data.N-1)
            uilabel(game_data.game_panel, ...
                'Position', [start_x+(j-1)*cell_size start_y-(game_data.N-1)*cell_size cell_size cell_size], ...
                'Text', num2str(matrix(end,j)), ...
                'HorizontalAlignment', 'center', ...
                'FontWeight', 'bold', ...
                'FontSize', 14);
        end
        
        % Add move input buttons
        uibutton(game_data.game_panel, 'Text', 'Image Input', ...
            'Position', [50 10 200 30], ...
            'ButtonPushedFcn', @webcamMove);
        
        uibutton(game_data.game_panel, 'Text', 'Voice Input', ...
            'Position', [270 10 200 30], ...
            'ButtonPushedFcn', @voiceMove);
    end
    
    function cellClicked(row, col)
        if isValidMove(row, col)
            game_data.crossed(row, col) = ~game_data.crossed(row, col);
            updateBoard();
            checkWinCondition();
        end
    end
    
    function webcamMove(~,~)
        % Assuming you have a function that handles manual input
        [x, y] = IMAGE_MOVE(); % This function should be provided
        if isValidMove(x, y)
            game_data.crossed(x, y) = ~game_data.crossed(x, y);
            updateBoard();
            checkWinCondition();
        end
    end
    
    function voiceMove(~,~)
        % Assuming you have a function that handles alternative input
        [x, y] = VOICE_MOVE(); % This function should be provided
        if isValidMove(x, y)
            game_data.crossed(x, y) = ~game_data.crossed(x, y);
            updateBoard();
            checkWinCondition();
        end
    end
    
    function valid = isValidMove(row, col)
        valid = row >= 1 && row <= (game_data.N-1) && ...
                col >= 1 && col <= (game_data.N-1);
        if ~valid
            uialert(fig, 'Invalid move! Position is outside the board.', 'Error');
        end
    end
    
    function updateBoard()
        for i = 1:(game_data.N-1)
            for j = 1:(game_data.N-1)
                btn = game_data.cell_buttons{i,j};
                if game_data.crossed(i,j)
                    btn.BackgroundColor = [0.95 0.15 0.15]; % Red
                else
                    % Show only the number
                    btn.Text = sprintf('%d', game_data.board(i,j));
                    btn.BackgroundColor = 'white';
                end
            end
        end
    end
    
    function checkWinCondition()
        % Get original board without the sums
        original_board = game_data.board(1:end-1, 1:end-1);
        
        % Calculate current sums
        row_sums = sum(original_board .* ~game_data.crossed, 2);
        col_sums = sum(original_board .* ~game_data.crossed, 1)';
        
        % Compare with target sums
        target_row_sums = game_data.board(1:end-1, end);
        target_col_sums = game_data.board(end, 1:end-1)';
        
        if all(row_sums == target_row_sums) && all(col_sums == target_col_sums)
            uialert(fig, 'Congratulations! You solved the puzzle!', 'Winner!', ...
                'Icon', 'success');
        end
    end
end