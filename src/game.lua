-- fuori, nero! / cortile notturno
-- pixel art originale, palette pico-8
-- z salta / x graffia / giu+x morde
-- doppio tocco sinistra o destra: dash

function _init()
 tick=0
 phase="title"
 world_w=320
 ground_y=112
 cam_x=0
 notice=""
 notice_t=0
 win_t=0
 dust={}
 echoes={}
 srand(9)
 hero={
  x=24,y=112,vx=0,vy=0,face=1,
  ground=true,coyote=6,buffer=0,
  dash_t=0,cool=0,dash_dir=1,
  tap_dir=0,tap_t=0,
  atk=0,atk_t=0,land_t=0,
  held_l=false,held_r=false,
  held_z=false,held_x=false
 }
 gates={
  {x=112,w=12,top=80,kind=1,open=false,hit=0},
  {x=194,w=16,top=88,kind=2,open=false,hit=0},
  {x=272,w=16,top=80,kind=3,open=false,hit=0}
 }
 ledges={{x=147,y=98,w=24}}
 frames={0,2,4,6,8,10,12,14,32,34,36,38}
 transparent()
 menuitem(1,"ricomincia",function() _init() end)
end

function transparent()
 palt(0,false)
 palt(15,true)
end

function _update60()
 tick=(tick+1)%7200
 update_fx()
 for g in all(gates) do
  g.hit=max(0,g.hit-1)
 end
 notice_t=max(0,notice_t-1)

 if phase=="title" then
  if btnp(4) or btnp(5) then
   phase="play"
   hero.held_z=btn(4)
   hero.held_x=btn(5)
   say("segui il nastro rosso")
  end
  return
 end
 if phase=="win" then
  win_t+=1
  if win_t>30 and (btnp(4) or btnp(5)) then
   _init()
   phase="play"
   hero.held_z=btn(4)
   hero.held_x=btn(5)
  end
  return
 end

 update_hero()
 local target=mid(0,hero.x-56+hero.face*5,world_w-128)
 cam_x+=(target-cam_x)*0.12

 if abs(hero.x-304)<9 and abs(hero.y-105)<15 then
  phase="win"
  win_t=0
  burst(304,102,14,14)
  sfx(5)
 end
end

function update_hero()
 local h=hero
 local dir=0
 if btn(0) then dir-=1 end
 if btn(1) then dir+=1 end
 local jump=btn(4) and not h.held_z
 local attack=btn(5) and not h.held_x
 local tap=0
 if btn(0) and not h.held_l then tap=-1 end
 if btn(1) and not h.held_r then tap=1 end
 h.held_l=btn(0)
 h.held_r=btn(1)
 h.held_z=btn(4)
 h.held_x=btn(5)
 h.cool=max(0,h.cool-1)
 h.tap_t=max(0,h.tap_t-1)
 h.atk_t=max(0,h.atk_t-1)
 h.land_t=max(0,h.land_t-1)
 if dir!=0 and h.dash_t==0 then h.face=dir end

 if tap!=0 then
  if tap==h.tap_dir and h.tap_t>0 and h.cool==0 then
   h.dash_t=9
   h.dash_dir=tap
   h.face=tap
   h.cool=32
   h.tap_t=0
   h.atk_t=0
   sfx(1)
   burst(h.x,h.y-3,12,5)
  else
   h.tap_dir=tap
   h.tap_t=16
  end
 end

 if h.ground then
  h.coyote=6
 else
  h.coyote=max(0,h.coyote-1)
 end
 h.buffer=max(0,h.buffer-1)
 if jump then h.buffer=8 end
 if h.buffer>0 and h.coyote>0 and h.dash_t==0 then
  h.vy=-3.1
  h.ground=false
  h.coyote=0
  h.buffer=0
  burst(h.x,h.y,6,4)
  sfx(0)
 end

 if attack and h.atk_t==0 and h.dash_t==0 then
  h.atk=1
  h.atk_t=12
  if btn(3) then h.atk=2 h.atk_t=18 end
  attack_gate(h.atk)
  sfx(h.atk+1)
 end

 if h.dash_t>0 then
  h.vx=h.dash_dir*3.4
  h.vy=0
  if h.dash_t%2==1 then
   add(echoes,{x=h.x,y=h.y,face=h.face,life=12})
  end
 else
  local speed=dir*1.12
  if h.atk_t>0 and h.ground then speed*=0.6 end
  h.vx+=mid(-0.22,speed-h.vx,0.22)
  if not btn(4) and h.vy<-1.2 then h.vy=-1.2 end
  h.vy=min(3.3,h.vy+0.16)
 end

 move_x()
 local was_ground=h.ground
 move_y()
 if h.ground and not was_ground then
  h.land_t=6
  burst(h.x,h.y,6,5)
 end
 if h.dash_t>0 then h.dash_t-=1 end
