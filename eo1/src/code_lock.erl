%% gen_fsm 测试
-module(code_lock).
-behaviour(gen_fsm).

-export([start_link/1]).
-export([button/1]).
-export([init/1, locked/2, open/2, stop/0]).
-export([code_change/4, handle_event/3, handle_info/3, handle_sync_event/4, terminate/3]).


 start_link(Code) ->
     % 第一个参数{local, code_lock}指定名字，在本地注册为code_lock
     % 第二个参数code_lock是回调模块
     % 第三个参数Code是传递给回调模块init函数的参数，将被原封不动传递给回调函数 init 。
     % 第四个[]是状态机的选项
     gen_fsm:start_link({local, code_lock}, code_lock, Code, []).


%%这个函数要返回 {ok, StateName, StateData}，其中 StateName 是gen_fsm初始状态的名字。
 init(LockCode) ->
     io:format("init: ~p~n", [LockCode]),
   {ok, locked, {[], LockCode}}.

 %% 使用gen_fsm:send_event/2来实现按建事件的通知
 %% gen_fsm:send_event -> Module:StateName/2
 %% Module为设置的code_lock回调模块，StateName为回调函数，即code_lock:locked
 -spec(button(Digit::string()) -> ok).
 button(Digit) ->
      %%code_lock 是gen_fsm的名字并且必须与启动时候所使用的名字一致。{button，Digit}是实际的事件。
     gen_fsm:send_event(code_lock, {button, Digit}).

 locked({button, Digit}, {SoFar, Code}) ->
     io:format("buttion: ~p, So far: ~p, Code: ~p~n", [Digit, SoFar, Code]),
   % 将输入的值连接起来
     InputDigits = lists:append(SoFar, Digit),
     case InputDigits of
         Code ->     % 密码输入正确
             do_unlock(),    % 解锁时要执行的代码可以放在do_unlock()方法中
             {next_state, open, {[], Code}, 10000};      % 解锁后状态为open，也表示超时10秒后调用open函数
         Incomplete when length(Incomplete)<length(Code) ->  % 输入的密码长度小于真实密码的长度（即输入未完成）
             {next_state, locked, {Incomplete, Code}, 5000}; % 超时5秒后调用locked(timeout,{SoFar, Code})方法
         Wrong ->    % 密码输入错误
             io:format("wrong passwd: ~p~n", [Wrong]),
             {next_state, locked, {[], Code}}    % 输入错误则直接清空已经输入的密码
     end;
 locked(timeout, {_SoFar, Code}) ->
     io:format("timout when waiting button inputting, clean the input, button again plz~n"),
     {next_state, locked, {[], Code}}.   % 超时清空已经输入的密码

 open(timeout, State) ->
     do_lock(),  % 上锁时要执行的代码可以放在do_unlock()方法中
     {next_state, locked, State}.    % 解锁超时后则将状态该为上锁状态

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