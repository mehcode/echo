$ = require 'jquery'
_ = require 'underscore-plus'
React = require 'react-atom-fork'
remote = require 'remote'
{div, h1, h2} = require 'reactionary-atom-fork'

glob = require 'glob'
mm = require 'musicmetadata'
fs = require 'fs'
path = require 'path'
async = require 'async'

# TODO: Use 'glob' on the FS to get data
songs = [
]

Song = React.createClass
  render: ->
    div {className: "song"},
      (div {className: "name"}, @props.title),
      (div {className: "duration"}, @props.duration),
      (div {className: "artist"}, @props.artist),
      (div {className: "album"}, @props.album),

SongList = React.createClass
  onMouseEnter: (event) ->
    name = event.currentTarget.className
    for el in document.querySelectorAll(".#{name}")
      el.classList.add("hover")

  onMouseLeave: (event) ->
    for el in document.querySelectorAll(".hover")
      el.classList.remove("hover")

  render: ->
    opts = {
      onMouseEnter: this.onMouseEnter,
      onMouseLeave: this.onMouseLeave
    }

    songNodes = @props.data.map (song) ->
      # TODO: Figure out a better unique key here
      Song(_.extend {key: song.filename}, song)

    div {className: "song-list"},
      div {className: "header"},
        (div (_.extend {className: "name"}, opts), "Name"),
        (div (_.extend {className: "duration"}, opts), "Duration"),
        (div (_.extend {className: "artist"}, opts), "Artist"),
        (div (_.extend {className: "album"}, opts), "Album"),

      div {className: "data"}, songNodes

SongBox = React.createClass
  getInitialState: ->
    {
      data: []
    }

  componentDidMount: ->
    # TODO: Base path should be configurable (of course)
    base = remote.process.argv[1]
    console.log("searching #{base}")
    glob (path.join base, "**/*"), {mark: true}, (err, files) =>
      # Skip directories
      # TODO: Test for 'music' files
      files = _.filter files, (file) ->
        file.slice(-1) isnt "/"

      async.eachLimit files, 10, ((file, cb) ->
        # Create the metadata parser
        stream = fs.createReadStream file
        parser = mm stream, {duration: true}
        parser.on 'metadata', (result) ->
          # Update our song list
          item = _.extend {filename: file}, result
          songs.push item

        parser.on 'done', (err) ->
          stream.destroy()
          cb()

      ), (err) =>
        # All files were processed successfully
        this.setState {data: songs}

  render: ->
    SongList {data: @state.data}

document.addEventListener 'DOMContentLoaded', ->
  React.renderComponent SongBox(), (document.getElementById "content")
