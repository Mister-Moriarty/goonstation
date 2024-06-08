/**
 *	Listen module tree datums handle applying the effects of modifier listen modules to say message datums received by
 *	the parent atom from an input listen module. All say message datums will be processed here prior to being passed to
 *	the `/atom/proc/hear()` proc.
 */
/datum/listen_module_tree
	/// The atom that should receive messages sent to this listen module tree.
	var/atom/listener_parent
	/// The atom that should act as the origin point for listening to messages.
	var/atom/listener_origin

	/// An associative list of input listen module subscription counts, indexed by the module ID.
	var/list/input_module_ids_with_subcount
	/// An associative list of input listen modules, indexed by the module ID.
	var/list/datum/listen_module/input/input_modules_by_id
	/// An associative list of input listen modules, indexed by the module channel.
	var/list/list/datum/listen_module/input/input_modules_by_channel

	/// An associative list of modifier listen module subscription counts, indexed by the module ID.
	var/list/listen_modifier_ids_with_subcount
	/// An associative list of modifier listen modules, indexed by the module ID.
	var/list/datum/listen_module/modifier/listen_modifiers_by_id

	/// An associative list of language datum subscription counts, indexed by the language ID.
	var/list/known_language_ids_with_subcount
	/// An associative list of language datums, indexed by the language ID.
	var/list/datum/language/known_languages_by_id
	/// Whether this listen module tree is capable of understanding all languages.
	var/understands_all_languages = FALSE

/datum/listen_module_tree/New(atom/parent, list/inputs = list(), list/modifiers = list(), list/languages = list())
	. = ..()

	src.listener_parent = parent
	src.listener_origin = parent

	src.input_module_ids_with_subcount = list()
	src.input_modules_by_id = list()
	src.input_modules_by_channel = list()
	for (var/input_id in inputs)
		src.AddInput(input_id)

	src.listen_modifier_ids_with_subcount = list()
	src.listen_modifiers_by_id = list()
	for (var/modifier_id in modifiers)
		src.AddModifier(modifier_id)

	src.known_language_ids_with_subcount = list()
	src.known_languages_by_id = list()
	for (var/language_id in languages)
		src.AddKnownLanguage(language_id)

/datum/listen_module_tree/disposing()
	for (var/input_id in src.input_modules_by_id)
		qdel(src.input_modules_by_id[input_id])

	for (var/modifier_id in src.listen_modifiers_by_id)
		qdel(src.listen_modifiers_by_id[modifier_id])

	src.input_modules_by_id = null
	src.listen_modifiers_by_id = null
	src.listener_origin = null
	src.listener_parent = null

	. = ..()

/// Process the heard message, applying the effects of each listen modifier module.
/datum/listen_module_tree/proc/process(datum/say_message/message)
	if (!istype(message))
		CRASH("A non say_message thing was passed to a listen_module_tree. This should never happen.")

	if (message.received_module.say_channel.affected_by_modifiers)
		if (src.understands_all_languages || src.known_languages_by_id[message.language.id])
			message = message.language.heard_understood(message)
		else
			message = message.language.heard_not_understood(message)

		if (QDELETED(message))
			return

		for (var/modifier_id in src.listen_modifiers_by_id)
			message = src.listen_modifiers_by_id[modifier_id].process(message)
			// If the module consumed the message, no need to process any further.
			if (QDELETED(message))
				return

	src.listener_parent.hear(message)

	if (message.hear_sound && !message.received_module.say_channel.suppress_hear_sound && ismob(src.listener_parent))
		var/mob/mob_listener = src.listener_parent
		mob_listener.playsound_local_not_inworld(message.hear_sound, 55, 0.01, flags = SOUND_IGNORE_SPACE)


/// Migrate the listener origin to a different atom. This will cause parent to hear messages from the location of the new listener origin.
/datum/listen_module_tree/proc/migrate_listener_origin(atom/new_origin)
	var/atom/old_origin = src.listener_origin
	src.listener_origin = new_origin

	SEND_SIGNAL(src, COMSIG_LISTENER_ORIGIN_MIGRATED, old_origin, new_origin)

/// Adds a new input module to the tree. Returns a reference to the new input module on success.
/datum/listen_module_tree/proc/AddInput(input_id, count = 1)
	RETURN_TYPE(/datum/listen_module/input)

	src.input_module_ids_with_subcount[input_id] += count
	if (src.input_modules_by_id[input_id])
		return src.input_modules_by_id[input_id]

	var/datum/listen_module/input/new_input = global.SpeechManager.GetInputInstance(input_id, src)
	if (!istype(new_input))
		return

	src.input_modules_by_id[input_id] = new_input
	src.input_modules_by_channel[new_input.channel] ||= list()
	src.input_modules_by_channel[new_input.channel] += new_input
	return new_input

