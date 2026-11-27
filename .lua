-- PULSE VISUALS V4 | LocalScript in StarterPlayerScripts
-- Local cosmetic effects only. No changes to other players or server physics.
local P = game:GetService('Players')
local U = game:GetService('UserInputService')
local R = game:GetService('RunService')
local T = game:GetService('TweenService')
local L = game:GetService('Lighting')
local D = game:GetService('Debris')
local p = P.LocalPlayer
local pg = p:WaitForChild('PlayerGui')
local old = pg:FindFirstChild('PulseVisualsV2')
if old then old:Destroy() end
local gui = Instance.new('ScreenGui')
gui.Name = 'PulseVisualsV2'; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.Parent = pg
local effects = Instance.new('Folder', workspace); effects.Name = 'PulseLocalEffects'
local purple = Color3.fromRGB(168,120,255)
local red = Color3.fromRGB(255,35,65)
local green = Color3.fromRGB(40,255,135)
local flags = {}
local originalFov=workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
local connections = {}
local function connect(signal, fn) local c = signal:Connect(fn); table.insert(connections,c); return c end
local function tween(obj, sec, props) local t = T:Create(obj,TweenInfo.new(sec,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),props); t:Play(); return t end
local function round(obj,n) local c = Instance.new('UICorner',obj); c.CornerRadius = UDim.new(0,n or 12) end
local function label(parent, txt, sz, pos, size)
 local a = Instance.new('TextLabel',parent); a.BackgroundTransparency = 1; a.Text = txt; a.TextColor3 = Color3.fromRGB(240,240,250); a.TextSize = sz; a.Font = Enum.Font.GothamMedium; a.Position = pos; a.Size = size; return a
end

-- 24x24 original SVG-style paths, drawn natively as GUI strokes.
local iconPaths = {
 pulse={{{2,12},{6,12},{9,4},{14,20},{17,12},{22,12}}},
 wave={{{2,12},{5,12},{7,7},{10,17},{13,4},{16,20},{19,12},{22,12}}},
 sahur={{{8,3},{16,3},{19,6},{19,18},{16,21},{8,21},{5,18},{5,6},{8,3}},{{9,9},{9,10}},{{15,9},{15,10}},{{9,15},{12,17},{15,15}}},
 ghost={{{4,20},{4,10},{6,5},{12,3},{18,5},{20,10},{20,20},{16,17},{12,20},{8,17},{4,20}},{{9,10},{9,11}},{{15,10},{15,11}}},
 bolt={{{13,2},{4,13},{11,13},{10,22},{20,10},{13,10},{13,2}}},
 blur={{{3,6},{16,6}},{{6,12},{21,12}},{{3,18},{16,18}}},
 landing={{{12,3},{12,15}},{{7,10},{12,15},{17,10}},{{3,20},{21,20}}},
 aura={{{12,2},{14,9},{22,12},{14,15},{12,22},{9,15},{2,12},{9,9},{12,2}}},
 trail={{{3,5},{11,5},{17,11},{21,11}},{{3,12},{9,12},{15,18},{21,18}}},
 sky={{{3,17},{3,13},{6,10},{9,10},{11,5},{16,5},{19,10},{21,12},{21,17},{3,17}}},
 rgb={{{12,3},{21,8},{21,16},{12,21},{3,16},{3,8},{12,3}},{{3,8},{12,13},{21,8}},{{12,13},{12,21}}},
 freeze={{{12,2},{12,22}},{{3,7},{21,17}},{{3,17},{21,7}},{{8,5},{12,9},{16,5}},{{8,19},{12,15},{16,19}}},
 cinema={{{3,5},{21,5},{21,19},{3,19},{3,5}},{{3,9},{21,9}},{{3,15},{21,15}}},
 music={{{4,9},{4,15}},{{8,5},{8,19}},{{12,2},{12,22}},{{16,6},{16,18}},{{20,9},{20,15}}},
 cross={{{12,2},{12,8}},{{12,16},{12,22}},{{2,12},{8,12}},{{16,12},{22,12}}},
 fov={{{9,4},{4,4},{4,9}},{{15,4},{20,4},{20,9}},{{4,15},{4,20},{9,20}},{{20,15},{20,20},{15,20}}},
 clock={{{12,2},{19,5},{22,12},{19,19},{12,22},{5,19},{2,12},{5,5},{12,2}},{{12,6},{12,12},{16,14}}},
 close={{{5,5},{19,19}},{{19,5},{5,19}}},
 arrow={{{9,5},{16,12},{9,19}}},
}
local rowIcons = {
 ['Shockwave / knockback FX']='wave',
 ['Tung Tung Tung Sahur']='sahur',
 ['Ghost Mode']='ghost',
 ['Dash FX']='bolt',
 ['Motion Blur']='blur',
 ['Landing FX']='landing',
 ['Aura Studio']='aura',
 ['Neon Trails']='trail',
 ['Atmosphere filter']='sky',
 ['Character RGB']='rgb',
 ['Time Freeze FX']='freeze',
 ['Cinematic Mode']='cinema',
 ['Animated equalizer (demo)']='music',
 ['Custom Crosshair']='cross',
 ['Wide FOV']='fov',
 ['Watermark']='pulse',
 ['Close / cleanup']='close',
}
local function icon(parent,name,position,size,tint,z)
 local host=Instance.new('Frame',parent); host.BackgroundTransparency=1; host.Size=UDim2.fromOffset(size,size); host.Position=position; host.ZIndex=z
 local scale=size/24
 for _,path in ipairs(iconPaths[name] or iconPaths.pulse) do
  for i=2,#path do
   local a,b=path[i-1],path[i]; local dx,dy=b[1]-a[1],b[2]-a[2]
   local line=Instance.new('Frame',host); line.AnchorPoint=Vector2.new(.5,.5); line.Position=UDim2.fromOffset((a[1]+b[1])*scale/2,(a[2]+b[2])*scale/2)
   line.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy)*scale+1.2,1.65); line.Rotation=math.deg(math.atan2(dy,dx)); line.BackgroundColor3=tint; line.BorderSizePixel=0; line.ZIndex=z+1; round(line,2)
  end
 end
 return host
