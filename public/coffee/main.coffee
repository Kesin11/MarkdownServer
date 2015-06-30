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
})

editor  = new Editor()
editorView = new EditorView({model: editor})
