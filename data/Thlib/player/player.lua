LoadPS('player_death_ef','THlib\\player\\player_death_ef.psi','parimg1')
LoadPS('graze','THlib\\player\\graze.psi','parimg6')
LoadImageFromFile('player_spell_mask','THlib\\player\\spellmask.png')

LoadTexture('magicsquare','THlib\\player\\player_magicsquare.png')
LoadImageGroup('player_aura_3D','magicsquare',0,0,256,256,5,5)

LoadTexture('player','THlib\\player\\player.png')
LoadImageGroup('playerring1','player',80,0,16,8,1,16)
for i=1,16 do SetImageState('playerring1'..i,'mul+add',Color(0x80FFFFFF)) end
LoadImageGroup('playerring2','player',48,0,16,8,1,16)
for i=1,16 do SetImageState('playerring2'..i,'mul+add',Color(0x80FFFFFF)) end

LoadImageFromFile('UI_gaming_item_collect_word','THlib\\UI\\UI_gaming_item_collect_word.png')
LoadImageFromFile('UI_gaming_item_collect_line','THlib\\UI\\UI_gaming_item_collect_line.png')

LoadImageFromFile('base_spell_hp','THlib\\player\\ring00.png')
SetImageState('base_spell_hp','',Color(0xFFFF0000))
LoadTexture('spellbar','THlib\\player\\spellbar.png')
--LoadImage('spell_node','spellbar',20,0,12,16)
LoadImage('spellbar1','spellbar',4,0,2,2)
SetImageState('spellbar1','',Color(0xFFFFFFFF))
LoadImage('spellbar2','player',116,0,2,2)
SetImageState('spellbar2','',Color(0x77D5CFFF))

----Base class of all player characters (abstract)----

DR_Pin=Class(object)
function DR_Pin:init()
	local var=lstg.var
	local tmpv=lstg.tmpvar
	self.group=GROUP_GHOST
	self.layer=LAYER_TOP
	self.x=0
	self.y=0
	var.dr=0.01--��(dream)��(reality)ָ��ֵ
	var.cp=0.0--combo_point ������������������dr�ļ���
	tmpv.bonus_count=0
	C_BOUNS_LIMIT_IN_CHAPTER=5000
	K_dr=0.003--���ڿ���dr��������ÿ��chapter���ܶ�Ҫ΢�������Լ���lstg.var����
	

	K_dr_ccced=1.0 --�ͷ����ʱ����ָ���������
	K_dr_item=1.0  --��©��������ָ��仯ϵ��
	K_dr_enemy=1.0 --��©�л�����ָ��仯ϵ��
	K_graze_c_max=125 --������������
	K_graze_c_min=50 --������������
	K_dr_graze_c=0.04  --����ϵ��
	K_graze_c_k=(-0.75)/(K_graze_c_max - K_graze_c_min) --�ͷ����POWWER���ٱ���
	K_dr_collectline=22.4 --����ָ��ָ����ʵ��ʱ�յ��߽���ϵ��
	K_dr_dist=0.2 --����ָ��ָ����ʵ��ʱ�������շ�Χ���ϵ��
	K_dr_SpellDmg=0.02 --����ָ��Է����˺�Ӱ��ϵ��
	K_dr_SlowSpell=1.25 + K_dr_SpellDmg*var.dr --���ٷ����˺�
	K_dr_HighSpell=1.0 + K_dr_SpellDmg*var.dr --���ٷ����˺�
	K_dr_BonusLimit=1.0 --��ý��н�����������ָ�����ֵ
	
	K_MaxSpell=60 --�������;����ֵ����ֵ
	K_dr_SpellHp=3 --����ָ��Է������;����ֵ��Ӱ��ϵ��
	K_SpellCost=20 --���η����������ĵķ������;�
	K_SpellDecay=0.1 --ÿ֡�������;�˥��ϵ��
	
	K_cp=0.2
	K_dr_reduce=0.002
	
	self.collectline_a=255 --�յ��ߦ�ֵ
	self.k_a=(255-100)/(K_dr_collectline*5) --��ֵ�ı�ϵ��
	self.collectline_y=112
	self.collectline_dy=112
	
	end
function DR_Pin.add(v)--���������������������������ӻ�������ָ������ǰ����ƫ
	local var=lstg.var
	v = abs(v)
	var.cp = var.cp + v * K_cp
	 if (abs(var.dr)<=5.0 - v * K_dr) then 
		var.dr =  ( abs(var.dr) + v * K_dr ) * sign(var.dr)
	 else
		var.dr = sign(var.dr) * 5.0
	 end --����dr����������������
