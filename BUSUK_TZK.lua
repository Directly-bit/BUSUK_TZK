--[[
    🚐 БУСИК ТЦК v3.3 — FINAL
    Меню с 4 кнопками, консоль, полёт, смерть SVO
]]

local UIS  = game:GetService("UserInputService")
local RS   = game:GetService("RunService")
local CA   = game:GetService("ContextActionService")
local TW   = game:GetService("TweenService")
local W    = game:GetService("Workspace")
local LP   = game:GetService("Players").LocalPlayer
local CAM  = W.CurrentCamera

-- ═══════════ КОНФИГ ═══════════
local CFG = {
    SPEED  = 250,
    TURN   = 2,
    FLY    = 100,
    UP     = 50,
    SIZE   = Vector3.new(10, 8, 22),
    COLOR  = Color3.fromRGB(45, 45, 45),
    ACCENT = Color3.fromRGB(255, 220, 0),
    KEY    = Enum.KeyCode.F,
}

-- ═══════════ СОСТОЯНИЕ ═══════════
local S = {
    bus     = nil,
    inBus   = false,
    flying  = false,
    vk      = {},
    savedCF = nil,
}

local function log(...) print("[BusTCK]", ...) end

-- ═══════════ UI ХЕЛПЕРЫ ═══════════
local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do
        pcall(function() o[k] = v end)
    end
    if parent then o.Parent = parent end
    return o
end

local function corner(p, r)
    new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, p)
end

local function stroke(p, c, t, tr)
    new("UIStroke", {
        Color = c or Color3.new(1, 1, 1),
        Thickness = t or 1,
        Transparency = tr or 0.4,
    }, p)
end

local PG = LP:FindFirstChildOfClass("PlayerGui")
if not PG then
    PG = Instance.new("PlayerGui")
    PG.Parent = LP
end

-- ═══════════════════════════════════════════════════════════
-- МЕНЮ
-- ═══════════════════════════════════════════════════════════
local menuGui = new("ScreenGui", {
    Name = "BusTCK_Menu",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PG)

-- Иконка меню
local icon = new("TextButton", {
    Name = "MenuIcon",
    Size = UDim2.new(0, 60, 0, 60),
    Position = UDim2.new(0, 20, 0, 80),
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    TextColor3 = CFG.ACCENT,
    Text = "🚐",
    TextSize = 30,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    ZIndex = 50,
}, menuGui)
corner(icon, 30)
stroke(icon, CFG.ACCENT, 2, 0)

-- Панель меню — высота 360, влезают все кнопки
local PANEL_H = 360
local panel = new("Frame", {
    Name = "Panel",
    Size = UDim2.new(0, 280, 0, PANEL_H),
    Position = UDim2.new(0, 20, 0, 150),
    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false,
    ZIndex = 49,
}, menuGui)
corner(panel, 14)
stroke(panel, CFG.ACCENT, 1.5, 0.4)

-- Заголовок
local title = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Text = "🚐  БУСИК ТЦК",
    TextColor3 = CFG.ACCENT,
    Font = Enum.Font.GothamBlack,
    TextSize = 20,
    ZIndex = 51,
}, panel)
corner(title, 14)

-- Хелпер кнопки меню — ВСЕГДА непрозрачная
local function mkMenuBtn(text, y, color, key)
    local btn = new("TextButton", {
        Name = "Btn_" .. key,
        Size = UDim2.new(1, -24, 0, 54),
        Position = UDim2.new(0, 12, 0, y),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        BackgroundTransparency = 0,
        TextColor3 = color,
        Text = text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 51,
    }, panel)
    corner(btn, 10)
    stroke(btn, color, 1, 0.5)
    return btn
end

local btnSpawn = mkMenuBtn("🚐  Создать бусик", 58,  Color3.fromRGB(0, 220, 0),  "spawn")
local btnEnter = mkMenuBtn("🚪  Сесть / Выйти", 120, CFG.ACCENT,                  "enter")
local btnFly   = mkMenuBtn("✈  Полёт: ВЫКЛ",    182, Color3.fromRGB(0, 200, 255), "fly")
local btnDel   = mkMenuBtn("🗑  Удалить бусик",  244, Color3.fromRGB(255, 80, 80), "delete")

