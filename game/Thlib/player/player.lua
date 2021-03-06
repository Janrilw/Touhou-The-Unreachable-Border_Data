LoadImageFromFile('graze_par','THlib\\player\\graze_par.png')
LoadImageFromFile('player_death_par','THlib\\player\\player_death_par.png')
LoadPS('player_death_ef','THlib\\player\\player_death_ef.psi','parimg1')
LoadPS('player_death_ef1','THlib\\player\\player_death_ef1.psi','player_death_par')
LoadPS('player_death_ef2','THlib\\player\\player_death_ef2.psi','player_death_par')
LoadPS('graze','THlib\\player\\graze.psi','graze_par')
LoadImageFromFile('player_spell_mask','THlib\\player\\spellmask.png')
for i=1,4 do LoadImageFromFile('player_indicator'..i,'THlib\\player\\player_indicator'..i..'.png') end
for i=1,3 do SetImageState('player_indicator'..i,'',Color(0x80FFFFFF)) end

LoadTexture('magicsquare','THlib\\player\\player_magicsquare.png')
LoadImageGroup('player_aura_3D','magicsquare',0,0,256,256,5,5)

LoadTexture('player','THlib\\player\\player.png')
LoadImageGroup('playerring1','player',80*4,0,16*4,8*4,1,16)
for i=1,16 do SetImageState('playerring1'..i,'mul+add',Color(0x80FFFFFF)) end
LoadImageGroup('playerring2','player',48*4,0,16*4,8*4,1,16)
for i=1,16 do SetImageState('playerring2'..i,'mul+add',Color(0x80FFFFFF)) end

LoadImageFromFile('base_spell_hp','THlib\\player\\ring00.png')
SetImageState('base_spell_hp','',Color(0xFFFF0000))
LoadTexture('spellbar','THlib\\player\\spellbar.png')
--LoadImage('spell_node','spellbar',20,0,12,16)
LoadImage('spellbar1','spellbar',4,0,2,2)
SetImageState('spellbar1','',Color(0xFFFFFFFF))
LoadImage('spellbar2','player',116,0,2,2)
SetImageState('spellbar2','',Color(0x77D5CFFF))

-----符卡环参数
	local ring_radius=180
	local ring_width=16
---------

----Base class of all player characters (abstract)----

local LOG_MODULE_NAME="[lstg][THlib][player]"
player_class=Class(object)

function player_class:init()
	--obj基本信息
	self.group=GROUP_PLAYER
	self.y=-176
	self.layer=LAYER_PLAYER

	self.supportx=0
	self.supporty=self.y
	self.hspeed=4
	self.lspeed=2
	self.collect_line=112
	self.slow=0
	self.lr=1
	self.lh=0
	self.fire=0
	self.lock=false
	self.dialog=false
	self.nextshoot=0
	self.nextspell=0
	self.A=0        --自机判定大小
	self.B=0
	self.item=1
	self.death=0
	self.protect=120
	
	--反转判定功能，最好在stagetask里使用
	self.reverse_colli=nil
	self.stay_safe=true

	self.graze_c=0
	self.graze_c_before=0
	self.ccc_state=1--指代必杀充能状态，1代表不能释放，2代表可以释放，3代表擦弹计数到达最大值
	self.offset=0.0 --灵击火力减损值
	self.SpellCardHp=0 --屏幕实际显示的符卡槽耐久数值
	self.SpellCardHpMax=tuolib.DRP_Sys.K_MaxSpell --当前最大耐久值
	self.NextSingleSpell=0 --符卡释放期间单次符卡攻击间隔
	self.SpellTimer1=-1 --用于符卡开始后帧计时
	self.KeyDownTimer1=0 --用于记录持续按压时长
	self.bomb_end=false --上一张符卡结束标志
	
	self.minPower=100 --灵力下限
	self.maxPower=400 --灵力上限
	self.PowerFlag=0 --随梦现指针变化的阶段标志，在（-5,5）范围内由-1至2变化
	self.PowerDelay1=-1 --上限减少时子机存留时间倒计时，-1表示没有在倒计时
	--self.PowerDelay2=-1 --【当出现连射灵击和符卡的情况时，有可能出现两个子机同时在减损中的状态】新方案决定当同时减损时直接去掉第一个在减损的子机
	self.SpellIndex=0
	self.SC_name=''
	
	self.itemcollect_dist=32 --道具收集范围半径
	self.ringX_aim,self.ringY_aim=self.x,self.y --用于显示自机符卡环的三组变量
	self.ringX,self.ringY=self.ringX_aim,self.ringY_aim
	self.ringR_aim,self.ringR=0,0
	self.ringW_aim,self.ringW=ring_width,ring_width
	self.ringWithdraw=false --自机被弹用
	
	-- New(DR_Pin)
	tuolib.DRP_Sys:init()
		
	lstg.player=self
	player=self
	self.grazer=New(grazer)
	if not lstg.var.init_player_data then error('Player data has not been initialized. (Call function item.PlayerInit.)') end
	self.support=int(lstg.var.power/100)
	self.sp={}
	self.time_stop=false
	
	self._wisys = PlayerWalkImageSystem(self)--by OLC，自机行走图系统
