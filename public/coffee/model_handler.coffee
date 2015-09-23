# EditorModel, GdriveModelへのアクセスとGDriveModel→EditorModelの同期周り

# Backbone.Modelを継承するがmodelは使わない。Backbone.Event系を使いたいだけ
ModelHandler = Backbone.Model.extend({
  initialize: (options)->
    # this.set('editorModel', options.editorModel)
    # this.set('gdriveModel', options.gdriveModel)
    # this.listenTo(this.get('gdriveModel'), 'change', this.sync)
    this.editorModel = options.editorModel
    this.gdriveModel = options.gdriveModel

    this.listenTo(
      this.gdriveModel,
      'change:title change:content',
      this.sync
    )

  sync: () ->
    title   = this.gdriveModel.get('title')
    content = this.gdriveModel.get('content')

    this.editorModel.set('title', title)
    this.editorModel.set('content', content)

  getEditorTitle: () ->
    return this.editorModel.get('title')

  getEditorContent: () ->
    return this.editorModel.get('content')
})

module.exports = ModelHandler
