function battleship_gui
    fig = figure('Name', 'Schiffe Versenken', 'NumberTitle', 'off', 'Resize', 'off', 'Position', [100, 100, 650, 500]);
    gridSize = 10;
    buttonSize = [30, 30];
    playerBoard = zeros(gridSize);
    computerBoard = zeros(gridSize);
    playerButtons = gobjects(gridSize, gridSize);
    computerButtons = gobjects(gridSize, gridSize);
    numPlayerShips = 0;
    statusText = uicontrol('Style', 'text', 'Position', [30, 430, 590, 40], 'Parent', fig);
    startScreen();
    
    % Added a variable to keep track of who starts the game
    startingPlayer = ''; % Will be set to either 'player' or 'computer'
    
    function startScreen()
        clf(fig);
        uicontrol('Style', 'text', 'String', 'Willkommen zu Schiffe Versenken!', 'Position', [100, 300, 450, 40], 'FontSize', 16, 'Parent', fig);
        uicontrol('Style', 'pushbutton', 'String', 'Spiel starten', 'Position', [275, 200, 100, 40], 'Callback', @initializeGame, 'Parent', fig);
        uicontrol('Style', 'pushbutton', 'String', 'Spiel beenden', 'Position', [275, 150, 100, 40], 'Callback', @(src, event)close(fig), 'Parent', fig);
    end

    function initializeGame(~, ~)
        clf(fig);
        playerBoard = zeros(gridSize);
        computerBoard = zeros(gridSize);
        numPlayerShips = 0;
        setupGameUI();
        placeComputerShips();
        decideStartingPlayer(); % Decide who starts the game but do not initiate attack
    end
    
    % New function to decide who starts without initiating an attack
    function decideStartingPlayer()
        if rand < 0.5
            startingPlayer = 'player';
            updateStatus('Du beginnst das Spiel. Platziere deine Schiffe.');
        else
            startingPlayer = 'computer';
            updateStatus('Der Computer beginnt. Bitte platziere deine Schiffe.');
            % Do not start computer attack immediately
        end
    end

    function setupGameUI()
        statusText = uicontrol('Style', 'text', 'String', 'Platziere deine Schiffe (5 benötigt).', 'Position', [30, 430, 590, 40], 'Parent', fig);
        for i = 1:gridSize
            for j = 1:gridSize
                playerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [30+(j-1)*buttonSize(1), 360-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@playerBoardCallback, i, j});
                computerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [350+(j-1)*buttonSize(1), 360-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@computerBoardCallback, i, j}, 'Enable', 'off');
            end
        end
        uicontrol('Style', 'pushbutton', 'String', 'Neustart', 'Position', [30, 470, 100, 20], 'Parent', fig, 'Callback', @(src,event)startScreen());
        uicontrol('Style', 'pushbutton', 'String', 'Spiel beenden', 'Position', [140, 470, 100, 20], 'Parent', fig, 'Callback', @(src, event)close(fig));
    end

    function playerBoardCallback(src, ~, row, col)
        if numPlayerShips < 5 && playerBoard(row, col) == 0
            playerBoard(row, col) = 1;
            set(src, 'String', 'S', 'Enable', 'off', 'BackgroundColor', [0.5, 1, 0.5]); % Light green for unhit ship
            numPlayerShips = numPlayerShips + 1;
            if numPlayerShips == 5
                updateStatus('Alle Schiffe platziert. Warte auf den Gegner.');
                set(arrayfun(@(x) x, computerButtons), 'Enable', 'on');
                if strcmp(startingPlayer, 'computer')
                    pause(1); % Short delay before computer starts if it is the starting player
                    computerAttack(); % Initiate computer attack only after player has placed all ships
                end
            else
                updateStatus(sprintf('Platziere deine Schiffe (%d/5).', numPlayerShips));
            end
        end
    end


    function computerBoardCallback(src, ~, row, col)
        set(src, 'Enable', 'off'); % Disable the button to prevent multiple clicks
        if computerBoard(row, col) == 0
            computerBoard(row, col) = 3; % Miss
            set(src, 'String', '~', 'BackgroundColor', [0.678, 0.847, 0.902]); % Light blue
            updateStatus('Fehlschuss!');
        elseif computerBoard(row, col) == 1
            computerBoard(row, col) = 2; % Hit
            set(src, 'String', 'X', 'ForegroundColor', 'white', 'BackgroundColor', 'red');
            updateStatus('Treffer!');
            if checkWin(computerBoard)
                updateStatus('Spieler gewinnt! Alle Schiffe versenkt.');
                disableBoard(computerButtons);
                showVictoryScreen('Spieler');
            end
        end
        computerAttack();
    end


    function placeComputerShips()
        numShipsPlaced = 0;
        while numShipsPlaced < 5
            row = randi(gridSize);
            col = randi(gridSize);
            if computerBoard(row, col) == 0
                computerBoard(row, col) = 1;
                numShipsPlaced = numShipsPlaced + 1;
            end
        end
    end

    function computerAttack()
        row = randi(gridSize);
        col = randi(gridSize);
        if playerBoard(row, col) <= 1
            if playerBoard(row, col) == 1
                playerBoard(row, col) = 2; % Mark as hit
                set(playerButtons(row, col), 'String', 'X', 'ForegroundColor', 'white', 'BackgroundColor', 'red');
                updateStatus('Computer hat getroffen!');
                pause(2); % Delay of 2 seconds
                if checkWin(playerBoard)
                    updateStatus('Computer gewinnt! Alle Schiffe versenkt.');
                    disableBoard(playerButtons);
                    showVictoryScreen('Computer');
                else
                    computerAttack();
                end
            else
                playerBoard(row, col) = 3; % Mark as miss
                set(playerButtons(row, col), 'String', '~', 'BackgroundColor', [0.678, 0.847, 0.902]); % Light blue
                updateStatus('Computer hat verfehlt.');
                pause(2); % Delay of 2 seconds
            end
        else
            computerAttack();
        end
    end

    function win = checkWin(board)
        win = all(board(:) ~= 1); % Win condition: no '1's left on the board
    end

    function disableBoard(buttons)
        for i = 1:numel(buttons)
            set(buttons(i), 'Enable', 'off');
        end
    end

    function updateStatus(message)
        set(statusText, 'String', message);
    end

    function showVictoryScreen(winner)
        clf(fig);
        message = sprintf('%s gewinnt!', winner);
        uicontrol('Style', 'text', 'String', message, 'Position', [100, 300, 450, 40], 'FontSize', 16, 'Parent', fig);
        uicontrol('Style', 'pushbutton', 'String', 'Neues Spiel', 'Position', [275, 200, 100, 40], 'Callback', @(src,event)startScreen(), 'Parent', fig);
        uicontrol('Style', 'pushbutton', 'String', 'Spiel beenden', 'Position', [275, 150, 100, 40], 'Callback', @(src, event)close(fig), 'Parent', fig);
    end
end