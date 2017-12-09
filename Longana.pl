
%----------------------------------------------------------------------------------------------------
%   Name:     Bishal Regmi
%	Project:  Longana
%	Class:	  OPL
%   Date:     December 8, 2017
%----------------------------------------------------------------------------------------------------



%%----------------------------------------------------------------------------------------------------
%%-----------------------------------Core Predicates ---------------------------------------------
%%----------------------------------------------------------------------------------------------------



%----------------------------------------------------------------------------------------------------
%   Predicate Name: longana
%   Purpose: To kick off the game and handle data loading for resumed games.
%   Parameters: none
%   Local Variables: choice
%----------------------------------------------------------------------------------------------------
longana(_):- write("Welcome to Longana!"),nl,
    write("Would you like to load a game?(y/n)"),
    read(Choice),
    validateYesNoChoice(Choice),
    startGame(Choice).
longana(_):- longana(_).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: startGame
%   Purpose: To either start a new tournament or load a file for the tournament.
%   Parameters: choices for whether to start a new gam (y) or load (n)
%   Local Variables: None
%----------------------------------------------------------------------------------------------------
startGame(y):- getTournamentFromFile(Tournament),
    loadTournament(Tournament).
startGame(n):- newTournament(_).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: newTournament
%   Purpose: To start a new Tournament.
%   Parameters: none
%   Local Variables: Score to get the tournament score
%----------------------------------------------------------------------------------------------------
newTournament(_) :- getTournamentScore(Score),
    % Round count is 1 because it starts from 1, everything else are default values for respective parameters
    playTournament(Score, 1, 0, 0, false).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getTournamentScore
%   Purpose: To get validates tournament score for the round.
%   Parameters: Score, to return the tournament score
%   Local Variables: Data, to hold the user input
%----------------------------------------------------------------------------------------------------
getTournamentScore(Score) :- write("Please enter the tournament score: "),
    read(Data),
    number(Data),
    Score = Data.
getTournamentScore(Score) :- nl,write("Invalid Input. Try again!"),nl,
    getTournamentScore(NewScore),
    Score = NewScore.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: loadTournament
%   Purpose: To load the tournament from a serialized file.
%   Parameters: Tournament, to store the tournament to return after loading
%   Local Variables: choice
%----------------------------------------------------------------------------------------------------
loadTournament(Tournament):- getTurn(Tournament, Turn),
    %if turn is an empty list, then the first player hasn't been determined, thus init the round
    Turn = [],
    Tournament = [TournScore,RoundCount,Computer, ComputerScore, Human,HumanScore, _, Stock, _, _],
    initRound(TournScore, RoundCount, Stock, Human, HumanScore, Computer, ComputerScore, NewGameState),
    resumeTournament(NewGameState).
% else on the other case, load everything and resume the tournament
loadTournament(Tournament) :- Tournament = [TournScore,RoundCount,NewComputer, ComputerScore, NewHuman,HumanScore, Layout, NewStock, Passed, NextPlayer],
    delete(Layout, r, NewLayout),
    delete(NewLayout, l, NewNewLayout),
    NewTournament = [TournScore,RoundCount,NewComputer, ComputerScore, NewHuman,HumanScore, NewNewLayout, NewStock, Passed, NextPlayer],
    resumeTournament(NewTournament).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getTournamentFromFile
%   Purpose: To read the tournament from a serialized file.
%   Parameters: Tournament, to store the tournament to return after loading
%   Local Variables: FileName to get the input from user and Content to fetch the content of the file
%----------------------------------------------------------------------------------------------------
getTournamentFromFile(Tournament):- write("Enter the filename to load: "),
    read(FileName),
    with_output_to(atom(AFileName), write(FileName)),
    string_concat("/Users/beeshall/Documents/Fall-2018/OPL/Longana_Prolog/", AFileName, FullPath),
    exists_file(FullPath),
    open(FullPath,read,File),
    read(File, Content),
    close(File),
    Tournament = Content.
getTournamentFromFile(Tournament):- getTournamentFromFile(NewTournament),
    Tournament = NewTournament.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: playTournament
%   Purpose: To play the tournament.
%   Parameters: TournScore, RoundCount, HumanScore, CompScore, and indication if player decided to save and quit
%   Local Variables: None
%----------------------------------------------------------------------------------------------------
%if player decided to save and quit
playTournament(_,_,_,_,true).
%if the torunament has ended, stop
playTournament(TournScore, _, HumanScore, CompScore,_):- checkIfTournamentEnded(TournScore, HumanScore, CompScore).
%if not generate a new round and continue
playTournament(TournScore, RoundCount, HumanScore, CompScore,_):-
    generateNewRound(TournScore, RoundCount, HumanScore, CompScore, GameState),
    resumeTournament(GameState).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: resumeTournament
%   Purpose: To resume the tournament with the given gamestate.
%   Parameters: gamestate, current game state
%   Local Variables: None
%----------------------------------------------------------------------------------------------------
resumeTournament(GameState) :- askIfSaveAndQuit(Choice),
    runRound(GameState, [CScore,HScore|_], 0, Choice, SaveAndQuit),
    GameState = [TournScore,RoundCount,_, ComputerScore, _,HumanScore, _, _, _, _],
    NewHumanScore is HumanScore + HScore,
    NewCompScore is ComputerScore+CScore,
    NewRoundCount is RoundCount+1,
    playTournament(TournScore, NewRoundCount, NewHumanScore, NewCompScore, SaveAndQuit).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: checkIfTournamentEnded
