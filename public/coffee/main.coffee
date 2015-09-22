# gapi.loadのコールバックが信用ならないので最初に読み込んでおく
gapi.load('picker')

Editor = require('./editor.coffee')
GDrive = require('./gdrive.coffee')

editorModel = new Editor.EditorModel()
editorView  = new Editor.EditorView({model: editorModel})
alertView   = new Editor.AlertView()

gdriveModel = new GDrive.GDriveModel()
gdriveView  = new GDrive.GDriveView({model: gdriveModel, alertView: alertView})
