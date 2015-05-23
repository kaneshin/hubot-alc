# Description:
#   alc
#
# Dependencies:
#   "htmlparser": "1.7.6"
#   "soupselect": "0.2.0"
#
# Configuration:
#   None
#
# Commands:
#   hubot alc me <word> - Show result of word in Japanese
#
# Author:
#   kaneshin

Select     = require("soupselect").select
HtmlParser = require "htmlparser"

alcUri = "http://eow.alc.co.jp"

module.exports = (robot) ->
  robot.respond /alc( me)? (.+)/i, (msg) ->
    for query, _ in (item for item in msg.match[2].split(" ") when item != '')
      msg.http(alcUri + "/search").query(q: query).get() (err, res, body) ->
        message = [alcUri + res.client._httpMessage.path]
        if res.statusCode is 200
          if res.headers['content-type'].indexOf('text/html') != 0
            return

          handler = new HtmlParser.DefaultHandler()
          parser  = new HtmlParser.Parser handler
          parser.parseComplete body

          try
            results = (Select handler.dom, "#resultsList ul li")
          catch RangeError
            return

          processResult = (elem) ->
            (item.raw for item, _ in elem.children when item.type is 'text').join("")

          if results[0]
            span = (Select results[0], "div span.wordclass")
            for ol, i in (Select results[0], "div ol")
              message.push processResult(span[i])
              list = (Select ol, "li")
              if list.length is 0
                message.push processResult(ol)
              else
                (message.push (j + 1) + ". " + processResult(li) for li, j in list when j < 3)
          else
            message.push "Not Found"

        else
          message.push "Error " + res.statusCode

        msg.send message.join("\n")

