--[[

FlamboyanceHUD
A plugin to dynamically change the colour of HUD elements based on conditions, events or custom preferences

By [RED] Espionage

http://sercodominion.org
#RED on irc.slashnet.org

Mode ideas
(1) Manufacturers HUD Mode: Changes the HUD depending on the manufactuer of the ship to their company colours TODO NOTE: Add control mechanism and loading and solve problem of what to do if generic manufacturer
(2) Health Mode: Green for 100% health and progressively going through yellow and then red as your HP decreases TODO: Event doesnt work on login
(3) Random mode: Gives you a random colour every time you undock
(4) Nebula Contrast Mode: Sets a different colour depending on the system you are in to contrast the nebula (example: Dau - 120 255 120) TODO
(5) Nebula complement mode: same as contrast mode except matches the nebula colour (example: Pelatus - 190 255 190, sedina 190 190 255) TODO 
(6) Ship colour mode: HUD colour conforms to the colour of the ship you're flying
(7) Warranty Sales Streak mode: Starts out white but gets progressively redder as you earn a larger kill streak, suggested by Savet TODO
(8) Race mode: Blue for Itani, Yellow for UIT, Red for Serco TODO: Events arent working for this one, doesnt load race on login
(9) Custom mode: sets HUD to custom palette
(10) Faction space mode: set HUD colour based on whos faction space you are in 

Also maybe NFZ unique colour when you enter a NFZ or maybe a mode that flashes when you take damage to replace the damage flash TODO: Investigate if this will work

TODO: the fixtargetless function doesnt need a timer anymore it can use the SECTOR_LOADED event on login. May still need a solution for when reload interface happens.
TODO: The login events dont seem to work very well for the Health and Race mode, I think its because the API functions they rely on don't work until after all the events. NOTE: Potential solution for race mode is to save default values in the config from when they first do the command, its sector notes so it will be the same for race mode. Still need a solution to health mode, maybe a timer?

]]

-- Declaratory Variables, Tables and such

flamboyance = {} -- Plugin Table
flamboyance.colour = {} -- Palette Table
flamboyance.timer = Timer()
flamboyance.settings = {}
flamboyance.settingsID = 359104463
flamboyance.settings.palettes = { -- Custom palettes table
	teal = {
		[1]="20 255 250 130 *",
		[2]="20 200 200",
		[3]="20 255 250 100*",
		[4]="20 155 150",
		[5]="20 255 250 40 *",
		[6]="20 255 250 80 *",
		[7]="20 255 250 50 *",
		[8]="20 255 250",
		[9]="20 255 228",
		[10]="20 255 250 80*",
		[11]={0.2,1,0.9,1,"&"},
		[12]="20 255 250 20 *",
		[13]="20 255 250 255 &",
		[14]="255 255 255",
		[15]="20 155 150",
	},
	yellow = {
		[1] = "192 192 0 130 *",
		[2] = "192 192 0",
		[3] = "192 192 0 100*",
		[4] = "142 142 0",
		[5] = "192 192 0 40 *",
		[6] = "192 180 0 80 *",
		[7] = "192 192 0 50 *",
		[8] = "192 192 0",
		[9] = "255 255 0",
		[10] = "192 192 80*",
		[11] = {0.8,0.8,-1,1,"&"},
		[12] = "192 180 0 20 *",
		[13] = "192 180 0 255 &",
		[14] = "255 255 255",
		[15] = "142 142 0",
	},
	red = {
		[1] = "255 20 20 100 *",
		[2] = "255 20 20",
		[3] = "255 20 20 100 *",
		[4] = "150 100 100",
		[5] = "255 20 20 40 *",
		[6] = "255 20 20 80 *",
		[7] = "255 20 20 50 *",
		[8] = "255 150 150",
		[9] = "200 40 40",
		[10] = "255 20 20 80*",
		[11] = {1,0.7,0.7,1,"&"},
		[12] = "255 20 20 20 *",
		[13] = "255 20 20 255 &",
		[14] = "255 255 255",
		[15] = "150 100 100",
	}
}

-- Save Settings
flamboyance.savesettings = function()
	SaveSystemNotes(spickle(flamboyance.settings), flamboyance.settingsID)
end

-- Load Settings/Establish Mode

