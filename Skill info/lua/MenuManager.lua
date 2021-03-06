local show_hours = false
local display_time = 15

if not _G.Skillinfo then
	_G.Skillinfo = _G.Skillinfo or {}
	Skillinfo._path = ModPath
    Skillinfo._data_path = SavePath .. "skillinfo.json"
    Skillinfo._data = {} 
	Skillinfo.Players = {}
	local num_player_slots = BigLobbyGlobals and BigLobbyGlobals:num_player_slots() or 4
	for i=1,num_player_slots do
		Skillinfo.Players[i] = {}
		for j=1,9 do
			Skillinfo.Players[i][j] = 0
		end
	end
end

function Skillinfo:Save()
    local file = io.open( self._data_path, "w+" )
	if file then
	   	file:write( json.encode( self._data ) )
	    file:close()
    end
end

function Skillinfo:Load()
   	local file = io.open( self._data_path, "r" )
   	if file then
   		self._data = json.decode( file:read("*all") )
   		file:close()
   	end
end
	
Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_Skillinfo", function( loc )
    loc:load_localization_file( Skillinfo._path .. "loc/en.json")
end)
	
Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_Skillinfo", function(menu_manager)
	MenuCallbackHandler.SkillInfo = function(self)
	    MenuCallbackHandler:Skill_Show()
		Skillinfo:Save()
    end
	Skillinfo:Load()
	MenuHelper:LoadFromJsonFile(Skillinfo._path .. "options/main.json", Skillinfo, Skillinfo._data)
end)

function MenuCallbackHandler:Skill_Show()
	log("skill_show")
	if managers.network:session() then
		Skillinfo:Information_To_HUD(managers.network:session():peer(_G.LuaNetworking:LocalPeerID()))
		for _, peer in pairs(managers.network:session():peers()) do
			Skillinfo:Information_To_HUD(peer)
		end
		Skillinfo:Debug_Message()
	end
end

function Skillinfo:Skills(peer_id)
	if managers.network:session() and managers.network:session():peers() then
		local peer = managers.network:session():peer(peer_id)
		if peer then
			if peer:skills() ~= nil then
				local skills = string.split(string.split(peer:skills(), "-")[1], "_")
				local perk_deck = string.split(string.split(peer:skills(), "-")[2], "_")
				local perk_deck_id = tonumber(perk_deck[1])
				local perk_deck_completion = tonumber(perk_deck[2])
				local message = peer:name().. Skillinfo:Text_Formatting(skills, managers.localization:text("menu_st_spec_" .. perk_deck_id), perk_deck_completion)
			end
		end
	end
end

function Skillinfo:NumberFormat(input_data)
	local array = {}
	for i=1,#input_data do
		if tonumber(input_data[i]) < 10 then
			input_data[i] = "0" .. input_data[i]
		end
		table.insert(array, input_data[i])
	end
	return array
end

function Skillinfo:Text_Formatting(skills, perk_deck, completion)
	local sk = {}
	local skill_string = {}
	local number = 0
	if #skills == 15 then
		skill_string = Skillinfo:NumberFormat(skills)
		if perk_deck and completion then
			return string.format(" M(%02u:%02u:%02u) E(%02u:%02u:%02u) T(%02u:%02u:%02u) G(%02u:%02u:%02u) F(%02u:%02u:%02u) %s %s/9", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5], skill_string[6], skill_string[7], skill_string[8], skill_string[9], skill_string[10], skill_string[11], skill_string[12], skill_string[13], skill_string[14], skill_string[15], perk_deck, completion)
		else
			return string.format("M(%02u:%02u:%02u) E(%02u:%02u:%02u) T(%02u:%02u:%02u) G(%02u:%02u:%02u) F(%02u:%02u:%02u)", skill_string[1], skill_string[2], skill_string[3], skill_string[4], skill_string[5], skill_string[6], skill_string[7], skill_string[8], skill_string[9], skill_string[10], skill_string[11], skill_string[12], skill_string[13], skill_string[14], skill_string[15])
		end
	end
end

