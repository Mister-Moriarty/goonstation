/atom/movable/abstract_say_source/flock_system
	start_speech_outputs = null
	default_speech_output_channel = SAY_CHANNEL_FLOCK
	say_language = LANGUAGE_FEATHER

/atom/movable/abstract_say_source/flock_system/New(loc, datum/flock/flock)
	. = ..()

	src.ensure_say_tree().AddSpeechOutput(SPEECH_OUTPUT_FLOCK_SYSTEM, subchannel = "\ref[flock]", flock = flock)
