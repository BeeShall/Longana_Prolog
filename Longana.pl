generateNums(Max,[]) :- Max < 0.
generateNums(Max, Nums) :- NewMax is Max-1,
	generateNums(NewMax, NewNums),
	append(NewNums, [Max], Nums).

generateDominoes(_, PipVals, []) :-  PipVals = [].
generateDominoes(PipNo, PipVals, Dominoes) :- [First | Rest] = PipVals,
	generateDominoes(PipNo, Rest, NewDominoes),
    Domino = [PipNo , First],
    append(NewDominoes, [Domino], Dominoes).

generateAllDominoes(Pips, []) :- Pips = [].
generateAllDominoes(Pips, Dominoes):- [First | Rest] = Pips,
    generateDominoes(First, Pips, DominoesForPip),
    generateAllDominoes(Rest, NewDominoes),
    append(DominoesForPip, NewDominoes, Dominoes).

getNDominoesFromStock(N, Stock,Stock, []) :- (   N =< 0) ; (Stock = []).
getNDominoesFromStock(N, Stock, UpdatedStock, Dominoes) :- [First | Rest ] = Stock,
    NewN is N - 1,
    getNDominoesFromStock(NewN, Rest, NewUpdatedStock, NewDominoes),
    append([First],NewDominoes, Dominoes),
    UpdatedStock = NewUpdatedStock.

drawFromStock([], Hand, Hand, []).
drawFromStock([Domino | Rest], Hand, NewHand, Rest) :-  append(Hand, [Domino], NewHand).

passTurn(NextPlayer, [TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, _, _], [TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, true, NextPlayer]).
placeDominoToLayout(Domino, l, OldLayout, NewLayout) :- validateMove(Domino, l, OldLayout, UpdatedDomino),
    append([UpdatedDomino], OldLayout, NewLayout).
placeDominoToLayout(Domino, r, OldLayout, NewLayout) :- validateMove(Domino, r, OldLayout, UpdatedDomino),
    append(OldLayout, [UpdatedDomino], NewLayout).

validateMove(Domino, _ , [], Domino).
validateMove(Domino, l, Layout, NewDomino) :- [First|_]=Layout,
    [CheckPip|_]=First,
    checkDominoPlacement(Domino, CheckPip, l, UpdatedDomino),
    NewDomino = UpdatedDomino.
validateMove(Domino, r, Layout, NewDomino) :- reverse(Layout, ReversedLayout),
    [First|_]=ReversedLayout,
    [_|[CheckPip|_]]=First,
    checkDominoPlacement(Domino, CheckPip, r, UpdatedDomino),
    NewDomino = UpdatedDomino.
validateMove(_,_,_,[]).
    
checkDominoPlacement([Pip1,Pip2],CheckPip, l, [Pip1,Pip2]) :- CheckPip = Pip2.
checkDominoPlacement([Pip1,Pip2],CheckPip, l, [Pip2,Pip1]) :- CheckPip = Pip1.
checkDominoPlacement([Pip1,Pip2],CheckPip, r, [Pip1,Pip2]) :- CheckPip = Pip1.
checkDominoPlacement([Pip1,Pip2],CheckPip, r, [Pip2,Pip1]) :- CheckPip = Pip2.

getSideString(l, left).
getSideString(r,right).

%determineFirstPlayer


determineFirstPlayer(Stock , Human, Computer , Engine, _, NextPlayer, Stock,NewHuman,NewComputer):- member(Engine, Human),
    write("Human has the engine!"),nl,
    delete(Human, Engine, NewHuman),
    NewComputer = Computer,
    NextPlayer = computer.   
determineFirstPlayer(Stock , Human, Computer , Engine, _, NextPlayer, Stock,NewHuman,NewComputer):- member(Engine, Computer),
    write("Computer has the engine!"),nl,
    delete(Computer, Engine, NewComputer),
    NewHuman = Human,
    NextPlayer = human.  
