LoadTexture('item','THlib\\item\\item.png')
--【修改标记】增加了正面道具和负面道具在这儿
--LoadImageGroup('item','item',0,0,32,32,2,5,8,8)
LoadImageGroup('item','item',0,0,32*2,32*2,2,5,16,16)
--LoadImageGroup('item_up','item',64,0,32,32,2,5)
LoadImageGroup('item_up','item',64*2,0,32*2,32*2,2,5)
SetImageState('item8','mul+add',Color(0xC0FFFFFF))
LoadTexture('bonus1','THlib\\item\\item.png')
LoadTexture('bonus2','THlib\\item\\item.png')
LoadTexture('bonus3','THlib\\item\\item.png')

lstg.var.collectingitem=0

item=Class(object)

function item:init(x,y,t,v,angle)
	x=min(max(x,lstg.world.l+8),lstg.world.r-8)
	self.x=x
	self.y=y
	angle=angle or 90
	v=v or 1.5
	SetV(self,v,angle)
	self.v=v
	self.group=GROUP_ITEM
	self.layer=LAYER_ITEM
	self.bound=false
	self.img='item'..t
	self.imgup='item_up'..t
	self.attract=0
end

function item:render()
	if self.y>lstg.world.t then Render(self.imgup,self.x,lstg.world.t-8) else object.render(self) end
end

function item:frame()
	local player=self.target
	if self.timer<24 then
		self.rot=self.rot+45
		self.hscale=(self.timer+25)/48
		self.vscale=self.hscale
		if self.timer==22 then self.vy=min(self.v,2) self.vx=0 end
	elseif self.attract>0 then
		local a=Angle(self,player)
		self.vx=self.attract*cos(a)+player.dx*0.5
		self.vy=self.attract*sin(a)+player.dy*0.5
	else self.vy=max(self.dy-0.03,-1.7) end
	if self.y<lstg.world.boundb then 
	    Del(self)
		DR_Pin.add(K_dr_item) --遗漏道具梦现指针往当前侧偏移
	end
	if self.attract>=8 then self.collected=true end
end

function item:colli(other)
	--if other==player then
	if IsPlayer(other) then
		if self.class.collect then self.class.collect(self,other) --RunSystem("on_collect_item",self,other) 
		end
		Kill(self)
		PlaySound('item00',0.3,self.x/200)
	end
	IsPlayerEnd()
end

function GetPower(v)
	local before=int(lstg.var.power/100)
	lstg.var.power=min(player.maxPower,lstg.var.power+v)
	local after=int(lstg.var.power/100)
	if after>before then PlaySound('powerup1',0.5) end
	if lstg.var.power>=400 then
		lstg.var.score=lstg.var.score+v*100
	end
end

function Getlife(v)
	lstg.var.chip=lstg.var.chip+v
	if lstg.var.chip>=100 then
		lstg.var.chip=lstg.var.chip-100
		lstg.var.lifeleft=min(11,lstg.var.lifeleft+1)
		PlaySound('extend',0.5)
		New(hinter,'hint.extend',0.6,0,112,15,120)
	end
end

function Getbomb(v)
	lstg.var.bombchip=lstg.var.bombchip+v
	if lstg.var.bombchip>=100 then
		lstg.var.bomb=min(3,lstg.var.bomb+1)
		lstg.var.bombchip=lstg.var.bombchip-100
		PlaySound('cardget',0.8)
	end
end
item_power=Class(item)
function item_power:init(x,y,v,a) item.init(self,x,y,1,v,a) end
function item_power:collect()
	GetPower(1)
end
item_power_mid=Class(item)
function item_power_mid:init(x,y,v,a) item.init(self,x,y,5,v,a) end
function item_power_mid:collect() GetPower(10)  end

item_power_large=Class(item)
function item_power_large:init(x,y,v,a) item.init(self,x,y,6,v,a) end
function item_power_large:collect() GetPower(100)  end

