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
-define(I(F), io:format(F ++ "~n", [])).
-define(I(F, A), io:format(F ++ "~n", A)).
-behaviour(gen_server).

%% API
-export([start_link/0, get_card/0, get_card/1]).
-export([init_poke/0, test/0]).
%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
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
  Ret = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13],
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
  get_card() ;
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
  case    get_level(CardA) > get_level(CardB) of
    true->  io:format("A Win ");
    false-> io:format("B Win ")
  end .


get_level([{poke_card,_A,Apoint},{poke_card,_B,Bpoint}|{poke_card,_C,Cpoint}])  ->
     Point = Apoint + Bpoint  + Cpoint ,
     ?I("point 是 ~w",[Point]),
     Point.

comparePoint() ->false.
print_dump() ->
  PokeDump  = get(poke_dump),
  ?I("the dump size is   ~w  ,they are   ~w ", [length(PokeDump),PokeDump]),
  true.

handle_call(get_poke, _From, State) ->
  ?I("deposit money: "),
  {reply, {ok, State}, State};
handle_call(_Request, _From, State) ->
  {reply, ok, State}.




handle_cast(_Request, State) ->
  {noreply, State}.


handle_info(check, Money) ->
  ?I("Current money is: ~w", [Money]),
  {noreply, Money};
handle_info(_Info, State) ->
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