%   Purpose: To check if the tournament ended.
%   Parameters: tournament score, human score and computer score
%   Local Variables: None
%----------------------------------------------------------------------------------------------------
checkIfTournamentEnded(TournScore, HumanScore, CompScore) :- HumanScore > TournScore,
    nl,write("Torunament ended!"),nl,
    write("Human won the tournament with the score of "),write(HumanScore),nl,
    write("Computer had a score of "),write(CompScore),nl.
checkIfTournamentEnded(TournScore, HumanScore, CompScore) :- CompScore > TournScore,
    nl,write("Torunament ended!"),nl,
    write("Computer won the tournament with the score of "),write(CompScore),nl,
    write("Human had a score of "),write(HumanScore),nl.


%----------------------------------------------------------------------------------------------------
%   Predicate Name: generateNewRound
%   Purpose: To generate a new fresh round.
%   Parameters: TournScore, RoundCount, HumanScore, ComputerScore and gamestate to store the game in
%   Local Variables: None
%----------------------------------------------------------------------------------------------------
generateNewRound(TournScore, RoundCount, HumanScore, ComputerScore, GameState) :- generateNums(6, Pips),
    generateAllDominoes(Pips, Dominoes),
    random_permutation(Dominoes,Stock),
    getNDominoesFromStock(8, Stock, UpdatedStock1, HumanHand),
    write("Human Hand: "),write(HumanHand),nl,
    getNDominoesFromStock(8, UpdatedStock1, UpdatedStock2,  ComputerHand),
    write("Computer Hand: "),write(ComputerHand),nl,nl,
    initRound(TournScore, RoundCount, UpdatedStock2, HumanHand, HumanScore, ComputerHand, ComputerScore, NewGameState),
    GameState = NewGameState.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: initRound
%   Purpose: To initialize the round determinig the first player and setiing the engine.
%   Parameters: TournScore, RoundCount, Stock, HumanHand, HumanScore, ComputerHand, ComputerScore and GameState to store the new state.
%   Local Variables: None
%----------------------------------------------------------------------------------------------------
initRound(TournScore, RoundCount, Stock, HumanHand, HumanScore, ComputerHand, ComputerScore, GameState) :-  getEngineFromRoundCount(RoundCount, 7, Engine),
    determineFirstPlayer(Stock, HumanHand, ComputerHand, Engine, human, NextPlayer, NewStock, NewHuman, NewComputer),
    Layout = [Engine],
    GameState = [TournScore,RoundCount,NewComputer, ComputerScore, NewHuman,HumanScore, Layout, NewStock, false, NextPlayer].

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getEngineFromRoundCount
%   Purpose: To get the engine for the respective round.
%   Parameters: RoundCount, PipCount is maximum count of pips used, Engine is to store the return value of the engine
%   Local Variables: None
%----------------------------------------------------------------------------------------------------
getEngineFromRoundCount(RoundCount, PipCount, Engine) :- ModVal is RoundCount mod PipCount,
    getEngine(ModVal, PipCount, GameEngine),
    Engine = GameEngine.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getEngine
%   Purpose: To get the engine from the given vals.
%   Parameters: Modval to modulus value from round count, PipCount is maximum count of pips used, Engine is to store the return value of the engine
%   Local Variables: None
%---------------------------------------------------------------------------------------------------- 
getEngine(0, _, [0,0]).
getEngine(ModVal, MaxPip, Engine):- Pip is MaxPip - ModVal,
    Engine = [Pip,Pip]. 

%----------------------------------------------------------------------------------------------------
%   Predicate Name: determineFirstPlayer
%   Purpose: To determine the first player for the round.
%   Parameters: Stock , Human, Computer , Engine, CurrentPlayer, NextPlayer
%   Local Variables: None
%----------------------------------------------------------------------------------------------------  
%if human has the engine already
determineFirstPlayer(Stock , Human, Computer , Engine, _, NextPlayer, Stock,NewHuman,NewComputer):- member(Engine, Human),
    write("Human has the engine!"),nl,
    delete(Human, Engine, NewHuman),
    NewComputer = Computer,
    NextPlayer = computer.   
%if computer has the engine already
determineFirstPlayer(Stock , Human, Computer , Engine, _, NextPlayer, Stock,NewHuman,NewComputer):- member(Engine, Computer),
    write("Computer has the engine!"),nl,
    delete(Computer, Engine, NewComputer),
    NewHuman = Human,
    NextPlayer = human.  
%Both Player draw from stock
determineFirstPlayer([First,Second|Rest] , Human, Computer, Engine, _, NextPlayer, UpdatedStock, UpdatedHuman, UpdatedComputer):- append(Human, [First], NewHuman),
    write("Human drew "), write(First), write(" from the stock!"),nl,
    append(Computer, [Second], NewComputer),
    write("Computer drew "), write(Second), write(" from the stock!"),nl,
    determineFirstPlayer(Rest, NewHuman, NewComputer, Engine, _, NewNextPlayer, NewStock, NewUpdatedHuman, NewUpdatedComputer),
    UpdatedStock = NewStock,
    UpdatedHuman = NewUpdatedHuman,
    UpdatedComputer = NewUpdatedComputer,
    NextPlayer = NewNextPlayer.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: runRound