item_power_full=Class(item)
function item_power_full:init(x,y) item.init(self,x,y,4) end
function item_power_full:collect() GetPower(400)  end

item_extend=Class(item)
function item_extend:init(x,y) item.init(self,x,y,7) end
function item_extend:collect()
	lstg.var.lifeleft=min(11,lstg.var.lifeleft+1)
	PlaySound('extend',0.5)
	New(hinter,'hint.extend',0.6,0,112,15,120)
end

item_chip=Class(item)
function item_chip:init(x,y) item.init(self,x,y,3)
--	PlaySound('bonus',0.8)
end
function item_chip:collect()
	Getlife(20)
end
----------------------------
item_bombchip=Class(item)
function item_bombchip:init(x,y) item.init(self,x,y,9)
--	PlaySound('bonus2',0.8)
end
function item_bombchip:collect()
	Getbomb(20)
end
item_bomb=Class(item)
function item_bomb:init(x,y)  item.init(self,x,y,10)
end
function item_bomb:collect()
	lstg.var.bomb=min(3,lstg.var.bomb+1)
	PlaySound('cardget',0.8)
end
----------------------------
item_faith=Class(item)
function item_faith:init(x,y) item.init(self,x,y,5) end
function item_faith:collect()
	 Getbomb(0.6)
end