end

function move_x()
 local h=hero
 local steps=flr(abs(h.vx))+1
 for i=1,steps do
  local nx=h.x+h.vx/steps
  for g in all(gates) do
   if not g.open and nx+5>g.x-g.w/2
    and nx-5<g.x+g.w/2
    and h.y>g.top and h.y-13<ground_y then
    if h.dash_t>0 and g.kind==3 then
     open_gate(g)
    else
     if h.vx>0 then nx=g.x-g.w/2-5 end
     if h.vx<0 then nx=g.x+g.w/2+5 end
     if h.dash_t>0 then
      burst(h.x,h.y-8,13,5)
      g.hit=8
     end
     h.vx=0
     h.dash_t=0
    end
   end
  end
  h.x=mid(8,nx,world_w-8)
 end
end

function move_y()
 local h=hero
 local old_y=h.y
 local ny=h.y+h.vy
 h.ground=false
 if ny>=ground_y then
  ny=ground_y
  h.vy=0
  h.ground=true
 end
 for l in all(ledges) do
  if h.vy>=0 and old_y<=l.y and ny>=l.y
   and h.x+4>l.x and h.x-4<l.x+l.w then
   ny=l.y
   h.vy=0
   h.ground=true
  end
 end
 h.y=ny
end

function attack_gate(kind)
 local h=hero
 local target=h.x+h.face*12
 for g in all(gates) do
  if not g.open and abs(target-g.x)<g.w/2+7
   and h.y>g.top and h.y-13<ground_y then
   if kind==g.kind then
    open_gate(g)
   else
    g.hit=7
    burst(target,h.y-8,6,3)
   end
  end
 end
end

function open_gate(g)
 g.open=true
 local colors={11,9,10}
 burst(g.x,ground_y-12,colors[g.kind],16)
 local messages={
  "un varco tra le foglie",
  "morso: cassa rotta!",
  "dash: via il cartone!"
 }
 say(messages[g.kind])
 sfx(4)
end

function say(s)
 notice=s
 notice_t=100
end

function burst(x,y,col,n)
 for i=1,n do
  add(dust,{
   x=x,y=y,vx=rnd(2)-1,vy=-rnd(1.4),
   color=col,life=18+flr(rnd(12)),size=1+flr(rnd(2))
  })
 end
end

function update_fx()
 for a in all(dust) do
  a.x+=a.vx
  a.y+=a.vy
  a.vy+=0.06
  a.life-=1
  if a.life<=0 then del(dust,a) end
 end
 for a in all(echoes) do
  a.life-=1
  if a.life<=0 then del(echoes,a) end
 end
end

function _draw()
 camera()
 draw_sky()
 camera(flr(cam_x),0)
 draw_courtyard()
 for g in all(gates) do draw_gate(g) end
 if phase!="win" then draw_ribbon() end
 draw_fx()
 if phase!="title" then draw_hero() end
 camera()
 if phase=="title" then
  draw_title()
 elseif phase=="win" then
  draw_hud()
  draw_win()
 else
  draw_hud()
 end
end