%   Purpose: To kick off the round and run it until the round ends.
%   Parameters: current game state, new game state for return value, passcount, save an quit option, saveandquit to return value
%   Local Variables: none
%----------------------------------------------------------------------------------------------------  
%if the player decided to save and quit
runRound(OldGameState, OldGameState,_, y, true) :-OldGameState = [TournScore,RoundCount,NewComputer, ComputerScore, NewHuman,HumanScore, Layout, NewStock, Passed, NextPlayer],
    NewLayout = [l|Layout],
    append(NewLayout, [r], FinalLayout),
    open("/Users/beeshall/Documents/Fall-2018/OPL/Longana_Prolog/game.txt",write, Stream),
    write(Stream,[TournScore,RoundCount,NewComputer, ComputerScore, NewHuman,HumanScore, FinalLayout, NewStock, Passed, NextPlayer]),
    write(Stream,"."),
    close(Stream).
%if the round ended
runRound(OldGameState, RoundResults, PassCount, _, false) :- OldGameState = [_,_,CompHand, _, HumanHand ,_, _, Stock, _, _],
    checkIfRoundEnded(Stock, HumanHand, CompHand, PassCount),nl,
    write("The round has ended!"),nl,
    calculateRoundScore(OldGameState, CompScore, HumanScore ),
    RoundResults = [CompScore,HumanScore]. 
%continue round with ususal flow
runRound(OldGameState, NewGameState, PassCount, n, SaveAndQuit) :- getLayout(OldGameState,Layout),
    getStock(OldGameState, Stock),
    displayGameState(Layout,Stock),
    playRound(OldGameState, NewState),
    getPlayerPassed(NewState, Passed),
    updatePassCount(Passed, PassCount, NewPassCount),
    askIfSaveAndQuit(Choice),
    runRound( NewState, NewestGameState, NewPassCount, Choice, NewSaveAndQuit),
    NewGameState = NewestGameState,
    SaveAndQuit = NewSaveAndQuit. 

%----------------------------------------------------------------------------------------------------
%   Predicate Name: playRound
%   Purpose: To decide the next player and get the respective move.
%   Parameters: current game state
%   Local Variables: Turn to the the current turn
%----------------------------------------------------------------------------------------------------  
%human player
playRound(OldGameState, NewGameState) :- getTurn(OldGameState, Turn),
    Turn = human,
    getHumanMenuAction(OldGameState, NewState, false),
    NewGameState = NewState.
%computer player
playRound(OldGameState, NewGameState) :- getTurn(OldGameState, Turn),
    Turn = computer,    
    getComputerMove(OldGameState, NewState, false),
    NewGameState = NewState.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: checkIfRoundEnded
%   Purpose: To check if round ended.
%   Parameters: stock, human hand, computer hand, passcount
%   Local Variables: none
%----------------------------------------------------------------------------------------------------  
%human hand is empty
checkIfRoundEnded(_, [], _, _).
%computer hand is empty
checkIfRoundEnded(_, _, [], _).
%stock is empty and both player passed
checkIfRoundEnded([],_, _, PassCount):- PassCount>2. 

%----------------------------------------------------------------------------------------------------
%   Predicate Name: calculateRoundScore
%   Purpose: To calculate the round score.
%   Parameters: game state, computer score and human score
%   Local Variables: choice
%---------------------------------------------------------------------------------------------------- 
calculateRoundScore(GameState, CompScore, HumanScore):- getHumanHand(GameState, HumanHand),
    getComputerHand(GameState, ComputerHand),
    getHandSum(HumanHand, HumanSum),
    getHandSum(ComputerHand, CompSum),
    write("Human Hand Sum: "),write(HumanSum),nl,
    write("Computer Hand Sum: "),write(CompSum),nl,
    determineRoundWinner(CompSum, HumanSum, CScore, HScore),
    CompScore = CScore,
    HumanScore = HScore.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: determineRoundWinner
%   Purpose: To determine the winner of the round.
%   Parameters: Compute hand Sum, Human hand Sum, human score, Compute score
%   Local Variables: choice
%---------------------------------------------------------------------------------------------------- 
determineRoundWinner(CompSum, HumanSum, 0, CompSum):- CompSum >HumanSum,
    write("Human wins the round with the score of "),write(CompSum),nl.
determineRoundWinner(CompSum, HumanSum, HumanSum, 0):- HumanSum >CompSum,
    write("Computer wins the round with the score of "),write(HumanSum),nl.
determineRoundWinner(CompSum, HumanSum, 0, 0):- HumanSum = CompSum,
    write("The round ended as a draw!"),nl.


%----------------------------------------------------------------------------------------------------
%   Predicate Name: getHumanMenuAction
%   Purpose: To display human game meni.
%   Parameters: GameState, New game State, Drawn - if previous player drew a tile from stock
%   Local Variables: none
%----------------------------------------------------------------------------------------------------  
getHumanMenuAction(GameState, NewState, Drawn) :-  getHumanHand(GameState, Hand),
    write("----------------------------------------------------------"),
    nl,
    write("Human Hand:"),
    nl,
    write(Hand),
    nl,
    write("----------------------------------------------------------"),
    nl,
    nl, write("----------------------------------------------------------"),nl,
	write("Please select one of the following options: "),nl,
	write("1. Make a move"),nl,
	write("2. Draw from stock"),nl,
	write("3. Hint??"),nl,
	write("----------------------------------------------------------"),nl,nl,
    read(Choice),
    number(Choice),
    getHumanChoiceAction(Choice, GameState, NewGameState, Drawn),
    NewState = NewGameState.
getHumanMenuAction(GameState, NewState, Drawn) :-  write("Invalid menu choice, try again!"),
    getHumanMenuAction(GameState, NewGameState, Drawn),
    NewState = NewGameState.
    