end

function player_class:frame()
	self.grazer.world=self.world
	--判断boss是否处在非符状态
		local boss_in_nonsc=IsValid(_boss) and (not boss.GetCurrentCard(_boss).is_sc) 
	
	--寻找目标
		if ((not IsValid(self.target)) or (not self.target.colli)) then player_class.findtarget(self) end
		if not KeyIsDown'shoot' then self.target=nil end

		if self.bomb_end and not KeyIsDown('spell') then self.bomb_end=false end
	
	--接下来将会使用的一些变量的定义
		local dx=0
		local dy=0
		local v=self.hspeed
	--非死亡状态时的逻辑
		if (self.death==0 or self.death>90) and (not self.lock) and not(self.time_stop) then
			--低速切换逻辑
				if KeyIsDown'slow' then self.slow=1 else self.slow=0 end
			--非对话期间逻辑（射击和符卡）
				if not self.dialog then
					--射击逻辑
						if KeyIsDown'shoot' and self.nextshoot<=0 then self.class.shoot(self) end

					--符卡逻辑
						if self.SpellCardHp==0 and self.SpellTimer1>=0 then self.SpellTimer1=-1 self.KeyDownTimer1=0 self.SC_name='' self.nextspell=90 self.bomb_end=true end
						if self.SpellCardHp>0 and self.SpellTimer1>90 then self.SpellCardHp=max(0,self.SpellCardHp-tuolib.DRP_Sys.K_SpellDecay) end
						if self.NextSingleSpell>0 then self.NextSingleSpell=self.NextSingleSpell-1 end
						if self.SpellTimer1>0 then self.SpellTimer1=self.SpellTimer1+1 end
						
						if self.SpellTimer1==90 then self.class.newSpell(self) end
						
						if KeyIsDown'spell' and not lstg.var.block_spell and not self.bomb_end then 
							if self.SpellTimer1>90 then self.KeyDownTimer1=self.KeyDownTimer1+1 end
							if (lstg.var.bomb>0 and self.death>90) or (self.SpellCardHp==0 and self.nextspell<=0 and self.NextSingleSpell==0 and lstg.var.bomb>0) then
								item.PlayerSpellCast()
								if self.slow==1 then self.SpellIndex=lstg.var.bomb+3
								else self.SpellIndex=lstg.var.bomb end
								
								if self.SpellIndex==1 then self.SC_name=self.cardname.high1 end
								if self.SpellIndex==2 then self.SC_name=self.cardname.high2 end
								if self.SpellIndex==3 then self.SC_name=self.cardname.high3 end
								if self.SpellIndex==4 then self.SC_name=self.cardname.low1 end
								if self.SpellIndex==5 then self.SC_name=self.cardname.low2 end
								if self.SpellIndex==6 then self.SC_name=self.cardname.low3 end
								
								lstg.var.bomb=lstg.var.bomb-1
								ui.menu.LoseSpell=15
								self.SpellCardHpMax=tuolib.DRP_Sys.K_MaxSpell+lstg.var.dr*tuolib.DRP_Sys.K_dr_SpellHp
								self.SpellCardHp=self.SpellCardHpMax
									
								self.SpellTimer1=1
								self.KeyDownTimer1=0
								PlaySound('cat00',0.7)
								self.class.spell(self)
								-- New(player_spell_mask,64,64,200,30,60,30)
								New(bullet_cleaner,player.x,player.y, 270, 60, 90, 1)
								self.protect=90
								
								self.death=0
								self.nextcollect=90
								self.NextSingleSpell=180
								self.nextspell=360
									
								ui.menu.HighlightFlag=30
							else if self.SpellCardHp>0 and self.NextSingleSpell==0 then
									item.PlayerSpellAttack()
									self.NextSingleSpell=90
									self.class.newSpell(self)
								end
							end
						else if self.KeyDownTimer1>0 then self.KeyDownTimer1=0 end
						end
					--必杀技逻辑（以前叫灵击）
						if self.graze_c>=tuolib.DRP_Sys.K_graze_c_min and self.graze_c_before<tuolib.DRP_Sys.K_graze_c_min then self.ccc_state=2 New(player_indicator_eff,2)
						elseif self.graze_c>=tuolib.DRP_Sys.K_graze_c_max and self.graze_c_before<tuolib.DRP_Sys.K_graze_c_max then self.ccc_state=3 New(player_indicator_eff,3) end
						self.graze_c_before=self.graze_c
						if KeyIsDown'special' and self.graze_c>=tuolib.DRP_Sys.K_graze_c_min and lstg.var.power>=100 and self.SpellTimer1==-1 then 
							item.PlayerCCC()
							self.offset = 100*(1.0 + tuolib.DRP_Sys.K_graze_c_k * (self.graze_c - tuolib.DRP_Sys.K_graze_c_min)) 
							New(bullet_cleaner,player.x,player.y, 125, 20, 45, 1)  New(player_indicator_explode,3) New(player_indicator_explode,1)
							GetPower(-self.offset)
							self.graze_c = 0
							PlaySound('ophide',0.1)
							self.protect=max(20,self.protect)
							self.class.ccc(self) -- 释放灵击
							self.ccc_state=1
						end
			--对话期间逻辑
				else self.nextshoot=15 self.nextspell=30 self.NextSingleSpell=30 end
			
			--自机移动逻辑
				if self.death==0 and not self.lock then
					if self.slowlock then self.slow=1 end
					if self.slow==1 then v=self.lspeed end
					if KeyIsDown'up' then dy=dy+1 end
					if KeyIsDown'down' then dy=dy-1 end
					if KeyIsDown'left' then dx=dx-1 end
					if KeyIsDown'right' then dx=dx+1 end
					if dx*dy~=0 then v=v*SQRT2_2 end
					self.x=self.x+v*dx
					self.y=self.y+v*dy		
				--[[本来想做全方向摇杆，但是实际操作起来由于阈值的关系仍然是八向摇杆的手感，因此作废
						local leftX,leftY,rightX,rightY=lstg.XInputManager.GetThumbState(1)
						local dx,dy=leftX/32768,leftY/32768
						local a=atan2(dy,dx)
						self.x=self.x+v*cos(a)
						self.y=self.y+v*sin(a)
						--]]
					--jstg的屎
						for i=1,#jstg.worlds do -----------------------------------------------------????????????????????
							if IsInWorld(self.world,jstg.worlds[i].world) then
								self.x=math.max(math.min(self.x,jstg.worlds[i].pr-8),jstg.worlds[i].pl+8)
								self.y=math.max(math.min(self.y,jstg.worlds[i].pt-32),jstg.worlds[i].pb+16)
							end
						end
					
				end
			--开火蓄力计时器
				if KeyIsDown'shoot' and not self.dialog then self.fire=self.fire+0.16 else self.fire=self.fire-0.16 end
				if self.fire<0 then self.fire=0 end
				if self.fire>1 then self.fire=1 end
			
			--火力残留计时器
				if self.PowerDelay1>0 then self.PowerDelay1=self.PowerDelay1-1 end
				--if self.PowerDelay2>0 then self.PowerDelay2=self.PowerDelay2-1 end --【旧方案】
			--火力上限变化
				if lstg.var.dr>=5 then self.maxPower=300
				else if lstg.var.dr<=-5 then self.maxPower=600 
				else if lstg.var.dr<=-2.5 then self.maxPower=500
				else self.maxPower=400 end end end
			--火力残留逻辑
				if lstg.var.power>self.maxPower then
					if lstg.var.power-self.maxPower>=100 then
						if self.PowerDelay1>=0 then
							PlaySound('enep02',0.3,self.x/200,true)
							local n=int(self.support)+1
							local r2=sqrt(ran:Float(1,4))
							local r1=ran:Float(0,360)
							New(item_power_mid,self.supportx+self.sp[n][1]+r2*cos(r1),self.supporty+self.sp[n][2]+r2*sin(r1))
						end
						self.PowerDelay1=180 self.support=self.support-1
					end
					lstg.var.power=self.maxPower
				end
				if self.PowerDelay1==0 then
					local n=int(self.support)+1
					PlaySound('enep02',0.3,self.x/200,true)
					local r4=sqrt(ran:Float(1,4))
					local r3=ran:Float(0,360)
				if self.supportx and self.sp[n][1] then 	
					New(item_power_mid,self.supportx+self.sp[n][1]+r4*cos(r3),self.supporty+self.sp[n][2]+r4*sin(r3)) end --修复崩溃的bug
					self.PowerDelay1=-1
				end

				
			--道具收集逻辑
				local dist_coe
				local line = 0.0
				if(lstg.var.dr<0) then 
					line = tuolib.DRP_Sys.K_dr_collectline
					dist_coe = 1 - tuolib.DRP_Sys.K_dr_dist*min(0,lstg.var.dr)  --dr值为负（现实侧）则增大道具收集范围，最大为(1+5*tuolib.DRP_Sys.K_dr_dist)，目前为最大两倍
				else 
					line=0
					dist_coe=1
				end
			--道具收集范围的平滑变化，其中56和24分别对应低速和高速收点基础范围
				if KeyIsDown'slow' then self.itemcollect_dist=self.itemcollect_dist+0.1*(56*dist_coe-self.itemcollect_dist)
				else self.itemcollect_dist=self.itemcollect_dist+0.1*(24*dist_coe-self.itemcollect_dist) end

				if self.y>(self.collect_line + line*lstg.var.dr) or (self.SpellTimer1>0 and self.SpellTimer1<=90) then
					for i,o in ObjList(GROUP_ITEM) do 
						local flag=false
						if o.attract<8 then
							flag=true			
						elseif o.attract==8 and o.target~=self then
							if (not o.target) or o.target.y<self.y then
								flag=true
							end
						end
						if flag then
							o.attract=8 o.num=self.item 
							o.target=self
						end
					end
				else
					if KeyIsDown'slow' then
						for i,o in ObjList(GROUP_ITEM) do
							if Dist(self,o)<self.itemcollect_dist then
								if o.attract<3 then
									o.attract=max(o.attract,3) 
									o.target=self
								end	
							end
						end
					else
						for i,o in ObjList(GROUP_ITEM) do
							if Dist(self,o)<self.itemcollect_dist then 
								if o.attract<3 then
									o.attract=max(o.attract,3) 
									o.target=self
								end	
							end
						end
					end
				end
			
			--符卡圈参数控制
				local k=0
				if self.SpellTimer1>0 and self.SpellCardHp and self.SpellCardHpMax then k=self.SpellCardHp/self.SpellCardHpMax end
				self.ringX_aim=player.x
				self.ringY_aim=player.y
				self.ringR_aim=ring_radius*k+ring_width
				self.ringW_aim=ring_width*(0.5+0.5*k)
				self.ringWithdraw=false
			--判定反转逻辑
			--由于core中objframe在collicheck之前，所以设为nil以防止设置参数的那一帧玩家直接biu
			if self.reverse_colli then
				if self.stay_safe then
					self.stay_safe=false
				elseif self.stay_safe==false then
					if self.death==0 and self.protect==0 and not self.dialog and not cheat then
						PlaySound('pldead00',0.5)
						self.death=100
					end
				elseif self.stay_safe==nil then
					self.stay_safe=false
				end
			else
				self.stay_safe=nil
			end
	--死亡计时器为90时的逻辑
		elseif self.death==90 then
			if self.time_stop then self.death=self.death-1 end
			item.PlayerMiss(self)
			
			if self.SpellTimer1>0 then 
				self.ringWithdraw=true
				if boss_in_nonsc then --自机被敌机收卡
					self.ringR_aim=ring_radius
					self.ringW_aim=ring_width
				else
					self.ringX_aim=player.x
					self.ringY_aim=player.y
					self.ringR_aim=0
					self.ringW_aim=0
				end
			end
			--lstg.var.power=max(0,lstg.var.power-50)
			GetPower(-50)
			New(player_death_ef,self.x,self.y,1)
			New(player_death_ef,self.x,self.y,2)
	--死亡计时器为84时的逻辑
		elseif self.death==84 then
			if self.time_stop then self.death=self.death-1 end
			-- self.hide=true
			self.support=int(lstg.var.power/100)
	--死亡计时器为65时的逻辑
		elseif self.death==65 then
			if not boss_in_nonsc then self.ringWithdraw=false end --自机收回符卡圈到这儿结束
			self.deathee={}
			self.deathee[1]=New(deatheff,self.x,self.y,'first')
			self.deathee[2]=New(deatheff,self.x,self.y,'second')
	--死亡计时器为50时的逻辑
		elseif self.death==50 then
			if self.time_stop then self.death=self.death-1 end
			self.x=0
			self.supportx=0
			self.y=-236
			self.supporty=-236
			self.hide=false
			New(bullet_deleter,self.x,self.y)
	--自机被弹后重新出现在屏幕上
		elseif self.death<50 and not(self.lock) and not(self.time_stop) then
			self.y=-176-1.2*self.death
		end
	--自机的符卡被boss收取的逻辑
		if boss_in_nonsc and self.death<90 and self.death>0 then 
			self.ringX_aim=_boss.x
			self.ringY_aim=_boss.y
			if self.death<65 then 
				local k=(self.death-1)/65
				self.ringR_aim=ring_radius*k
				self.ringW_aim=ring_width*k
			end
		end
	--by OLC，自机行走图系统	
		---加上time_stop的限制来实现图像时停
			if not(self._wisys) then
				self._wisys=PlayerWalkImageSystem(self)
			end
			if not(self.time_stop) then
				self._wisys:frame(dx)

				self.lh=self.lh+(self.slow-self.lh)*0.2
				-- if self.lh<0 then self.lh=0 end
				-- if self.lh>1 then self.lh=1 end
		--计时器和各种参数变换
				if self.nextshoot>0 then self.nextshoot=self.nextshoot-1 end
				if self.nextspell>0 then self.nextspell=self.nextspell-1 end

				if self.support>int(lstg.var.power/100) then self.support=self.support-0.0625
				elseif self.support<int(lstg.var.power/100) then self.support=self.support+0.0625 end
				if abs(self.support-int(lstg.var.power/100))<0.0625 then self.support=int(lstg.var.power/100) end

				self.supportx=self.x+(self.supportx-self.x)*0.6875
				self.supporty=self.y+(self.supporty-self.y)*0.6875

				if self.protect>0 then self.protect=self.protect-1 end --无敌时间减少，死亡计时减少
				if self.death>0 then self.death=self.death-1 end
		--刷新分数上限
				lstg.var.pointrate=item.PointRateFunc(lstg.var)
		--更新子机
				if self.slist then
					self.sp={}
					if self.support==7 then-------------------------------------------------?????????????????????????????????
						for i=1,6 do self.sp[i]=MixTable(self.lh,self.slist[8][i]) self.sp[i][3]=1 end
					else
						local s=int(self.support)+1
						if self.PowerDelay1>0 then s=s+1 end
						local t=self.support-int(self.support)
						for i=1,6 do
							if self.slist[s][i] and self.slist[s+1][i] then
								self.sp[i]=MixTable(t,MixTable(self.lh,self.slist[s][i]),MixTable(self.lh,self.slist[s+1][i]))
								self.sp[i][3]=1
							elseif self.slist[s+1][i] then
								self.sp[i]=MixTable(self.lh,self.slist[s+1][i])
								self.sp[i][3]=t
							end
						end
					end
				end
			end
	--时停
		if self.time_stop then self.timer=self.timer-1 end
	--符卡环参数的丝滑
		local dx=self.ringX-self.ringX_aim
		local dy=self.ringY-self.ringY_aim
		local dr=self.ringR-self.ringR_aim
		local dw=self.ringW-self.ringW_aim
		if abs(dx)<0.5 	then self.ringX=self.ringX_aim else self.ringX=self.ringX+(self.ringX_aim-self.ringX)*0.15 end --符卡圈每帧都会向自机靠近7%，如果距离只有0.5则直接贴脸
		if abs(dy)<0.5 	then self.ringY=self.ringY_aim else self.ringY=self.ringY+(self.ringY_aim-self.ringY)*0.15 end
		if abs(dr)<1 	then self.ringR=self.ringR_aim else self.ringR=self.ringR+(self.ringR_aim-self.ringR)*0.07 end
		if abs(dw)<0.05 then self.ringW=self.ringW_aim else self.ringW=self.ringW+(self.ringW_aim-self.ringW)*0.07 end
	--梦现指针系统帧逻辑
		tuolib.DRP_Sys:frame()
