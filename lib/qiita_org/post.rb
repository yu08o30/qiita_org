# -*- coding: utf-8 -*-
#+begin_src ruby -n
require "net/https"
require "json"
require 'command_line/global'

class QiitaPost
  def get_title_tags(src)
    $conts = File.read(src)
    title =  $conts.match(/\#\+(TITLE|title|Title): (.+)/)[2] || "テスト"
    m = []
    tags = if m =  $conts.match(/\#\+(TAG|tag|Tag|tags|TAGS|Tags): (.+)/)
             m[2].split(',').inject([]) do |l, c|
        l << {name: c.strip} #, versions: []}
      end
           else
             [{ name: "hoge"}] #, versions: [] }]
           end
    p tags
    return title,tags
  end

  def initialize(file, mode)
    src = file
    title, tags = get_title_tags(src)
    p command = "emacs #{src} --batch -l ~/.emacs.d/site_lisp/ox-qmd -f org-qmd-export-to-markdown --kill"
    res = command_line command
    p res
    lines = File.readlines(src.gsub('org','md'))
    path = Dir.pwd.gsub(ENV['HOME'],'~')
    lines << "------\n - **source** #{path}/#{src}\n"

    m = []
    patch = false
    if m = $conts.match(/\#\+qiita_id: (.+)/)
      qiita_id = m[1]
      patch = true
    else
      qiita_id = ''
    end

    m = []
    if mode == "open" || mode == nil
      mode = "qiita"
    end
    p mode
    patch = false
    if m = $conts.match(/\#\+#{mode}_id: (.+)/)
      qiita_id = m[1]
      patch = true
    else
      qiita_id = ""
    end

    case mode
    when 'teams'
      qiita = 'https://nishitani.qiita.com/'
      p access_token = ENV['QIITA_TEAM_WRITE_TOKEN']
      private = false
    when 'qiita'
      qiita = 'https://qiita.com/'
      p access_token = ENV['QIITA_WRITE_TOKEN']
      private = false
    else
      qiita = 'https://qiita.com/'
      p access_token = ENV['QIITA_WRITE_TOKEN']
      private = true
    end

    params = {
      "body": lines.join, #"# テスト",
      "private": private,
      "title": title,
      "tags": tags
    }

    if patch
      path = "api/v2/items/#{qiita_id}"
    else
      path = 'api/v2/items'
    end
    p qiita+path
    uri = URI.parse(qiita+path)

    http_req = Net::HTTP.new(uri.host, uri.port)
    http_req.use_ssl = uri.scheme === "https"

    headers = {"Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json"}
    if patch
      res = http_req.patch(uri.path, params.to_json, headers)
    else
      res = http_req.post(uri.path, params.to_json, headers)
    end

    p res.message

    res_body = JSON.parse(res.body)
    res_body.each do |key, cont|
      if key == 'rendered_body' or key == 'body'
        puts "%20s brabrabra..." % key
        next
      end
      print "%20s %s\n" % [key, cont]
    end
    system "open #{res_body["url"]}"
    qiita_id =res_body["id"]
    unless patch
      File.write(src, "#+#{mode}_id: #{qiita_id}\n" + $conts)
    end
  end
end

#+end_src