%----------------------------------------------------------------------------------------------------
%   Predicate Name: getHumanChoiceAction
%   Purpose: To get the human move based on the selected menu option.
%   Parameters: menu choice, GameState, NewGameState, Drawn
%----------------------------------------------------------------------------------------------------  
%user selected make a move
%check if has a valid move, and then let play
getHumanChoiceAction(1, GameState, NewState,_ ):- GameState = [_, _, _, _, HumanHand, _, Layout, _, Passed, _],
    playerHasAnyMoves(Layout, HumanHand, Passed , l , r),
    playHuman(GameState, NewGameState),
    NewState = NewGameState.
%if human does't have a valid move, draw from stock automatically
getHumanChoiceAction(1, GameState, NewState, Drawn) :- nl,write("You don't have any playable moves in hand!"),nl,
    getHumanChoiceAction(2,GameState, NewGameState, Drawn),
    NewState = NewGameState.
%draw from stock
%if stock is empty and user wants to draw, automatically pass
getHumanChoiceAction(2, GameState, NewGameState, _ ) :- getStock(GameState, Stock),
    Stock = [],
    write("You can't draw a tile because stock is empty! Your turn will now be passed"), nl,
    passTurn(computer, GameState, NewState),
    NewGameState = NewState. 
%if human wants to draw and arleady has moves
getHumanChoiceAction(2, GameState, NewGameState, Drawn) :- GameState = [_,_,_, _, HumanHand ,_, Layout, _, Passed, _],
    playerHasAnyMoves(Layout, HumanHand, Passed , l , r),
    write("You already have valid moves in hand"),nl,
    getHumanMenuAction(GameState, NewState, Drawn),
    NewGameState = NewState.
%if human wants to draw and but has already drawn
getHumanChoiceAction(2, GameState, NewGameState, true) :- nl, write("You already drew from stock! You don't have any playable tiles either. So your turn will be passed!"), nl,
    passTurn(computer, GameState, NewState),
    NewGameState = NewState.      
%if human wants to draw and can draw                                                                                                                           
getHumanChoiceAction(2, GameState, NewState, false) :- GameState = [TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, Passed, Player],
    drawFromStock(Stock, HumanHand, NewHand, NewStock),
    Stock=[Domino|_],
    write("You drew "), write(Domino), write(" from the stock!"),nl,
    write("Human Hand:"),nl, write(NewHand),nl,
    AfterGameState = [TournScore,RoundNo,CompHand, CompScore, NewHand ,HumanScore, Layout, NewStock, Passed, Player],
    getHumanMenuAction(AfterGameState, NewGameState, true),
    NewState = NewGameState.
% if human asks for a hint
getHumanChoiceAction(3, GameState, NewState, Drawn) :- GameState = [_, _, _, _, HumanHand, _, Layout, _, Passed, _],
	getHint(Layout, HumanHand, Passed, l,r,Hint),
    Hint \= [],
    getHumanMenuAction(GameState, NewGameState, Drawn),
    NewState = NewGameState.
% if human doesn't have any playable moves for hint
getHumanChoiceAction(3, GameState, NewState, Drawn) :- write("You do not have any playable moves in hand!"),nl, 
    getHumanMenuAction(GameState, NewGameState, Drawn),
    NewState = NewGameState.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: playHuman
%   Purpose: To get and play the human move.
%   Parameters: OldGameState, NewGameState
%----------------------------------------------------------------------------------------------------  
playHuman(OldGameState, NewGameState) :- getHumanMove(OldGameState, HumanMove),
    ensurePlayableHumanMove(OldGameState, HumanMove,  Move),
    Move = [Side|Domino],
    getLayout(OldGameState, OldLayout),
    getHumanHand(OldGameState, Hand),
    placeDominoToLayout(Domino, Side, OldLayout, NewLayout),
    delete(Hand, Domino, NewHand),
    OldGameState = [TournScore, RoundNo, CompHand, CompScore, _, HumanScore, _, Stock, _, _],
    NewGameState = [TournScore, RoundNo, CompHand, CompScore, NewHand, HumanScore, NewLayout, Stock, false, computer].

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getHumanMove
%   Purpose: To read the human move and make sure it is valid
%   Parameters: GameState, HumanMove to return the read move
%----------------------------------------------------------------------------------------------------  
getHumanMove(GameState, HumanMove) :- getHumanHand(GameState, Hand),
    readHumanMove(Move),
    checkIfSideValid(Move, GameState, Move1),
    Move1 = [Side1|Domino1],
    getPlayerPassed(GameState, Passed),
    checkIfDominoDouble(Domino1, Double),
    checkIfSideisAllowed(Side1, human, Passed, Double, GameState, Move1, Move2),
    checkIfMoveInHand(Move2, Hand, GameState, [NewSide|NewDomino] ),
    HumanMove = [NewSide|NewDomino].

%----------------------------------------------------------------------------------------------------
%   Predicate Name: readHumanMove
%   Purpose: To read the human move.
%   Parameters: hand,Move - made by the user
%   Local Variables: choice
%----------------------------------------------------------------------------------------------------  
readHumanMove(Move) :- 
    write("Please enter the domino you'd like to play enclosed in [ ] with side (l/r) as the first element. E.g. [l, 1, 6]:: "),
    nl,
    read([Side | Domino]),
    append([Side],Domino, Move).
readHumanMove(Move) :- write("Please follow the correct format and enter your move again!"),nl,
    readHumanMove(NewMove),
    Move = NewMove.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: playerHasAnyMoves
