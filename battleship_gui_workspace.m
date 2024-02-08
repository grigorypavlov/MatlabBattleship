function battleship_gui_v07
    fig = figure('Name', 'Schiffe Versenken', 'NumberTitle', 'off', 'Resize', 'off', 'Position', [100, 100, 680, 500],'CloseRequestFcn', @stopMusicAndClose);
    gridSize = 10;
    buttonSize = [30, 30];
    playerBoard = zeros(gridSize);
    computerBoard = zeros(gridSize);
    playerButtons = gobjects(gridSize, gridSize);
    computerButtons = gobjects(gridSize, gridSize);
    shipSizes = [5, 4, 3, 2, 2]; % Array of ship sizes for both player and computer
    currentShipSizeIndex = 1; % To track which ship size the player is currently placing
    shipOrientation = 'horizontal'; % Default orientation
    numPlayerShips = 0;
    statusText = uicontrol('Style', 'text', 'Position', [30, 430, 590, 40], 'Parent', fig);
    startScreen();
    startingPlayer = ''; % Will be set to either 'player' or 'computer'
    global waterSound bombSound startgame;
    
    function playBackgroundMusic()
        audioFilePath = 'Menu.mp3';
        if ~isfile(audioFilePath)
            error('Die Audiodatei wurde nicht gefunden: %s', audioFilePath);
        end
        [y, Fs] = audioread(audioFilePath);
        volumeFactor = 0.1;
        y = y * volumeFactor;
        player = audioplayer(y, Fs);
        set(player, 'StopFcn', @(src, event)play(src));
        play(player);
        set(fig, 'UserData', player);
    end

    function stopMusicAndClose(src, event)
        player = get(fig, 'UserData');
        if ~isempty(player) && isvalid(player)
            stop(player);
        end
        delete(gcf);
    end

    function startScreen()
        clf(fig); % Clear the Figure object for the start screen
        playBackgroundMusic();
    
        % Load and resize the background image to fit the figure size
        bg = imread('Titlescreen.jpg');
        bgResized = imresize(bg, [500, 650]); % Resize the image to 500x650 pixels
    
        % Create axes that fill the figure
        ax = axes('Parent', fig, 'Position', [0 0 1 1]);
        imagesc(ax, bgResized);
        axis(ax, 'off'); % Turn off axis lines and labels
        uistack(ax, 'bottom'); % Send the axes to the bottom layer
    
        % UI elements for the start screen
        uicontrol('Style', 'text', 'String', 'Welcome to Battleship!', 'Position', [190, 0, 300, 30], 'FontSize', 20, 'Parent', fig, 'BackgroundColor', [0.678, 0.847, 0.902], 'ForegroundColor', [0, 0, 0]);
        % Centrally aligned 'Start Game' button
        uicontrol('Style', 'pushbutton', 'String', 'Start Game', 'Position', [290, 220, 100, 40], 'Callback', @initializeGame, 'Parent', fig, 'BackgroundColor', [0.678, 0.847, 0.902], 'ForegroundColor', [0, 0, 0]);
        % Centrally aligned 'Exit Game' button, adjusted for aesthetic vertical spacing
        uicontrol('Style', 'pushbutton', 'String', 'Exit Game', 'Position', [290, 170, 100, 40], 'Callback', @(src, event)close(fig), 'Parent', fig, 'BackgroundColor', [0.678, 0.847, 0.902], 'ForegroundColor', [0, 0, 0]);
    end


    function initializeGame(~, ~)
        clf(fig); % Bereinige das Figure-Objekt, um die UI zurückzusetzen

        % Setze die Spielbretter zurück
        playerBoard = zeros(gridSize);
        computerBoard = zeros(gridSize);

        % Setze die Schiffsplatzierungsvariablen zurück
        numPlayerShips = 0;
        currentShipSizeIndex = 1; % Zurück zum ersten Schiff
        shipOrientation = 'horizontal'; % Standardorientierung zurücksetzen

        % Laden der Soundeffekte und Initialisieren der audioplayer-Objekte
        [y1, Fs1] = audioread('wasser.mp3');
        waterSound = audioplayer(y1, Fs1);

        [y2, Fs2] = audioread('bomb.mp3');
        bombSound = audioplayer(y2, Fs2);

        setupGameUI(); % Initialisiere die Spiel-UI neu
        placeComputerShips(); % Platziere die Schiffe des Computers neu
        decideStartingPlayer(); % Entscheide neu, wer das Spiel beginnt
    end
    
    % New function to decide who starts without initiating an attack
    function decideStartingPlayer()
        if rand < 0.5
            startingPlayer = 'player';
            updateStatus('Du beginnst das Spiel. Platziere dein 5-Felder Schiff.');
        else
            startingPlayer = 'computer';
            updateStatus('Der Computer beginnt. Bitte platziere dein 5-Felder Schiff.');
            % Do not start computer attack immediately
        end
    end
    
    function setupGameUI()
        % Status Text at the top for clear visibility
        statusText = uicontrol('Style', 'text', 'String', 'Platziere deine Schiffe (5 benötigt).', 'Position', [30, 450, 590, 40], 'FontSize', 12, 'Parent', fig);
    
        % Adjust the placement of player and computer grids for better visual separation
        % Player Grid
        uicontrol('Style', 'text', 'String', 'Spielfeld', 'Position', [30, 430, 300, 20], 'Parent', fig);
        % Computer Grid
        uicontrol('Style', 'text', 'String', 'Computerfeld', 'Position', [350, 430, 300, 20], 'Parent', fig);
    
        % Generate buttons for player and computer grids
        for i = 1:gridSize
            for j = 1:gridSize
                playerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [30+(j-1)*buttonSize(1), 380-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@playerBoardCallback, i, j});
                computerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [350+(j-1)*buttonSize(1), 380-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@computerBoardCallback, i, j}, 'Enable', 'off');
            end
        end

        % Control Buttons for actions
        uicontrol('Style', 'pushbutton', 'String', 'Neustart', 'Position', [30, 20, 100, 30], 'Parent', fig, 'Callback', @(src,event)startScreen());
        uicontrol('Style', 'pushbutton', 'String', 'Spiel beenden', 'Position', [140, 20, 100, 30], 'Parent', fig, 'Callback', @(src, event)close(fig));
    
        % Orientation Buttons for ship placement
        uicontrol('Style', 'pushbutton', 'String', 'Horizontal', 'Position', [350, 20, 100, 30], 'Parent', fig, 'Callback', @(src,event)setOrientation('horizontal'));
        uicontrol('Style', 'pushbutton', 'String', 'Vertikal', 'Position', [460, 20, 100, 30], 'Parent', fig, 'Callback', @(src,event)setOrientation('vertical'));
    end


    function setOrientation(orientation)
        shipOrientation = orientation;
        updateStatus(sprintf('Ausrichtung gesetzt zu %s. Platziere dein Schiff.', orientation));
    end

    function playerBoardCallback(~, ~, row, col)
        % Überprüfe, ob wir noch Schiffe zu platzieren haben
        if numPlayerShips >= length(shipSizes)
            updateStatus('Alle Schiffe sind bereits platziert.');
            return;
        end

        shipSize = shipSizes(currentShipSizeIndex); % Aktuelle Schiffgröße
        if strcmp(shipOrientation, 'horizontal')
            % Überprüfe, ob das Schiff horizontal platziert werden kann
            if col + shipSize - 1 > gridSize || ~isSpaceFree(playerBoard, row, col, shipSize, 1)
                updateStatus('Schiff passt nicht in diese Position (horizontal) oder Platz ist bereits belegt.');
                return;
            end
            % Platziere das Schiff
            for i = 0:(shipSize - 1)
                playerBoard(row, col + i) = 1;
                set(playerButtons(row, col + i), 'String', 'S', 'Enable', 'off', 'BackgroundColor', [0.5, 1, 0.5]);
            end
        else
            % Überprüfe, ob das Schiff vertikal platziert werden kann
            if row + shipSize - 1 > gridSize || ~isSpaceFree(playerBoard, row, col, shipSize, 2)
                updateStatus('Schiff passt nicht in diese Position (vertikal) oder Platz ist bereits belegt.');
                return;
            end
            % Platziere das Schiff
            for i = 0:(shipSize - 1)
                playerBoard(row + i, col) = 1;
                set(playerButtons(row + i, col), 'String', 'S', 'Enable', 'off', 'BackgroundColor', [0.5, 1, 0.5]);
            end
        end

        % Aktualisiere die Anzahl der platzierten Schiffe
        numPlayerShips = numPlayerShips + 1;
        if numPlayerShips == length(shipSizes)
            updateStatus('Alle Schiffe platziert. Warte auf den Gegner.');
            set(arrayfun(@(x) x, computerButtons), 'Enable', 'on');
            if strcmp(startingPlayer, 'computer')
                pause(1); % Kurze Verzögerung
                computerAttack(); % Der Computer startet seinen Angriff
            end
        else
            currentShipSizeIndex = currentShipSizeIndex + 1;
            updateStatus(sprintf('Platziere dein %d-Felder Schiff.', shipSizes(currentShipSizeIndex)));
        end
    end
    
    function computerBoardCallback(src, ~, row, col)
        set(src, 'Enable', 'off'); % Disable the button to prevent multiple clicks
        if computerBoard(row, col) == 0
            computerBoard(row, col) = 3; % Miss
            set(src, 'String', '~', 'BackgroundColor', [0.678, 0.847, 0.902]); % Light blue
            updateStatus('Fehlschuss!');
            play(waterSound); % Spielt den Fehlschusssound
            computerAttack(); % Now it's computer's turn
        elseif computerBoard(row, col) == 1
            computerBoard(row, col) = 2; % Hit
            set(src, 'String', 'X', 'ForegroundColor', 'white', 'BackgroundColor', 'red');
            updateStatus('Treffer!');
            play(bombSound); % Spielt den Treffersound
            % Do not call computerAttack here to allow for another player turn
            if checkWin(computerBoard)
                updateStatus('Spieler gewinnt! Alle Schiffe versenkt.');
                disableBoard(computerButtons);
                showVictoryScreen('Spieler');
            end
        end
        % No else condition needed for calling computerAttack, as it's called only on miss
    end



    function placeComputerShips()
        shipSizes = [5, 4, 3, 2, 2]; % Array of ship sizes
        for shipSize = shipSizes
            placed = false;
            while ~placed
                orientation = randi([1, 2]); % 1 for horizontal, 2 for vertical
                if orientation == 1 % Horizontal
                    row = randi(gridSize);
                    col = randi([1, gridSize - shipSize + 1]);
                else % Vertical
                    row = randi([1, gridSize - shipSize + 1]);
                    col = randi(gridSize);
                end
            
                % Check if the space is free for the ship
                if isSpaceFree(computerBoard, row, col, shipSize, orientation)
                    % Place the ship
                    for i = 0:(shipSize - 1)
                        if orientation == 1
                            computerBoard(row, col + i) = 1;
                        else
                            computerBoard(row + i, col) = 1;
                        end
                    end
                    placed = true;
                end
            end
        end
    end