end
function DR_Pin.reduce(v)
	local var=lstg.var
	var.dr=max(0.01,abs(var.dr)-v)*sign(var.dr)
end
function DR_Pin.reset()--�ؿ������̶�����õĺ���
	local var=lstg.var
	local tmpv=lstg.tmpvar
	lstg.var.cp=1.0--������������
	lstg.tmpvar.bonus_count=0--���ý��н��׼�������������

	if not var.spelled_in_chapter and not var.ccced_in_chapter then--һ��һ����Ť�����ǻ��x���ٵ��ģ����Լ�ʹ��chapterMiss��Ҳ��һ��ƫ��
		DR_Pin.pin_shift(-0.15)
		if not var.missed_in_chapter then DR_Pin.pin_shift(-0.8) end
	end
	var.missed_in_chapter=false
	var.spelled_in_chapter=false
	var.ccced_in_chapter=false
end
function DR_Pin.pin_shift(v)
	local var=lstg.var
	if abs(var.dr+v)<=5.0 then
		var.dr = var.dr + v
	else
		var.dr=sign(var.dr)*5.0
	end
end
function DR_Pin:frame() 
	local var=lstg.var
	local tmpv=lstg.tmpvar
	tmpv.bonus_rate=0--����Ǿ���Ľ��н�����
	
	if not player.dialog then
		--�����cp���ٵĴ���
		if (var.cp <=15.0 and var.cp>5.0) then
			var.cp = var.cp-0.2
		elseif (var.cp <= 5.0 and var.cp>1.8) then
			var.cp = var.cp-0.04
		elseif (var.cp <=1.8 and var.cp>=0.008) then
			var.cp = var.cp-0.008--����125֡cp����
		else
			var.cp = 0.0
		end
		local drReduce=K_dr_reduce
		if IsValid(_boss) then drReduce=K_dr_reduce/2 else drReduce=K_dr_reduce end
		if (var.cp<=1 and abs(var.dr)>1-	(1-var.cp) * drReduce) then--combo_pointС��1��dr����1�������d�Żὥ����С����Խ�ӽ�1����Խ��
			var.dr = (abs(var.dr)-			(1-var.cp) * drReduce) * sign(var.dr)
		end --ddrΪ0ʱ��dr�������
		
		--����Ǹ���Դ�Ĵ���
		--�����˵��½������Դ����ֵ��ʵ�ʵ����޻�����ָ����ı�
		if abs(var.dr) >= K_dr_BonusLimit then
			tmpv.bonus_count=tmpv.bonus_count+(abs(var.dr)-K_dr_BonusLimit)--ָ�����ֵ������н�����ֵ�Ĳ��ֻ�ֱ�Ӽӵ��������������
			--���影��������(2,4)��������ڷֲ���ƫ�ξ��������3��ƫ��ʵ����С��3������ƫ������ָ��ֵ����
			--�ڴ˻����ϳ�һ��ϵ����������������ϵ���������
			--( C_BOUNS_LIMIT_IN_CHAPTER   -   tmpv.bonus_count )   /   C_BOUNS_LIMIT_IN_CHAPTER
			--Ҳ����һ��[0,1]�ڵ�ϵ����bonus_countԽ�����ϵ��ԽС������󼸺�Ϊ0
			--��һ�д���ܳ���������˼·��������Ӧ���ܿ�����
			if tmpv.bonus_count>C_BOUNS_LIMIT_IN_CHAPTER then tmpv.bonus_count=C_BOUNS_LIMIT_IN_CHAPTER end
			tmpv.bonus_rate = (  3.0 + sign(var.dr)*  (abs(var.dr)-K_dr_BonusLimit)/(5 - K_dr_BonusLimit) )* (C_BOUNS_LIMIT_IN_CHAPTER-tmpv.bonus_count)/C_BOUNS_LIMIT_IN_CHAPTER
			
			var.chip = var.chip + tmpv.bonus_rate 			* 0.01 	*(1 + min(0,sign(var.dr))* -1.5)
			var.bombchip = var.bombchip + tmpv.bonus_rate 	* 0.01 	*(1 + max(0,sign(var.dr))*0.5)
																	--��һ�Σ���ƫ����ʵ����л�������2.5������ƫ���ξ��������������1.5��
		end
		--����Ǽ������Ĵ���
		if abs(var.dr) >= 1.0 then
			GetPower(min((abs(var.dr)-1.0),2.0) * (-2 + sign(var.dr)) / -10 * 0.25) 
		end
	end
