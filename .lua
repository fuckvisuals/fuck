-- FUCK VISUALS V2 | Studio LocalScript | local practice parry + HUD and graffiti.
-- Install under StarterPlayer > StarterPlayerScripts in your own experience.
-- Ctrl: menu | G: HUD editor | N: local graffiti | F: manual practice parry.
-- Local practice ball only; does not hook or affect public Blade Ball matches.
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local Run = game:GetService('RunService')
local Tween = game:GetService('TweenService')
local Debris = game:GetService('Debris')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')
local previous = pg:FindFirstChild('FV_HUD')
if previous then previous:Destroy() end
local C = {bg=Color3.fromRGB(15,18,25), panel=Color3.fromRGB(28,33,44), ink=Color3.fromRGB(238,244,252), dim=Color3.fromRGB(148,160,178), accent=Color3.fromRGB(139,215,255)}
local function make(class,parent,props)
    local v=Instance.new(class)
    for k,x in pairs(props or {}) do v[k]=x end
    v.Parent=parent
    return v
end
local function round(p,r) return make('UICorner',p,{CornerRadius=UDim.new(0,r or 12)}) end
local function stroke(p,color,alpha) return make('UIStroke',p,{Color=color or C.dim,Transparency=alpha or .75,Thickness=1}) end
local function frame(p,pos,size,color,alpha)
    return make('Frame',p,{Position=pos,Size=size,BackgroundColor3=color or C.panel,BackgroundTransparency=alpha or 0,BorderSizePixel=0})