end

function player_class:render()
	SetImageState('player_indicator'..self.ccc_state,'',Color(0x80FFFFFF))
	Render('player_indicator'..self.ccc_state,self.x,self.y,self.ani*0.5,self.itemcollect_dist/112)
	-- misc.Renderhp(self.x,self.y,0,360,self.itemcollect_dist,self.itemcollect_dist+2,32,1)	 --测试用
	self._wisys:render()--by OLC，自机行走图系统
	
	if self.SpellCardHp>0 or self.ringWithdraw then
		-- for i=1,25 do SetImageState('player_aura_3D'..i,'mul+add',Color(255,255,255,255)) end
	    -- Render('player_aura_3D'..self.ani%25+1,self.x,self.y,self.ani*0.75,0.6,0.6+0.05*sin(90+self.ani*0.75)) --名字，中心点xy，旋转度，xy缩放，z轴深度默认0.5
	    local alpha=255* min(1,(self.ringR/ring_radius)*2) --也就是说自机符卡血量低于50%之后符卡环会越来越透明
			for i=1,16 do SetImageState('playerring1'..i,'mul+add',Color(alpha,255,255,255)) end
			for i=1,16 do SetImageState('playerring2'..i,'mul+add',Color(alpha,255,255,255)) end
		if self.SpellTimer1<=90 then
			local k=self.SpellTimer1/90
		    misc.RenderRing('playerring1',self.x,self.y,
				ring_radius*k+ring_radius*0.75*sin(180*k),
				ring_radius*k+ring_radius*0.75*sin(180*k)+ring_width,
				self.ani*3,32,16)
		    misc.RenderRing('playerring2',self.x,self.y,
				ring_radius*0.5+ring_radius*0.5*k,
				-ring_radius+ring_radius*2*k-ring_width,
				-self.ani*3,32,16)
			self.ringR=ring_radius--强行锁定为最大值，以便之后平滑过渡
		else
			--这里完全由那些参数控制
			misc.RenderRing('playerring1',self.ringX,self.ringY,self.ringR,self.ringR+self.ringW, self.ani*3*2,32,16)
			misc.RenderRing('playerring2',self.ringX,self.ringY,self.ringR,self.ringR-self.ringW, self.ani*3*2,32,16)		
		end

        Renderspellbar(self.x,self.y,90,360,60,64,360,1)
		Renderspellhp(self.x,self.y,90,360*self.SpellCardHp/self.SpellCardHpMax,60,64,360*self.SpellCardHp/self.SpellCardHpMax+2,1)
		Render('base_spell_hp',self.x,self.y,0,0.548,0.548)
        Render('base_spell_hp',self.x,self.y,0,0.512,0.512)
		-- Render('life_node',self.x-63*cos(tuolib.DRP_Sys.K_SpellCost/self.SpellCardHpMax),self.y+63*sin(tuolib.DRP_Sys.K_SpellCost/self.SpellCardHpMax),tuolib.DRP_Sys.K_SpellCost/self.SpellCardHpMax-90,1.1)
	end
