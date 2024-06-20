/// This atom's listen module tree. May be null if no input modules are registered.
/atom/var/datum/listen_module_tree/listen_tree
/// The listen modifiers that this atom *starts* with. It will not be updated nor used again after initialisation.
/atom/var/list/start_listen_modifiers
/// The listen inputs that this atom *starts* with. It will not be updated nor used again after initialisation.
/atom/var/list/start_listen_inputs
/// The listen languages that this atom *starts* with. It will not be updated nor used again after initialisation. Note this is the languages that the atom understands when heard.
/atom/var/list/start_listen_languages

/atom/New()
	if (length(src.start_listen_inputs))
		src.ensure_listen_tree()

	. = ..()

/atom/disposing()
	qdel(src.listen_tree)
	qdel(src.say_tree)

	. = ..()

/// Determines what happens to a message after this atom's listen tree has finished processing it. Typically the final destination of say message datums.
/atom/proc/hear(datum/say_message/message)
	boutput(src, message.format_for_output())


/// This atom's speech module tree. Lazy loaded on the first `say()` call.
/atom/var/datum/speech_module_tree/say_tree
/// The speech modifiers that this atom *starts* with. It will not be updated nor used again after initialisation.
/atom/var/list/start_speech_modifiers
/// The speech outputs that this atom *starts* with. It will not be updated nor used again after initialisation.
/atom/var/list/start_speech_outputs = list(SPEECH_OUTPUT_SPOKEN)
/// The default speech output module that this atom will send unprefixed say messages to. A value of `null` will sent to all available outputs.
/atom/var/default_speech_output_channel = SAY_CHANNEL_OUTLOUD
/// The default output language for say messages to be sent in.
/atom/var/say_language = LANGUAGE_ENGLISH

/// The default say verb for standard spoken phrases. Also acts as a fallback verb if contextual verbs are `null`. Accepts both text and lists
/atom/var/speech_verb_say = "says"
/// The default say verb for spoken phrases ending in a question mark. Accepts both text and lists
/atom/var/speech_verb_ask = null
/// The default say verb for spoken phrases ending in an exclaimation mark. Accepts both text and lists
/atom/var/speech_verb_exclaim = null
/// The default say verb for stammered phrases. Accepts both text and lists
/atom/var/speech_verb_stammer = null
/// The default say verb for gasped phrases. Accepts both text and lists
/atom/var/speech_verb_gasp = null

/// Whether a client controlling this mob can make this mob speak through the use of say wrappers or commands.
/mob/var/can_use_say = TRUE

/**
 *	The primary entry point for all say code; messages sent will be mutated by the speech tree, passed to a say channel, disseminated to listeners, mutated by listen trees, then finally heard by recipients.
 *	- `message`: The plain text that should be used as the content of the say message datum. See `_std/defines/speech_defines/sayflags.dm`.
 *	- `flags`: The flags that should be applied to the say message datum, which determine how it should be formatted and displayed.
 *	- `message_params`: Use this to override the default variables of the say message datum. Use explitly only where a speech module would not be appropriate.
 *	- `atom_listeners_override`: In lieu of being sent over a say channel, messages will instead attempt to be passed to the listen trees of these atoms directly.
 */
/atom/proc/say(message as text, flags = 0, list/message_params = null, list/atom/atom_listeners_override = null)
	SHOULD_CALL_PARENT(TRUE)
	if (dd_hasprefix(message, "*"))
		return src.emote(copytext(message, 2), 1)

	src.ensure_say_tree()
	var/datum/say_message/said = new(message, src, flags, message_params, atom_listeners_override)
	if (QDELETED(said) || !length(said.content))
		return

	SEND_SIGNAL(src, COMSIG_ATOM_SAY, said)
	SEND_GLOBAL_SIGNAL(COMSIG_ATOM_SAY, said)

	src.say_tree.process(said)