function draw_sky()
 cls(1)
 rectfill(0,54,127,79,2)
 for i=0,11 do
  local sx=(i*37+13)%128
  local sy=(i*17+11)%40+9
  pset(sx,sy,5)
  if (tick+i*23)%180<24 then pset(sx,sy,13) end
 end
 local mx=106-flr(cam_x*0.04)
 circfill(mx,25,10,6)
 circfill(mx-1,24,9,7)
 rectfill(mx-5,21,mx-3,23,6)
 pset(mx+3,28,6)
 line(mx+1,30,mx+3,30,6)

 -- skyline: masse compatte, contrasto ridotto
 local heights={25,34,21,30,18,28,36,23}
 for i=-1,7 do
  local x=i*26-flr(cam_x*0.22)%26
  local y=82-heights[(i+8)%8+1]
  rectfill(x,y,x+22,99,2)
  rectfill(x-2,y,x+24,y+2,1)
  rectfill(x+14,y-6,x+17,y,1)
  line(x,y+3,x+22,y+3,5)
  for wy=y+10,90,13 do
   rectfill(x+5,wy,x+7,wy+3,5)
   rectfill(x+14,wy,x+16,wy+3,4)
  end
 end
end

function draw_courtyard()
 -- recinzione in un piano intermedio
 for x=-8,world_w+8,8 do
  sspr(48,32,8,24,x,88)
 end
 line(0,91,world_w,91,5)
 line(0,104,world_w,104,2)

 -- casa: luce calda, bordi freddi sul lato lunare
 rectfill(0,55,48,111,2)
 line(48,57,48,111,13)
 for y=61,105,8 do
  for x=0,43,16 do
   local bx=x+(y%16==5 and 8 or 0)
   line(bx,y,bx+10,y,4)
  end
 end
 for y=0,9 do
  rectfill(max(0,24-y*3),44+y,min(48,24+y*3),44+y,5)
 end
 line(24,44,48,52,13)
 rectfill(0,54,48,56,4)
 rectfill(9,37,15,46,5)
 line(9,37,15,37,13)
 line(9,40,15,40,4)
 sspr(112,40,16,16,25,65)
 sspr(112,16,16,24,12,88)
 sspr(32,48,8,16,43,77)
 sspr(56,40,16,16,62,96)

 -- albero e fiori: volumi compatti, pochi dettagli
 rectfill(125,87,129,111,4)
 line(129,86,129,111,5)
 line(127,92,119,84,4)
 sspr(16,48,16,16,111,75)
 sspr(16,48,16,16,124,70)
 sspr(16,48,16,16,130,81)
 sspr(56,40,16,16,238,96)
 sspr(56,40,16,16,292,96)

 for l in all(ledges) do
  line(l.x+3,l.y+7,l.x+3,ground_y,4)
  line(l.x+l.w-4,l.y+7,l.x+l.w-4,ground_y,4)
  for x=l.x,l.x+l.w-1,8 do
   sspr(0,40,8,8,x,l.y)
  end
 end

 for x=0,world_w-1,8 do
  local sx=0
  if x<48 or (x>=176 and x<216) then sx=16 end
  sspr(sx,32,8,8,x,ground_y)
  sspr(8,32,8,8,x,ground_y+8)
 end
 for x=52,world_w,48 do
  sspr(0,48,16,8,x,ground_y-7)
 end
 -- lucciole: piccoli punti luminosi intenzionali
 for i=0,3 do
  local x=70+i*63+sin(tick/300+i/4)*5
  local y=77+sin(tick/240+i/3)*4
  pset(x,y,9)
 end
end

function draw_gate(g)
 if g.open then
  line(g.x-5,110,g.x+5,110,g.kind==1 and 3 or 4)
  return
 end
 local shake=0
 if g.hit>0 then shake=(g.hit%4<2 and -1 or 1) end
 local x=g.x-8+shake
 if g.kind==1 then
  sspr(96,16,16,32,x,g.top)
 elseif g.kind==2 then
  sspr(64,16,16,24,x,g.top)
 else
  sspr(80,16,16,32,x,g.top)
 end
end

function draw_ribbon()
 local y=101+flr(sin(tick/120)*2)
 sspr(40,40,8,8,300,y)
 if tick%60<12 then
  line(309,y-2,309,y+2,7)
  line(307,y,311,y,7)
 end