item_faith_minor=Class(object)
function item_faith_minor:init(x,y)
	self.x=x self.y=y
	self.img='item'..8
	self.group=GROUP_ITEM
	self.layer=LAYER_ITEM
	if not BoxCheck(self,lstg.world.l,lstg.world.r,lstg.world.b,lstg.world.t) then RawDel(self) end
	self.vx=ran:Float(-0.15,0.15)
	self._vy=ran:Float(3.25,3.75)
	self.flag=1
	self.attract=0
	self.bound=false
	self.is_minor=true
	self.target=jstg.players[ex._item1%#jstg.players+1]
	ex._item1=ex._item1+1
end
function item_faith_minor:frame()
	local player=self.target
	if player.death>80 and player.death<90 then
		self.flag=0
		self.attract=0
	end
	if self.timer<45 then
		self.vy=self._vy-self._vy*self.timer/45
	end
	if self.timer>=54 and self.flag==1 then
		SetV(self,8,Angle(self,player))
	end
	if self.timer>=54 and self.flag==0 then
		if self.attract>0 then
			local a=Angle(self,player)
			self.vx=self.attract*cos(a)+player.dx*0.5
			self.vy=self.attract*sin(a)+player.dy*0.5
		else
			self.vy=max(self.dy-0.03,-2.5)
			self.vx=0
		end
		if self.y<lstg.world.boundb then Del(self) end
	end
	if Dist(self,player)<10 then
		PlaySound('item00',0.3,self.x/200)
		lstg.var.faith=lstg.var.faith+4
		Del(self)
	end
end
item_faith_minor.colli=item.colli

function item_faith_minor:collect()
	local var=lstg.var
	var.faith=var.faith+4
	var.score=var.score+500
end

item_point=Class(item)
function item_point:init(x,y) item.init(self,x,y,2) end
function item_point:collect()
	local var=lstg.var
	if self.attract==8 then
		New(float_text,'item',var.pointrate,self.x,self.y+6,0.75,90,60,0.5,0.5,Color(0x80FFFF00),Color(0x00FFFF00))
		var.score=var.score+var.pointrate
	else
		New(float_text,'item',int(var.pointrate/20)*10,self.x,self.y+6,0.75,90,60,0.5,0.5,Color(0x80FFFFFF),Color(0x00FFFFFF))
		var.score=var.score+int(var.pointrate/20)*10
	end
end

function item.DropItem(x,y,drop)
	local m
	if lstg.var.power==400 then
		m = drop[1]
	elseif drop[1] >= 400 then
		m = drop[1]
	else
		m = drop[1] / 100 + drop[1] % 100
	end
	local n=m+drop[2]+drop[3]
	if n<1 then return end
	local r=sqrt(n-1)*5
	--if lstg.var.power==500 then drop[2]=drop[2]+drop[1] drop[1]=0 end
	if drop[1] >= 400 then
		local r2=sqrt(ran:Float(1,4))*r
		local a=ran:Float(0,360)
		New(item_power_full,x+r2*cos(a),y+r2*sin(a))
	else
		drop[4] = drop[1] / 100
		drop[1] = drop[1] % 100
		for i=1,drop[4] do
			local r2=sqrt(ran:Float(1,4))*r
			local a=ran:Float(0,360)
			New(item_power_large,x+r2*cos(a),y+r2*sin(a))
		end
		for i=1,drop[1] do
			local r2=sqrt(ran:Float(1,4))*r
			local a=ran:Float(0,360)
			New(item_power,x+r2*cos(a),y+r2*sin(a))
		end
	end
	for i=1,drop[2] do
		local r2=sqrt(ran:Float(1,4))*r
		local a=ran:Float(0,360)
		New(item_faith,x+r2*cos(a),y+r2*sin(a))
	end
	for i=1,drop[3] do
		local r2=sqrt(ran:Float(1,4))*r
		local a=ran:Float(0,360)
		New(item_point,x+r2*cos(a),y+r2*sin(a))
	end
end

item.sc_bonus_max=2000000
item.sc_bonus_base=1000000

function item:StartChipBonus()
	self.missed_in_chapter=false
	self.spelled_in_chapter=false
	self.ccced_in_chapter=false
end

function item:EndChipBonus(x,y)
	if (not self.missed_in_chapter) and (not self.spelled_in_chapter) and (not self.ccced_in_chapter) then--符卡或非符NMNBNC指针值-0.2
		DR_Pin.pin_shift(-0.2)
	else
		if (not self.spelled_in_chapter) and (not self.ccced_in_chapter) then DR_Pin.pin_shift(-0.05)end--如果不小心撞了-0.05
	end
end

function item.PlayerInit()
	lstg.var.power=100
	lstg.var.lifeleft=2
	lstg.var.bomb=2
	lstg.var.bonusflag=0
	lstg.var.chip=0
	lstg.var.graze=0
	lstg.var.faith=0
	lstg.var.score=0
	lstg.var.bombchip=0
	lstg.var.coun_num=0
	lstg.var.pointrate=item.PointRateFunc()
	lstg.var.collectitem={0,0,0,0,0,0}
	--lstg.var.itembar={0,0,0}
	lstg.var.block_spell=false
	--lstg.var.chip_bonus=false
	--lstg.var.bombchip_bonus=false
	
	lstg.var.missed_in_chapter = false--用于记录单chapter是否miss或放b
	lstg.var.spelled_in_chapter = false
	lstg.var.ccced_in_chapter = false
	
	lstg.var.init_player_data=true
end
------------------------------------------
function item.PlayerReinit()
	lstg.var.power=400
	lstg.var.lifeleft=2
	lstg.var.chip=0
	lstg.var.bomb=2
	lstg.var.bomb_chip=0
	lstg.var.block_spell=false
	lstg.var.init_player_data=true
	lstg.var.coun_num=min(9,lstg.var.coun_num+1)
	lstg.var.score=lstg.var.coun_num
	--if lstg.var.score % 10 ~= 9 then item.AddScore(1) end
end
------------------------------------------
--HZC的收点系统
function item.playercollect(n)
	New(tasker,function()
		local z=0
		local Z=0
		local var=lstg.var
		local f=nil
		local maxpri=-1
		for i,o in ObjList(GROUP_ITEM) do
			if o.attract>=8 and not o.collecting and not o.is_minor then
				local dx=player.x-o.x
				local dy=player.y-o.y
				local pri=abs(dy)/(abs(dx)+0.01)
				if pri>maxpri then maxpri=pri f=o end
				o.collecting=true
			end
		end
		for i=1,300 do
			if not(IsValid(f)) then break end
			task.Wait(1)
		end
		z=lstg.var.collectitem[n]
		local x=player.x
		local y=player.y
		if z>=0 and z<40 then Z=1.0
		elseif z<60 then Z=1.5
		elseif z<80 then Z=2.4
		elseif z<100 then Z=3.6
		elseif z<120 then Z=5.0
		elseif z>=120 then Z=8.0 end
		if z>=5 and z<20 then
			task.Wait(15)
			New(float_text2,'bonus','NO BONUS',x,y+60,0,90,120,0.5,0.5,Color(0xF0B0B0B0),Color(0x00B0B0B0))
		elseif z>=20 and z<40 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFF29E8E8),Color(0x0029E8E8))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFF29E8E8),Color(0x0029E8E8))
			var.faith=var.faith+Z*z*20
		elseif z>=40 and z<60 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFF29E8E8),Color(0x0029E8E8))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFF29E8E8),Color(0x0029E8E8))
			var.faith=var.faith+Z*z*20
		elseif z>=60 and z<80 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFF44FFA1),Color(0x0044FFA1))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFF44EEA1),Color(0x0044EEA1))
			var.faith=var.faith+Z*z*20
		elseif z>=80 and z<100 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFF44FFA1),Color(0x0044FFA1))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFF44FFA1),Color(0x0044FFA1))
			var.faith=var.faith+Z*z*20
		elseif z>=100 and z<120 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFFFFFF00),Color(0x00FFFF00))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFFFFFF00),Color(0x00FFFF00))
			var.faith=var.faith+Z*z*20
		elseif z>=120 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFFFF4422),Color(0x00FF4422))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFFFF4422),Color(0x00FF4422))
			var.faith=var.faith+Z*z*20
		end
		lstg.var.collectitem[n]=0
	end)