%   Purpose: To check if player has any valid moves.
%   Parameters: Layout, Hand, Passed, Side, OtherSide
%----------------------------------------------------------------------------------------------------  
playerHasAnyMoves(Layout, Hand, Passed, Side, OtherSide) :- getAllPlayableMoves(Layout, Hand, Passed, Side, OtherSide, Moves),
    Moves \= [].
 
%----------------------------------------------------------------------------------------------------
%   Predicate Name: ensurePlayableHumanMove
%   Purpose: To validate the and ensure that the human move is playable .
%   Parameters: GameState, Move to check, New Move if the move wasn't valid
%----------------------------------------------------------------------------------------------------    
ensurePlayableHumanMove(GameState, [Side|Domino], ValidMove) :- getLayout(GameState, Layout),
    validateMove(Domino, Side, Layout, NewDomino),
    NewDomino \= [],
    ValidMove = [Side | NewDomino].
ensurePlayableHumanMove(GameState, _,  ValidMove) :- write("Invalid move, Try again!"), nl,
    getHumanMove(GameState, NewMove),
    ensurePlayableHumanMove(GameState, NewMove, NewValidMove),
    ValidMove = NewValidMove.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getComputerMove
%   Purpose: To get the computer move
%   Parameters: GameState, NewGameState, playerDrawn
%---------------------------------------------------------------------------------------------------- 
%if computer has a playable move in hand
getComputerMove([TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, Passed, _], NewGameState, _) :- write("Computer Hand:"),nl,
    write(CompHand),nl,nl,
    write("Computer's Move: "),nl,
    getHint(Layout, CompHand, Passed, r, l, HintMove),
    HintMove = [Side|Domino],
    placeDominoToLayout(Domino, Side, Layout, NewLayout),
    delete(CompHand, Domino, NewHand),
    NewGameState = [TournScore,RoundNo,NewHand, CompScore, HumanHand ,HumanScore, NewLayout, Stock, false, human].
%if stock is empty and computer doesn't have a move in hand
getComputerMove([TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, _, _], [TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, true, human], _) :- Stock = [],
    write("Computer doesn't have a valid move in hand"),nl,
    write("Stock is empty! So computer passed!"),nl.
%if computer doesn't have a move in hand even after drawing from stock
getComputerMove([TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, _, _], [TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, true, human], true) :- write("Computer still doesn't have any valid move in hand! Computer passed!"),nl.
%if computer doesn't have any valid moves and draws form stock
getComputerMove([TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, Passed, Player], NewGameState, false):- drawFromStock(Stock, CompHand, NewHand, NewStock),
    Stock = [Domino|_],
    write("Computer drew "), write(Domino), write(" from the stock!"),nl,
    getComputerMove([TournScore,RoundNo,NewHand, CompScore, HumanHand ,HumanScore, Layout, NewStock, Passed, Player], NewState, true),
    NewGameState = NewState.  

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getHint
%   Purpose: To get the hint for the current gamestate.
%   Parameters: Layout, Hand, Passed, Side, OtherSide, HintMove to return the move
%---------------------------------------------------------------------------------------------------- 
%get all the valid moves in hand
%get the highest score yielding move in hand
%get the side that yields a better score on the next move
getHint(Layout, Hand, Passed, Side, OtherSide, HintMove) :- getAllPlayableMoves(Layout, Hand, Passed, Side, OtherSide, Moves),
    getHighestYieldingMove(Moves, BestMove),
    BestMove = [_|Domino],
    write(Domino),write(" is the highest score yielding domino in the hand!"),nl,
    getBestSideForMove(Layout, Hand, BestMove, Side, OtherSide, NewMove),
    HintMove = NewMove.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getAllPlayableMoves
%   Purpose: To get all the playable moves at the current game state.
%   Parameters: Layout, Hand, Passed, Side, OtherSide, Moves to return the list of playable moves
%---------------------------------------------------------------------------------------------------- 
%if hand is empty, no moves
getAllPlayableMoves(_, [], _, _, _, []).
%if domino is double or passed, check to see if it can be placed on both sides
getAllPlayableMoves(Layout, [Domino | Rest], Passed, Side, OtherSide, Moves):- (Passed = true; ( checkIfDominoDouble(Domino, Double), Double = true)),
    findPlayableMoveSide(Domino, l, r, Layout, [Side1|_]),
    findPlayableMoveSide(Domino, r, l, Layout, [Side2|_]),
    Side1 \= Side2,                    
    getAllPlayableMoves(Layout, Rest, Passed, Side, OtherSide, NewMoves),
    append(NewMoves, [[a|Domino]], Moves).
%if domino is double and passed but can be placed only on one side
getAllPlayableMoves(Layout, [Domino | Rest], Passed, Side, OtherSide, Moves):- (Passed = true; ( checkIfDominoDouble(Domino, Double), Double = true)),
    findPlayableMoveSide(Domino, OtherSide, Side, Layout, Move),                    
    getAllPlayableMoves(Layout, Rest, Passed, Side, OtherSide, NewMoves),
    append(NewMoves, [Move], Moves).
%if domino is not double or passed
getAllPlayableMoves(Layout, [Domino | Rest], Passed, Side, OtherSide, Moves) :- findPlayableMoveSide(Domino, Side, OtherSide, Layout, Move),
    getAllPlayableMoves(Layout, Rest, Passed, Side, OtherSide, NewMoves),
    append(NewMoves, [Move], Moves).
%recursive call for the rest of the hand
getAllPlayableMoves(Layout, [_ | Rest], Passed, Side, OtherSide, Moves):- getAllPlayableMoves(Layout, Rest, Passed, Side, OtherSide, NewMoves),
    Moves = NewMoves.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: findPlayableMoveSide