end
function DR_Pin:render() --���½�������Ⱦ
	local var=lstg.var
	local x,y=-182,-204
	SetImageState('white','',Color(255,255*0.75+var.dr*0.05,125,255*7/8-var.dr*0.025))
	RenderText('bonus','Pin_of_dream&reality:'..var.dr,x,y,0.35,8)
	RenderRect('white',x+25,x+25+var.dr*5,y-12,y-10)
	SetImageState('white','',Color(255,255,255,255))
	RenderText('bonus','combo_point:'..var.cp,x,y+20,0.35,8)
	RenderRect('white',x,x+var.cp,y+8,y+10)
	RenderText('bonus','graze_count:'..player.graze_c,x,y+40,0.35,8)
	RenderRect('white',x,x+player.graze_c,y+28,y+30)
	
	RenderText('bonus','SpellCard:'..player.SpellCardHp,x,y+60,0.35,8) --������
	RenderRect('white',x,x+player.SpellCardHp,y+48,y+50)
	
	
	--------�յ�������
	if self.timer<60 and self.timer%20==0 then 
		SetImageState('UI_gaming_item_collect_word','',Color(255,255,255,255))
	elseif self.timer<60 and (self.timer+10)%20==0 then 
		SetImageState('UI_gaming_item_collect_word','',Color(155,255,255,255))
	elseif self.timer>=60 and self.timer<=120 then
		SetImageState('UI_gaming_item_collect_word','',Color(255-int((self.timer-60)/60*255),255,255,255))
		Render('UI_gaming_item_collect_word',0,player.collect_line+22) 
	end
	--------------------�յ���ֻҪ�б䶯�ͻ�����͸���䣬�����������͸��
	local y=min(112,player.collect_line+lstg.var.dr*K_dr_collectline)
	self.collectline_y = self.collectline_y + (y - self.collectline_y)*0.25--ƽ������
	self.collectline_a=max(20,min(200,self.collectline_a	-3	+abs(self.collectline_dy-self.collectline_y)*100)) --alpha������20��200
	self.collectline_dy=self.collectline_y
	SetImageState('UI_gaming_item_collect_line','',Color(self.collectline_a,255,255,255))
	Render('UI_gaming_item_collect_line',0,self.collectline_y)
	
	--------------------
	-- if lstg.var.dr<0 then
	    -- local a=255-(self.k_a*abs(lstg.var.dr)*K_dr_collectline)
		-- local y=player.collect_line-abs(lstg.var.dr)*K_dr_collectline
		-- if self.collectline_a>a then self.collectline_a=max(self.collectline_a-1,a)
		-- else self.collectline_a=min(self.collectline_a+1,a) end
		-- if self.collectline_y>y then self.collectline_y=max(self.collectline_y-0.5,y)
		-- else self.collectline_y=min(self.collectline_y+0.5,y) end
		-- SetImageState('UI_gaming_item_collect_line','',Color(self.collectline_a,255,255,255))
		-- Render('UI_gaming_item_collect_line',0,self.collectline_y)
	-- else
	    -- if self.collectline_a==255 and self.collectline_y==player.collect_line then
		    -- Render('UI_gaming_item_collect_line',0,player.collect_line)
		-- else
		    -- if self.collectline_a~=255 then self.collectline_a=min(self.collectline_a+1,255) end
			-- if self.collectline_y~=player.collect_line then self.collectline_y=min(self.collectline_y+0.5,player.collect_line) end
			-- SetImageState('UI_gaming_item_collect_line','',Color(self.collectline_a,255,255,255))
			-- Render('UI_gaming_item_collect_line',0,self.collectline_y)
		-- end
	-- end
end

bonus_par=Class(object)
function bonus_par:init(x,y,n)
	self.x=x self.y=y
	self.img='itembar_par'..n
	self.group=GROUP_GHOST
	self.layer=LAYER_TOP
end
function bonus_par:frame()
	if self.timer>8 then ParticleStop(self) end
	if self.timer>60 then Del(self) end
end
function bonus_par:render()
	object.render(self)
end

local LOG_MODULE_NAME="[lstg][THlib][player]"
player_class=Class(object)

