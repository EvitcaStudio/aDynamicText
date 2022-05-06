#DEFINE DYNAMIC_FAST 2
#DEFINE DYNAMIC_NORMAL 4
#DEFINE DYNAMIC_SLOW 10

#ENABLE LOCALCLIENTCODE
#BEGIN CLIENTCODE

const TEXT_TICK_RATE = 10
const OPTIONS = [ 'pause', 'output', 'caret', 'style', 'speed', 'wipe', 'type', 'delete', 'replace', 'remove', 'add', 'print' ]
const aDynamicText = new Object('aDynamicText')

aDynamicText
	const version = 'v1.0.0'
	var options = {
		'loop': false, // if this should loop the given animation
		'active': false, // if this is active or not
		'paused': false, // if the text is paused
		'showCaret': true, // if the caret is to be shown
		'callback': null, // callback
		'callbackInterior': null, // callback from a option
		'output': null, // the output where the text will go to
		'tags': null, // a array full of the html tags used in the text
		'caret': '|', // caret char to be used
		'style': '', // a optional style to be applied to each letter
		'speed': 'normal', // speed of the text
		'queue': [], // array of objects that hold information about the next queued thing
		'storedOutputs': [], // a array of outputs that were involved with this typing
		'loopData': [], // the params of the initial call so you can loop it
		'newLine': [], // an array of objects, that have indexes at where to place a new line
		'textCounter': 0, // counts the current string char you are on
		'tracker': 0, // counts time in ms,
		'delay': 0, // the delay to wait before `typing`
		'value': false
	}

	onNew()
		Client.___EVITCA_aDynamicText = true;
		Client.aDynamicText = this
		Client.timeScale = (Client.timeScale || Client.timeScale === 0 ? Client.timeScale : 1)

	function start(options, interface, element, loop, callback)
		if (this.options.active)
			//
			return

		if (interface && element)
			this.options.output = Client.getInterfaceElement(interface, element)
			this.options.storedOutputs.push(this.options.output)
		
		foreach (var op in options)
			for (var v in op)
				if (OPTIONS.includes(v)) // only adds in valid options
					this.options.queue.push({ [v]: op[v] })
				
		if (loop)
			this.options.loopData = [options, interface, element, loop, callback]
			this.options.loop = true

		if (callback)
			this.options.callback = callback

		this.options.active = true
		this.options.delay = this.speed2Num(this.options.speed)
		Event.addTicker(this, { 'resetAt': this.options.delay })
		
	function reset(hard) // reset vars to normal
		if (hard) // if outputs are to be cleared as well
			foreach (var o in this.options.storedOutputs)
				o.text = ''

		this.options.loop = false
		this.options.active = false
		this.options.paused = false
		this.options.callback = null
		this.options.callbackInterior = null
		this.options.output = null
		this.options.tags = null
		this.options.caret = '|'
		this.options.style = ''
		this.options.speed = 'normal'
		this.options.queue = []
		this.options.storedOutputs = []
		this.options.textCounter = 0
		this.options.tracker = 0
		this.options.delay = 0
		this.options.value = false
		Event.removeTicker(this)

	onTick(tick)
		// if (Client.___EVITCA_aPause)
		// 	if (aPause.paused)
		// 		return
				
		var queueItem = this.options.queue[0]
		var optionType

		if (queueItem)
			optionType = Util.getObjectKeys(queueItem)[0]
			if (Util.isObject(queueItem[optionType]) && queueItem[optionType].value)
				var callback = queueItem[optionType].callback
				this.options.value = true
				this.options.callbackInterior = callback

			switch (optionType)
				case 'output':
					if (this.options.output)
						this.removeCaret('removeClean')

					if (this.options.tags)
						this.options.tags = ''
						this.frontTag = ''
						this.backTag = ''

					this.options.output = Client.getInterfaceElement((this.options.value ? this.options.queue[0].output.value.interface : this.options.queue[0].output.interface), (this.options.value ? this.options.queue[0].output.value.element : this.options.queue[0].output.element))
					
					if (this.options.output)
						if (!this.options.storedOutputs.includes(this.options.output))
							this.options.storedOutputs.push(this.options.output)

					if (this.options.showCaret)
						this.handleTextCaret('ontoText')
					else
						this.handleTextCaret('ontoDeleted_no_caret')

					this.removeFromQueue()
					break

				case 'style':
					this.options.style = (this.options.value ? this.options.queue[0].style.value : this.options.queue[0].style)
					if (this.options.output)
						if (this.options.showCaret)
							this.handleTextCaret('text')
						else
							this.handleTextCaret('text_no_caret')
						
					this.removeFromQueue()
					break

				case 'print':
					if (this.options.output)
						this.handleTags('print')

						if (this.options.showCaret)
							this.handleTextCaret('print')
						else
							this.handleTextCaret('print_no_caret')

					this.removeFromQueue()
					break

				case 'replace':
					if (this.options.showCaret)
						this.handleTextCaret('replacedText')
					else
						this.handleTextCaret('replacedText_no_caret')

					this.removeFromQueue()
					break

				case 'speed':
					this.options.delay = this.speed2Num((this.options.value ? this.options.queue[0].speed.value : this.options.queue[0].speed))
					this.inTicker.resetAt = this.options.delay
					this.removeFromQueue()
					break

				case 'remove':
					this.options.showCaret = false
					this.removeCaret('remove')
					this.removeFromQueue()
					break

				case 'add':
					this.options.showCaret = true
					this.handleTextCaret('text')
					this.removeFromQueue()
					break			

				case 'caret':
					if (this.options.output)
						this.removeCaret('remove')

					this.options.caret = (this.options.value ? this.options.queue[0].caret.value/* .charAt(0) */ : this.options.queue[0].caret/* .charAt(0) */)

					if (this.options.output)
						if (this.options.showCaret)
							this.handleTextCaret('text')
						else
							this.handleTextCaret('text_no_caret')

					this.removeFromQueue()
					break

				case 'wipe':
					if (this.options.output)
						if (this.options.tags)
							this.options.tags = ''
							this.frontTag = ''
							this.backTag = ''

						if (this.options.showCaret)
							this.handleTextCaret('only')
						else
							this.handleTextCaret('only_no_caret')

						this.removeFromQueue()
						break				

				case 'type':
					if (tick === this.options.delay)
						if (this.options.output)
							this.handleTags('type')

							if (this.options.textCounter >= (this.options.value ? this.options.queue[0].type.value : this.options.queue[0].type).length + 1)
								if (this.options.tags)
									this.removeCaret('remove')
									
									if (this.options.showCaret)
										this.handleTextCaret('clean')
									else
										this.handleTextCaret('clean_no_caret')

								this.options.textCounter = 0
								this.removeFromQueue()
								break

							this.removeCaret('remove')
							this.handleTextCaret('none')
						
							if (this.options.showCaret)
								this.handleTextCaret('clean')
							else
								this.handleTextCaret('clean_no_caret')

							this.options.textCounter++
					break

				case 'delete':
					if (tick === this.options.delay)
						if (this.options.output)
							if ((this.options.value ? this.options.queue[0].delete.value : this.options.queue[0].delete) === -1)
								this.options.deleteAll = true
								if (this.options.value)
									this.options.queue[0].delete.value = extractContent(this.options.output.text).length
								else
									this.options.queue[0].delete = extractContent(this.options.output.text).length
								
							if (this.options.textCounter >= (this.options.value ? this.options.queue[0].delete.value : this.options.queue[0].delete))
								if (this.options.deleteAll)
									this.options.deleteAll = false

									if (this.options.tags)
										this.options.tags = ''
										this.frontTag = ''
										this.backTag = ''

								this.options.textCounter = 0
								this.removeFromQueue()
								break

							if (this.options.showCaret)
								this.handleTextCaret('ontoDeleted')
							else
								this.handleTextCaret('ontoDeleted_no_caret')

							this.options.textCounter++
					break

				case 'pause':
					if ((this.options.value ? this.options.queue[0].pause.value : this.options.queue[0].pause) === -1)
						if (!this.options.paused)
							this.options.paused = true
						return
					
					if (this.options.tracker >= (this.options.value ? this.options.queue[0].pause.value : this.options.queue[0].pause))
						if (this.options.queue[0].pause !== 0)
							this.options.tracker = 0
						this.removeFromQueue()
						return

					if (!this.options.paused)
						this.options.tracker += TEXT_TICK_RATE
					break

			return
			
		Event.removeTicker(this)

	onTickerRemove()
		if (this.options.output)
			this.removeCaret('remove')

		if (this.options.callback)
			this.options.callback()

		if (this.options.loop)
			this.reset(true)
			this.start(this.options.loopData[0], this.options.loopData[1], this.options.loopData[2], this.options.loopData[3], this.options.loopData[4])
		else
			this.reset()

	function removeFromQueue()
		if (this.options.callbackInterior && this.options.queue[0].pause !== 0)
			this.options.callbackInterior()
			this.options.callbackInterior = null

		this.options.value = false
		this.options.queue.shift()

	function removeCaret(method)
		switch (method)
			case 'clean': // means clean version of text, stripped of all html
				return extractContent(this.options.output.text).replace(Util.regExp('\\' + this.options.caret, 'gm'), '')

			case 'remove':
				this.options.output.text = this.options.output.text.replace(Util.regExp('\\' + this.options.caret, 'gm'), '')
				break

			case 'removeClean':
				this.options.output.text = '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + this.removeCaret('clean') + (this.backTag ? this.backTag : '') + '</span>'
				break

	function handleTextCaret(method)
		switch (method)
			case 'only': // adds the caret as the only existing text
				this.options.output.text = '<span class="' + this.options.style + '\">' + '<span id="caret">' + this.options.caret + '</span></span>'
				break

			case 'only_no_caret':
				this.options.output.text = ''
				break

			case 'print':
				this.options.output.text = '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + this.removeCaret('clean') + (this.options.value ? this.options.queue[0].print.value : this.options.queue[0].print) + '<span id="caret">' + this.options.caret + (this.backTag ? this.backTag : '') + '</span></span>'
				break

			case 'print_no_caret':
				this.options.output.text = '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + this.removeCaret('clean') + (this.options.value ? this.options.queue[0].print.value : this.options.queue[0].print) + '</span>'
				break

			case 'text': // adds the current in with the current text
				this.options.output.text = '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + this.removeCaret('clean') + '<span id="caret">' + this.options.caret + (this.backTag ? this.backTag : '') + '</span></span>'
				break

			case 'text_no_caret':
				this.options.output.text = '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + this.removeCaret('clean') + (this.backTag ? this.backTag : '') + '</span>'
				break
				
			case 'ontoText': // adds the cursor onto pre existing text
				this.options.output.text += '<span class="' + this.options.style + '\">' + '<span id="caret">' + this.options.caret + '</span></span>'
				break

			case 'ontoDeleted': // adds cursor onto text being deleted
				this.options.output.text = '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + this.removeCaret('clean').slice(0, -1) + '<span id="caret">' + this.options.caret + (this.backTag ? this.backTag : '') + '</span></span>'
				break

			case 'ontoDeleted_no_caret': // adds cursor onto text being deleted
				this.options.output.text = '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + this.removeCaret('clean').slice(0, -1) + (this.backTag ? this.backTag : '') + '</span>'
				break

			case 'replacedText':
				this.options.output.text = '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + this.changeCharAt((this.options.value ? this.options.queue[0].replace.value.index : this.options.queue[0].replace.index), (this.options.value ? this.options.queue[0].replace.value.char : this.options.queue[0].replace.char)) + '<span id="caret">' + this.options.caret + (this.backTag ? this.backTag : '') + '</span></span>'
				break

			case 'replacedText_no_caret':
				this.options.output.text = '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + this.changeCharAt((this.options.value ? this.options.queue[0].replace.value.index : this.options.queue[0].replace.index), (this.options.value ? this.options.queue[0].replace.value.char : this.options.queue[0].replace.char)) + (this.backTag ? this.backTag : '') + '</span>'
				break

			case 'clean': // adds cursor onto clean text stripped of all html
				this.options.output.text = '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + extractContent(this.options.output.text) + '<span id="caret">' + this.options.caret + (this.backTag ? this.backTag : '') + '</span></span>'
				break

			case 'clean_no_caret':
				this.options.output.text = '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + extractContent(this.options.output.text) + (this.backTag ? this.backTag : '') + '</span>'
				break

			case 'none':
				this.options.output.text += '<span class="' + this.options.style + '\">' + (this.frontTag ? this.frontTag : '') + (this.options.value ? this.options.queue[0].type.value : this.options.queue[0].type).slice(this.options.textCounter - 1, this.options.textCounter) + (this.backTag ? this.backTag : '') + '</span>'		
				break

	function pause()
		if (this.options.paused)
			return

		if (this.options.queue[0].pause === 0)
			this.options.queue.shift()

		this.options.queue.unshift({ 'pause': -1 })
		this.options.paused = true
		this.options.value = false

	function unpause()
		this.options.paused = false
		this.options.queue.shift() // remove the negative one pause
		this.options.queue.unshift({ 'pause': 0 }) // add a pause for 0

	function speed2Num(speed)
		switch (speed)
			case DYNAMIC_FAST:
				return 2 * Client.timeScale

			case DYNAMIC_NORMAL:
				return 4 * Client.timeScale

			case DYNAMIC_SLOW:
				return 10 * Client.timeScale

	function changeCharAt(index, char)
		if (this.options.output)
			var text = extractContent(this.options.output.text).replace(Util.regExp('\\' + this.options.caret, 'gm'), '')

			if (index < 0) // go from behind the string
				index = text.length - Math.abs(index)

			var newText = setCharAt(text, index, char)
			return newText

	function handleTags(method)
		if (!this.options.tags)
			var style = (this.options.value ? this.options.queue[0][method].value : this.options.queue[0][method]).match(Util.regExp('<.([^r>][^>]*)?>', 'gm'))
			if (style)
				this.options.tags = style
				foreach (let t in this.options.tags)
					if (this.options.value)
						this.options.queue[0][method].value = this.options.queue[0][method].value.replace(Util.regExp(t, 'gm'), '')
					else
						this.options.queue[0][method] = this.options.queue[0][method].replace(Util.regExp(t, 'gm'), '')

		if (this.options.tags)
			var half2
			var frontTags = ''
			var backTags = ''

			for (let i = 0; i < this.options.tags.length; i++)
				if (i === this.options.tags.length / 2)
					half2 = true

				if (half2)
					backTags += this.options.tags[i]
				else
					frontTags += this.options.tags[i]

			this.frontTag = (frontTags ? frontTags : '')
			this.backTag = (backTags ? backTags : '')

function extractContent(s, space)
	var span = JS.document.createElement('span')
	span.innerHTML = s

	if (space)
		var children= span.querySelectorAll('*')
		for (var i = 0; i < children.length; i++)
			if (children[i].textContent)
				children[i].textContent += ' '
			else
				children[i].innerText += ' '

	return [span.textContent || span.innerText].toString()

function setCharAt(str, index, char)
	if (index > str.length-1)
		return str

	return str.substr(0, index) + char + str.substr(index + 1)

#END CLIENTCODE

#BEGIN WEBSTYLE

#caret {
  animation: flicker 1s infinite;
}

@keyframes flicker {
  from { opacity: 1; }
  to { opacity: 0; }
}

#END WEBSTYLE
