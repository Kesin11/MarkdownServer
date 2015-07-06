marked.setOptions({
  renderer: new marked.Renderer()
  gfm: true
  tables: true
  breaks: false
  pedantic: false
  sanitize: true
  smartLists: true
  smartypants: false
})

Editor = Backbone.Model.extend({
  initialize: ()->
    this.markdown = ''
})
EditorView = Backbone.View.extend({
  el: '#markdown'
  events:
    'keyup': 'update_model'
    'click #authorizeButton': 'gapi_authorize'
    'click #uploadButton': 'upload_text'
  initialize: ()->
    this.listenTo(this.model, 'change', this.render)
    autosize(this.$('textarea')) # textareaの自動拡張プラグイン

  update_model: ()->
    this.model.set({markdown: this.$('[name=raw-text]').val() })
  render: ()->
    markdown = this.model.get('markdown')
    if markdown
      html = marked(markdown)
      $('#rendered-html').html(html)
  gapi_authorize: ()->
    GDrive.prototype.checkAuth()
  upload_text: ()->
    GDrive.prototype.uploadFile()
})

editor  = new Editor()
editorView = new EditorView({model: editor})