determineFirstPlayer([First|Rest] , Human, Computer, Engine, human, NextPlayer, UpdatedStock, UpdatedHuman, UpdatedComputer):- append(Human, [First], NewHuman),
    write("Human drew "), write(First), write(" from the stock!"),nl,
    determineFirstPlayer(Rest, NewHuman, Computer, Engine, computer, NewNextPlayer, NewStock, NewUpdatedHuman, NewUpdatedComputer),
    UpdatedStock = NewStock,
    UpdatedHuman = NewUpdatedHuman,
    UpdatedComputer = NewUpdatedComputer,
    NextPlayer = NewNextPlayer.
determineFirstPlayer([First|Rest] , Human, Computer, Engine, computer, NextPlayer, UpdatedStock, UpdatedHuman, UpdatedComputer):- append(Computer, [First], NewComputer),
    write("Computer drew "), write(First), write(" from the stock!"),nl,
    determineFirstPlayer(Rest, Human, NewComputer, Engine, human, NewNextPlayer, NewStock, NewUpdatedHuman, NewUpdatedComputer),
    UpdatedStock = NewStock,
    UpdatedHuman = NewUpdatedHuman,
    UpdatedComputer = NewUpdatedComputer,
    NextPlayer = NewNextPlayer.

getHumanMenuAction(GameState, NewState, Drawn) :-  nl, write("----------------------------------------------------------"),nl,
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
    

%make a move
getHumanChoiceAction(1, GameState, NewState,_ ):- GameState = [_, _, _, _, HumanHand, _, Layout, _, Passed, _],
    playerHasAnyMoves(Layout, HumanHand, Passed , l , r),
    playHuman(GameState, NewGameState),
    NewState = NewGameState.
getHumanChoiceAction(1, GameState, NewState, Drawn) :- nl,write("You don't have any playable moves in hand!"),nl,
    getHumanChoiceAction(2,GameState, NewGameState, Drawn),
    NewState = NewGameState.
%draw from stock
getHumanChoiceAction(2, GameState, NewGameState, _ ) :- getStock(GameState, Stock),
    Stock = [],
    write("You can't draw a tile because stock is empty! Your turn will now be passed"), nl,
    passTurn(computer, GameState, NewState),
    NewGameState = NewState. 
getHumanChoiceAction(2, GameState, NewGameState, Drawn) :- GameState = [_,_,_, _, HumanHand ,_, Layout, _, Passed, _],
    playerHasAnyMoves(Layout, HumanHand, Passed , l , r),
    write("You already have valid moves in hand"),nl,
    getHumanMenuAction(GameState, NewState, Drawn),
    NewGameState = NewState.
getHumanChoiceAction(2, GameState, NewGameState, true) :- nl, write("You already drew from stock! You don't have any playable tiles either. So your turn will be passed!"), nl,
    passTurn(computer, GameState, NewState),
    NewGameState = NewState.                                                                                                                                 
getHumanChoiceAction(2, GameState, NewState, false) :- GameState = [TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, Passed, Player],
    drawFromStock(Stock, HumanHand, NewHand, NewStock),
    Stock=[Domino|_],
    write("You drew "), write(Domino), write(" from the stock!"),nl,
    write("Human Hand:"),nl, write(NewHand),nl,
    AfterGameState = [TournScore,RoundNo,CompHand, CompScore, NewHand ,HumanScore, Layout, NewStock, Passed, Player],
    getHumanMenuAction(AfterGameState, NewGameState, true),
    NewState = NewGameState.

getHumanChoiceAction(3, GameState, NewState, Drawn) :- GameState = [_, _, _, _, HumanHand, _, Layout, _, Passed, _],
	getHint(Layout, HumanHand, Passed, l,r,Hint),
    Hint \= [],
    getHumanMenuAction(GameState, NewGameState, Drawn),
    NewState = NewGameState.
getHumanChoiceAction(3, GameState, NewState, Drawn) :- write("You do not have any playable moves in hand!"),nl, 
    getHumanMenuAction(GameState, NewGameState, Drawn),
    NewState = NewGameState.
%hint

playerHasAnyMoves(Layout, Hand, Passed, Side, OtherSide) :- getAllPlayableMoves(Layout, Hand, Passed, Side, OtherSide, Moves),
    Moves \= [].