%   Purpose: To find the playable side for the given domini.
%   Parameters: Domino, player side, other side, Layout, Move
%---------------------------------------------------------------------------------------------------- 
%if the player side is left
findPlayableMoveSide(Domino, l, r, Layout, [l|Domino]) :- validateMove(Domino, l, Layout, NewDomino),
     NewDomino \= [].
%if the player side is right
findPlayableMoveSide(Domino, r, l, Layout, [r|Domino]) :- validateMove(Domino, r, Layout, NewDomino),
     NewDomino \= [].

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getHighestYieldingMove
%   Purpose: To get the move yielding the highest score.
%   Parameters: Moves, BestMove - to return the best move
%---------------------------------------------------------------------------------------------------- 
%if the playable moves are empty
getHighestYieldingMove([],[]).
%compare every single sum and return the best move
getHighestYieldingMove([Move | Rest], BestMove) :- getHighestYieldingMove( Rest, NewMove),
    compareAndGetBestDomino(Move,NewMove, NewBestMove),
    BestMove = NewBestMove.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: compareAndGetBestDomino
%   Purpose: To compare two dominos based on the sum and return the best domino.
%   Parameters: none
%   Local Variables: choice
%---------------------------------------------------------------------------------------------------- 
compareAndGetBestDomino([], Move, Move).
compareAndGetBestDomino(Move, [], Move).
compareAndGetBestDomino([Side1 | Domino1],[_ | Domino2],NewMove) :- Domino1 = [First1 | [Second1|_]],
    Domino2 = [First2| [Second2|_]],
    (   First1+Second1) >= (First2+Second2),
    NewMove = [Side1 | Domino1].
compareAndGetBestDomino(_,Move,Move).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getBestSideForMove
%   Purpose: To get the best side for the given move.
%   Parameters: Layout, Hand, Move, Side, OtherSide, BestMove
%---------------------------------------------------------------------------------------------------- 
%if move can be placd on any side, get the side that yield best score on the next move
getBestSideForMove(Layout, Hand, [a|Domino], Side, OtherSide, BestMove):- write("However, this domino can be placed on either side!"),nl, getNextMoveScoresAfterPlacement(Layout, Hand, Domino, false, Side, OtherSide, l, LeftScore),
    getNextMoveScoresAfterPlacement(Layout, Hand, Domino, false, Side, OtherSide, r, RightScore),
    write("If played on the LEFT, the next move will yield a score of "),write(LeftScore),write(" and playing on the RIGHT will yield "),write(RightScore), nl,
    getSideBasedOnScore(LeftScore, RightScore, Side, OtherSide, BestSide),
    append([BestSide],Domino, BestMove).
%if move can only be played on one side
getBestSideForMove(_, _, Move, _, _, Move):- Move = [Side|_], write("This domino can be played "),getSideString(Side,String),write(String),nl.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getSideBasedOnScore
%   Purpose: To get the best side given the best score on the next move
%   Parameters: LeftScore, LeftScore, OtherSide, BestSide - to return the best side
%---------------------------------------------------------------------------------------------------- 
%if it yields the same score regardless of side
getSideBasedOnScore(LeftScore, LeftScore, _, OtherSide, OtherSide):- write("Since you yield the same score on the next move regardless of the side you choose, placing it on the "), getSideString(OtherSide, String), write(String), write(" will create more chances of the opponent screwing up!"),nl.  
%if yields best score if placed on left
getSideBasedOnScore(LeftScore, RightScore, _, _,l):-LeftScore > RightScore, write("Since playing on the "), getSideString(l, String), write(String),write(" yields a better score on the next move, this domino is best if placed on this side! "),nl.
%if yields best score if placed on left
getSideBasedOnScore(LeftScore, RightScore, _, _,r) :- RightScore>LeftScore, write("Since playing on the "), getSideString(r, String), write(String),write(" yields a better score on the next move, this domino is best if placed on this side! ").

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getNextMoveScoresAfterPlacement
%   Purpose: To get the next best score after placing the domino on the given side.
%   Parameters: Layout, Hand, Domino, Passed, Side, OtherSide, PlayingSide, Score - Next Best score
%---------------------------------------------------------------------------------------------------- 
getNextMoveScoresAfterPlacement(Layout, Hand, Domino, Passed, Side, OtherSide, PlayingSide, Score) :- placeDominoToLayout(Domino, PlayingSide, Layout, NewLayout),
    delete(Hand, Domino, NewHand),
    getAllPlayableMoves(NewLayout, NewHand, Passed, Side, OtherSide, Moves),
    getHighestYieldingMove(Moves, [_ | [Pip1|[Pip2|_]]]),
    Score is Pip1+Pip2.
getNextMoveScoresAfterPlacement(_, _, _, _, _, _,_, 0).  

%----------------------------------------------------------------------------------------------------
%   Predicate Name: validateMove
%   Purpose: To validate if the move can be placed on the given side of the layout.
%   Parameters: Domino, side, Layout, NewDomino - updated domino if needed
%---------------------------------------------------------------------------------------------------- 
%if layout is empty, place it
validateMove(Domino, _ , [], Domino).
%if side is left check against the leftpip
validateMove(Domino, l, Layout, NewDomino) :- [First|_]=Layout,
    [CheckPip|_]=First,
    checkDominoPlacement(Domino, CheckPip, l, UpdatedDomino),
    NewDomino = UpdatedDomino.
