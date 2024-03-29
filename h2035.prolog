%% -*- mode: prolog; coding: utf-8 -*-

%Auteurs : -Tchoumkeu Djeumen Thierry Manuel 20170651
%          - Medjahed Mehdi 20142385


%% GNU Prolog défini `new_atom`, mais SWI Prolog l'appelle `gensym`.
genatom(X, A) :-
    %% Ugly hack, âmes sensibles s'abstenir.
    (predicate_property(new_atom/2, built_in);    % Older GNU Prolog
     predicate_property(new_atom(_,_), built_in)) % Newer GNU Prolog
    -> new_atom(X, A);
    gensym(X, A).

debug_print(E) :- write(user_error, E), nl(user_error).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Description de la syntaxe des termes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Ces règles sont inutiles en soit, elle ne servent qu'à documenter pour
%% vous la forme des termes du langage H2035, ainsi que vous montrer quelques
%% primitives de Prolog qui peuvent vous être utiles dans ce TP, telles que
%% `=..`.

%% wf_type(+T)
%% Vérifie que T est un type syntaxiquement valide. Equivalent de la syntaxe dans le pdf du TP.
wf_type(int).
wf_type(bool).
wf_type(list(T)) :- wf_type(T).
wf_type((T1 -> T2)) :- wf_type(T1), wf_type(T2).
wf_type(Alpha) :- identifier(Alpha).
wf_type(forall(X,T)) :- atom(X), wf_type(T).
wf_type(X) :- var(X). %Une métavariable, utilisée pendant l'inférence de type.

%% wf(+E)
%% Vérifie que E est une expression syntaxiquement valide.
wf(X) :- integer(X).
wf(X) :- identifier(X).                   %Une constante ou une variable.
wf(lambda(X, E)) :- identifier(X), wf(E). %Une fonction.
wf(app(E1, E2)) :- wf(E1), wf(E2).        %Un appel de fonction.
wf(if(E1, E2, E3)) :- wf(E1), wf(E2), wf(E3).
wf((E : T)) :- wf(E), wf_type(T).
wf(?).                                  %Infère le code.
wf(E) :- E =.. [Head|Tail],
         (Head = let -> wf_let(Tail);
          identifier(Head), wf_exps(Tail)).

%% identifier(+X)
%% Vérifie que X est un identificateur valide, e.g. pas un mot réservé.
identifier(X) :- atom(X),
                 \+ member(X, [lambda, app, if, let, (:), (?)]).

wf_exps([]).
wf_exps([E|Es]) :- wf(E), wf_exps(Es).

wf_let([E]) :- wf(E).
wf_let([Rdecl|Tail]) :- wf_rdecl(Rdecl), wf_let(Tail).

wf_rdecl([]).
wf_rdecl(D) :- wf_decl(D).
wf_rdecl([D|Ds]) :- wf_decl(D), wf_rdecl(Ds).

wf_decl(X = E) :-
    wf(E),
    (identifier(X);
     X =.. [F|Args], identifier(F), wf_args(Args)).

wf_args([]).
wf_args([Arg|Args]) :- wf_args(Args), identifier(Arg).

