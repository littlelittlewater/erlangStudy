{application, o3,
 [{description, "A simple caching system"},
  {vsn, "0.1.0"},
  {modules, [
        gen_server_skel,
   simple,tr_server
            ]},

  {applications, [kernel, stdlib]}

 ]}.