function Skillinfo:Information_To_HUD(peer)
	if peer ~= nil then
		if peer:is_outfit_loaded() then
			local skills_perk_deck_info = string.split(peer:skills(), "-") or {}
			if #skills_perk_deck_info == 2 then
				local skills = string.split(skills_perk_deck_info[1], "_")
				local perk_deck = string.split(skills_perk_deck_info[2], "_")
				local p = managers.localization:text("menu_st_spec_" .. perk_deck[1])
				if show_hours then
					Steam:http_request('http://steamcommunity.com/profiles/'..peer:user_id()..'/games/?tab=recent', function(success, body)
	              	  if success  then
				   	     local name = peer:name() or ""
	                	    local s1, e1 = string.find(body, 'PAYDAY 2')
	                	    if e1 then
		             	       local s2, e2 = string.find(body, 'hours_forever', e1)
			          	      if e2 then
			          	          local hours = ''
			           	         local i = e2+4
				       	         while true do
			           	                local ch = string.sub(body, i, i)
				       	                if tonumber(ch) then
					                    	hours = hours..ch
					                    	i = i + 1
				                    	elseif ch == ',' then
					                    	i = i + 1
				                    	else
				                        	break
			                        	end
		                        	end
                                	local hrs = tonumber(hours)
	                            	if hrs and hrs > 0 then 								
					                	Skillinfo.Players[peer:id()][3] = peer:name() .. Skillinfo:Text_Formatting(skills, p, perk_deck[2]) .. " Hrs:" .. hrs
					            	end			   
			                	end
				        	else
                            	Skillinfo.Players[peer:id()][3] = peer:name() .. Skillinfo:Text_Formatting(skills, p, perk_deck[2]) .. " Hrs:Hidden"					
		                	end
				    	elseif not success then
				        	Skillinfo.Players[peer:id()][3] = peer:name() .. Skillinfo:Text_Formatting(skills, p, perk_deck[2]) .. " Hrs:Failed (too many requests)"
	                	end
                	end)
				else
					Skillinfo.Players[peer:id()][3] = peer:name() .. Skillinfo:Text_Formatting(skills, p, perk_deck[2])	
				end
			end
		end
	end
end

function Skillinfo:Debug_Message(message, color, message2, message3, message4)
	local num_player_slots = BigLobbyGlobals and BigLobbyGlobals:num_player_slots() or 4
	if not Skillinfo.overlay then
		Skillinfo.overlay = Overlay:newgui():create_screen_workspace() or {}
		Skillinfo.fonttype = tweak_data.menu.pd2_small_font
		Skillinfo.fontsize = tweak_data.menu.pd2_small_font_size
		if RenderSettings.resolution.x >= 600 and RenderSettings.resolution.x < 800 then
			Skillinfo.fontsize = 8
		elseif RenderSettings.resolution.x >= 800 and RenderSettings.resolution.x < 1024 then
			Skillinfo.fontsize = 12
		elseif RenderSettings.resolution.x >= 1024 and RenderSettings.resolution.x < 1280 then
			Skillinfo.fontsize = 16
		else
			Skillinfo.fontsize = 24
		end
		Skillinfo.stats = {}
		Skillinfo.mod = Skillinfo.overlay:panel():text{name = "mod", x = - (RenderSettings.resolution.x/2.1) + 0.5 * RenderSettings.resolution.x, y = - (RenderSettings.resolution.y/4) + 4.7/9 * RenderSettings.resolution.y, text = "Skill Info", font = Skillinfo.fonttype, font_size = Skillinfo.fontsize, color = Color("ffffff"), layer = 1}
		local pos = 5
		for i=1, num_player_slots do
			Skillinfo.stats[i] = Skillinfo.overlay:panel():text{name = "name" .. i, x = - (RenderSettings.resolution.x/2.1) + 0.5 * RenderSettings.resolution.x, y = - (RenderSettings.resolution.y/4) + pos/9 * RenderSettings.resolution.y, text = "", font = Skillinfo.fonttype, font_size = Skillinfo.fontsize, color = tweak_data.chat_colors[i], layer = 1}
			pos = pos + 0.3
		end
	end
	Skillinfo.mod:show()
	if not message then
		for i=1,num_player_slots do
			if Skillinfo.Players[i][3] ~= 0 then
				Skillinfo.stats[i]:set_text((Skillinfo.Players[i][3]))
				Skillinfo.stats[i]:show()
			end
		end
	else
		Skillinfo.stats[1]:set_text(message)
		Skillinfo.stats[1]:show()
		if message2 then
			Skillinfo.stats[2]:set_text(message2)
			Skillinfo.stats[2]:show()
		end
		if message3 then
			Skillinfo.stats[3]:set_text(message3)
			Skillinfo.stats[3]:show()
		end
		if message4 then
			Skillinfo.stats[4]:set_text(message4)
			Skillinfo.stats[4]:show()
		end
	end
	DelayedCalls:Add("Skillinfo:Timed_Remove", display_time, function()
		if Skillinfo.overlay then
			Skillinfo.mod:hide()
			for i=1,num_player_slots do
				Skillinfo.stats[i]:hide()
			end
		end
	end)
end