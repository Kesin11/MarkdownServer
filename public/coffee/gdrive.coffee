class GDrive
  CLIENT_ID: '966231612988-cmob8calt2b646p4sddlb4410q2eekmq' +
  '.apps.googleusercontent.com'
  SCOPES: 'https://www.googleapis.com/auth/drive'

  # Check if the current user has authorized the application.
  checkAuth: () ->
    that = this
    gapi.auth.checkSessionState({
      'client_id': this.CLIENT_ID, 'session_state': null},
      (isLoggedOut) ->
        if !isLoggedOut
          console.log(that)
          gapi.auth.authorize({
            'client_id': that.CLIENT_ID,
            'scope': that.SCOPES,
            'immediate': false },
            that.handleAuthResult
          )
        else
          console.log('You already logged in')
      )



   # Called when authorization server replies.
   # @param {Object} authResult Authorization result.
  handleAuthResult: (authResult) ->
    that = this
    console.log(authResult)
    if (authResult && !authResult.error)
      # Access token has been successfully retrieved,
      # requests can be sent to the API.
      console.log("authorized")

   # Start the file upload.
   # @param {Object} evt Arguments from the file selector.
  uploadFile: (evt) ->
    that = this
    console.log('upload file')

    content = $('#markdown > textarea').val()
    title = 'test_file.txt'
    console.log(content)
    gapi.client.load('drive', 'v2', ->
      that.insertFile(title, content)
    )

   # Insert new file.
   # @param {File} fileData File object to read data from.
   # @param {Function} callback Function to call when the request is complete.
  insertFile: (title, content, callback) ->
    that = GDrive.prototype
    console.log('insert file')
    boundary = '-------314159265358979323846'
    delimiter = "\r\n--" + boundary + "\r\n"
    close_delim = "\r\n--" + boundary + "--"

    contentType = 'text/plain'
    metadata = {
      'title': title,
      'mimeType': contentType
    }
    console.log(metadata)

    base64Data = that.utf8_to_b64(content)
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

    request = gapi.client.request({
      'path': '/upload/drive/v2/files',
      'method': 'POST',
      'params': {'uploadType': 'multipart'},
      'headers': {
        'Content-Type': 'multipart/mixed; boundary="' + boundary + '"'
      },
      'body': multipartRequestBody})
    if (!callback)
      callback = (file) ->
        console.log(file)
    request.execute(callback)

  utf8_to_b64: (str) ->
    window.btoa( unescape(encodeURIComponent( str ) ) )
