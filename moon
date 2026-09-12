local MoonUI = {}
MoonUI.__index = MoonUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local C = {
    bg         = Color3.fromRGB(13, 13, 15),
    card       = Color3.fromRGB(24, 24, 28),
    cardHover  = Color3.fromRGB(31, 31, 36),
    inner      = Color3.fromRGB(18, 18, 22),
    accent     = Color3.fromRGB(167, 139, 250),
    accentDeep = Color3.fromRGB(139, 92, 246),
    text       = Color3.fromRGB(229, 229, 229),
    textDim    = Color3.fromRGB(120, 120, 128),
    border     = Color3.fromRGB(35, 35, 42),
    track      = Color3.fromRGB(45, 45, 55),
}

local ROW_HEIGHT = 36
local BODY_BASE = 24

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = parent
    return c
end

local function bindClick(button, fn)
    button.Active = true
    local lock = 0
    button.MouseButton1Click:Connect(function()
        if tick() - lock < 0.05 then return end
        lock = tick()
        pcall(fn)
    end)
end

local function makeDraggable(frame, dragArea, onClick)
    dragArea = dragArea or frame
    local dragging, dragStart, startPos, moved = false, nil, nil, false
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved and onClick then pcall(onClick) end
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then moved = true end
            if moved then
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

local function makeRow(parent, labelText, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -36, 0, height or 30)
    row.BackgroundTransparency = 1
    row.ZIndex = 8
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.55, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = C.text
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 9
    lbl.Parent = row

    return row, lbl
end

local function createSlider(parent, labelText, minV, maxV, defaultV, step, onChange)
    local row = makeRow(parent, labelText, 30)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 130, 0, 4)
    track.Position = UDim2.new(1, -80, 0.5, 0)
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.BackgroundColor3 = C.track
    track.BorderSizePixel = 0
    track.ZIndex = 9
    track.Parent = row
    corner(track, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C.accentDeep
    fill.BorderSizePixel = 0
    fill.ZIndex = 10
    fill.Parent = track
    corner(fill, 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = C.accent
    knob.BorderSizePixel = 0
    knob.ZIndex = 11
    knob.Parent = track
    corner(knob, 7)

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(0, 60, 1, 0)
    valueLbl.Position = UDim2.new(1, 0, 0, 0)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = tostring(defaultV)
    valueLbl.TextColor3 = C.text
    valueLbl.TextSize = 13
    valueLbl.Font = Enum.Font.GothamMedium
    valueLbl.TextXAlignment = Enum.TextXAlignment.Right
    valueLbl.ZIndex = 9
    valueLbl.Parent = row

    local value = defaultV
    local function setValue(v)
        v = math.clamp(v, minV, maxV)
        if step then v = math.floor(v / step + 0.5) * step end
        value = v
        local p = (v - minV) / (maxV - minV)
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, 0)
        valueLbl.Text = string.format("%.2f", v):gsub("%.?0+$", "")
        if onChange then pcall(onChange, v) end
    end
    setValue(defaultV)

    local dragging = false
    local function updateFromInput(input)
        local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        setValue(minV + rel * (maxV - minV))
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {row = row, setValue = setValue, getValue = function() return value end}
end

local function createButton(parent, labelText, valueText, width, cb)
    local row = makeRow(parent, labelText, 30)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(width or 80, 24)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.BackgroundColor3 = C.inner
    btn.Text = valueText or ""
    btn.TextColor3 = C.text
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.AutoButtonColor = false
    btn.ZIndex = 10
    btn.Active = true
    btn.Parent = row
    corner(btn, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.border
    stroke.Thickness = 1
    stroke.Parent = btn

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.cardHover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.inner end)
    if cb then btn.MouseButton1Click:Connect(function() pcall(cb, btn) end) end

    return btn
end

local function createToggleRow(parent, labelText, defaultValue, onChange)
    local row = makeRow(parent, labelText, 30)

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.fromOffset(36, 20)
    switch.Position = UDim2.new(1, 0, 0.5, 0)
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.BackgroundColor3 = defaultValue and C.accentDeep or C.track
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.BorderSizePixel = 0
    switch.ZIndex = 10
    switch.Active = true
    switch.Parent = row
    corner(switch, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = defaultValue and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 11
    knob.Parent = switch
    corner(knob, 8)

    local value = defaultValue
    local function update(v)
        value = v
        switch.BackgroundColor3 = v and C.accentDeep or C.track
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = v and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        }):Play()
        if onChange then pcall(onChange, v) end
    end
    switch.MouseButton1Click:Connect(function() update(not value) end)

    return {getValue = function() return value end, setValue = update}