end

local function root() local c = p.Character; return c and c:FindFirstChild('HumanoidRootPart') end
local function part(size,cf,color,shape)
 local a = Instance.new('Part'); a.Size = size; a.CFrame = cf; a.Color = color; a.Material = Enum.Material.Neon; a.Anchored = true; a.CanCollide = false; a.CanTouch = false; a.CanQuery = false; if shape then a.Shape = shape end; a.Parent = effects; return a
end
local function ring(pos,color,maxSize)
 local a = part(Vector3.new(.13,2,2),CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2),color,Enum.PartType.Cylinder); a.Transparency = .58
 tween(a,.65,{Size=Vector3.new(.08,maxSize,maxSize),Transparency=1}); D:AddItem(a,.7)
end
local function sparks(pos,color,count)
 for i=1,count do
  local a = part(Vector3.new(.18,.18,.18),CFrame.new(pos),color,Enum.PartType.Ball)
  local v = Vector3.new(math.random(-8,8),math.random(1,7),math.random(-8,8)); tween(a,.6,{Position=pos+v,Transparency=1,Size=Vector3.new(.04,.04,.04)}); D:AddItem(a,.65)
 end
end
local function shockwave()
 local r = root(); if not r then return end
 ring(r.Position-Vector3.new(0,2.6,0),purple,26); sparks(r.Position,purple,20)
 -- A locally generated abstract training cube, animated, not a real character.
 local a = part(Vector3.new(2,2,2),r.CFrame*CFrame.new(0,0,-6),purple); a.Material = Enum.Material.SmoothPlastic
 local v = r.CFrame.LookVector; tween(a,.65,{CFrame=a.CFrame+v*14+Vector3.new(0,5,0),Transparency=1}); D:AddItem(a,.8)
