package;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class HUD extends FlxSpriteGroup {
    public var timeTxt:FlxText;
    public var timeBar:FlxBar;
    public var timeBarBG:AttachedSprite.NGAttachedSprite;
    public var healthBarBG:AttachedSprite.NGAttachedSprite;
    public var healthBar:HealthBar;
    private var curHealth:Float = 1;
    private var curSongPercent:Float = 0;
    public var ratingsTxt:FlxText;
    private var curRatings:Map<String, Int> = [];
    public var songCard:FlxSprite;
    public var mirrorSongCard:FlxSprite;
    public var noGhostTapping:FlxText;
    public var noBotplay:FlxText;
    public var songCreditsTxt:FlxText;
    public var remixCreditsTxt:FlxText;
    public var songNameTxt:FlxText;
    public var botplayTxt:FlxText;
    public var botplaySine:Float = 0;
    public var scoreTxtBg:FlxSprite;
    public var accuracyBg:FlxSprite;
    public var scoreTxt:FlxText;
    public var leftTxt:FlxText;
    public var rightTxt:FlxText;
    public var accuracyTxt:FlxText;
    private var timeTxtTween:FlxTween;
	private var scoreTxtTween:FlxTween;
	private var leftTxtTween:FlxTween;
	private var rightTxtTween:FlxTween;
    private var cardTweenTo:Float = -601;
	final showTime:Bool = (ClientPrefs.settings.get("timeBarType") != 'Disabled');
	final showJustTimeText:Bool = (cast (ClientPrefs.settings.get("timeBarType"), String)).contains('(No Bar)'); //worst syntax ever written

    public function new()
    {
        super();

        //timebar shit
		timeTxt = new FlxText(PlayState.STRUM_X + (FlxG.width / 2) - 248, ClientPrefs.settings.get("downScroll") ? FlxG.height - 44 : 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0.001;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		timeTxt.active = false;
	
		if(ClientPrefs.settings.get("timeBarType") == 'Song Name')
			timeTxt.text = PlayState.SONG.header.song;
		timeBarBG = new AttachedSprite.NGAttachedSprite(400, 20, FlxColor.BLACK);
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0.001;
		timeBarBG.visible = showTime;
		if (timeBarBG.visible == true && showJustTimeText)
			timeBarBG.visible = false;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);
	
		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'curSongPercent', 0, 1);
		timeBar.scrollFactor.set();
		var color:FlxColor;
		var blockyness:Int = 1;
		if(PlayState.isPixelStage) blockyness = 5;
		try {
			timeBar.createGradientBar([0xFF0a0a0a], [color = FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0].red, PlayState.instance.dad.healthColorArray[0].green, PlayState.instance.dad.healthColorArray[0].blue), FlxColor.subtract(color, 0x00333333)], blockyness, 90);
		} catch(e) {
			timeBar.createGradientBar([0xFF0a0a0a], [color = FlxColor.fromRGB(255,255,255), FlxColor.subtract(color, 0x00333333)], blockyness, 90);
			FlxG.log.add('Error: ' + e + ' at HUD.hx (78-80)');
		}
		if (ClientPrefs.settings.get("lowQuality") || PlayState.isPixelStage)
			timeBar.numDivisions = Std.int((timeBar.width)/4);
		else
			timeBar.numDivisions = Std.int(timeBar.width); //what if it was 1280 :flushed:
		timeBar.alpha = 0.001;
		timeBar.visible = showTime;
		if (timeBar.visible == true && showJustTimeText)
			timeBar.visible = false;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;
	
		var type:String = cast (ClientPrefs.settings.get("timeBarType"), String);
		switch (type.toLowerCase().replace(' ', '').trim()) {
			case 'songname':
				timeTxt.size = 24;
				timeTxt.y += 3;
			case 'timeleft(nobar)' | 'timeelapsed(nobar)':
				timeTxt.size = 40;
				timeTxt.y -= 6;
		}

        //healthbar shit
		healthBarBG = new AttachedSprite.NGAttachedSprite(601, 20, FlxColor.BLACK);
		healthBarBG.y = (ClientPrefs.settings.get("downScroll") ? 0.11 * FlxG.height : FlxG.height * 0.89) + ClientPrefs.comboOffset[4];
		healthBarBG.y += ClientPrefs.settings.get("downScroll") ? 20 : -20;
		healthBarBG.x = FlxG.width/4 + ClientPrefs.comboOffset[5];
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.settings.get("hideHud");
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);

		healthBar = new HealthBar(healthBarBG.x + 4, healthBarBG.y + 10, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), 12, this,
			'curHealth', 0, PlayState.instance.maxHealth);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.settings.get("hideHud");
		healthBar.numDivisions = (ClientPrefs.settings.get("lowQuality") ? Std.int((healthBar.width)/4) : Std.int(healthBar.width));
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

        //rating display shit
		if (ClientPrefs.settings.get("ratingsDisplay")) {
			ratingsTxt = new FlxText(12, (FlxG.height/2)-84, 0, '');
			ratingsTxt.scrollFactor.set();
			ratingsTxt.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ratingsTxt.active = false;
			add(ratingsTxt);
            updateRatings();
		}

        //watermark shit
		if (ClientPrefs.settings.get("watermarks"))
		{
			var pixelShit:String = PlayState.isPixelStage ? 'pixelUI/' : '';
			var scale:Float = PlayState.isPixelStage ? 6 : 1;
			var cardName = 'songCard';
			switch(PlayState.SONG.header.song.toLowerCase()) {
				case 'senpai' | 'roses':
					cardName = 'senpaiCard';
			}
			songCard = new FlxSprite(0, ClientPrefs.settings.get("downScroll") ? 134 : FlxG.height - 264).loadGraphic(Paths.image(pixelShit + cardName));
			songCard.scrollFactor.set();
			if(cardName == 'songCard')
				songCard.color = FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0].red, PlayState.instance.dad.healthColorArray[0].green, PlayState.instance.dad.healthColorArray[0].blue);
			songCard.scale.set(scale,scale);
			songCard.updateHitbox();
			songCard.x = -songCard.width;
			songCard.antialiasing = false;
			songCard.active = false;
			add(songCard);

			mirrorSongCard = new FlxSprite(songCard.x, songCard.y).loadGraphic(Paths.image(pixelShit + cardName));
			mirrorSongCard.scrollFactor.set();
			if(cardName == 'songCard')
				mirrorSongCard.color = FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0].red, PlayState.instance.dad.healthColorArray[0].green, PlayState.instance.dad.healthColorArray[0].blue);
			mirrorSongCard.flipX = true;
			mirrorSongCard.scale.set(scale,scale);
			mirrorSongCard.updateHitbox();
			mirrorSongCard.x -= mirrorSongCard.width;
			mirrorSongCard.antialiasing = false;
			mirrorSongCard.active = false;
			add(mirrorSongCard);

			noGhostTapping = new FlxText(6, ClientPrefs.settings.get("downScroll") ? 4 : FlxG.height - 24, 0, "Ghost Tapping is forced off!");
			noGhostTapping.scrollFactor.set();
			noGhostTapping.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noGhostTapping.visible = !PlayState.SONG.options.allowGhostTapping;
			noGhostTapping.active = false;
			add(noGhostTapping);
			noBotplay = new FlxText(6, ClientPrefs.settings.get("downScroll") ? 24 : FlxG.height - 44, 0, "Botplay is forced off!");
			noBotplay.scrollFactor.set();
			noBotplay.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noBotplay.visible = !PlayState.SONG.options.allowBot;
			noBotplay.active = false;
			if (noGhostTapping.visible == false)
				noBotplay.y = ClientPrefs.settings.get("downScroll") ? 4 : FlxG.height - 24;
			else
				noBotplay.y = ClientPrefs.settings.get("downScroll") ? 24 : FlxG.height - 44;
			add(noBotplay);
			songCreditsTxt = new FlxText(songCard.x, songCard.y + 20, 0, "");
			songCreditsTxt.scrollFactor.set();
			songCreditsTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
			songCreditsTxt.active = false;
			add(songCreditsTxt);
			remixCreditsTxt = new FlxText(songCard.x, songCreditsTxt.y + 40, 0, "");
			remixCreditsTxt.scrollFactor.set();
			remixCreditsTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
			remixCreditsTxt.active = false;
			add(remixCreditsTxt);

			songNameTxt = new FlxText(songCard.x + 2, (songCreditsTxt.y - 64) + 2, 0, "");
			songNameTxt.scrollFactor.set();
			songNameTxt.setFormat("VCR OSD Mono", 48, FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0].red, PlayState.instance.dad.healthColorArray[0].green, PlayState.instance.dad.healthColorArray[0].blue), LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
			songNameTxt.text = PlayState.SONG.header.song;
			songNameTxt.active = false;
			add(songNameTxt);

			switch (PlayState.SONG.header.song.toLowerCase())
			{
				case 'tutorial' | 'bopeebo' | 'fresh' | 'dad battle' | 'spookeez' | 'south' | 'pico' | 'philly nice' | 'blammed' | 'satin panties' | 'high' | 'milf' | 'cocoa' | 'eggnog' | 'senpai' | 'roses' | 'thorns' | 'ugh' | 'guns' | 'stress':
					songCreditsTxt.text = "Song by Kawaisprite";
					remixCreditsTxt.text = "From: Friday Night Funkin'";
				case 'monster' | 'winter horrorland':
					songCreditsTxt.text = "Song by Bassetfilms";
					remixCreditsTxt.text = "From: Friday Night Funkin'";
			}
			if (PlayState.SONG.options.credits != null && PlayState.SONG.options.remixCreds != null) {
				songCreditsTxt.text = PlayState.SONG.options.credits;
				remixCreditsTxt.text = PlayState.SONG.options.remixCreds;
			}
		}

        //shit for score text
		scoreTxtBg = new FlxSprite(0, 0).makeGraphic(679, 30, FlxColor.WHITE);
		scoreTxtBg.x = (FlxG.width/4)-40;
		scoreTxtBg.y = ClientPrefs.settings.get("downScroll") ? 13 : 683;
		scoreTxtBg.width = scoreTxtBg.width*2;
		scoreTxtBg.height = scoreTxtBg.height*2;
		scoreTxtBg.scrollFactor.set();
		scoreTxtBg.alpha = 0.001;
		if (ClientPrefs.settings.get("scoreDisplay") == 'Sarvente') {
			scoreTxtBg.alpha = 0.5;
		}
		scoreTxtBg.color = FlxColor.BLACK;
		scoreTxtBg.visible = !ClientPrefs.settings.get("hideHud");
		scoreTxtBg.active = false;
		add(scoreTxtBg);

		accuracyBg = new FlxSprite(0, 0).makeGraphic(205, 30, FlxColor.WHITE);
		accuracyBg.x = ClientPrefs.settings.get("watermarks") ? FlxG.width/4 + FlxG.width/4 + FlxG.width/4 + 80 : 40;
		accuracyBg.y = scoreTxtBg.y;
		accuracyBg.height = scoreTxtBg.height;
		accuracyBg.scrollFactor.set();
		accuracyBg.alpha = 0.001;
		if (ClientPrefs.settings.get("scoreDisplay") == 'Sarvente') {
			accuracyBg.alpha = 0.5;
		}
		accuracyBg.color = FlxColor.BLACK;
		accuracyBg.visible = !ClientPrefs.settings.get("hideHud");
		accuracyBg.active = false;
		add(accuracyBg);

		scoreTxt = new FlxText(0, 687, FlxG.width, "", 20);
		scoreTxt.y = ClientPrefs.settings.get("downScroll") ? 17 : 687;
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		if (ClientPrefs.settings.get("scoreDisplay") == 'Sarvente') {
			scoreTxt.x = 0;
			scoreTxt.borderStyle = SHADOW;
		} else if (ClientPrefs.settings.get("scoreDisplay") == 'Kade') {
			scoreTxt.x = 160;
		}
		scoreTxt.visible = !ClientPrefs.settings.get("hideHud");
		scoreTxt.active = false;
		
		leftTxt = new FlxText(scoreTxtBg.x + 40, scoreTxt.y, FlxG.width, "", 20);
		leftTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		leftTxt.scrollFactor.set();
		leftTxt.borderSize = 1.25;
		if (ClientPrefs.settings.get("scoreDisplay") == 'Sarvente') {
			leftTxt.borderStyle = SHADOW;
			leftTxt.x = scoreTxtBg.x + 5;
		}
		leftTxt.visible = !ClientPrefs.settings.get("hideHud");
		leftTxt.active = false;

		rightTxt = new FlxText(-FlxG.width/2 + 280, scoreTxt.y, FlxG.width, "", 20);
		rightTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		rightTxt.scrollFactor.set();
		rightTxt.borderSize = 1.25;
		switch (ClientPrefs.settings.get("scoreDisplay").toLowerCase()) {
			case 'sarvente':
				rightTxt.borderStyle = SHADOW;
				rightTxt.x = -FlxG.width/2 + 315;
			case 'fnf+':
				rightTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				rightTxt.x = -15;
				rightTxt.y = FlxG.height/2 - 100;
			case 'fnm':
				rightTxt.setFormat(Paths.font("helvetica.ttf"), 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				rightTxt.y += ClientPrefs.settings.get("downScroll") ? 40 : -20;
		}
		rightTxt.visible = !ClientPrefs.settings.get("hideHud");
		rightTxt.active = false;

		accuracyTxt = new FlxText(accuracyBg.x + 5, scoreTxt.y, FlxG.width, "", 20);
		accuracyTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		accuracyTxt.scrollFactor.set();
		accuracyTxt.borderSize = 1.25;
		if (ClientPrefs.settings.get("scoreDisplay") == 'Sarvente') {
			accuracyTxt.borderStyle = SHADOW;
		}
		accuracyTxt.visible = !ClientPrefs.settings.get("hideHud");
		accuracyTxt.active = false;

		add(leftTxt);
		add(scoreTxt);
		add(rightTxt);
		add(accuracyTxt);

		botplayTxt = new FlxText(400, ClientPrefs.settings.get("downScroll") ? timeBarBG.y - 78 : timeBarBG.y + 55, FlxG.width - 800, "AUTO", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = PlayState.instance.cpuControlled;
		botplayTxt.active = false;
		add(botplayTxt);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

		if (!botplayTxt.visible) return;
		botplaySine += 180 * elapsed * PlayState.instance.playbackRate;
		botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
    }

    public function updateRatings() {
        if (!ClientPrefs.settings.get("ratingsDisplay")) return;
		final rats = ["highestCombo", "combo", "perfects", "sicks", "goods", "bads", "shits", "wtfs", "misses"];
		final ratVars = [PlayState.instance.highestCombo, PlayState.instance.combo, PlayState.instance.perfects, PlayState.instance.sicks, PlayState.instance.goods, PlayState.instance.bads, PlayState.instance.shits, PlayState.instance.wtfs, PlayState.instance.songMisses];
		for (i in 0...rats.length) {
			curRatings.set(rats[i], ratVars[i]);
		}
        ratingsTxt.text = 'Max Combo: ${curRatings.get("highestCombo")}\nCombo: ${curRatings.get("combo")}\nPerfects: ${curRatings.get("perfects")}\nSicks: ${curRatings.get("sicks")}\nGoods: ${curRatings.get("goods")}\nBads: ${curRatings.get("bads")}\nShits: ${curRatings.get("shits")}\nWTFs: ${curRatings.get("wtfs")}\nCombo Breaks: ${curRatings.get("misses")}';
    }

    public function updateSongPercent(songPercent:Float)
        curSongPercent = songPercent;

    public function updateHealth(health:Float)
        curHealth = health;

    public function updateGS(gsOff:Bool) {
        if(noGhostTapping != null)
            noGhostTapping.visible = gsOff;
    }

    public function updateNBot(botOff:Bool) {
        botplayTxt.visible = !botOff;
        if(noBotplay != null) {
            if (noGhostTapping.visible == false) {
                noBotplay.y = ClientPrefs.settings.get("downScroll") ? 4 : FlxG.height - 24;
                noBotplay.visible = botOff;
            } else {
                noBotplay.y = ClientPrefs.settings.get("downScroll") ? 24 : FlxG.height - 44;
                noBotplay.visible = botOff;
            }
        }
    }

    public function tweenInCard() {
		if (songCreditsTxt != null && songCreditsTxt.text.length > 0) {
			FlxTween.tween(songCard, {x: 0}, 0.7, {
				startDelay: 0.1,
				ease: FlxEase.backInOut,
				onComplete: _ ->
				{
					new FlxTimer().start(1.3/(Conductor.bpm/100)/PlayState.instance.playbackRate, _ ->
						{
							if(songCard != null){
								FlxTween.tween(songCard, {x: cardTweenTo}, 0.5, {
									startDelay: 0.1,
									ease: FlxEase.backInOut,
									onComplete: _ ->
									{
										for (obj in [songCard, mirrorSongCard, songCreditsTxt, remixCreditsTxt, songNameTxt]) {
											remove(obj, true);
											obj.destroy();
										}
									}
								});
							}
							for (obj in [mirrorSongCard, songCreditsTxt, remixCreditsTxt, songNameTxt]) {
								FlxTween.tween(obj, {x: (obj == mirrorSongCard ? -1202 : cardTweenTo)}, 0.5, {
									startDelay: 0.1,
									ease: (obj == songNameTxt ? FlxEase.quadInOut : FlxEase.backInOut)
								});
							}
						});
				}
			});
			var objects = [mirrorSongCard, songCreditsTxt, remixCreditsTxt, songNameTxt];
			for (obj in objects) {
				FlxTween.tween(obj, {x: (obj == mirrorSongCard ? cardTweenTo : 0)}, 0.7, {
					startDelay: 0.1,
					ease: (obj == songNameTxt ? FlxEase.quadInOut : FlxEase.backInOut)
				});
			}
		} else {
			if (songCard != null) {
				for (obj in [songCard, mirrorSongCard, songCreditsTxt, remixCreditsTxt, songNameTxt]) {
					remove(obj, true);
					obj.destroy();
				}
			}
		}
    }

    public function timeTween() {
		if (timeTxt == null) return;
		if(timeTxtTween != null) {
			timeTxtTween.cancel();
		}
		timeTxt.scale.set(1.075, 1.075);
		timeTxtTween = FlxTween.tween(timeTxt.scale, {x: 1, y: 1}, Conductor.crochet / 1250 / 1.5 / PlayState.instance.playbackRate * PlayState.instance.gfSpeed, {onComplete: _ -> timeTxtTween = null});
    }

    public function scoreTween(daRating:String) {
        if(scoreTxtTween != null) {
            scoreTxtTween.cancel();
            leftTxtTween.cancel();
            rightTxtTween.cancel();
        }
        final ratingsArr = ['perfect', 'sick', 'good', 'bad', 'shit', 'wtf'];
        //math >>> switch statement ong
        final scaler:Float = 1.125 - (0.05 * ratingsArr.indexOf(daRating));
        scoreTxt.scale.set(scaler, scaler);
        leftTxt.scale.set(scaler, scaler);
        rightTxt.scale.set(scaler, scaler);
        scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, Conductor.crochet / 1250 / 2 / PlayState.instance.playbackRate * PlayState.instance.gfSpeed, {onComplete: _ ->scoreTxtTween = null});
        leftTxtTween = FlxTween.tween(leftTxt.scale, {x: 1, y: 1}, Conductor.crochet / 1250 / 2 / PlayState.instance.playbackRate * PlayState.instance.gfSpeed, {onComplete: _ -> leftTxtTween = null});
        rightTxtTween = FlxTween.tween(rightTxt.scale, {x: 1, y: 1}, Conductor.crochet / 1250 / 2 / PlayState.instance.playbackRate * PlayState.instance.gfSpeed, {onComplete: _ -> rightTxtTween = null});
    }
}