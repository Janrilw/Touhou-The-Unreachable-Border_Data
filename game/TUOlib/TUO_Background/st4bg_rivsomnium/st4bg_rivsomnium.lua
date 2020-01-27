---------------------------
--code by janrilw
---------------------------
local PATH = 'TUOlib\\TUO_Background\\st4bg_rivsomnium\\'
local RT_NAME1 = "st4_bg_render_target1"
local RT_NAME2 = "st4_bg_render_target2"
st4bg_rivsomnium = Class(object)

--region cracks
local cracks = Class(object)
local c_pos = {
	{ 218, 99 },
	{ 479, 120 },
	{ 686, 186 },
	{ 158, 170 },
	{ 317, 289 },
	{ 413, 232 },
	{ 595, 327 },
	{ 527, 237 },
	{ 567, 160 },
	{ 160, 603 },
	{ 508, 626 },
	{ 506, 845 },
	{ 606, 706 }
}
for i = 1, #c_pos do
	c_pos[i][1] = c_pos[i][1] / 2 - 196
	c_pos[i][2] = -(c_pos[i][2] / 2 - 224)
end
function cracks:init(index, layer)
	self.index = index
	self.img = 'st4bg_crack' .. index
	-- self.group=GROUP_ENEMY
	-- self.a=10
	-- self.b=10
	self.layer = layer
	self.x = c_pos[index][1]
	self.y = c_pos[index][2]
	local a = math.random(45, 135)
	local v = math.random(50, 200) / 100
	self.vx = cos(a) * v
	self.vy = sin(a) * v
	self.omiga = math.random(-1, 1)
	self.ay = -math.random(0.15, 0.17)
	self.bound = false
	self.dhs = math.random(0.45, 0.75)
end
function cracks:frame()
	if self.timer == 2 then
		lstg.var.timeslow = 4
	elseif self.timer > 15 then
		lstg.var.timeslow = 1
	end
	if self.y <= -500 then
		RawDel(self)
	end
	self.vscale = 1 - self.dhs * self.timer / 60
end
function cracks:render()
	-- local alpha=min(1,self.timer/60)
	local t = max(0, (self.timer - 7) / 7)
	local alpha2 = 1 - min(1, t)
	-- SetImageState(self.img,'',Color((1-alpha)*255*alpha2,255,255,255))
	SetImageState(self.img, '', Color(255 * alpha2, 255, 255, 255))
	object.render(self)
	-- SetImageState(self.img,'mul+add',Color(alpha*255*alpha2,255,255,255))
	-- object.render(self)
	-- if self.index==1 then
	-- 	local r=128*(1+self.timer/30)
	-- 	local alpha=(1-min(1,self.timer/30))*255
	-- 	sp.misc.DrawCircle2(0,144,r,32,'',alpha,255,255,255,0)
	-- end
end
InitSingleClass(cracks)

--endregion cracks

--region riv_cracks
local riv_cracks = {}

--因为init里会调用frame，所以frame提前了
function riv_cracks.New(bg, rep)
	---把原本的对象改为一个循环队列
	local list = bg.rivcrack_list
	bg.rivcrack_list_array = bg.rivcrack_list_array + 1
	if bg.rivcrack_list_array > bg.rivcrack_list_length then
		bg.rivcrack_list_array = 1
	end
	if not list[bg.rivcrack_list_array] then
		list[bg.rivcrack_list_array] = {}
	end
	riv_cracks.Refresh(list[bg.rivcrack_list_array], bg, rep)
end

function riv_cracks:Refresh(master, rep)
	self.master = self.master or master
	self.index = int(math.random(1, 16))
	self.img = 'st4bg_rivsomnium_crack' .. self.index
	self.x = 15
	self.size = 0.05 + math.random() ^ 4
	self.y = math.random(-10, 10) * self.size
	self.va = 180 + math.random(-1, 1) * self.size * 10
	self.z = self.size * 6 - 3
	self.size = self.size * math.random(3, 5)
	self.speed = 0.03 * math.random(1, 1.25)
	self.rot = math.random(0, 360)
	self.omiga = math.random(-0.3, 0.3)
	if rep then
		for _ = 1, rep * 5 do
			riv_cracks.frame(self)
		end
	end
end

function riv_cracks:frame()
	if not IsValid(self.master) then
		RawDel(self)
	end
	local dx, dy = self.speed * cos(self.va), self.speed * sin(self.va)
	self.x = self.x + dx
	self.y = self.y + dy
	self.rot = self.rot + self.omiga
	if self.x < -10 then
		riv_cracks.Refresh(self)
	end