function free = isSpaceFree(board, row, col, size, orientation)
    free = true;
    for i = 0:(size - 1)
        if orientation == 1
            if board(row, col + i) ~= 0
                free = false;
                break;
            end
        else
            if board(row + i, col) ~= 0
                free = false;
                break;
            end
        end
    end
end


    function computerAttack()
        pause(1);
        [row, col] = findBestMove();
        if playerBoard(row, col) <= 1
            if playerBoard(row, col) == 1
                playerBoard(row, col) = 2; % Mark as hit
                set(playerButtons(row, col), 'String', 'X', 'ForegroundColor', 'white', 'BackgroundColor', 'red');
                updateStatus('Computer hat getroffen!');
                play(bombSound); % Spielt den Treffersound
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
                play(waterSound); % Spielt den Fehlschusssound
                pause(1); % Delay of 2 seconds
            end
        else
            computerAttack();
        end
    end


    function [row, col] = findBestMove()
        persistent mode; % Persistente Variable, um den Modus zwischen den Aufrufen zu speichern
    
        % Überprüfe, ob der Modus bereits festgelegt ist
        if isempty(mode)
            % Wenn nicht, setze den Modus auf 'hunt'
            mode = 'hunt';
        end
    
        if strcmp(mode, 'hunt')
            % Im Hunt-Modus wähle zufällige Positionen im Schachbrettmuster
            row = randi(gridSize); % Wähle eine zufällige Zeile
            if mod(row, 2) == 0 % Wenn die Zeile gerade ist
                col = round(randi([2, gridSize])/2)*2; % Wähle eine zufällige gerade Spalte zwischen 2 und gridSize
            else % Wenn die Zeile ungerade ist
                col = round((randi([1, gridSize-1])-1)/2)*2 + 1; % Wähle eine zufällige ungerade Spalte zwischen 1 und gridSize-1
            end
        else
            % Im Target-Modus suche nach angeschossenen Schiffen
            [row, col] = findTarget();
        end
    end
    
    
    
    function [row, col] = findTarget()
        % Waiting for Francesco to implement sinking ship logic
        row = randi(gridSize);
        col = randi(gridSize);
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
        clf(fig); % Clear the Figure window
        
        % Load and resize the background image to fit the figure size
        bg = imread('Endscreen.png');
        bgResized = imresize(bg, [500, 650]); % Resize the image to 500x650 pixels
    
        % Create axes that fill the figure
        ax = axes('Parent', fig, 'Position', [0 0 1 1]);
        imagesc(ax, bgResized);
        axis(ax, 'off'); % Turn off axis lines and labels
        uistack(ax, 'bottom'); % Send the axes to the bottom layer
    
        % Centered victory message with larger font
        uicontrol('Style', 'text', 'String', sprintf('%s gewinnt!', winner), 'Position', [100, 250, 450, 60], 'FontSize', 20, 'FontWeight', 'bold', 'Parent', fig, 'HorizontalAlignment', 'center', 'BackgroundColor', 'none', 'ForegroundColor', [1, 1, 1]);
    
        % Button for a new game
        uicontrol('Style', 'pushbutton', 'String', 'Neues Spiel', 'Position', [265, 170, 150, 50], 'FontSize', 12, 'Parent', fig, 'Callback', @(src,event)startScreen(), 'BackgroundColor', [0, 0, 0, 0.5], 'ForegroundColor', [1, 1, 1]);
    
        % Button to end the game
        uicontrol('Style', 'pushbutton', 'String', 'Spiel beenden', 'Position', [265, 110, 150, 50], 'FontSize', 12, 'Parent', fig, 'Callback', @(src, event)close(fig), 'BackgroundColor', [0, 0, 0, 0.5], 'ForegroundColor', [1, 1, 1]);
    end
end


