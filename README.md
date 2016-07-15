# Clippy

Clippy (and friends) for your [Atom](http://atom.io).

![Clippy and friends](http://i.imgur.com/2hvJCEF.jpg)

## Using Clippy from your Atom package

You can use the Clippy service in your own Atom packages.
This requires that the user has the Clippy package installed.

In your `package.json` file add the following:

```json
  "consumedServices": {
    "clippy": {
      "versions": {
        "^1.0.0": "consumeClippyService"
      }
    }
  }
```

Then in your plugin code add a `consumeClippyService` method (also returning a disposable):

```coffee
{Disposable} = require 'atom'

clippy = null

module.exports =
  consumeClippyService: (service) ->
    clippy = service
    new Disposable -> clippy = null

  activate: ->
    atom.commands.add 'atom-workspace', 'hello', ->
      if clippy
        clippy.speak 'Hello world'
```

The clippy service object provides the following (more to come):

* `animations` property that returns a list of valid animations
* `animate(animation)` method that animates Clippy (parameter is optional)
* `speak(text)` method that makes Clippy speak

You can refer to the [Raptorize](https://github.com/sibartlett/atom-raptorize) package for a working example.

For more detailed documentation, refer to the [Atom documentation](https://atom.io/docs/latest/behind-atom-interacting-with-packages-via-services).

## Special Thanks

* [Smore](https://www.smore.com) for developing [Clippy.JS](http://www.smore.com/clippy-js) the jQuery plugin that this package was ported from
* [Cinnamon Software](http://www.cinnamonsoftware.com/) for developing [Double Agent](http://doubleagent.sourceforge.net/)
the program that was used to unpack Clippy and his friends!
* Microsoft, for creating Clippy :)
