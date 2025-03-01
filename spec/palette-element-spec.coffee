Color = require '../lib/color'
Palette = require '../lib/palette'
{THEME_VARIABLES} = require '../lib/uris'
{change, click} = require './helpers/events'

describe 'PaletteElement', ->
  [nextID, palette, paletteElement, workspaceElement, pigments, project] = [0]

  createVar = (name, color, path, line, isAlternate=false) ->
    {name, color, path, line, id: nextID++, isAlternate}

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    atom.config.set 'pigments-redux.sourceNames', [
      '*.styl'
      '*.less'
    ]

    waitsForPromise -> atom.packages.activatePackage('pigments-redux').then (pkg) ->
      pigments = pkg.mainModule
      project = pigments.getProject()

    waitsForPromise -> project.initialize()

  afterEach ->
    project.destroy()

  describe 'as a view provider', ->
    beforeEach ->
      palette = new Palette([
        createVar 'red', new Color('#ff0000'), 'file.styl', 0
        createVar 'green', new Color('#00ff00'), 'file.styl', 1
        createVar 'blue', new Color('#0000ff'), 'file.styl', 2
        createVar 'redCopy', new Color('#ff0000'), 'file.styl', 3
        createVar 'red_copy', new Color('#ff0000'), 'file.styl', 3, true
        createVar 'red', new Color('#ff0000'), THEME_VARIABLES, 0
      ])

      paletteElement = atom.views.getView(palette)
      jasmine.attachToDOM(paletteElement)

    it 'is associated with the Palette model', ->
      expect(paletteElement).toBeDefined()

    it 'does not render alernate form of a variable', ->
      expect(paletteElement.querySelectorAll('li').length).toEqual(5)

    it 'does not render the file link when the variable comes from a theme', ->
      expect(paletteElement.querySelectorAll('li')[4].querySelector(' [data-variable-id]')).not.toExist()

  describe 'when pigments-redux:show-palette commands is triggered', ->
    beforeEach ->
      atom.commands.dispatch(workspaceElement, 'pigments-redux:show-palette')

      waitsFor ->
        paletteElement = workspaceElement.querySelector('pigments-palette')

      runs ->
        palette = paletteElement.getModel()
        jasmine.attachToDOM(paletteElement)

    it 'opens a palette element', ->
      expect(paletteElement).toBeDefined()

    it 'creates as many list item as there is colors in the project', ->
      expect(paletteElement.querySelectorAll('li').length).not.toEqual(0)
      expect(paletteElement.querySelectorAll('li').length).toEqual(palette.variables.filter((v) -> not v.isAlternate).length)

    it 'binds colors with project variables', ->
      projectVariables = project.getColorVariables()

      li = paletteElement.querySelector('li')
      expect(li.querySelector('.path').textContent).toEqual(atom.project.relativize(projectVariables[0].path))

    describe 'clicking on a result path', ->
      it 'shows the variable in its file', ->
        spyOn(project, 'showVariableInFile')

        pathElement = paletteElement.querySelector('[data-variable-id]')

        click(pathElement)

        waitsFor -> project.showVariableInFile.callCount > 0

    describe 'when the sortPaletteColors settings is set to color', ->
      beforeEach ->
        atom.config.set 'pigments-redux.sortPaletteColors', 'by color'

      it 'reorders the colors', ->
        sortedColors = project.getPalette().sortedByColor().filter((v) -> not v.isAlternate)
        lis = paletteElement.querySelectorAll('li')

        for {name},i in sortedColors
          expect(lis[i].querySelector('.name').textContent).toEqual(name)

    describe 'when the sortPaletteColors settings is set to name', ->
      beforeEach ->
        atom.config.set 'pigments-redux.sortPaletteColors', 'by name'

      it 'reorders the colors', ->
        sortedColors = project.getPalette().sortedByName().filter((v) -> not v.isAlternate)
        lis = paletteElement.querySelectorAll('li')

        for {name},i in sortedColors
          expect(lis[i].querySelector('.name').textContent).toEqual(name)

    describe 'when the groupPaletteColors setting is set to file', ->
      beforeEach ->
        atom.config.set 'pigments-redux.groupPaletteColors', 'by file'

      it 'renders the list with sublists for each files', ->
        ols = paletteElement.querySelectorAll('ol ol')
        expect(ols.length).toEqual(5)

      it 'adds a header with the file path for each sublist', ->
        ols = paletteElement.querySelectorAll('.pigments-color-group-header')
        expect(ols.length).toEqual(5)

      describe 'and the sortPaletteColors is set to name', ->
        beforeEach ->
          atom.config.set 'pigments-redux.sortPaletteColors', 'by name'

        it 'sorts the nested list items', ->
          palettes = paletteElement.getFilesPalettes()
          ols = paletteElement.querySelectorAll('.pigments-color-group')
          n = 0

          for file, palette of palettes
            ol = ols[n++]
            lis = ol.querySelectorAll('li')
            sortedColors = palette.sortedByName().filter((v) -> not v.isAlternate)

            for {name},i in sortedColors
              expect(lis[i].querySelector('.name').textContent).toEqual(name)

      describe 'when the mergeColorDuplicates', ->
        beforeEach ->
          atom.config.set 'pigments-redux.mergeColorDuplicates', true

        it 'groups identical colors together', ->
          lis = paletteElement.querySelectorAll('li')

          expect(lis.length).toEqual(40)

    describe 'sorting selector', ->
      [sortSelect] = []

      describe 'when changed', ->
        beforeEach ->
          sortSelect = paletteElement.querySelector('#sort-palette-colors')
          sortSelect.querySelector('option[value="by name"]').setAttribute('selected', 'selected')

          change(sortSelect)

        it 'changes the settings value', ->
          expect(atom.config.get('pigments-redux.sortPaletteColors')).toEqual('by name')

    describe 'grouping selector', ->
      [groupSelect] = []

      describe 'when changed', ->
        beforeEach ->
          groupSelect = paletteElement.querySelector('#group-palette-colors')
          groupSelect.querySelector('option[value="by file"]').setAttribute('selected', 'selected')

          change(groupSelect)

        it 'changes the settings value', ->
          expect(atom.config.get('pigments-redux.groupPaletteColors')).toEqual('by file')

  describe 'when the palette settings differs from defaults', ->
    beforeEach ->
      atom.config.set('pigments-redux.sortPaletteColors', 'by name')
      atom.config.set('pigments-redux.groupPaletteColors', 'by file')
      atom.config.set('pigments-redux.mergeColorDuplicates', true)

    describe 'when pigments-redux:show-palette commands is triggered', ->
      beforeEach ->
        atom.commands.dispatch(workspaceElement, 'pigments-redux:show-palette')

        waitsFor ->
          paletteElement = workspaceElement.querySelector('pigments-palette')

        runs ->
          palette = paletteElement.getModel()

      describe 'the sorting selector', ->
        it 'selects the current value', ->
          sortSelect = paletteElement.querySelector('#sort-palette-colors')
          expect(sortSelect.querySelector('option[selected]').value).toEqual('by name')

      describe 'the grouping selector', ->
        it 'selects the current value', ->
          groupSelect = paletteElement.querySelector('#group-palette-colors')
          expect(groupSelect.querySelector('option[selected]').value).toEqual('by file')

      it 'checks the merge checkbox', ->
        mergeCheckBox = paletteElement.querySelector('#merge-duplicates')
        expect(mergeCheckBox.checked).toBeTruthy()

  describe 'when the project variables are modified', ->
    [spy, initialColorCount] = []
    beforeEach ->
      atom.commands.dispatch(workspaceElement, 'pigments-redux:show-palette')

      waitsFor ->
        paletteElement = workspaceElement.querySelector('pigments-palette')

      runs ->
        palette = paletteElement.getModel()
        initialColorCount = palette.getColorsCount()
        spy = jasmine.createSpy('onDidUpdateVariables')

        project.onDidUpdateVariables(spy)

        atom.config.set 'pigments-redux.sourceNames', [
          '*.styl'
          '*.less'
          '*.sass'
        ]

      waitsFor -> spy.callCount > 0

    it 'updates the palette', ->
      expect(palette.getColorsCount()).not.toEqual(initialColorCount)

      lis = paletteElement.querySelectorAll('li')

      expect(lis.length).not.toEqual(initialColorCount)