end

function riv_cracks:render()
	local dx = cos(self.rot) * self.size
	local dy = sin(self.rot) * self.size
	local x, y, z = self.x, self.y, self.z
	Render4V(self.img, x - dx, y + dy, z, x + dy, y + dx, z, x + dx, y - dy, z, x - dy, y - dx, z)
end
InitSingleClass(riv_cracks)

--endregion riv_cracks


--region riv_crack_big
------------------------------------------------------------------------------------
---@class riv_cracks_big
---这个东西只能同时存在一个，新的会直接把旧的踢掉，请注意
---然后发现问题了，没办法只能搞三示例
local riv_cracks_big = {}
function riv_cracks_big.New(master, index)
	local riv = {}
	local init_position = {
		{ 8.5, -7, 4.5 },
		{ 9, 2, 5 },
		{ 5.5, -7, 6 },
	}
	riv.master = master
	riv.index = index
	riv.x, riv.y, riv.z = unpack(init_position[index])
	riv.img = 'st4bg_bigdreamcrack'
	riv.imgmask = 'st4bg_bigdreamcrack_mask'
	riv.va = ({ 180, 180, 150 })[index]
	riv.size = ({ 18, 18, 20 })[index]
	riv.speed = ({ 0.02, 0.02, 0.01 })[index]
	riv.rot = ({ 0, 0, 180 })[index]
	riv.omiga = ({ 0.1, -0.1, 0.05 })[index]
	riv.frame = riv_cracks_big.frame
	riv.render = riv_cracks_big.render
	riv.timer = 0
	master.riv_cracks_big[index] = riv
	return riv
end
function riv_cracks_big:frame()
	if self.disable then
		return
	end
	self.timer = self.timer + 1
	local dx, dy = self.speed * cos(self.va), self.speed * sin(self.va)
	self.x = self.x + dx
	self.y = self.y + dy
	self.rot = self.rot + self.omiga
	if self.x < -20 then
		self.disable = true
	end
end
local function RenderScene(self, index, timer)
	RenderClear(Color(0x00000000))
	if index == 1 then
		SetViewMode 'world'
		Render('st4bg_scene1', -30 - timer * 0.1, 1.8 * 224 - timer * 0.5, 0, 1)
		SetViewMode '3d'
	elseif index == 2 then
		SetViewMode 'world'
		Render('st4bg_scene2', 30 + timer * 0.1, 2 * 224 - timer * 0.5, 0, 1)
		SetViewMode '3d'
	elseif index == 3 then
		SetViewMode '3d'
		local dx = 5
		local dy = 5
		local z = -1
		local dddx = (self.xpos * 0.35) % (dx * 2)
		for ddx = -4 * dx, 4 * dx, dx * 2 do
			for ddy = -4 * dy, 4 * dy, dy * 2 do
				Render4V('st4bg_stary_sky', dddx + ddx + dx, ddy - dy, z, dddx + ddx + dx, ddy + dy, z, dddx + ddx - dx, ddy + dy, z, dddx + ddx - dx, ddy - dy, z)
			end
		end
		dx, dy = 1, 1
		dddx = (self.xpos * 2) % (dx * 2)
		local i = 0
		for z = -3, 5, 4 do
			if z==1 then
				local dx, dy = 4 ,4
				local z=1
				local dddx = (self.xpos * 2) % (dx * 2)
				for ddx = -4 * dx, 4 * dx, dx * 2 do
					for ddy = -4 * dy, 4 * dy, dy * 2 do
						Render4V('st4bg_dreamweb_pattern', dddx + ddx + dx, ddy - dy, z, dddx + ddx + dx, ddy + dy, z, dddx + ddx - dx, ddy + dy, z, dddx + ddx - dx, ddy - dy, z)
					end
				end
			end
			local imgname = 'st4bg_dreamweb' .. (i + 1)
			i = (i + 1) % 2
			for ddx = -10 * dx, 10 * dx, dx * 2 do
				for ddy = -10 * dy, 4 * dy, dy * 2 do
					Render4V(imgname, dddx + ddx + dx, ddy - dy, z, dddx + ddx + dx, ddy + dy, z, dddx + ddx - dx, ddy + dy, z, dddx + ddx - dx, ddy - dy, z)
				end
			end
		end

	end
end

