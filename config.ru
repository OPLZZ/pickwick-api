$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require File.expand_path('../lib/pickwick-api',  __FILE__)

run Pickwick::API::Application
