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

markdown = $('#markdown').text()
rendered_html = marked(markdown)

$('#rendered-html').html(rendered_html)
