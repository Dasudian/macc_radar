% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                                                         %
%  This file is created as part of research done by the Multi-Agent Coordination & Control (MACC) group.  %
%                                                                                                         %
%  (C) 2013 Johan Philips, Bart Saint Germain, Jan Van Belle, Paul Valckenaers, macc.radar@gmail.com      %
%                                                                                                         %
%  Department of Mechanical Engineering, Katholieke Universiteit Leuven, Belgium.                         %
%                                                                                                         %
%  You may redistribute this software and/or modify it under either the terms of the GNU Lesser           %
%  General Public License version 2.1 (LGPLv2.1 <http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>) %
%  or (at your discretion) of the Modified BSD License:                                                   %
%  Redistribution and use in source and binary forms, with or without modification, are permitted         %
%  provided that the following conditions are met:                                                        %
%     1. Redistributions of source code must retain the above copyright notice, this list of              %
%        conditions and the following disclaimer.                                                         %
%     2. Redistributions in binary form must reproduce the above copyright notice, this list of           %
%        conditions and the following disclaimer in the documentation and/or other materials              %
%        provided with the distribution.                                                                  %
%     3. The name of the author may not be used to endorse or promote products derived from               %
%        this software without specific prior written permission.                                         %
%  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,    %
%  BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE     %
%  ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,  %
%  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS    %
%  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY        %
%  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR           %
%  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY      %
%  OF SUCH DAMAGE.                                                                                        %
%                                                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
-module(server).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2,
         handle_info/2, code_change/3, terminate/2]).
-export([start_link/1, stop/1]).

-include("states.hrl").

stop(Id) -> 
	gen_server:call(Id, stop, ?callTimeout).

start_link(ComState=#comState{init=Init,ip=Ip,port=Port,parser=Parser})
	when is_function(Init) and
		 is_tuple(Ip) and 
		 is_integer(Port) and 
		 is_function(Parser) ->
	gen_server:start_link(?MODULE, [ComState], []);
start_link(Other) ->
	util:log(error, server, "Invalid com state for server: ~w", [Other]).

% init server
init([ServerState=#comState{init=Init}]) ->
    %% To know when the parent shuts down
    process_flag(trap_exit, true),
	case Init(ServerState) of
		ok -> 
			util:log(info, server,"Initialized server for ~w:~w at ~w.", [ServerState#comState.ip, ServerState#comState.port, self()]),
			{ok, ServerState};
		error ->
			util:log(error, server, "Initialization of server ~w failed!", [ServerState]),
			{stop, "Initialization failed"}
	end.

	
handle_call({request, Data}, _From, S=#comState{parser=Parser}) ->
	Result = Parser(Data),
	util:log(info, server, "Server ~w parsed request with result: ~p",[self(),Result]),
	{reply, {reply,request,Result}, S};
handle_call(stop, _From, S) ->
    {stop, normal, ok, S};
handle_call(_Message, _From, S) ->
    {noreply, S}.

handle_cast(_Message, S) ->
    {noreply, S}.

handle_info({request, Data}, S=#comState{parser=Parser}) ->
	Parser(Data),
	{noreply, S};
	
handle_info(Message, S) ->
	util:log(error, server, "Server ~w received unknown message ~w",[self(),Message]),
    {noreply, S}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(normal, _S) ->
    io:format("Server terminated normally~n",[]);
terminate(shutdown, _S) ->
    io:format("Server got shutdown~n",[]);
terminate(Reason, _S) ->
    io:format("Server got killed with reason: ~w~n", [Reason]).