flamboyance.loadsettings = function()
	flamboyance.settings = unspickle(LoadSystemNotes(flamboyance.settingsID))
	local currentmode = flamboyance.settings.mode
	if currentmode == 1 then
		
	elseif currentmode == 2 then
		flamboyance.healthmode()
		RegisterEvent(flamboyance.healthhit, "PLAYER_GOT_HIT")
		RegisterEvent(flamboyance.healthhit, "LEAVING_STATION")
		if flamboyance.settings.newrecticles == true then flamboyance.newrecticles() end
	elseif currentmode == 3 then
		flamboyance.randommode()
		RegisterEvent(flamboyance.randommode, "LEAVING_STATION")
		if flamboyance.settings.newrecticles == true then flamboyance.newrecticles() end
	elseif currentmode == 4 then

	elseif currentmode == 5 then

	elseif currentmode == 6 then
		  flamboyance.makeshipcolour()
		  RegisterEvent(flamboyance.makeshipcolour, "LEAVING_STATION")
		  if flamboyance.settings.newrecticles == true then flamboyance.newrecticles() end
	elseif currentmode == 7 then

	elseif currentmode == 8 then
		flamboyance.racemode()
		if flamboyance.settings.newrecticles == true then flamboyance.newrecticles() end
		RegisterEvent(flamboyance.racemode, "SECTOR_LOADED")
	elseif currentmode == 9 then
		if (flamboyance.settings.custom) then
		flamboyance.make(flamboyance.settings.custom)
		if flamboyance.settings.newrecticles == true then flamboyance.newrecticles() end
		end
	elseif currentmode == 10 then
		flamboyance.factionspace()
		RegisterEvent(flamboyance.factionspace, "SECTOR_LOADED")
		if flamboyance.settings.newrecticles == true then flamboyance.newrecticles() end
	end
end

-- Control System

function flamboyance.control(_,args)
	if (args~=nil) then
		flamboyance.clearmodes()
		if (args[2]~=nil and args[3]~=nil) then
			local red = tonumber(args[1])
			local green = tonumber(args[2])
			local blue = tonumber(args[3])
			if ((red >= 0 and red <= 255) and (green >= 0 and green <= 255) and (blue >= 0 and blue <= 255)) then
				flamboyance.clearmodes()
				flamboyance.settings.custom = {args[1],args[2],args[3]}
				flamboyance.settings.mode = 9
				if args[4] == "new" then
					flamboyance.newrecticles()
					flamboyance.settings.newrecticles = true
				end
				flamboyance.savesettings()
				flamboyance.make(args)
 				flamboyance.fixtargetless()
			else
				print("\127DBE3DEHUD: Invalid RGB Value, enter 3 values between 0 and 255")
			end
		elseif args[1] == "ship" then
			flamboyance.settings.mode = 6
			if args[2] == "new" then
				flamboyance.newrecticles()
				flamboyance.settings.newrecticles = true
			end
			flamboyance.savesettings()
			flamboyance.makeshipcolour()
			RegisterEvent(flamboyance.makeshipcolour, "LEAVING_STATION")
		elseif args[1] == "health" then
			flamboyance.settings.mode = 2
			if args[2] == "new" then
				flamboyance.newrecticles()
				flamboyance.settings.newrecticles = true
			end
			flamboyance.savesettings()
			flamboyance.healthmode()
			RegisterEvent(flamboyance.healthhit, "PLAYER_GOT_HIT")
			RegisterEvent(flamboyance.healthhit, "LEAVING_STATION")
		elseif args[1] == "random" then
			flamboyance.settings.mode = 3
			if args[2] == "new" then
				flamboyance.newrecticles()
				flamboyance.settings.newrecticles = true
			end
			flamboyance.savesettings()
			local random_table = flamboyance.generate_random_table()
			flamboyance.randommode(random_table)
			RegisterEvent(flamboyance.randommode, "LEAVING_STATION")
		elseif args[1] == "factionspace" then
			flamboyance.settings.mode = 10
			if args[2] == "new" then
				flamboyance.newrecticles()
				flamboyance.settings.newrecticles = true
			end
			flamboyance.savesettings()
			flamboyance.factionspace()
			RegisterEvent(flamboyance.factionspace, "SECTOR_LOADED")
		elseif args[1] == "fresh" then --fresh mode (like random except generates a random colour and saves it permanently, doesnt change on undock)
			local random_table = flamboyance.generate_random_table()
			flamboyance.settings.custom = random_table
			flamboyance.settings.mode = 9
			if args[2] == "new" then
				flamboyance.newrecticles()
				flamboyance.settings.newrecticles = true
			end
			flamboyance.savesettings()
			flamboyance.make(random_table)
			flamboyance.fixtargetless()
		elseif args[1] == "race" then
			flamboyance.settings.mode = 8
			if args[2] == "new" then
				flamboyance.newrecticles()
				flamboyance.settings.newrecticles = true
			end
			flamboyance.savesettings()
			flamboyance.racemode()
		end

	end
