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

  # metadataのget
  get: (fileId) ->
    return gapi.client.load('drive', 'v2')
      .then () ->
        gapi.client.drive.files.get({ 'fileId' : fileId })
      .then (response) -> Promise.resolve(response.result)

  # fileの中身のget
  getFileResource: (downloadUrl, accessToken) ->
    # $.ajaxをPromiseにcast
    return Promise.resolve(
      $.ajax({
        method: 'GET'
        url: downloadUrl
        headers: {
          'Authorization': 'Bearer ' + accessToken
        }
      })
    )

  insert: (title, content) ->
    multipartRequestBody = this.requestBody(title, content)
    # Promise互換を返す
    return gapi.client.request({
      'path': '/upload/drive/v2/files',
      'method': 'POST',
      'params': {'uploadType': 'multipart'},
      'headers': {
        'Content-Type': 'multipart/mixed; boundary="' +
        this.BOUNDARY + '"'
      },
      'body': multipartRequestBody})

  update: (fileId, title, content) ->
    multipartRequestBody = this.requestBody(title, content)
    return gapi.client.request({
      'path': '/upload/drive/v2/files/' + fileId,
      'method': 'PUT',
      'params': {'uploadType': 'multipart'},
      'headers': {
        'Content-Type': 'multipart/mixed; boundary="' +
        this.BOUNDARY + '"'
      },
      'body': multipartRequestBody})

  utf8_to_b64: (str) ->
    window.btoa( unescape(encodeURIComponent( str ) ) )

GDriveModel = Backbone.Model.extend({
  initialize: ()->
    this.gdrive = new GDrive()
    this.set({
      access_token: ''
      file: null
      title: ''
      content: ''
    })

    this.set("client_id", this.gdrive.CLIENT_ID)

  authorize: ()->
    that = this
    return new Promise((resolve, reject) ->
      reject(null) unless gapi.auth

      gapi.auth.authorize({
        'client_id': that.gdrive.CLIENT_ID,
        'scope': that.gdrive.SCOPES,
        'immediate': true },
        (authResult)->
          # immediate: trueが失敗したときはflaseで再チャレンジ
          # 今度はダイアログが開く
          if (authResult && !authResult.error)
            console.log("immediate true")
            that.set("access_token", authResult.access_token)
            resolve(authResult)
          else
            console.log("immediate false")
            gapi.auth.authorize({
              'client_id': that.gdrive.CLIENT_ID,
              'scope': that.gdrive.SCOPES,
              'immediate': false },
              (authResult)->
                if (authResult && !authResult.error)
                  that.set("access_token", authResult.access_token)
                  resolve(authResult)
                else
                  console.log("authorize failed")
                  reject(authResult)
            )
        )
    )

  fetchFile: (fileId) ->
    that = this
    return new Promise((resolve, reject) ->
      that.gdrive.get(fileId)
        .then (file) ->
          that.set("file", file)
          that.set('title', file.title)

          that.gdrive.getFileResource(
            file.downloadUrl,
            that.get('access_token')
          )
        .then (fileContent) ->
          that.set('content', fileContent)
          resolve(fileContent)
      )

  upload: (title, content) ->
    this.set({title: title, content: content})

    if this.get("file")
      this.update(title, content)
      return Promise.resolve('update')
    else
      this.insert(title, content)
      return Promise.resolve('insert')

  insert: (title, content) ->
    that = this
    gapi.client.load('drive', 'v2')
      .then () -> that.gdrive.insert(title, content)
      .then (response) ->
        console.log("insert file")
        console.log(response.result)
        that.set("file", response.result)

        Promise.resolve(response.result)

  update: (title, content) ->
    that = this
    fileId = that.get('file').id
    gapi.client.load('drive', 'v2')
      .then () -> that.gdrive.update(fileId, title, content)
      .then (response) ->
        console.log("update file")
        console.log(response.result)
        that.set("file", response.result)

        Promise.resolve(response.result)
})

GDriveView = Backbone.View.extend({
  el: '#gdrive'
  events:
    'click [name=authorize-button]': 'gapi_authorize'
    'click [name=upload-button]': 'upload'
    'click [name=picker-button]': 'showPicker'

  initialize: (options)->
    this.alertView = options.alertView # modelなどの特別以外は明示的に受け取る必要がある
    this.model_handler = options.modelHandler

    this.listenTo(this.model, 'change:file', this.updateDocumentLink)

  gapi_authorize: ()->
    this.model.authorize()
      .then () =>
        this.alertView.show("success", "Success GoogleDrive authorization")
      .catch () =>
        this.alertView.show("warning", "Fail GoogleDrive authorization")

  upload: ()->
    title = this.model_handler.getEditorTitle()
    content = this.model_handler.getEditorContent()

    this.model.upload(title, content)
      .then (methodName) =>
        this.alertView.show("info", "Success " + methodName + "!")
      .catch (methodName) =>
        this.alertView.show("danger", "Fail " + methodName + "!")

  updateDocumentLink: ()->
    console.log("update_document_link")
    file = this.model.get("file")
    if file
      documentLink = $('#document-link')
      documentLink.text(file.title)
      documentLink.attr("href", file.alternateLink)
      documentLink.removeClass("text-muted").addClass("text-primary")

  showPicker: ()->
    that = this
    client_id = that.model.get('client_id')
    access_token = that.model.get("access_token")
    if access_token
      view = new google.picker.View(google.picker.ViewId.DOCS)
      # 現状何かエラー出ているけど一応使えるのでとりあえず放置
      picker = new google.picker.PickerBuilder()
        .addView(view)
        .setAppId(client_id)
        .setOAuthToken(access_token)
        .setCallback((data) =>
          if data.action == google.picker.Action.PICKED
            fileId = data.docs[0].id
            this.model.fetchFile(fileId)
              .then () =>
                this.alertView.show("info", "Success fetch!")
              .catch () =>
                this.alertView.show("danger", "Fail fetch!")
        )
        # .setDeveloperKey(developerKey)
        # .enableFeature(google.picker.Feature.NAV_HIDDEN)
        # .enableFeature(google.picker.Feature.MULTISELECT_ENABLED)
        .build()
      picker.setVisible(true)
})

module.exports = {
  GDriveModel: GDriveModel,
  GDriveView:  GDriveView,
}
