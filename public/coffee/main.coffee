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

AlertView = Backbone.View.extend({
  el: '#alert-region'

  show: (context, message)->
    alertDiv = $("<div></div>")
        .addClass("alert alert-" + context)
        .text(message)
        .alert()
    this.$el.append(alertDiv)
    alertDiv.fadeTo(2000, 500).slideUp(500, ()->
      alertDiv.alert('close')
    )
})

editor  = new Editor()
editorView = new EditorView({model: editor})
alertView = new AlertView()

# gapi.loadのコールバックが信用ならないので最初に読み込んでおく
gapi.load('picker')
