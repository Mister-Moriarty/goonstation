/datum/say_channel/mentor_mouse
	suppress_speech_bubble = TRUE
	suppress_say_sound = TRUE
	channel_id = SAY_CHANNEL_MENTOR_MOUSE

/datum/speech_module/output/mentor_mouse
	id = SPEECH_OUTPUT_MENTOR_MOUSE
	channel = SAY_CHANNEL_MENTOR_MOUSE

/datum/speech_module/output/mentor_mouse/process(datum/say_message/message)
	var/mind_ref = ""
	if (ismob(message.speaker))
		var/mob/mob_speaker = message.speaker
		mind_ref = "\ref[mob_speaker.mind]"

	// We aren't *actually* whispering mechanically,

	// Handles class for admin mouse speech, since they are just rebranded mentor mice
	var/ooc_flavor = "mhelp"
	if (istype(message.speaker, /mob/dead/target_observer/mentor_mouse_observer))
		var/mob/dead/target_observer/mentor_mouse_observer/mentor_mouse = message.speaker
		if (mentor_mouse.is_admin)
			ooc_flavor = "adminooc"

	message.format_speaker_prefix = {"\
		<span class='game [ooc_flavor]'>\
			<span class='name' data-ctx='[mind_ref]'>\
	"}

	message.format_verb_prefix = {"\
		</span> \
		<span class='message'>\
	"}

	message.format_content_prefix = {"\
		, \
	"}

	message.format_message_suffix = {"\
		</span></span>\
	"}

	. = ..()

/**
 * 		var/rendered = "<span class='game say[more_class]'><span class='name' data-ctx='\ref[src.mind]'>[src.name]</span> whispers, [SPAN_MESSAGE("\"[message]\"")]</span>"
		var/rendered_admin = "<span class='game say[more_class]'><span class='name' data-ctx='\ref[src.mind]'>[src.name] ([src.ckey])</span> whispers, [SPAN_MESSAGE("\"[message]\"")]</span>"
 */