function player_class:init()
	self.group=GROUP_PLAYER
	self.y=-176
	self.supportx=0
	self.supporty=self.y
	self.hspeed=4
	self.lspeed=2
	self.collect_line=112
	self.slow=0
	self.layer=LAYER_PLAYER
	self.lr=1
	self.lh=0
	self.fire=0
	self.lock=false
	self.dialog=false
	self.nextshoot=0
	self.nextspell=0
	self.A=4        --�Ի��ж���С
	self.B=4
	--self.nextcollect=0--HZC�յ�ϵͳ�����ˡ�
	self.item=1
	self.death=0
	self.protect=120
	
	self.graze_c=0
	self.offset=0.0 --�����������ֵ
	self.SpellCardHp=0 --��Ļʵ����ʾ�ķ������;���ֵ
	self.SpellCardHpMax=K_MaxSpell --��ǰ����;�ֵ
	self.NextSingleSpell=0 --�����ͷ��ڼ䵥�η����������
	self.SpellTimer1=-1 --���ڷ�����ʼ��֡��ʱ
	self.KeyDownTimer1=0 --���ڼ�¼������ѹʱ��
	
	self.maxPower=400 --��������
	self.PowerFlag=0 --������ָ��仯�Ľ׶α�־���ڣ�-5,5����Χ����-1��2�仯
	self.PowerDelay1=-1 --���޼���ʱ�ӻ�����ʱ�䵹��ʱ��-1��ʾû���ڵ���ʱ
	--self.PowerDelay2=-1 --����������������ͷ��������ʱ���п��ܳ��������ӻ�ͬʱ�ڼ����е�״̬���·���������ͬʱ����ʱֱ��ȥ����һ���ڼ�����ӻ�
	self.SpellIndex=0
	self.SC_name=''
	
	New(DR_Pin)
		
	lstg.player=self
	player=self
	self.grazer=New(grazer)
	if not lstg.var.init_player_data then error('Player data has not been initialized. (Call function item.PlayerInit.)') end
	self.support=int(lstg.var.power/100)
	self.sp={}
	self.time_stop=false
	--New(item_bar)
	
	--RunSystem("on_player_init",self)
	
	self._wisys = PlayerWalkImageSystem(self)--by OLC���Ի�����ͼϵͳ
	
	--self.collect_time=0  �����ˡ�
end

function player_class:frame()
	self.grazer.world=self.world
	local _temp_key=nil
	local _temp_keyp=nil
	if self.key then
		_temp_key=KeyState
		_temp_keyp=KeyStatePre
		KeyState=self.key
		KeyStatePre=self.keypre
	end


	--find target
	if ((not IsValid(self.target)) or (not self.target.colli)) then player_class.findtarget(self) end
	if not KeyIsDown'shoot' then self.target=nil end
	--
	local dx=0
	local dy=0
	local v=self.hspeed
	if (self.death==0 or self.death>90) and (not self.lock) and not(self.time_stop) then
		--slow
		if KeyIsDown'slow' then self.slow=1 else self.slow=0 end
		--shoot and spell
		if not self.dialog then
			if KeyIsDown'shoot' and self.nextshoot<=0 then self.class.shoot(self) end
			--if KeyIsDown'spell' and self.nextspell<=0 and lstg.var.bomb>0 and not lstg.var.block_spell then
			--	item.PlayerSpell()
			--	lstg.var.bomb=lstg.var.bomb-1
			--	self.class.spell(self)
			--	self.death=0
			--	self.nextcollect=90
			--end

--------------------------------------------------------�µķ������
            if self.SpellCardHp==0 and self.SpellTimer1>=0 then self.SpellTimer1=-1 self.KeyDownTimer1=0 self.SC_name='' end
            if self.SpellCardHp>0 and self.SpellTimer1>90 then self.SpellCardHp=max(0,self.SpellCardHp-K_SpellDecay) end
			if self.NextSingleSpell>0 then self.NextSingleSpell=self.NextSingleSpell-1 end
			if self.SpellTimer1>0 then self.SpellTimer1=self.SpellTimer1+1 end
			
			if self.SpellTimer1==90 then self.class.newSpell(self) end
			
			if KeyIsDown'spell' and not lstg.var.block_spell then
			    if self.SpellTimer1>90 then self.KeyDownTimer1=self.KeyDownTimer1+1 end
				if (lstg.var.bomb>0 and self.death>90) or (self.SpellCardHp==0 and self.nextspell<=0 and self.NextSingleSpell==0 and lstg.var.bomb>0) then
			        item.PlayerSpell()
					if self.slow==1 then self.SpellIndex=lstg.var.bomb+3
					else self.SpellIndex=lstg.var.bomb end
					
					if player.SpellIndex==1 then SpellName='������������项' end
					if player.SpellIndex==2 then SpellName='����������ӡ��' end
					if player.SpellIndex==3 then SpellName='���顸�����ӡ���š�' end
					if player.SpellIndex==4 then SpellName='��������鰵Ͷ��' end
					if player.SpellIndex==5 then SpellName='�������������' end
					if player.SpellIndex==6 then SpellName='���ߡ��������񾮡�' end
					
				    lstg.var.bomb=lstg.var.bomb-1
					ui.menu.LoseSpell=15
				    self.SpellCardHpMax=K_MaxSpell+lstg.var.dr*K_dr_SpellHp
				    self.SpellCardHp=self.SpellCardHpMax
						 
					self.SpellTimer1=1
					self.KeyDownTimer1=0
					New(player_spell_mask,64,64,200,30,60,30)
					New(bullet_cleaner,player.x,player.y, 270, 60, 90, 1)
					self.protect=90
						 
				    self.death=0
				    self.nextcollect=90
					self.NextSingleSpell=180
					self.nextspell=360
						 
					ui.menu.HighlightFlag=30
			    else if self.SpellCardHp>0 and self.NextSingleSpell==0 then
				         self.NextSingleSpell=90
					     self.class.newSpell(self)
					end
				end
			else if self.KeyDownTimer1>0 then self.KeyDownTimer1=0 end
			end

