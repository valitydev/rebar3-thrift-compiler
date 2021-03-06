-module(rebar3_thrift_compiler_prv_compile).

-export([init/1, do/1, format_error/1]).

%% Public API

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.

init(State) ->
    Provider = providers:create([
        {name, 'compile'},
        {namespace, 'thrift'},
        {module, ?MODULE},
        {bare, true},
        {deps, [{default, app_discovery}]},
        {example, "rebar3 thrift compile"},
        {short_desc, "Compile Thrift IDL files using thrift compiler"},
        {desc,
            "Compile Thrift IDL files using thrift compiler."
            "\n\n"
            "Compilation process scans for all *.thrift files in the `in` directory, "
            "fires `thrift` shell command with required arguments for each one of them, "
            "collects artifacts and stuffs them to respective directories. Source files "
            "fall in `erlout` directory and headers fall in `hrlout` directory."
            "\n\n"
            "It's possible to explicitly specify *.thrift files to compile with command args:\n"
            "$ rebar3 thrift compile -- file1.thrift file2.thrift ..."
            "\n\n"
            "Options available in `rebar.config`:"
            "\n\n"
            % Strive to keep in sync with README.md
            "  {thrift_compiler_opts, [\n"
            "    % Directory where *.thrift files are located, relative to application root\n"
            "    {in_dir, \"proto\"},\n"
            "    % Explicit list of files to compile instead of every single *.thrift file"
            "    % found inside the `in_dir`\n"
            "    {in_files, [\"file1.thrift\", ...]},\n"
            "    % Directory to put all generated *.erl files into, relative to application"
            "    % output directory\n"
            "    {out_erl_dir, \"src\"},\n"
            "    % Directory to put all generated *.hrl files into, relative to application"
            "    % output directory\n"
            "    {out_hrl_dir, \"include\"},\n"
            "    % List of directories searched for include directives\n"
            "    {include_dirs, []},\n"
            "    % Generator (with arbitrary flags) to use when compiling *.thrift files\n"
            "    {gen, \"erl:legacy_names\"},\n"
            "    % Tell compiler to generate code recursively (i.e. generate module for each"
            "    % transitively included thrift file)\n"
            "    % [default: false]\n"
            "    {recursive, true},\n"
            "    % Tell compiler to run in strict mode (will emit warnings more often)\n"
            "    % [default: false]\n"
            "    {strict, true}\n"
            "  ]}."
            "\n"},
        {opts, opts()}
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.

opts() ->
    [
        {in_dir, $I, "in", string,
            "Directory where *.thrift files are located, relative to application root"
            " (default = \"proto\")"},
        {out_erl_dir, $o, "erlout", string,
            "Directory to put all generated *.erl files into, relative to application output directory"
            " (default = \"src\")"},
        {out_hrl_dir, $O, "hrlout", string,
            "Directory to put all generated *.hrl files into, relative to application output directory"
            " (default = \"include\")"},
        {gen, $g, "gen", string,
            "Generator (with flags) to use when compiling *.thrift files"
            " (default = \"erl\")"}
    ].

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.

do(State) ->
    Cwd = rebar_state:dir(State),
    Providers = rebar_state:providers(State),
    rebar_hooks:run_all_hooks(Cwd, pre, thrift, Providers, State),
    CmdOpts = rebar_state:command_parsed_args(State),
    ok = lists:foreach(
        fun(AppInfo) -> rebar3_thrift_compiler_prv:compile(AppInfo, CmdOpts, State) end,
        get_apps(State)
    ),
    {ok, State}.

-spec get_apps(rebar_state:t()) -> [rebar_app_info:t()].

get_apps(State) ->
    case rebar_state:current_app(State) of
        undefined ->
            rebar_state:project_apps(State);
        AppInfo ->
            [AppInfo]
    end.

-spec format_error(any()) -> iolist().

format_error(Reason) ->
    io_lib:format("~p", [Reason]).
