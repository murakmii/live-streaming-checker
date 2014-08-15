"use strict"

# URLに対するGETリクエストをキューに入れて指定の間隔で実行する
class RequestQueue

   _request: ( ) ->
      req_param = @_queue.shift( )
      unless req_param?
         @_requesting = false
         return

      @_requesting = true
      core.Util.getRequest req_param.url, ( success, xhr ) =>
         req_param.callback( success, xhr )
         setTimeout @_request.bind( this ), @_interval

   constructor: ( @_interval ) ->
      @_requesting = false
      @_queue = [ ]

   queuing: ( url, fn ) ->
      # 同一URLに対するリクエストがまだキューに残っている場合、リクエストを受理しない
      for q in @_queue
         return if q.url is url

      @_queue.push ( url: url, callback: fn )
      @_request( ) unless @_requesting

@core.RequestQueue = RequestQueue

