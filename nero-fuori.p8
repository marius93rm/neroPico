pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- fuori, nero! - prototipo cortile
-- frecce: muovi | z: salta | x: graffia
-- giu+x: morde | doppio tocco sinistra/destra: dash

room_w=256
floor_y=110
cam_x=0
msg=""
msg_t=0

function _init()
 p={
  x=18,y=floor_y,vx=0,vy=0,
  face=1,grounded=true,
  dash=0,dash_dir=1,
  last_dir=0,last_tap=-10,
  attack="",atk_t=0
 }
 barriers={
  {x=82,kind="vines",top=73,alive=true},
  {x=151,kind="crate",top=84,alive=true},
  {x=218,kind="card",top=73,alive=true}
 }
end

function _update()
 local dir=0
 if btn(0) then dir=-1 elseif btn(1) then dir=1 end
 if dir!=0 then p.face=dir end

 -- doppio tocco direzionale per lo scatto
 local tap=0
 if btnp(0) then tap=-1 elseif btnp(1) then tap=1 end
 if tap!=0 then
  if tap==p.last_dir and time()-p.last_tap<0.32 then
   p.dash=7
   p.dash_dir=tap
   p.last_tap=-10
  else
   p.last_dir=tap
   p.last_tap=time()
  end
 end

 if btnp(4) and p.grounded then
  p.vy=-3.7
  p.grounded=false
 end

 if btnp(5) then
  if btn(3) then
   p.attack="morso"
  else
   p.attack="graffio"
  end
  p.atk_t=8
  hit_barrier(p.attack)
 end

 if p.dash>0 then
  p.vx=p.dash_dir*3.2
  p.vy=0
  p.dash-=1
 else
  p.vx=dir*1.15
  p.vy=min(3.5,p.vy+0.22)
 end

 local nx=p.x+p.vx
 for b in all(barriers) do
  if b.alive and p.y>b.top and p.y-14<floor_y and abs(nx-b.x)<7 then
   if p.dash>0 and b.kind=="card" then
    b.alive=false
    say("dash: cartone sfondato!")
   else
    nx=p.x
   end
  end
 end
 p.x=mid(5,nx,room_w-5)

 p.y+=p.vy
 if p.y>=floor_y then
  p.y=floor_y
  p.vy=0
  p.grounded=true
 else
  p.grounded=false
 end

 if p.atk_t>0 then p.atk_t-=1 end
 if msg_t>0 then msg_t-=1 else msg="" end
 cam_x=mid(0,p.x-58,room_w-128)
end

function hit_barrier(kind)
 local tx=p.x+p.face*12
 for b in all(barriers) do
  if b.alive and abs(b.x-tx)<12 then
   if kind=="graffio" and b.kind=="vines" then
    b.alive=false
    say("rampicanti tagliati!")
   elseif kind=="morso" and b.kind=="crate" then
    b.alive=false
    say("cassa sfondata!")
   end
  end
 end
end

function say(s)
 msg=s
 msg_t=90
end

function _draw()
 cls(1)
 camera(cam_x,0)
 draw_world()
 for b in all(barriers) do draw_barrier(b) end
 draw_cat()
 camera()
 print("fuori, nero!",2,2,7)
 print("z salta  x graffia",2,10,6)
 print("giu+x morde  doppio tocco=dash",2,118,7)
 if msg_t>0 then
  rectfill(24,48,104,61,0)
  print(msg,28,52,10)
 end
end

function draw_world()
 -- cielo notturno e luna
 cls(1)
 circfill(107,25,11,6)
 circfill(112,22,10,1)
 pset(24,28,7)
 pset(54,18,7)
 pset(186,34,7)
 pset(240,20,7)

 -- sagome di case e recinzione
 rectfill(0,70,54,109,0)
 rectfill(27,61,49,109,5)
 rectfill(95,74,145,109,0)
 rectfill(162,65,205,109,0)
 for x=0,room_w,12 do
  line(x,91,x,109,5)
 end
 line(0,92,room_w,92,5)

 -- terreno e ciuffi d'erba
 rectfill(0,floor_y,room_w,127,4)
 line(0,floor_y,room_w,floor_y,11)
 for x=4,room_w,16 do
  line(x,109,x-2,105,11)
  line(x,109,x+2,106,3)
 end
 -- ingresso di casa e traccia del nastro rosso
 rectfill(8,78,25,109,5)
 rect(8,78,25,109,6)
 rectfill(31,103,41,105,8)
 print("casa",10,82,7)
 print("segui il nastro",174,98,8)
end

function draw_barrier(b)
 if not b.alive then return end
 if b.kind=="vines" then
  rectfill(b.x-4,b.top,b.x+4,floor_y,3)
  for y=b.top+3,floor_y-3,6 do
   circfill(b.x-5,y,3,11)
   circfill(b.x+4,y+2,3,3)
  end
  print("x",b.x-1,84,7)
 elseif b.kind=="crate" then
  rectfill(b.x-6,b.top,b.x+6,floor_y,9)
  rect(b.x-6,b.top,b.x+6,floor_y,4)
  line(b.x-5,b.top+1,b.x+5,floor_y-1,4)
  line(b.x+5,b.top+1,b.x-5,floor_y-1,4)
  print("giu+x",b.x-10,90,7)
 else
  rectfill(b.x-5,b.top,b.x+5,floor_y,9)
  rect(b.x-5,b.top,b.x+5,floor_y,10)
  line(b.x-4,b.top+3,b.x+4,floor_y-3,4)
  line(b.x+4,b.top+3,b.x-4,floor_y-3,4)
  print("dash",b.x-7,87,7)
 end
end

function draw_cat()
 local x=p.x
 local y=p.y
 -- scia breve durante il dash
 if p.dash>0 then
  circfill(x-p.face*7,y-5,3,5)
  circfill(x-p.face*12,y-5,2,6)
 end
 -- coda, corpo, testa e orecchie
 line(x-2*p.face,y-4,x-6*p.face,y-7,1)
 line(x-6*p.face,y-7,x-8*p.face,y-4,1)
 rectfill(x-3,y-7,x+3,y-2,1)
 circfill(x-2,y-5,3,1)
 circfill(x+2,y-5,3,1)
 circfill(x+p.face*3,y-8,4,1)
 line(x+p.face*1,y-11,x+p.face*1,y-14,1)
 line(x+p.face*1,y-14,x+p.face*4,y-11,1)
 line(x+p.face*5,y-11,x+p.face*7,y-14,1)
 line(x+p.face*7,y-14,x+p.face*8,y-10,1)
 pset(x+p.face*4,y-9,12)
 pset(x+p.face*6,y-9,12)
 if p.atk_t>0 then
  if p.attack=="graffio" then
   line(x+p.face*8,y-9,x+p.face*13,y-13,7)
   line(x+p.face*9,y-6,x+p.face*15,y-8,7)
   line(x+p.face*8,y-3,x+p.face*13,y-1,7)
  else
   line(x+p.face*8,y-7,x+p.face*14,y-7,8)
   pset(x+p.face*15,y-8,7)
   pset(x+p.face*15,y-6,7)
  end
 end
end
