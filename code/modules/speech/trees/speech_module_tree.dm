/**
 *	Speech module tree datums handle applying the effects of accent, modifier, and output speech modules to say message
 *	datums sent by the parent atom. All say message datums will be processed here prior to being passed to the speech
 *	manager to be disseminated to input listen modules.
 */
/datum/speech_module_tree
	/// The owner of this speech module tree.
	var/atom/speaker_parent
	/// The atom that should act as the origin point for sending messages from this speech module tree.
	var/atom/speaker_origin

	/// An associative list of output speech module subscription counts, indexed by the module ID.
	var/list/output_module_ids_with_subcount
	/// An associative list of output speech modules, indexed by the module ID.
	var/list/datum/speech_module/output/output_modules_by_id
	/// An associative list of output speech modules, indexed by the module channel. Additionally, each sublist of modules is sorted by priority.
	var/list/datum/speech_module/output/output_modules_by_channel

	/// An associative list of modifier speech module subscription counts, indexed by the module ID.
	var/list/speech_modifier_ids_with_subcount
	/// An associative list of modifier speech modules, indexed by the module ID.
	var/list/datum/speech_module/modifier/speech_modifiers_by_id
	/// An associative list of modifier speech modules that overide say channel modifier preferences, indexed by the module ID.
	var/list/datum/speech_module/modifier/persistent_speech_modifiers_by_id

/datum/speech_module_tree/New(atom/parent, list/modifiers = list(), list/outputs = list())
	. = ..()

	src.speaker_parent = parent
	src.speaker_origin = parent

	src.output_module_ids_with_subcount = list()
	src.output_modules_by_id = list()
	src.output_modules_by_channel = list()
	for (var/output_id in outputs)
		src.AddOutput(output_id)

	src.speech_modifier_ids_with_subcount = list()
	src.speech_modifiers_by_id = list()
	src.persistent_speech_modifiers_by_id = list()
	for (var/modifier_id in modifiers)
		src.AddModifier(modifier_id)

/datum/speech_module_tree/disposing()
	for (var/output_id in src.output_modules_by_id)
		qdel(src.output_modules_by_id[output_id])

	src.persistent_speech_modifiers_by_id = null
	for (var/modifier_id in src.speech_modifiers_by_id)
		qdel(src.speech_modifiers_by_id[modifier_id])

	src.output_modules_by_id = null
	src.speech_modifiers_by_id = null
	src.output_modules_by_channel = null
	src.speaker_origin = null
	src.speaker_parent = null

	. = ..()

/// Process the message, applying the effects of each accent, speech, and output module.
/datum/speech_module_tree/proc/process(datum/say_message/message)
	if (!istype(message))
		CRASH("A non say_message thing was passed to a speech_module_tree. This should never happen.")

	var/list/datum/speech_module/output/output_modules
	if (message.output_module_override)
		var/datum/speech_module/output/output_override = src.GetOutputByID(message.output_module_override)
		if (output_override)
			output_modules = list(output_override)
	else
		output_modules = src.GetOutputByChannel(message.output_module_channel)

	if (!length(output_modules))
		return

	// If the say channel permits, apply the effects of all modifiers, otherwise only those that override say channel preferences.
	var/was_uncool = global.phrase_log.is_uncool(message.content)
	if (global.SpeechManager.GetSayChannelInstance(message.output_module_channel).affected_by_modifiers)
		for (var/modifier_id in src.speech_modifiers_by_id)
			message = src.speech_modifiers_by_id[modifier_id].process(message)
			// If the module consumed the message, no need to process any further.
			if (QDELETED(message))
				return
	else
		for (var/modifier_id in src.persistent_speech_modifiers_by_id)
			message = src.persistent_speech_modifiers_by_id[modifier_id].process(message)
			// If the module consumed the message, no need to process any further.
			if (QDELETED(message))
				return

	// If a combination of message modifiers caused the message's content to become uncool, log the modifier combination and garble the uncool words.
	if (!was_uncool && global.phrase_log.is_uncool(message.content))
		var/list/modifier_ids
		if (global.SpeechManager.GetSayChannelInstance(message.output_module_channel).affected_by_modifiers)
			modifier_ids = src.speech_modifiers_by_id.Copy()
		else
			modifier_ids = src.persistent_speech_modifiers_by_id.Copy()

		logTheThing(LOG_ADMIN, message.speaker, "[message.speaker] tried to say \"[message.original_content]\" but it was garbled into \"[message.content]\", which is uncool by the following effects: [jointext(modifier_ids, ", ")]. The uncool words were garbled.")
		message.content = replacetext(message.content, global.phrase_log.uncool_words, pick("urr", "blargh", "der", "hurr", "pllt"))

	// Apply sayflag message manipulation.
	global.SpeechManager.ApplyMessageModifierPreprocessing(message)
	message.output_module_channel = null

	// If flagged with `SAYFLAG_DO_NOT_OUTPUT`, return the message to the caller without passing it to an output module.
	. = message
	if (message.flags & SAYFLAG_DO_NOT_OUTPUT)
		return

	// Attempt to use the highest priority module as an output, defaulting to the next highest priority on failure.
	for (var/datum/speech_module/output/output_module as anything in output_modules)
		if (!CAN_PASS_MESSAGE_TO_SAY_CHANNEL(output_module.say_channel, message))
			boutput(src.speaker_parent, output_module.say_channel.disabled_message)
			continue

		var/datum/say_message/module_message = message.Copy()
		if (!output_module.process(module_message))
			continue

		// Handle say sounds and speech bubbles.
		if (!output_module.say_channel.suppress_say_sound)
			module_message.process_say_sound()
		if (!output_module.say_channel.suppress_speech_bubble)
			module_message.process_speech_bubble()

		break

