/datum/speech_module/prefix/left_hand
	id = SPEECH_PREFIX_LEFT_HAND
	prefix_id = ":lh"

/datum/speech_module/prefix/left_hand/process(datum/say_message/message)
	. = message

	var/mob/mob_speaker = message.message_origin
	var/atom/listener

	if (ismobcritter(mob_speaker))
		var/mob/living/critter/critter = mob_speaker
		for (var/i in 1 to length(critter.hands))
			var/datum/handHolder/HH = critter.hands[i]
			if (!HH.can_hold_items || !HH.item)
				continue

			listener = HH.item
			break

	else
		listener = mob_speaker.l_hand

	if (!listener)
		return

	message.say_sound = 'sound/misc/talk/radio.ogg'
	message.atom_listeners_to_be_excluded ||= list()
	message.atom_listeners_to_be_excluded[listener] = TRUE

	var/datum/say_message/radio_message = message.Copy()
	radio_message.atom_listeners_override = list(listener)
	src.parent_tree.GetOutputByID(SPEECH_OUTPUT_EQUIPPED)?.process(radio_message)

	message.flags |= SAYFLAG_WHISPER
