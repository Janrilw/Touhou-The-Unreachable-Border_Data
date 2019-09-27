------------------------------------------------
---TUO_Developer_Tool_kit 
---东方梦无垠开发者工具兼大型高危实验基地 
---code by JanrilW
--F3可以开关调试界面（第一次开启需要快速连按3下）
--F6刷新输入设备
--F9
-----如果boss不存在，则跳过一个chapter（推荐在关卡开头使用）
-----如果boss存在则杀掉boss一身
--F10
--重载指定文件（filereloadlist.lua），如果同时按住shift则直接全部重载（也就是返回stageinit）
--计划中的功能：
--背景调试：读取位于Library\TUO_Developer_Tool_kit\bg中的所有lua文件，提取其中所有资源加载函数中的资源名并卸载，然后重载这些lua文件，并将lstg.bg删除，然后替换为新的背景脚本
--------------按下某个键可以改变背景的phase
--重载指定关卡
--
--!注意，插件外的鼠标滚轮状态获取函数可能会失效，如有需要请把这里的移出去
---------------------------------------------------
TUO_Developer_Tool_kit = {}
local self=TUO_Developer_Tool_kit
local INCLUDE_PATH='Library\\plugins\\TUO_Developer_Tool_kit\\'
--这个是界面
Include(INCLUDE_PATH.."TUO_Developer_HUD.lua")

--独立按键检测
local _KeyDown={}

local PATH={
	FILE_RELOAD='Library\\plugins\\filereloadlist.lua'
}
--简易的日志输出
local ENABLED_LOG_LEVEL=4
local Log=function (text,level) 
	level=level or 4
	if level>ENABLED_LOG_LEVEL then return end
	Print('[TUO_Developer_Tool_kit] '..text) 
end

---------------------------------------------
---重载外部文件或者程序内部指定的单个脚本
---@param path string 脚本的路径
local ReloadSingleFile=function(path)
	if not(lfs.attributes(path) == nil) then 
		local err
		local r,msg=xpcall(lstg.DoFile,function() err=debug.traceback() end,path)
		if r then 
			Log('成功重载脚本：'..path,2)
			flag=true
		else
			Log('重载脚本：'..path..' 的时候发生错误\n\t行数:'..msg..'\n\t错误详细信息:\n\t\t'..err,1) 
		end
	else
		Log('脚本 '..path..' 不存在',1) 
	end
end


---------------------------------------------
---重载指定（多个）脚本
---@param path string 若提供具体文件路径那就重载提供了路径的脚本，也可以传一个表进去
local ReloadFiles = function (path)
	Log('尝试重载指定脚本')
	if path then
		if type(path)=='string' then
			ReloadSingleFile(path)
		elseif type(path)=='table' then
			for k,v in pairs(path) do ReloadSingleFile(v) end
		end
	else
		if not(lfs.attributes(PATH.FILE_RELOAD) == nil) then 
			local list=lstg.DoFile(PATH.FILE_RELOAD) 
			local flag=false
			for k,v in pairs(list) do ReloadSingleFile(v)
			end
			if flag then  
				InitAllClass() --如果有成功重载就初始化所有类
			else 
				Log('重载列表为空',2)  
			end
		else
			Log('重载列表不存在，尝试生成 Library\\plugins\\filereloadlist.lua 添加项目',1)
			local text='local tmp={\n	--请在下方添加文件路径\n	--"",\n}\nreturn tmp'
			local f,msg=io.open(PATH.FILE_RELOAD)
			if f then 
				f.write(text)
				f.close()
			else
				Log('生成失败？？\n'..msg,1)
			end
		end
	end
end

--------------------------------------------
---独立按键检测函数，这个每帧只能调用一次
---@return boolean 返回键值状态
local CheckKeyState= function (k)
	if not _KeyDown[k] then _KeyDown[k]=false end
	if lstg.GetKeyState(k) then
		if not _KeyDown[k] then
			_KeyDown[k] = true
			return true
		end
	else
		_KeyDown[k] = false
	end
	return false
end



function TUO_Developer_Tool_kit.init()
	--
	self.ttf='f3_word'
	-- LoadTTF('f3_word','THlib\\UI\\ttf\\yrdzst.ttf',32)
	LoadTTF('f3_word','THlib\\exani\\times.ttf',32)
	self.visiable=false --标记界面是否可见
	self.locked=true --标记是否锁定
	self.unlock_time_limit=0
	self.UNLOCK_TIME_LIMIT=60
	self.unlock_count=0
	self.UNLOCK_COUNT=3
	self.hud=TUO_Developer_HUD
	self.hud.init()
	self:AddPanels()
	Log('初始化完毕',4)
end

function TUO_Developer_Tool_kit.frame()
	--解锁需要在一秒内连按三下F3
	if self.locked then 
		if CheckKeyState(KEY.F3) then
			if self.unlock_time_limit<=0 then 
				self.unlock_time_limit=	self.UNLOCK_TIME_LIMIT
				self.unlock_count=1
			else
				self.unlock_count=self.unlock_count+1
			end
		end
		self.unlock_time_limit=max(0,self.unlock_time_limit-1)
		if self.unlock_time_limit<=0 then
			self.unlock_count=0
		end
		if self.unlock_count>=self.UNLOCK_COUNT and self.unlock_time_limit>0 then 
			self.locked=false 
			self.visiable = not self.visiable
			if self.visiable then Log('F3调试界面已开启') else Log('F3调试界面已关闭') end
		end
	else
		if CheckKeyState(KEY.F10) then 
			if lstg.GetKeyState(KEY.SHIFT) then 
				ResetPool()
				lstg.included={}
				stage.Set('none', 'init') 
			else ReloadFiles() end
		end
		if CheckKeyState(KEY.F9) then
			do
				--适配多boss
				local boss_list={}
				for _,o in ObjList(GROUP_ENEMY) do
					if o._bosssys then table.insert(boss_list,o) end
				end
				if #boss_list>0 and (not lstg.GetKeyState(KEY.SHIFT)) then 
					for i=1,#boss_list do boss_list[i].hp=0 end
				elseif debugPoint then
					if lstg.GetKeyState(KEY.SHIFT) then 
						debugPoint=debugPoint-1
					else 
						debugPoint=debugPoint+1 end
				end
			end
		end
		if CheckKeyState(KEY.F3) then
			self.visiable = not self.visiable
			if self.visiable then Log('F3调试界面已开启') else Log('F3调试界面已关闭') end
		end
		--右键或者esc退出这个界面
		if (lstg.GetMouseState(2) or lstg.GetKeyState(KEY.ESCAPE)) and self.visiable then self.visiable=false Log('F3调试界面已关闭') end
		if CheckKeyState(KEY.TAB) then
			local hud=self.hud
			local num=#hud.panel
			num=max(1,min(num))
			if lstg.GetKeyState(KEY.SHIFT) then
				if hud.cur==1 then hud.cur=num else hud.cur=hud.cur-1 end
			else
				if hud.cur==num then hud.cur=1 else hud.cur=hud.cur+1 end
			end
		end
		--鼠标滚轮的操作写HUD里了

		if self.visiable then
			self.hud.timer=min(30,self.hud.timer+1)
		else 
			self.hud.timer=max(0,self.hud.timer-1)
		end
		self.hud.frame()
	end
end
function TUO_Developer_Tool_kit.render()
--这里用exanieditor的字体了
	if self.hud.timer>0 then
		self.hud.render()
	end
end

TUO_Developer_Tool_kit.init()