/// Update this speech module tree's speaker origin. This will cause spoken messages to appear to originate fom the new speaker origin.
/datum/speech_module_tree/proc/update_speaker_origin(atom/new_origin)
	var/atom/old_origin = src.speaker_origin
	src.speaker_origin = new_origin

	SEND_SIGNAL(src, COMSIG_SPEAKER_ORIGIN_UPDATED, old_origin, new_origin)

/// Adds a new output module to the tree. Returns a reference to the new output module on success.
/datum/speech_module_tree/proc/AddOutput(output_id, count = 1)
	RETURN_TYPE(/datum/speech_module/output)

	src.output_module_ids_with_subcount[output_id] += count
	if (src.output_modules_by_id[output_id])
		return src.output_modules_by_id[output_id]

	var/datum/speech_module/output/new_output = global.SpeechManager.GetOutputInstance(output_id, src)
	if (!istype(new_output))
		return

	src.output_modules_by_id[output_id] = new_output
	src.output_modules_by_channel[new_output.channel] ||= list()
	src.output_modules_by_channel[new_output.channel] += new_output
	sortList(src.output_modules_by_channel[new_output.channel], GLOBAL_PROC_REF(cmp_say_modules))
	return new_output

/// Removes an output module from the tree. Returns TRUE on success, FALSE on failure.
/datum/speech_module_tree/proc/RemoveOutput(output_id, count = 1)
	if (!src.output_modules_by_id[output_id])
		return FALSE

	src.output_module_ids_with_subcount[output_id] -= count
	if (!src.output_module_ids_with_subcount[output_id])
		src.output_modules_by_channel[src.output_modules_by_id[output_id].channel] -= src.output_modules_by_id[output_id]
		qdel(src.output_modules_by_id[output_id])
		src.output_modules_by_id -= output_id

	return TRUE

/// Returns the output module that matches the specified ID.
/datum/speech_module_tree/proc/GetOutputByID(output_id)
	RETURN_TYPE(/datum/speech_module/output)
	return src.output_modules_by_id[output_id]

/// Returns a list of output modules that output to the specified channel.
/datum/speech_module_tree/proc/GetOutputByChannel(channel_id)
	RETURN_TYPE(/list/datum/speech_module/output)
	return src.output_modules_by_channel[channel_id]

/// Adds a new modifier module to the tree. Returns a reference to the new modifier module on success.
/datum/speech_module_tree/proc/AddModifier(modifier_id, count = 1)
	RETURN_TYPE(/datum/speech_module/modifier)

	src.speech_modifier_ids_with_subcount[modifier_id] += count
	if (src.speech_modifiers_by_id[modifier_id])
		return src.speech_modifiers_by_id[modifier_id]

	var/datum/speech_module/modifier/new_modifier = global.SpeechManager.GetSpeechModifierInstance(modifier_id)
	if (!istype(new_modifier))
		return

	src.speech_modifiers_by_id[modifier_id] = new_modifier
	sortList(src.speech_modifiers_by_id, GLOBAL_PROC_REF(cmp_say_modules), TRUE)

	if (new_modifier.override_say_channel_modifier_preference)
		src.persistent_speech_modifiers_by_id[modifier_id] = new_modifier
		sortList(src.persistent_speech_modifiers_by_id, GLOBAL_PROC_REF(cmp_say_modules), TRUE)

	return new_modifier

/// Removes a modifier from the tree. Returns TRUE on success, FALSE on failure.
/datum/speech_module_tree/proc/RemoveModifier(modifier_id, count = 1)
	if (!src.speech_modifiers_by_id[modifier_id])
		return FALSE

	src.speech_modifier_ids_with_subcount[modifier_id] -= count
	if (!src.speech_modifier_ids_with_subcount[modifier_id])
		qdel(src.speech_modifiers_by_id[modifier_id])
		src.speech_modifiers_by_id -= modifier_id
		src.persistent_speech_modifiers_by_id -= modifier_id

	return TRUE

/// Returns the speech modifier module that matches the specified ID.
/datum/speech_module_tree/proc/GetModifierByID(modifier_id)
	RETURN_TYPE(/datum/speech_module/modifier)
	return src.speech_modifiers_by_id[modifier_id]
