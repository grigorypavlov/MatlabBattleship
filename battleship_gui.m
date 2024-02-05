function battleship_gui
    fig = figure('Name', 'Schiffe Versenken', 'NumberTitle', 'off', 'Resize', 'off', 'Position', [100, 100, 650, 400]);
    gridSize = 10;
    buttonSize = [30, 30];
    playerBoard = zeros(gridSize);
    computerBoard = zeros(gridSize);
    playerButtons = gobjects(gridSize, gridSize);
    computerButtons = gobjects(gridSize, gridSize);
    numPlayerShips = 0;
    statusText = uicontrol('Style', 'text', 'String', 'Platziere deine Schiffe (5 benötigt).', 'Position', [30, 330, 590, 40], 'Parent', fig);

    initializeBoards();

    uicontrol('Style', 'pushbutton', 'String', 'Neustart', 'Position', [30, 370, 100, 20], 'Parent', fig, 'Callback', @resetGame);

    function playerBoardCallback(src, ~, row, col)
        if numPlayerShips < 5 && playerBoard(row, col) == 0
            playerBoard(row, col) = 1;
            set(src, 'String', 'S', 'Enable', 'off');
            numPlayerShips = numPlayerShips + 1;
            if numPlayerShips == 5
                updateStatus('Alle Schiffe platziert. Beginne das Spiel!');
                for i = 1:gridSize
                    for j = 1:gridSize
                        set(computerButtons(i, j), 'Enable', 'on');
                    end
                end
            else
                updateStatus(sprintf('Platziere deine Schiffe (%d/5).', numPlayerShips));
            end
        end
    end

    function computerBoardCallback(src, ~, row, col)
        if computerBoard(row, col) == 0
            computerBoard(row, col) = 3;
            set(src, 'String', '~', 'Enable', 'off');
            updateStatus('Fehlschuss!');
        elseif computerBoard(row, col) == 1
            computerBoard(row, col) = 2;
            set(src, 'String', 'X', 'ForegroundColor', 'red', 'Enable', 'off');
            updateStatus('Treffer!');
            if checkWin(computerBoard)
                updateStatus('Alle Schiffe versenkt. Spieler gewinnt!');
                disableBoard(computerButtons);
            end
        end
        computerAttack();
    end

    function resetGame(~, ~)
        initializeBoards();
        updateStatus('Spiel zurückgesetzt. Platziere deine Schiffe.');
    end

    function initializeBoards()
        playerBoard(:) = 0;
        computerBoard(:) = 0;
        numPlayerShips = 0;
        for i = 1:gridSize
            for j = 1:gridSize
                playerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [30+(j-1)*buttonSize(1), 280-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@playerBoardCallback, i, j});
                computerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [350+(j-1)*buttonSize(1), 280-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@computerBoardCallback, i, j}, 'Enable', 'off');
            end
        end
        placeComputerShips();
    end

    function placeComputerShips()
        numShips = 5;
        for n = 1:numShips
            placed = false;
            while ~placed
                row = randi(gridSize);
                col = randi(gridSize);
                if computerBoard(row, col) == 0
                    computerBoard(row, col) = 1;
                    placed = true;
                end
            end
        end
    end

    function computerAttack()
        attacked = false;
        while ~attacked
            row = randi(gridSize);
            col = randi(gridSize);
            if playerBoard(row, col) <= 1
                if playerBoard(row, col) == 1
                    playerBoard(row, col) = 2;
                    updatePlayerBoard(row, col, 'X', 'red');
                    updateStatus('Computer hat getroffen!');
                    if checkWin(playerBoard)
                        updateStatus('Alle Schiffe versenkt. Computer gewinnt!');
                        disableBoard(playerButtons);
                        break;
                    end
                else
                    playerBoard(row, col) = 3;
                    updatePlayerBoard(row, col, '~', 'blue');
                    updateStatus('Computer hat verfehlt!');
                end
                attacked = true;
            end
        end
    end

    function updatePlayerBoard(row, col, text, color)
        set(playerButtons(row, col), 'String', text, 'ForegroundColor', color, 'Enable', 'off');
    end

    function win = checkWin(board)
        win = all(board(board > 0) ~= 1);
        if win
            disableBoard(computerButtons);
            disableBoard(playerButtons);
        end
    end

    function disableBoard(buttons)
        set(buttons(:), 'Enable', 'off');
    end

    function updateStatus(message)
        set(statusText, 'String', message);
    end
end