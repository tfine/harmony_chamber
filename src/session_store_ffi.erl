-module(session_store_ffi).
-export([safe_binary_to_term/1]).

safe_binary_to_term(Binary) ->
    Tag = <<"harmony_snapshot_v2">>,
    try binary_to_term(Binary) of
        {RawTag, Session} ->
            case normalize_tag(RawTag) of
                Tag -> {ok, Session};
                _ -> {error, <<"invalid_snapshot">>}
            end;
        _ ->
            {error, <<"invalid_snapshot">>}
    catch
        Class:Reason ->
            Message = unicode:characters_to_binary(
                io_lib:format("~p:~p", [Class, Reason])
            ),
            {error, Message}
    end.

normalize_tag(Tag) when is_binary(Tag) ->
    Tag;
normalize_tag(Tag) when is_list(Tag) ->
    unicode:characters_to_binary(Tag);
normalize_tag(_) ->
    <<>>.