end

function player_class:colli(other)
	if self.death==0 and not self.dialog and not cheat then
		if not self.reverse_colli then
			if self.protect==0 then
				PlaySound('pldead00',0.5)
				self.death=100
			end
			if other.group==GROUP_ENEMY_BULLET then Del(other) end
		else
			self.stay_safe=true
		end
	end
end

function player_class:findtarget()
	self.target=nil
	local maxpri=-1
	for i,o in ObjList(GROUP_ENEMY) do
		if o.colli then
			local dx=self.x-o.x
			local dy=self.y-o.y
			local pri=abs(dy)/(abs(dx)+0.01)
			if pri>maxpri then maxpri=pri self.target=o end
		end
	end
	for i,o in ObjList(GROUP_NONTJT) do
		if o.colli then
			local dx=self.x-o.x
			local dy=self.y-o.y
			local pri=abs(dy)/(abs(dx)+0.01)
			if pri>maxpri then maxpri=pri self.target=o end
		end
	end
end

function player_class:SpellClear()
	if self.SpellCardHp>0 then
		lstg.var.bombchip=lstg.var.bombchip+self.SpellCardHp/tuolib.DRP_Sys.K_MaxSpell*0.4
		self.SpellCardHp=0
		self.SpellTimer1=-1
		self.KeyDownTimer1=0
		self.SC_name=''
	end
