class GDrive
  CLIENT_ID: GOOGLE_DRIVE_CLIENT_ID
  SCOPES: 'https://www.googleapis.com/auth/drive'
  BOUNDARY = '-------314159265358979323846'

  requestBody: (title, content)->
    delimiter = "\r\n--" + this.BOUNDARY + "\r\n"
    close_delim = "\r\n--" + this.BOUNDARY + "--"

    contentType = 'text/plain'
    metadata = {
      'title': title,
      'mimeType': contentType
    }

    base64Data = this.utf8_to_b64(content)
    multipartRequestBody =
      delimiter +
      'Content-Type: application/json\r\n\r\n' +
      JSON.stringify(metadata) +
      delimiter +
      'Content-Type: ' + contentType + '\r\n' +
      'Content-Transfer-Encoding: base64\r\n' +
      '\r\n' +
      base64Data +
      close_delim

    return multipartRequestBody

  insert: (title, content, callback) ->
    multipartRequestBody = this.requestBody(title, content)
    request = gapi.client.request({
      'path': '/upload/drive/v2/files',
      'method': 'POST',
      'params': {'uploadType': 'multipart'},
      'headers': {
        'Content-Type': 'multipart/mixed; boundary="' +
        this.BOUNDARY + '"'
      },
      'body': multipartRequestBody})
    if (!callback)
      callback = (file) ->
        console.log(file)
    request.execute(callback)

  update: (fileId, title, content, callback) ->
    console.log('update file')
    multipartRequestBody = this.requestBody(title, content)
    request = gapi.client.request({
      'path': '/upload/drive/v2/files/' + fileId,
      'method': 'PUT',
      'params': {'uploadType': 'multipart'},
      'headers': {
        'Content-Type': 'multipart/mixed; boundary="' +
        this.BOUNDARY + '"'
      },
      'body': multipartRequestBody})
    if (!callback)
      callback = (file) ->
        console.log(file)
    request.execute(callback)

  utf8_to_b64: (str) ->
    window.btoa( unescape(encodeURIComponent( str ) ) )

GDriveModel = Backbone.Model.extend({
  initialize: ()->
    this.gdrive = new GDrive()
    this.authResult = this.authorize()
    this.file = null

  authorize: (callback)->
    that = this
    return null unless gapi.auth

    gapi.auth.authorize({
      'client_id': this.gdrive.CLIENT_ID,
      'scope': this.gdrive.SCOPES,
      'immediate': true },
      (authResult)->
        # immediate: trueが失敗したときはflaseで再チャレンジ
        # 今度はダイアログが開く
        if (authResult && !authResult.error)
          console.log("immediate true")
          that.authResult = authResult
          console.log(callback)
          callback(authResult)
        else
          console.log("immediate false")
          gapi.auth.authorize({
            'client_id': that.gdrive.CLIENT_ID,
            'scope': that.gdrive.SCOPES,
            'immediate': false },
            (authResult)->
              that.authResult = authResult
              console.log(callback)
              callback(authResult)
          )
    )

  upload: (title, content) ->
    if this.file == null
      this.insert(title, content)
    else
      this.update(title, content)

  insert: (title, content) ->
    that = this
    gapi.client.load('drive', 'v2', ->
      that.gdrive.insert(title, content, (file)->
        console.log("insert file")
        console.log(file)
        that.file = file
        )
    )

  update: (title, content) ->
    that = this
    gapi.client.load('drive', 'v2', ->
      that.gdrive.update(that.file.id, title, content, (file)->
        console.log("update file")
        console.log(file)
        that.file = file
        )
    )
})
GDriveView = Backbone.View.extend({
  el: '#gdrive'
  events:
    'click [name=authorize-button]': 'gapi_authorize'
    'click [name=upload-button]': 'upload'
  initialize: ()->

  gapi_authorize: ()->
    this.model.authorize(this.authorizeAlert)
  upload: ()->
    content = $('#markdown > textarea').val()
    title = 'test_file.txt'
    this.model.upload(title, content)
  authorizeAlert: (authResult)->
    console.log(authResult)
    if authResult && !authResult.error
      this.alertView.show("success", "Success GoogleDrive authorization")
    else
      this.alertView.show("warning", "Fail GoogleDrive authorization")
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

alertView = new AlertView()
gdriveModel = new GDriveModel()
gdriveView = new GDriveView({model: gdriveModel, alertView: alertView})
