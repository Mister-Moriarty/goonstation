/datum/say_channel/delimited/local/outloud
	channel_id = SAY_CHANNEL_OUTLOUD

/datum/say_channel/delimited/local/outloud/PassToChannel(datum/say_message/message)
	if (!(message.flags & SAYFLAG_WHISPER))
		var/list/list/datum/listen_module/input/listen_modules_by_type = list()

		if (isturf(message.speaker.loc))
			var/turf/centre = message.speaker.loc
			SET_UP_HEARD_TURFS(visible_turfs, message.heard_range, centre)

			for (var/type in src.listeners)
				listen_modules_by_type[type] ||= list()
				for (var/datum/listen_module/input/outloud/input as anything in src.listeners[type])
					// If the outermost listener's loc is a turf, they must be within the speaker's line of sight to hear the message.
					if (isturf(GET_INPUT_OUTERMOST_LISTENER_LOC(input)))
						if (!visible_turfs[GET_INPUT_OUTERMOST_LISTENER_LOC(input)])
							continue
					// If the outermost listener's loc is the speaker, they may hear the message.
					else if (GET_INPUT_OUTERMOST_LISTENER_LOC(input) != message.speaker)
						continue
					// If the input's hearing range is less than the message's heard range, ensure that the speaker and listener are within that range.
					if (input.hearing_range < message.heard_range)
						if (!IN_RANGE(input.parent_tree.parent, centre, input.hearing_range))
							if (!centre.vistarget || !IN_RANGE(input.parent_tree.parent, centre.vistarget, input.hearing_range))
								continue

					listen_modules_by_type[type] += input

		else
			for (var/type in src.listeners)
				listen_modules_by_type[type] ||= list()
				for (var/datum/listen_module/input/outloud/input as anything in src.listeners[type])
					// If the outermost listener of the listener and the speaker match, the listener may hear the message.
					if (GET_INPUT_OUTERMOST_LISTENER(input) != GET_MESSAGE_OUTERMOST_LISTENER(message))
						// If the outermost listener's loc is the speaker, the listener may hear the message.
						if (GET_INPUT_OUTERMOST_LISTENER_LOC(input) != message.speaker)
							// If the speaker's loc is the listener, the listener may hear the message.
							if (message.speaker.loc != input.parent_tree.parent)
								continue

					listen_modules_by_type[type] += input

		src.PassToListeners(message, listen_modules_by_type)

	// Whisper handling.
	else
		var/list/list/datum/listen_module/input/heard_clearly_listen_modules_by_type = list()
		var/list/list/datum/listen_module/input/heard_distorted_listen_modules_by_type = list()

		if (isturf(message.speaker.loc))
			var/turf/centre = message.speaker.loc
			SET_UP_HEARD_TURFS(heard_clearly_turfs, WHISPER_RANGE, centre)
			SET_UP_HEARD_DISTORTED_TURFS(heard_distorted_turfs, message.heard_range, centre, heard_clearly_turfs)

			for (var/type in src.listeners)
				heard_clearly_listen_modules_by_type[type] ||= list()
				heard_distorted_listen_modules_by_type[type] ||= list()
				for (var/datum/listen_module/input/outloud/input as anything in src.listeners[type])
					// If the input's hearing range is less than the message's heard range, ensure that the speaker and listener are within that range.
					if (input.hearing_range < message.heard_range)
						if (!IN_RANGE(input.parent_tree.parent, centre, input.hearing_range))
							if (!centre.vistarget || !IN_RANGE(input.parent_tree.parent, centre.vistarget, input.hearing_range))
								continue
					// If the outermost listener's loc is a turf, they must be within the speaker's line of sight to hear the message.
					if (isturf(GET_INPUT_OUTERMOST_LISTENER_LOC(input)))
						// If within `WHISPER_RANGE`, the message may be heard clearly.
						if (heard_clearly_turfs[GET_INPUT_OUTERMOST_LISTENER_LOC(input)])
							heard_clearly_listen_modules_by_type[type] += input
						// If outside of `WHISPER_RANGE`, but still within message range, the message will be heard distorted.
						else if (heard_distorted_turfs[GET_INPUT_OUTERMOST_LISTENER_LOC(input)])
							heard_distorted_listen_modules_by_type[type] += input
					// If the listener's loc is the speaker, they may hear the message clearly. Nested contents will not hear whispers.
					else if (input.parent_tree.parent.loc == message.speaker)
						heard_clearly_listen_modules_by_type[type] += input

		else
			for (var/type in src.listeners)
				heard_clearly_listen_modules_by_type[type] ||= list()
				for (var/datum/listen_module/input/outloud/input as anything in src.listeners[type])
					// If the listener's loc and the speaker's loc match, the listener may hear the message clearly.
					if (input.parent_tree.parent.loc != message.speaker.loc)
						// If the listener's loc is the speaker, the listener may hear the message clearly.
						if (input.parent_tree.parent.loc != message.speaker)
							// If the speaker's loc is the listener, the listener may hear the message clearly.
							if (message.speaker.loc != input.parent_tree.parent)
								continue

					heard_clearly_listen_modules_by_type[type] += input

		src.PassToListeners(message, heard_clearly_listen_modules_by_type)
		if (length(heard_distorted_listen_modules_by_type))
			var/datum/say_message/distorted_message = message.Copy()
			distorted_message.content = stars(distorted_message.content)
			src.PassToListeners(distorted_message, heard_distorted_listen_modules_by_type)

/datum/say_channel/delimited/local/outloud/log_message(datum/say_message/message)
	var/mob/M = message.speaker
	if (!istype(M) || !M.client || !(message.flags & SAYFLAG_SPOKEN_BY_PLAYER))
		return

	if (message.flags & SAYFLAG_SINGING)
		logTheThing(LOG_DIARY, src, "(singing): [message]", "say")
		phrase_log.log_phrase("sing", message.content, user = message.speaker, strip_html = TRUE)

	else if (message.flags & SAYFLAG_WHISPER)
		logTheThing(LOG_DIARY, src, "(whisper): [message]", "whisper")
		logTheThing(LOG_WHISPER, src, "SAY: [message]")
		phrase_log.log_phrase("whisper", message.content, user = message.speaker, strip_html = TRUE)

	else
		logTheThing(LOG_DIARY, src, "(spoken): [message]", "say")
		phrase_log.log_phrase("say", message.content, user = message.speaker, strip_html = TRUE)


/datum/say_channel/global_channel/outloud
	channel_id = SAY_CHANNEL_GLOBAL_OUTLOUD
	delimited_channel_id = SAY_CHANNEL_OUTLOUD