playHuman(OldGameState, NewGameState) :- getHumanMove(OldGameState, HumanMove),
    ensurePlayableHumanMove(OldGameState, HumanMove,  Move),
    Move = [Side|Domino],
    getLayout(OldGameState, OldLayout),
    getHumanHand(OldGameState, Hand),
    placeDominoToLayout(Domino, Side, OldLayout, NewLayout),
    delete(Hand, Domino, NewHand),
    OldGameState = [TournScore, RoundNo, CompHand, CompScore, _, HumanScore, _, Stock, _, _],
    NewGameState = [TournScore, RoundNo, CompHand, CompScore, NewHand, HumanScore, NewLayout, Stock, false, computer].
    
    
ensurePlayableHumanMove(GameState, [Side|Domino], ValidMove) :- getLayout(GameState, Layout),
    validateMove(Domino, Side, Layout, NewDomino),
    NewDomino \= [],
    ValidMove = [Side | NewDomino].
ensurePlayableHumanMove(GameState, _,  ValidMove) :- write("Invalid move, Try again!"), nl,
    getHumanMove(GameState, NewMove),
    ensurePlayableHumanMove(GameState, NewMove, NewValidMove),
    ValidMove = NewValidMove.

getHumanMove(GameState, HumanMove) :- getHumanHand(GameState, Hand),
    readHumanMove(Hand, Move),
    checkIfSideValid(Move, GameState, Move1),
    Move1 = [Side1|Domino1],
    getPlayerPassed(GameState, Passed),
    checkIfDominoDouble(Domino1, Double),
    checkIfSideisAllowed(Side1, human, Passed, Double, GameState, Move1, Move2),
    checkIfMoveInHand(Move2, Hand, GameState, [NewSide|NewDomino] ),
    HumanMove = [NewSide|NewDomino].

readHumanMove(Hand, Move) :- write("----------------------------------------------------------"),
    nl,
    write("Human Hand:"),
    nl,
    write(Hand),
    nl,
    nl,
    write("----------------------------------------------------------"),
    nl,
    write("Please enter the domino you'd like to play enclosed in [ ] with side (l/r) as the first element. E.g. [l, 1, 6]:: "),
    nl,
    read([Side | Domino]),
    append([Side],Domino, Move).
readHumanMove(Hand, Move) :- write("Please follow the correct format and enter your move again!"),nl,
    readHumanMove(Hand, NewMove),
    Move = NewMove.

getComputerMove([TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, Passed, _], NewGameState, _) :- write("Computer Hand:"),nl,
    write(CompHand),nl,nl,
    write("Computer's Move: "),nl,
    getHint(Layout, CompHand, Passed, r, l, HintMove),
    HintMove = [Side|Domino],
    placeDominoToLayout(Domino, Side, Layout, NewLayout),
    delete(CompHand, Domino, NewHand),
    NewGameState = [TournScore,RoundNo,NewHand, CompScore, HumanHand ,HumanScore, NewLayout, Stock, false, human].

getComputerMove([TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, _, _], [TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, true, human], _) :- Stock = [],
    write("Computer doesn't have a valid move in hand"),nl,
    write("Stock is empty! So computer passed!"),nl.

getComputerMove([TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, _, _], [TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, true, human], true) :- write("Computer still doesn't have any valid move in hand! Computer passed!"),nl.


getComputerMove([TournScore,RoundNo,CompHand, CompScore, HumanHand ,HumanScore, Layout, Stock, Passed, Player], NewGameState, false):- drawFromStock(Stock, CompHand, NewHand, NewStock),
    Stock = [Domino|_],
    write("Computer drew "), write(Domino), write(" from the stock!"),nl,
    getComputerMove([TournScore,RoundNo,NewHand, CompScore, HumanHand ,HumanScore, Layout, NewStock, Passed, Player], NewState, true),
    NewGameState = NewState.

    

getHint(Layout, Hand, Passed, Side, OtherSide, HintMove) :- getAllPlayableMoves(Layout, Hand, Passed, Side, OtherSide, Moves),
    getHighestYieldingMove(Moves, BestMove),
    BestMove = [_|Domino],
    write(Domino),write(" is the highest score yielding domino in the hand!"),nl,
    getBestSideForMove(Layout, Hand, BestMove, Side, OtherSide, NewMove),
    HintMove = NewMove.

