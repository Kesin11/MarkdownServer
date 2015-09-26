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
  get: (fileId, callback) ->
    gapi.client.load('drive', 'v2', ->
      request = gapi.client.drive.files.get({
        'fileId' : fileId
      })
      if (!callback)
        callback = (file) ->
          console.log(file)
      request.execute(callback)
    )

  # fileの中身のget
  getFileResource: (downloadUrl, accessToken, callback) ->
    $.ajax({
      method: 'GET'
      url: downloadUrl
      headers: {
        'Authorization': 'Bearer ' + accessToken
      }
    })
    .always((data) ->
      callback(data)
    )

  insert: (title, content, callback) ->
    multipartRequestBody = this.requestBody(title, content)
    # memo: gapi.client.requestはpromiseも使えるらしい
    # https://developers.google.com/api-client-library/javascript/features/promises
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

  fetchFile: (fileId, callback, caller) ->
    that = this
    that.gdrive.get(fileId, (file)->
      that.set("file", file)
      that.set('title', file.title)

      that.gdrive.getFileResource(
        file.downloadUrl,
        that.get('access_token'),
        (data) ->
          that.set('content', data)
      )

      callback(file, caller)
    )

  upload: (title, content, callback, caller) ->
    this.set({title: title, content: content})

    if this.get("file")
      this.update(title, content, callback, caller)
    else
      this.insert(title, content, callback, caller)

  insert: (title, content, callback, caller) ->
    that = this
    # memo: gapi.client.loadはGDriveオブジェクトの方に移したい
    # さらにclient.loadはcallback無しのときにpromiseが返るらしい
    # https://developers.google.com/api-client-library/javascript/reference/referencedocs
    gapi.client.load('drive', 'v2', ->
      that.gdrive.insert(title, content, (file)->
        console.log("insert file")
        console.log(file)
        that.set("file", file)

        callback(file, "insert", caller)
        )
    )

  update: (title, content, callback, caller) ->
    that = this
    gapi.client.load('drive', 'v2', ->
      that.gdrive.update(that.get("file").id, title, content, (file)->
        console.log("update file")
        console.log(file)
        that.set("file", file)

        callback(file, "update", caller)
        )
    )
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

    this.listenTo(this.model, 'change', this.updateDocumentLink)

  gapi_authorize: ()->
    # memo: コールバックで戻ってきたときのauthorizeAlert()で自身のthisを使いたいので渡しておく
    # このあたりはPromiseを使えばこんなややこしいことしなくても済みそう
    this.model.authorize()
      .then () =>
        this.alertView.show("success", "Success GoogleDrive authorization")
      .catch () =>
        this.alertView.show("warning", "Fail GoogleDrive authorization")

  upload: ()->
    title = this.model_handler.getEditorTitle()
    content = this.model_handler.getEditorContent()
    this.model.upload(title, content, this.uploadFileAlert, this)

  updateDocumentLink: ()->
    console.log("update_document_link")
    file = this.model.get("file")
    if file
      documentLink = $('#document-link')
      documentLink.text(file.title)
      # TODO: file.alternateLinkで同じアドレス取れそう
      documentLink.attr("href", "https://drive.google.com/file/d/" \
       + file.id + "/view")
      documentLink.removeClass("text-muted").addClass("text-primary")

  uploadFileAlert: (file, methodName, caller)->
    if !file.error
      caller.alertView.show("info", "Success " + methodName + "!")
    else
      caller.alertView.show("danger", "Fail " + methodName + "!")

  fetchFileAlert: (file, caller)->
    if !file.error
      caller.alertView.show("info", "Success " + "fetch" + "!")

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
        .setCallback((data) ->
          if data.action == google.picker.Action.PICKED
            fileId = data.docs[0].id
            that.model.fetchFile(fileId, that.fetchFileAlert, that)
        )
        # .setDeveloperKey(developerKey)
        # .enableFeature(google.picker.Feature.NAV_HIDDEN)
        # .enableFeature(google.picker.Feature.MULTISELECT_ENABLED)
        .build()
      console.log(picker)
      picker.setVisible(true)
})

module.exports = {
  GDriveModel: GDriveModel,
  GDriveView:  GDriveView,
}
