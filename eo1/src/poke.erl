%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 六月 2018 15:05
%%%-------------------------------------------------------------------
-module(poke).
-author("Administrator").
-define(Debug,false).
-define(I(F),case ?Debug of ture -> io:format(F ++ "~n", []);false -> false end).
-define(I(F, A), case ?Debug of ture -> io:format(F ++ "~n", A); false -> false end).
-behaviour(gen_server).

%% API
-export([start_link/0, get_card/0, get_card/1, get_level2/1, compare/2, get_level1/1]).
-export([init_poke/0, test/0]).
%% gen_server callbacks
-export([init/1,
  handalsole_call/3,
  handalsole_cast/2,
  handalsole_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {}).

-record(poke_card, {
  type,
  point
}).


%%%===================================================================
%%% API
%%%===================================================================
%%%创建poke牌堆
init_poke() ->
  NotUsed = addpoke([]),
  ?I("init result is ~w", [NotUsed]),
  random:seed(erlang:now()),
  put(poke_dump,NotUsed),
  start_link().
%%--------------------------------------------------------------------
%%开始
%%--------------------------------------------------------------------
-spec(start_link() ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


init([]) ->
  {ok, #state{}}.


%% 添加扑克牌
addpoke([]) ->
  Ret = add_point(),
  add_color([], Ret).

%% 添加点数
add_point() ->
  Ret = [ 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,14],
  add_color(Ret,[]).


%% 添加颜色
add_color(Ret, []) ->
  Ret;
add_color(Ret, [Head | Tail]) ->
  add_color([#poke_card{type = heart, point = Head}, #poke_card{type = spade, point = Head}, #poke_card{type = diamond, point = Head}, #poke_card{type = club, point = Head}] ++ Ret, Tail).

%%获取多张卡牌
get_card(Number)->
  Got  =  get_card1(Number),
  ?I("i got  ~w  poke  ~w ", [Number,Got]),
  Got.
%%取出最后一张牌
get_card1(1) ->
  [get_card()] ;
get_card1(Number)  when Number > 1 ->
    [get_card()|get_card1(Number -1)].

%%获取一张卡牌   从已有的卡堆里头随机都丑一张牌
get_card() ->
  PokeDump = get(poke_dump),
  ?I("i got ~w", [PokeDump]),

  Index = random:uniform(length(PokeDump)),
  GotCard= lists:nth(Index,PokeDump),
  NotUsed1=lists:delete(GotCard,PokeDump),
  put(poke_dump,NotUsed1),
  ?I("i got  ~w  poke  ~w ", [Index,GotCard]),
  print_dump(),
  GotCard.

%%compare 比较大小
compare(CardA,CardB)  ->
  get_level1(CardA) > get_level1(CardB) .


get_level1(Card) ->
  Soreted = lists:keysort(3, Card),
  {Level,Info} = get_level2(Soreted),
  ?I("you card is ~w you level is ~w , Info is ~w",[Card,Level,Info]),
  Level*1000000 + Info.

get_level2([{poke_card,_A,_Apoint},{poke_card,_B,_Bpoint},{poke_card,_C,_Cpoint}])  when _Apoint == _Bpoint andalso _Bpoint == _Cpoint
  ->{6,_Apoint* 10000};

get_level2([{poke_card,_A,_Apoint},{poke_card,_B,_Bpoint},{poke_card,_C,_Cpoint}])  when _A =:= _B andalso _B =:= _C andalso  _Apoint + 2 =:= _Bpoint + 1 andalso _Bpoint + 1=:= _Cpoint
  ->{5,_Apoint* 10000};

get_level2([{poke_card,_A,_Apoint},{poke_card,_B,_Bpoint},{poke_card,_C,_Cpoint}])  when _A =:= _B andalso _B =:= _C
  ->{4,_Apoint*1 + _Bpoint * 100 + _Cpoint * 10000};

get_level2([{poke_card,_A,_Apoint},{poke_card,_B,_Bpoint},{poke_card,_C,_Cpoint}])  when _Apoint + 2 =:= _Bpoint + 1 andalso _Bpoint + 1=:= _Cpoint
  ->{3,_Apoint* 10000};

get_level2([{poke_card,_A,_Apoint},{poke_card,_B,_Bpoint},{poke_card,_C,_Cpoint}])    when _Apoint =:= _Bpoint
  ->{2,_Cpoint*100 + _Bpoint * 10000 };

get_level2([{poke_card,_A,_Apoint},{poke_card,_B,_Bpoint},{poke_card,_C,_Cpoint}])    when _Apoint =:= _Cpoint
  ->{2,_Cpoint*100 + _Bpoint * 10000 };

get_level2([{poke_card,_A,_Apoint},{poke_card,_B,_Bpoint},{poke_card,_C,_Cpoint}])    when _Bpoint =:= _Cpoint
  ->{2,_Cpoint*100 + _Bpoint * 10000 };

get_level2([{poke_card,_A,_Apoint},{poke_card,_B,_Bpoint},{poke_card,_C,_Cpoint}])
  ->{1,_Apoint*1 + _Bpoint * 100 + _Cpoint * 10000}.
comparePoint() ->false.



print_dump() ->
  PokeDump  = get(poke_dump),
  ?I("the dump size is   ~w  ,they are   ~w ", [length(PokeDump),PokeDump]),
  true.

handalsole_call(get_poke, _From, State) ->
  ?I("deposit money: "),
  {reply, {ok, State}, State};
handalsole_call(_Request, _From, State) ->
  {reply, ok, State}.




handalsole_cast(_Request, State) ->
  {noreply, State}.


handalsole_info(check, Money) ->
  ?I("Current money is: ~w", [Money]),
  {noreply, Money};
handalsole_info(_Info, State) ->
  {noreply, State}.



terminate(_Reason, _State) ->
  ok.



code_change(_OldVsn, State, _Extra) ->
  {ok, State}.


test()  ->
  init_poke(),
  A = get_card(3),
  B = get_card(3),
  io:format(compare(A,B)).



