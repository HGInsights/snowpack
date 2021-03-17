%{
  configs: [
    %{
      name: "default",
      files: %{
        included: [
          "lib/",
          "src/",
          "test/",
          "web/",
          "apps/*/lib/",
          "apps/*/src/",
          "apps/*/test/",
          "apps/*/web/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      requires: [],
      strict: false,
      color: true,
      checks: [
        # enabled extra Credo checks
        {Credo.Check.Readability.AliasAs, []},
        {Credo.Check.Readability.SinglePipe, []},
        {Credo.Check.Readability.StrictModuleLayout, order: ~w/
          shortdoc
          moduledoc
          behaviour
          use
          import
          alias
          require
          module_attribute
          defstruct
          opaque
          type
          typep
          callback
          macrocallback
          optional_callbacks
          public_guard
          public_macro
          public_fun
          impl
          private_fun
        /a,
        ignore: ~w/
          private_macro
          callback_impl
          private_guard
          module
        /a},
        {Credo.Check.Readability.Specs, []},

        # modified checks
        {Credo.Check.Design.TagTODO, [exit_status: 0]},

        # disabled checks
        {Credo.Check.Readability.ModuleDoc, false}
      ]
    }
  ]
}
