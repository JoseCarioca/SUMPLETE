function gameBoard = generateGameBoard(n)

    N = n+1; % Example board size (5x5 grid + sums row/column)
    
    % Generate a random valid board
    mainBoard = randi([1, 9], N-1, N-1); % Random (N-1)x(N-1) numbers

    % Randomly select cells to turn to 0 (approximately 1/3 of cells)
    numCells = (N-1) * (N-1);
    removableCount = floor(numCells / 3); % 1/3 of the cells
    removableCells = randperm(numCells, removableCount);

    % Create a copy of the board to calculate sums after setting cells to 0
    modifiedBoard = mainBoard;
    for idx = removableCells
        [r, c] = ind2sub([N-1, N-1], idx);
        modifiedBoard(r, c) = 0; % Set to 0
    end

    % Calculate row and column sums based on the modified board
    rowSums = sum(modifiedBoard, 2); % Row sums
    colSums = sum(modifiedBoard, 1); % Column sums

    % Create the full game board with sums
    gameBoard = zeros(N, N);
    gameBoard(1:N-1, 1:N-1) = mainBoard; % Original numbers
    gameBoard(1:N-1, N) = rowSums;       % Row sums
    gameBoard(N, 1:N-1) = colSums;       % Column sums
    gameBoard
end