--------------------------------------------------------
		else self.nextshoot=15 self.nextspell=30 self.NextSingleSpell=30
		end
		
		--move
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
		
		for i=1,#jstg.worlds do -----------------------------------------------------????????????????????
			if IsInWorld(self.world,jstg.worlds[i].world) then
				self.x=math.max(math.min(self.x,jstg.worlds[i].pr-8),jstg.worlds[i].pl+8)
				self.y=math.max(math.min(self.y,jstg.worlds[i].pt-32),jstg.worlds[i].pb+16)
			end
		end
		
		end
		--fire
		if KeyIsDown'shoot' and not self.dialog then self.fire=self.fire+0.16 else self.fire=self.fire-0.16 end
		if self.fire<0 then self.fire=0 end
		if self.fire>1 then self.fire=1 end
		
		-----------------------------------------------  �����仯
		if self.PowerDelay1>0 then self.PowerDelay1=self.PowerDelay1-1 end
		--if self.PowerDelay2>0 then self.PowerDelay2=self.PowerDelay2-1 end --���ɷ�����
		
		if lstg.var.dr==5 then self.maxPower=300
		else if lstg.var.dr==-5 then self.maxPower=600 
		else if lstg.var.dr<=-2.5 then self.maxPower=500
		else self.maxPower=400 end end end
		
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
		    New(item_power_mid,self.supportx+self.sp[n][1]+r4*cos(r3),self.supporty+self.sp[n][2]+r4*sin(r3))
			self.PowerDelay1=-1
		end
		-----------------------------------------------
		
		--���
		if KeyIsDown'special' and not self.dialog and self.graze_c>=K_graze_c_min and lstg.var.power>=100 and self.SpellTimer1==-1 then 
		    self.offset = 100*(1.0 + K_graze_c_k * (self.graze_c - K_graze_c_min))
			New(bullet_cleaner,player.x,player.y, 125, 20, 45, 1)
			-- �����䣺��������A��BOMB������ɢ����������Ч
			GetPower(-self.offset)
			self.graze_c = 0
			PlaySound('ophide',0.1)
			self.ccced_in_chapter=true
			self.protect=max(20,self.protect)
			self.class.ccc(self) -- �ͷ����
			DR_Pin.pin_shift(K_dr_ccced)   --�ͷ��������ָ������
		end
			
		--item
		local line = 0.0
		local distant=1.0
		if(lstg.var.dr<0) then 
		    line = K_dr_collectline
			distant = 1 + K_dr_dist*abs(lstg.var.dr)
		else 
		    line=0
			distant=1
		end
		
		if self.y>(self.collect_line + line*lstg.var.dr) then
			--self.collect_time= self.collect_time + 1
		
			--if not(self.itemed) and not(self.collecting) then
			--	self.itemed=true
			--	self.collecting=true
--				lstg.var.collectitem=0
			--	self.nextcollect=15
			--end
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
		-----
		else
			--self.nextcollect=0
			--self.collect_time=0
			if KeyIsDown'slow' then
				for i,o in ObjList(GROUP_ITEM) do
					if Dist(self,o)<(48*distant) or (self.SpellTimer1>0 and self.SpellTimer1<=90) then
						if o.attract<3 then
							o.attract=max(o.attract,3) 
							o.target=self
						end	
					end
				end
			else
				for i,o in ObjList(GROUP_ITEM) do
					if Dist(self,o)<(24*distant) or (self.SpellTimer1>0 and self.SpellTimer1<=90) then 
						if o.attract<3 then
							o.attract=max(o.attract,3) 
							o.target=self
						end	
					end
				end
			end
		end
		--if self.nextcollect<=0 and self.itemed then
		--	item.playercollect(self.item)
		--	self.item=self.item%6+1
