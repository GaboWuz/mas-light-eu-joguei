package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var noteStyle:String;
	var stage:String;
	var validScore:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	public var noteStyle:String = 'normal';
	public var stage:String = 'stage';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		#if mobile
		// Charts saved by the Chart Editor to external storage take priority
		// over the ones bundled in the APK, so edits are actually playable.
		var external:SwagSong = loadExternal(jsonInput);

		if (external == null)
		{
			// A chart saved once in the editor is used for every difficulty.
			var base:String = jsonInput.toLowerCase();
			for (suffix in ['-easy', '-hard'])
				if (base.endsWith(suffix))
					external = loadExternal(base.substr(0, base.length - suffix.length));
		}

		if (external != null)
			return external;
		#end

		var rawJson = Assets.getText(Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase())).trim();

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);

		// trace('LOADED FROM JSON: ' + songData.notes);
		/* 
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daBpm = songData.bpm; */

		return parseJSONshit(rawJson);
	}

	#if mobile
	public static function loadExternal(jsonInput:String):SwagSong
	{
		try
		{
			var rawJson:String = AndroidStorage.readChart(jsonInput);

			if (rawJson == null || rawJson.trim() == "")
				return null;

			var swagShit:SwagSong = parseJSONshit(rawJson.trim());

			if (swagShit == null || swagShit.notes == null)
				return null;

			return swagShit;
		}
		catch (e:Dynamic)
		{
			trace('[Song] External chart invalid for ' + jsonInput + ': ' + Std.string(e));
			return null;
		}
	}
	#end

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}
}