end

-- Administrative Lua Functions

function split(str, pat) -- to split a string
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

function flamboyance.clearmodes() -- Record an unregister command for every event registered in the plugin here
	UnregisterEvent(flamboyance.makeshipcolour, "LEAVING_STATION")
	UnregisterEvent(flamboyance.healthhit, "PLAYER_GOT_HIT")
	UnregisterEvent(flamboyance.healthhit, "LEAVING_STATION")
	UnregisterEvent(flamboyance.randommode, "LEAVING_STATION")
	UnregisterEvent(flamboyance.factionspace, "SECTOR_LOADED")
	UnregisterEvent(flamboyance.racemode, "SECTOR_LOADED")
end

-- Auto Generated Palette System Functions
flamboyance.make = function(rgbtable)
	local hr = rgbtable[1]
	local hg = rgbtable[2]
	local hb = rgbtable[3]

	local hrn = tonumber(rgbtable[1])
	local hgn = tonumber(rgbtable[2])
	local hbn = tonumber(rgbtable[3])

	local hrl = math.floor(hrn * 0.5)
	if hrl < 0 then hrl = tostring(0) else hrl = tostring(hrl) end
	local hgl = math.floor(hgn * 0.5)
	if hgl < 0 then hgl = tostring(0) else hgl = tostring(hgl) end
	local hbl = math.floor(hbn * 0.5)
	if hbl < 0 then hbl = tostring(0) else hbl = tostring(hbl) end

	local hrml = math.floor(hrn * 0.75)
	if hrml < 0 then hrml = tostring(0) else hrml = tostring(hrml) end
	local hgml = math.floor(hgn * 0.75)
	if hgml < 0 then hgml = tostring(0) else hgml = tostring(hgml) end
	local hbml = math.floor(hbn * 0.75)
	if hbml < 0 then hbml = tostring(0) else hbml = tostring(hbml) end

	local hrh = hrn + 40
	if hrh > 255 then hrh = tostring(255) else hrh = tostring(hrh) end
	local hgh = hgn + 40
	if hgh > 255 then hgh = tostring(255) else hgh = tostring(hgh) end
	local hbh = hbn + 40
	if hbh > 255 then hbh = tostring(255) else hbh = tostring(hbh) end

	local hrsh = hrn + 120
	if hrsh > 255 then hrsh = tostring(255) else hrsh = tostring(hrsh) end
	local hgsh = hgn + 120
	if hgsh > 255 then hgsh = tostring(255) else hgsh = tostring(hgsh) end
	local hbsh = hbn + 120
	if hbsh > 255 then hbsh = tostring(255) else hbsh = tostring(hbsh) end

	flamboyance.colour[1] = hr .. " " .. hg .. " " .. hb .. " 130 *"
	flamboyance.colour[2] = hr .. " " .. hg .. " " .. hb
	flamboyance.colour[3] = hr .. " " .. hg .. " " .. hb .. " 100 *"
	flamboyance.colour[4] = hrl .. " " .. hgl .. " " .. hbl
	flamboyance.colour[5] = hr .. " " .. hg .. " " .. hb .. " 40 *"
	flamboyance.colour[6] = hr .. " " .. hg .. " " .. hb .. " 80 *"
	flamboyance.colour[7] = hr .. " " .. hg .. " " .. hb .. " 50 *"
	flamboyance.colour[8] = hr .. " " .. hg .. " " .. hb .. " 40 *"
	flamboyance.colour[9] = hrh .. " " .. hgh .. " " .. hbh
	flamboyance.colour[10] = hr .. " " .. hg .. " " .. hb .. " 80 *"
	flamboyance.colour[11] = {hrn / 255, hgn / 255, hbn / 255,1, "&"}
	flamboyance.colour[12] = hr .. " " .. hg .. " " .. hb .. " 20 *"
	flamboyance.colour[13] = hr .. " " .. hg .. " " .. hb .. " 255 &"
	flamboyance.colour[14] = hrsh .. " " .. hgsh .. " " .. hbsh
	flamboyance.colour[15] = hrml .. " " .. hgml .. " " .. hbml

	-- Debug function will print the palette to the HUD

	-- for idx,valu in ipairs(flamboyance.colour) do
	--   if idx ~= 11 then
	--   print("Colour " .. idx .. ": " .. valu)
	--   end
	-- end

	flamboyance.makeit()
	flamboyance.fixtargetless() -- to fix issues with targetless