getAllPlayableMoves(_, [], _, _, _, []).
getAllPlayableMoves(Layout, [Domino | Rest], Passed, Side, OtherSide, Moves):- (Passed = true; ( checkIfDominoDouble(Domino, Double), Double = true)),
    findPlayableMoveSide(Domino, l, r, Layout, [Side1|_]),
    findPlayableMoveSide(Domino, r, l, Layout, [Side2|_]),
    Side1 \= Side2,                    
    getAllPlayableMoves(Layout, Rest, Passed, Side, OtherSide, NewMoves),
    append(NewMoves, [[a|Domino]], Moves).
getAllPlayableMoves(Layout, [Domino | Rest], Passed, Side, OtherSide, Moves):- (Passed = true; ( checkIfDominoDouble(Domino, Double), Double = true)),
    findPlayableMoveSide(Domino, OtherSide, Side, Layout, Move),                    
    getAllPlayableMoves(Layout, Rest, Passed, Side, OtherSide, NewMoves),
    append(NewMoves, [Move], Moves).
getAllPlayableMoves(Layout, [Domino | Rest], Passed, Side, OtherSide, Moves) :- findPlayableMoveSide(Domino, Side, OtherSide, Layout, Move),
    getAllPlayableMoves(Layout, Rest, Passed, Side, OtherSide, NewMoves),
    append(NewMoves, [Move], Moves).
getAllPlayableMoves(Layout, [_ | Rest], Passed, Side, OtherSide, Moves):- getAllPlayableMoves(Layout, Rest, Passed, Side, OtherSide, NewMoves),
    Moves = NewMoves.

findPlayableMoveSide(Domino, l, r, Layout, [l|Domino]) :- validateMove(Domino, l, Layout, NewDomino),
     NewDomino \= [].
findPlayableMoveSide(Domino, r, l, Layout, [r|Domino]) :- validateMove(Domino, r, Layout, NewDomino),
     NewDomino \= [].

getHighestYieldingMove([],[]).
getHighestYieldingMove([Move | Rest], BestMove) :- getHighestYieldingMove( Rest, NewMove),
    compareAndGetBestDomino(Move,NewMove, NewBestMove),
    BestMove = NewBestMove.

compareAndGetBestDomino([], Move, Move).
compareAndGetBestDomino(Move, [], Move).
compareAndGetBestDomino([Side1 | Domino1],[_ | Domino2],NewMove) :- Domino1 = [First1 | [Second1|_]],
    Domino2 = [First2| [Second2|_]],
    (   First1+Second1) >= (First2+Second2),
    NewMove = [Side1 | Domino1].
compareAndGetBestDomino(_,Move,Move).

getBestSideForMove(Layout, Hand, [a|Domino], Side, OtherSide, BestMove):- write("However, this domino can be placed on either side!"),nl, getNextMoveScoresAfterPlacement(Layout, Hand, Domino, false, Side, OtherSide, l, LeftScore),
    getNextMoveScoresAfterPlacement(Layout, Hand, Domino, false, Side, OtherSide, r, RightScore),
    write("If played on the LEFT, the next move will yield a score of "),write(LeftScore),write(" and playing on the RIGHT will yield "),write(RightScore), nl,
    LeftScore \= RightScore,
    getSideBasedOnScore(LeftScore, RightScore, Side, BestSide),
    write("Since playing on the "), getSideString(BestSide, String), write(String),write(" yields a better score on the next move, this domino is best if placed on this side! "),
    append([l],Domino, BestMove).
getBestSideForMove(_, _, [a|_], _,_, _) :- write("Since you yield the same score on the next move regardless of the side you choose, placing it on the opposite side will create more chances of the opponent screwing up!").
getBestSideForMove(_, _, Move, _, _, Move):- Move = [Side|_], write("This domino can be played "),getSideString(Side,String),write(String),nl.

getSideBasedOnScore(LeftScore, LeftScore, l, r).  
getSideBasedOnScore(RightScore, RightScore, r, l).
getSideBasedOnScore(LeftScore, RightScore, _, l):-LeftScore > RightScore.
getSideBasedOnScore(LeftScore, RightScore, _, r) :- RightScore>LeftScore.