end

function draw_fx()
 for a in all(echoes) do
  local col=1
  if a.life>4 then col=13 end
  if a.life>8 then col=12 end
  for c=0,14 do pal(c,col) end
  spr(32,flr(a.x)-8,flr(a.y)-16,2,2,a.face<0)
  pal()
  transparent()
 end
 for a in all(dust) do
  local col=a.color
  if a.life<5 then col=5 end
  rectfill(a.x,a.y,a.x+a.size-1,a.y+a.size-1,col)
 end
end

function draw_hero()
 local h=hero
 local pose=1
 if h.dash_t>0 then
  pose=9
 elseif h.atk_t>0 then
  pose=h.atk==1 and 10 or 11
 elseif not h.ground then
  pose=h.vy<0 and 7 or 8
 elseif h.land_t>0 or btn(3) then
  pose=12
 elseif abs(h.vx)>0.2 then
  pose=3+flr(tick/6)%4
 elseif tick%180>166 then
  pose=2
 end
 local x=flr(h.x)
 local y=flr(h.y)
 line(x-5,ground_y+1,x+5,ground_y+1,0)
 spr(frames[pose],x-8,y-16,2,2,h.face<0)
 if h.atk_t>5 and h.atk==1 then
  local reach=12-h.atk_t
  for i=0,2 do
   line(x+h.face*(8+reach),y-12+i*4,
    x+h.face*(13+reach),y-14+i*4,i==1 and 12 or 7)
  end
 elseif h.atk_t>8 and h.atk==2 then
  pset(x+h.face*10,y-6,7)
  pset(x+h.face*11,y-4,7)
 end
end

function draw_hud()
 rectfill(0,0,127,11,0)
 print("cortile",4,3,6)
 print("dash",79,3,5)
 rect(98,3,123,7,5)
 local ready=(32-hero.cool)/32
 rectfill(100,5,100+flr(21*ready),5,hero.cool==0 and 12 or 1)
 rectfill(0,119,127,127,0)
 local hint="z salta  x graffia"
 for g in all(gates) do
  if not g.open and abs(hero.x-g.x)<27 then
   local hints={"x: graffio","giu+x: morso","doppio tocco: dash"}
   hint=hints[g.kind]
  end
 end
 if notice_t>0 then hint=notice end
 print(hint,4,121,notice_t>0 and 10 or 6)
end

function draw_title()
 -- lettere 5x5, senza filtri, a scala intera
 big_word("fuori,",29,21,7)
 big_word("nero!",35,35,14)
 print("una notte fuori casa",25,52,6)
 local sx=tick%180>165 and 16 or 0
 sspr(sx,0,16,16,50,79,32,32)
 rectfill(8,115,119,126,0)
 print("z / x: esci di casa",28,118,7)
end

function big_word(word,x,y,col)
 local glyphs={
  f={"11111","10000","11110","10000","10000"},
  u={"10001","10001","10001","10001","01110"},
  o={"01110","10001","10001","10001","01110"},
  r={"11110","10001","11110","10010","10001"},
  i={"111","010","010","010","111"},
  n={"10001","11001","10101","10011","10001"},
  e={"11111","10000","11110","10000","11111"},
  [","]={"0","0","0","1","1"},
  ["!"]={"1","1","1","0","1"}
 }
 for i=1,#word do
  local g=glyphs[sub(word,i,i)]
  for gy=1,5 do
   for gx=1,#g[gy] do
    if sub(g[gy],gx,gx)=="1" then
     rectfill(x+(gx-1)*2+1,y+(gy-1)*2+1,
      x+gx*2,y+gy*2,0)
     rectfill(x+(gx-1)*2,y+(gy-1)*2,
      x+gx*2-1,y+gy*2-1,col)
    end
   end
  end
  x+=(#g[1]+1)*2
 end
end

function draw_win()
 rectfill(13,39,114,76,0)
 rect(15,41,112,74,13)
 print("nastro ritrovato!",32,47,14)
 print("la notte continua...",25,57,6)
 print("z / x: ricomincia",32,66,7)
end