function riv_cracks_big:render()
	if self.disable then
		return
	end
	local dx = cos(self.rot) * self.size
	local dy = sin(self.rot) * self.size
	local x, y, z = self.x, self.y, self.z
	--具体内容
	PushRenderTarget(RT_NAME1)
	RenderScene(self.master, self.index, self.timer)

	PopRenderTarget(RT_NAME1)
	--遮罩
	PushRenderTarget(RT_NAME2)
	RenderClear(Color(0x00000000))
	Render4V(self.imgmask, x - dx, y + dy, z, x + dy, y + dx, z, x + dx, y - dy, z, x - dy, y - dx, z)
	PopRenderTarget(RT_NAME2)
	PostEffect(RT_NAME1, 'mask', '', {
		tex = RT_NAME2
	})
	Render4V(self.img, x - dx, y + dy, z, x + dy, y + dx, z, x + dx, y - dy, z, x - dy, y - dx, z)

end

--endregion


--region st4bg_rivsomnium
--------------------------------------------------------------------------------
---四面背景本体
function st4bg_rivsomnium:InitPhaseInfo(phase)
	self.phaseinfo = lstg.DoFile(PATH .. '_phase_info.lua')
	tuolib.BGHandler.DoPhaseLogic(self, phase or 1)
end

function st4bg_rivsomnium.load_res()
	lstg.SetResourceStatus('global')
	local res_list = {
		{ 'st4bg_tree1', 'st4bg_tree1.png' },
		{ 'st4bg_brancch', 'st4bg_brancch.png' },
		{ 'st4bg_tree2', 'st4bg_tree2.png' },
		{ 'st4bg_cloud', 'st4bg_cloud.png' },
		{ 'st4bg_rivsomnium_flow', 'st4bg_rivsomnium_flow.png' },
		{ 'st4bg_stary_sky', 'st4bg_stary_sky.png' },
		{ 'st4bg_bigdreamcrack', 'st4bg_bigdreamcrack.png' },
		{ 'st4bg_bigdreamcrack_mask', 'st4bg_bigdreamcrack_mask.png' },
		{ 'st4bg_scene1', 'st4bg_scene1.png' },
		{ 'st4bg_scene2', 'st4bg_scene2.png' },
		{ 'st4bg_dreamweb1', 'st4bg_dreamweb.png' },
		{ 'st4bg_dreamweb_pattern', 'st4bg_dreamweb_pattern.png' },
	}
	for _, v in pairs(res_list) do
		--移除旧的并加载新的，仅调试用（也就调试的时候有机会卸载资源）
		--local pool=CheckRes("tex", v[1])
		--if pool then
		--	RemoveResource(pool, 1, v[1])
		--	RemoveResource(pool, 2, v[1])
		--end
		local ret, err = xpcall(_LoadImageFromFile, debug.traceback, v[1], PATH .. v[2], true, 0, 0, false, 0)
		if not ret and not CheckRes("tex", v[1]) then
			TUO_Developer_Flow:ErrorWindow(err)
		end
	end
	LoadImageGroupFromFile('st4bg_rivsomnium_crack', PATH .. 'st4bg_rivsomnium_crack.png', true, 4, 4)
	for i = 1, 16 do
		SetImageState('st4bg_rivsomnium_crack' .. i, 'mul+add', Color(0xFFFFFFFF))
	end
	SetImageState('st4bg_bigdreamcrack', 'mul+add', Color(0xFFFFFFFF))
	SetImageState('st4bg_dreamweb1', 'mul+add', Color(0xFFFF0000))
	CopyImage('st4bg_dreamweb2', 'st4bg_dreamweb1')
	SetImageState('st4bg_dreamweb2', 'mul+add', Color(0xFF0000FF))
	SetImageState('st4bg_dreamweb_pattern', '', Color(0x30FFFFFF))
	local TEXNAME = 'st4bg_crack'
	lstg.SetResourceStatus('global')
	lstg.LoadFX('mask', 'shader\\texture_mask.fx')
	lstg.LoadTexture(TEXNAME, PATH .. 'st4bg_crack.png', true)
	local coor_temp = {
		{ 942, 0, 436, 204 },
		{ 1378, 0, 369, 236 },
		{ 1852, 0, 196, 362 },
		{ 963, 789, 321, 308 },
		{ 0, 0, 433, 155 },
		{ 1747, 171, 105, 65 },
		{ 433, 0, 378, 204 },
		{ 1694, 236, 158, 51 },
		{ 1747, 0, 105, 171 },
		{ 983, 204, 321, 585 },
		{ 1490, 462, 558, 541 },
		{ 1490, 362, 558, 100 },
		{ 1693, 1003, 355, 308 },
		{ 942, 0, 436, 204 }
	}
	for i = 1, #coor_temp do
		lstg.LoadImage('st4bg_crack' .. i, TEXNAME, coor_temp[i][1], coor_temp[i][2], coor_temp[i][3], coor_temp[i][4])
	end
	lstg.LoadImage('st4bg_crack_b1', TEXNAME, 0, 1152, 784, 896)
	lstg.LoadImage('st4bg_crack_b2', TEXNAME, 784, 1152, 784, 896)
	lstg.LoadImage('st4bg_crack_b3', TEXNAME, 0, 256, 784, 896)
	lstg.SetResourceStatus('stage')
	lstg.CreateRenderTarget(RT_NAME1)
	lstg.CreateRenderTarget(RT_NAME2)