end

function flamboyance.newrecticles() -- Loads new custom high contrast recticles that are higher resolution and neutral coloured
	HUD.crosshairlayer[2][2].IMAGE = "plugins/FlamboyanceHUD/images/cross.png"
	HUD.crosshairlayer[2][2].SIZE = "128x128"
	radar.SetAimDirIcon("plugins/FlamboyanceHUD/images/newrecticle.png")
	radar.SetAimDirIconSize(55)
end

flamboyance.makeit = function() -- Primary function for recolouring HUD, contains all the API HUD table elements
	HUD.leftbar.LOWERCOLOR = flamboyance.colour[1]
	HUD.rightbar.LOWERCOLOR = flamboyance.colour[1]
	HUD.leftbar.UPPERCOLOR = flamboyance.colour[5]
	HUD.rightbar.UPPERCOLOR = flamboyance.colour[5]

	HUD.leftbar.MIDDLEABOVECOLOR = flamboyance.colour[12] -- these two are for FA mode
	HUD.leftbar.MIDDLEBELOWCOLOR = flamboyance.colour[3]

	HUD.distancebar[4][1].MIDDLEABOVECOLOR = flamboyance.colour[1]
	HUD.distancebar[4][1].MIDDLEBELOWCOLOR = flamboyance.colour[6]

	HUD.distancebar[4][1].LOWERCOLOR = flamboyance.colour[7]
	HUD.distancebar[4][1].UPPERCOLOR = flamboyance.colour[7]

	HUD.righttext.FGCOLOR = flamboyance.colour[4]
	HUD.lefttext.FGCOLOR = flamboyance.colour[4]

	HUD.distancebar[3].FGCOLOR = flamboyance.colour[4] -- 1300m 
	HUD.distancebar[6].FGCOLOR = flamboyance.colour[4] -- Latos I-8
	HUD.distancebar[8].FGCOLOR = flamboyance.colour[4] -- Unaligned Unmonitored

	HUD.distancebar[4][2].BGCOLOR = flamboyance.colour[3] --ACTIVATE

	HUD.energybar[1].FGCOLOR = flamboyance.colour[4] -- A/A Mode
	HUD.energybar[3].FGCOLOR = flamboyance.colour[4] -- 300

	HUD.leftflightassistindicator.FGCOLOR = flamboyance.colour[4] -- F/A Mode

	HUD.addonframe.FGCOLOR = flamboyance.colour[2] -- Addon frame

	HUD.cargoframe.FGCOLOR = flamboyance.colour[2] -- Cargo frame
	HUD.chatframe[1][1].BGCOLOR = flamboyance.colour[2] -- Chat Frame
	HUD.chatframe[1][1][1][1][2][2].BGCOLOR = flamboyance.colour[12] -- Background of text box
	if HUD.chatframe[1][1][1][2][2].TITLE == "" then HUD.chatframe[1][1][1][2][2].VISIBLE = "NO" end -- Fixes bug reported by Azurea and Rin, required to stop the chatframe outline from appearing when the textbox isnt being used but a pallette is being applied
	HUD.groupinfoframe[1].BGCOLOR = flamboyance.colour[13] -- Group frame
	HUD.missiontimerframe[1].BGCOLOR = flamboyance.colour[2] -- mission timer frame

	HUD.targetframe[1].BGCOLOR = flamboyance.colour[2] -- target frame
	HUD.targetframe.VISIBLE = "YES"
		HUD.targetframe[1][1][1][1].FGCOLOR = flamboyance.colour[9]
		HUD.targetframe[1][1][2][1].FGCOLOR = flamboyance.colour[9]
		HUD.targetframe[1][1][3][1].FGCOLOR = flamboyance.colour[9]
		HUD.targetframe[1][1][4][1].FGCOLOR = flamboyance.colour[9]
		HUD.targetframe[1][1][5][1].FGCOLOR = flamboyance.colour[9]

	HUD.licensewatchframe.FGCOLOR = flamboyance.colour[2] -- Combat License box
		HUD.licensewatchframe[1][1].FGCOLOR = flamboyance.colour[9] -- Combat License:
		HUD.licensewatchframe[1][2].FGCOLOR = flamboyance.colour[12] -- progressbar frame 
		HUD.licensewatchframe[1][2][1][1].LOWERCOLOR = flamboyance.colour[6] -- the progressbar 

	HUD.selfinfoframe.BGCOLOR = flamboyance.colour[13] -- self info frame
		HUD.selfinfo[1].FGCOLOR = flamboyance.colour[9] -- Credits"
		HUD.selfinfo[2].FGCOLOR = flamboyance.colour[15] -- 200,000
		HUD.selfinfo[3].FGCOLOR = flamboyance.colour[9] -- Mass
		HUD.selfinfo[4].FGCOLOR = flamboyance.colour[15] -- 4,900kg
		HUD.selfinfo[5].FGCOLOR = flamboyance.colour[9] -- Cargo
		HUD.selfinfo[6].FGCOLOR = flamboyance.colour[15] -- 0 / 2cu

	HUD.radarlayer[2][1][2].FGCOLOR = flamboyance.colour[6] -- left radar
	HUD.radarlayer[2][3][2].FGCOLOR = flamboyance.colour[6] -- left radar

	HUD.notify_text.FGCOLOR = flamboyance.colour[9] -- The large notification text
	HUD.notify_text.TITLE = "" -- Fixes a bug found by phaserlight where this text would linger

	HUD.crosshairlayer[2][2].FGCOLOR = flamboyance.colour[10] -- Crosshair
	HUD.targetdirectionlayer[2][2].FGCOLOR = flamboyance.colour[2]

	-- Mouselook recticle
	radar.SetAimDirIconColor(flamboyance.colour[11][1],flamboyance.colour[11][2],flamboyance.colour[11][3],flamboyance.colour[11][4],flamboyance.colour[11][5])

	local setspeed_old = HUD.setspeed -- These lines are for setting the colour of the speed indicator when exceeding turbo speed
	function HUD:setspeed(value)
	setspeed_old(self, value)
	local dacolour = (value < self.maxspeed) and flamboyance.colour[4] or flamboyance.colour[9]
	self.lefttext.FGCOLOR = dacolour
	end