/// Removes an input from the tree. Returns TRUE on success, FALSE on failure.
/datum/listen_module_tree/proc/RemoveInput(input_id, count = 1)
	if (!src.input_modules_by_id[input_id])
		return FALSE

	src.input_module_ids_with_subcount[input_id] -= count
	if (!src.input_module_ids_with_subcount[input_id])
		src.input_modules_by_channel[src.input_modules_by_id[input_id].channel] -= src.input_modules_by_id[input_id]
		qdel(src.input_modules_by_id[input_id])
		src.input_modules_by_id -= input_id

	return TRUE

/// Returns the input module that matches the specified ID.
/datum/listen_module_tree/proc/GetInputByID(input_id)
	RETURN_TYPE(/datum/listen_module/input)
	return src.input_modules_by_id[input_id]

/// Returns a list of output modules that output to the specified channel.
/datum/listen_module_tree/proc/GetInputByChannel(channel_id)
	RETURN_TYPE(/list/datum/listen_module/input)
	. = list()

	for (var/input_id as anything in src.input_modules_by_id)
		if (src.input_modules_by_id[input_id].channel == channel_id)
			. += src.input_modules_by_id[input_id]

/// Adds a new modifier module to the tree. Returns a reference to the new modifier module on success.
/datum/listen_module_tree/proc/AddModifier(modifier_id, count = 1)
	RETURN_TYPE(/datum/listen_module/modifier)

	src.listen_modifier_ids_with_subcount[modifier_id] += count
	if (src.listen_modifiers_by_id[modifier_id])
		return src.listen_modifiers_by_id[modifier_id]

	var/datum/listen_module/modifier/new_modifier = global.SpeechManager.GetListenModifierInstance(modifier_id, src)
	if (!istype(new_modifier))
		return

	src.listen_modifiers_by_id[modifier_id] = new_modifier
	sortList(src.listen_modifiers_by_id, GLOBAL_PROC_REF(cmp_say_modules), TRUE)
	return new_modifier

/// Removes a modifier from the tree. Returns TRUE on success, FALSE on failure.
/datum/listen_module_tree/proc/RemoveModifier(modifier_id, count = 1)
	if (!src.listen_modifiers_by_id[modifier_id])
		return FALSE

	src.listen_modifier_ids_with_subcount[modifier_id] -= count
	if (!src.listen_modifier_ids_with_subcount[modifier_id])
		qdel(src.listen_modifiers_by_id[modifier_id])
		src.listen_modifiers_by_id -= modifier_id

	return TRUE

/// Returns the listen modifier module that matches the specified ID.
/datum/listen_module_tree/proc/GetModifierByID(modifier_id)
	RETURN_TYPE(/list/datum/listen_module/modifier)
	return src.listen_modifiers_by_id[modifier_id]

/// Adds a known language to this listen tree. Known languages allow messages to be understood. Returns TRUE on success, FALSE on failure.
/datum/listen_module_tree/proc/AddKnownLanguage(language_id, count = 1)
	if (language_id == LANGUAGE_ALL)
		return src.AddLanguageAllSubcount(count)

	src.known_language_ids_with_subcount[language_id] += count
	if (src.known_languages_by_id[language_id])
		return TRUE

	var/datum/language/language = global.SpeechManager.GetLanguageInstance(language_id)
	if (!istype(language))
		return FALSE

	src.known_languages_by_id[language_id] = language
	return TRUE

/// Removes a known language from this listen tree. Known languages allow messages to be understood. Returns TRUE on success, FALSE on failure.
/datum/listen_module_tree/proc/RemoveKnownLanguage(language_id, count = 1)
	if (language_id == LANGUAGE_ALL)
		return src.RemoveLanguageAllSubcount(count)

	if (!src.known_languages_by_id[language_id])
		return TRUE

	src.known_language_ids_with_subcount[language_id] -= count
	if (!src.known_language_ids_with_subcount[language_id])
		src.known_languages_by_id -= language_id

	return TRUE

/// Adds a count from the `LANGUAGE_ALL` subcount, and enables `understands_all_languages`.
/datum/listen_module_tree/proc/AddLanguageAllSubcount(count = 1)
	src.known_language_ids_with_subcount[LANGUAGE_ALL] += count
	src.understands_all_languages = TRUE
	return TRUE

/// Removes a count from the `LANGUAGE_ALL` subcount, and disables `understands_all_languages` if no counts remain.
/datum/listen_module_tree/proc/RemoveLanguageAllSubcount(count = 1)
	if (!src.understands_all_languages)
		return TRUE

	src.known_language_ids_with_subcount[LANGUAGE_ALL] -= count
	if (!src.known_language_ids_with_subcount[LANGUAGE_ALL])
		src.understands_all_languages = FALSE

	return TRUE
