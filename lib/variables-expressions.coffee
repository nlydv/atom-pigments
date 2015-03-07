{strip} = require './utils'
ExpressionsRegistry = require './expressions-registry'
VariableExpression = require './variable-expression'

module.exports = registry = new ExpressionsRegistry(VariableExpression)

registry.createExpression 'less', '(@[a-zA-Z0-9\\-_]+)\\s*:\\s*([^;\\n]+);?'

registry.createExpression 'scss', '(\\$[a-zA-Z0-9\\-_]+):\\s*(.*?)(\\s*!default)?;'

registry.createExpression 'sass', '(\\$[a-zA-Z0-9\\-_]+):\\s*(.*?)(\\s*!default)?$'

registry.createExpression 'stylus_hash', '([a-zA-Z_$][a-zA-Z0-9\\-_]*)\\s*=\\s*\\{([^=]*)\\}', (match, solver) ->
  buffer = ''
  [match, name, content] = match
  current = match.indexOf(content)
  scope = [name]
  scopeBegin = /\{/
  scopeEnd = /\}/
  commaSensitiveBegin = /\(|\[/
  commaSensitiveEnd = /\)|\]/
  inCommaSensitiveContext = false
  for char in content
    if scopeBegin.test(char)
      scope.push buffer.replace(/[\s:]/g, '')
      buffer = ''
    else if scopeEnd.test(char)
      scope.pop()
      return solver.endParsing(current) if scope.length is 0
    else if commaSensitiveBegin.test(char)
      buffer += char
      inCommaSensitiveContext = true
    else if inCommaSensitiveContext
      buffer += char
      inCommaSensitiveContext = !commaSensitiveEnd.test(char)
    else if /[,\n]/.test(char)
      buffer = strip(buffer)
      if buffer.length
        [key, value] = buffer.split(/\s*:\s*/)

        solver.appendResult([
          scope.concat(key).join('.')
          value
          current - buffer.length - 1
          current
        ])

      buffer = ''
    else
      buffer += char

    current++

  solver.endParsing(match.length)

registry.createExpression 'stylus', '([a-zA-Z_$][a-zA-Z0-9\\-_]*)\\s*=\\s*([^\\n;]*);?$'