function sumplete_game
    fig = uifigure('Name', 'Sumplete Game', 'Position', [100 100 550 650]);
    
    initial_panel = uipanel(fig, 'Position', [25 250 500 200]);
    
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
        matrix = generateGameBoard(n);
        startGame(matrix);
    end
    
    function readFromWebcam(~,~)
        delete(initial_panel);
        
        % Different panel during webcam grab
        verify_panel = uipanel(fig, 'Position', [50 150 500 200]);

        status_label = uilabel(verify_panel, ...
            'Position', [100 140 300 30], ...
            'Text', 'Reading board from webcam...', ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 14);
        
        % Ref
        matrix = READ_BOARD();
        game_data.board = matrix;
        status_label.Text = 'Board detected. Please verify:';
        
        accept_btn = uibutton(verify_panel, ...
            'Text', 'Accept Board', ...
            'Position', [100 80 300 40], ...
            'ButtonPushedFcn', @(~,~)acceptBoard(verify_panel));
        
        retry_btn = uibutton(verify_panel, ...
            'Text', 'Try Again', ...
            'Position', [100 20 300 40], ...
            'ButtonPushedFcn', @(~,~)retryRead(verify_panel, status_label));
    end
    
    function acceptBoard(panel_to_delete)
        delete(panel_to_delete);
        startGame(game_data.board);
    end
    
    function retryRead(panel, status_label)
        status_label.Text = 'Reading board from webcam...';
        matrix = READ_BOARD();
        game_data.board = matrix;
        status_label.Text = 'Board detected. Please verify:';
    end
    
    function startGame(matrix)
        delete(initial_panel);

        game_data.solution = solveGenetic(matrix);
        
        game_data.N = size(matrix, 1);
        game_data.board = matrix;
        game_data.crossed = false(game_data.N-1, game_data.N-1);
        
        game_data.game_panel = uipanel(fig, 'Position', [25 25 500 550]);
        
        cell_size = min(500/(game_data.N+1), 100);
        start_x = 50;
        start_y = 550-cell_size;
        
        game_data.cell_buttons = cell(game_data.N-1, game_data.N-1);
        
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
        
        % Input
        uibutton(game_data.game_panel, 'Text', 'Image Input', ...
            'Position', [50 50 200 30], ...
            'ButtonPushedFcn', @webcamMove);
        
        uibutton(game_data.game_panel, 'Text', 'Voice Input', ...
            'Position', [270 50 200 30], ...
            'ButtonPushedFcn', @voiceMove);

        uibutton(game_data.game_panel, 'Text', 'Ask for help', ...
            'Position', [270 10 200 30], ...
            'ButtonPushedFcn', @helpClick);

        checkWinCondition();


    end
    
    function cellClicked(row, col)
        if row < game_data.N && col < game_data.N
            if game_data.crossed(row, col)%check if its already crossed
    
                game_data.crossed(row, col) = ~game_data.crossed(row, col);
                updateBoard();
                
            elseif isValidMove(row, col)
    
                game_data.crossed(row, col) = ~game_data.crossed(row, col);
                updateBoard();
                checkWinCondition();
            end

        else
            uialert(fig, 'Invalid move!', 'Error');
        end
    end
    
   function webcamMove(~,~)
    % Primer número
    x = READ_NUMBER();
    %uialert(fig, sprintf('The number read is %i', x), "Success", 'Icon', 'success');

    % Confirmación para continuar
    choice = uiconfirm(fig, sprintf('The number read is %i , is it correct?', x), ...
        'Continue?', 'Options', {'Yes', 'No'});
    
    if strcmp(choice, 'Yes')
        y = READ_NUMBER();
        choice = uiconfirm(fig, sprintf('The number read is %i , is it correct?', y), ...
        'Continue?', 'Options', {'Yes', 'No'});

        if strcmp(choice, 'Yes')
            cellClicked(x, y);
        end
    end
end
    
    function voiceMove(~,~)
        [x, y] = VOICE_MOVE(); % TODO
        if isValidMove(x, y)
            game_data.crossed(x, y) = ~game_data.crossed(x, y);
            updateBoard();
            checkWinCondition();
        end
    end

    function helpClick(~,~)
        % Differences between the board and the solution
        [rows, cols] = find(abs(game_data.solution-game_data.crossed) == 1);
        
        idx = randi(length(rows));
        
        x = rows(idx);
        y = cols(idx);

        game_data.crossed(x, y) = ~game_data.crossed(x, y);
        updateBoard();
        checkWinCondition();
    end
    
    function valid = isValidMove(row, col)
        x_marked = game_data.crossed(row,:) == 1;
        y_marked = game_data.crossed(:,col) == 1;

        sum_x = sum(game_data.board(row,x_marked));
        sum_y = sum(game_data.board(y_marked,col));
        valid = row >= 1 && row <= (game_data.N-1) && ...
                col >= 1 && col <= (game_data.N-1) && ...
                (sum_x + game_data.board(row,col)) <= game_data.board(row,game_data.N) && ...
                (sum_y + game_data.board(row,col))<= game_data.board(game_data.N,col);


        if ~valid
            uialert(fig, 'Invalid move!', 'Error');
        end
    end
    
    function updateBoard()
        for i = 1:(game_data.N-1)
            for j = 1:(game_data.N-1)
                btn = game_data.cell_buttons{i,j};
                if game_data.crossed(i,j)
                    btn.BackgroundColor = [0.95 0.15 0.15]; % Red
                else
                    % If not crossed
                    btn.Text = sprintf('%d', game_data.board(i,j));
                    btn.BackgroundColor = 'white';
                end
            end
        end
    end
    
    function checkWinCondition()
        original_board = game_data.board(1:end-1, 1:end-1);
        
        row_sums = sum(original_board .* game_data.crossed, 2);
        col_sums = sum(original_board .* game_data.crossed, 1)';
        
        target_row_sums = game_data.board(1:end-1, end);
        target_col_sums = game_data.board(end, 1:end-1)';
        
        if all(row_sums == target_row_sums) && all(col_sums == target_col_sums)
            msg = msgbox({'Congratulations! You did it, you solved the puzzle!'; ...
                'There is no more. Click OK to close.'}, 'The end');
            uiwait(msg);
            close(fig);
        end
    end
end