special_manual=Class(object)
function special_manual:init()
	self.layer=LAYER_TOP
	self.group=GROUP_GHOST
	
	self.title='Manual_title'
	self.pre_menu='main_menu'
	self.has_logo=false
	self.locked=true
	
	self.choose=1
	self.changed=false --更换选项
	
	self.exani_names={'Manual_item'}
	self.enables={true}
	
	menus['manual_menu']=self
end

function special_manual:frame()
	if self.locked then return end
	
	if self.changed and not lstg.GetKeyState(KEY.UP) and not lstg.GetKeyState(KEY.DOWN) then self.changed=false end
	
	if not self.changed then
		local action
		if lstg.GetKeyState(KEY.UP) then
			self.choose=self.choose-1
			if self.choose<1 then
				self.choose=10
				action='1to10'
			else
				action=(self.choose+1)..'to'..self.choose
			end
			exani_player_manager.ExecuteExaniPredefine(play_manager,'Manual_item',action)
			self.changed=true
		elseif lstg.GetKeyState(KEY.DOWN) then
			self.choose=self.choose+1
			if self.choose>10 then
				self.choose=1
				action='10to1'
			else
				action=(self.choose-1)..'to'..self.choose
			end
			exani_player_manager.ExecuteExaniPredefine(play_manager,'Manual_item',action)
			self.changed=true
		end
	end
	
	if not self.changed then
		if lstg.GetKeyState(KEY.X) then
			if self.pre_menu~='' then base_menu.ChangeLocked(self) base_menu.ChangeLocked(menus[self.pre_menu]) end
			PlaySound('cancel00', 0.3)
			self.changed=true
		end
	end
end

-------------------------------------------------

local function FetchReplaySlots()
	local ret = {}
	ext.replay.RefreshReplay()

	for i = 1, ext.replay.GetSlotCount() do
		local text={}
		local slot = ext.replay.GetSlot(i)
		if slot then
			-- 使用第一关的时间作为录像时间
			local date = os.date("!%Y/%m/%d", slot.stages[1].stageDate + setting.timezone * 3600)

			-- 统计总分数
			local totalScore = 0
			local diff,stage_num=0,0
			local tmp
			for i, k in ipairs(slot.stages) do
				totalScore = totalScore + slot.stages[i].score
				diff=string.match(k.stageName,'^.+@(.+)$')
				tmp=string.match(k.stageName,'^(.+)@.+$')
				if string.match(tmp,'%d+')==nil then
					stage_num=tmp
				else
					stage_num='St'..string.match(tmp,'%d+')
				end
			end
			if diff=='Spell Practice' then diff='SpellCard' end
			if tmp=='Spell Practice' then stage_num='SC' end
			if slot.group_finish == 1 then stage_num='All' end
			text = {string.format('No.%02d',i), slot.userName, date, slot.stages[1].stagePlayer, diff, stage_num}
		else
			text = {string.format('No.%02d',i), '--------', '----/--/--', '--------', '--------', '---'}
		end
		table.insert(ret, text)
	end
	return ret
end

special_replay=Class(object)

function special_replay:init()
	self.layer = LAYER_TOP
	self.group = GROUP_GHOST
	self.bound = false
	self.x = screen.width * 0.5 + screen.width
	self.y = screen.height * 0.5
	
	self.title='Replay_titleAndTable'
	self.pre_menu='main_menu'
	self.has_logo=false
	self.locked = true

	self.shakeValue = 0

	self.state = 0
	self.state1Selected = 1
	self.state1Text = {}
	self.state2Selected = 1
	self.state2Text = {}

	special_replay.Refresh(self)
	
	menus['replay_menu']=self
end

function special_replay:Refresh()
	self.state1Text = FetchReplaySlots()
end

