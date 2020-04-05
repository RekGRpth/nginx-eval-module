# vi:filetype=

use lib 'lib';
use Test::Nginx::Socket; # skip_all => 'ngx_memc storage commands do not work with the ngx_eval module';

repeat_each(2);

plan tests => repeat_each() * 2 * blocks();

$ENV{TEST_NGINX_MEMCACHED_PORT} ||= 11211;

no_long_string();
#no_diff;

run_tests();

__DATA__

=== TEST 1: bug
--- main_config
    load_module /etc/nginx/modules/ngx_http_eval_module.so;
--- config
    location = /eval {
             eval_escalate on;
             eval $var {
                 set $foo bar;
                 return 403;
             }
            return 405;
    }
--- request
    GET /eval
--- response_body_like: 403 Forbidden
--- error_code: 403



=== TEST 2: bug
--- SKIP
--- main_config
    load_module /etc/nginx/modules/ngx_http_eval_module.so;
--- config
location /eval/ {
         rewrite   /eval(.*)$  $1 break;
          eval $res {
               set $memc_key $host:$request_uri;
               set $memc_value 1;
               set $memc_cmd incr;
               memc_pass 127.0.0.1:11211;
          }
           resolver 10.40.6.72;
           proxy_pass http://www.yahoo.com/;
       }
--- request
    GET /eval
--- response_body
--- SKIP



=== TEST 3: github issue #1: "eval" hangs in named locations.
--- main_config
    load_module /etc/nginx/modules/ngx_http_echo_module.so;
    load_module /etc/nginx/modules/ngx_http_eval_module.so;
--- config
    location @eval {
         eval $var {
            proxy_pass http://127.0.0.1:$server_port/echo;
         }
         echo $var;
    }

    location /echo {
        echo hello;
    }

    location /t {
        echo_exec @eval;
    }
--- request
    GET /t
--- response_body
hello