end
local function sahur()
 local r = root(); if not r then return end
 local base = r.CFrame*CFrame.new(0,0,-8)
 local pieces = {}
 local function piece(size,offset,col,shape)
  local a = part(size,base*offset,col,shape); a.Material = Enum.Material.Wood; table.insert(pieces,{a,offset}); return a
 end
 local wood = Color3.fromRGB(156,97,53)
 piece(Vector3.new(2.2,3.8,1.7),CFrame.new(0,1,0),wood)
 piece(Vector3.new(1.8,1.7,1.7),CFrame.new(0,3.4,0),wood,Enum.PartType.Ball)
 for _,x in ipairs({-.43,.43}) do
  local a=piece(Vector3.new(.32,.42,.14),CFrame.new(x,3.55,-.76),Color3.new(1,1,1)); a.Material=Enum.Material.SmoothPlastic
  local b=piece(Vector3.new(.14,.22,.13),CFrame.new(x,3.55,-.86),Color3.new(0,0,0)); b.Material=Enum.Material.SmoothPlastic
 end
 piece(Vector3.new(.52,2.1,.55),CFrame.new(-1.4,1.1,0)*CFrame.Angles(0,0,-.4),wood)
 piece(Vector3.new(.52,2.1,.55),CFrame.new(1.4,1.1,0)*CFrame.Angles(0,0,.4),wood)
 for _,x in ipairs({-.65,.65}) do piece(Vector3.new(.65,1.6,.65),CFrame.new(x,-1.35,0),wood) end
 local tag = Instance.new('BillboardGui',pieces[2][1]); tag.Size=UDim2.fromOffset(230,55); tag.StudsOffset=Vector3.new(0,2,0); tag.AlwaysOnTop=true
 label(tag,'TUNG TUNG TUNG SAHUR',18,UDim2.new(),UDim2.fromScale(1,1))
 task.spawn(function()
  for i=1,3 do
   for _,v in ipairs(pieces) do if v[1].Parent then tween(v[1],.15,{CFrame=base*CFrame.new(0,.8,0)*v[2]}) end end
   ring(base.Position-Vector3.new(0,2,0),Color3.fromRGB(255,170,80),9); task.wait(.17)
   for _,v in ipairs(pieces) do if v[1].Parent then tween(v[1],.17,{CFrame=base*v[2]}) end end; task.wait(.25)
  end
  for _,v in ipairs(pieces) do if v[1].Parent then tween(v[1],.5,{Transparency=1}); D:AddItem(v[1],.6) end end
 end)
end
local edges={}; local edgeTweens={}; local hold=false; local token=0
for i=1,4 do
 local f=Instance.new('Frame',gui); f.BorderSizePixel=0; f.BackgroundTransparency=1; f.BackgroundColor3=red; f.ZIndex=2
 local g=Instance.new('UIGradient',f); g.Transparency=NumberSequence.new(0,1)
 if i<=2 then f.Size=UDim2.fromScale(.13,1); f.Position=UDim2.fromScale(i==1 and 0 or .87,0); g.Rotation=i==1 and 0 or 180
 else f.Size=UDim2.fromScale(1,.13); f.Position=UDim2.fromScale(0,i==3 and 0 or .87); g.Rotation=i==3 and 90 or 270 end
 table.insert(edges,f)
