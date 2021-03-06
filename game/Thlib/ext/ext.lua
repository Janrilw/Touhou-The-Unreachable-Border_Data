---=====================================
---stagegroup|replay|pausemenu system
---=====================================

----------------------------------------
---ext加强库

---@class ext @额外游戏循环加强库
ext={}

local extpath="THlib\\ext\\"

DoFile(extpath.."ext_pause_menu.lua")--暂停菜单和暂停菜单资源
DoFile(extpath.."ext_replay.lua")--CHU爷爷的replay系统以及切关函数重载
DoFile(extpath.."ext_stage_group.lua")--关卡组

ext.replayTicker=0--控制录像播放速度时有用
ext.slowTicker=0--控制时缓的变量
ext.time_slow_level={1, 2, 3, 4}--60/30/20/15 4个程度
ext.pause_menu=ext.pausemenu()--实例化的暂停菜单对象，允许运行时动态更改样式

---重置缓速计数器
function ext.ResetTicker()
	ext.replayTicker=0
	ext.slowTicker=0
end

---获取暂停菜单发送的命令
---@return string
function ext.GetPauseMenuOrder()
	return ext.pause_menu_order
end

---发送暂停菜单的命令，命令有以下类型：
---'Continue'
---'Return to Title'
---'Quit and Save Replay'
---'Give up and Retry'
---'Restart'
---'Replay Again'
---@param msg string
function ext.PushPauseMenuOrder(msg)
	ext.pause_menu_order=msg
end

----------------------------------------
---extra game loop

function GameStateChange() ResetWorldOffset() end
--GetInput已经移动到Linput


	
function DoFrameEx()
	if ext.replay.IsReplay() then
		--播放录像时
		ext.replayTicker = ext.replayTicker + 1
		ext.slowTicker = ext.slowTicker + 1
		-- if GetKeyState(setting.keysys.repfast) then
		if GetKeyState(setting.keysys.repfast) or GetKeyState(setting.joysticks.repfast) then
			for _=1,4 do
				DoFrame(true, false)
				ext.pause_menu_order = nil
			end
		-- elseif GetKeyState(setting.keysys.repslow) then
		elseif GetKeyState(setting.keysys.repslow) or GetKeyState(setting.joysticks.repslow) then
			if ext.replayTicker % 4 == 0 then
				DoFrame(true, false)
				ext.pause_menu_order = nil
			end
		else
			if lstg.var.timeslow then
				local tmp=min(4,max(1,lstg.var.timeslow))
				if ext.slowTicker%(ext.time_slow_level[tmp])==0 then
					DoFrame(true, false)
				end
			else
				DoFrame(true, false)
			end
			ext.pause_menu_order = nil
		end
	else
		--正常游戏时
		ext.slowTicker=ext.slowTicker+1
		if lstg.var.timeslow and lstg.var.timeslow>0 then
			local tmp=min(4,max(1,lstg.var.timeslow))
			if ext.slowTicker%(ext.time_slow_level[tmp])==0 then
				DoFrame(true, false)
			end
		else
			DoFrame(true, false)
		end
	end
end

function FrameFunc()
	--加了一层判断，用于单帧操作和测试
	if not TUO_Developer_Tool_kit.ban_framefunc then
		if jstg then jstg.ProceedConnect() end--刷新网络状态
		boss_ui.active_count=0--重设boss ui的槽位（多boss支持）
		-- if GetLastKey() == setting.keysys.snapshot and setting.allowsnapshot then
		if (GetLastKey() == setting.keysys.snapshot or GetLastKey() == setting.joysticks.snapshot) and setting.allowsnapshot then
			Snapshot('snapshot\\'..os.date("!%Y-%m-%d-%H-%M-%S", os.time() + setting.timezone * 3600)..'.png')--支持时区
		end
		--执行场景逻辑
		if ext.pause_menu:IsKilled() then
			--处理录像速度与正常更新逻辑
			-- GetInput()
			DoFrameEx()
			--按键弹出菜单
			-- if (GetLastKey() == setting.keysys.menu or ext.pop_pause_menu) and (not stage.current_stage.is_menu) then
			if (GetLastKey() == setting.keysys.menu or GetLastKey() == setting.joysticks.menu or ext.pop_pause_menu) and (not stage.current_stage.is_menu) then
				ext.pause_menu:FlyIn()
			end
		else
			--暂停菜单部分
			--仍然需要更新输入
			-- jstg爆破痕迹
			-- jstg.GetInputEx(true)
			--切关处理
			if stage.next_stage then
				local w1=GetDefaultWorld()
				jstg.ApplyWorld(w1)
				
				-- ResetLstgtmpvar()--重置lstg.tmpvar
				-- ex.Reset()--重置ex全局变量
				
				-- if lstg.nextvar then
				-- 	lstg.var=lstg.nextvar
				-- 	lstg.nextvar =nil
				-- end
				-- 初始化随机数
				-- if lstg.var.ran_seed then
				-- 	--Print('RanSeed',lstg.var.ran_seed)
				-- 	ran:Seed(lstg.var.ran_seed)
				-- end
				
				-- if not stage.next_stage.is_menu then
				-- 	if scoredata.hiscore == nil then
				-- 		scoredata.hiscore = {}
				-- 	end
				-- 	lstg.tmpvar.hiscore = scoredata.hiscore[stage.next_stage.stage_name..'@'..tostring(lstg.var.player_name)]
				-- end
			end
			-- GetInput(true)
		end
		--暂停菜单更新
		ext.pause_menu:frame()
	end
	--开发者工具套件更新
	if TUO_Developer_Tool_kit then TUO_Developer_Tool_kit:frame() end
	--退出游戏逻辑
	if lstg.quit_flag then
		GameExit()
	end
	return lstg.quit_flag
end

function RenderFunc()
	BeginScene()
	SetWorldFlag(1)
	BeforeRender()
	--加了一层判断，用于在必要的时候关闭渲染，节省性能（实际上不知道有没有这个必要）
	if not TUO_Developer_Tool_kit.ban_renderfunc then
		if stage.current_stage.timer and stage.current_stage.timer >= 0 and stage.next_stage == nil then
			stage.current_stage:render()
			for i=1,jstg.GetWorldCount() do
				jstg.SwitchWorld(i)
				SetWorldFlag(jstg.worlds[i].world)
				ObjRender()
				SetViewMode('world')
				DrawCollider()
			end
		end
	end
	AfterRender()
	EndScene()
end

function AfterRender()
	--暂停菜单渲染
	ext.pause_menu:render()
	if Collision_Checker then
		SetViewMode'world'
		Collision_Checker.render()
	end
	--开发者工具套件渲染
	if TUO_Developer_Tool_kit then 	TUO_Developer_Tool_kit:render() end
	if lstg.CheckRes(7,'menu') then
		SetFontState('menu','',Color(50,255,255,255))
		RenderText('menu',TUO_VERSION,320,480,0.35,'center')
		SetFontState('menu','',Color(255,255,255,255))
	end
end

function FocusLoseFunc()
	if  ext.pause_menu:IsKilled() and stage.current_stage and jstg.network.status==0 then
		if not stage.current_stage.is_menu then
			ext.pop_pause_menu=true
		end
	end
end


