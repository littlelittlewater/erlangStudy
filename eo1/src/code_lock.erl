%% gen_fsm ����
-module(code_lock).
-behaviour(gen_fsm).

-export([start_link/1]).
-export([button/1]).
-export([init/1, locked/2, open/2, stop/0]).
-export([code_change/4, handle_event/3, handle_info/3, handle_sync_event/4, terminate/3]).


 start_link(Code) ->
     % ��һ������{local, code_lock}ָ�����֣��ڱ���ע��Ϊcode_lock
     % �ڶ�������code_lock�ǻص�ģ��
     % ����������Code�Ǵ��ݸ��ص�ģ��init�����Ĳ���������ԭ�ⲻ�����ݸ��ص����� init ��
     % ���ĸ�[]��״̬����ѡ��
     gen_fsm:start_link({local, code_lock}, code_lock, Code, []).


%%�������Ҫ���� {ok, StateName, StateData}������ StateName ��gen_fsm��ʼ״̬�����֡�
 init(LockCode) ->
     io:format("init: ~p~n", [LockCode]),
   {ok, locked, {[], LockCode}}.

 %% ʹ��gen_fsm:send_event/2��ʵ�ְ����¼���֪ͨ
 %% gen_fsm:send_event -> Module:StateName/2
 %% ModuleΪ���õ�code_lock�ص�ģ�飬StateNameΪ�ص���������code_lock:locked
 -spec(button(Digit::string()) -> ok).
 button(Digit) ->
      %%code_lock ��gen_fsm�����ֲ��ұ���������ʱ����ʹ�õ�����һ�¡�{button��Digit}��ʵ�ʵ��¼���
     gen_fsm:send_event(code_lock, {button, Digit}).

 locked({button, Digit}, {SoFar, Code}) ->
     io:format("buttion: ~p, So far: ~p, Code: ~p~n", [Digit, SoFar, Code]),
   % �������ֵ��������
     InputDigits = lists:append(SoFar, Digit),
     case InputDigits of
         Code ->     % ����������ȷ
             do_unlock(),    % ����ʱҪִ�еĴ�����Է���do_unlock()������
             {next_state, open, {[], Code}, 10000};      % ������״̬Ϊopen��Ҳ��ʾ��ʱ10������open����
         Incomplete when length(Incomplete)<length(Code) ->  % ��������볤��С����ʵ����ĳ��ȣ�������δ��ɣ�
             {next_state, locked, {Incomplete, Code}, 5000}; % ��ʱ5������locked(timeout,{SoFar, Code})����
         Wrong ->    % �����������
             io:format("wrong passwd: ~p~n", [Wrong]),
             {next_state, locked, {[], Code}}    % ���������ֱ������Ѿ����������
     end;
 locked(timeout, {_SoFar, Code}) ->
     io:format("timout when waiting button inputting, clean the input, button again plz~n"),
     {next_state, locked, {[], Code}}.   % ��ʱ����Ѿ����������

 open(timeout, State) ->
     do_lock(),  % ����ʱҪִ�еĴ�����Է���do_unlock()������
     {next_state, locked, State}.    % ������ʱ����״̬��Ϊ����״̬

 code_change(_OldVsn, StateName, Data, _Extra) ->
     {ok, StateName, Data}.

 terminate(normal, _StateName, _Data) ->
     ok.

 %% gen_fsm:send_all_state_event(CallModule, Event) -> CallModule:handle_event(Event, StateName, Data)
 %% gen_fsm:send_all_state_event(code_lock, stop) -> code_lock:handle_event(stop, StateName, Date)
 stop() ->
     gen_fsm:send_all_state_event(code_lock, stop).

 %% ��ʱ��һ���¼����Ե���gen_fsm���̵��κ�״̬��
 %% ȡ����gen_fsm:send_event/2������Ϣ��дһ��ÿ��״̬���������¼��Ĵ��룬
 %% �����Ϣ���ǿ�����gen_fsm:send_all_state_event/2 ���ͣ���Module:handle_event/3����
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