end
local function glow(color,alpha,time) for _,f in ipairs(edges) do if edgeTweens[f] then edgeTweens[f]:Cancel() end; edgeTweens[f]=tween(f,time,{BackgroundColor3=color,BackgroundTransparency=alpha}) end end
local function release() if not hold then return end; hold=false; token=token+1; local n=token; glow(green,.35,.22); task.delay(.24,function() if token==n and not hold and gui.Parent then glow(green,1,.65) end end) end
local panel=Instance.new('Frame',gui); panel.Size=UDim2.fromOffset(390,475); panel.Position=UDim2.new(.5,-195,.5,-237); panel.BackgroundColor3=Color3.fromRGB(20,22,34); panel.BackgroundTransparency=.12; panel.BorderSizePixel=0; panel.ZIndex=5; round(panel,22)
local stroke=Instance.new('UIStroke',panel); stroke.Color=purple; stroke.Transparency=.5
icon(panel,'pulse',UDim2.fromOffset(16,13),24,purple,6)
local head=label(panel,'PULSE / VISUALS',22,UDim2.fromOffset(48,8),UDim2.new(1,-64,0,34)); head.TextXAlignment=Enum.TextXAlignment.Left; head.ZIndex=6; head.Active=true
local subtitle=label(panel,'CTRL menu  •  R hold  •  Q wave  •  T sahur',12,UDim2.fromOffset(16,42),UDim2.new(1,-32,0,25)); subtitle.TextXAlignment=Enum.TextXAlignment.Left; subtitle.ZIndex=6
local scroll=Instance.new('ScrollingFrame',panel); scroll.Position=UDim2.fromOffset(12,75); scroll.Size=UDim2.new(1,-24,1,-87); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=3; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(); scroll.ZIndex=6
local layout=Instance.new('UIListLayout',scroll); layout.Padding=UDim.new(0,6)
local function row(name,action,isToggle)
 if name=='Watermark' then flags[name]=true end
 local b=Instance.new('TextButton',scroll); b.Size=UDim2.new(1,-6,0,38); b.BackgroundColor3=Color3.fromRGB(40,43,61); b.BackgroundTransparency=.2; b.BorderSizePixel=0; b.Text=''; b.ZIndex=7; round(b,10)
 icon(b,rowIcons[name],UDim2.fromOffset(10,9),20,purple,8)
 local txt=label(b,name,14,UDim2.fromOffset(39,0),UDim2.new(1,-105,1,0)); txt.TextXAlignment=Enum.TextXAlignment.Left; txt.ZIndex=8
 local pill=Instance.new('Frame',b); pill.Size=UDim2.fromOffset(43,23); pill.Position=UDim2.new(1,-55,.5,-11); pill.BackgroundColor3=Color3.fromRGB(85,85,100); pill.ZIndex=8; round(pill,20)
 local knob=Instance.new('Frame',pill); knob.Size=UDim2.fromOffset(17,17); knob.Position=UDim2.fromOffset(3,3); knob.BackgroundColor3=Color3.new(1,1,1); knob.ZIndex=9; round(knob,20)
 if isToggle and flags[name] then pill.BackgroundColor3=purple; knob.Position=UDim2.fromOffset(23,3) end
 if not isToggle then pill.Visible=false; local x=label(b,'RUN',12,UDim2.new(1,-55,0,0),UDim2.fromOffset(48,38)); x.ZIndex=8 end
 connect(b.Activated,function() if isToggle then flags[name]=not flags[name]; tween(pill,.2,{BackgroundColor3=flags[name] and purple or Color3.fromRGB(85,85,100)}); tween(knob,.2,{Position=UDim2.fromOffset(flags[name] and 23 or 3,3)}); if action then action(flags[name]) end else action() end end)
end
local blur=Instance.new('BlurEffect',L); blur.Name='PulseLocalBlur'; blur.Size=0
local color=Instance.new('ColorCorrectionEffect',L); color.Name='PulseLocalColor'; color.Enabled=false
local cross=label(gui,'+',25,UDim2.new(.5,-15,.5,-15),UDim2.fromOffset(30,30)); cross.Visible=false; cross.ZIndex=4
-- Compact, single-line HUD inspired by the public Pulse layout.
local mark=Instance.new('Frame',gui)
mark.Name='PulseWatermark'; mark.Size=UDim2.fromOffset(0,32); mark.AutomaticSize=Enum.AutomaticSize.X
mark.Position=UDim2.fromOffset(14,14); mark.BackgroundColor3=Color3.fromRGB(18,18,20); mark.BackgroundTransparency=.16; mark.BorderSizePixel=0; mark.ZIndex=10; round(mark,10)
local markStroke=Instance.new('UIStroke',mark); markStroke.Color=Color3.fromRGB(255,255,255); markStroke.Transparency=.88
local padding=Instance.new('UIPadding',mark); padding.PaddingLeft=UDim.new(0,9); padding.PaddingRight=UDim.new(0,10)
local markLayout=Instance.new('UIListLayout',mark); markLayout.FillDirection=Enum.FillDirection.Horizontal; markLayout.VerticalAlignment=Enum.VerticalAlignment.Center; markLayout.SortOrder=Enum.SortOrder.LayoutOrder; markLayout.Padding=UDim.new(0,8)
local white=Color3.fromRGB(241,241,244)
local muted=Color3.fromRGB(180,180,188)
local logo=icon(mark,'pulse',UDim2.new(),18,white,11); logo.LayoutOrder=1
local function divider(order)
 local f=Instance.new('Frame',mark); f.Size=UDim2.fromOffset(1,15); f.BackgroundColor3=Color3.fromRGB(255,255,255); f.BackgroundTransparency=.83; f.BorderSizePixel=0; f.ZIndex=11; f.LayoutOrder=order
