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

EditorModel = Backbone.Model.extend({
  initialize: ()->
    this.title   = ''
    this.content = ''
})

EditorView = Backbone.View.extend({
  el: '#markdown'
  events:
    'keyup': 'updateModel'

  initialize: ()->
    this.dom = {
      title: this.$('[name=title]')
      content: this.$('[name=raw-text]')
      rendered_html: this.$('#rendered-html')
    }
    this.listenTo(this.model, 'change', this.render)
    autosize(this.$('textarea')) # textareaの自動拡張プラグイン

  updateModel: ()->
    this.model.set({ title: this.dom.title.val() })
    this.model.set({ content: this.dom.content.val() })

  render: ()->
    title   = this.model.get('title')
    content = this.model.get('content')
    # markdown area
    if content
      html = marked(content)
      $('#rendered-html').html(html)

    # text area
    this.dom.title.val(title)
    this.dom.content.val(content)

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

module.exports = {
  EditorModel: EditorModel,
  EditorView:  EditorView,
  AlertView:   AlertView,
}