end

function Renderspellhp(x,y,rot,la,r1,r2,n,c)
	local da=la/n
	local nn=int(n*c)
	for i=1,nn do
		local a=rot+da*i
		Render4V('spellbar1',
			r1*cos(a+da)+x,r1*sin(a+da)+y,0.5,
			r2*cos(a+da)+x,r2*sin(a+da)+y,0.5,
			r2*cos(a)+x,r2*sin(a)+y,0.5,
			r1*cos(a)+x,r1*sin(a)+y,0.5)
	end
end
function Renderspellbar(x,y,rot,la,r1,r2,n,c)
	local da=la/n
	local nn=int(n*c)
	for i=1,nn do
		local a=rot+da*i
		Render4V('spellbar2',
			r1*cos(a+da)+x,r1*sin(a+da)+y,0.5,
			r2*cos(a+da)+x,r2*sin(a+da)+y,0.5,
			r2*cos(a)+x,r2*sin(a)+y,0.5,
			r1*cos(a)+x,r1*sin(a)+y,0.5)
	end
end

function MixTable(x,t1,t2)
	r={}
	local y=1-x
	if t2 then
		for i=1,#t1 do
			r[i]=y*t1[i]+x*t2[i]
		end
		return r
	else
		local n=int(#t1/2)
		for i=1,n do
			r[i]=y*t1[i]+x*t1[i+n]
		end
		return r
	end
end

grazer=Class(object)

function grazer:init(player)
	self.layer=LAYER_ENEMY_BULLET_EF+50
	self.group=GROUP_PLAYER
	self.player=player or lstg.player
	self.grazed=false
	self.graze_count=0
	self.img='graze'
	ParticleStop(self)
	self.a=32
	self.b=32
	self.aura=0
	self.aura_timer=0
end

function grazer:frame()
	self.x=self.player.x
	self.y=self.player.y
	self.hide=self.player.hide
	if not self.player.time_stop then
		if self.player.slow==1 then
			self.aura_timer=self.aura_timer+1
			if self.aura_timer>15 then
				self.aura=self.aura+sin(min(60,self.aura_timer-15)/60*90)*1.5
			end
		else
			self.aura_timer=0
		end
		
	end
	--
	if self.grazed then
		PlaySound('graze',0.3,self.x/200)
		self.grazed=false
		ParticleSetEmission(self,self.graze_count*60)
		self.graze_count=0
		ParticleFire(self)
	else ParticleStop(self) end
end

local scale=0
function grazer:render()
	scale=sin(90*self.player.lh)
	object.render(self)
	SetImageState('player_aura','',Color(0xFFFFFFFF)*self.player.lh+Color(0x00FFFFFF)*(1-self.player.lh))
	Render('player_aura',self.x,self.y, self.aura,(2-scale))
	SetImageState('player_aura','',Color(0xFFFFFFFF))
	Render('player_aura',self.x,self.y,-self.aura,scale)
	if player.death<50 then

		scale=(1-sqrt(sqrt(1/player.protect)))*2+1
		scale=1+0.5*sin(90*min(3,player.protect/30)/3)

		SetImageState('player_indicator4','mul+add',Color(255*min(1,player.protect/10),255,255,255))
		Render('player_indicator4',self.x,self.y,self.timer*2,scale)
		SetImageState('player_indicator4','',Color(75*min(1,player.protect/10),255,255,255))
		Render('player_indicator4',self.x,self.y,self.timer*2,scale)
	elseif player.death<90 then
		if player.death>75 then
			local k=1-(player.death-75)/25
			SetImageState('player_indicator4','mul+add',Color(255*(1-k),255,255,255))
			Render('player_indicator4',self.x,self.y,self.timer*2,k*5)
		end
		do
			local k=1-(player.death-50)/40
			SetImageState('player_indicator4','mul+add',Color(255*(1-k),255,255,255))
			Render('player_indicator4',self.x,self.y,self.timer*2,k*5)
		end
	end
end

function grazer:colli(other)
	if other.group~=GROUP_ENEMY and (not other._graze) then
		item.PlayerGraze()
		--lstg.player.grazer.grazed=true
		self.grazed=true
		if not ext.sc_pr then self.graze_count=self.graze_count+1 end
		other._graze=true
	end
end

player_bullet_straight=Class(object)

function player_bullet_straight:init(img,x,y,v,angle,dmg)
	self.group=GROUP_PLAYER_BULLET
	self.layer=LAYER_PLAYER_BULLET
	self.img=img
	self.x=x
	self.y=y
	self.rot=angle
	self.vx=v*cos(angle)
	self.vy=v*sin(angle)
	self.dmg=dmg
	if self.a~=self.b then self.rect=true end
end

player_bullet_hide=Class(object)

function player_bullet_hide:init(a,b,x,y,v,angle,dmg,delay)
	self.group=GROUP_PLAYER_BULLET
	self.layer=LAYER_PLAYER_BULLET
	self.colli=false
	self.a=a
	self.b=b
	self.x=x
	self.y=y
	self.rot=angle
	self.vx=v*cos(angle)
	self.vy=v*sin(angle)
	self.dmg=dmg
	self.delay=delay or 0
end

function player_bullet_hide:frame()
	if self.timer==self.delay then self.colli=true end
end

player_bullet_trail=Class(object)

function player_bullet_trail:init(img,x,y,v,angle,target,trail,dmg)
	self.group=GROUP_PLAYER_BULLET
	self.layer=LAYER_PLAYER_BULLET
	self.img=img
	self.x=x
	self.y=y
	self.rot=angle
	self.v=v
	self.target=target
	self.trail=trail
	self.dmg=dmg
end

function player_bullet_trail:frame()
	if IsValid(self.target) and self.target.colli then
		local a=math.mod(Angle(self,self.target)-self.rot+720,360)
		if a>180 then a=a-360 end
		local da=self.trail/(Dist(self,self.target)+1)
		if da>=abs(a) then self.rot=Angle(self,self.target)
		else self.rot=self.rot+sign(a)*da end
	end
	self.vx=self.v*cos(self.rot)
	self.vy=self.v*sin(self.rot)
end

player_spell_mask=Class(object)

function player_spell_mask:init(r,g,b,t1,t2,t3)
	self.x=0
	self.y=0
	self.group=GROUP_GHOST
	self.layer=LAYER_BG+1
	self.img='player_spell_mask'
	self.bcolor={['blend']='mul+add',['a']=0,['r']=r,['g']=g,['b']=b}
	task.New(self,function()
		for i=1,t1 do
			-- SetImageState('player_spell_mask','mul+add',Color(i*255/t1,r,g,b))
			self.bcolor.a=i*255/t1
			task.Wait(1)
		end
		task.Wait(t2)
		for i=t3,1,-1 do
			-- SetImageState('player_spell_mask','mul+add',Color(i*255/t3,r,g,b))
			self.bcolor.a=i*255/t3
			task.Wait(1)
		end
		Del(self)
	end)
end

function player_spell_mask:frame()
	task.Do(self)
end

function player_spell_mask:render()
	local w=lstg.world
	local c=self.bcolor
	SetImageState(self.img,c.blend,Color(c.a,c.r,c.g,c.b))
	RenderRect(self.img,w.l,w.r,w.b,w.t)
end

player_death_ef=Class(object)

function player_death_ef:init(x,y,i)
	self.x=x self.y=y self.img='player_death_ef' self.layer=LAYER_PLAYER+50 if i then self.img='player_death_ef'..i end
end

function player_death_ef:frame()
	if self.timer==25 then ParticleStop(self) end
	if self.timer==60 then Del(self) end
end

--death_ef
deatheff=Class(object)

function deatheff:init(x,y,type_)
	self.x=x
	self.y=y
	self.type=type_
	self.size=0
	self.size1=0
	self.layer=LAYER_TOP-1
	task.New(self,function()
		local size=0
		local size1=0
		if self.type=='second' then task.Wait(35) end--【修改标记】原先是30
		for i=1,360 do
			self.size=size
			self.size1=size1
			size=size+18--【修改标记】原先是12
			size1=size1+12--【修改标记】原先是8
			task.Wait(1)
		end
	end)
end

function deatheff:frame()
	task.Do(self)
	if self.timer>180 then Del(self) end
end

function deatheff:render()
    --稍微减少了死亡反色圈的分割数，视觉效果基本不变，减少性能消耗（原分割数为180）
	if self.type=='first' then
		rendercircle(self.x,self.y,self.size,60)
		rendercircle(self.x+35,self.y+35,self.size1,60)
		rendercircle(self.x+35,self.y-35,self.size1,60)
		rendercircle(self.x-35,self.y+35,self.size1,60)
		rendercircle(self.x-35,self.y-35,self.size1,60)
	elseif self.type=='second' then
		rendercircle(self.x,self.y,self.size,60)
	end
end
---
---指示必杀充能
player_indicator_eff=Class(object)

function player_indicator_eff:init(index)
	self.img='player_indicator'..index
	self.index=index
	self.layer=LAYER_PLAYER+1
	self.group=GROUP_GHOST
	self.x=player.x self.y=player.y
end
function player_indicator_eff:frame() 
	if self.timer==60 then RawDel(self) end
	self.x=player.x self.y=player.y
	self.scale=1+self.timer/60
end

function player_indicator_eff:render() 	
	SetImageState(self.img,'mul+add',Color(255*(1-self.timer/60),255,255,255))
	Render(self.img,self.x,self.y,0,self.scale*player.itemcollect_dist/122) 
end

player_indicator_explode=Class(object)

function player_indicator_explode:init(index)
	self.img='player_indicator'..index
	self.index=index
	self.layer=LAYER_PLAYER+1
	self.group=GROUP_GHOST
	self.x=player.x self.y=player.y
end
function player_indicator_explode:frame() 
	if self.timer==20 then RawDel(self) end
	self.x=player.x self.y=player.y
	if self.index==1 then self.scale=1+(1-self.timer/20)*0.5
	else self.scale=1+self.timer/20*0.5
	end
end

function player_indicator_explode:render() 	
	if self.index==1 then
		if self.timer<10 then 	SetImageState(self.img,'mul+add',Color(255*(self.timer/10),255,255,255))
		else 					SetImageState(self.img,'mul+add',Color(255*(1-(self.timer-10)/10),255,255,255)) end
	else
		SetImageState(self.img,'mul+add',Color(255*(1-self.timer/20),255,255,255))
	end
	local s=(player.itemcollect_dist/122)+(2-player.itemcollect_dist/122)*(self.scale-1)
	Render(self.img,self.x,self.y,0,s)
	
end


--列表里的三项分别代表被展示名称，类名和类的name值
player_list={
	{"博丽灵梦 A型","reimu_playerA","ReimuA"},
	{"博丽灵梦 B型","reimu_playerB","ReimuB"},
	{"雾雨魔理沙 A型","marisa_playerA","MarisaA"},
	{"雾雨魔理沙 B型","marisa_playerB","MarisaB"},
	{"东风谷早苗 A型","sanae_playerA","SanaeA"},
	{"东风谷早苗 B型","sanae_playerB","SanaeB"},
	{"宇佐见堇子 A型","sumireko_playerA","SumirekoA"},
	{"宇佐见堇子 B型","sumireko_playerB","SumirekoB"},
}