end
divider(2)
local avatar=Instance.new('ImageLabel',mark); avatar.Name='Avatar'; avatar.Size=UDim2.fromOffset(19,19); avatar.BackgroundColor3=Color3.fromRGB(56,56,62); avatar.BorderSizePixel=0; avatar.ZIndex=11; avatar.LayoutOrder=3; round(avatar,6)
task.spawn(function()
 local ok,url=pcall(function() return P:GetUserThumbnailAsync(p.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)
 if ok and avatar.Parent then avatar.Image=url end
end)
local function markText(txt,order,tint)
 local a=label(mark,txt,12,UDim2.new(),UDim2.fromOffset(0,24)); a.AutomaticSize=Enum.AutomaticSize.X; a.TextXAlignment=Enum.TextXAlignment.Left; a.TextColor3=tint; a.LayoutOrder=order; a.ZIndex=11; return a
end
local nameLabel=markText(p.Name,4,white); nameLabel.Font=Enum.Font.GothamBold
divider(5)
local pingLabel=markText('-- ms',6,muted)
divider(7)
local fpsLabel=markText('-- FPS',8,white)
local fpsFrames,fpsElapsed=0,0
local bars=Instance.new('Frame',gui); bars.BackgroundTransparency=1; bars.Size=UDim2.fromOffset(130,40); bars.Position=UDim2.new(1,-150,1,-65); bars.Visible=false
local barList={}; for i=1,12 do local b=Instance.new('Frame',bars); b.AnchorPoint=Vector2.new(0,1); b.Position=UDim2.fromOffset((i-1)*10,40); b.Size=UDim2.fromOffset(7,5); b.BackgroundColor3=purple; b.BorderSizePixel=0; round(b,3); table.insert(barList,b) end
local hi=Instance.new('Highlight',effects); hi.Enabled=false; hi.FillTransparency=.7; hi.OutlineTransparency=.1
local cinema=Instance.new('Frame',gui); cinema.Size=UDim2.fromScale(1,1); cinema.BackgroundTransparency=1; cinema.Visible=false
for i=1,2 do local b=Instance.new('Frame',cinema); b.BackgroundColor3=Color3.new(0,0,0); b.BorderSizePixel=0; b.Size=UDim2.fromScale(1,.09); b.Position=UDim2.fromScale(0,i==1 and 0 or .91) end
row('Shockwave / knockback FX',shockwave,false); row('Tung Tung Tung Sahur',sahur,false)
row('Ghost Mode',nil,true); row('Dash FX',function() local r=root(); if r then sparks(r.Position,purple,18) end end,false)
row('Motion Blur',nil,true); row('Landing FX',nil,true); row('Aura Studio',nil,true); row('Neon Trails',nil,true)
row('Atmosphere filter',function(v) color.Enabled=v; color.TintColor=Color3.fromRGB(178,194,255); color.Contrast=.15; color.Saturation=-.1 end,true)
row('Character RGB',function(v) hi.Enabled=v end,true)
row('Time Freeze FX',function(v) color.Enabled=v or flags['Atmosphere filter']; color.Saturation=v and -1 or -.1; color.TintColor=v and Color3.fromRGB(210,230,255) or Color3.fromRGB(178,194,255) end,true)
row('Cinematic Mode',function(v) cinema.Visible=v end,true)
row('Animated equalizer (demo)',function(v) bars.Visible=v end,true)
row('Custom Crosshair',function(v) cross.Visible=v end,true)
row('Wide FOV',function(v) local c=workspace.CurrentCamera; if c then c.FieldOfView=v and 95 or originalFov end end,true)
row('Watermark',function(v) mark.Visible=v end,true)
row('Close / cleanup',function() gui:Destroy() end,false)
local dragStart, startPos, dragging
connect(head.InputBegan,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; startPos=panel.Position end end)
connect(U.InputChanged,function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dragStart; panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
connect(U.InputBegan,function(i,g) if g then return end; if i.KeyCode==Enum.KeyCode.LeftControl then panel.Visible=not panel.Visible elseif i.KeyCode==Enum.KeyCode.R and not hold then hold=true; token=token+1; glow(red,.28,.2) elseif i.KeyCode==Enum.KeyCode.Q then shockwave() elseif i.KeyCode==Enum.KeyCode.T then sahur() end end)
connect(U.InputEnded,function(i) if i.KeyCode==Enum.KeyCode.R then release() elseif i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
connect(U.WindowFocusReleased,function() dragging=false; release() end)
local last=0; local lastDir; local lastGround=true; local lastPos
connect(R.RenderStepped,function(dt)
 local c=workspace.CurrentCamera; if not c then return end
 local now=os.clock(); local r=root(); local dir=c.CFrame.LookVector
 local speed=lastDir and (dir-lastDir).Magnitude/math.max(dt,.001) or 0; lastDir=dir
 blur.Size=blur.Size+( (flags['Motion Blur'] and math.clamp(speed*2,0,14) or 0)-blur.Size)*math.min(dt*10,1)
 local rgb=Color3.fromHSV((now*.18)%1,.75,1); hi.Adornee=p.Character; hi.FillColor=rgb; hi.OutlineColor=rgb
 fpsFrames+=1; fpsElapsed+=dt
 if fpsElapsed>=.5 then
  local fps=math.floor(fpsFrames/fpsElapsed+.5); fpsLabel.Text=tostring(fps)..' FPS'
  local ok,ping=pcall(function() return p:GetNetworkPing() end)
  pingLabel.Text=ok and type(ping)=='number' and string.format('%d ms',math.floor(ping*1000+.5)) or '-- ms'
  fpsFrames=0; fpsElapsed=0
 end
 if bars.Visible then for i,b in ipairs(barList) do b.Size=UDim2.fromOffset(7,5+30*math.abs(math.sin(now*5+i*.9))) end end
 if not r then lastPos=nil; return end
 local hum=p.Character and p.Character:FindFirstChildOfClass('Humanoid'); local grounded=hum and hum.FloorMaterial~=Enum.Material.Air
 if grounded and not lastGround and flags['Landing FX'] then ring(r.Position-Vector3.new(0,2.5,0),purple,12); sparks(r.Position,purple,10) end; lastGround=grounded
 if now-last>=.17 then
  last=now; local moving=lastPos and (r.Position-lastPos).Magnitude>.4; lastPos=r.Position
  if flags['Aura Studio'] then local a=part(Vector3.new(.25,.25,.25),CFrame.new(r.Position+Vector3.new(math.cos(now*4)*2,math.sin(now*3),math.sin(now*4)*2)),rgb,Enum.PartType.Ball); tween(a,.5,{Transparency=1}); D:AddItem(a,.6) end
  if moving and flags['Neon Trails'] then local a=part(Vector3.new(.3,.3,.3),r.CFrame*CFrame.new(0,-2,1),rgb,Enum.PartType.Ball); tween(a,.8,{Transparency=1}); D:AddItem(a,.9) end
  if moving and flags['Ghost Mode'] then for _,body in ipairs(p.Character:GetChildren()) do if body:IsA('BasePart') and body~=r then local a=part(body.Size,body.CFrame,purple); a.Transparency=.65; tween(a,.45,{Transparency=1}); D:AddItem(a,.5) end end end
 end
end)
connect(gui.Destroying,function() for _,c in ipairs(connections) do c:Disconnect() end; effects:Destroy(); blur:Destroy(); color:Destroy(); if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=originalFov end end)
