-module(bank_server).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([create_account/2]).

-define(I(F), io:format(F++"~n", [])).
-define(I(F, A), io:format(F++"~n", A)).

% --------------------------------------------------------------------
% API
% --------------------------------------------------------------------

%%'银行开户，并存入初始金额
-spec create_account(Name, Money) -> any() when
  Name :: atom(),
  Money :: integer().

create_account(Name, Money)->
  %% gen_server:start(Mod, Args, Options)
  {ok, Pid} = gen_server:start(?MODULE, [Money], []),
  %% 假设年费为10
  Pid ! {yearly, 60},
  erlang:register(Name, Pid).

% --------------------------------------------------------------------
% Callback
% --------------------------------------------------------------------

init([Money]) ->
  {ok, Money}.

handle_call(check, _From, Money) ->
  {reply, Money, Money};

handle_call(Request, _From, State) ->
  ?I("handle_call: ~p", [Request]),
  Reply = ok,
  {reply, Reply, State}.

handle_cast(Msg, State) ->
  ?I("handle_cast: ~p", [Msg]),
  {noreply, State}.

%%'存钱
handle_info({deposit, AddMoney}, Money) ->
  NewMoney = Money + AddMoney,
  ?I("deposit money: ~w -> ~w", [Money, NewMoney]),
  {noreply, NewMoney};
%%.

%%'取钱(可透支)
handle_info({cash1, SubMoney}, Money) ->
  NewMoney = Money - SubMoney,
  ?I("deposit money: ~w -> ~w", [Money, NewMoney]),
  {noreply, NewMoney};
%%.

%%'取钱(不可透支)
handle_info({cash2, SubMoney}, Money) ->
  NewMoney = Money - SubMoney,
  case NewMoney > 0 of
    true ->
      %% 支取成功
      ?I("deposit money: ~w -> ~w", [Money, NewMoney]),
      {noreply, NewMoney};
    false ->
      %% 支取失败 提示余额不足
      ?I("Insufficient balance, current money is ~w", [Money]),
      {noreply, Money}
  end;
%%.

%%'利息增加（这里假设10秒为一年）
handle_info({yearly, Payment}, Money) ->
  Year = case get(year) of
           undefined ->
             put(year, 0),
             0;
           Y ->
             YY = Y + 1,
             put(year, YY),
             YY
         end,
  erlang:send_after(60 * 1000, self(), {yearly, Payment}),
  Reply = if
            Money =< 0 ->
              %% 没有钱可以扣
              Money;
            Year =:= 0 ->
              %% 还不到一年，不用扣
              Money;
            true ->
              NewMoney = Money + Payment,
              case NewMoney > 0 of
                true ->
                  %% 扣费成功
                  ?I("Yearly Payment: ~w -> ~w", [Money, NewMoney]),
                  NewMoney;
                false ->
                  %% 余额不足以扣年费，则扣到0为止
                  ?I("Yearly Payment: ~w -> ~w", [Money, 0]),
                  0
              end
          end,
  {noreply, Reply};
%%.

%%'查询
handle_info(check, Money) ->
  ?I("Current money is: ~w", [Money]),
  {noreply, Money};

handle_info({From, check}, Money) ->
  %% ?I("Send result to: ~w", [From]),
  From ! {self(), Money},
  {noreply, Money};
%%.

handle_info(stop1, Money) ->
  ?I("Receive STOP1"),
  Reason = "Force STOP",
  {stop, Reason, Money};

handle_info(stop2, Money) ->
  ?I("Receive STOP2"),
  Reason = normal,
  {stop, Reason, Money};

handle_info(Info, State) ->
  ?I("handle_info: ~p", [Info]),
  {noreply, State}.

terminate(Reason, _State) ->
  ?I("terminate: ~p", [Reason]),
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.