%if side is right, check against the rightpip
validateMove(Domino, r, Layout, NewDomino) :- reverse(Layout, ReversedLayout),
    [First|_]=ReversedLayout,
    [_|[CheckPip|_]]=First,
    checkDominoPlacement(Domino, CheckPip, r, UpdatedDomino),
    NewDomino = UpdatedDomino.
validateMove(_,_,_,[]).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: checkDominoPlacement
%   Purpose: To check if domino can be placed on the given side
%   Parameters: Domino, the pip to be place against, side, updatedDomino (flipped if needed)
%----------------------------------------------------------------------------------------------------    
checkDominoPlacement([Pip1,Pip2],CheckPip, l, [Pip1,Pip2]) :- CheckPip = Pip2.
checkDominoPlacement([Pip1,Pip2],CheckPip, l, [Pip2,Pip1]) :- CheckPip = Pip1.
checkDominoPlacement([Pip1,Pip2],CheckPip, r, [Pip1,Pip2]) :- CheckPip = Pip1.
checkDominoPlacement([Pip1,Pip2],CheckPip, r, [Pip2,Pip1]) :- CheckPip = Pip2.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getSideString
%   Purpose: To get the string for the character representation of side.
%   Parameters: side, side string
%---------------------------------------------------------------------------------------------------- 
getSideString(l, left).
getSideString(r,right).
                 
%----------------------------------------------------------------------------------------------------
%   Predicate Name: checkIfMoveInHand
%   Purpose: To check if move exists in the player hand.
%   Parameters: Move, Hand, GameState, Move - new move if no move in hand
%---------------------------------------------------------------------------------------------------- 
checkIfMoveInHand(Move, Hand, _, Move) :- Move = [_|Domino], 
    member(Domino,Hand).
checkIfMoveInHand(_, Hand, GameState, NewMove):- write("You don't have that domino in hand!"), nl, 
    getHumanMove(GameState, Move),
    checkIfMoveInHand(Move, Hand, GameState, MoveNew),
    NewMove = MoveNew.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: checkIfSideValid
%   Purpose: To check if the side played on the move is legal'
%   Parameters: Move, GameState, NewMove if illegal side played
%---------------------------------------------------------------------------------------------------- 
checkIfSideValid(Move, GameState, NewMove) :- Move = [ Side | _ ], 
      Side \= l , Side\=r ,
    write("Please select a valid side!"), nl,
    getHumanMove(GameState, NewMove),
    checkIfSideValid(NewMove, GameState, MoveNew),
    NewMove = MoveNew.
checkIfSideValid(Move,_,Move).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: checkIfSideAllowed
%   Purpose: To check if the side played on the move is allowed based on player
%   Parameters: Side, Player, Passed, Double, GameState, Move, NewMove if illegal side played
%---------------------------------------------------------------------------------------------------- 
checkIfSideisAllowed(l, human, _,_, _,  Move, Move).
checkIfSideisAllowed(r, computer, _,_, _, Move, Move).
checkIfSideisAllowed(l, computer, true,_, _, Move, Move).
checkIfSideisAllowed(r, human, true,_,_, Move, Move).
checkIfSideisAllowed(_,_,_,true,_, Move, Move).
checkIfSideisAllowed(_,Player,Passed, Double , GameState, _, NewMove) :- write("You are not allowed to place the domino on that side"),nl,
    getHumanMove(GameState, Move),
    Move = [Side|_],
    checkIfSideisAllowed(Side, Player, Passed, Double, GameState, Move, MoveNew),
    NewMove = MoveNew.


%%----------------------------------------------------------------------------------------------------
%%-----------------------------------Utility Predicates ---------------------------------------------
%%----------------------------------------------------------------------------------------------------

%----------------------------------------------------------------------------------------------------
%   Predicate Name: generateNums
%   Purpose: generate numbers from 0 to given number.
%   Parameters: maximum number, list to store the numbers in
%---------------------------------------------------------------------------------------------------- 
generateNums(Max,[]) :- Max < 0.
generateNums(Max, Nums) :- NewMax is Max-1,
	generateNums(NewMax, NewNums),
	append(NewNums, [Max], Nums).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: generateDominoes
%   Purpose: To generate all the dominoes for given pip with the given pips.
%   Parameters: pip to create the dominoes for, other pips to associate the dominoes with, set of dominoes
%---------------------------------------------------------------------------------------------------- 
generateDominoes(_, PipVals, []) :-  PipVals = [].
generateDominoes(PipNo, PipVals, Dominoes) :- [First | Rest] = PipVals,
	generateDominoes(PipNo, Rest, NewDominoes),
    Domino = [PipNo , First],
    append(NewDominoes, [Domino], Dominoes).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: generateAllDominoes
%   Purpose: To generate all the dominoes for the given pips.
%   Parameters: pips to create the dominoes for, set of dominoes
%---------------------------------------------------------------------------------------------------- 
generateAllDominoes(Pips, []) :- Pips = [].
generateAllDominoes(Pips, Dominoes):- [First | Rest] = Pips,
    generateDominoes(First, Pips, DominoesForPip),
    generateAllDominoes(Rest, NewDominoes),
    append(DominoesForPip, NewDominoes, Dominoes).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: getNDominoesFromStock
%   Purpose: To get N dominoes from the top of the stock
%   Parameters: Num of dominoes to draw, Stock, UpdatedStock, Dominoes
%---------------------------------------------------------------------------------------------------- 
getNDominoesFromStock(N, Stock,Stock, []) :- (   N =< 0) ; (Stock = []).
getNDominoesFromStock(N, Stock, UpdatedStock, Dominoes) :- [First | Rest ] = Stock,
    NewN is N - 1,
    getNDominoesFromStock(NewN, Rest, NewUpdatedStock, NewDominoes),
    append([First],NewDominoes, Dominoes),
    UpdatedStock = NewUpdatedStock.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: drawFromStock
