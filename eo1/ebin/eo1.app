{application, eo1,
 [{description, "A simple caching system"},
  {vsn, "0.1.0"},
  {modules, [
        poke,bank_server,console
            ]},

  {applications, [kernel, stdlib]}

 ]}.
