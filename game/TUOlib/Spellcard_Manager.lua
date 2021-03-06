local m={}
tuolib.spellcard_manager=m



local function 说明()
	local sample_sc_table_new={
		--boss标识符，从一面到EX面分别为"1A","1B","2"......"6A","6B","EX"
		['1A']={
			---@class cardinfo
			{
				--boss在_editor_class中的索引
				boss_name="Valenria",
				--显示在符卡练习界面的符卡名
					--如果是string，则无论什么难度都显示这个名称，为空字符串，则显示为“通常弹幕X”，X的值依照前后顺序而定
					--如果是table，则分别对应四个难度来显示，规则和string一样
					--只有对这项的处理不能照抄
				card_name={"静符「情感的抑制」","静符「情感的抑制」","眠符「Abandon Thinking」","眠符「Abandon Thinking」"},
				--符卡本体, 可能会变成{sc_Easy,sc_Normal,sc_Hard,sc_Lunatic}，因为都是表所以通过判断有无init属性来判断是否是符卡吧
				card=_tmp_sc,
				performingaction=false
			}
		},

	}
end
-- 说明() --卧槽真就可以用中文当函数名？好吧，挺正常的
----------------------------------------
---添加至符卡练习列表，支持直接覆盖
---@param card table 符卡本体
---@param name table 符卡名集合
---@param boss_name string
---@param boss_id string 
---@param card_index number 这个数字代表了这张卡在符卡练习列表里的次序，在编辑器里把这个留空则不计入符卡练习列表中
---@param performingaction boolean
function m.EditSpellCardList(card, name, boss_name, boss_id, card_index ,performingaction)
	
	if not card_index then return end
	-- Print("新符卡："..name..", "..boss_name..", "..boss_id..", "..card_index)
	if not _sc_table_new[boss_id] then _sc_table_new[boss_id]={} end
	local sctb=_sc_table_new[boss_id]

	if not sctb[card_index] then sctb[card_index]={} end
	local cardinfo=sctb[card_index]
	
	local pos=string.find(boss_name,":") 
	local index=nil

	--符卡信息分难度的话用表存储
	if pos then
		local diff=string.sub(boss_name,pos+1)
		for i,v in ipairs({"Easy","Normal","Hard","Lunatic"}) do
			if diff==v then index=i end
		end
		boss_name=string.sub(boss_name,1,pos-1)
	end

	--是否为道中，这个属性备用
	if string.find(boss_name,"mid") then cardinfo.is_mid=true end

	--符卡名字、符卡本体、是否为符卡这些信息的存入
	if index then 
		if not cardinfo.card then cardinfo.card={} end
		if not cardinfo.card_name then cardinfo.card_name={} end
		if not cardinfo.is_sc then cardinfo.is_sc={} end
		if not cardinfo.performingaction then cardinfo.performingaction={} end
		cardinfo.card_name[index]=name
		cardinfo.card[index]=card
		cardinfo.performingaction[index]=performingaction
		if name~='' then cardinfo.is_sc[index]=true end
	else
		cardinfo.card_name=name
		--适配多难度符卡名
		if type(name)=='table' then
			card.namelist=name
		end
		cardinfo.card=card
		cardinfo.performingaction=performingaction
		if name~='' then cardinfo.is_sc=true end
	end
	cardinfo.boss_name=boss_name
	
end
_AddToSCPRList=m.EditSpellCardList


