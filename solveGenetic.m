function solution = solveGenetic(matrix)
    N = size(matrix, 1) - 1;  
    target_row_sums = matrix(1:N, end);
    target_col_sums = matrix(end, 1:N);
    puzzle_board = matrix(1:N, 1:N);
    
    options = optimoptions('ga', ...
        'PopulationType', 'bitstring', ...
        'PopulationSize', 3000, ...
        'MaxGenerations', 200, ...
        'MaxStallGenerations', 150, ...
        'FunctionTolerance', 1e-6, ...
        'Display', 'none');
    
    numberOfVariables = N * N;
    
    solution_vector = ga(@(x)fitness_function(x, puzzle_board, target_row_sums, target_col_sums), ...
        numberOfVariables, [], [], [], [], [], [], [], [], options);
    
    % Reshape to solution
    solution = reshape(solution_vector, [N, N]);
    checkWinCondition(matrix, solution);
end

function fitness = fitness_function(x, puzzle_board, target_row_sums, target_col_sums)
    N = size(puzzle_board, 1);
    solution_matrix = reshape(x, [N, N]);
    
    current_row_sums = sum(puzzle_board .* ~solution_matrix, 2);
    current_col_sums = sum(puzzle_board .* ~solution_matrix, 1);
    
    %row_diff = sum(abs(current_row_sums - target_row_sums));
    %col_diff = sum(abs(current_col_sums - target_col_sums));
    %fitness = row_diff + col_diff;
    fitness = -(sum(current_row_sums == target_row_sums)+sum(current_col_sums == target_col_sums));
    %fitness = fitness - (row_diff+col_diff);
end

function checkWinCondition(matrix, solution)
    original_board = matrix(1:end-1, 1:end-1);
    
    row_sums = sum(original_board .* ~solution, 2);
    col_sums = sum(original_board .* ~solution, 1)';
    
    target_row_sums = matrix(1:end-1, end);
    target_col_sums = matrix(end, 1:end-1)';
    
    all(target_row_sums == row_sums) && all(target_col_sums == col_sums)
end