end

local function createTextbox(parent, labelText, placeholder, defaultText, onSubmit)
    local row = makeRow(parent, labelText, 30)

    local box = Instance.new("TextBox")
    box.Size = UDim2.fromOffset(120, 24)
    box.Position = UDim2.new(1, 0, 0.5, 0)
    box.AnchorPoint = Vector2.new(1, 0.5)
    box.BackgroundColor3 = C.inner
    box.Text = defaultText or ""
    box.PlaceholderText = placeholder or ""
    box.TextColor3 = C.text
    box.PlaceholderColor3 = C.textDim
    box.TextSize = 12
    box.Font = Enum.Font.GothamMedium
    box.ClearTextOnFocus = false
    box.ZIndex = 10
    box.Parent = row
    corner(box, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.border
    stroke.Thickness = 1
    stroke.Parent = box

    box.FocusLost:Connect(function(enter)
        if onSubmit then pcall(onSubmit, box.Text, enter) end
    end)

    return box
end

local function createKeybind(parent, labelText, defaultKey, onChange)
    local row = makeRow(parent, labelText, 30)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(80, 24)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.BackgroundColor3 = C.inner
    btn.Text = defaultKey and defaultKey.Name or "None"
    btn.TextColor3 = C.text
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.AutoButtonColor = false
    btn.ZIndex = 10
    btn.Active = true
    btn.Parent = row
    corner(btn, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.border
    stroke.Thickness = 1
    stroke.Parent = btn

    local currentKey = defaultKey
    local listening = false
    local conn = nil

    btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "..."
        if conn then conn:Disconnect() end
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if listening and (input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton) then
                currentKey = input.KeyCode
                btn.Text = currentKey.Name
                listening = false
                if conn then conn:Disconnect() conn = nil end
                if onChange then pcall(onChange, currentKey) end
            end
        end)
    end)

    return {
        getKey = function() return currentKey end,
        setKey = function(k)
            currentKey = k
            btn.Text = k and k.Name or "None"
            if onChange then pcall(onChange, k) end
        end
    }
end