function special_replay:frame()
	task.Do(self)
	if self.locked then return end

	if self.shakeValue > 0 then
		self.shakeValue = self.shakeValue - 1
	end

	if self.state == 0 then
		local lastKey = GetLastKey()
		if lastKey == setting.keys.up then
			self.state1Selected = max(1, self.state1Selected - 1)
			self.shakeValue = ui.menu.shake_time
			PlaySound('select00', 0.3)
		elseif lastKey == setting.keys.down then
			self.state1Selected = min(ext.replay.GetSlotCount(), self.state1Selected + 1)
			self.shakeValue = ui.menu.shake_time
			PlaySound('select00', 0.3)
		elseif KeyIsPressed("shoot") then
			-- 构造关卡列表
			local slot = ext.replay.GetSlot(self.state1Selected)
			if slot ~= nil then
				self.state = 1
				self.state2Text = {}
				self.state2Selected = 1
				self.shakeValue = ui.menu.shake_time

				for i, v in ipairs(slot.stages) do
					local stage = string.match(v.stageName,'^(.+)@.+$')
					local score = string.format("%012d", v.score)
					table.insert(self.state2Text, {stage, score})
				end
				PlaySound('ok00', 0.3)
			end
		elseif KeyIsPressed("spell") then
			if self.pre_menu~='' then
				base_menu.ChangeLocked(self)
				base_menu.ChangeLocked(menus[self.pre_menu])
				menu.FadeOut2(replay_menu,'right')
			end
			PlaySound('cancel00', 0.3)
		end
	elseif self.state == 1 then
		local slot = ext.replay.GetSlot(self.state1Selected)
		local lastKey = GetLastKey()
		if lastKey == setting.keys.up then
			self.state2Selected = max(1, self.state2Selected - 1)
			self.shakeValue = ui.menu.shake_time
			PlaySound('select00', 0.3)
		elseif lastKey == setting.keys.down then
			self.state2Selected = min(#slot.stages, self.state2Selected + 1)
			self.shakeValue = ui.menu.shake_time
			PlaySound('select00', 0.3)
		elseif KeyIsPressed("shoot") then
			-- 转场
			local slot = ext.replay.GetSlot(self.state1Selected)
			menu.FadeOut2(replay_menu,'right')
            stage.IsReplay=true--判定进入rep播放的flag add by OLC
            stage.Set('load', slot.path, slot.stages[self.state2Selected].stageName)
			PlaySound('ok00', 0.3)
		elseif KeyIsPressed("spell") then
			self.shakeValue = ui.menu.shake_time
			self.state = 0
		end
	end
end

function special_replay:render()
	SetViewMode('ui')
	if self.state == 0 then
		ui.DrawRepText(
			"replayfnt",
			"replay_title",
			self.state1Text,
			self.state1Selected,
			self.x,
			self.y,
			1,
			self.timer,
			self.shakeValue
			)
	elseif self.state == 1 then
		ui.DrawRepText2(
			"replayfnt",
			"replay_title",
			self.state2Text,
			self.state2Selected,
			self.x,
			self.y+120,
			1,
			self.timer,
			self.shakeValue,
			"center")
	end
end

function menu:FadeIn2()
	self.x=screen.width*0.5
	task.Clear(self)
	task.New(self,function()
		for i=0,29 do
			self.alpha=i/29
			task.Wait()
		end
	end)
end

function menu:FadeOut2()
	task.Clear(self)
	if not self.locked then
		task.New(self,function()
			for i=29,0,-1 do
				self.alpha=i/29
				task.Wait()
			end
		end)
	end
end

-------------------------------------

special_difficulty=Class(object)
function special_difficulty:init()
	self.layer=LAYER_TOP
	self.group=GROUP_GHOST
	self.bound=false
	
	self.title='ChooseDiff_title'
	self.pre_menu='start_menu'
	self.has_logo=false
	self.locked=true
	self.init_timer=0
	
	self.choose=1
	self.changed=false
	
	self.is_choose=false
	
	self.pics={'ChooseDiff_Easy','ChooseDiff_Normal','ChooseDiff_Hard','ChooseDiff_Lunatic'} --exani名字刚好和图片相同
	self.gap=280
	self.repeats=4
	self.speed=0.5
	self.y=200
	self.z=1.5
	
	menus['diff_menu']=self
end

function special_difficulty:frame()
	if self.locked then return end
	self.init_timer=self.init_timer+1
	if self.changed and not lstg.GetKeyState(KEY.LEFT) and not lstg.GetKeyState(KEY.RIGHT) then self.changed=false end
	
	if self.init_timer>0 and self.init_timer<=30 then
		
	end
	
	if self.init_timer==30 then
		exani_player_manager.ExecuteExaniPredefine(play_manager,self.pics[self.choose],'activate')
	end
	
	if self.init_timer>30 then
		if lstg.GetKeyState(KEY.LEFT) then
			if self.choose~=1 then
				self.choose=self.choose-1
				exani_player_manager.ExecuteExaniPredefine(play_manager,self.pics[self.choose],'activate')
			end
		elseif
		
		end
	end
end

function special_difficulty:render()
	if self.locked and not self.is_choose then
		SetViewMode('ui')
		for i=1,#self.pics do
			local dx=(self.gap*(i-self.repeats*(#self.pics)/2))
			Render(self.pics[i],x,self.y,0,1,1,self.z)
			if x>560 then Render(self.pics[i],x-640,self.y,0,1,1,self.z) end
		end
	elseif not self.locked then
		for i=1,#self.pics do
			if i~=self.choose then
				local x=80+160*(i-1)
				Render(self.pics[i],x,self.y,0,1,1,self.z)
			end
		end
	end
end