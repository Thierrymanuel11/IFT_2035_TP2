/*Commentaires en prolog.*/

frangins2(X, Y) :-
    frangins(manuel, X),
    frangins(manuel, Y).

jeudefoot(X) :-
    jeuvideo(X),
    football(X).
maman(manuel, carine).
papa(manuel, emeric).
parent(manuel, X):-
    maman(manuel, X),
    fille(X).

parent(manuel, X):-
    papa(manuel, X),
    homme(X).

positif(X) :-
    content(X),
    homme(X),
    format('~w ~s ~n', [X, "est positif"]).

positive(X) :-
    content(X),
    femme(X),
    format('~w ~s ~n', [X, "est positive"]).

somme(X ,Y, Z) :- 
    Z is X+Y.
mult(X,Y,Z):-
    Z is X*Y.

dec(X, Y):-
    Y is X-1.

fact(0,1).
fact(1,1).
fact(N,FN) :- 
    dec(N, X),
    fact(X, FX),
    mult(N, FX, FN).


quicksort([], []).
quicksort([X], [X]).
quicksort([X|Xr], Y):-
    partition(X, Xr, S, G),
    sort(S, K),
    sort(G, L),
    append(K, [X|L], Y).

homme(emeric).
homme(manuel).
homme(andy).
homme(filip).
homme(mike).
homme(yvan).
homme(loic).
homme(liam).
homme(olivier).
homme(christian).

femme(judith).
femme(carine).
femme(lynda).
femme(maeva).
femme(adeline).
femme(francine).
femme(christine).
femme(patricia).
femme(marie).
femme(beleive).

enfant(maeva, emeric, carine). 
enfant(lynda, emeric, carine).
enfant(manuel, emeric, carine).
enfant(andy, emeric, carine).
enfant(mike, olivier, judith).
enfant(filip, olivier, judith).
enfant(marie, olivier, judith).
enfant(patricia,christian, francine).

/*Suite de fibonacci en prolog*/
fibo(0, 0).
fibo(1, 1).
fibo(X, Y):-
    Z is X - 1,
    H is X - 2,
    fibo(Z, L),
    fibo(H, M),
    Y is L + M.

/*Fonction semblable à la fonction member*/
elem([], _):- write('La liste est vide').
elem([X], X).
elem([X|Xr], X).
elem([X|Xr], Y):- elem(Xr, Y).  

/*Prédicat Prolog qui retire les 3 premiers éléments d'une liste et renvoie le résultat*/
retirer3([], []).
retirer3([X], []).
retirer3([X,Y], []).
retirer3([X,Y,Z], []).
retirer3([X,Y,Z|Xr], Xr).


/*Prédicat Prolog qui retire les 3 premiers et derniers éléments d'une liste et renvoie le résultat*/
retirer33([], []).
retirer33([X], []).
retirer33([X,Y], []).
retirer33([X,Y,Z], []).
retirer33([X,Y,Z,A], []).
retirer33([X,Y,Z,A,B], []).
retirer33([X,Y,Z,A,B,C], []).
retirer33([X,Y,Z,T|Xr], [T|Yr]):- append(Yr, [A,B,C], Xr).

/*Predicat Prolog qui renvoie le dernier élément d'une liste*/
\+(der([],_)).
der([X],X).
der([X|Xr], Y):- der(Xr, Y).

/*Predicat Prolog qui calcule le max de 3 nombre*/
max3(X, Y, Z, X):- X>Y, X>Z.
max3(X, Y, Z, Y):- Y>X, Y>Z.
max3(X, Y, Z, Z):- Z>X, Z>Y.

/*Predicat Prolog qui calcule le max de 2 nombre*/
max2(X, Y, X):- X>Y. 
max2(X, Y, Y):- Y>X.

/*Predicat Prolog qui calcule le min de 2 nombre*/
min2(X, Y, X):- X<Y. 
min2(X, Y, Y):- Y<X.

/*Prédicat Prolog calcule le max d'une liste d'entiers*/
max([], _):- write('La liste est vide.').
max([X], X).
max([X, Y], X):- X > Y.
max([X, Y], Y):- Y > X.
max([X, Y ,Z], R):- max3(X, Y, Z, R).
max([X, Y, Z|Xr], A):- max3(X, Y, Z, R), max(Xr, L), max2(R, L, A).

/*Prédicat Prolog qui renvoit la longueur d'une liste*/
longueur([], 0):- 
longueur([X], 1).
longueur([X|Xr], Y):- longueur(Xr, Z), Y is Z + 1. 

/*Prédicat prolog qui prends une liste de listes en entrée et renvoie le min des max de chaque liste. */
minmax([] ,_):-write('La liste est vide').
minmax([X], Y):- max(X, Y).
minmax([X, Y], Z):- max(X, K), max(Y, I), min2(K, I, Z).
minmax([X|Xr], Y):- max(X, Z), minmax(Xr, S), min2(Z, S, Y).

/*Predicat qui permet d'inserer un élément n'importe ou dans une liste*/
inserer([], Y, [Y]).
inserer([X], Y, [X, Y]).
inserer([X], Y, [Y, X]).
inserer(X, Y, Z):- longueur(X, J), longueur(X, K), J is K + 1, member(Y, Z). 

/*Prédicat qui inverse le contenu d'une liste*/
inverse([], []).
inverse([X], [X]).
inverse([X, Y], [Y, X]).
inverse([X|Xr], Y):- inverse(Xr, Z), append(Z, [X], Y).

/*Prédicat Prolog qui construit une liste de nombre de N à 1*/
list1(1, [1]).
list1(2, [2,1]).
list1(X, [X|Xr]):- Z is X - 1, list1(Z, Xr).


/*Prédicat Prolog qui construit pour un entier N la liste des N premiers nombres entiers*/
gen(X, Y):- list1(X, Z), inverse(Z, Y).

/*Prédicat Prolog qui retire les N premiers nombres entiers d'une liste et renvoie le résultat*/
removen(0, Tab, Tab).
removen(1, [X|Xr], Xr).
removen(X, Tab, Z):- longueur(Tab, N), N >=X, gen(X, A), append(A, Z, Tab). 

/*2e version de gen qui pour deux nombres passés en entrée, renvoie une liste de nombres compris entre ces deux la et triée*/
gen2(X, X, [X]).
gen2(X, Y, Z):- Y > X, A is X - 1, gen(Y, B), removen(A, B, Z).

/*Prédicat Prolog qui va dupliquer les éléments d'une liste et renvoyer le résultat*/
dup([], []).
dup([X], [X,X]).
dup([X|Xr], [X,X|Yr]):- dup(Xr, Yr).

/*Prédicat Prolog qui répète les éléments d'une liste N fois*/
rep([], _, []).
rep([X], 1, [X]). 
rep([X], N, [X|Xr]):- Z is N - 1, rep([X], Z, Xr) .
rep([X|Xr], N, Y):- rep([X], N, A), rep(Xr, N, B), append(A, B, Y).  

%Prédicat Prolog qui retourne l'élément d'un tableau situé à une position donnée
pos([], _, _):- write("La liste est vide").
pos([X|Xr], Y, X):- Y = 0.
pos([X|Xr], Y, Z) :-
    K is Y - 1,
    pos(Xr, K, Z).

%% Prédicat Prolog qui renvoie l'index d'un élément passé en argument avec le tableau.
index([], _, _) :- write('Le Tableau est vide').
index([X|Xr], X, 0).
index([X|Xr], A, N) :- index(Xr, A, G), N is G+1.
