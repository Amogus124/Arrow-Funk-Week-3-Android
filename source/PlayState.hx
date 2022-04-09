package;

#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;

#if sys
import sys.FileSystem;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['Go play the tutorial lmao.', 0.2], //From 0% to 19%
		['You suck!!', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	
	#if (haxe >= "4.0.0")
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	#else
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, Dynamic>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	#end

	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	//SONG NAME CREDIT SHIT IDK
	var songinfo:FlxSprite;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	private var healthBarOV:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	

	var botplaySine:Float = 0;
	var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;
	

	//COISAS DO ARROW FUNK

		//BALADA
		private var angryDad:Bool = false; //eu só peguei da outra versão, eu nem sei se isso ainda ta sendo usado lmao

			//luz
			var fundo1:BGSprite;
			var chao1:BGSprite;
			var base1:BGSprite;
			var luzes1:BGSprite;
			var curti1:BGSprite;
			//escuro
			var fundo2:BGSprite;
			var chao2:BGSprite;
			var base2:BGSprite;
			var luzes2:BGSprite;
			var curti2:BGSprite;

			var balight:BGSprite;

			//interruptor
			private var BaladaIsDark:Bool = false;


			
	

		//BALADA DO MEDO UUU
		var spookers:BGSprite;
		var dancef:BGSprite;

		var barbaravirus:BGSprite;

		var floorcolor:Int = 1;
		var spookersvel:Int = 2;
		var dancefvel:Int = 2;
		


		//COISINHAS DA FAVELA VAI BRASIL UOOOOHHHOOOOOOOOOOOOOO!!
		//eis que a favela venceu fml tmj

		private var gfmedo:Bool = false;
		var kleistate:Int = 3;

		var carrofoda:BGSprite;
		var danielzinho:BGSprite;
		var daniel:BGSprite;
		var kleitin:BGSprite;
		var busao:BGSprite;

		//frente da tela
		var acidscreen:FlxSprite;
		var favelalight:FlxSprite;
		var favelight:FlxSprite;
		var poste:FlxSprite;
		var pessoas:BGSprite;
		var treefront:FlxSprite;
		var florestalight:FlxSprite;

	var phillyCityLights:FlxTypedGroup<BGSprite>;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:ModchartSprite;
	var blammedLightsBlackTween:FlxTween;
	var phillyCityLightsEvent:FlxTypedGroup<BGSprite>;
	var phillyCityLightsEventTween:FlxTween;
	var trainSound:FlxSound;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	override public function create()
	{
		#if MODS_ALLOWED
		Paths.destroyLoadedImages();
		#end

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		curStage = PlayState.SONG.stage;
		//trace('stage is: ' + curStage);
		if(PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				default:
					curStage = 'balada';
			}
		}

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,
			
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100]
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{

			case 'balada': //Week 1
				defaultCamZoom = 0.57;

								
				//FAÇA uh... Escuro??

				fundo2 = new BGSprite('stages/balada/layer1D', -0, 0, 0.94, 0.9);
				fundo2.screenCenter(XY);
				add(fundo2);
				

				chao2 = new BGSprite('stages/balada/layer2D', 0, 0, 0.9, 0.9);
				chao2.screenCenter(XY);
				chao2.updateHitbox();
				add(chao2);
				

				base2 = new BGSprite('stages/balada/layer3D', 0, 0, 0.88, 0.9);
				base2.screenCenter(XY);
				add(base2);
				

				luzes2 = new BGSprite('stages/balada/layer4D', 0, 0, 0.86, 0.86);
				luzes2.screenCenter(XY);
				add(luzes2);
				

				curti2 = new BGSprite('stages/balada/layer5D', 0, 0, 0.82, 0.9);
				curti2.screenCenter(XY);
				add(curti2);
				

				balight = new BGSprite('stages/balada/light', 0, 0, 0.80, 0.9);
				balight.screenCenter(XY);
				balight.alpha = 0;
				

					//FAÇA LUZ
					fundo1 = new BGSprite('stages/balada/layer1', -0, 0, 0.94, 0.9);
					fundo1.screenCenter(XY);
					add(fundo1);

					chao1 = new BGSprite('stages/balada/layer2', 0, 0, 0.9, 0.9);
					chao1.screenCenter(XY);
					chao1.updateHitbox();
					add(chao1);

					base1 = new BGSprite('stages/balada/layer3', 0, 0, 0.88, 0.9);
					base1.screenCenter(XY);
					add(base1);

					luzes1 = new BGSprite('stages/balada/layer4', 0, 0, 0.86, 0.86);
					luzes1.screenCenter(XY);
					add(luzes1);

					curti1 = new BGSprite('stages/balada/layer5', 0, 0, 0.82, 0.9);
					curti1.screenCenter(XY);
					add(curti1);
				
				case 'baladamedo': //Week 2

				defaultCamZoom = 0.56;
				
				GameOverSubstate.characterName = 'bidu-spooky';

				var bg:BGSprite = new BGSprite('stages/baladamedo/layer0', -0, 0, 0.9, 0.9);
				
				bg.screenCenter(XY);
				add(bg);

				var front:BGSprite = new BGSprite('stages/baladamedo/layer1', 0, 0, 0.9, 0.9);
				
				front.screenCenter(XY);
				front.updateHitbox();
				add(front);
				
				spookers = new BGSprite('stages/baladamedo/spookers', 0, 0, 0.9, 0.9, ['SPEAKERS']);
				spookers.screenCenter(XY);
				spookers.y += 125;
				spookers.x += 6;
				add(spookers);

				//CHAO (por favor funciona eu nao aguento mais esse sofrimento)

				dancef = new BGSprite('stages/baladamedo/dancefloor', 0, 0, 0.9, 0.9, ['floor0a']);
				dancef.animation.addByPrefix('floor1', 'floor1a', 24, false);
				dancef.animation.addByPrefix('floor2', 'floor2a', 24, false);
				dancef.animation.addByPrefix('floor3', 'floor3a', 24, false);	
				dancef.animation.addByPrefix('floor4', 'floor4a', 24, false);
				dancef.animation.addByPrefix('floor5', 'floor5a', 24, false);
				dancef.screenCenter(XY);
				dancef.visible = ClientPrefs.flashing;
				add(dancef);
				dancef.alpha = 0.001;

				case 'baladamedovirus': //Week 2

				//defaultCamZoom = 0.56;
				defaultCamZoom = 0.56;
				
				GameOverSubstate.characterName = 'bidu-virus';

				var bg:BGSprite = new BGSprite('stages/baladamedo/layer0', -0, 0, 0.9, 0.9);
				
				bg.screenCenter(XY);
				add(bg);

				var front:BGSprite = new BGSprite('stages/baladamedo/layer1virus', 0, 0, 0.9, 0.9);
				front.screenCenter(XY);
				front.updateHitbox();
				add(front);
				
				dancef = new BGSprite('stages/baladamedo/dancefloor_virus', 0, 0, 0.9, 0.9, ['floor0a']);
				dancef.animation.addByPrefix('floor1', 'floor1a', 24, false);
				dancef.animation.addByPrefix('floor2', 'floor2a', 24, false);
				dancef.animation.addByPrefix('floor3', 'floor3a', 24, false);	
				dancef.animation.addByPrefix('floor4', 'floor4a', 24, false);
				dancef.animation.addByPrefix('floor5', 'floor5a', 24, false);
				dancef.screenCenter(XY);
				add(dancef);

				spookers = new BGSprite('stages/baladamedo/spookers_virus', 0, 0, 0.9, 0.9, ['SPEAKERS_VIRUS']);
				spookers.screenCenter(XY);
				spookers.y += 125;
				spookers.x += 6;
				add(spookers);

				barbaravirus = new BGSprite('stages/baladamedo/barbara', 0, 0, 0.9, 0.9, ['danceleft']);
				barbaravirus.animation.addByPrefix('danceleft', 'danceleft', 24, false);
				barbaravirus.animation.addByPrefix('danceright', 'danceright', 24, false);
				add(barbaravirus);
				barbaravirus.y -= 630;
				barbaravirus.x -= 630;
				

				acidscreen = new BGSprite('stages/baladamedo/screen', 0, 0, 0.95, 0.95);
				acidscreen.screenCenter(XY);
				acidscreen.cameras = [camHUD];
				
			case 'spooky': //Week 2 (OG)
				if(!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -FlxG.width, -FlxG.height, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				CoolUtil.precacheSound('thunder_1');
				CoolUtil.precacheSound('thunder_2');

			case 'favela': //Week 3 (só que no por do sol) //favelinha //fava //SLA

				defaultCamZoom = 0.68;
				
				//bf com o mic de ouro lol 
				GameOverSubstate.characterName = 'bidu-gold';

				var sky:BGSprite = new BGSprite('stages/favela/layer0', 0, 0, 0.1, 0.1);
				sky.screenCenter(XY);
				add(sky);
				
				var roaded:BGSprite = new BGSprite('stages/favela/layer6', 0, 0, 0.2, 0.2);
				roaded.screenCenter(XY);
				roaded.setGraphicSize(Std.int(roaded.width * 0.85));
				add(roaded);

				var houseback:BGSprite = new BGSprite('stages/favela/layer52', 0, 0, 0.36, 0.36);
				houseback.screenCenter(XY);
				add(houseback);

				var house:BGSprite = new BGSprite('stages/favela/layer5', 0, 0, 0.4, 0.4);
				house.screenCenter(XY);
				add(house);

				var tree:BGSprite = new BGSprite('stages/favela/layer42', 0, 0, 0.420, 0.420);
				tree.screenCenter(XY);
				add(tree);
				
				var brickthing:BGSprite = new BGSprite('stages/favela/layer4', 0, 0, 0.65, 0.65);
				brickthing.screenCenter(XY);
				add(brickthing);

				var thing:BGSprite = new BGSprite('stages/favela/layer3', 0, 0, 0.69, 0.69);
				thing.screenCenter(XY);
				add(thing);

				danielzinho = new BGSprite('stages/favela/danielzinho', 500, 510, 0.7, 0.7, ['danielwalk']);
				//danielzinho.x = 500;
				add(danielzinho);
				

				carrofoda = new BGSprite('stages/favela/carrofoda', 0, 600, 0.72, 0.72);
				add(carrofoda);
				
				busao = new BGSprite('stages/favela/busao', 2300, -40, 0.7, 0.7, ['busao']);
				add(busao);

				var city:BGSprite = new BGSprite('stages/favela/layer2', 0, 0, 0.85, 0.85);
				city.screenCenter(XY);
				add(city);

				var street:BGSprite = new BGSprite('stages/favela/layer1', 0, 0, 0.9, 0.9);
				street.screenCenter(XY);
				add(street);
				//street.alpha = 0.5; //a
				
				daniel = new BGSprite('stages/favela/daniel', -540, 260, 0.92, 0.91, ['danieldance']);
				//daniel.screenCenter(XY);
				daniel.x = -2000;
				//kleito
				kleitin = new BGSprite('stages/favela/kleitin', 2500, 255, 0.9, 0.9, ['kleiwalk']);
				//2500, 240
				kleitin.animation.addByPrefix('walk', 'kleiwalk', 24, true);
				kleitin.animation.addByPrefix('stop', 'kleistop', 24, false);
				kleitin.animation.addByPrefix('idle', 'kleidance', 24, false);
				kleitin.animation.addByPrefix('susto', 'kleisusto', 24, false);
				kleitin.animation.addByPrefix('dance', 'kleitin', 24, false);
				kleitin.animation.addByPrefix('bala', 'kleitiro', 24, false);
				


				//danielzinho.x = 500;

				favelalight = new BGSprite('stages/favela/layer7', 0, 0, 0.1, 0.1);
				favelalight.screenCenter(XY);

				favelight = new BGSprite('stages/favela/layer7', 0, 0, 0.8, 0.8);
				favelight.screenCenter(XY);
				

				
				case 'faveladia': //Week 3
				defaultCamZoom = 0.76;
				//bf com o mic de ouro lol 
				GameOverSubstate.characterName = 'bidu-gold';

				var sky:BGSprite = new BGSprite('stages/faveladia/layer0', 0, 0, 0.1, 0.1);
				sky.screenCenter(XY);
				add(sky);
				
				var roaded:BGSprite = new BGSprite('stages/faveladia/layer6', 0, 0, 0.2, 0.2);
				roaded.screenCenter(XY);
				roaded.setGraphicSize(Std.int(roaded.width * 0.85));
				add(roaded);

				var houseback:BGSprite = new BGSprite('stages/faveladia/layer52', 0, 0, 0.36, 0.36);
				houseback.screenCenter(XY);
				add(houseback);

				var house:BGSprite = new BGSprite('stages/faveladia/layer5', 0, 0, 0.4, 0.4);
				house.screenCenter(XY);
				add(house);

				var tree:BGSprite = new BGSprite('stages/faveladia/layer42', 0, 0, 0.420, 0.420);
				tree.screenCenter(XY);
				add(tree);
				
				var brickthing:BGSprite = new BGSprite('stages/faveladia/layer4', 0, 0, 0.65, 0.65);
				brickthing.screenCenter(XY);
				add(brickthing);

				var thing:BGSprite = new BGSprite('stages/faveladia/layer3', 0, 0, 0.69, 0.69);
				thing.screenCenter(XY);
				add(thing);

				phillyTrain = new BGSprite('stages/faveladia/busao', 2000, 560);
				//phillyTrain.scale.set(1.8, 1.8);
				add(phillyTrain);

				
				var city:BGSprite = new BGSprite('stages/faveladia/layer2', 0, 0, 0.85, 0.85);
				city.screenCenter(XY);
				add(city);

				var street:BGSprite = new BGSprite('stages/faveladia/layer1', 0, 0, 0.9, 0.9);
				street.screenCenter(XY);
				add(street);

				
				favelalight = new BGSprite('stages/faveladia/layer7', 0, 0, 0.1, 0.1);
				favelalight.screenCenter(XY);

			case 'favelanoite': //Week 3 (só que de noite ué)

			defaultCamZoom = 0.75;

			gfmedo = true;
			
				//bf com o mic de ouro lol 
				GameOverSubstate.characterName = 'bidu-gold';

				var sky:BGSprite = new BGSprite('stages/favelanoite/layer0', 0, 0, 0.1, 0.1);
				sky.screenCenter(XY);
				add(sky);
				
				var roaded:BGSprite = new BGSprite('stages/favelanoite/layer6', 0, 0, 0.2, 0.2);
				roaded.screenCenter(XY);
				roaded.setGraphicSize(Std.int(roaded.width * 0.85));
				add(roaded);

				var houseback:BGSprite = new BGSprite('stages/favelanoite/layer52', 0, 0, 0.36, 0.36);
				houseback.screenCenter(XY);
				add(houseback);

				var house:BGSprite = new BGSprite('stages/favelanoite/layer5', 0, 0, 0.4, 0.4);
				house.screenCenter(XY);
				add(house);

				var tree:BGSprite = new BGSprite('stages/favelanoite/layer42', 0, 0, 0.420, 0.420);
				tree.screenCenter(XY);
				add(tree);
				
				var brickthing:BGSprite = new BGSprite('stages/favelanoite/layer4', 0, 0, 0.65, 0.65);
				brickthing.screenCenter(XY);
				add(brickthing);

				var thing:BGSprite = new BGSprite('stages/favelanoite/layer3', 0, 0, 0.69, 0.69);
				thing.screenCenter(XY);
				add(thing);

				carrofoda = new BGSprite('stages/favelanoite/carrofoda', -600, 600, 0.72, 0.72);
				add(carrofoda);

				busao = new BGSprite('stages/favelanoite/busao', 230, -40, 0.7, 0.7, ['busao']);
				add(busao);

				var city:BGSprite = new BGSprite('stages/favelanoite/layer2', 0, 0, 0.85, 0.85);
				city.screenCenter(XY);
				add(city);

				var street:BGSprite = new BGSprite('stages/favelanoite/layer1', 0, 0, 0.9, 0.9);
				street.screenCenter(XY);
				add(street);
				
				daniel = new BGSprite('stages/favelanoite/daniel', -540, 260, 0.92, 0.91, ['danieldance']);
				//daniel.screenCenter(XY);
				
				//kleito
				kleitin = new BGSprite('stages/favelanoite/kleitin', 1080, 255, 0.9, 0.9, ['kleiwalk']);
				kleitin.animation.addByPrefix('walk', 'kleiwalk', 24, true);
				kleitin.animation.addByPrefix('stop', 'kleistop', 24, false);
				kleitin.animation.addByPrefix('idle', 'kleidance', 24, false);
				kleitin.animation.addByPrefix('susto', 'kleisusto', 24, false);
				kleitin.animation.addByPrefix('dance', 'kleitin', 24, false);
				kleitin.animation.addByPrefix('bala', 'kleitiro', 24, false);

				favelalight = new BGSprite('stages/favelanoite/layer7', 0, 0, 0.1, 0.1);
				favelalight.screenCenter(XY);

				pessoas = new BGSprite('stages/favelanoite/CARRO', 0, 0, 1, 1, ['carroum']);
				pessoas.animation.addByPrefix('dance', 'carroum', 24, false);
				pessoas.screenCenter(XY);
				pessoas.y += 685;
				
				

			case 'floresta': //Salsicha
			
				defaultCamZoom = 0.48;

				var sky:BGSprite = new BGSprite('stages/floresta/layer0', 0, 0, 0.1, 0.1);
				sky.screenCenter(XY);
				add(sky);
				
				var tree:BGSprite = new BGSprite('stages/floresta/layer1', 0, 0, 0.2, 0.2);
				tree.screenCenter(XY);
				add(tree);

				var tree:BGSprite = new BGSprite('stages/floresta/layer2', 0, 0, 0.46, 0.46);
				tree.screenCenter(XY);
				add(tree);

				var tree:BGSprite = new BGSprite('stages/floresta/layer3', 0, 0, 0.55, 0.55);
				tree.screenCenter(XY);
				add(tree);

				var tree:BGSprite = new BGSprite('stages/floresta/layer4', 0, 0, 0.66, 0.66);
				tree.screenCenter(XY);
				add(tree);

				var pedras:BGSprite = new BGSprite('stages/floresta/layer5', 0, 0, 0.85, 0.85);
				pedras.screenCenter(XY);
				add(pedras);

				var van:BGSprite = new BGSprite('stages/floresta/layer6', 0, 0, 0.9, 0.9);
				van.screenCenter(XY);
				add(van);

				treefront = new BGSprite('stages/floresta/layer7', 0, 0, 0.95, 0.95);
				treefront.screenCenter(XY);

				florestalight = new BGSprite('stages/floresta/layer8', 0, 0, 0.1, 0.1);
				florestalight.screenCenter(XY);
				
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
				/*
			case 'spooky': //Week 2
				if(!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -FlxG.width, -FlxG.height, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				CoolUtil.precacheSound('thunder_1');
				CoolUtil.precacheSound('thunder_2');
*/
			case 'philly': //Week 3
				defaultCamZoom = 0.46;
					
				GameOverSubstate.characterName = 'bidu-spooky';

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyCityLights = new FlxTypedGroup<BGSprite>();
				add(phillyCityLights);

				for (i in 0...5)
				{
					var light:BGSprite = new BGSprite('philly/dancefloor' + i, city.x, city.y, 0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					phillyCityLights.add(light);
				}

				if(!ClientPrefs.lowQuality) {
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				CoolUtil.precacheSound('train_passes');
				FlxG.sound.list.add(trainSound);

				var street:BGSprite = new BGSprite('philly/street', -40, 50);
				add(street);

			case 'limo': //Week 4
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!ClientPrefs.lowQuality) {
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...4)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					//PRECACHE SOUND
					CoolUtil.precacheSound('dancerdeath');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': //Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!ClientPrefs.lowQuality) {
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				CoolUtil.precacheSound('Lights_Shut_off');

			case 'mallEvil': //Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': //Week 6 - Senpai, Roses
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!ClientPrefs.lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!ClientPrefs.lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': //Week 6 - Thorns
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				/*if(!ClientPrefs.lowQuality) { //Does this even do something?
					var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
					var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
				}*/

				var posX = 400;
				var posY = 200;
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				} else {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}
		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'balada':
				
					boyfriendGroup.y -= 10;
					boyfriendGroup.x += 65;
					dadGroup.y -= 10;
					dadGroup.x -= 90;
					gfGroup.y -= 10;
					gfGroup.x -= 115;
					
					gfGroup.scrollFactor.set(0.93, 0.9);
					boyfriendGroup.scrollFactor.set(0.9, 0.9);
					dadGroup.scrollFactor.set(0.9, 0.9);

			case 'baladamedo':
				boyfriendGroup.y -= 60;
				boyfriendGroup.x += 35;
				dadGroup.y -= 22;
				dadGroup.x -= 180;
				gfGroup.x -= 80;
				gfGroup.y -= 88;
				
				gfGroup.scrollFactor.set(0.9, 0.9);
				boyfriendGroup.scrollFactor.set(0.9, 0.9);
				dadGroup.scrollFactor.set(0.9, 0.9);

			case 'baladamedovirus':
				boyfriendGroup.y -= 60;
				boyfriendGroup.x += 35;
				dadGroup.y -= 22;
				dadGroup.x -= 180;
				gfGroup.x -= 80;
				gfGroup.y -= 88;
				
				gfGroup.scrollFactor.set(0.9, 0.9);
				boyfriendGroup.scrollFactor.set(0.9, 0.9);
				dadGroup.scrollFactor.set(0.9, 0.9);

			case 'favela':
				boyfriendGroup.y -= 80;
				boyfriendGroup.x += 42;

				dadGroup.x -= 180;
				dadGroup.y -= 35;

				gfGroup.y -= 15;
				gfGroup.x -= 20;

				gfGroup.scrollFactor.set(0.9, 0.9);
				boyfriendGroup.scrollFactor.set(0.9, 0.9);
				dadGroup.scrollFactor.set(0.9, 0.9);

			case 'faveladia':
				boyfriendGroup.y -= 80;
				boyfriendGroup.x += 42;

				dadGroup.x -= 180;
				dadGroup.y -= 35;

				gfGroup.y -= 15;
				gfGroup.x -= 20;

				gfGroup.scrollFactor.set(0.9, 0.9);
				boyfriendGroup.scrollFactor.set(0.9, 0.9);
				dadGroup.scrollFactor.set(0.9, 0.9);

			case 'favelanoite':
				boyfriendGroup.y -= 80;
				boyfriendGroup.x += 42;

				dadGroup.x -= 180;
				dadGroup.y -= 35;

				gfGroup.y -= 15;
				gfGroup.x -= 20;

				gfGroup.scrollFactor.set(0.9, 0.9);
				boyfriendGroup.scrollFactor.set(0.9, 0.9);
				dadGroup.scrollFactor.set(0.9, 0.9);

			case 'floresta':
			
				boyfriendGroup.x += 390;
				dadGroup.x -= 440;
				gfGroup.y -= 250;
				gfGroup.x -= 100;
				
				gfGroup.scale.set(0.8, 0.8);
				gfGroup.scrollFactor.set(0.85, 0.85);
				boyfriendGroup.scrollFactor.set(0.9, 0.9);
				dadGroup.scrollFactor.set(0.9, 0.9);

			case 'mall':
				boyfriendGroup.x += 200;

			case 'mallEvil':
				boyfriendGroup.x += 320;
				dad.y -= 80;
			case 'school':
				boyfriendGroup.x += 200;
				boyfriendGroup.y += 220;
				gfGroup.x += 180;
				gfGroup.y += 300;
			case 'schoolEvil':
				if(FlxG.save.data.distractions){
				// trailArea.scrollFactor.set();
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				// evilTrail.changeValuesEnabled(false, false, false, false);
				// evilTrail.changeGraphic()
				add(evilTrail);
				// evilTrail.scrollFactor.set(1.1, 1.1);
				}


				boyfriendGroup.x += 200;
				boyfriendGroup.y += 220;
				gfGroup.x += 180;
				gfGroup.y += 300;
		}


		add(gfGroup);

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		if (curStage == 'baladamedovirus') {

		add(barbaravirus);

		}

		add(dadGroup);
		add(boyfriendGroup);
		
		if(curStage == 'balada') {

			add(balight);
			
		}

		if(curStage == 'baladamedovirus') {

				
				add(acidscreen);
				
		}
		
		if(curStage == 'faveladia') {

			add(favelalight);

		}

		if(curStage == 'favela') {
			add(daniel);
			add(kleitin);
			add(favelalight);
			add(favelight);
		}

		if(curStage == 'favelanoite') {
			add(daniel);
			add(kleitin);
			add(favelalight);
			add(pessoas);
			add(poste);
		}
		

		if(curStage == 'floresta') {
			add(treefront);
			add(florestalight);
		}
		
		if(curStage == 'spooky') {
			add(halloweenWhite);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		if(curStage == 'philly') {
			phillyCityLightsEvent = new FlxTypedGroup<BGSprite>();
			for (i in 0...5)
			{
				var light:BGSprite = new BGSprite('philly/win' + i, -10, 0, 0.3, 0.3);
				light.visible = false;
				light.setGraphicSize(Std.int(light.width * 0.85));
				light.updateHitbox();
				phillyCityLightsEvent.add(light);
			}
		}



		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [SUtil.getPath() + Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end
		

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = SUtil.getPath() + Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush) 
			luaArray.push(new FunkinLua(luaFile));
		#end

		if(!modchartSprites.exists('blammedLightsBlack')) { //Creates blammed light black fade in case you didn't make your own
			blammedLightsBlack = new ModchartSprite(FlxG.width * -0.5, FlxG.height * -0.5);
			blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
			var position:Int = members.indexOf(gfGroup);
			if(members.indexOf(boyfriendGroup) < position) {
				position = members.indexOf(boyfriendGroup);
			} else if(members.indexOf(dadGroup) < position) {
				position = members.indexOf(dadGroup);
			}
			insert(position, blammedLightsBlack);

			blammedLightsBlack.wasAdded = true;
			modchartSprites.set('blammedLightsBlack', blammedLightsBlack);
		}
		if(curStage == 'philly') insert(members.indexOf(blammedLightsBlack) + 1, phillyCityLightsEvent);
		blammedLightsBlack = modchartSprites.get('blammedLightsBlack');
		blammedLightsBlack.alpha = 0.0;

		var gfVersion:String = SONG.player3;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				default:
					gfVersion = 'gf';
			}
			SONG.player3 = gfVersion; //Fix for the Chart Editor
		}

		gf = new Character(0, 0, gfVersion);
		startCharacterPos(gf);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);
		startCharacterLua(gf.curCharacter);

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);
		
		var camPos:FlxPoint = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
		camPos.x += gf.cameraPosition[0];
		camPos.y += gf.cameraPosition[1];

		if(dad.curCharacter.startsWith('kevin')) {
			gf.visible = false;
		}

		switch(curStage)
		{
			case 'limo':
				resetFastCar();
				insert(members.indexOf(gfGroup) - 1, fastCar);
			
			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				insert(members.indexOf(dadGroup) - 1, evilTrail);
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(SUtil.getPath() + file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(SUtil.getPath() + file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFAE75);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = SUtil.getPath() + Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = SUtil.getPath() + Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		healthBarOV = new AttachedSprite('healthBarOV');
		healthBarOV.y = FlxG.height * 0.89;
		healthBarOV.screenCenter(X);
		healthBarOV.scrollFactor.set();
		healthBarOV.visible = !ClientPrefs.hideHud;
		healthBarOV.xAdd = -4;
		healthBarOV.yAdd = -4;
		add(healthBarOV);

		if(ClientPrefs.downScroll) healthBarOV.y = 0.11 * FlxG.height;

		//Coisa la da musica sla
		songinfo = new AttachedSprite('song/song-' + curSong);
		songinfo.scrollFactor.set();
		songinfo.visible = !ClientPrefs.hideHud;
		songinfo.x -= 500;
		add(songinfo);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		
		reloadHealthBarColors();

		add(iconP2);
		add(iconP1);

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("Vividly-Regular.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("Vividly-Regular.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		healthBarOV.cameras = [camHUD];
		songinfo.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

                #if android
                addAndroidControls();
                #end

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;


		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end
		
		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

					
					case "virus":
					
					inCutscene = true;
					
					snapCamFollowToPos(640, 0);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1;

					new FlxTimer().start(0.2, function(tmr:FlxTimer)
						{
							FlxG.sound.play(Paths.sound('virus'));
							
						});

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
					


				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				default:
					startCountdown();
			}
			seenCutscene = true;
		} else {
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);
		
		super.create();
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		return value;
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});
		luaDebugGroup.add(new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					newBoyfriend.alreadyLoaded = false;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					newDad.alreadyLoaded = false;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(!gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					newGf.alreadyLoaded = false;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = SUtil.getPath() + Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		
		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
		#if sys
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);
			#if sys
			if(FileSystem.exists(fileName)) {
			#else
			if(OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;
			}
		}

		if(foundFile) {
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
				if(endingSong) {
					endSong();
				} else {
					startCountdown();
				}
			}
			return;
		} else {
			FlxG.log.warn('Couldnt find video file: ' + fileName);
		}
		#end
		if(endingSong) {
			endSong();
		} else {
			startCountdown();
		}
	}

	var dialogueCount:Int = 0;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			var doof:DialogueBoxPsych = new DialogueBoxPsych(dialogueFile, song);
			doof.scrollFactor.set();
			if(endingSong) {
				doof.finishThing = endSong;
			} else {
				doof.finishThing = startCountdown;
			}
			doof.nextDialogueThing = startNextDialogue;
			doof.skipDialogueThing = skipDialogue;
			doof.cameras = [camHUD];
			add(doof);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownEmoji:FlxSprite;
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
                        #if android
                        androidc.visible = true;
                        #end
			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);

			var swagCounter:Int = 0;

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (tmr.loopsLeft % gfSpeed == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
				{
					gf.dance();
				}
				if(tmr.loopsLeft % 2 == 0) {
					if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing'))
					{
						boyfriend.dance();
					}
					if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					{
						dad.dance();
					}
				}
				else if(dad.danceIdle && dad.animation.curAnim != null && !dad.stunned && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing"))
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['emoji', 'ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);
	
					bottomBoppers.dance(true);
					santa.dance(true);
				}

				if(curStage == 'baladamedo') {
					
					spookers.dance(true);

				}

				if(curStage == 'baladamedovirus') {

					spookers.dance(true);
					
					if (curBeat % 1 == 0)
						{
							barbaravirus.animation.play('danceleft', true);
						}
					
					if (curBeat % 2 == 0)
						{
							barbaravirus.animation.play('danceright', true);
						}

				}

				if(curStage == 'favela') {
					

					danielzinho.dance(true);
					
					if (kleistate == 2)
						{
							if (curBeat % 2 == 0)
							kleitin.animation.play('idle', true);
						}

					if (kleistate == 3)
						{
							if (curBeat % 2 == 0)
							kleitin.animation.play('dance', true);
						}

						if (curBeat % 2 == 0)
							{
							daniel.dance(true);
		
							}

					busao.dance(true);

				}

				if(curStage == 'favelanoite'){
					
					if (kleistate == 2)
						{
							if (curBeat % 2 == 0)
							kleitin.animation.play('idle', true);
						}

					if (kleistate == 3)
						{
							if (curBeat % 2 == 0)
							kleitin.animation.play('dance', true);
						}

					
						pessoas.animation.play('dance', true);
						
						busao.dance(true);

				}

				switch (swagCounter)
				{
					case 0:
						countdownEmoji = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownEmoji.scrollFactor.set();
						countdownEmoji.updateHitbox();

						if (PlayState.isPixelStage)
							countdownEmoji.setGraphicSize(Std.int(countdownEmoji.width * daPixelZoom));

						countdownEmoji.screenCenter();
						countdownEmoji.antialiasing = antialias;
						add(countdownEmoji);
						FlxTween.tween(countdownEmoji, {/*y: countdownEmoji.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownEmoji);
								countdownEmoji.destroy();
							}
						});
						
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[3]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						add(countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if(ClientPrefs.middleScroll && !note.mustPress) {
						note.alpha *= 0.5;
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				if (generatedMusic)
				{
					notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
				}

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		
		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
		
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		
		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(SUtil.getPath() + file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<SwagSection> = Song.loadFromJson('events', songName).notes;
			for (section in eventsData)
			{
				for (songNotes in section.sectionNotes)
				{
					if(songNotes[1] < 0) {
						eventNotes.push([songNotes[0] + ClientPrefs.noteOffset, songNotes[1], songNotes[2], songNotes[3], songNotes[4]]);
						eventPushed(songNotes);
					}
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if(songNotes[1] > -1) { //Real notes
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int = Std.int(songNotes[1] % 4);

					var gottaHitNote:Bool = section.mustHitSection;

					if (songNotes[1] > 3)
					{
						gottaHitNote = !section.mustHitSection;
					}

					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;

					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					swagNote.mustPress = gottaHitNote;
					swagNote.sustainLength = songNotes[2];
					swagNote.noteType = songNotes[3];
					if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
					
					swagNote.scrollFactor.set();

					var susLength:Float = swagNote.sustainLength;

					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);

					var floorSus:Int = Math.floor(susLength);
					if(floorSus > 0) {
						for (susNote in 0...floorSus+1)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							unspawnNotes.push(sustainNote);

							if (sustainNote.mustPress)
							{
								sustainNote.x += FlxG.width / 2; // general offset
							}
							else if(ClientPrefs.middleScroll)
							{
								sustainNote.x += 310;
								if(daNoteData > 1)
								{ //Up and Right
									sustainNote.x += FlxG.width / 2 + 25;
								}
							}
						}
					}

					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else if(ClientPrefs.middleScroll)
					{
						swagNote.x += 310;
						if(daNoteData > 1) //Up and Right
						{
							swagNote.x += FlxG.width / 2 + 25;
						}
					}

					if(!noteTypeMap.exists(swagNote.noteType)) {
						noteTypeMap.set(swagNote.noteType, true);
					}
				} else { //Event Notes
					eventNotes.push([songNotes[0] + ClientPrefs.noteOffset, songNotes[1], songNotes[2], songNotes[3], songNotes[4]]);
					eventPushed(songNotes);
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:Array<Dynamic>) {
		switch(event[2]) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event[3].toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event[3]);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event[4];
				addCharacterToList(newCharacter, charType);
		}

		if(!eventPushedMap.exists(event[2])) {
			eventPushedMap.set(event[2], true);
		}
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event[2]]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event[2]) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		var earlyTime1:Float = eventNoteEarlyTrigger(Obj1);
		var earlyTime2:Float = eventNoteEarlyTrigger(Obj2);
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0] - earlyTime1, Obj2[0] - earlyTime2);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1 && ClientPrefs.middleScroll) targetAlpha = 0.5;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = false;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = false;

			if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = true;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = true;
			
			if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = true;
				}
			}
			
			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		if (angryDad)
			{
				dad.playAnim('throwmic');
			}

		

		if (curStage == 'balada') {
			if (BaladaIsDark == true) //Pode me xingar o quanto quiser, o importante é que funciona
				{
				//claro
				fundo1.alpha = 0;
				chao1.alpha = 0;
				base1.alpha = 0;
				luzes1.alpha = 0;
				curti1.alpha = 0;
				balight.alpha = 1;
				} else
				{
				//escuro
				fundo1.alpha = 1;
				chao1.alpha = 1;
				base1.alpha = 1;
				luzes1.alpha = 1;
				curti1.alpha = 1;
				balight.alpha = 0;
				}
		}

		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{
			case 'schoolEvil':
				if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				
			
				
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if(ratingName == '?') {
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
		} else {
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
		}

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE #if android || FlxG.android.justReleased.BACK #end && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 1 / 1000 chance for Gitaroo Man easter egg
				/*if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					cancelFadeTween();
					CustomFadeTransition.nextCamera = camOther;
					MusicBeatState.switchState(new GitarooPause());
				}
				else {*/
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				PauseSubState.transCamera = camOther;
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				//}
		
				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;
			cancelFadeTween();
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new ChartingState());

			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health > 2)
			health = 2;
		
		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else if (healthBar.percent > 80)
			iconP1.animation.curAnim.curFrame = 2;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else if (healthBar.percent < 20)
			iconP2.animation.curAnim.curFrame = 2;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelFadeTween();
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
					
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		var roundedSpeed:Float = FlxMath.roundDecimal(songSpeed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if(roundedSpeed < 1) time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				// i am so fucking sorry for this if condition
				var strumX:Float = 0;
				var strumY:Float = 0;
				var strumAngle:Float = 0;
				var strumAlpha:Float = 0;
				if(daNote.mustPress) {
					strumX = playerStrums.members[daNote.noteData].x;
					strumY = playerStrums.members[daNote.noteData].y;
					strumAngle = playerStrums.members[daNote.noteData].angle;
					strumAlpha = playerStrums.members[daNote.noteData].alpha;
				} else {
					strumX = opponentStrums.members[daNote.noteData].x;
					strumY = opponentStrums.members[daNote.noteData].y;
					strumAngle = opponentStrums.members[daNote.noteData].angle;
					strumAlpha = opponentStrums.members[daNote.noteData].alpha;
				}

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;
				var center:Float = strumY + Note.swagWidth / 2;

				if(daNote.copyX) {
					daNote.x = strumX;
				}
				if(daNote.copyAngle) {
					daNote.angle = strumAngle;
				}
				if(daNote.copyAlpha) {
					daNote.alpha = strumAlpha;
				}
				if(daNote.copyY) {
					if (ClientPrefs.downScroll) {
						daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
						if (daNote.isSustainNote && !ClientPrefs.keSustains) {
							//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
							if (daNote.animation.curAnim.name.endsWith('end')) {
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
								if(PlayState.isPixelStage) {
									daNote.y += 8;
								} else {
									daNote.y -= 19;
								}
							} 
							daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
							daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (roundedSpeed - 1);

							if(daNote.mustPress || !daNote.ignoreNote)
							{
								if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
									&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}
						}
					} else {
						daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

						if(!ClientPrefs.keSustains)
						{
							if(daNote.mustPress || !daNote.ignoreNote)
							{
								if (daNote.isSustainNote
									&& daNote.y + daNote.offset.y * daNote.scale.y <= center
									&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
									swagRect.y = (center - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;

									daNote.clipRect = swagRect;
								}
							}
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
						goodNoteHit(daNote);
					}
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * songSpeed));

				var doKill:Bool = daNote.y < -daNote.height;
				if(ClientPrefs.downScroll) doKill = daNote.y > FlxG.height;

				if(ClientPrefs.keSustains && daNote.isSustainNote && daNote.wasGoodHit) doKill = true;

				if (doKill)
				{
					if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();

		if (!inCutscene) {
			if(!cpuControlled) {
				keyShit();
			} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
		}
		
		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if(daNote.strumTime + 800 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
				for (i in 0...unspawnNotes.length) {
					var daNote:Note = unspawnNotes[0];
					if(daNote.strumTime + 800 >= Conductor.songPosition) {
						break;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}

				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();

				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				
				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var early:Float = eventNoteEarlyTrigger(eventNotes[0]);
			var leStrumTime:Float = eventNotes[0][0];
			if(Conductor.songPosition < leStrumTime - early) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0][3] != null)
				value1 = eventNotes[0][3];

			var value2:String = '';
			if(eventNotes[0][4] != null)
				value2 = eventNotes[0][4];

			triggerEventNote(eventNotes[0][2], value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value)) value = 1;
				gfSpeed = value;

			case 'Blammed Lights':
				var lightId:Int = Std.parseInt(value1);
				if(Math.isNaN(lightId)) lightId = 0;

				if(lightId > 0 && curLightEvent != lightId) {
					if(lightId > 5) lightId = FlxG.random.int(1, 5, [curLightEvent]);

					var color:Int = 0xffffffff;
					switch(lightId) {
						case 1: //Blue
							color = 0xff31a2fd;
						case 2: //Green
							color = 0xff31fd8c;
						case 3: //Pink
							color = 0xfff794f7;
						case 4: //Red
							color = 0xfff96d63;
						case 5: //Orange
							color = 0xfffba633;
					}
					curLightEvent = lightId;

					if(blammedLightsBlack.alpha == 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 1}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});

						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length) {
							if(chars[i].colorTween != null) {
								chars[i].colorTween.cancel();
							}
							chars[i].colorTween = FlxTween.color(chars[i], 1, FlxColor.WHITE, color, {onComplete: function(twn:FlxTween) {
								chars[i].colorTween = null;
							}, ease: FlxEase.quadInOut});
						}
					} else {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = null;
						blammedLightsBlack.alpha = 1;

						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length) {
							if(chars[i].colorTween != null) {
								chars[i].colorTween.cancel();
							}
							chars[i].colorTween = null;
						}
						dad.color = color;
						boyfriend.color = color;
						gf.color = color;
					}
					
					if(curStage == 'philly') {
						if(phillyCityLightsEvent != null) {
							phillyCityLightsEvent.forEach(function(spr:BGSprite) {
								spr.visible = false;
							});
							phillyCityLightsEvent.members[lightId - 1].visible = true;
							phillyCityLightsEvent.members[lightId - 1].alpha = 1;
						}
					}
				} else {
					if(blammedLightsBlack.alpha != 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 0}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});
					}

					if(curStage == 'philly') {
						phillyCityLights.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});
						phillyCityLightsEvent.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});

						var memb:FlxSprite = phillyCityLightsEvent.members[curLightEvent - 1];
						if(memb != null) {
							memb.visible = true;
							memb.alpha = 1;
							if(phillyCityLightsEventTween != null)
								phillyCityLightsEventTween.cancel();

							phillyCityLightsEventTween = FlxTween.tween(memb, {alpha: 0}, 1, {onComplete: function(twn:FlxTween) {
								phillyCityLightsEventTween = null;
							}, ease: FlxEase.quadInOut});
						}
					}

					var chars:Array<Character> = [boyfriend, gf, dad];
					for (i in 0...chars.length) {
						if(chars[i].colorTween != null) {
							chars[i].colorTween.cancel();
						}
						chars[i].colorTween = FlxTween.color(chars[i], 1, chars[i].color, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
							chars[i].colorTween = null;
						}, ease: FlxEase.quadInOut});
					}

					curLight = 0;
					curLightEvent = 0;
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;
		
						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = Std.parseFloat(split[0].trim());
					var intensity:Float = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							if(!boyfriend.alreadyLoaded) {
								boyfriend.alpha = 1;
								boyfriend.alreadyLoaded = true;
							}
							boyfriend.visible = true;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							dad.visible = false;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf) {
									gf.visible = true;
								}
							} else {
								gf.visible = false;
							}
							if(!dad.alreadyLoaded) {
								dad.alpha = 1;
								dad.alreadyLoaded = true;
							}
							dad.visible = true;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf.curCharacter != value2) {
							if(!gfMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							gf.visible = false;
							gf = gfMap.get(value2);
							gf.visible = true;
							if(!gf.alreadyLoaded) {
								gf.alpha = 1;
								gf.alreadyLoaded = true;
							}
						}
						setOnLuas('gfName', gf.curCharacter);
				}
				reloadHealthBarColors();
			
			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();
			
			case 'Change Scroll Speed':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0];
			camFollow.y += gf.cameraPosition[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0];
			camFollow.y += dad.cameraPosition[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			switch (curStage)
			{
				case 'limo':
					camFollow.x = boyfriend.getMidpoint().x - 300;
				case 'mall':
					camFollow.y = boyfriend.getMidpoint().y - 200;
				case 'school' | 'schoolEvil':
					camFollow.x = boyfriend.getMidpoint().x - 200;
					camFollow.y = boyfriend.getMidpoint().y - 200;
			}
			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 0.8}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 0.7}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}
		
                #if android
                androidc.visible = false;
                #end		
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['tutorial_nomiss','week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'debugger', 'cruzes']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		
		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelFadeTween();
					CustomFadeTransition.nextCamera = camOther;
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff);

		switch (daRating)
		{
			case "shit": // shit
				totalNotesHit += 0;
				shits++;
			case "bad": // bad
				totalNotesHit += 0.5;
				bads++;
			case "good": // good
				totalNotesHit += 0.75;
				goods++;
			case "sick": // sick
				totalNotesHit += 1;
				sicks++;
		}


		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			songHits++;
			totalPlayed++;
			RecalculateRating();

			if(ClientPrefs.scoreZoom)
			{
				if(scoreTxtTween != null) {
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtTween = null;
					}
				});
			}
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		//rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];


		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];


		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			//numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
					{
						if(daNote.noteData == key && !daNote.isSustainNote)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}
							
						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else if (canMiss) {
					noteMissPress(key);
					callOnLuas('noteMissPress', [key]);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}
	
	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];
		
		var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
		if(controlArray.contains(true))
		{
			for (i in 0...controlArray.length)
			{
				if(controlArray[i])
					onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});

			if (controlHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}
		}

		var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
		if(controlArray.contains(true))
		{
			for (i in 0...controlArray.length)
			{
				if(controlArray[i])
					onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;

		health -= daNote.missHealth * healthLoss;
		if(instakillOnMiss)
		{
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;
		
		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if(daNote.noteType == 'GF Sing') {
			char = gf;
		}

		if(char.hasMissAnimations)
		{
			if(daNote.noteType == 'Dodge Note') { 
                if(char.animOffsets.exists('damage') && char.curCharacter.startsWith('bidu')) {
                    char.playAnim('damage', true);
                }
            }

			var daAlt = '';
			if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

			if(daNote.noteType == 'Shoot Note') daAlt = '-shoot';

			if(daNote.noteType != 'Dodge Note') { 
				var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
				char.playAnim(animToPlay, true);
			}
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)//AQUI3
		{
			
			health -= 0.05 * healthLoss;
			
			if(instakillOnMiss)
			{
				doDeathCheck(true);
			}

			if (combo > 5 && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 1;
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if(note.noteType == 'Shoot Note') {
            var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + '-shoot';
                dad.playAnim(animToPlay);
				FlxG.sound.play(Paths.sound('shoot'));
            
        }

		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}

				if (SONG.notes[curSection].altAnim || note.noteType == 'Shoot Note') {
					altAnim = '-shoot';
					FlxG.camera.zoom += 0.005;
					camHUD.zoom += 0.005;
					FlxG.camera.shake(0.01, 0.03);

					
					if (curStage == 'favela' || curStage == 'favelanoite' )
						{
						if (kleistate == 2)
							{
								kleitin.animation.play('susto', true);
							}

						if (kleistate == 3)
							{
								kleitin.animation.play('bala', true);
							}
						}
					

					if (gfmedo == true) {
						gf.playAnim('scared', true);
					}
					//AQUI CARAI
				}

				if (SONG.notes[curSection].altAnim || note.noteType == 'Dodge Note') {
					altAnim = '-dodge';

				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if(SONG.notes[curSection].gfSection || note.noteType == 'GF Sing') {
				char = gf;
			}

			char.playAnim(animToPlay, true);
			char.holdTimer = 0;
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit) //AQUI2
		{
				
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('damage') != null) {
							FlxG.sound.play(Paths.sound('hurtacid'));
							boyfriend.playAnim('damage', true);
							boyfriend.specialAnim = true;
						}

					
						
				}
				
				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';

				if(note.noteType == 'Shoot Note') daAlt = '-shoot';

				if(note.noteType == 'Dodge Note') daAlt = '-dodge';
	
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if(note.noteType == 'GF Sing') {
					gf.playAnim(animToPlay + daAlt, true);
					gf.holdTimer = 0;
				} else {
					boyfriend.playAnim(animToPlay + daAlt, true);
					boyfriend.holdTimer = 0;
				}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

				
	
				}
				
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		
		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
		}

		if (startedMoving)
			{
				phillyTrain.x -= 400;
	
				if (phillyTrain.x < -2000 && !trainFinishing)
				{
					phillyTrain.x = -1150;
					trainCars -= 1;
	
					if (trainCars <= 0)
						trainFinishing = true;
				}
	
				if (phillyTrain.x < -4000 && trainFinishing)
					trainReset();
			}
	}

	function trainReset():Void
	{
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}
		if(gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		super.destroy();
	}

	public function cancelFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
		{
			super.stepHit();
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
				|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
			{
				resyncVocals();
			}

		if(curStep == lastStepHit) {
			return;
		}
		//essa merda de step hit 

		//COISA DA MUSICA

		if (curStep == 1)
			{
				FlxTween.tween(songinfo, {x: 0}, 2.6, {ease: FlxEase.expoOut});
			}
		
		if (curStep == 32)
			{
				FlxTween.tween(songinfo, {x: -500}, 2.6, {
					ease: FlxEase.expoIn,
					onComplete: function(twn:FlxTween)
					{
						songinfo.alpha = 0;
					}
				});
			}

			

		/*
		if (curSong == 'Tutorial') //não funciona P A I N
			{
				if (curStep >= 608 && difficulty == 0)
					{
					vocals.volume = 0;
					}

			}
			*/

		//SALSICHA

		if (curSong == 'Earthquake') //zoom na partezinha legal da música uwu
			{
					
					//transformasao
					 //VAI
					if (curStep == 1248)
						{
							FlxG.sound.play(Paths.sound('salsicha1'));
						}

					 //VOLTA
					if (curStep == 2064)
						{
							FlxG.sound.play(Paths.sound('salsicha2'));
						}


					//FLASH
						//VAI
						if (curStep == 1296)
						{
							FlxG.camera.flash(FlxColor.WHITE, 2);
						}

						//VOLTA
						if (curStep == 2096)
							{
								FlxG.camera.flash(FlxColor.WHITE, 2);
							}
					
					//FIM DOS FRLASH
				
				//vai
				if (curStep == 1840)
					{
						defaultCamZoom = 0.54;
					}
				//volta
				if (curStep == 2088)
					{
						defaultCamZoom = 0.58;
					}

				if (curStep == 2092)
					{
						defaultCamZoom = 0.62;
					}

				if (curStep == 2096)
					{
						defaultCamZoom = 0.48;
					}

					
			}

		//FRESHER
		if (curSong == 'Fresher') 
			{
				if (curStep == 428)
				{
					defaultCamZoom = 0.65;
	
					
					
	
				}
				
				if (curStep == 432)
				{
					defaultCamZoom = 0.70;
	
					
					
	
				}
	
				if (curStep == 448)
				{
					
					defaultCamZoom = 0.57;
				}

				if (curStep == 704)
					{
						
						defaultCamZoom = 0.70;
					}

					if (curStep == 892)
						{
							
							defaultCamZoom = 0.57;
						}


	
			}
			if (curSong == 'Reboop') 
			{
			//hey
				/*
					//Descartado, mas vou deixar aqui mesmo assim caso alguém encontre
					//COLOQUEI NA PSYCH ENGINE UOOOOOOO
	
						if (curStep == 128)
							{
							boyfriend.playAnim('hey', true);
							}	
						if (curStep == 256)
							{
							boyfriend.playAnim('hey', true);
							}	
						if (curStep == 324)
							{
							boyfriend.playAnim('hey', true);
							}
						if (curStep == 388)
							{
							boyfriend.playAnim('hey', true);
							}
						if (curStep == 512)
							{
							boyfriend.playAnim('hey', true);
							}
						if (curStep == 640)
							{
							boyfriend.playAnim('hey', true);
							}
						if (curStep == 772)
							{
							boyfriend.playAnim('hey', true);
							}
						if (curStep == 896)
							{
							boyfriend.playAnim('hey', true);
							gf.playAnim('cheer', true);
							}
					*/
	
			//zoom
							if (curStep == 128)
							{
							defaultCamZoom = 0.6;
							}
							//z1
							if (curStep == 184)
							{
							defaultCamZoom = 0.65;
							}
							//z2
							if (curStep == 186)
							{
							defaultCamZoom = 0.7;
							}
							//z3
							if (curStep == 190)
							{
							defaultCamZoom = 0.75;
							}
							//volta1
							if (curStep == 192)
							{
							defaultCamZoom = 0.6;
							}
							//z1 
							if (curStep == 248)
							{
							defaultCamZoom = 0.65;
							}
							//z2
							if (curStep == 250)
							{
							defaultCamZoom = 0.7;
							}
							//z3
							if (curStep == 254)
							{
							defaultCamZoom = 0.75;
							}
							//volta2
							if (curStep == 256)
							{
							defaultCamZoom = 0.6;
							}
							
							if (curStep == 568)
							{
							defaultCamZoom = 0.65;
							}
	
							if (curStep == 570)
							{
							defaultCamZoom = 0.7;
							}
	
							if (curStep == 573)
							{
							defaultCamZoom = 0.75;
							}
	
							if (curStep == 576)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 632)
							{
							defaultCamZoom = 0.65;
							}
	
							if (curStep == 633)
							{
							defaultCamZoom = 0.7;
							}
	
							if (curStep == 637)
							{
							defaultCamZoom = 0.75;
							}
	
							if (curStep == 640)
							{
							defaultCamZoom = 0.6;
							}
	
			}
			if (curSong == 'Fresher') //de novo porra? vsf 
			{
				if (curStep == 704)
					{
					defaultCamZoom = 0.65;
					}


				if (curStep == 832)
					{
					defaultCamZoom = 0.57;
					}
			}
			if (curSong == 'Rap-King') 
			{
	
						//FINAL ANIMATION LOOOL
					if (health >= 1)
						{
							if (curBeat == 728)
								{
	
									angryDad = true;
	
								}
	
							if (curStep == 2914)
								{
			
									FlxG.sound.play(Paths.sound('micthrow'));
			
								}
	
							if (curBeat == 729)
								{
			
									angryDad = false;
									
			
								}
								if (curBeat > 729)
									{
				
										dad.playAnim('micend');
				
									}
						}
				//animation test
					//
			//zoom
				//inicio 
	
					
	
							if (curStep == 32)
							{
							defaultCamZoom = 0.6;
							
							}
	
							if (curStep == 48)
							{
							defaultCamZoom = 0.62;
							
							}
	
							if (curStep == 64)
							{
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 96)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 112)
							{
							defaultCamZoom = 0.62;
							}
	
							if (curStep == 128)
							{
							
							defaultCamZoom = 0.57;
							}
	
					//Voz começa aqui uwu
	
							if (curStep == 640)
							{
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 672)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 688)
							{
							defaultCamZoom = 0.63;
							}
	
							if (curStep == 688)
							{
							defaultCamZoom = 0.64;
							}
	
							if (curStep == 692)
							{
							
							defaultCamZoom = 0.65;
							}
	
							if (curStep == 698)
							{
							defaultCamZoom = 0.7;
							}
	
							if (curStep == 700)
							{
							defaultCamZoom = 0.75;
							}
	
							if (curStep == 704)
							{
						
							defaultCamZoom = 0.7;
							}
				//parte meio 1
							if (curStep == 960)
							{
							FlxG.camera.flash(FlxColor.WHITE, 1.5);
							BaladaIsDark = true;
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 1088)
							{
							defaultCamZoom = 0.58;
							}
	
							if (curStep == 1104)
							{
							defaultCamZoom = 0.62;
							}
	
							if (curStep == 1120)
							{
							defaultCamZoom = 0.66;
							}
	
							if (curStep == 1136)
							{
							defaultCamZoom = 0.60;
							}
	
							if (curStep == 1144)
							{
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 1152)
							{
							defaultCamZoom = 0.59;
							}
	
							if (curStep == 1168)
							{
							defaultCamZoom = 0.62;
							}
	
							if (curStep == 1184)
							{
							defaultCamZoom = 0.65;
							}
	
							if (curStep == 1200)
							{
							defaultCamZoom = 0.7;
							}
	
							if (curStep == 1204)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 1208)
							{
							defaultCamZoom = 0.8;
							}
	
							if (curStep == 1212)
							{
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 1216)
							{
							FlxG.camera.flash(FlxColor.WHITE, 1.5);
							BaladaIsDark = false;
							defaultCamZoom = 0.65;
							}
	
							if (curStep == 1344)
							{
							defaultCamZoom = 0.68;
							}
	
							if (curStep == 1408)
							{
							defaultCamZoom = 0.72;
							}
	
							if (curStep == 1464)
							{
							defaultCamZoom = 0.78;
							}
	
							if (curStep == 1472)
							{
							FlxG.camera.flash(FlxColor.BLACK, 1.5);
							BaladaIsDark = true;
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 1600)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 1728)
							{
							FlxG.camera.flash(FlxColor.WHITE, 1.5);
							BaladaIsDark = false;
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 1856)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 1968)
							{
							defaultCamZoom = 0.65;
							}
	
							if (curStep == 1976)
							{
							defaultCamZoom = 0.7;
							}
	
							if (curStep == 1980)
							{
							defaultCamZoom = 0.75;
							}
	
							if (curStep == 1984)
							{
							FlxG.camera.flash(FlxColor.WHITE, 1.5);
							BaladaIsDark = true;
							defaultCamZoom = 0.6;
							}
	
					//pitch mudou slk
	
							if (curStep == 2112)
							{
							FlxG.camera.flash(FlxColor.WHITE, 1.5);
							BaladaIsDark = false;
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 2128)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 2144)
							{
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 2160)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 2176)
							{
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 2192)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 2208)
							{
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 2224)
							{
							defaultCamZoom = 0.6;
							}
	
					//ah shit here we go again
							if (curStep == 2240)
							{
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 2256)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 2272)
							{
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 2288)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 2304)
							{
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 2320)
							{
							defaultCamZoom = 0.6;
							}
	
							if (curStep == 2336)
							{
							defaultCamZoom = 0.57;
							}
	
							if (curStep == 2352)
							{
							defaultCamZoom = 0.6;
							}
	
					//acabou graças a deus
	
							if (curStep == 2368)
							{
							
							defaultCamZoom = 0.57;
							}
			}
			if (curSong == 'Bittersweet') 
			{	
	
				if (curStep == 256)
					{
						FlxTween.tween(dancef, {alpha:1}, 2.4, {ease: FlxEase.expoOut});
					
					}
				
							if (curStep == 668)
							{
							defaultCamZoom = 0.75;
							
							}
	
							if (curStep == 672)
							{
							defaultCamZoom = 0.63;
							}
	
							if (curStep == 732)
							{
							defaultCamZoom = 0.75;
							
							}
	
							if (curStep == 736)
							{
							defaultCamZoom = 0.63;
							}
	
						//zooms e gf mexendo 
	
							if (curStep == 1)
							{
							defaultCamZoom = 0.7;
							
							}
	
							if (curStep == 256)
							{
							defaultCamZoom = 0.63;
							spookersvel = 1;
							
							}
	
								if (curStep == 1024)
									{
										spookersvel = 2;
									
									}

								if (curStep == 1040)
									{
										spookersvel = 1;
									
									}

							if (curStep == 1056)
							{
							defaultCamZoom = 0.7;
							spookersvel = 2;
							
							
							}
	
							if (curStep == 1296)
							{
							defaultCamZoom = 0.8;
							spookersvel = 1;
							
							}
	
							if (curStep == 1300)
							{
							defaultCamZoom = 0.7;
							
							}
	
							if (curStep == 1304)
							{
							defaultCamZoom = 0.8;
							
							}
	
							if (curStep == 1308)
							{
							defaultCamZoom = 0.7;
							
							}
	
							if (curStep == 1312)
							{
							defaultCamZoom = 0.63;
							
							
							}
	
							if (curStep == 2080)
							{
							defaultCamZoom = 0.66;
							
							}
	
							if (curStep == 2084)
							{
							defaultCamZoom = 0.7;
							
							}

							if (curStep == 336)
								{
								spookersvel = 2;
								
								}
						
	
			}
			if (curSong == 'Nightfall') 
				{	
					//começo 1 

					if (curStep == 1)
						{
							FlxTween.tween(dancef, {alpha:1}, 2.4, {ease: FlxEase.expoOut});
						
						}

					if (curStep == 640)
						{
						defaultCamZoom = 0.60;
						spookersvel = 1;
						dancefvel = 3;
						
						}

					if (curStep == 880)
						{
						defaultCamZoom = 0.65;
						dancefvel = 2;
						}
					if (curStep == 888)
						{
						defaultCamZoom = 0.70;

						}

					if (curStep == 896)
						{
						defaultCamZoom = 0.75;
						dancefvel = 1;

						}
					//cabo 1 (lento)
					if (curStep == 1152)
						{
						defaultCamZoom = 0.56;
						spookersvel = 2;
						dancefvel = 2;
						
						}

					//começo 2
					if (curStep == 1664)
						{
						defaultCamZoom = 0.65;
						spookersvel = 1;
						dancefvel = 3;
						
						}

					if (curStep == 1920)
						{
						defaultCamZoom = 0.75;
						dancefvel = 1;
						
						
						}

					if (curStep == 2176)
						{
						defaultCamZoom = 0.65;
						dancefvel = 2;
						
						}

					if (curStep == 2432)
						{
						defaultCamZoom = 0.75;
						dancefvel = 1;
						
						
						}

					if (curStep == 2688)
						{
						defaultCamZoom = 0.56;
						spookersvel = 2;
						dancefvel = 3;
						
						//falouu
						FlxTween.tween(dancef, {alpha:0}, 3.4, {ease: FlxEase.expoIn});

						}


				}
			if (curSong == 'Virus') 
				{	

					if (curStep == 512)
						{
							defaultCamZoom = 0.65;
						}
	
					if (curStep == 576)
						{
							defaultCamZoom = 0.7;
						}
	
					if (curStep == 624)
						{
							defaultCamZoom = 0.75;
						}
	
					if (curStep == 512)
						{
							defaultCamZoom = 0.65;
						}
	
					if (curStep == 704)
						{
							defaultCamZoom = 0.7;
						}
				
					if (curStep == 752)
						{
							defaultCamZoom = 0.75;
						}
						//metade
					if (curStep == 768)
						{
							defaultCamZoom = 0.63;
						}
	
					if (curStep == 1024)
						{
							defaultCamZoom = 0.7;
						}
	
					if (curStep == 1152)
						{
							defaultCamZoom = 0.65;
						}
	
					if (curStep == 1392)
						{
							defaultCamZoom = 0.7;
						}
	
					if (curStep == 1408)
						{
							defaultCamZoom = 0.65;
						}
	
					if (curStep == 1520)
						{
							defaultCamZoom = 0.7;
						}
	
					if (curStep == 1536)
						{
							defaultCamZoom = 0.63;
						}
					//final
	
					if (curStep == 1552)
						{
							defaultCamZoom = 0.68;
						}
							
				
					if (curStep == 1556)
					{
						defaultCamZoom = 0.72;
					}
					
					
				}

				if (curSong == 'Shacklesz')
					{
						
						if (curStep == 128)
							{
								defaultCamZoom = 0.85;
							}

						if (curStep == 384)
							{
								defaultCamZoom = 0.8;
							}

						if (curStep == 636)
							{
								defaultCamZoom = 0.7;
							}

							if (curStep == 640)
								{
									defaultCamZoom = 0.75;
								}
						
						if (curStep == 896)
							{
								defaultCamZoom = 0.8;
							}


							if (curStep == 1018)
								{
									defaultCamZoom = 0.85;
								}

								if (curStep == 1024)
									{
										defaultCamZoom = 0.8;
									}

						if (curStep > 1135 && curStep < 1150)
							{
								defaultCamZoom -= 0.005;
							}

							if (curStep == 1400)
								{
									defaultCamZoom = 0.82;
								}

								if (curStep == 1404)
									{
										defaultCamZoom = 0.78;
									}
						//fin LOL
						if (curStep == 1408)
							{
								defaultCamZoom = 0.75;
							}

							if (curStep == 1476)
								{
									defaultCamZoom = 0.8;
								}
								if (curStep == 1536)
									{
										defaultCamZoom = 0.75;
									}

						//zooms sus
						if (curStep == 832)
							{
								defaultCamZoom = 0.8;
							}

							if (curStep == 898)
								{
									defaultCamZoom = 0.7;
								}

							if (curStep == 928)
								{
									defaultCamZoom = 0.85;
								}
								if (curStep == 960)
									{
										defaultCamZoom = 0.8;
									}
							if (curStep == 992)
								{
									defaultCamZoom = 0.85;
								}
								if (curStep == 1050)
									{
										defaultCamZoom = 0.88;
									}

								if (curStep == 1050)
									{
										defaultCamZoom = 0.85;
									}

									if (curStep == 1082)
										{
											defaultCamZoom = 0.9;
										}
										if (curStep == 1088)
											{
												defaultCamZoom = 0.8;
											}

								//sus
								if (curStep == 1272)
									{
										defaultCamZoom = 0.78;
									}
									if (curStep == 1280)
										{
											defaultCamZoom = 0.85;
										}
						//fim dos suus
						}

					if (curStage == 'favela' || curStage == 'favelanoite')
						{
							if (kleistate == 1) 
								{
		
									kleitin.animation.play('walk', false);
									
								}
						}
			if (curSong == 'Blam')
				{
					// aud

					if (curStep == 2488)
						{
							FlxG.sound.play(Paths.sound('oops'));
						
						}

						if (curStep == 2492)
							{
								FlxG.sound.play(Paths.sound('oops'));
							
							}

					//KLEITIN EVENT wip

					if (curStep == 16) //fiz isso pra saporra nao trava na hora das notinha //(spoiler: NÃO FUNCIONOU)
						{
							kleistate = 1;
							FlxTween.tween(kleitin, {x: 2600}, 3.8, {ease: FlxEase.quartOut});
						
						}

					if (curStep == 752) //752
						{
							
							FlxTween.tween(kleitin, {x: 1080}, 3.8, {
								startDelay: 0.1,
								ease: FlxEase.linear,
								onComplete: function(twn:FlxTween)
								{
			
									kleitin.animation.play('stop', true);
									kleistate = 2;
								
								}
							});

						}

						if (curStep == 1904) //sentou
							{
								defaultCamZoom = 0.82;
								kleistate = 3;
							}

					//DANIEL EVENT
					if (curStep == 1016) //1116
						{
							FlxTween.tween(carrofoda, {x:-600}, 2, {ease: FlxEase.quartOut});
						}

					if (curStep == 1116) //1116
						{
							FlxTween.tween(danielzinho, {x:-1020}, 8, {ease: FlxEase.linear});
						}


						//nasceu
						if (curStep == 1424) //1232
							{
								FlxTween.tween(daniel, {x:-540}, 1.4, {ease: FlxEase.sineOut});
							}

					//fim do daniel event pq eu quero
					//BUSAO
					if (curStep == 1865) 
						{
							busao.y = -45;
							FlxTween.tween(busao, {x:230}, 6, {ease: FlxEase.quartOut}); //BUSAO EVENT
							FlxTween.tween(busao, {y:-40}, 6, {ease: FlxEase.bounceInOut});
						}
					//ok
					//nao funciona por motivos de (num sei porra)
					if (curStep == 16)
						{
							defaultCamZoom = 0.7;
						}
						if (curStep == 32)
							{
								defaultCamZoom = 0.72;
							}
							if (curStep == 48)
								{
									defaultCamZoom = 0.74;
								}
								if (curStep == 64)
									{
										defaultCamZoom = 0.76;
									}
									if (curStep == 80)
										{
											defaultCamZoom = 0.78;
										}
										if (curStep == 96)
											{
												defaultCamZoom = 0.8;
											}
											if (curStep == 112)
												{
													defaultCamZoom = 0.82;
												}
												if (curStep == 116)
													{
														defaultCamZoom = 0.84;
													}
													if (curStep == 120)
														{
															defaultCamZoom = 0.86;
														}
														if (curStep == 124)
															{
																defaultCamZoom = 0.88;
															}
						//zoofim
						
					if (curStep == 128)
						{
							defaultCamZoom = 0.7;
						}

						if (curStep == 386)
							{
								defaultCamZoom = 0.75;
							}

							if (curStep == 512)
								{
									defaultCamZoom = 0.8;
								}
								if (curStep == 624)
									{
										defaultCamZoom = 0.85;
									}
									if (curStep == 628)
										{
											defaultCamZoom = 0.9;
										}
										if (curStep == 632)
											{
												defaultCamZoom = 0.95;
											}
											if (curStep == 636)
												{
													defaultCamZoom = 1;
												}
												
				//TIRO
				if (curStep == 640)
					{
						defaultCamZoom = 0.7;
					}
					//ativa a barbara com medinho de bala uiui 
					if (curStep == 656)
						{
							gfmedo = true;
						}
				//continua
				if (curStep == 766)
					{
						defaultCamZoom = 0.75;
					}
					if (curStep == 768)
						{
							defaultCamZoom = 0.8;
						}

				if (curStep == 1024)
					{
						defaultCamZoom = 0.7;
					}

				if (curStep == 1152)
					{
						defaultCamZoom = 0.75;
					}

				if (curStep == 1280)
					{
						defaultCamZoom = 0.8;
					}
				//z
				if (curStep == 1380)
					{
						defaultCamZoom = 0.9;
					}
					if (curStep == 1382)
						{
							defaultCamZoom = 0.8;
						}
				
				if (curStep == 1396)
					{
						defaultCamZoom = 0.9;
					}
					if (curStep == 1398)
						{
							defaultCamZoom = 0.8;
						}

				
				if (curStep == 1506)
					{
						defaultCamZoom = 0.9;
					}
					if (curStep == 1510)
						{
							defaultCamZoom = 0.8;
						}
				
				if (curStep == 1522)
					{
						defaultCamZoom = 0.9;
					}
					if (curStep == 1526)
						{
							defaultCamZoom = 0.8;
						}
						if (curStep == 1536)
							{
								defaultCamZoom = 0.75;
							}
				if (curStep == 1664)
					{
						defaultCamZoom = 0.7;
					}
					if (curStep == 1712)
						{
							defaultCamZoom = 0.75;
						}
						if (curStep == 1728)
							{
								defaultCamZoom = 0.7;
							}
				if (curStep == 1776)
					{
						defaultCamZoom = 0.8;
					}
					if (curStep == 1792)
						{
							defaultCamZoom = 0.7;
						}
						if (curStep == 1824)
							{
								defaultCamZoom = 0.75;
							}
							if (curStep == 1856)
								{
									defaultCamZoom = 0.7;
								}
				if (curStep == 1920)
					{
						defaultCamZoom = 0.8;
					}
					if (curStep >= 2008 && curStep < 2016)
						{
							defaultCamZoom -= 0.002;
						}
				if (curStep == 2016)
					{
						defaultCamZoom = 0.7;
					}
					if (curStep == 2048)
						{
							defaultCamZoom = 0.75;
						}
						if (curStep == 2176)
							{
								defaultCamZoom = 0.8;
							}
							if (curStep == 2304)
								{
									defaultCamZoom = 0.85;
								}

				if (curStep == 2432)
					{
						defaultCamZoom = 0.75;
					}
					if (curStep == 2486)
						{
							defaultCamZoom = 0.85;
						}
						if (curStep == 2496)
							{
								defaultCamZoom = 0.75;
							}
							if (curStep == 2688)
								{
									defaultCamZoom = 0.7;
								}
				}
			if (curSong == 'Loaded')
				{
					if (curStep == 128)
						{
							defaultCamZoom = 0.9;
						}

							if (curStep == 144)
								{
									defaultCamZoom = 0.8;
								}

						if (curStep == 148)
							{
								defaultCamZoom = 0.85;
							}

								if (curStep == 150)
									{
										defaultCamZoom = 0.7;
									}

							if (curStep == 154)
								{
									defaultCamZoom = 0.75;
								}

								if (curStep == 156)
									{
										defaultCamZoom = 0.7;
									}

						if (curStep == 156)
							{
								defaultCamZoom = 0.8;
							}

						if (curStep == 184)
							{
								defaultCamZoom = 0.85;
							}
							//dnv
							if (curStep == 192)
								{
									defaultCamZoom = 0.9;
								}
		
									if (curStep == 208)
										{
											defaultCamZoom = 0.8;
										}
		
								if (curStep == 212)
									{
										defaultCamZoom = 0.85;
									}
		
										if (curStep == 214)
											{
												defaultCamZoom = 0.7;
											}
		
									if (curStep == 218)
										{
											defaultCamZoom = 0.75;
										}
		
										if (curStep == 220)
											{
												defaultCamZoom = 0.7;
											}
		
								if (curStep == 224)
									{
										defaultCamZoom = 0.8;
									}
		
								if (curStep == 248)
									{
										defaultCamZoom = 0.85;
									}
									//fim do inicio (???)
					if (curStep == 288)
						{
							defaultCamZoom = 0.9;
						}
						if (curStep == 312)
							{
								defaultCamZoom = 0.95;
							}
					if (curStep == 320)
						{
							defaultCamZoom = 0.9;
						}
						if (curStep == 354)
							{
								defaultCamZoom = 0.95;
							}
							if (curStep == 368)
								{
									defaultCamZoom = 0.9;
								}
								if (curStep == 374)
									{
										defaultCamZoom = 0.95;
									}
							if (curStep == 380)
								{
									defaultCamZoom = 0.8;
								}
						if (curStep == 384)
							{
								defaultCamZoom = 0.75;
							}
							if (curStep == 512)
								{
									defaultCamZoom = 0.77;
								}
								if (curStep == 576)
									{
										defaultCamZoom = 0.72;
									}
					if (curStep == 640)
						{
							defaultCamZoom = 0.95;
						}
						if (curStep == 696)
							{
								defaultCamZoom = 0.9;
							}
					if (curStep == 704)
						{
							defaultCamZoom = 0.95;
						}
						if (curStep == 766)
							{
								defaultCamZoom = 0.9;
							}
					if (curStep == 768)
						{
							defaultCamZoom = 0.95;
						}
						if (curStep == 820)
							{
								defaultCamZoom = 1;
							}
							if (curStep == 824)
								{
									defaultCamZoom = 1.05;
								}
								if (curStep == 828)
									{
										defaultCamZoom = 1.10;
									}
					if (curStep == 832)
						{
							defaultCamZoom = 0.9;
						}
					if (curStep == 864)
						{
							defaultCamZoom = 0.95;
						}
						if (curStep ==  884)
							{
								defaultCamZoom = 1;
							}
							if (curStep == 888) 
								{
									defaultCamZoom = 1.05;
								}
								if (curStep == 892)
									{
										defaultCamZoom = 1.10;
									}
				if (curStep == 896)
					{
						defaultCamZoom = 0.9;
					}
					if (curStep == 1024)
						{
							defaultCamZoom = 0.95;
						}
						if (curStep == 1088)
							{
								defaultCamZoom = 1;
							}
					if (curStep == 1152)
						{
							defaultCamZoom = 0.85;
						}
						if (curStep == 1280)
							{
								defaultCamZoom = 0.9;
							}
							if (curStep == 1344)
								{
									defaultCamZoom = 0.95;
								}
								if (curStep == 1376)
									{
										defaultCamZoom = 1;
									}
									if (curStep == 1400)
										{
											defaultCamZoom = 1.05;
										}
					if (curStep == 1408)
						{
							defaultCamZoom = 0.85;
						}
						if (curStep == 1568)
							{
								defaultCamZoom = 0.95;
							}
							if (curStep == 1588)
								{
									defaultCamZoom = 0.9;
								}
								if (curStep == 1592)
									{
										defaultCamZoom = 0.85;
									}
									if (curStep == 1596)
										{
											defaultCamZoom = 0.8;
										}

							if (curStep == 1600)
								{
									defaultCamZoom = 0.85;
								}
						if (curStep == 1632)
							{
								defaultCamZoom = 0.95;
							}
							if (curStep == 1652)
								{
									defaultCamZoom = 0.9;
								}
								if (curStep == 1656)
									{
										defaultCamZoom = 0.85;
									}
									if (curStep == 1660)
										{
											defaultCamZoom = 0.8;
										}
										if (curStep == 1664)
											{
												defaultCamZoom = 0.75;
											}
				}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			setOnLuas('gfSection', SONG.notes[Math.floor(curStep / 16)].gfSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		//icones
		if (curBeat % 1 == 0)
			{
				
				iconP1.scale.set(0.9, 0.9);
				iconP2.scale.set(1.1, 1.1);
			}
		
		if (curBeat % 2 == 0)
			{
				iconP1.scale.set(1.1, 1.1);
				iconP2.scale.set(0.9, 0.9);
			}
			
	

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
		{
			gf.dance();
		}

		if(curBeat % 2 == 0) {
			if (boyfriend.animation.curAnim.name != null && !boyfriend.animation.curAnim.name.startsWith("sing"))
			{
				boyfriend.dance();
			}
			if (dad.animation.curAnim.name != null && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned)
			{
				dad.dance();
			}
		} else if(dad.danceIdle && dad.animation.curAnim.name != null && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned) {
			dad.dance();
		}

		switch (curStage)
		{
			case 'school':
				if(!ClientPrefs.lowQuality) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality) {
					upperBoppers.dance(true);
				}

				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);

			case 'baladamedo':
			
			if (dancefvel == 1) {

				dancef.animation.play('floor' + ((curBeat % 5) + 1));

			}
			else if (dancefvel == 3){

				dancef.animation.play('floor' + ((Math.floor(curBeat / 4) % 5) + 1));
					
			}
			else {

				dancef.animation.play('floor' + ((Math.floor(curBeat / 2) % 5) + 1));
					
			}


			if (spookersvel == 1) {

				if (curBeat % 1 == 0)
					{
						spookers.dance(true);
					}

			}
			else {

				if (curBeat % 2 == 0)
					{
						spookers.dance(true);
					}
					
			}

			case 'baladamedovirus':
			
				if (dancefvel == 1) {

					dancef.animation.play('floor' + ((curBeat % 5) + 1));
	
				}
				else if (dancefvel == 3){
	
					dancef.animation.play('floor' + ((Math.floor(curBeat / 4) % 5) + 1));
						
				}
				else {
	
					dancef.animation.play('floor' + ((Math.floor(curBeat / 2) % 5) + 1));
						
				}
	
	
				if (spookersvel == 1) {
	
					if (curBeat % 1 == 0)
						{
							spookers.dance(true);
						}
	
				}
				else {
	
					if (curBeat % 2 == 0)
						{
							spookers.dance(true);
						}
						
				}

				if (curBeat % 1 == 0)
					{
						barbaravirus.animation.play('danceleft', true);
					}
				
				if (curBeat % 2 == 0)
					{
						barbaravirus.animation.play('danceright', true);
					}
				
			case 'favela':

					danielzinho.dance(true);
					if (kleistate == 2)
						{
							if (curBeat % 2 == 0)
							kleitin.animation.play('idle', true);
						}

					if (kleistate == 3)
						{
							if (curBeat % 2 == 0)
							kleitin.animation.play('dance', true);
						}

					if (curBeat % 2 == 0)
					{
					daniel.dance(true);

					}

					busao.dance(true);
			

			case 'favelanoite':

				
				if (kleistate == 2)
					{
						if (curBeat % 2 == 0)
						kleitin.animation.play('idle', true);
					}

				if (kleistate == 3)
					{
						if (curBeat % 2 == 0)
						kleitin.animation.play('dance', true);
					}

					pessoas.animation.play('dance', true);
					
					
					busao.dance(true);

					if (curBeat % 2 == 0)
						{
						daniel.dance(true);
	
						}

			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:BGSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1, [curLight]);

					phillyCityLights.members[curLight].visible = true;
					phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}

			
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
		lastBeatHit = curBeat;

		callOnLuas('onBeatHit', []);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != FunkinLua.Function_Continue) {
				returnVal = ret;
			}
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String>):String {
		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'tutorial_nomiss' | 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'tutorial':
									if(achievementName == 'tutorial_nomiss') unlock = true;
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 20 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !ClientPrefs.imagesPersist) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == '-debug' && CoolUtil.difficultyString() == 'HARD' && songMisses < 1 && !changedDifficulty && !usedPractice){
							unlock = true;
						}
					case 'cruzes':
						if(Paths.formatToSongPath(SONG.song) == 'earthquake' && CoolUtil.difficultyString() == 'HARD' && songMisses < 1 && !changedDifficulty && !usedPractice){
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}