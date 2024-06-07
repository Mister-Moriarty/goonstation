/datum/listen_module/input/outloud/global_hearing
	id = LISTEN_INPUT_GLOBAL_HEARING
	channel = SAY_CHANNEL_GLOBAL_OUTLOUD

/datum/listen_module/input/outloud/global_hearing/process(datum/say_message/message)
	var/turf/T = get_turf(message.speaker)
	if (IN_RANGE(src.parent_tree.parent, T, message.heard_range) || (T.vistarget && IN_RANGE(src.parent_tree.parent, T.vistarget, message.heard_range)))
		return

	. = ..()


/datum/listen_module/input/outloud/ears/global_counterpart
	id = LISTEN_INPUT_GLOBAL_HEARING_LOCAL_COUNTERPART

/datum/listen_module/input/outloud/ears/global_counterpart/format(datum/say_message/message)
	. = ..()

	message.format_speaker_prefix = "<b>" + message.format_speaker_prefix
	message.format_message_suffix += "</b>"
