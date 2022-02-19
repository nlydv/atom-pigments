registry = require '../../lib/color-expressions'
Pigments = require '../../lib/pigments'

deserializers =
  Palette: 'deserializePalette'
  ColorSearch: 'deserializeColorSearch'
  ColorProject: 'deserializeColorProject'
  ColorProjectElement: 'deserializeColorProjectElement'
  VariablesCollection: 'deserializeVariablesCollection'

beforeEach ->
  atom.config.set('pigments-redux.markerType', 'native-background')
  atom.views.addViewProvider(pigments.pigmentsViewProvider)

  for k,v of deserializers
    atom.deserializers.add name: k, deserialize: Pigments[v]

  registry.removeExpression('pigments-redux:variables')

  jasmineContent = document.body.querySelector('#jasmine-content')
  jasmineContent.style.width = '100%'
  jasmineContent.style.height = '100%'

afterEach ->
  registry.removeExpression('pigments-redux:variables')