end
function st4bg_rivsomnium:init(phase,timer)
	background.init(self, false)
	st4bg_rivsomnium.load_res()
	self.speed = 0.03--即行走速度
	self.xpos = 0--等效的摄像机x轴位置,x轴方向向前
	self.init_phase = phase or 1
	self.init_timer=timer
	self.rivcrack_list = {}
	self.rivcrack_list_array = 0
	self.rivcrack_list_length = 120
	self.BIG_CRACK_APPEAR = { 4185, 4993, 5792 }
	self.riv_cracks_big = {}
end

function st4bg_rivsomnium:frame()
	if self.init_timer then
		local phase=1
		self.phaseinfo = lstg.DoFile(PATH .. '_phase_info.lua')
		for i,v in ipairs(self.phaseinfo) do
			if self.init_timer>=v.time then
				phase=i
				break
			end
		end
		tuolib.BGHandler.DoPhaseLogic(self, phase)
		self.timer=self.init_timer
		self.init_timer=nil
		self.init_phase=nil
	elseif self.init_phase then
		st4bg_rivsomnium.InitPhaseInfo(self, self.init_phase)
		self.init_phase = nil
	end
	self.xpos = self.xpos - self.speed

	tuolib.BGHandler.DoPhaseLogic(self)
	local phase = tuolib.BGHandler.GetCurPhase(self)
	--if phase >= 7 and self.timer % 5 == 0 then
	--	riv_cracks.New(self)
	--New(riv_cracks, self)
	--end
	for _, v in ipairs(self.rivcrack_list) do
		if v then
			riv_cracks.frame(v)
		end
	end
	for i, v in ipairs(self.BIG_CRACK_APPEAR) do
		if self.timer == v then
			riv_cracks_big.New(self, i)
			--如果落到触发节点之间
		elseif self.timer > v and ((self.BIG_CRACK_APPEAR[i + 1] and self.timer < self.BIG_CRACK_APPEAR[i + 1]) or (not self.BIG_CRACK_APPEAR[i + 1])) then
			local riv=riv_cracks_big.New(self, i)
			riv.timer = self.timer - v
			local dx, dy = riv.speed * cos(riv.va), riv.speed * sin(riv.va)
			riv.x = riv.x + dx * (self.timer - v)
			riv.y = riv.y + dy * (self.timer - v)
			riv.rot = riv.rot + riv.omiga * (self.timer - v)
		end
	end
	--带场景的大碎片
	for i = 1, 3 do
		if self.riv_cracks_big[i] then
			self.riv_cracks_big[i]:frame()
		end
	end
	task.Do(self)
end