%%%%%% ELABORATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% elaborate(+Env, +Exp, ?Type, -NewExp)
%% Infère/vérifie le type de Exp, élimine le sucre syntaxique, et remplace
%% les variables par des indexes de deBruijn.
%% Note: Le cut est utilisé pour éviter de tomber dans la dernière clause
%% (qui signale un message d'erreur) en cas d'erreur de type.
elaborate(_, E, _, _) :-
    var(E), !,
    debug_print(elaborate_nonclos(E)), fail.
elaborate(_, N, T, N) :- number(N), !, T = int.

elaborate(Env, X, _, var(I)) :-
    identifier(X),
    index(Env, (X, _), I),!. 
elaborate(Env, lambda(X,E), T, lambda(DE)) :-
    !, elaborate([(X,T1)|Env], E, T2, DE), T = (T1 -> T2).
%% ¡¡ REMPLIR ICI !!

%%Elaborate des expréssions booléenes
elaborate(Env, N, T, var(I)) :- N = true,!, index(Env, (N, T),I); N=false,!,index(Env, (N, T),I).
%%Elaborate de l'inverse de l'inference de type
elaborate(Env, E, T, Eretour):-
    E =.. [?, Middle, nil],
    elaborate(Env, cons(Middle, nil), T, Eretour),!.
elaborate(Env, E, T, N):-
    E=..[?, Middle, ?(Tail)],
    A = cons(Tail),
    elaborate(Env, Middle, _, Elab_Middle),
    elaborate(Env, A, _, Elab_Tail),
    elaborate(Env, cons(Elab_Middle, cons(Elab_Tail, nil)), T1, N),!.
%%Elaborate de l'inférence de types
elaborate(Env, E, Tail, E2):-
    E =.. [:, Middle, Tail],
    elaborate(Env, Middle, _, E2),!.
%%elaborate pour les expressions let
elaborate(Env, let([E1] ,E2), GT, let([R1], R2)):-!,
    (E1) =.. [= , Var, Exp],
    elaborate([(Var, T1)|Env], Exp,_, R1),
    elaborate([(Var, T1)|Env], E2, T, R2),
    generalize(Fenv, [(_,T)], [(_,GT)]).

%%elaborate pour le cas de base de l'operateur de constructeur de liste.
elaborate(Env, nil, T, var(I)):-
    index(Env, (nil, T), I),!.
%%Elaborate de la récursion de l'opérateur de constructeur de liste.
elaborate(Env, E, T, app(app(var(I), E1), Eautre)):-
    E=.. [Head, Middle, Tail],
    Head = cons,
    index(Env, (Head, T), I),
    elaborate(Env, Middle, _, E1),!,
    elaborate(Env, Tail, _, Eautre).
%%Elaborate pour empty
elaborate(Env, E, bool, app(var(Idx), N)):-
    E=.. [empty, E1],!,
    index(Env, (empty, T), Idx),
    elaborate(Env, E1, _, N).
%%Elaborate pour le car
elaborate(Env, E , T, app(var(Idx), R1)):-
    E=.. [car, E1],!,
    index(Env, (car, T),Idx),
    elaborate(Env, E1, _, R1).
%%Elaborate pour le cdr
elaborate(Env, E , T, app(var(Idx), R1)):-
    E=.. [cdr, E1],!,
    index(Env, (cdr, T), Idx),
    elaborate(Env, E1, _, R1).
%%elaborate pour le cas de base des opérations arithmétiques 
elaborate(Env, E, T, app(var(I), Eretour)):- 
    E =.. [Head,Eretour],
    index(Env
        , ((Head), (A -> T), _), I),!.
%%elaborate de la récursion des opérations arithmétiques 
elaborate(Env, E, T, app(app(var(I), E2), Eautre)):-
    E =.. [Head, Middle, Tail],
    index(Env, (Head,(A -> B -> T)), I),
    elaborate(Env,Middle , _, E2),
    elaborate(Env, Tail, _, Eautre),!.
%%elaborate des opérateurs conditionels (if(e1, e2, e3))
elaborate(Env, E, T, if(R1, R2, R3)):-
    E=.. [if, E1, E2, E3],!,
    elaborate(Env, E1, _, R1),
    elaborate(Env, E2, T, R2),
    elaborate(Env, E3, _, R3).


elaborate(_, E, _, _) :-
    debug_print(elab_unknown(E)), fail.

%% Ci-dessous, quelques prédicats qui vous seront utiles:
%% - instantiate: correspond à la règle "σ ⊂ τ" de la donnée.
%% - freelvars: correspond au "fv" de la donnée.
%% - generalize: fait le travail du "gen" de la donnée.

%% instantiate(+PT, -T)
%% Choisi une instance d'un type polymorphe PT.
instantiate(V, T) :- var(V), !, T = V.
instantiate(forall(X,T), T2) :-
    !, substitute(T, X, _, T1), instantiate(T1, T2).
instantiate(T, T).              %Pas de polymorphisme à instancier.


%% substitute(+Type1, +TVar, +Type2, -Type3)
%% Remplace TVar par Type2 dans Type1, i.e. `Type3 = Type1[Type2/TVar]`.
substitute(T1, _, _, T3) :- var(T1), !, T3 = T1.
substitute(X, X, T, T) :- !.
substitute(T1, X, T2, T3) :-
    %% T1 a la forme Head(Tail).  E.g. Head='->' et Tail=[int,int].
    %% Ça peut aussi être Head='int' et Tail=[].
    T1 =.. [Head|Tail],
    mapsubst(Tail, X, T2, NewTail),
    T3 =.. [Head|NewTail].

%% Applique `substitute' sur une liste.
mapsubst([], _, _, []).
mapsubst([T1|T1s], X, T2, [T3|T3s]) :-
    substitute(T1, X, T2, T3), mapsubst(T1s, X, T2, T3s).

%% freelvars(+E, -Vs)
%% Trouve toutes les variables logiques (i.e. variables Prolog) non
%% instanciées qui apparaissent dans le terme Prolog E, et les renvoie
%% dans la liste Vs.
freelvars(E, Vs) :- freelvars([], E, Vs).

memberFV(X,[Y|_]) :- X == Y, !.
memberFV(X,[_|XS]) :- memberFV(X,XS).

%% freelvars(+Vsi, +E, -Vso)
%% Règle auxiliaire de freelvars/2.
freelvars(Vsi, V, Vso) :-
    var(V), !,
    (memberFV(V, Vsi) -> Vso = Vsi; Vso = [V|Vsi]).
freelvars(Vsi, [T|Ts], Vso) :-
    !, freelvars(Vsi, T, Vs1),
    freelvars(Vs1, Ts, Vso).
freelvars(Vsi, E, Vso) :-
    (E =.. [_,T|Ts]) ->
        freelvars(Vsi, [T|Ts], Vso);
    Vso = Vsi.

%% generalize(+FVenv, +Env, -GEnv)
%% Généralise un morceau d'environnement Env en un morceau d'environnement
%% GEnv où chaque variable a été rendue aussi polymorphe que possible.
%% FVenv est la liste des variables libres de l'environnement externe.
generalize(_, [], []).
generalize(FVenv, [(X,T)|DeclEnv], [(X,GT)|GenEnv]) :-
    freelvars(T,FVs),
    gentype(FVenv, FVs, T, GT),
    generalize(FVenv, DeclEnv, GenEnv).

%% gentype(+FVenv, +FV, +T, -GT)
%% Généralise le type T en un type GT aussi polymorphe que possible.
%% FVenv est la liste des variables libres de l'environnement, et FV
%% est la liste des variables libres de T.
gentype(_, [], T, T).
gentype(FVenv, [V|Vs], T, GT) :-
    gentype(FVenv, Vs, T, GT1),
    (memberFV(V, FVenv) -> GT = GT1;
     genatom(t, V), GT = forall(V, T)).



%%%%%% EVALUATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% eval(+Env, +Exp, -Val)
%% Évalue Exp dans le context Env et renvoie sa valeur Val.
%% Note: Le cut est utilisé pour éviter de tomber dans la dernière clause
%% (qui signale un message d'erreur) en cas d'échec après l'évaluation,
%% i.e. pour distinguer le cas d'une expression que notre code ne couvre pas
%% des autres cas d'échec.
eval(_, E, _) :-
    var(E), !,
    debug_print(eval_nonclos(E)), fail.
eval(_, N, N) :- number(N), !.
eval(Env, var(Idx), V) :- !, nth_elem(Idx, Env, V).
eval(Env, lambda(E), closure(Env, E)) :- !.

%% ¡¡ REMPLIR ICI !!

%%Evaluation pour les constructeurs de liste
eval(Env, app(app(var(Idx), A), var(Indx2)), V):-!,
    index(Env, (builtin(C)), Idx),
    builtin(C, A, builtin(X)),
    builtin(X, [], V).
%%Evaluation pour les opérateurs sur les listes
eval(Env, app(var(Idx), E), V):-!,
    index(Env, (builtin(O)), Idx),
    eval(Env, E, R),
    builtin(O, R, V).
%%Evaluation pour l'opérateur conditionel
eval(Env, if(Cond, E1, E2), V):-!,
    eval(Env, Cond, true) -> eval(Env, E1, V);
    eval(Env, E2, V).

eval(Env, app(E1, E2), V) :-
    !, eval(Env, E1, V1),
    eval(Env, E2, V2),
    apply(V1, V2, V).

%%Evaluation pour les expressions arithmétiques
eval(Env, app(var(Indx), A), V):-!,
    index(Env,(builtin(S)), Indx),
   builtin(S, A, V).
eval(Env, app(app(var(I), E2), Eautre), V):-!,
    index(Env, (builtin(S)), I),
    eval(Env, E2, R2),
    eval(Env, Eautre, Rautre),
    builtin((+R2), Rautre, V).
% Evaluation de let  
eval(Env, let([E1], E2), V):-
    eval(Env, E1, Exp_Builtin),
    eval([Exp_Builtin|Env], E2, V).


eval(_, E, _) :-
    debug_print(eval_unknown(E)), fail.


%% apply(+Fun, +Arg, -Val)
%% Evaluation des fonctions et des opérateurs prédéfinis.
apply(closure(Env, Body), Arg, V) :- eval([Arg|Env], Body, V).
apply(builtin(BI), Arg, V) :- builtin(BI, Arg, V).
%% builtin(list, V, list(V)).
builtin((+), N1, builtin(+(N1))).
builtin(+(N1), N2, N) :- N is N1 + N2.
builtin(cons, X, builtin(cons(X))).
builtin(cons(X), XS, [X|XS]).
builtin(empty, X, Res) :- X = [] -> Res = true; Res = false.
builtin(car, [X|_], X).
builtin(cdr, [_|XS], XS).
builtin(cdr, [], []).

%% nth_elem(+I, +VS, -V)
%% Renvoie le I-ème élément de la liste Vs.
nth_elem(0, [V|_], V).
nth_elem(I, [_|Vs], V) :- I > 0, I1 is I - 1, nth_elem(I1, Vs, V).

%%%%%% TOP-LEVEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% env0(-Env)
%% Renvoie l'environnement initial combiné (types et valeurs).
env0([((+), (int -> int -> int), builtin(+)),
      (true, bool, true),
      (false, bool, false),
      (nil, forall(t, list(t)), []),
      (cons, forall(t, (t -> list(t) -> list(t))), builtin(cons)),
      (empty, forall(t, (list(t) -> bool)), builtin(empty)),
      (car, forall(t, (list(t) -> t)), builtin(car)),
      (cdr, forall(t, (list(t) -> list(t))), builtin(cdr))]).

%% Extrait l'environnement de typage de l'environnement combiné.
get_tenv([], []).
get_tenv([(X,T,_)|Env], [(X,T)|TEnv]) :- get_tenv(Env, TEnv).

%% tenv0(-TEnv)
%% Renvoie l'environnment de types initial.
tenv0(TEnv) :- env0(Env), get_tenv(Env, TEnv).

%% Extrait l'environnement de valeurs de l'environnement combiné.
get_venv([], []).
get_venv([(_,_,V)|Env], [V|VEnv]) :- get_venv(Env, VEnv).

%% venv0(-VEnv)
%% Renvoie l'environnment de valeurs initial.
venv0(VEnv) :- env0(Env), get_venv(Env, VEnv).

%% runelab(+Prog, -Type, -Elab)
%% Elabore Prog et renvoie le code élaboré et son type.
runelab(E, T, El) :- tenv0(TEnv), elaborate(TEnv, E, T, El).

%% runeval(+Prog, -Type, -Val)
%% Type et exécute le programme Prog dans l'environnement initial.
runeval(E, T, V) :- tenv0(TEnv), elaborate(TEnv, E, T, DE),
                   !,
                   venv0(VEnv), eval(VEnv, DE, V).

%% Exemples d'usage:
%% runeval(1 + 2, T, V).
%% runeval(app(lambda(x,x+1),3), T, V).
%% runeval(app(lambda(f,f(3)),lambda(x,x+1)), T, V).
%% runeval(let([x = 1], 3 + x), T, V).
%% runeval(let(f(x) = x+1, f(3)), T, V).
%% runeval(let([x = 1, x = lambda(a, a + 1)], (3 + x(x))), T, V).
%% runeval(cons(1,nil), T, V).
%% runeval(?(1,nil), T, V).
%% runeval(let([length = lambda(x, if(empty(x), 0, 1 + length(cdr(x))))],
%%             length(?(42,?(41,?(40,nil))))
%%             + length(cons(1,nil))),
%%         T, V).
%% runeval(let([length(x) = if(empty(x), 0, 1 + length(cdr(x)))],
%%             length(?(42,?(41,?(40,nil)))) + length(cons(4,nil))),
%%         T, V)
%% runeval(let([length = lambda(x, if(empty(x), 0, 1 + length(cdr(x))))],
%%             length(?(42,?(41,?(40,nil))))
%%             + length(cons(true,nil))),
%%         T, V).


%%Prédicats auxiliaires dont on aura besoin
%% Prédicat Prolog qui renvoie l'index d'un élément passé en argument avec le tableau.
index([], _, _) :- write('Le Tableau est vide').
index([X|Xr], X, 0).
index([X|Xr], A, N) :- index(Xr, A, G), N is G+1.
%%index([(X, Y)], (X, Y), 0).
%%index([(X, Y)|Resttab], A, N):- index(Resttab, A, G), N is G+1.