/datum/speech_module/prefix/radio
	id = SPEECH_PREFIX_RADIO
	prefix_id = list(";", ":")

/datum/speech_module/prefix/radio/process(datum/say_message/message)
	. = message

	var/obj/item/device/radio/radio
	if (ismob(message.message_origin))
		var/mob/mob_speaker = message.message_origin
		radio = mob_speaker.find_radio()
	else
		var/obj/item/organ/head/head = message.message_origin
		radio = head.ears

	if (!istype(radio))
		return

	message.say_sound = 'sound/misc/talk/radio.ogg'
	message.atom_listeners_to_be_excluded ||= list()
	message.atom_listeners_to_be_excluded[radio] = TRUE

	var/datum/say_message/radio_message = message.Copy()
	radio_message.atom_listeners_override = list(radio)
	src.parent_tree.GetOutputByID(SPEECH_OUTPUT_EQUIPPED)?.process(radio_message)

	message.flags |= SAYFLAG_WHISPER

/datum/speech_module/prefix/radio/get_prefix_choices()
	var/obj/item/device/radio/radio
	if (ismob(src.parent_tree.speaker_origin))
		var/mob/mob_speaker = src.parent_tree.speaker_origin
		radio = mob_speaker.find_radio()
	else
		var/obj/item/organ/head/head = src.parent_tree.speaker_origin
		radio = head.ears

	if (!istype(radio) || radio.bricked)
		return

	. = list()

	var/general_channel_name = global.headset_channel_lookup["[radio.frequency]"] || "???"
	var/general_channel_frequency = global.format_frequency(radio.frequency)
	.["[general_channel_name]: \[[general_channel_frequency]\]"] = ";"

	for (var/prefix in radio.secure_frequencies)
		var/frequency = radio.secure_frequencies[prefix]
		var/channel_name = global.headset_channel_lookup["[frequency]"] || "???"
		var/channel_frequency = global.format_frequency(frequency)
		.["[channel_name]: \[[channel_frequency]\]"] = ":[prefix]"