getNextMoveScoresAfterPlacement(Layout, Hand, Domino, Passed, Side, OtherSide, PlayingSide, Score) :- placeDominoToLayout(Domino, PlayingSide, Layout, NewLayout),
    delete(Hand, Domino, NewHand),
    getAllPlayableMoves(NewLayout, NewHand, Passed, Side, OtherSide, Moves),
    getHighestYieldingMove(Moves, [_ | [Pip1|[Pip2|_]]]),
    Score is Pip1+Pip2.
getNextMoveScoresAfterPlacement(_, _, _, _, _, _,_, 0).

                        

checkIfMoveInHand(Move, Hand, _, Move) :- Move = [_|Domino], 
    member(Domino,Hand).
checkIfMoveInHand(_, Hand, GameState, NewMove):- write("You don't have that domino in hand!"), nl, 
    getHumanMove(GameState, Move),
    checkIfMoveInHand(Move, Hand, GameState, MoveNew),
    NewMove = MoveNew.

checkIfSideValid(Move, GameState, NewMove) :- Move = [ Side | _ ], 
      Side \= l , Side\=r ,
    write("Please select a valid side!"), nl,
    getHumanMove(GameState, NewMove),
    checkIfSideValid(NewMove, GameState, MoveNew),
    NewMove = MoveNew.
checkIfSideValid(Move,_,Move).

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



checkIfDominoDouble([Left | [Right|_]], true):- Left = Right.
checkIfDominoDouble(_, false).
    
 %getters for the lists from gameState
getTournamentScore(GameState, Score):- nth0(0,GameState,Score).

getRoundNo(GameState, RoundNo):- nth0(1,GameState,RoundNo).

getComputerHand(GameState, Hand):-nth0(2,GameState,Hand).

getComputerScore(GameState, Score):-nth0(3,GameState,Score).

getHumanHand(GameState, Hand ):-nth0(4,GameState,Hand).

getHumanScore(GameState, Score):-nth0(5,GameState,Score).

getLayout(GameState, Layout):-nth0(6,GameState,Layout).

getStock(GameState, Stock):-nth0(7,GameState,Stock).

getPlayerPassed(GameState, Passed):-nth0(8,GameState,Passed).

getTurn(GameState, Turn):-nth0(9,GameState,Turn).



%

playRound(OldGameState, NewGameState) :- getTurn(OldGameState, Turn),
    Turn = human,
    getHumanMenuAction(OldGameState, NewState, false),
    NewGameState = NewState.
playRound(OldGameState, NewGameState) :- getTurn(OldGameState, Turn),
    Turn = computer,    
    getComputerMove(OldGameState, NewState, false),
    NewGameState = NewState.

runRound(OldGameState, RoundResults, PassCount) :- OldGameState = [_,_,CompHand, _, HumanHand ,_, _, Stock, _, _],
    checkIfRoundEnded(Stock, HumanHand, CompHand, PassCount),nl,
    write("The round has ended!"),nl,
    calculateRoundScore(OldGameState, CompScore, HumanScore ),
    RoundResults = [CompScore,HumanScore].%calculate score and display winner  
runRound(OldGameState, NewGameState, PassCount) :- getLayout(OldGameState,Layout),
    getStock(OldGameState, Stock),
    displayGameState(Layout,Stock),
    playRound(OldGameState, NewState),
    getPlayerPassed(NewState, Passed),
    updatePassCount(Passed, PassCount, NewPassCount),
    runRound( NewState, NewestGameState, NewPassCount),
    NewGameState = NewestGameState. 
        
updatePassCount(true, PassCount, NewCount) :- NewPassCount is PassCount+1,
    NewCount = NewPassCount.
updatePassCount(false, _, 0).
%human hand is empty
checkIfRoundEnded(_, [], _, _).
%computer hand is empty
checkIfRoundEnded(_, _, [], _).
%stock is empty and both player passed
checkIfRoundEnded([],_, _, PassCount):- PassCount>2. 