end
local function label(p,s,pos,size,n,bold,color)
    return make('TextLabel',p,{Position=pos,Size=size,BackgroundTransparency=1,Text=s,TextColor3=color or C.ink,TextSize=n or 14,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
end
local function tween(o,props,t) Tween:Create(o,TweenInfo.new(t or .17,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props):Play() end
local root=make('ScreenGui',pg,{Name='FV_HUD',ResetOnSpawn=false,DisplayOrder=50,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local marks=make('Folder',root,{Name='LocalGraffiti'})
-- Icons are resolution-independent line shapes built from GUI primitives.
-- Optional asset IDs from your own uploaded PNG exports of SVG artwork.
local iconAssets={logo='',fps='',ping='',clock='',session='',health='',players='',menu='',spray='',edit=''}
local paths={logo={{3,12,10,3},{10,3,13,11},{13,11,21,3},{3,12,10,21},{10,21,13,13},{13,13,21,21}},fps={{2,18,22,18},{4,15,8,9},{8,9,13,13},{13,13,20,4}},ping={{3,20,3,15},{9,20,9,11},{15,20,15,7},{21,20,21,3}},clock={{5,4,19,4},{19,4,22,12},{22,12,19,20},{19,20,5,20},{5,20,2,12},{2,12,5,4},{12,7,12,12},{12,12,16,15}},session={{5,3,19,3},{19,3,19,8},{19,8,5,20},{5,20,19,20},{5,3,5,8},{5,8,19,20}},health={{2,12,7,12},{7,12,10,5},{10,5,14,18},{14,18,17,12},{17,12,22,12}},players={{4,20,4,15},{4,15,20,15},{20,15,20,20},{8,4,16,4},{16,4,16,11},{16,11,8,11},{8,11,8,4}},menu={{3,5,21,5},{3,12,21,12},{3,19,21,19}},spray={{7,8,17,8},{17,8,17,21},{17,21,7,21},{7,21,7,8},{10,8,10,3},{10,3,16,3},{18,4,22,2}},edit={{3,7,21,7},{3,17,21,17},{8,3,8,11},{16,13,16,21}}}
paths.parry={{12,2,21,6},{21,6,19,15},{19,15,12,22},{12,22,5,15},{5,15,3,6},{3,6,12,2},{7,12,11,16},{11,16,17,8}}
local function icon(parent,key,pos,size,color)
    local holder=frame(parent,pos,UDim2.fromOffset(size,size),C.bg,1)
    local id=iconAssets[key]
    if id and id~='' then make('ImageLabel',holder,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=id,ImageColor3=color or C.accent}); return holder end
    for _,p in ipairs(paths[key] or paths.logo) do
        local x1,y1,x2,y2=p[1]/24,p[2]/24,p[3]/24,p[4]/24
        local line=frame(holder,UDim2.fromScale((x1+x2)/2,(y1+y2)/2),UDim2.new(math.sqrt((x2-x1)^2+(y2-y1)^2),0,0,1.6),color or C.accent,0)
        line.AnchorPoint=Vector2.new(.5,.5); line.Rotation=math.deg(math.atan2(y2-y1,x2-x1)); round(line,2)
    end
    return holder
end
local function glass(p)
    round(p,14); stroke(p,C.accent,.78)
    make('UIGradient',p,{Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(162,178,202)),Rotation=105})
end
local function button(p,s,pos,size,fn)
    local b=make('TextButton',p,{Position=pos,Size=size,Text=s,AutoButtonColor=false,TextColor3=C.ink,TextSize=12,Font=Enum.Font.GothamMedium,BackgroundColor3=C.panel,BorderSizePixel=0})
    round(b,8); stroke(b,C.dim,.85)
    b.MouseEnter:Connect(function() tween(b,{BackgroundColor3=Color3.fromRGB(51,63,79)}) end)
    b.MouseLeave:Connect(function() tween(b,{BackgroundColor3=C.panel}) end)
    b.Activated:Connect(fn); return b
end
local settings={watermark=true,crosshair=false,graffiti=true,glass=true,accent=1,spraySize=3,autoParry=false,practice=false,parryWindow=.16,ballSpeed=65}
local accents={C.accent,Color3.fromRGB(195,166,255),Color3.fromRGB(149,245,190),Color3.fromRGB(255,210,145)}
local widgets={}; local editing=false; local menuOpen=false; local motion=nil
local start=os.clock(); local fps=0; local ping='--'; local markCount=0; local lastSpray=-10
local hud=frame(root,UDim2.fromScale(0,0),UDim2.fromScale(1,1),C.bg,1)
local wm=frame(hud,UDim2.fromOffset(18,18),UDim2.fromOffset(280,45),C.bg,.12); glass(wm)
icon(wm,'logo',UDim2.fromOffset(12,11),23)
label(wm,'FUCK VISUALS',UDim2.fromOffset(45,4),UDim2.fromOffset(155,19),13,true)
local wmInfo=label(wm,'BLADE / CLIENT HUD',UDim2.fromOffset(45,23),UDim2.fromOffset(230,15),10,false,C.dim)
local wmScale=make('UIScale',wm,{Scale=1})
local wmBorder=make('UIStroke',wm,{Color=C.accent,Transparency=1,Thickness=2})
local cross=frame(hud,UDim2.fromScale(.5,.5),UDim2.fromOffset(20,20),C.bg,1); cross.AnchorPoint=Vector2.new(.5,.5); cross.Visible=false
for _,s in ipairs({{8,0,4,6},{8,14,4,6},{0,8,6,4},{14,8,6,4}}) do round(frame(cross,UDim2.fromOffset(s[1],s[2]),UDim2.fromOffset(s[3],s[4]),C.accent,.1),2) end
local toast=frame(root,UDim2.new(.5,-130,1,-80),UDim2.fromOffset(260,38),C.bg,.08); glass(toast); toast.Visible=false
local toastText=label(toast,'',UDim2.fromOffset(12,0),UDim2.new(1,-24,1,0),12,true); toastText.TextXAlignment=Enum.TextXAlignment.Center
local toastId=0
local function notify(s)
    toastId=toastId+1; local id=toastId; toastText.Text=s; toast.Visible=true
    task.delay(2,function() if id==toastId and toast.Parent then toast.Visible=false end end)
end
local function viewport() return root.AbsoluteSize end
local function constrain(obj,x,y,scale)
    local v=viewport(); local w=obj.Size.X.Offset*scale; local h=obj.Size.Y.Offset*scale
    return math.clamp(x,0,math.max(0,v.X-w)),math.clamp(y,0,math.max(0,v.Y-h))
end
local function startDrag(obj,scaleObj,kind,input)
    if input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    motion={obj=obj,scale=scaleObj,kind=kind,mouse=UIS:GetMouseLocation(),pos=obj.AbsolutePosition-root.AbsolutePosition,initial=scaleObj.Scale}
end
local function attachDrag(obj,scaleObj,allow,resize)
    obj.Active=true
    obj.InputBegan:Connect(function(input) if allow() then startDrag(obj,scaleObj,'move',input) end end)
    if resize then
        local h=frame(obj,UDim2.new(1,-16,1,-16),UDim2.fromOffset(14,14),C.accent,.2); round(h,4); h.Visible=false; h.Active=true
        h.InputBegan:Connect(function(input) if allow() then startDrag(obj,scaleObj,'size',input) end end)
        return h
    end
end
local wmHandle=attachDrag(wm,wmScale,function() return editing end,true)
local definitions={{'fps','Frame rate','FPS'},{'ping','Network','ms'},{'clock','Local time',''},{'session','Session',''},{'health','Health','HP'},{'players','Players','online'},{'parry','Parry practice','hits'}}
for i,d in ipairs(definitions) do
    local box=frame(hud,UDim2.fromOffset(18+((i-1)%2)*158,77+math.floor((i-1)/2)*75),UDim2.fromOffset(148,65),C.bg,.18); glass(box)
    icon(box,d[1],UDim2.fromOffset(10,10),20)
    label(box,d[2],UDim2.fromOffset(36,8),UDim2.fromOffset(106,17),11,true,C.dim)
    local value=label(box,'--',UDim2.fromOffset(12,28),UDim2.fromOffset(124,27),21,true)
    local scale=make('UIScale',box,{Scale=1}); local outline=stroke(box,C.accent,1); outline.Thickness=2
    local handle=attachDrag(box,scale,function() return editing end,true)
    widgets[d[1]]={box=box,value=value,scale=scale,outline=outline,handle=handle,on=i<=4,name=d[2],index=i}; box.Visible=i<=4
end
local menu=frame(root,UDim2.new(.5,-240,.5,-190),UDim2.fromOffset(480,380),C.bg,.06); glass(menu); menu.Visible=false
local menuScale=make('UIScale',menu,{Scale=1}); local menuAnim=menuScale
icon(menu,'logo',UDim2.fromOffset(20,18),28)
label(menu,'FUCK VISUALS',UDim2.fromOffset(57,16),UDim2.fromOffset(250,25),19,true)
label(menu,'CLIENT STUDIO  /  02',UDim2.fromOffset(58,41),UDim2.fromOffset(250,15),10,false,C.dim)
local header=frame(menu,UDim2.fromOffset(0,0),UDim2.new(1,-60,0,63),C.bg,1); header.Active=true
header.InputBegan:Connect(function(input) startDrag(menu,menuScale,'move',input) end)
local function showMenu(on)
    menuOpen=on; menu.Visible=on
    if on then menuAnim.Scale=.94; tween(menuAnim,{Scale=1},.20) end
end
button(menu,'×',UDim2.new(1,-50,0,18),UDim2.fromOffset(32,32),function() showMenu(false) end)
local tabs=frame(menu,UDim2.fromOffset(18,72),UDim2.fromOffset(444,34),C.panel,.4); round(tabs,9)
local body=frame(menu,UDim2.fromOffset(18,118),UDim2.fromOffset(444,219),C.bg,1)
local pages={}; local tabButtons={}; local current='Visuals'
local function page(name) local p=frame(body,UDim2.fromScale(0,0),UDim2.fromScale(1,1),C.bg,1); pages[name]=p; return p end
local function selectPage(name)
    current=name
    for key,p in pairs(pages) do p.Visible=key==name; tabButtons[key].TextColor3=key==name and C.accent or C.dim end
end
local visual=page('Visuals'); local spray=page('Graffiti'); local sys=page('System'); local parry=page('Parry')
for i,key in ipairs({'Visuals','Parry','Graffiti','System'}) do tabButtons[key]=button(tabs,key,UDim2.fromOffset((i-1)*111+3,3),UDim2.fromOffset(105,28),function() selectPage(key) end) end
local toggleRefresh={}
local function toggle(parent,y,title,desc,key,cb)
    local item=frame(parent,UDim2.fromOffset(0,y),UDim2.new(1,0,0,62),C.panel,.28); round(item,10)
    label(item,title,UDim2.fromOffset(12,8),UDim2.fromOffset(350,20),13,true)
    label(item,desc,UDim2.fromOffset(12,30),UDim2.fromOffset(350,18),11,false,C.dim)
    local b=make('TextButton',item,{Position=UDim2.new(1,-55,0,18),Size=UDim2.fromOffset(43,25),Text='',AutoButtonColor=false,BackgroundColor3=C.panel,BorderSizePixel=0}); round(b,20)
    local knob=frame(b,UDim2.fromOffset(3,3),UDim2.fromOffset(19,19),C.ink,0); round(knob,20)
    local function update() tween(b,{BackgroundColor3=settings[key] and accents[settings.accent] or Color3.fromRGB(62,68,81)}); tween(knob,{Position=UDim2.fromOffset(settings[key] and 21 or 3,3)}) end
    table.insert(toggleRefresh,update); update()
    b.Activated:Connect(function() settings[key]=not settings[key]; update(); cb(settings[key]) end)
end
toggle(visual,0,'Watermark','Brand, FPS and latency','watermark',function(v) wm.Visible=v end)
toggle(visual,70,'Center marker','Cosmetic reticle only','crosshair',function(v) cross.Visible=v end)
toggle(visual,140,'Glass surface','Adjust HUD transparency','glass',function(v) wm.BackgroundTransparency=v and .12 or 0; for _,w in pairs(widgets) do w.box.BackgroundTransparency=v and .18 or 0 end end)
toggle(spray,0,'Graffiti','N places a local cosmetic tag','graffiti',function() end)
label(spray,'TAG SIZE',UDim2.fromOffset(2,78),UDim2.fromOffset(180,20),11,true,C.dim)
local sizeLabel=label(spray,'3 studs',UDim2.fromOffset(98,106),UDim2.fromOffset(230,30),14,true); sizeLabel.TextXAlignment=Enum.TextXAlignment.Center
local function changeSpray(delta) settings.spraySize=math.clamp(settings.spraySize+delta,1,6); sizeLabel.Text=settings.spraySize..' studs' end
button(spray,'−',UDim2.fromOffset(0,106),UDim2.fromOffset(90,30),function() changeSpray(-1) end)
button(spray,'+',UDim2.fromOffset(354,106),UDim2.fromOffset(90,30),function() changeSpray(1) end)
local decals={}
local function clearGraffiti() for _,p in ipairs(decals) do if p.Parent then p:Destroy() end end; table.clear(decals); markCount=0 end
button(spray,'Clear local graffiti',UDim2.fromOffset(0,152),UDim2.fromOffset(444,40),function() clearGraffiti(); notify('Graffiti cleared') end)
label(sys,'ACCENT PALETTE',UDim2.fromOffset(0,0),UDim2.fromOffset(300,24),11,true,C.dim)
for i,color in ipairs(accents) do
    local b=button(sys,'',UDim2.fromOffset((i-1)*113,31),UDim2.fromOffset(102,35),function()
        settings.accent=i; wmBorder.Color=color; for _,w in pairs(widgets) do w.outline.Color=color; w.handle.BackgroundColor3=color end; wmHandle.BackgroundColor3=color; for _,c in ipairs(cross:GetChildren()) do if c:IsA('Frame') then c.BackgroundColor3=color end end; for _,refresh in ipairs(toggleRefresh) do refresh() end; notify('Accent updated')
    end); local swatch=frame(b,UDim2.fromOffset(8,7),UDim2.fromOffset(86,21),color,0); round(swatch,6)
end
local function resetHUD()
    wm.Position=UDim2.fromOffset(18,18); wmScale.Scale=1
    for _,w in pairs(widgets) do local i=w.index; w.box.Position=UDim2.fromOffset(18+((i-1)%2)*158,77+math.floor((i-1)/2)*75); w.scale.Scale=1 end
    notify('HUD layout reset')
end
button(sys,'Reset HUD layout',UDim2.fromOffset(0,90),UDim2.fromOffset(444,38),resetHUD)
label(sys,'Ctrl menu   G HUD   N graffiti   F practice parry',UDim2.fromOffset(0,150),UDim2.fromOffset(444,35),12,false,C.dim)
label(menu,'LOCAL PRACTICE   •   V2',UDim2.fromOffset(19,344),UDim2.fromOffset(442,20),10,true,C.dim)
selectPage('Visuals')
local editor=frame(root,UDim2.new(1,-246,0,20),UDim2.fromOffset(226,406),C.bg,.08); glass(editor); editor.Visible=false
icon(editor,'edit',UDim2.fromOffset(12,12),22); label(editor,'HUD EDITOR',UDim2.fromOffset(42,10),UDim2.fromOffset(166,25),15,true)
label(editor,'Drag widgets / pull corner to resize',UDim2.fromOffset(12,41),UDim2.fromOffset(204,19),10,false,C.dim)
local rows={}
local function refreshRows() for key,b in pairs(rows) do local on=key=='wm' and settings.watermark or key~='wm' and widgets[key].on; b.Text=(on and '−  ' or '+  ')..(key=='wm' and 'Watermark' or widgets[key].name); b.TextColor3=on and C.ink or C.dim end end
local function setEditing(on)
    editing=on; editor.Visible=on; motion=nil; wmHandle.Visible=on; wmBorder.Transparency=on and .1 or 1
    for _,w in pairs(widgets) do w.handle.Visible=on; w.outline.Transparency=on and .1 or 1 end
    refreshRows()
end
rows.wm=button(editor,'',UDim2.fromOffset(12,68),UDim2.fromOffset(202,31),function() settings.watermark=not settings.watermark; wm.Visible=settings.watermark; for _,f in ipairs(toggleRefresh) do f() end; refreshRows() end)
for i,d in ipairs(definitions) do local key=d[1]; rows[key]=button(editor,'',UDim2.fromOffset(12,68+i*36),UDim2.fromOffset(202,31),function() local w=widgets[key]; w.on=not w.on; w.box.Visible=w.on; refreshRows() end) end
button(editor,'Done  [G]',UDim2.fromOffset(12,362),UDim2.fromOffset(202,31),function() setEditing(false) end)
refreshRows()
-- Local-only cosmetic surface tag. No replicated remotes or gameplay effects.
local function sprayTag()
    if not settings.graffiti or os.clock()-lastSpray<1 then return end
    local cam=workspace.CurrentCamera; if not cam then return end
    local ray=cam:ViewportPointToRay(cam.ViewportSize.X/2,cam.ViewportSize.Y/2)
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
    local filter={}; if player.Character then table.insert(filter,player.Character) end; for _,p in ipairs(decals) do if p.Parent then table.insert(filter,p) end end; params.FilterDescendantsInstances=filter
    local hit=workspace:Raycast(ray.Origin,ray.Direction*30,params)
    if not hit or not hit.Instance:IsA('BasePart') or not hit.Instance.Anchored then notify('Aim at a nearby static surface'); return end
    lastSpray=os.clock()
    for i=#decals,1,-1 do if not decals[i].Parent then table.remove(decals,i) end end
    if #decals>=12 then table.remove(decals,1):Destroy() end
    local normal=hit.Normal; local up=math.abs(normal:Dot(Vector3.yAxis))>.95 and Vector3.zAxis or Vector3.yAxis
    local size=settings.spraySize; local part=make('Part',workspace,{Name='FV_LocalTag',Size=Vector3.new(size,size*.48,.02),CFrame=CFrame.lookAt(hit.Position+normal*.035,hit.Position+normal,up),Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Transparency=1})
    local surface=make('SurfaceGui',part,{Face=Enum.NormalId.Front,CanvasSize=Vector2.new(500,240),AlwaysOnTop=false,LightInfluence=.15})
    local art=frame(surface,UDim2.fromScale(0,0),UDim2.fromScale(1,1),C.bg,1)
    icon(art,'logo',UDim2.fromOffset(10,35),150,accents[settings.accent])
    local t=label(art,'FV / 01',UDim2.fromOffset(168,28),UDim2.fromOffset(320,125),60,true,accents[settings.accent]); t.TextStrokeTransparency=.55
    label(art,'VISUAL DIVISION',UDim2.fromOffset(172,144),UDim2.fromOffset(315,45),27,true,C.ink)
    table.insert(decals,part); markCount=markCount+1; Debris:AddItem(part,60); notify('Local graffiti placed')
end
-- Standalone client-side practice simulation. It never inspects public match balls,
-- fires game remotes or modifies the character. Timing is based on relative motion.
local practice={ball=nil,velocity=Vector3.zero,hits=0,misses=0,streak=0,best=0,
    state='idle',nextAt=0,returnUntil=0,lastETA=nil,angle=0}
local function characterRoot()
    local char=player.Character
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    if not hum or hum.Health<=0 then return nil end
    return char:FindFirstChild('HumanoidRootPart')
end
local function destroyBall()
    if practice.ball then practice.ball:Destroy(); practice.ball=nil end
    practice.state='idle'; practice.lastETA=nil
end
local function scheduleBall(delay)
    destroyBall(); practice.nextAt=os.clock()+(delay or .7)
end
local function spawnPracticeBall(hrp)
    practice.angle=(practice.angle+137.5)%360
    local angle=math.rad(practice.angle)
    local dir=Vector3.new(math.cos(angle),0,math.sin(angle))
    local target=hrp.Position+Vector3.new(0,1,0)
    local ball=make('Part',workspace,{Name='FV_PracticeBall',Shape=Enum.PartType.Ball,Size=Vector3.new(2,2,2),Material=Enum.Material.Neon,Color=accents[settings.accent],Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Position=target+dir*math.max(45,settings.ballSpeed*1.1)})
    make('PointLight',ball,{Color=ball.Color,Brightness=1,Range=9})
    local a=make('Attachment',ball,{Position=Vector3.new(0,.65,0)})
    local b=make('Attachment',ball,{Position=Vector3.new(0,-.65,0)})
    make('Trail',ball,{Attachment0=a,Attachment1=b,Lifetime=.15,FaceCamera=true,Color=ColorSequence.new(ball.Color),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(1,1)})})
    practice.ball=ball; practice.velocity=-dir*settings.ballSpeed; practice.state='incoming'; practice.lastETA=nil
end
-- Solve time to the edge of a virtual contact sphere with relative velocity.
local function timeToContact(offset,relativeVelocity,radius)
    local c=offset:Dot(offset)-radius*radius
    if c<=0 then return 0 end
    local a=relativeVelocity:Dot(relativeVelocity)
    local b=2*offset:Dot(relativeVelocity)
    if a<.0001 or b>=0 then return nil end
    local disc=b*b-4*a*c
    if disc<0 then return nil end
    local t=(-b-math.sqrt(disc))/(2*a)
    return t>=0 and t or nil
end
local function parryFlash(hrp)
    local ring=make('Part',workspace,{Name='FV_ParryFlash',Shape=Enum.PartType.Ball,Size=Vector3.new(3,3,3),Position=hrp.Position,Material=Enum.Material.ForceField,Color=Color3.fromRGB(105,255,182),Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Transparency=.25})
    tween(ring,{Size=Vector3.new(10,10,10),Transparency=1},.28); Debris:AddItem(ring,.35)
end
local function executeParry(hrp)
    if practice.state~='incoming' or not practice.ball then return false end
    practice.state='return'; practice.hits=practice.hits+1; practice.streak=practice.streak+1
    practice.best=math.max(practice.streak,practice.best)
    local direction=practice.ball.Position-(hrp.Position+Vector3.new(0,1,0))
    if direction.Magnitude<.01 then direction=hrp.CFrame.LookVector end
    practice.velocity=direction.Unit*settings.ballSpeed*1.35; practice.returnUntil=os.clock()+.45
    practice.ball.Color=Color3.fromRGB(105,255,182); parryFlash(hrp)
    return true
end
local function manualParry()
    if not settings.practice or practice.state~='incoming' then return end
    local hrp=characterRoot(); if not hrp then return end
    local eta=practice.lastETA
    if eta and eta<=settings.parryWindow+.10 then executeParry(hrp) else notify('Too early / no contact predicted') end
end
local function practiceStep(dt)
    if not settings.practice then return end
    local hrp=characterRoot()
    if not hrp then if practice.ball then scheduleBall(.6) end; return end
    if not practice.ball then if os.clock()>=practice.nextAt then spawnPracticeBall(hrp) end; return end
    if practice.state=='return' then
        practice.ball.Position=practice.ball.Position+practice.velocity*math.min(dt,.1)
        if os.clock()>=practice.returnUntil then scheduleBall(.35) end
        return
    end
    local offset=practice.ball.Position-(hrp.Position+Vector3.new(0,1,0))
    if offset.Magnitude<.001 then practice.misses=practice.misses+1; practice.streak=0; scheduleBall(.55); return end
    -- Practice ball continuously aims toward the current local avatar.
    practice.velocity=-offset.Unit*settings.ballSpeed
    local eta=timeToContact(offset,practice.velocity-hrp.AssemblyLinearVelocity,3)
    local staticETA=math.max(0,(offset.Magnitude-3)/settings.ballSpeed)
    -- Use current distance as conservative fallback when movement is abrupt.
    eta=eta and math.min(eta,staticETA) or staticETA
    practice.lastETA=eta
    practice.ball.Color=eta<=settings.parryWindow+.12 and Color3.fromRGB(255,104,120) or accents[settings.accent]
    if settings.autoParry and eta<=settings.parryWindow+math.min(dt,.1) then executeParry(hrp); return end
    if staticETA<=dt then practice.misses=practice.misses+1; practice.streak=0; scheduleBall(.55); return end
    practice.ball.Position=practice.ball.Position+practice.velocity*math.min(dt,.1)
end
toggle(parry,0,'Practice arena','Local training ball / no public match hooks','practice',function(on)
    if on then scheduleBall(.25); notify('Practice started / F = manual parry') else destroyBall() end
end)
toggle(parry,67,'Predictive auto parry','Relative motion + time-to-contact','autoParry',function(on) if on then notify('Auto parry enabled for practice') end end)
local windowLabel=label(parry,'',UDim2.fromOffset(98,139),UDim2.fromOffset(248,30),12,true); windowLabel.TextXAlignment=Enum.TextXAlignment.Center
local speedLabel=label(parry,'',UDim2.fromOffset(98,176),UDim2.fromOffset(248,30),12,true); speedLabel.TextXAlignment=Enum.TextXAlignment.Center
local function updateParryLabels()
    windowLabel.Text=string.format('Lead time: %d ms',math.floor(settings.parryWindow*1000+.5))
    speedLabel.Text=string.format('Ball speed: %d studs/s',settings.ballSpeed)
end
local function adjustWindow(d) settings.parryWindow=math.clamp(settings.parryWindow+d,.06,.36); updateParryLabels() end
local function adjustSpeed(d) settings.ballSpeed=math.clamp(settings.ballSpeed+d,35,165); updateParryLabels() end
button(parry,'−',UDim2.fromOffset(0,139),UDim2.fromOffset(90,30),function() adjustWindow(-.02) end)
button(parry,'+',UDim2.fromOffset(354,139),UDim2.fromOffset(90,30),function() adjustWindow(.02) end)
button(parry,'−',UDim2.fromOffset(0,176),UDim2.fromOffset(90,30),function() adjustSpeed(-10) end)
button(parry,'+',UDim2.fromOffset(354,176),UDim2.fromOffset(90,30),function() adjustSpeed(10) end)
updateParryLabels()
local connections={}
local function bind(signal,callback) local c=signal:Connect(callback); table.insert(connections,c); return c end
bind(Run.Heartbeat,practiceStep)
bind(UIS.InputChanged,function(input)
    if not motion or input.UserInputType~=Enum.UserInputType.MouseMovement then return end
    local m=motion; local delta=UIS:GetMouseLocation()-m.mouse
    if m.kind=='size' then m.scale.Scale=math.clamp(m.initial+(delta.X+delta.Y)/(m.obj.Size.X.Offset+m.obj.Size.Y.Offset),.65,1.8); local x,y=constrain(m.obj,m.pos.X,m.pos.Y,m.scale.Scale); m.obj.Position=UDim2.fromOffset(x,y)
    else local x,y=constrain(m.obj,m.pos.X+delta.X,m.pos.Y+delta.Y,m.scale.Scale); m.obj.Position=UDim2.fromOffset(x,y) end
end)
bind(UIS.InputEnded,function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then motion=nil end end)
bind(UIS.InputBegan,function(input,processed)
    if processed or UIS:GetFocusedTextBox() then return end
    if input.KeyCode==Enum.KeyCode.LeftControl or input.KeyCode==Enum.KeyCode.RightControl then showMenu(not menuOpen)
    elseif input.KeyCode==Enum.KeyCode.G then setEditing(not editing)
    elseif input.KeyCode==Enum.KeyCode.N then sprayTag()
    elseif input.KeyCode==Enum.KeyCode.F then manualParry() end
end)
local frames,elapsed=0,0
bind(Run.RenderStepped,function(dt)
    frames=frames+1; elapsed=elapsed+dt
    if elapsed<.5 then return end
    fps=math.floor(frames/elapsed+.5); frames=0; elapsed=0
    local ok,value=pcall(function() return player:GetNetworkPing() end); ping=ok and tostring(math.floor(value*1000+.5)) or '--'
    wmInfo.Text=string.format('%d FPS   /   %s ms   /   CLIENT',fps,ping)
    widgets.fps.value.Text=tostring(fps)..' FPS'; widgets.ping.value.Text=ping..' ms'; widgets.clock.value.Text=os.date('%H:%M:%S')
    local s=math.floor(os.clock()-start); widgets.session.value.Text=string.format('%02d:%02d:%02d',math.floor(s/3600),math.floor(s/60)%60,s%60)
    local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid'); widgets.health.value.Text=hum and string.format('%d / %d',math.floor(hum.Health),math.floor(hum.MaxHealth)) or '--'
    widgets.players.value.Text=tostring(#Players:GetPlayers())..' online'
    widgets.parry.value.Text=string.format('%d / %d',practice.hits,practice.hits+practice.misses)
end)
root.Destroying:Connect(function() for _,c in ipairs(connections) do c:Disconnect() end; clearGraffiti(); destroyBall() end)