local function createSection(page, title, opts, guiRoot)
    opts = opts or {}

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = C.card
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.ZIndex = 7
    card.Parent = page
    corner(card, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.border
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = card

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundTransparency = 1
    header.ZIndex = 8
    header.Parent = card

    local titleLabel = Instance.new("TextButton")
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.new(0, 18, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = C.text
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.AutoButtonColor = false
    titleLabel.Active = true
    titleLabel.ZIndex = 9
    titleLabel.Parent = header

    local plusBtn = Instance.new("TextButton")
    plusBtn.Size = UDim2.fromOffset(28, 28)
    plusBtn.Position = UDim2.new(1, -46, 0.5, 0)
    plusBtn.AnchorPoint = Vector2.new(0, 0.5)
    plusBtn.BackgroundTransparency = 1
    plusBtn.Text = "+"
    plusBtn.TextColor3 = C.textDim
    plusBtn.TextSize = 20
    plusBtn.Font = Enum.Font.GothamBold
    plusBtn.AutoButtonColor = false
    plusBtn.Active = true
    plusBtn.ZIndex = 10
    plusBtn.Parent = header

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 0, 0)
    body.Position = UDim2.new(0, 0, 0, 60)
    body.BackgroundTransparency = 1
    body.ClipsDescendants = true
    body.ZIndex = 8
    body.Parent = card

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.Padding = UDim.new(0, 6)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = body

    local bodyPadding = Instance.new("UIPadding")
    bodyPadding.PaddingTop = UDim.new(0, 8)
    bodyPadding.PaddingBottom = UDim.new(0, 14)
    bodyPadding.Parent = body

    local expanded = false
    local enabled = false
    local rowCount = 0

    local function computeBodyHeight()
        if rowCount <= 0 then return BODY_BASE end
        return rowCount * ROW_HEIGHT + BODY_BASE
    end

    local function refreshHeight()
        if not expanded then return end
        local targetH = computeBodyHeight()
        TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 60 + targetH)
        }):Play()
        TweenService:Create(body, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, targetH)
        }):Play()
    end

    plusBtn.MouseEnter:Connect(function() plusBtn.TextColor3 = C.text end)
    plusBtn.MouseLeave:Connect(function()
        plusBtn.TextColor3 = expanded and C.accent or C.textDim
    end)

    bindClick(plusBtn, function()
        expanded = not expanded
        plusBtn.Text = expanded and "−" or "+"
        plusBtn.TextColor3 = expanded and C.accent or C.textDim
        if expanded then
            refreshHeight()
        else
            TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, 60)
            }):Play()
            TweenService:Create(body, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
        end
    end)

    bindClick(titleLabel, function()
        enabled = not enabled
        titleLabel.TextColor3 = enabled and C.accent or C.text
        if opts.onToggle then pcall(opts.onToggle, enabled) end
    end)

    local section = {}
    section.card = card
    section.body = body
    section.title = titleLabel
    section.plus = plusBtn
    section.isEnabled = function() return enabled end
    section.setEnabled = function(v)
        enabled = v
        titleLabel.TextColor3 = v and C.accent or C.text
        if opts.onToggle then pcall(opts.onToggle, v) end
    end

    function section:addSlider(label, minV, maxV, def, step, cb)
        rowCount = rowCount + 1
        local r = createSlider(body, label, minV, maxV, def, step, cb)
        refreshHeight()
        return r
    end
    function section:addButton(label, valueText, width, cb)
        rowCount = rowCount + 1
        local r = createButton(body, label, valueText, width, cb)
        refreshHeight()
        return r
    end
    function section:addToggle(label, def, cb)
        rowCount = rowCount + 1
        local r = createToggleRow(body, label, def, cb)
        refreshHeight()
        return r
    end
    function section:addTextbox(label, placeholder, def, cb)
        rowCount = rowCount + 1
        local r = createTextbox(body, label, placeholder, def, cb)
        refreshHeight()
        return r
    end
    function section:addKeybind(label, def, cb)
        rowCount = rowCount + 1
        local r = createKeybind(body, label, def, cb)
        refreshHeight()
        return r
    end
    function section:addLabel(text)
        rowCount = rowCount + 1
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -36, 0, 20)
        row.BackgroundTransparency = 1
        row.ZIndex = 8
        row.Parent = body
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = C.textDim
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 9
        lbl.Parent = row
        refreshHeight()
        return lbl
    end
    function section:addDivider()
        rowCount = rowCount + 1
        local d = Instance.new("Frame")
        d.Size = UDim2.new(1, -36, 0, 1)
        d.BackgroundColor3 = C.border
        d.BorderSizePixel = 0
        d.ZIndex = 9
        d.Parent = body
        refreshHeight()
        return d
    end
    function section:addDropdown(label, options, defaultOption, onSelect, guiPass)
        rowCount = rowCount + 1
        guiPass = guiPass or guiRoot

        local row = makeRow(body, label, 30)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(120, 24)
        btn.Position = UDim2.new(1, 0, 0.5, 0)
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.BackgroundColor3 = C.inner
        btn.Text = defaultOption or (options and options[1] or "")
        btn.TextColor3 = C.text
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamMedium
        btn.AutoButtonColor = false
        btn.ZIndex = 10
        btn.Active = true
        btn.Parent = row
        corner(btn, 6)

        local stroke2 = Instance.new("UIStroke")
        stroke2.Color = C.border
        stroke2.Thickness = 1
        stroke2.Parent = btn

        local panel = Instance.new("Frame")
        panel.BackgroundColor3 = C.card
        panel.BorderSizePixel = 0
        panel.Visible = false
        panel.ZIndex = 500
        panel.Parent = guiPass or gui
        corner(panel, 6)

        local panelStroke = Instance.new("UIStroke")
        panelStroke.Color = C.border
        panelStroke.Thickness = 1
        panelStroke.Parent = panel

        local panelLayout = Instance.new("UIListLayout")
        panelLayout.Padding = UDim.new(0, 0)
        panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
        panelLayout.Parent = panel

        local selected = defaultOption or (options and options[1])

        local function addOption(opt)
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 24)
            optBtn.BackgroundTransparency = 1
            optBtn.Text = opt
            optBtn.TextColor3 = C.text
            optBtn.TextSize = 12
            optBtn.Font = Enum.Font.GothamMedium
            optBtn.AutoButtonColor = false
            optBtn.ZIndex = 501
            optBtn.Active = true
            optBtn.Parent = panel
            optBtn.MouseEnter:Connect(function()
                optBtn.BackgroundTransparency = 0
                optBtn.BackgroundColor3 = C.cardHover
            end)
            optBtn.MouseLeave:Connect(function()
                optBtn.BackgroundTransparency = 1
            end)
            optBtn.MouseButton1Click:Connect(function()
                selected = opt
                btn.Text = opt
                panel.Visible = false
                if onSelect then pcall(onSelect, opt) end
            end)
        end

        if options then
            for _, opt in ipairs(options) do addOption(opt) end
        end

        btn.MouseButton1Click:Connect(function()
            if panel.Visible then
                panel.Visible = false
            else
                local abs = btn.AbsolutePosition
                local absSize = btn.AbsoluteSize
                panel.Position = UDim2.fromOffset(abs.X, abs.Y + absSize.Y + 4)
                local optCount = 0
                for _, ch in ipairs(panel:GetChildren()) do
                    if ch:IsA("TextButton") then optCount = optCount + 1 end
                end
                panel.Size = UDim2.fromOffset(absSize.X, optCount * 24)
                panel.Visible = true
            end
        end)

        refreshHeight()

        return {
            getValue = function() return selected end,
            setValue = function(v)
                selected = v
                btn.Text = v
                if onSelect then pcall(onSelect, v) end
            end,
            setOptions = function(list)
                for _, ch in ipairs(panel:GetChildren()) do
                    if ch:IsA("TextButton") then ch:Destroy() end
                end
                for _, opt in ipairs(list) do addOption(opt) end
            end
        }
    end

    return section
