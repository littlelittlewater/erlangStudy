%% ---
%%  Excerpted from "Programming Erlang",
%%  published by The Pragmatic Bookshelf.
%%  Copyrights apply to this code. It may not be used to create training material, 
%%  courses, books, articles, and the like. Contact us if you are in doubt.
%%  We make no guarantees that this code is fit for any purpose. 
%%  Visit http://www.pragmaticprogrammer.com/titles/jaerlang for more book information.
%%---
-module(shop1).
-export([total/1,test/0]).

total([{What, N}|T]) -> shop:cost(What) * N + total(T);
total([])            -> 0.

test() ->
    7 = total([{milk,1}]),

  16 = total([{milk,1},{pears,1}]).