calculateRoundScore(GameState, CompScore, HumanScore):- getHumanHand(GameState, HumanHand),
    getComputerHand(GameState, ComputerHand),
    getHandSum(HumanHand, HumanSum),
    getHandSum(ComputerHand, CompSum),
    write("Human Hand Sum: "),write(HumanSum),nl,
    write("Computer Hand Sum: "),write(CompSum),nl,
    determineRoundWinner(CompSum, HumanSum, CScore, HScore),
    CompScore = CScore,
    HumanScore = HScore.

determineRoundWinner(CompSum, HumanSum, 0, CompSum):- CompSum >HumanSum,
    write("Human wins the round with the score of "),write(CompSum),nl.
determineRoundWinner(CompSum, HumanSum, HumanSum, 0):- HumanSum >CompSum,
    write("Computer wins the round with the score of "),write(HumanSum),nl.

getHandSum([],0).
getHandSum([Domino|Rest],Sum):- Domino = [Pip1|[Pip2|_]],
    getHandSum(Rest, NewSum),
    Sum is NewSum+Pip1+Pip2.
    
displayGameState(Layout, Stock):- write("----------------------------------------------------------"),
    nl,
    write("Layout:"),nl,
    write(Layout),nl,
    write("----------------------------------------------------------"),
    nl,
    write("Stock:"),nl,
    write(Stock),nl,
    write("----------------------------------------------------------"),nl.


generateRound(TournScore, RoundCount, HumanScore, ComputerScore, GameState) :- generateNums(6, Pips),
    generateAllDominoes(Pips, Dominoes),
    random_permutation(Dominoes,Stock),
    getNDominoesFromStock(8, Stock, UpdatedStock1, HumanHand),
    write("Human Hand: "),write(HumanHand),nl,
    getNDominoesFromStock(8, UpdatedStock1, UpdatedStock2,  ComputerHand),
    write("Computer Hand: "),write(ComputerHand),nl,nl,
    getEngineFromRoundCount(RoundCount, 7, Engine),
    determineFirstPlayer(UpdatedStock2, HumanHand, ComputerHand, Engine, human, NextPlayer, NewStock, NewHuman, NewComputer),
    Layout = [Engine],
    GameState = [TournScore,RoundCount,NewComputer, ComputerScore, NewHuman,HumanScore, Layout, NewStock, false, NextPlayer].

getEngineFromRoundCount(RoundCount, PipCount, Engine) :- ModVal is RoundCount mod PipCount,
   getEngine(ModVal, PipCount, GameEngine),
    Engine = GameEngine.
    
getEngine(0, _, [0,0]).
getEngine(ModVal, MaxPip, Engine):- Pip is MaxPip - ModVal,
    Engine = [Pip,Pip]. 

getTournamentScore(Score) :- write("Please enter the tournament score: "),
    read(Data),
    number(Data),
    Score = Data.
getTournamentScore(Score) :- nl,write("Invalid Input. Try again!"),nl,
    getTournamentScore(NewScore),
    Score = NewScore.

newTournament(_) :- getTournamentScore(Score),
    playTournament(Score, 1, 0, 0).

playTournament(TournScore, _, HumanScore, CompScore):- checkIfTournamentEnded(TournScore, HumanScore, CompScore).
playTournament(TournScore, RoundCount, HumanScore, CompScore):-
    generateRound(TournScore, RoundCount, HumanScore, CompScore, GameState),
    runRound(GameState, [CScore,HScore|_], 0),
    NewHumanScore is HumanScore + HScore,
    NewCompScore is CompScore+CScore,
    NewRoundCount is RoundCount+1,
    playTournament(TournScore, NewRoundCount, NewHumanScore, NewCompScore).

checkIfTournamentEnded(TournScore, HumanScore, CompScore) :- HumanScore > TournScore,
    write("Human won the tournament with the score of "),write(HumanScore),nl,
    write("Computer had a score of "),write(CompScore),nl.
checkIfTournamentEnded(TournScore, HumanScore, CompScore) :- CompScore > TournScore,
    write("Computer won the tournament with the score of "),write(CompScore),nl,
    write("Human had a score of "),write(HumanScore),nl.