$cr = window.$cr = window.$cr or {}

cache = {}

$cr.tmpl = (id, context) ->
  tmpl = cache[id]
  if not tmpl
    tmpl = cache[id] = Mustache.compile $('#tmpl-' + id).html()
  tmpl(context)