end

function MoonUI:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Moon"
    local subtitle = config.Subtitle or ""
    local tag = config.Tag
    local winSize = config.Size or UDim2.fromOffset(900, 580)
    local guiName = config.Name or "MoonUI"

    for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if g.Name == guiName then g:Destroy() end
    end
    pcall(function()
        if gethui then
            for _, g in ipairs(gethui():GetChildren()) do
                if g.Name == guiName then g:Destroy() end
            end
        end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = guiName
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local parented = false
    pcall(function()
        if gethui then gui.Parent = gethui() parented = true end
    end)
    if not parented then
        pcall(function() gui.Parent = game:GetService("CoreGui") parented = true end)
    end
    if not parented then
        pcall(function()
            local pg = LocalPlayer:WaitForChild("PlayerGui", 5)
            if pg then gui.Parent = pg parented = true end
        end)
    end
    if not parented then return nil end

    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(280, 38)
    pill.AnchorPoint = Vector2.new(0.5, 0)
    pill.Position = UDim2.new(0.5, 0, 0, 16)
    pill.BackgroundColor3 = Color3.fromRGB(140, 80, 240)
    pill.BorderSizePixel = 0
    pill.Active = true
    pill.Visible = false
    pill.ZIndex = 10
    pill.Parent = gui
    corner(pill, 19)

    local pillGradient = Instance.new("UIGradient")
    pillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(124, 58, 237)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168, 85, 247)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(192, 132, 252)),
    })
    pillGradient.Parent = pill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Color = Color3.fromRGB(216, 180, 254)
    pillStroke.Thickness = 1
    pillStroke.Transparency = 0.5
    pillStroke.Parent = pill

    local pillText = Instance.new("TextLabel")
    pillText.Size = UDim2.new(1, -20, 1, 0)
    pillText.Position = UDim2.new(0, 10, 0, 0)
    pillText.BackgroundTransparency = 1
    pillText.Text = title .. "  ·  FPS: 60  ·  Ping: 0"
    pillText.TextColor3 = Color3.fromRGB(255, 255, 255)
    pillText.TextSize = 14
    pillText.Font = Enum.Font.GothamBold
    pillText.TextStrokeTransparency = 1
    pillText.ZIndex = 11
    pillText.Parent = pill

    task.spawn(function()
        local frames = 0
        local last = tick()
        RunService.RenderStepped:Connect(function() frames = frames + 1 end)
        while pill.Parent do
            task.wait(1)
            local now = tick()
            local fps = math.floor(frames / (now - last))
            frames = 0
            last = now
            local ping = 0
            pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
            pillText.Text = string.format("%s  ·  FPS: %d  ·  Ping: %d", title, fps, ping)
        end
    end)

    local main = Instance.new("Frame")
    main.Size = winSize
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = C.bg
    main.BorderSizePixel = 0
    main.Active = false
    main.ZIndex = 5
    main.Parent = gui
    corner(main, 14)

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = C.border
    mainStroke.Thickness = 1
    mainStroke.Parent = main

    pcall(function()
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local sc = Instance.new("UIScale")
        sc.Scale = math.min(1, vp.X / (winSize.X.Offset + 100), vp.Y / (winSize.Y.Offset + 120))
        sc.Parent = main
    end)

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.fromOffset(34, 30)
    minBtn.Position = UDim2.new(1, -80, 0, 6)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "—"
    minBtn.TextColor3 = C.textDim
    minBtn.TextSize = 18
    minBtn.Font = Enum.Font.GothamBold
    minBtn.AutoButtonColor = false
    minBtn.ZIndex = 100
    minBtn.Parent = main

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(34, 30)
    closeBtn.Position = UDim2.new(1, -42, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = C.textDim
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 100
    closeBtn.Parent = main

    minBtn.MouseEnter:Connect(function() minBtn.TextColor3 = C.text end)
    minBtn.MouseLeave:Connect(function() minBtn.TextColor3 = C.textDim end)
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = C.text end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = C.textDim end)

    bindClick(minBtn, function()
        main.Visible = false
        pill.Visible = true
    end)
    bindClick(closeBtn, function() gui.Enabled = false end)

    makeDraggable(pill, pill, function()
        main.Visible = true
        pill.Visible = false
    end)

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 200, 1, 0)
    sidebar.BackgroundTransparency = 1
    sidebar.ZIndex = 6
    sidebar.Parent = main

    local logoArea = Instance.new("Frame")
    logoArea.Size = UDim2.new(0, 200, 0, 70)
    logoArea.BackgroundTransparency = 1
    logoArea.Active = true
    logoArea.ZIndex = 7
    logoArea.Parent = sidebar
    makeDraggable(main, logoArea)

    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, -30, 0, 28)
    logoText.Position = UDim2.new(0, 20, 0, 20)
    logoText.BackgroundTransparency = 1
    logoText.Text = title
    logoText.TextColor3 = C.text
    logoText.TextSize = 22
    logoText.Font = Enum.Font.GothamBold
    logoText.TextXAlignment = Enum.TextXAlignment.Left
    logoText.ZIndex = 8
    logoText.Parent = logoArea

    if tag and tag ~= "" then
        local logoTag = Instance.new("TextLabel")
        logoTag.Size = UDim2.fromOffset(30, 16)
        logoTag.Position = UDim2.new(0, 20 + (#title * 11), 0, 26)
        logoTag.BackgroundColor3 = C.accentDeep
        logoTag.Text = tag
        logoTag.TextColor3 = Color3.fromRGB(255, 255, 255)
        logoTag.TextSize = 10
        logoTag.Font = Enum.Font.GothamBold
        logoTag.ZIndex = 8
        logoTag.Parent = logoArea
        corner(logoTag, 4)
    end

    local logoSub = Instance.new("TextLabel")
    logoSub.Size = UDim2.new(1, -30, 0, 16)
    logoSub.Position = UDim2.new(0, 20, 0, 48)
    logoSub.BackgroundTransparency = 1
    logoSub.Text = subtitle
    logoSub.TextColor3 = C.textDim
    logoSub.TextSize = 11
    logoSub.Font = Enum.Font.GothamMedium
    logoSub.TextXAlignment = Enum.TextXAlignment.Left
    logoSub.ZIndex = 8
    logoSub.Parent = logoArea

    local tabList = Instance.new("ScrollingFrame")
    tabList.Size = UDim2.new(1, -20, 1, -80)
    tabList.Position = UDim2.new(0, 10, 0, 75)
    tabList.BackgroundTransparency = 1
    tabList.BorderSizePixel = 0
    tabList.ScrollBarThickness = 2
    tabList.ScrollBarImageColor3 = C.border
    tabList.CanvasSize = UDim2.new(0, 0, 0, 2000)
    tabList.ZIndex = 6
    tabList.Parent = sidebar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabList

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -220, 1, -30)
    content.Position = UDim2.new(0, 210, 0, 20)
    content.BackgroundTransparency = 1
    content.ZIndex = 6
    content.Parent = main

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Size = UDim2.new(1, 0, 1, 0)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 3
    contentScroll.ScrollBarImageColor3 = C.border
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 2000)
    contentScroll.ZIndex = 6
    contentScroll.Parent = content

    local tabs = {}
    local tabByName = {}
    local selectedTab = nil

    local function doSelectTab(data)
        if selectedTab == data then return end
        if selectedTab then
            selectedTab.button.BackgroundTransparency = 1
            selectedTab.button.BackgroundColor3 = C.bg
            selectedTab.label.TextColor3 = C.textDim
            selectedTab.page.Visible = false
        end
        selectedTab = data
        data.button.BackgroundTransparency = 0
        data.button.BackgroundColor3 = C.accentDeep
        data.label.TextColor3 = Color3.fromRGB(255, 255, 255)
        data.page.Visible = true
    end

    local window = {}
    window.gui = gui
    window.main = main
    window.pill = pill

    function window:CreateTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = C.bg
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Active = true
        btn.ZIndex = 7
        btn.Parent = tabList
        corner(btn, 8)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -32, 1, 0)
        label.Position = UDim2.new(0, 16, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = C.textDim
        label.TextSize = 13
        label.Font = Enum.Font.GothamMedium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 8
        label.Parent = btn

        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, 0, 0, 2000)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.ZIndex = 7
        page.Parent = contentScroll

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = page

        local data = {button = btn, label = label, page = page, name = name, layout = pageLayout}
        table.insert(tabs, data)
        tabByName[name] = data

        btn.MouseEnter:Connect(function()
            if selectedTab ~= data then
                btn.BackgroundColor3 = C.card
                btn.BackgroundTransparency = 0.4
            end
        end)
        btn.MouseLeave:Connect(function()
            if selectedTab ~= data then btn.BackgroundTransparency = 1 end
        end)
        btn.MouseButton1Click:Connect(function() doSelectTab(data) end)

        local tab = {}
        function tab:CreateSection(sectionTitle, opts)
            return createSection(page, sectionTitle, opts, gui)
        end
        function tab:Select()
            doSelectTab(data)
        end
        return tab
    end

    function window:SelectTab(name)
        local d = tabByName[name]
        if d then doSelectTab(d) end
    end

    function window:Minimize()
        main.Visible = false
        pill.Visible = true
    end

    function window:Restore()
        main.Visible = true
        pill.Visible = false
    end

    function window:Destroy()
        gui:Destroy()
    end

    return window
end

return MoonUI