-- Подсказка внизу
new("TextLabel", {
    Size = UDim2.new(1, -24, 0, 50),
    Position = UDim2.new(0, 12, 0, 304),
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    Text = "F — создать/удалить\nSpace/Shift — вверх/вниз",
    TextColor3 = Color3.fromRGB(180, 180, 180),
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextWrapped = true,
    ZIndex = 51,
}, panel)

-- Открытие/закрытие
local menuOpen = false
local function setOpen(state)
    menuOpen = state
    icon.Text = state and "✕" or "🚐"
    if state then
        panel.Visible = true
        panel.Size = UDim2.new(0, 280, 0, 0)
        TW:Create(panel, TweenInfo.new(0.2), {Size = UDim2.new(0, 280, 0, PANEL_H)}):Play()
    else
        local t = TW:Create(panel, TweenInfo.new(0.15), {Size = UDim2.new(0, 280, 0, 0)})
        t:Play()
        t.Completed:Connect(function()
            if not menuOpen then panel.Visible = false end
        end)
    end
end

icon.MouseButton1Click:Connect(function()
    setOpen(not menuOpen)
end)

-- Обновление кнопок (не через Transparency, а через цвет + Active)
local function refreshMenu()
    local hasBus = S.bus ~= nil

    btnSpawn.Text = hasBus and "🗑  Удалить бусик" or "🚐  Создать бусик"
    btnSpawn.TextColor3 = hasBus and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(0, 220, 0)

    local function setEnabled(btn, on)
        btn.Active = on
        btn.TextColor3 = on and btn.TextColor3 or Color3.fromRGB(120, 120, 120)
        btn.BackgroundColor3 = on and Color3.fromRGB(35, 35, 35)
            or Color3.fromRGB(22, 22, 22)
    end

    setEnabled(btnEnter, hasBus)
    setEnabled(btnFly, hasBus)
    setEnabled(btnDel, hasBus)

    btnFly.Text = S.flying and "✈  Полёт: ВКЛ" or "✈  Полёт: ВЫКЛ"
    btnFly.BackgroundColor3 = S.flying
        and Color3.fromRGB(0, 90, 130)
        or Color3.fromRGB(35, 35, 35)
end

