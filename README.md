MarkdownServer

MarkdownServer is a simple editor for write markdown. It's implemented with javascript.

# DEMO
https://markdown-server.herokuapp.com/

please allow popup on this site for GoogleDrive authorization.

# Install
```
bundle install
npm install
```

# For development
grunt

```
# run 'watch' and 'connect' task
grunt
```

start server

```
bundle exec foreman start
```

# For production
For example deploy to heroku

## Create heroku app with multi_buildpack
```
heroku create -b https://github.com/heroku/heroku-buildpack-multi.git markdown-server
git push heroku
```

## Set your Google Drive Client ID
1. Get your Google Drive Client ID following [here](https://developers.google.com/drive/web/enable-sdk)
2. heroku config:set GOOGLE_DRIVE_CLIENT_ID="your_client_id"