--			lstg.var.collectitem=0
		--	self.itemed=false
		--	self.collecting=false
		--end
		--if self.collecting and not(self.itemed) then end
	elseif self.death==90 then                                 --������90֡�ڷ������¼�
		if self.time_stop then self.death=self.death-1 end
		item.PlayerMiss(self)
		self.deathee={}
		self.deathee[1]=New(deatheff,self.x,self.y,'first')
		self.deathee[2]=New(deatheff,self.x,self.y,'second')
		New(player_death_ef,self.x,self.y)
	elseif self.death==84 then
		if self.time_stop then self.death=self.death-1 end
		self.hide=true
		self.support=int(lstg.var.power/100)
	elseif self.death==50 then
		if self.time_stop then self.death=self.death-1 end
		self.x=0
		self.supportx=0
		self.y=-236
		self.supporty=-236
		self.hide=false
		New(bullet_deleter,self.x,self.y)
	elseif self.death<50 and not(self.lock) and not(self.time_stop) then
		self.y=-176-1.2*self.death

	end
	if self.death<90 and self.death>=40 then
		--���޸ı�ǡ���p
		if lstg.var.power>0 then lstg.var.power=lstg.var.power-1 end
	end
	--img
	---����time_stop��������ʵ��ͼ��ʱͣ
	if not(self._wisys) then
		self._wisys=PlayerWalkImageSystem(self)
	end
	if not(self.time_stop) then
		self._wisys:frame(dx)--by OLC���Ի�����ͼϵͳ
		
	--if not(self.time_stop) then               ----����������ͼϵͳ��
	--if abs(self.lr)==1 then
	--	self.img=self.imgs[int(self.ani/8)%8+1]
	--elseif self.lr==-6 then
	--	self.img=self.imgs[int(self.ani/8)%4+13]
	--elseif self.lr== 6 then
	--	self.img=self.imgs[int(self.ani/8)%4+21]
	--elseif self.lr<0 then
	--	self.img=self.imgs[7-self.lr]
	--elseif self.lr>0 then
	--	self.img=self.imgs[15+self.lr]
	--end
	--------------------
	--self.a=self.A
	--self.b=self.B
	--some status
	--self.lr=self.lr+dx;
	--if self.lr> 6 then self.lr= 6 end
	--if self.lr<-6 then self.lr=-6 end
	--if self.lr==0 then self.lr=self.lr+dx end
	--if dx==0 then
	--	if self.lr> 1 then self.lr=self.lr-1 end
	--	if self.lr<-1 then self.lr=self.lr+1 end
	--end

	self.lh=self.lh+(self.slow-0.5)*0.3
	if self.lh<0 then self.lh=0 end
	if self.lh>1 then self.lh=1 end

	if self.nextshoot>0 then self.nextshoot=self.nextshoot-1 end
	if self.nextspell>0 then self.nextspell=self.nextspell-1 end
	--if self.nextcollect>0 then self.nextcollect=self.nextcollect-1 end--HZC�յ�ϵͳ

	if self.support>int(lstg.var.power/100) then self.support=self.support-0.0625
	elseif self.support<int(lstg.var.power/100) then self.support=self.support+0.0625 end
	if abs(self.support-int(lstg.var.power/100))<0.0625 then self.support=int(lstg.var.power/100) end

	self.supportx=self.x+(self.supportx-self.x)*0.6875
	self.supporty=self.y+(self.supporty-self.y)*0.6875

	if self.protect>0 then self.protect=self.protect-1 end --�޵�ʱ����٣�������ʱ����
	if self.death>0 then self.death=self.death-1 end

	lstg.var.pointrate=item.PointRateFunc(lstg.var)
	--update supports
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
	--
	end---time_stop
	if self.time_stop then self.timer=self.timer-1 end
	
	
	if self.key then
		KeyState=_temp_key
		KeyStatePre=_temp_keyp
	end
	
end

