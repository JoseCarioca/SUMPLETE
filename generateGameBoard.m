function gameBoard = generateGameBoard(n)

    N = n+1;
    
    mainBoard = randi([1, 9], N-1, N-1);

    % Select random cells
    numCells = (N-1) * (N-1);
    removableCount = floor(numCells / 3); % 1/3 of the cells
    removableCells = randperm(numCells, removableCount);

    % Copy of the board to calculate sums after setting cells to 0
    modifiedBoard = mainBoard;
    for idx = removableCells
        [r, c] = ind2sub([N-1, N-1], idx);
        modifiedBoard(r, c) = 0;
    end

    % Calculate row and column sums of the modified board
    rowSums = sum(modifiedBoard, 2); 
    colSums = sum(modifiedBoard, 1); 

    % Concat
    gameBoard = zeros(N, N);
    gameBoard(1:N-1, 1:N-1) = mainBoard; 
    gameBoard(1:N-1, N) = rowSums;   
    gameBoard(N, 1:N-1) = colSums;   
end