/// The world time that this atom last played a voice sound effect.
/atom/var/last_voice_sound = 0
/// The set of vocal sounds that this atom should use. See the `sounds_speak` global list.
/atom/var/voice_type = null
/// If set, will override `voice_type` and play the specified sound when this atom speaks.
/atom/var/voice_sound_override = null
/// The pitch of this atom's voice.
/atom/var/voice_pitch = null

/// Whether this atom should display a speech bubble after speaking.
/atom/var/use_speech_bubble = FALSE
/// The shared speech bubble appearance.
/atom/var/static/mutable_appearance/speech_bubble = global.living_speech_bubble

/// The default speech bubble for standard spoken phrases. Also acts as a fallback icon if contextual icons are `null`.
/atom/var/speech_bubble_icon_say = "speech"
/// The default speech bubble for spoken phrases ending in a question mark.
/atom/var/speech_bubble_icon_ask = "?"
/// The default speech bubble for spoken phrases ending in an exclaimation mark.
/atom/var/speech_bubble_icon_exclaim = "!"
/// The default speech bubble for sung phrases.
/atom/var/speech_bubble_icon_sing = "note"
/// The default speech bubble for sung phrases that were either sung loudly or poorly.
/atom/var/speech_bubble_icon_sing_bad = "notebad"

/// Displays an atom's speech bubble overlay, then removes it after a short delay.
/atom/proc/show_speech_bubble(image/override_image)
	src.AddOverlays(override_image || src.speech_bubble, "speech_bubble")
	OVERRIDE_COOLDOWN(src, "speech_bubble", 1.4 SECONDS)

	SPAWN(1.5 SECONDS)
		if (!GET_COOLDOWN(src, "speech_bubble"))
			src.ClearSpecificOverlays("speech_bubble")

/// Returns this atom's speech module tree. If this atom does not possess a speech module tree, instantiates one.
/atom/proc/ensure_say_tree()
	RETURN_TYPE(/datum/speech_module_tree)
	src.say_tree ||= new(src, src.start_speech_modifiers, src.start_speech_outputs)
	return src.say_tree

/// Returns this atom's listen module tree. If this atom does not possess a listen module tree, instantiates one.
/atom/proc/ensure_listen_tree()
	RETURN_TYPE(/datum/listen_module_tree)
	src.listen_tree ||= new(src, src.start_listen_inputs, src.start_listen_modifiers, src.start_listen_languages)
	return src.listen_tree

/// A stub proc to facilitate `say()` passing on messages prefixed with "*".
/atom/proc/emote(act, voluntary = FALSE, atom/target)
	set waitfor = FALSE
	SHOULD_CALL_PARENT(TRUE)
	return FALSE

/// Compare the priority of two speech/listen modules. If the priority is the same, compare them based on their ID.
/proc/cmp_say_modules(datum/speech_module/a, datum/speech_module/b)
	. = b.priority - a.priority
	. ||= cmp_text_asc(a.id, b.id)



/*

TODO:

Contributing:
- Authors: Mr. Moriarty, Amylizzle, DisturbHerb, Romayne, & Skeletonman0
- If you make a PR to the say rework branch, feel free to add your name to the above list.
- Please make an effort to adhere to the set out code style, primarily the following:
	Absolute pathing,
	Thorough documentation,
	The use of `src` and `global` when accessing applicable variables.

Limitations To Later Code Out:
- Currently tree can only support one instance of each module ID - this is not ideal for delimited listen and speech modules.
- Delimited listen modules do not harmonise with associted global listen modules - two messages will be displayed.

Cleanup:
- Move say procs into this directory.
- Tidy speech variables on types. Especially mobs. (search for speech_verb_)
- `VAR_PRIVATE` where necessary.
- `RETURN_TYPE` where necessary.

Things To Implement:
- AI
- Observers (not ghosts)
- Zoldorf
- Ghostdrones (language)
- Radio brain (bioeffect)

Old Code To Remove:
- `say_quote`
- `say_understands`
- `get_heard_name`
- `try_render_chat_to_admin`
- `process_accents`
- `separate_radio_prefix_and_message`
- `saylist`
- `proc/speak`. `all_hearers` implementations may be good to look at too.
- `say()` implementations that predate the rework.
- Replace `COMSIG_MOB_SAY` with `COMSIG_ATOM_SAY`.
- Remove the commented out `/mob/living/say` in `living.dm`.
- Remove all implementations of `say()` where the `NEWSPEECH` define is used.
- Check span defines in `chat_output.dm`. Some may now be unused.

Parity:
- Review `/mob/proc/say_quote`.
- `radio_brain`
- Potentially deprecate `protected_radio`.
- Uncool filter before/after message modifiers.

Fixes:
- Never add tags to `message.content` See message modifiers.

Accents:
- muffle?
- furious
- gurgle
- Remove `/datum/bioEffect/speech/proc/OnSpeak()`.

Refactors:
- Perhaps refactor `/mob/living/say_radio()` to be cleaner?
- Split deadchat up into multiple outputs, akin to hivechat.
- Anything that uses `SPAN_NAME` could likely be moved onto the new system.

Documentation:
- Finished! (for now)

Say Implementations To Remove:
- /code/mob/living/.../
	seanceghost.dm
	ai-camera.dm
- /obj/machinery/bot

*/





