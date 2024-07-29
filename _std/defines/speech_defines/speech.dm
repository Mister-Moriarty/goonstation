//------------- WRAPPERS -------------//
/// A wrapper for _AddOutput that permits the usage of named arguments.
#define AddOutput(output_id, arguments...) _AddOutput(output_id, list(##arguments))
/// A wrapper for _AddInput that permits the usage of named arguments.
#define AddInput(input_id, arguments...) _AddInput(input_id, list(##arguments))
/// A wrapper for _AddModifier that permits the usage of named arguments. This caters to both speech and listen trees.
#define AddModifier(modifier_id, arguments...) _AddModifier(modifier_id, list(##arguments))


//------------- COOLDOWNS -------------//
/// The minimum time between voice sound effects for a single atom. Measured in tenths of a second.
#define VOICE_SOUND_COOLDOWN 8
/// The minimum time between playing the cluwne laugh for atoms affacted by it. Measured in tenths of a second.
#define CLUWNE_NOISE_COOLDOWN 50


//------------- MESSAGE RANGES -------------//
/// The maximum distance from which standard spoken messages may be heard.
#define DEFAULT_HEARING_RANGE 5
/// The maximum distance from which whispered messages may be clearly heard.
#define WHISPER_RANGE 1
/// The maximum distance from which LOOC messages may be heard.
#define LOOC_RANGE 8