end

flamboyance.fixtargetless = function()
	flamboyance.timer:SetTimeout(1500,flamboyance.targetlessfix)
end

flamboyance.targetlessfix = function()
	local has_targetless = pcall(function() return targetless end)
	if has_targetless then
		if (targetless.var.PlayerData ~= nil) then
		    targetless.var.PlayerData[1][3][3].FGCOLOR = flamboyance.colour[2] 
		    targetless.var.PlayerData[1][3][1][1][1][1][2].FGCOLOR = flamboyance.colour[2]
		    targetless.var.PlayerData[1][2][3][3][1].FGCOLOR = flamboyance.colour[2]
		    targetless.var.PlayerData[1][2][3][3][2][1].FGCOLOR = flamboyance.colour[2]
		    targetless.var.PlayerData[1][3][1][1][1][1][1].FGCOLOR = flamboyance.colour[2]
		    targetless.var.PlayerData[1][3][1][1][1][1][2].FGCOLOR = flamboyance.colour[2] -- hidden mission box
--		    targetless.var.PlayerData[1][3][1][1][2][1][1].BGCOLOR = flamboyance.colour[13]
		end
	end
end

-- Health Mode Functions

function flamboyance.gethealthstringcolour(health)
	local ranges = {
		[100] = {120,255,120},
		[90] = {150,255,150},
		[80] = {190,255,190},
		[70] = {225,225,170},
		[60] = {225,225,120},
		[50] = {220,190,150},
		[40] = {220,160,80},
		[30] = {225,120,60},
		[20] = {225,70,40},
		[10] = {225,20,20}
	}

	local colourtable = {}

	if health >= 95 then
		colourtable = ranges[100]
	elseif health >= 90 then
		colourtable = ranges[90]
	elseif health >= 80 then
		colourtable = ranges[80]
	elseif health >= 70 then
		colourtable = ranges[70]
	elseif health >= 60 then
		colourtable = ranges[60]
	elseif health >= 50 then
		colourtable = ranges[50]
	elseif health >= 40 then
		colourtable = ranges[40]
	elseif health >= 30 then
		colourtable = ranges[30]
	elseif health >= 20 then
		colourtable = ranges[20]
	elseif health < 20 then
		colourtable = ranges[10]
	end

	return colourtable