-- ═══════════════════════════════════════════════════════════
-- КОНСОЛЬ (при посадке)
-- ═══════════════════════════════════════════════════════════
local consGui = new("ScreenGui", {
    Name = "BusTCK_Console",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    Enabled = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PG)

local consPanel = new("Frame", {
    Size = UDim2.new(0, 460, 0, 180),
    Position = UDim2.new(0.5, -230, 1, -200),
    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
}, consGui)
corner(consPanel, 16)
stroke(consPanel, CFG.ACCENT, 2, 0.35)

local function mkC(txt, pos, col, key)
    local b = new("TextButton", {
        Size = UDim2.new(0, 66, 0, 66),
        Position = pos,
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        TextColor3 = col,
        Text = txt,
        TextSize = 24,
        Font = Enum.Font.GothamBlack,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, consPanel)
    corner(b, 33)
    stroke(b, col, 1.5, 0.5)

    -- Только ВАЛИДНЫЕ события TextButton
    b.MouseButton1Down:Connect(function() S.vk[key] = true end)
    b.MouseButton1Up:Connect(function()   S.vk[key] = false end)
    b.MouseLeave:Connect(function()       S.vk[key] = false end)
    b.TouchLongPress:Connect(function()   S.vk[key] = true end)
    return b
end

mkC("▲", UDim2.new(0, 20,  0, 20),  Color3.new(1, 1, 1),          "W")
mkC("◀", UDim2.new(0, 100, 0, 95),  Color3.new(1, 1, 1),          "A")
mkC("▼", UDim2.new(0, 180, 0, 95),  Color3.new(1, 1, 1),          "S")
mkC("▶", UDim2.new(0, 260, 0, 95),  Color3.new(1, 1, 1),          "D")
mkC("⬆", UDim2.new(1, -200, 0, 20), Color3.fromRGB(0, 200, 255),  "Up")
mkC("⬇", UDim2.new(1, -200, 0, 95), Color3.fromRGB(0, 200, 255),  "Dn")

local btnExit = mkC("💀", UDim2.new(1, -120, 0, 55), Color3.fromRGB(255, 80, 80), "Exit")

-- Глобальный сброс vk (страховка от залипания)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        for k in pairs(S.vk) do
            S.vk[k] = false
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- ЭКРАН СМЕРТИ
-- ═══════════════════════════════════════════════════════════
local function showDeath()
    local g = new("ScreenGui", {
        Name = "BusTCK_Death",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
    }, PG)

    local bg = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, g)

    local top = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(140, 0, 0),
        BorderSizePixel = 0,
    }, g)

    local bot = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 0),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Color3.fromRGB(140, 0, 0),
        BorderSizePixel = 0,
    }, g)

    local main = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 140),
        Position = UDim2.new(0.5, 0, 0.5, -80),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Text = "SVO НЕ ИЗБЕЖАААТЬ",
        TextColor3 = Color3.fromRGB(255, 30, 30),
        TextScaled = true,
        Font = Enum.Font.GothamBlack,
        TextStrokeTransparency = 0,
        TextStrokeColor3 = Color3.new(0, 0, 0),
        TextTransparency = 1,
    }, g)

    local sub = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 80),
        Position = UDim2.new(0.5, 0, 0.5, 60),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Text = "ТЦК БУСИИК",
        TextColor3 = CFG.ACCENT,
        TextScaled = true,
        Font = Enum.Font.GothamBlack,
        TextStrokeTransparency = 0,
        TextStrokeColor3 = Color3.new(0, 0, 0),
        TextTransparency = 1,
    }, g)

    local t0 = tick()
    local sc
    sc = RS.RenderStepped:Connect(function()
        local t = tick() - t0
        local a = 8 * math.max(0, 1 - t / 1.5)
        main.Position = UDim2.new(0.5, (math.random() - 0.5) * a, 0.5, -80 + (math.random() - 0.5) * a)
        sub.Position  = UDim2.new(0.5, (math.random() - 0.5) * a, 0.5,  60 + (math.random() - 0.5) * a)
        main.TextColor3 = Color3.fromRGB(255, math.floor(30 + math.sin(t * 12) * 40), 30)
    end)

    TW:Create(bg, TweenInfo.new(0.4), {BackgroundTransparency = 0.3}):Play()
    TW:Create(top, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0.25, 0)}):Play()
    TW:Create(bot, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0.25, 0)}):Play()

    task.delay(0.2, function()
        TW:Create(main, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    end)
    task.delay(0.5, function()
        TW:Create(sub, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    end)

    task.delay(4, function()
        if sc then sc:Disconnect() end
        TW:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TW:Create(main, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        TW:Create(sub,  TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        TW:Create(top,  TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        TW:Create(bot,  TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        task.wait(0.6)
        g:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════
-- БУСИК
-- ═══════════════════════════════════════════════════════════
local function sideText(part, face)
    local g = new("SurfaceGui", {
        Face = face,
        CanvasSize = Vector2.new(800, 400),
        LightInfluence = 0,
    }, part)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "ТЦК",
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        Font = Enum.Font.GothamBlack,
    }, g)
end

local function buildBus(cf)
    local m = Instance.new("Model")
    m.Name = "BusTCK"
    local Sz = CFG.SIZE

    local body = new("Part", {
        Name = "Body",
        Size = Sz,
        Color = CFG.COLOR,
        Material = Enum.Material.Metal,
        Anchored = true,
        CanCollide = false,
        CFrame = cf,
        TopSurface = Enum.SurfaceType.Smooth,
        BottomSurface = Enum.SurfaceType.Smooth,
    }, m)

    local stripe = new("Part", {
        Size = Vector3.new(Sz.X + 0.1, 1.2, Sz.Z + 0.1),
        Color = CFG.ACCENT,
        Material = Enum.Material.Neon,
        Anchored = false,
        CanCollide = false,
        Massless = true,
        CFrame = body.CFrame * CFrame.new(0, -Sz.Y / 4, 0),
    }, m)
    new("WeldConstraint", {Part0 = body, Part1 = stripe, Parent = stripe})

    local roof = new("Part", {
        Size = Vector3.new(Sz.X - 0.4, 0.6, Sz.Z - 0.4),
        Color = CFG.COLOR,
        Material = Enum.Material.Metal,
        Anchored = false,
        CanCollide = false,
        Massless = true,
        CFrame = body.CFrame * CFrame.new(0, Sz.Y / 2 + 0.3, 0),
    }, m)
    new("WeldConstraint", {Part0 = body, Part1 = roof, Parent = roof})

    local wR = 2.4
    for i, off in ipairs({
        Vector3.new(-Sz.X / 2 - 0.2, -Sz.Y / 2 + 1,  Sz.Z / 2 - 3),
        Vector3.new( Sz.X / 2 + 0.2, -Sz.Y / 2 + 1,  Sz.Z / 2 - 3),
        Vector3.new(-Sz.X / 2 - 0.2, -Sz.Y / 2 + 1, -Sz.Z / 2 + 3),
        Vector3.new( Sz.X / 2 + 0.2, -Sz.Y / 2 + 1, -Sz.Z / 2 + 3),
    }) do
        local w = new("Part", {
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(1.6, wR * 2, wR * 2),
            Color = Color3.fromRGB(15, 15, 15),
            Material = Enum.Material.Rubber,
            Anchored = false,
            CanCollide = false,
            Massless = true,
            CFrame = body.CFrame * CFrame.new(off) * CFrame.Angles(0, 0, math.rad(90)),
        }, m)
        new("WeldConstraint", {Part0 = body, Part1 = w, Parent = w})
    end

    for _, sx in ipairs({-1, 1}) do
        local h = new("Part", {
            Size = Vector3.new(1.6, 1.6, 0.4),
            Color = Color3.fromRGB(255, 255, 200),
            Material = Enum.Material.Neon,
            Anchored = false,
            CanCollide = false,
            Massless = true,
            CFrame = body.CFrame * CFrame.new(sx * (Sz.X / 4), 0, -Sz.Z / 2 - 0.1),
        }, m)
        new("WeldConstraint", {Part0 = body, Part1 = h, Parent = h})
        new("SpotLight", {Face = Enum.NormalId.Front, Range = 90, Brightness = 4}, h)
    end

    sideText(body, Enum.NormalId.Left)
    sideText(body, Enum.NormalId.Right)

    local att = new("Attachment", {}, body)
    local lv = new("LinearVelocity", {
        Attachment0 = att,
        RelativeTo = Enum.ActuatorRelativeTo.World,
        MaxForce = math.huge,
        VectorVelocity = Vector3.zero,
        ForceLimitMode = Enum.ForceLimitMode.Magnitude,
        MaxAxesForce = Vector3.new(1e6, 1e6, 1e6),
    }, body)
    local ao = new("AlignOrientation", {
        Mode = Enum.OrientationAlignmentMode.OneAttachment,
        Attachment0 = att,
        RigidityEnabled = false,
        MaxTorque = math.huge,
        Responsiveness = 25,
        CFrame = body.CFrame,
    }, body)
    local av = new("VectorForce", {
        Attachment0 = att,
        RelativeTo = Enum.ActuatorRelativeTo.World,
        ApplyAtCenterOfMass = true,
        Force = Vector3.zero,
    }, body)

    return {model = m, body = body, lv = lv, ao = ao, av = av}
end

-- ═══════════════════════════════════════════════════════════
-- СПАВН / ДЕСПАВН
-- ═══════════════════════════════════════════════════════════
local function spawnBus()
    if S.bus then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then log("Нет HRP"); return end

    local cf = hrp.CFrame * CFrame.new(0, 10, -20)
    local ok, bus = pcall(buildBus, cf)
    if not ok then log("buildBus err:", bus); return end

    bus.model.Parent = W
    bus.model:PivotTo(cf)
    bus.body.Anchored = false
    task.wait()

    if bus.body.Parent then
        bus.body.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5, 1, 1)
        bus.av.Force = Vector3.new(0, bus.body.AssemblyMass * W.Gravity, 0)
    end

    S.bus = bus
    log("✅ Бусик создан")
    refreshMenu()
end

local function despawnBus()
    if not S.bus then return end
    if S.inBus then kill() end
    S.bus.model:Destroy()
    S.bus = nil
    S.flying = false
    log("🗑 Бусик удалён")
    refreshMenu()
end

-- ═══════════════════════════════════════════════════════════
-- ПОСАДКА / СМЕРТЬ
-- ═══════════════════════════════════════════════════════════
local function enterBus()
    if not S.bus or S.inBus then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    S.savedCF = hrp.CFrame
    hum.WalkSpeed = 0
    hum.JumpPower = 0
    hum.PlatformStand = true
    hrp.CFrame = S.bus.body.CFrame * CFrame.new(0, 0, CFG.SIZE.Z / 2 - 3)
    hrp.Velocity = Vector3.zero

    CAM.CameraType = Enum.CameraType.Custom
    CAM.CameraSubject = S.bus.body

    CA:BindAction("BusUp", function(_, st)
        if st == Enum.UserInputState.Begin then S.vk.Space = true
        elseif st == Enum.UserInputState.End then S.vk.Space = false end
    end, false, Enum.KeyCode.Space)

    CA:BindAction("BusDn", function(_, st)
        if st == Enum.UserInputState.Begin then S.vk.Shift = true
        elseif st == Enum.UserInputState.End then S.vk.Shift = false end
    end, false, Enum.KeyCode.LeftShift)

    S.inBus = true
    consGui.Enabled = true
    log("🚪 Посадка")
end

function kill()
    if not S.inBus then return end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    S.inBus = false
    consGui.Enabled = false
    CA:UnbindAction("BusUp")
    CA:UnbindAction("BusDn")

    if hum then
        hum.PlatformStand = false
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        pcall(function() hum.Health = 0 end)
    end

    showDeath()
    log("💀 SVO НЕ ИЗБЕЖАААТЬ")
end

-- ═══════════════════════════════════════════════════════════
-- ФИЗИКА (delta-time)
-- ═══════════════════════════════════════════════════════════
RS.Heartbeat:Connect(function(dt)
    local bus = S.bus
    if not bus or not bus.body or not bus.body.Parent then return end

    if not S.inBus then
        bus.lv.VectorVelocity = Vector3.zero
        return
    end

    local k = function(code) return UIS:IsKeyDown(code) end
    local W_ = k(Enum.KeyCode.W) or S.vk.W
    local S_ = k(Enum.KeyCode.S) or S.vk.S
    local A_ = k(Enum.KeyCode.A) or S.vk.A
    local D_ = k(Enum.KeyCode.D) or S.vk.D
    local Up = S.vk.Space or S.vk.Up
    local Dn = S.vk.Shift or S.vk.Dn

    local body, lv, ao = bus.body, bus.lv, bus.ao

    -- Поворот
    local turn = (A_ and 1 or 0) - (D_ and 1 or 0)
    if turn ~= 0 then
        body.CFrame = body.CFrame * CFrame.Angles(0, turn * CFG.TURN * dt, 0)
        ao.CFrame = body.CFrame
    end

    -- Движение
    local fwd = body.CFrame.LookVector
    local thr = (W_ and 1 or 0) - (S_ and 1 or 0)
    local sp = S.flying and CFG.FLY or CFG.SPEED

    local vel = fwd * sp * thr
    if S.flying then
        if Up then vel = vel + Vector3.new(0,  CFG.UP, 0) end
        if Dn then vel = vel + Vector3.new(0, -CFG.UP, 0) end
    end
    lv.VectorVelocity = vel

    -- Держим игрока внутри
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Velocity = Vector3.zero
        hrp.CFrame = body.CFrame * CFrame.new(0, 0, CFG.SIZE.Z / 2 - 3)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- ОБРАБОТЧИКИ КНОПОК МЕНЮ
-- ═══════════════════════════════════════════════════════════
btnSpawn.MouseButton1Click:Connect(function()
    if S.bus then despawnBus() else spawnBus() end
end)

btnEnter.MouseButton1Click:Connect(function()
    if not S.bus then return end
    if S.inBus then kill() else enterBus() end
    setOpen(false)
end)

btnFly.MouseButton1Click:Connect(function()
    if not S.bus or not S.inBus then return end
    S.flying = not S.flying
    refreshMenu()
end)

btnDel.MouseButton1Click:Connect(function()
    despawnBus()
    setOpen(false)
end)

btnExit.MouseButton1Click:Connect(function()
    kill()
end)

-- ═══════════════════════════════════════════════════════════
-- ХОТКЕЙ F
-- ═══════════════════════════════════════════════════════════
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == CFG.KEY then
        if S.bus then despawnBus() else spawnBus() end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- РЕСПАВН
-- ═══════════════════════════════════════════════════════════
LP.CharacterAdded:Connect(function()
    if S.inBus then
        S.inBus = false
        consGui.Enabled = false
    end
    if S.bus then despawnBus() end
    setOpen(false)
end)

-- ═══════════════════════════════════════════════════════════
-- ИНИЦИАЛИЗАЦИЯ
-- ═══════════════════════════════════════════════════════════
refreshMenu()

log("✅ БУСИК ТЦК v3.3 загружен")
log("F — создать | тап 🚐 — меню")
