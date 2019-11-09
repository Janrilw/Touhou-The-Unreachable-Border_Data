---------------------------
--code by janrilw
---------------------------
local PATH='TUOlib/TUO_Background/bg_template/'
bg_template=Class(object)
--------------------------------
---加载资源
function bg_template.load_res()
	local res_list={
		{'bg_test','bg_test.png'}
	}
	for _,v in pairs(res_list) do
		_LoadImageFromFile(v[1],PATH..v[2],true,0,0,false,0)
	end
end
---------------------------------
---设置每个phase的属性
---算法说明：
---phaseinfo表用来记录所有的phase固有属性
---stt表用来记录当前3d参数的起始点，
---cur表用来记录当前3d参数
function bg_template:InitPhaseInfo(phase)
	self.phaseinfo=lstg.DoFile(PATH..'_phase_info.lua')
	tuolib.BGHandler.DoPhaseLogic(self,1)
end

function bg_template:init(phase)
	--
	background.init(self,false)
	bg_template.load_res()
	self.speed=0.03--即行走速度
	self.xpos=0--等效的摄像机x轴位置,x轴方向向前
	bg_template.InitPhaseInfo(self,phase)

	SetImageState('bg_test','',Color(0xA0FFFFFF))
end

function bg_template:frame()
	self.xpos=self.xpos-self.speed

	tuolib.BGHandler.DoPhaseLogic(self)
	task.Do(self)
end

function bg_template:render()
	SetViewMode'3d'
	tuolib.BGHandler.Apply3DParamater(self)
	local showboss = IsValid(_boss)

	if showboss then background.WarpEffectCapture() end

	RenderClear(Color(0xFFFFFFFF))
	--以上是固定要放进去的代码
	--下面是渲染
	local x=self.xpos%1
	for z=-3.1,-0.1,1 do
		for dx=12,-1,-1 do
			for y=5,-5,-1 do
				Render4V('bg_test',x+dx+1,y,z,x+dx+1,y+1,z,x+dx,y+1,z,x+dx,y,z)
			end
		end
	end

	if showboss then background.WarpEffectApply() end
	--恢复viewmode至正常
	SetViewMode'world'
end