function player_class:render()
	self._wisys:render()--by OLC���Ի�����ͼϵͳ
	
	if self.SpellCardHp>0 then
	    for i=1,25 do SetImageState('player_aura_3D'..i,'mul+add',Color(255,255,255,255)) end
	    Render('player_aura_3D'..self.ani%25+1,self.x,self.y,self.ani*0.75,0.6,0.6+0.05*sin(90+self.ani*0.75)) --���֣����ĵ�xy����ת�ȣ�xy���ţ�z�����Ĭ��0.5
		
		if self.SpellTimer1<=90 then
		    for i=1,16 do SetImageState('playerring1'..i,'mul+add',Color(255,255,255,255)) end
		    for i=1,16 do SetImageState('playerring2'..i,'mul+add',Color(255,255,255,255)) end
		    misc.RenderRing('playerring1',self.x,self.y,self.SpellTimer1*2+300*sin(self.SpellTimer1*2),self.SpellTimer1*2+300*sin(self.SpellTimer1*2)+16, self.ani*3,32,16)
		    misc.RenderRing('playerring2',self.x,self.y,90+self.SpellTimer1*1,-180+self.SpellTimer1*4-16,-self.ani*3,32,16)
		else
		    if self.SpellTimer1<=180 then
			    for i=1,16 do SetImageState('playerring1'..i,'mul+add',Color(255-(self.SpellTimer1-90),255,255,255)) end
		        for i=1,16 do SetImageState('playerring2'..i,'mul+add',Color(255-(self.SpellTimer1-90),255,255,255)) end
		        misc.RenderRing('playerring1',self.x,self.y,180-(self.SpellTimer1-90)*130/90,180-(self.SpellTimer1-90)*130/90+16-(self.SpellTimer1-90)/10, self.ani*3*self.SpellTimer1/90,32,16)
				misc.RenderRing('playerring2',self.x,self.y,180-(self.SpellTimer1-90)*130/90,180-(self.SpellTimer1-90)*130/90-16+(self.SpellTimer1-90)/10, self.ani*3*self.SpellTimer1/90,32,16)
				
			    --misc.RenderRing('playerring2',self.x,self.y,(1000-self.SpellTimer1)/(1000-90)*180,(1000-self.SpellTimer1)/(1000-90)*180-16,-self.ani*3,32,16)
			else
			    misc.RenderRing('playerring1',self.x,self.y,50,57, self.ani*3*2,32,16)
				misc.RenderRing('playerring2',self.x,self.y,50,43, self.ani*3*2,32,16)
			end
		end
		
		
		Renderspellbar(self.x,self.y,90,360,60,64,360,1)
		Renderspellhp(self.x,self.y,90,360*self.SpellCardHp/self.SpellCardHpMax,60,64,360*self.SpellCardHp/self.SpellCardHpMax+2,1)
		Render('base_spell_hp',self.x,self.y,0,0.548,0.548)
        Render('base_spell_hp',self.x,self.y,0,0.512,0.512)
		Render('life_node',self.x-63*cos(K_SpellCost/self.SpellCardHpMax),self.y+63*sin(K_SpellCost/self.SpellCardHpMax),K_SpellCost/self.SpellCardHpMax-90,1.1)
	end
end

function player_class:colli(other)
	if self.death==0 and not self.dialog and not cheat then
		if self.protect==0 then
			PlaySound('pldead00',0.5)
			self.death=100
		end
		if other.group==GROUP_ENEMY_BULLET then Del(other) end
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
		lstg.var.bombchip=lstg.var.bombchip+self.SpellCardHp/K_MaxSpell*0.4
		self.SpellCardHp=0
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
	self.img='graze'
	ParticleStop(self)
	self.a=48
	self.b=48
	self.aura=0
end

function grazer:frame()
	self.x=self.player.x
	self.y=self.player.y
	self.hide=self.player.hide
	if not self.player.time_stop then
	self.aura=self.aura+1.5 end
	--
	if self.grazed then
		PlaySound('graze',0.3,self.x/200)
		self.grazed=false
		ParticleFire(self)
	else ParticleStop(self) end
end

function grazer:render()
	object.render(self)
	SetImageState('player_aura','',Color(0xC0FFFFFF)*self.player.lh+Color(0x00FFFFFF)*(1-self.player.lh))
	Render('player_aura',self.x,self.y, self.aura,(2-self.player.lh)*2)
	SetImageState('player_aura','',Color(0xC0FFFFFF))
	Render('player_aura',self.x,self.y,-self.aura,self.player.lh*2)
end

function grazer:colli(other)
	if other.group~=GROUP_ENEMY and (not other._graze) then
		item.PlayerGraze()
		--lstg.player.grazer.grazed=true
		self.grazed=true
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
--			SetImageState('player_spell_mask','mul+add',Color(i*255/t1,r,g,b))
			self.bcolor.a=i*255/t1
			task.Wait(1)
		end
		task.Wait(t2)
		for i=t3,1,-1 do
--			SetImageState('player_spell_mask','mul+add',Color(i*255/t3,r,g,b))
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

function player_death_ef:init(x,y)
	self.x=x self.y=y self.img='player_death_ef' self.layer=LAYER_PLAYER+50
end

function player_death_ef:frame()
	if self.timer==4 then ParticleStop(self) end
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
		if self.type=='second' then task.Wait(35) end--���޸ı�ǡ�ԭ����30
		for i=1,360 do
			self.size=size
			self.size1=size1
			size=size+18--���޸ı�ǡ�ԭ����12
			size1=size1+12--���޸ı�ǡ�ԭ����8
			task.Wait(1)
		end
	end)
