$ = require 'jquery'
_ = require 'underscore-plus'
React = require 'react-atom-fork'
remote = require 'remote'
NProgress = require 'nprogress'
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
    name = if @props.title
      @props.title
    else
      @props.filename

    div {className: "song"},
      (div {className: "name-container"},
        (div {className: "name"}, name)),

      (div {className: "duration-container"},
        (div {className: "duration"}, @props.duration)),

      (div {className: "artist-container"},
        (div {className: "artist"}, @props.artist)),

      (div {className: "album-container"},
        (div {className: "album"}, @props.album)),

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

    key = @props.sortKey
    @props.data.sort (a, b) ->
      return +1 if a[key] > b[key]
      return -1 if a[key] < b[key]
      return 0

    songNodes = @props.data.map (song) ->
      # TODO: Figure out a better unique key here
      Song(_.extend {key: song.filename}, song)

    div {className: "song-list"},
      div {className: "header"},
        (div (_.extend {className: "name-container"}, opts),
          (div {className: "name"}, "Name")),

        (div (_.extend {className: "duration-container"}, opts),
          (div {className: "duration"}, "Duration")),

        (div (_.extend {className: "artist-container"}, opts),
          (div {className: "artist"}, "People")),

        (div (_.extend {className: "album-container"}, opts),
          (div {className: "album"}, "Release")),

      div {className: "data"}, songNodes

SongBox = React.createClass
  getInitialState: ->
    {
      data: [],
      progress: 0.00
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

      updateProgress = _.throttle (->
        # Update progress
        progress = songs.length / total
        NProgress.set(progress)
      ), 60, true

      total = files.length
      async.eachLimit files, 1, ((file, cb) ->
        # Create the metadata parser
        stream = fs.createReadStream file
        parser = mm stream, {duration: true}
        parser.on 'metadata', (result) ->
          # Update our song list
          item = _.extend {filename: file}, result
          songs.push item

          # Update progress
          updateProgress()

        parser.on 'done', (err) ->
          if err
            # Probably not really a music file ..
            # TODO: Log the error somewhere
            total -= 1
            updateProgress()

          stream.destroy()
          cb()

      ), (err) =>
        # All files were processed successfully
        NProgress.done()
        this.setState {data: songs}

  render: ->
    div {className: "container"},
      (SongList {data: @state.data, sortKey: "title"})

document.addEventListener 'DOMContentLoaded', ->
  # Configure NProgress
  NProgress.configure {
    trickle: false,
    speed: 300,
    showSpinner: false
  }

  React.renderComponent SongBox(), (document.getElementById "content")