function st4bg_rivsomnium:render()
	if self.init_phase then
		st4bg_rivsomnium.InitPhaseInfo(self, self.init_phase)
		self.init_phase = nil
	end
	SetViewMode '3d'
	tuolib.BGHandler.Apply3DParamater(self)
	local phase = tuolib.BGHandler.GetCurPhase(self)
	local showboss = IsValid(_boss)

	if showboss then
		background.WarpEffectCapture()
	end
	RenderClear(Color(255, self.cur.fogc[1], self.cur.fogc[2], self.cur.fogc[3]))

	--以上是固定要放进去的代码
	--下面是渲染
	-- local x=self.xpos%1
	local rfv = Render4V

	if phase <= 6 then
		local z = 0
		local dy = 2.5
		local dx = dy * 1.1
		local dr = sqrt(dx ^ 2 + dy ^ 2)

		if self.cur.eye[3] < 0 then
			local c = 255 * min(60, self.timer) / 60
			RenderClear(Color(255, c, c, c))
			rfv('st4bg_tree1', dx, -dy, z, dx, dy, z, -dx, dy, z, -dx, -dy, z)
			for z = -0.5, -3.5, -1 do
				local dx = dx + (dr) * cos(-z * 360) * 0.25
				local dy = dy + (dr) * sin(-z * 360) * 0.25
				rfv('st4bg_brancch', dx, -dy, z, dx, dy, z, -dx, dy, z, -dx, -dy, z)
			end
		else
			local dddx = 0
			if phase >= 5 then
				dddx = (self.xpos * 0.25) % (dx * 2)
			end
			for ddx = -4 * dx, 4 * dx, dx * 2 do
				for ddy = -4 * dy, 4 * dy, dy * 2 do
					rfv('st4bg_tree2', dddx + ddx + dx, ddy - dy, z, dddx + ddx + dx, ddy + dy, z, dddx + ddx - dx, ddy + dy, z, dddx + ddx - dx, ddy - dy, z)
				end
			end
			local x, dx = 10, (-self.xpos) % 10
			local y = 5
			for z = 1.5, 2.5, 0.05 do
				local light = z - 1.5
				SetImageState('st4bg_cloud', '', Color(255 * (1 - abs(z - 2)) ^ 3, 30 * light, 77 * light, 149 * light))
				for ddx = -10, 10, 10 do
					for ddy = -10, 10, 10 do
						rfv('st4bg_cloud', x - dx + ddx, y + ddy, z, -dx + ddx, y + ddy, z, -dx + ddx, -y + ddy, z, x - dx + ddx, -y + ddy, z)
					end
				end
			end
			if phase == 6 then
				local time_end = self.phaseinfo[6].duration - 1
				local time = { time_end - 30, time_end - 20, time_end - 10, time_end }
				local t = self.timer - self.phaseinfo[6].time
				if t == time[1] then
					misc.ShakeScreen(time[4] - time[1], 5)
				elseif t == time[4] then

				end
				SetViewMode 'world'

				if t >= time[1] and t < time[2] then
					if t == time[1] then
						misc.ShakeScreen(30, 3)
					end
					Render('st4bg_crack_b1', 0, 0)
				elseif t >= time[2] and t < time[3] then
					if t == time[2] then
						misc.ShakeScreen(30, 3)
					end
					Render('st4bg_crack_b2', 0, 0)
				elseif t >= time[3] and t < time[4] then
					if t == time[3] then
						misc.ShakeScreen(30, 3)
					end
					Render('st4bg_crack_b3', 0, 0)
				elseif t == time[4] then
					misc.ShakeScreen(60, 5)
					for i = 1, #c_pos do
						New(cracks, i, self.layer + 1)
					end
					for i = 1, 150 do
						riv_cracks.New(self, i)
						--New(riv_cracks, self, i)
					end
				end
				SetViewMode '3d'
			end
		end
	elseif phase >= 7 then
		local dx = 5
		local dy = 5
		local z = -1
		local dddx = (self.xpos * 0.25) % (dx * 2)
		for ddx = -4 * dx, 4 * dx, dx * 2 do
			for ddy = -4 * dy, 4 * dy, dy * 2 do
				rfv('st4bg_stary_sky', dddx + ddx + dx, ddy - dy, z, dddx + ddx + dx, ddy + dy, z, dddx + ddx - dx, ddy + dy, z, dddx + ddx - dx, ddy - dy, z)
			end
		end
		for i = 1, 3 do
			local speed = 1 + 0.5 * sin(60 * i - 45)
			local x, dx = 10, (-self.xpos * speed) % 10
			local dddy = speed * 5
			local y = 5
			for z = i - 0.5, i + 0.5, 0.1 do
				SetImageState('st4bg_rivsomnium_flow', 'mul+add', Color(15 * (1 - (abs(z - i) * 2) ^ 8), 255, 255, 255))
				for ddx = -10, 10, 10 do
					for ddy = -10 + dddy, 10 + dddy, 10 do
						rfv('st4bg_rivsomnium_flow', x - dx + ddx, y + ddy, z, -dx + ddx, y + ddy, z, -dx + ddx, -y + ddy, z, x - dx + ddx, -y + ddy, z)
					end
				end
			end
		end
	end

	for _, v in ipairs(self.rivcrack_list) do
		if v then
			riv_cracks.render(v)
		end
	end
	--带场景的大碎片
	for i = 1, 3 do
		if self.riv_cracks_big[i] then
			self.riv_cracks_big[i]:render()
		end
	end
	if showboss then
		background.WarpEffectApply()
	end
	--恢复viewmode至正常
	SetViewMode 'world'
end

--endregion