end

function deatheff:frame()
	task.Do(self)
	if self.timer>180 then Del(self) end
end

function deatheff:render()
    --��΢������������ɫȦ�ķָ������Ӿ�Ч���������䣬�����������ģ�ԭ�ָ���Ϊ180��
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
player_list={
	{'Hakurei Reimu','reimu_player','Reimu'},
	{'Kirisame Marisa','marisa_player','Marisa'},
	{'Izayoi Sakuya','sakuya_player','Sakuya'},
	{'shababa','shababa_player','Shababa'}
}

Include'THlib\\player\\reimu\\reimu.lua'
Include'THlib\\player\\marisa\\marisa.lua'
Include'THlib\\player\\sakuya\\sakuya.lua'
Include'THlib\\player\\shababa\\shababa_player.lua'

----------------------------------------
---�����Ի�
--[[
local PLAYER_PATH="Library\\players\\"    --�Ի����·��
local PLAYER_PATH_1="Library\\"           --�Ի����·��һ��·��
local PLAYER_PATH_2="Library\\players\\"  --�Ի����·������·��
local ENTRY_POINT_SCRIPT_PATH=""          --��ڵ��ļ�·��
local ENTRY_POINT_SCRIPT="__init__.lua"   --��ڵ��ļ�

---���Ŀ¼�Ƿ���ڣ��������򴴽�
local function check_directory()
	if not plus.DirectoryExists(PLAYER_PATH_1) then
		plus.CreateDirectory(PLAYER_PATH_1)
	end
	if not plus.DirectoryExists(PLAYER_PATH_2) then
		plus.CreateDirectory(PLAYER_PATH_2)
	end
end

---���һ���Ի�������Ƿ�Ϸ�������ڵ��ļ���
---�ú�����װ���Ի��������Ȼ����м�飬������ǺϷ����Ի������������ж�ص�
---@param player_plugin_path string @�����·��
---@return boolean
local function LoadAndCheckValidity(player_plugin_path)
	lstg.LoadPack(player_plugin_path)
	local fs=lstg.FindFiles("", "lua", player_plugin_path)
	for _,v in pairs(fs) do
		local filename=string.sub(v[1],string.len(ENTRY_POINT_SCRIPT_PATH)+1,-1)
		if filename==ENTRY_POINT_SCRIPT then
			return true
		end
	end
	lstg.UnloadPack(player_plugin_path)
	lstg.Log(4,LOG_MODULE_NAME,"\""..player_plugin_path.."\"������Ч���Ի��������û����ڵ��ļ�\""..ENTRY_POINT_SCRIPT.."\"")
	return false
end

---�����Ի�����Ϣ��
---@type table @{{displayname,classname,replayname}, ... }
player_list={}
--]]
---���Ի����������
--local function PlayerListSort()
--	local playerDisplayName={}--{displayname, ... }
--	local pl2id={}--{[displayname]=player_list_pos, ... }
--	for i,v in ipairs(player_list) do
--		table.insert(playerDisplayName,v[1])
--		pl2id[v[1]]=i
--	end
--	table.sort(playerDisplayName)
--	local id2pl={}--{[pos]=player_list_pos}
--	for i,v in ipairs(playerDisplayName) do
--		id2pl[i]=pl2id[v]
--	end
--	local tmp_player_list={}
--	for i,v in ipairs(id2pl) do
--		tmp_player_list[i]=player_list[v]
--	end
--	player_list=tmp_player_list
--end

---����Ի���Ϣ���Ի���Ϣ��
---@param displayname string @��ʾ�ڲ˵��е�����
---@param classname string @ȫ���е��Ի�����
---@param replayname string @��ʾ��rep��Ϣ�е�����
---@param pos number @�����λ��
---@param _replace boolean @�Ƿ�ȡ����λ��
--[[
function AddPlayerToPlayerList(displayname,classname,replayname,pos,_replace)
	if _replace then
		player_list[pos]={displayname,classname,replayname}
	elseif pos then
		table.insert(player_list,pos,{displayname,classname,replayname})
	else
		table.insert(player_list,{displayname,classname,replayname})
	end
end

---�����Ի���
function LoadPlayerPacks()
	player_list={}--�����һ��
	
	check_directory()
	local fs=lstg.FindFiles(PLAYER_PATH, "zip", "")--���в����
	for _,v in pairs(fs) do
		--���Լ��ز��������������Ϸ���
		local result=LoadAndCheckValidity(v[1])
		--������ڵ�ű�
		if result then
			lstg.DoFile(ENTRY_POINT_SCRIPT, v[1])
		end
	end
	
	PlayerListSort()
end

LoadPlayerPacks()
--]]