%   Purpose: To draw a domino from stock and place it in hand.
%   Parameters: Stock, Hand, New hand, New stock
%---------------------------------------------------------------------------------------------------- 
drawFromStock([], Hand, Hand, []).
drawFromStock([Domino | Rest], Hand, NewHand, Rest) :-  append(Hand, [Domino], NewHand).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: placeDominoToLayout
%   Purpose: To place the given domino to given side in the layout
%   Parameters: Domino, Side, OldLayout, NewLayout
%---------------------------------------------------------------------------------------------------- 
placeDominoToLayout(Domino, l, OldLayout, NewLayout) :- validateMove(Domino, l, OldLayout, UpdatedDomino),
    append([UpdatedDomino], OldLayout, NewLayout).
placeDominoToLayout(Domino, r, OldLayout, NewLayout) :- validateMove(Domino, r, OldLayout, UpdatedDomino),
    append(OldLayout, [UpdatedDomino], NewLayout).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: passTurn
%   Purpose: To pass the turn.
%---------------------------------------------------------------------------------------------------- 
passTurn(NextPlayer, [TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, _, _], [TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, true, NextPlayer]).


%----------------------------------------------------------------------------------------------------
%   Predicate Name: checkIfDominoDouble
%   Purpose: To check if the domino is a double
%   Parameters: domino to check for, return value
%---------------------------------------------------------------------------------------------------- 
checkIfDominoDouble([Left | [Right|_]], true):- Left = Right.
checkIfDominoDouble(_, false).
    
 %getters for the lists from gameState
getComputerHand(GameState, Hand):-nth0(2,GameState,Hand).

getHumanHand(GameState, Hand ):-nth0(4,GameState,Hand).

getLayout(GameState, Layout):-nth0(6,GameState,Layout).

getStock(GameState, Stock):-nth0(7,GameState,Stock).

getPlayerPassed(GameState, Passed):-nth0(8,GameState,Passed).

getTurn(GameState, Turn):-nth0(9,GameState,Turn).
%


 %----------------------------------------------------------------------------------------------------
%   Predicate Name: updatePassCount
%   Purpose: To update passCount.
%   Parameters: previous player passed, previous pass count, new pass count.
%----------------------------------------------------------------------------------------------------        
updatePassCount(true, PassCount, NewCount) :- NewPassCount is PassCount+1,
    NewCount = NewPassCount.
updatePassCount(false, _, 0).


%----------------------------------------------------------------------------------------------------
%   Predicate Name: getHandSum
%   Purpose: To get the sum of all the pips in hand.
%   Parametes: Hand and variable to hold the sum for return
%---------------------------------------------------------------------------------------------------- 
getHandSum([],0).
getHandSum([Domino|Rest],Sum):- Domino = [Pip1|[Pip2|_]],
    getHandSum(Rest, NewSum),
    Sum is NewSum+Pip1+Pip2.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: askIfSaveAndQuit
%   Purpose: To kick if the user wants to save and quit
%   Parameters: Answer to return the user choice
%---------------------------------------------------------------------------------------------------- 
askIfSaveAndQuit(Answer):- write("Would you like to save and quit? (Y/N)"),
    read(Choice),
    validateYesNoChoice(Choice),
    Answer = Choice.
askIfSaveAndQuit(Answer):- askIfSaveAndQuit(NewAnswer),
    Answer = NewAnswer.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: validateYesNoChoice
%   Purpose: To validate yes or no choice.
%---------------------------------------------------------------------------------------------------- 
validateYesNoChoice(y).
validateYesNoChoice(n).

 %----------------------------------------------------------------------------------------------------
%   Predicate Name: displayGameState
%   Purpose: To display the game state (layout and stock)
%----------------------------------------------------------------------------------------------------    
displayGameState(Layout, Stock):- write("----------------------------------------------------------"),
    nl,
    write("Layout:"),nl,
    printLayout(Layout),
    write("----------------------------------------------------------"),
    nl,
    write("Stock:"),nl,
    write(Stock),nl,
    write("----------------------------------------------------------"),nl.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: printLayout
%   Purpose: To print the layout.
%---------------------------------------------------------------------------------------------------- 
printLayout(Layout) :- write("  "),printLine(Layout),nl,
    write("l "),printMiddleLine(Layout),write("r"),nl,
    write("  "),printLine(Layout),nl.

%----------------------------------------------------------------------------------------------------
%   Predicate Name: printLine
%   Purpose: To print the first and third line of the layout
%---------------------------------------------------------------------------------------------------- 
printLine([]).
printLine([Domino|Rest]):- checkIfDominoDouble(Domino, Double), Double = true,
    Domino =[Pip1|_],
	write(Pip1),write(" "),
    printLine(Rest).
printLine([_|Rest]) :- tab(6),
    printLine(Rest).

%----------------------------------------------------------------------------------------------------
%   Predicate Name: printMiddleLine
%   Purpose: To print the middle line of the layout.
%---------------------------------------------------------------------------------------------------- 
printMiddleLine([]).
printMiddleLine([Domino|Rest]):- checkIfDominoDouble(Domino, Double), Double = true,
    write("| "),
    printMiddleLine(Rest).
printMiddleLine([Domino|Rest]):- Domino = [Pip1,Pip2],
    write(Pip1),write(" - "),write(Pip2),write(" "),
    printMiddleLine(Rest).        