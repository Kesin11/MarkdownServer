# gapi.loadのコールバックが信用ならないので最初に読み込んでおく
gapi.load('picker')

Editor = require('./editor.coffee')
GDrive = require('./gdrive.coffee')
ModelHandler = require('./model_handler.coffee')

editorModel = new Editor.EditorModel()
gdriveModel = new GDrive.GDriveModel()
modelHandler = new ModelHandler({
  editorModel: editorModel,
  gdriveModel: gdriveModel
})

editorView  = new Editor.EditorView({model: editorModel})
alertView   = new Editor.AlertView()

gdriveView  = new GDrive.GDriveView({
  model: gdriveModel,
  alertView: alertView,
  modelHandler: modelHandler
})
