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

placeDominoToLayout(Domino, l, OldLayout, NewLayout) :- validateMove(Domino, l, OldLayout, NewDomino),
    append([NewDomino], OldLayout, NewLayout).
placeDominoToLayout(Domino, r, OldLayout, NewLayout) :- validateMove(Domino, r, OldLayout, NewDomino),
    append(OldLayout, [NewDomino], NewLayout).

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
validateMove(_,_,_,_):- write("Invalid move, Try again!"), nl, false.
    
checkDominoPlacement([Pip1,Pip2],CheckPip, l, [Pip1,Pip2]) :- CheckPip = Pip2.
checkDominoPlacement([Pip1,Pip2],CheckPip, l, [Pip2,Pip1]) :- CheckPip = Pip1.
checkDominoPlacement([Pip1,Pip2],CheckPip, r, [Pip1,Pip2]) :- CheckPip = Pip1.
checkDominoPlacement([Pip1,Pip2],CheckPip, r, [Pip2,Pip1]) :- CheckPip = Pip2.

%determineFirstPlayer


determineFirstPlayer(Stock , Human, Computer , Engine, _, NextPlayer, Stock,NewHuman,NewComputer):- member(Engine, Human),
    delete(Human, Engine, NewHuman),
    NewComputer = Computer,
    NextPlayer = computer; 
    member(Engine, Computer),
    delete(Computer, Engine, NewComputer),
    NewHuman = Human,
    NextPlayer = human.
determineFirstPlayer([First|Rest] , Human, Computer , Engine, human, computer, Rest,Human,Computer):-  First = Engine.
determineFirstPlayer([First|Rest] , Human, Computer, Engine, computer, human, Rest,Human,Computer):-  First = Engine.   
determineFirstPlayer([First|Rest] , Human, Computer, Engine, computer, human, NewStock,Human,NewComputer):-  First = Engine,
    NewStock = Rest; 
    member(Engine, Computer),
    delete(Engine, Computer, NewComputer),
    append([First], Rest, NewStock).
determineFirstPlayer([First|Rest] , Human, Computer, Engine, human, NextPlayer, UpdatedStock, UpdatedHuman, UpdatedComputer):- append(Human, [First], NewHuman),
    determineFirstPlayer(Rest, NewHuman, Computer, Engine, computer, NewNextPlayer, NewStock, NewUpdatedHuman, NewUpdatedComputer),
    UpdatedStock = NewStock,
    UpdatedHuman = NewUpdatedHuman,
    UpdatedComputer = NewUpdatedComputer,
    NextPlayer = NewNextPlayer.
determineFirstPlayer([First|Rest] , Human, Computer, Engine, computer, NextPlayer, UpdatedStock, UpdatedHuman, UpdatedComputer):- append(Computer, [First], NewComputer),
    determineFirstPlayer(Rest, Human, NewComputer, Engine, human, NewNextPlayer, NewStock, NewUpdatedHuman, NewUpdatedComputer),
    UpdatedStock = NewStock,
    UpdatedHuman = NewUpdatedHuman,
    UpdatedComputer = NewUpdatedComputer,
    NextPlayer = NewNextPlayer.


getHumanMove(OldGameState, NewGameState):-write("----------------------------------------------------------"),
    nl,
    write("Human Hand:"),
    nl,
    getHumanHand(OldGameState, Hand),
    write(Hand),
    nl,
    nl,
    write("----------------------------------------------------------"),
    nl,
    write("Please enter the domino you'd like to play enclosed in [ ] with side (l/r) as the first element. E.g. [l, 1, 6]:: "),
    nl,
    read([Side | Domino]),
    getPlayerPassed(OldGameState, Passed),
    checkIfSideValid(Side, human, Passed, Domino),
    checkIfMoveInHand(Domino, Hand),
    getLayout(OldGameState, OldLayout),
    placeDominoToLayout(Domino, Side, OldLayout, NewLayout),
    delete(Hand, Domino, NewHand),
    OldGameState = [TournScore, RoundNo, CompHand, CompScore, _, HumanScore, _, Stock, _, _],
    NewGameState = [TournScore, RoundNo, CompHand, CompScore, NewHand, HumanScore, NewLayout, Stock, false, computer].
 getHumanMove(OldGameState, NewGameState):- write("Please follow the correct format and enter your move again!"),
    nl,
    getHumanMove(OldGameState, NewNewGameState),
    NewGameState = NewNewGameState.

checkIfMoveInHand(Domino, Hand) :- member(Domino,Hand).
checkIfMoveInHand(Domino, Hand):- \+ (member(Domino, Hand)), write("You don't have that domino in hand!"), nl, false.


checkIfSideValid(Side, _,  _, _):-( Side \= l ), ( Side \= r),  write("Please select a valid side!"), nl,  false.
checkIfSideValid(_, _, true, _). 
checkIfSideValid(_,_,_,Domino) :- checkIfDominoDouble(Domino).
checkIfSideValid(l, human, false, _).
checkIfSideValid(r, computer, false, _).
checkIfSideValid(_, _, _, _) :- write("You cannot place the domino on that side!"), nl, false.

checkIfDominoDouble([left| [right, _]]):- left = right.
    
 %getters for the lists from gameState
getTournamentScore(GameState, Score):- nth0(0,GameState,Score).

getRoundNo(GameState, RoundNo):- nth0(1,GameState,RoundNo).

getComputerHand(GameState, Hand):-nth0(2,GameState,Hand).

getComputerScore(GameState, Score):-nth0(3,GameState,Score).

getHumanHand(GameState, Hand ):-nth0(4,GameState,Hand).

getHumanScore(GameState, Score):-nth0(5,GameState,Score).

getLayout(GameState, Layout):-nth0(6,GameState,Layout).

getStock(GameState, Stock):-nth0(7,GameState,Stock).

getTurn(GameState, Turn):-nth0(8,GameState,Turn).

getPlayerPassed(GameState, Passed):-nth0(9,GameState,Passed).

 %
    

generateRound(GameState) :- generateNums(6, Pips),
    generateAllDominoes(Pips, Dominoes),
    random_permutation(Dominoes,Stock),
    getNDominoesFromStock(8, Stock, UpdatedStock1, HumanHand),
    getNDominoesFromStock(8, UpdatedStock1, UpdatedStock2,  ComputerHand),
    Engine = [6,6],
    determineFirstPlayer(UpdatedStock2, HumanHand, ComputerHand, Engine, human, NextPlayer, NewStock, NewHuman, NewComputer),
    Layout = [Engine],
    GameState = [0,0,NewComputer, 0, NewHuman,0, Layout, NewStock, NextPlayer, false].
    