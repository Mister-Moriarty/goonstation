/datum/say_prefix/right_hand
	id = ":rh"

/datum/say_prefix/right_hand/process(datum/say_message/message, datum/speech_module_tree/say_tree)
	. = message

	var/mob/mob_speaker = message.message_origin
	var/atom/listener

	if (ismobcritter(mob_speaker))
		var/mob/living/critter/critter = mob_speaker
		for (var/i in length(critter.hands) to 1 step -1)
			var/datum/handHolder/HH = critter.hands[i]
			if (!HH.can_hold_items || !HH.item)
				continue

			listener = HH.item
			break

	else
		listener = mob_speaker.r_hand

	if (!listener)
		return

	message.atom_listeners_to_be_excluded ||= list()
	message.atom_listeners_to_be_excluded[listener] = TRUE

	var/datum/say_message/radio_message = message.Copy()
	radio_message.atom_listeners_override = list(listener)
	say_tree.GetOutputByID(SPEECH_OUTPUT_EQUIPPED)?.process(radio_message)