end

flamboyance.healthhit = function()
	flamboyance.timer:SetTimeout(100, flamboyance.healthmode)
end

flamboyance.healthmode = function()
	local currenthp = GetPlayerHealth(GetCharacterID())
	local rgbtablesplit = flamboyance.gethealthstringcolour(currenthp)

	flamboyance.make(rgbtablesplit)
end

-- Manufacturer Mode Functions
function flamboyance.getmfgrace(namestring)
	local races = {
		[1] = "Itani",
		[2] = "Serco",
		[3] = "UIT",
		[4] = "TPG",
		[5] = "BioCom",
		[6] = "Valent",
		[7] = "Orion",
		[8] = "Axia",
		[9] = "Corvus",
		[10] = "Tunguska",
		[11] = "Aeolus",
		[12] = "Ineubis",
		[13] = "Xang Xi"
	}
	local shiprace = nil
	for idx,race in ipairs(races) do
		if string.find(namestring, race) ~= nil then shiprace = idx end
	end
	if shiprace ~= nil then
		return shiprace
	else return 0 end
end

function flamboyance.mfgmode()
	local currentshipstring = GetActiveShipName()
	local doracetable = flamboyance.getfactionspacecolourtable(flamboyance.getmfgrace(currentshipstring))
	flamboyance.make(doracetable)
end

-- Ship Colour Mode Functions
flamboyance.makeshipcolour = function()
	local currentcolour = GetLastShipLoadout()
	local shipcolour = ShipPalette_string[currentcolour.shipcolor]
	local rgbtablesplit = split(shipcolour, " ")
	flamboyance.make(rgbtablesplit)
end

-- Random Mode
flamboyance.randommode = function(randomtable)
	if randomtable ~= nil and randomtable ~= "LEAVING_STATION" then -- LEAVING_STATION is passed in as a parameter when random mode is on
		flamboyance.make(randomtable)
	else
		local random_table = flamboyance.generate_random_table()
		flamboyance.make(random_table)
	end
end

function flamboyance.generate_random_table()
	local randomtable = {}
	randomtable[1] = math.random(0,255)
	randomtable[2] = math.random(0,255)
	randomtable[3] = math.random(0,255)
	return randomtable
end

-- Faction Space Mode
function flamboyance.getfactionspacecolourtable(index) -- WARNING This function is used in other modes besides faction space mode
	local factioncolourtable = { -- NOTE Colours in this table have been tweaked to have better contrast on the HUD
		[0] = {212,212,212}, -- Unaligned
		[1] = {96,128,255}, -- Itani
		[2] = {255,32,32}, -- Serco
		[3] = {192,192,0}, -- UIT
		[4] = {118,197,61}, -- TPG
		[5] = {50,151,221}, -- BioCom
		[6] = {254,141,26}, -- Valent
		[7] = {194,195,194}, -- Orion
		[8] = {146,80,188}, -- Axia
		[9] = {90,100,90}, -- Corvus
		[10] = {125,225,182}, -- Tunguska
		[11] = {223,88,186}, -- Aeolus
		[12] = {220,76,69}, -- Ineubis
		[13] = {5,190,80}, -- Xang Xi
	}
	return factioncolourtable[index]
end

function flamboyance.factionspace()
	local colourtable = flamboyance.getfactionspacecolourtable(GetSectorAlignment()) or {212,212,212} -- Get the colour or pick greyspace as the default
	flamboyance.make(colourtable)
end

-- Race mode
function flamboyance.racemode()
	local race_code = GetPlayerFaction() or 0
	if race_code < 1 then
		RegisterEvent(flamboyance.racemode, "SECTOR_LOADED")
	else
		flamboyance.make(flamboyance.getfactionspacecolourtable(race_code))
		UnregisterEvent(flamboyance.racemode, "SECTOR_LOADED")
	end
end

-- Register events and load settings on plugin initialize
flamboyance.loadsettings()
HUD.chatframe[1][1][1][2][2].VISIBLE = "NO" -- TODO: Quick hack to stop it from showing the chat bar on startup. Will likely be fixed by using the HUD_SHOW event instead of the PLAYER_ENTERED_GAME one

RegisterEvent(flamboyance.loadsettings, "PLAYER_ENTERED_GAME")
RegisterEvent(flamboyance.fixtargetless, "SECTOR_LOADED")
RegisterUserCommand('hud',flamboyance.control)