stage.group.New('menu',{},"Spell Practice New",{lifeleft=0,power=400,faith=50000,bomb=0},false)
stage.group.AddStage('Spell Practice New','Spell Practice New@Spell Practice New',{lifeleft=0,power=400,faith=50000,bomb=0},false)
stage.group.DefStageFunc('Spell Practice New@Spell Practice New','init',function(self)
    _init_item(self)
    New(mask_fader,'open')
    New(_G[lstg.var.player_name])
	task.New(self,function()
		--设定bgm和背景
		local cardinfo=_sc_table_new[lstg.var.sc_index_new1][lstg.var.sc_index_new2]
		local card,perf
		ext.sc_pr=true
		local suffix=''
		local diff=difficulty
		--card本身也是表，所以只能用这种条件来判断card是表还是card
		if not cardinfo.card.init then
			card=cardinfo.card[diff]
			if cardinfo.performingaction and cardinfo.performingaction[diff] then
				perf=cardinfo.performingaction[diff]
			end
			suffix=":"..({"Easy","Normal","Hard","Lunatic"})[diff]
		else
			card=cardinfo.card
			if cardinfo.performingaction then
				perf=cardinfo.performingaction
			end
		end
		
		local b=_editor_class[cardinfo.boss_name..suffix]
		if not b then b=_editor_class[cardinfo.boss_name] end
		do
			Print(cardinfo.boss_name..suffix,b.bgm)
			if b.bgm ~= "" then
				LoadMusicRecord(b.bgm)
			else
				LoadMusic('spellcard',music_list.spellcard[1],music_list.spellcard[2],music_list.spellcard[3])
			end
			if b._bg ~= nil then
				New(b._bg)
			else
				New(temple_background)
			end
        end
        task._Wait(30)
		local _,bgm=EnumRes('bgm')
		for _,v in pairs(bgm) do
			if GetMusicState(v)~='stopped' then
				ResumeMusic(v)
			else
				if b.bgm ~= "" then
					_play_music(b.bgm)
				else
					_play_music("spellcard")
				end
			end
		end

        local _boss_wait=true local _ref
		if perf then
			_ref=New(b,{perf,card}) last=_ref
		else
			-- _ref=New(b,{card}) last=_ref
			_ref=New(b,{boss.move.New(0,144,60,MOVE_DECEL),card}) last=_ref
		end
        if _boss_wait then while IsValid(_ref) do task.Wait() end end
        task._Wait(150)
		if ext.replay.IsReplay() then
			ext.pop_pause_menu=true
			ext.rep_over=true
			lstg.tmpvar.pause_menu_text={'Replay Again','Return to Title',nil}
		else
			ext.pop_pause_menu=true
			lstg.tmpvar.death = false
			lstg.tmpvar.pause_menu_text={'Continue','Quit and Save Replay','Return to Title'}
		end
		task._Wait(60)
    end)
    task.New(self,function()
		while coroutine.status(self.task[1])~='dead' do task.Wait() end
		New(mask_fader,'close')
		_stop_music()
		task.Wait(30)
		stage.group.FinishStage()
	end)
end)





local non_sc_prefix1="道中-通常弹幕"
local non_sc_prefix2="通常弹幕"
---废弃的函数，用来整理符卡名字，让通常弹幕也带上次序
function m.SortCardName(boss_id,card_index,difficulty)
	local sctb=_sc_table_new[boss_id]
	if not sctb then TUO_Developer_Flow:ErrorWindow("没这boss！\nboss_id: "..boss_id) end
	local mid_nonsc_count,nonsc_count=0,0
	for i,v in ipairs(sctb) do
		local is_sc=false
		if type(v.is_sc)=='table' then
			is_sc=v.is_sc[difficulty]
			-- if not v.realname then v.realname={} end
		else
			is_sc=v.is_sc
		end
		if not is_sc then
			local realname
			if v.is_mid then
				mid_nonsc_count	=mid_nonsc_count+1
				realname=non_sc_prefix1..tostring(mid_nonsc_count)
			else
				nonsc_count=nonsc_count+1
				realname=non_sc_prefix2..tostring(nonsc_count)
			end
			if type(v.is_sc)=='table' then
				v.name[difficulty]=realname
			else
				v.name=realname
			end
		else

		end
	end




	
	local cardinfo=sctb[card_index]
	if not cardinfo then TUO_Developer_Flow:ErrorWindow("没这张符卡！\nboss_id: "..boss_id.."\ncard_index: "..card_index) end

end