/// This client's auxiliary speech module tree.
/client/var/datum/speech_module_tree/auxiliary/say_tree
/// This client's auxiliary listen module tree.
/client/var/datum/listen_module_tree/auxiliary/listen_tree

/client/New()
	. = ..()

	src.say_tree = new(null, null, list(SPEECH_OUTPUT_OOC, SPEECH_OUTPUT_LOOC), src.mob.say_tree)
	src.listen_tree = new(null, null, null, null, src.mob.listen_tree)

	src.preferences.listen_ooc = !src.preferences.listen_ooc
	src.toggle_ooc(!src.preferences.listen_ooc)

	src.preferences.listen_looc = !src.preferences.listen_looc
	src.toggle_looc(!src.preferences.listen_looc)

	if (src.holder && !src.player_mode)
		src.holder.admin_say_tree.update_target_speech_tree(src.say_tree)
		src.holder.admin_listen_tree.update_target_listen_tree(src.listen_tree)

/client/proc/toggle_ooc(ooc_enabled)
	if (src.preferences.listen_ooc == ooc_enabled)
		return

	src.preferences.listen_ooc = ooc_enabled

	if (src.preferences.listen_ooc)
		if (src.holder && !src.player_mode)
			src.listen_tree.AddInput(LISTEN_INPUT_OOC_ADMIN)
		else
			src.listen_tree.AddInput(LISTEN_INPUT_OOC)

	else
		if (src.holder && !src.player_mode)
			src.listen_tree.RemoveInput(LISTEN_INPUT_OOC_ADMIN)
		else
			src.listen_tree.RemoveInput(LISTEN_INPUT_OOC)

/client/proc/toggle_looc(looc_enabled)
	if (src.preferences.listen_looc == looc_enabled)
		return

	src.preferences.listen_looc = looc_enabled

	if (src.preferences.listen_looc)
		if (src.holder && !src.player_mode)
			if (src.only_local_looc)
				src.listen_tree.AddInput(LISTEN_INPUT_LOOC_ADMIN_LOCAL)
			else
				src.listen_tree.AddInput(LISTEN_INPUT_LOOC_ADMIN_GLOBAL)
		else
			src.listen_tree.AddInput(LISTEN_INPUT_LOOC)

	else
		if (src.holder && !src.player_mode)
			if (src.only_local_looc)
				src.listen_tree.RemoveInput(LISTEN_INPUT_LOOC_ADMIN_LOCAL)
			else
				src.listen_tree.RemoveInput(LISTEN_INPUT_LOOC_ADMIN_GLOBAL)
		else
			src.listen_tree.RemoveInput(LISTEN_INPUT_LOOC)

/mob/Login()
	. = ..()

	src.ensure_say_tree()
	src.ensure_listen_tree()

	src.client.say_tree?.update_target_speech_tree(src.say_tree)
	src.client.listen_tree?.update_target_listen_tree(src.listen_tree)