end
-----------------------------
function item:PlayerMiss()
--	lstg.var.chip_bonus=false
	lstg.var.missed_in_chapter=true
	if lstg.var.sc_bonus then lstg.var.sc_bonus=0 end
	ex.ClearBonus(true,false)
	DR_Pin.reduce(4)
	self.protect=360
	lstg.var.lifeleft=lstg.var.lifeleft-1
	ui.menu.LoseLife=15
	--self.lifeleft=self.lifeleft-1
--	lstg.var.power=math.max(lstg.var.power-50,100)
	lstg.var.bomb=3
	--self.bomb=max(self.bomb,2)
--	if lstg.var.lifeleft>0 then
--		for i=1,7 do
--			local a=90+(i-4)*18+player.x*0.26
--			New(item_power,player.x,player.y+10,3,a)
--		end
--	else New(item_power_full,player.x,player.y+10) end
    lstg.var.bombchip=0
	self.SpellCardHp=0
end

function item.PlayerSpell()
	if lstg.var.sc_bonus then lstg.var.sc_bonus=0 end
	ex.ClearBonus(false,true)
	
	
	if player.death==0 then
		DR_Pin.pin_shift(2.0)
	else
		DR_Pin.pin_shift(3.0)--如果是决死的话就多加1
	end
--	lstg.var.bombchip_bonus=false
	player.spelled_in_chapter = true
end

function item.PlayerGraze()
	lstg.var.graze=lstg.var.graze+1
	if IsValid(_boss) then DR_Pin.add(0.2) else DR_Pin.add(0.1) end
	if player.graze_c<K_graze_c_max then player.graze_c=min(K_graze_c_max,player.graze_c + 1 + (lstg.var.dr * K_dr_graze_c)) end
	
--	lstg.var.score=lstg.var.score+50
end

--这一行是决定最大得点的地方
function item.PointRateFunc()
	local var=lstg.var
	local r=int(  (  10000 + int(var.graze/10)*10 + int(var.faith/10)*10  ) * (max((var.dr or -1)*-1,1))  /10)*10
	return r
end
