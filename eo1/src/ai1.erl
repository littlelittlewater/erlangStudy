%% gen_fsm 测试
-module(ai1).
-behaviour(gen_fsm).
-define(I(F), io:format(F ++ "~n", [])).
-define(I(F, A), io:format(F ++ "~n", A)).
-export([start_link/1]).
-export([ get_card/0]).
-export([init/1, stop/0]).
-export([code_change/4, handle_event/3, handle_info/3, handle_sync_event/4, terminate/3]).


start_link(Name) ->
  gen_fsm:start_link({local, Name}, Name, Name).


%%把这个ai加入积分系统
init(Name) ->
  io:format("init: ~p~n", [Name]),
  bank_server:create_account(Name, 10000),
  {ok, idle, Name}.

%% 使用gen_fsm:send_event/2来实现按建事件的通知
%% gen_fsm:send_event -> Module:StateName/2
%% Module为设置的code_lock回调模块，StateName为回调函数，即code_lock:locked

get_card() -> get(card).

idle(start, Name) ->
  % 上锁时要执行的代码可以放在do_unlock()方法中
  Card = poke:get_card(3),
  put(card, Card),
  console:add(100),
  {next_state, addMoney, 100, {Name, Card}}.
%%这个状态可能会变成结束状态  或者继续加价的状态
addMoney(start, {Name, Card}) ->
  case ai(Card) of
    {addedMoney, Money} ->
      console:add(Name, {times, Money}),
      {next_state, addMoney, {Name, Card}};
    {result} ->
      console:result(Name),
      {next_state, idle, {Name, Card}}
  end.


ai(Card) ->
  Socre = poke:get_level1(Card),
  Turn = get(turn),
  dosomething(Socre, Turn).

dosomething(Socre, Turn) when Socre > 6 * 100 * 100 * 100 andalso Turn < 14 ->
  {addedMoney, ai_follow(big)};
dosomething(Socre, Turn) when Socre > 5 * 100 * 100 * 100 andalso Turn < 11 ->
  {addedMoney, ai_follow(big)};
dosomething(Socre, Turn) when Socre > 4 * 100 * 100 * 100 andalso Turn < 9 ->
  {addedMoney, ai_follow(middle)};
dosomething(Socre, Turn) when Socre > 3 * 100 * 100 * 100 andalso Turn < 7 ->
  {addedMoney, ai_follow(middle)};
dosomething(Socre, Turn) when Socre > 2 * 100 * 100 * 100 andalso Turn < 6 ->
  {addedMoney, ai_follow(little)};
dosomething(Socre, Turn) when Socre > 1 * 100 * 100 * 100 andalso Turn < 4 ->
  {addedMoney, ai_follow(little)};
dosomething(_Socre, _Turn) ->
  {result}.

ai_follow(Money) ->
  random:seed(erlang:now()),
  Index = random:uniform(100),
  case Money of
    big when Index > 70 -> random:uniform(20) + 200;
    big when Index > 50 -> random:uniform(30) + 150;
    big when Index > 0 -> random:uniform(40) + 100;
    middle when Index > 70 -> random:uniform(40) + 200;
    middle when Index > 30 -> random:uniform(30) + 150;
    middle when Index > 0 -> random:uniform(20) + 100;
    little when Index > 98 -> random:uniform(40) + 200;
    little when Index > 0 -> random:uniform(10) + 100
  end / 100.



code_change(_OldVsn, StateName, Data, _Extra) ->
  {ok, StateName, Data}.

terminate(normal, _StateName, _Data) ->
  ok.

%% gen_fsm:send_all_state_event(CallModule, Event) -> CallModule:handle_event(Event, StateName, Data)
%% gen_fsm:send_all_state_event(code_lock, stop) -> code_lock:handle_event(stop, StateName, Date)
stop() ->
  gen_fsm:send_all_state_event(code_lock, stop).

%% 有时候一个事件可以到达gen_fsm进程的任何状态，
%% 取代用gen_fsm:send_event/2发送消息和写一段每个状态函数处理事件的代码，
%% 这个消息我们可以用gen_fsm:send_all_state_event/2 发送，用Module:handle_event/3处理
handle_event(Event, StateName, Data) ->
  io:format("handle_event... ~n"),
  unexpected(Event, StateName),
  {next_state, StateName, Data}.

%% gen_fsm:sync_send_all_state_event -> Module:handle_sync_event/4
handle_sync_event(Event, From, StateName, Data) ->
  io:format("handle_sync_event, for process: ~p... ~n", [From]),
  unexpected(Event, StateName),
  {next_state, StateName, Data}.

handle_info(Info, StateName, Data) ->
  io:format("handle_info...~n"),
  unexpected(Info, StateName),
  {next_state, StateName, Data}.


%% Unexpected allows to log unexpected messages
unexpected(Msg, State) ->
  io:format("~p RECEIVED UNKNOWN EVENT: ~p, while FSM process in state: ~p~n",
    [self(), Msg, State]).

%% actions
do_unlock() ->
  io:format("passwd is right, open the DOOR.~n").

do_lock() ->
  io:format("over, close the DOOR.~n").