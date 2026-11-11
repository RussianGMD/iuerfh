local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local function create(className: string, props: {[string]: any}, children: {Instance}?): any
    local inst = Instance.new(className)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            (inst :: any)[k] = v
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

if game.PlaceId ~= 18336470541 then
    local guiParent = (gethui and gethui()) or CoreGui
    local oldGuard = guiParent:FindFirstChild("AirFlow_TaphHub_Guard")
    if oldGuard then
        oldGuard:Destroy()
    end

    local GuardGui = create("ScreenGui", {
        Name = "AirFlow_TaphHub_Guard",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = guiParent
    })

    local gStroke = create("UIStroke", {
        Color = Color3.fromRGB(220, 55, 55),
        Thickness = 1.3,
        Transparency = 0.15
    })

    local gTitle = create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(220, 55, 55),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Taph Hub Guard",
        ZIndex = 1001
    })

    local gDesc = create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 36),
        Position = UDim2.new(0, 12, 0, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        TextColor3 = Color3.fromRGB(225, 235, 228),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = "You cannot execute this script in this game, you can\nexecute only in Seeker vs Hider, bro.",
        ZIndex = 1001
    })

    local gFrame = create("Frame", {
        Size = UDim2.new(0, 320, 0, 72),
        Position = UDim2.new(1, -335, 1, -92),
        BackgroundColor3 = Color3.fromRGB(16, 22, 18),
        BorderSizePixel = 0,
        ZIndex = 1000,
        Parent = GuardGui
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        gStroke,
        gTitle,
        gDesc
    })

    task.delay(5, function()
        if gFrame and gFrame.Parent then
            local tw = TweenService:Create(gFrame, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
            TweenService:Create(gTitle, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            TweenService:Create(gDesc, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            TweenService:Create(gStroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
            tw:Play()
            tw.Completed:Wait()
            if GuardGui then
                GuardGui:Destroy()
            end
        end
    end)

    return
end

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local disableAnimations = false
local currentTheme = "Black"
local themeUpdaters: {() -> ()} = {}

local function playTween(instance: Instance, duration: number, props: {[string]: any})
    if disableAnimations or duration <= 0 then
        for k, v in pairs(props) do
            (instance :: any)[k] = v
        end
    else
        TweenService:Create(instance, TweenInfo.new(duration), props):Play()
    end
end

local function makeDraggable(frame: GuiObject, handle: GuiObject?)
    local dragTarget = handle or frame
    local dragging = false
    local dragInput: InputObject? = nil
    local dragStart = Vector3.zero
    local startPos = UDim2.new()

    dragTarget.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragTarget.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local ConfigValues: {[string]: any} = {}
local ConfigSetters: {[string]: (any, boolean?) -> ()} = {}
local saveFunctionsEnabled = false
local suppressConfigSave = false

local FolderName = "TaphHub_Configs"
local AutoSaveFile = FolderName .. "/_autosave.json"
local AutoLoadMetaFile = FolderName .. "/_autoload.txt"
local memoryConfigs: {[string]: string} = {}

local function ensureFolder()
    pcall(function()
        if isfolder and makefolder and not isfolder(FolderName) then
            makefolder(FolderName)
        end
    end)
end
ensureFolder()

local function writeTextFile(path: string, data: string)
    ensureFolder()
    local ok = pcall(function()
        if writefile then
            writefile(path, data)
        else
            memoryConfigs[path] = data
        end
    end)
    if not ok then
        memoryConfigs[path] = data
    end
end

local function readTextFile(path: string): string?
    local result: string? = nil
    pcall(function()
        if isfile and readfile and isfile(path) then
            result = readfile(path)
        elseif memoryConfigs[path] then
            result = memoryConfigs[path]
        end
    end)
    return result
end

local function removeTextFile(path: string)
    pcall(function()
        if isfile and delfile and isfile(path) then
            delfile(path)
        end
        memoryConfigs[path] = nil
    end)
end

local function listConfigNames(): {string}
    ensureFolder()
    local names: {string} = {}
    local seen: {[string]: boolean} = {}

    pcall(function()
        if listfiles then
            for _, file in ipairs(listfiles(FolderName)) do
                local clean = string.gsub(file, "\\", "/")
                local base = string.match(clean, "([^/]+)%.json$")
                if base and base ~= "_autosave" and not seen[base] then
                    seen[base] = true
                    table.insert(names, base)
                end
            end
        end
    end)

    for path in pairs(memoryConfigs) do
        local base = string.match(path, "^" .. FolderName .. "/([^/]+)%.json$")
        if base and base ~= "_autosave" and not seen[base] then
            seen[base] = true
            table.insert(names, base)
        end
    end

    table.sort(names)
    return names
end

local function serializeCurrentConfig(): string
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(ConfigValues)
    end)
    return (ok and encoded) or "{}"
end

local function triggerAutoSave()
    if suppressConfigSave or not saveFunctionsEnabled then
        return
    end
    writeTextFile(AutoSaveFile, serializeCurrentConfig())
end

local function applyConfigJson(rawJson: string)
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(rawJson)
    end)
    if not ok or type(decoded) ~= "table" then
        return
    end
    suppressConfigSave = true
    for k, v in pairs(decoded) do
        ConfigValues[k] = v
        local setter = ConfigSetters[k]
        if setter then
            pcall(setter, v, true)
        end
    end
    suppressConfigSave = false
    if saveFunctionsEnabled then
        writeTextFile(AutoSaveFile, serializeCurrentConfig())
    end
end

local LucideIcons: {[string]: any} = {}
pcall(function()
    local loaded = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"))()
    if type(loaded) == "table" then
        LucideIcons = loaded
    end
end)

local FallbackIcons: {[string]: string} = {
    ["home"] = "rbxassetid://10723407389",
    ["house"] = "rbxassetid://10723407389",
    ["user"] = "rbxassetid://10747373176",
    ["eye"] = "rbxassetid://10723346959",
    ["crosshair"] = "rbxassetid://10709790948",
    ["gamepad-2"] = "rbxassetid://10723395457",
    ["settings"] = "rbxassetid://10734950309"
}

local function applyIcon(imageLabel: ImageLabel, iconName: string)
    local keys = (iconName == "home") and {"house", "home"} or {iconName}
    local found: any = nil

    for _, k in ipairs(keys) do
        local direct = rawget(LucideIcons, k)
        if direct ~= nil then
            found = direct
            break
        end
        local subTable = rawget(LucideIcons, "icons") or rawget(LucideIcons, "Icons")
        if type(subTable) == "table" then
            local nested = rawget(subTable, k)
            if nested ~= nil then
                found = nested
                break
            end
        end
    end

    if type(found) == "string" and #found > 0 then
        imageLabel.Image = (string.find(found, "rbxassetid://") or string.find(found, "http")) and found or ("rbxassetid://" .. found)
        return
    elseif type(found) == "number" then
        imageLabel.Image = "rbxassetid://" .. tostring(found)
        return
    elseif type(found) == "table" then
        local img = rawget(found, "Image") or rawget(found, "image") or rawget(found, "id")
        local rSize = rawget(found, "ImageRectSize") or rawget(found, "imageRectSize")
        local rOff = rawget(found, "ImageRectOffset") or rawget(found, "imageRectOffset")
        if type(img) == "string" then
            imageLabel.Image = string.find(img, "rbxassetid://") and img or ("rbxassetid://" .. img)
        elseif type(img) == "number" then
            imageLabel.Image = "rbxassetid://" .. tostring(img)
        end
        if typeof(rSize) == "Vector2" then imageLabel.ImageRectSize = rSize end
        if typeof(rOff) == "Vector2" then imageLabel.ImageRectOffset = rOff end
        return
    end

    imageLabel.Image = FallbackIcons[iconName] or "rbxassetid://10723407389"
end

local placeName = "Seeker vs Hider"
local creatorName = "Unknown"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name then placeName = info.Name end
    if info and info.Creator and info.Creator.Name then creatorName = info.Creator.Name end
end)

local weaponNames: {[string]: boolean} = {}
task.spawn(function()
    local sph = ReplicatedStorage:WaitForChild("SPH_Assets", 10)
    local wm = sph and sph:WaitForChild("WeaponModels", 10)
    if wm then
        for _, child in ipairs(wm:GetChildren()) do weaponNames[child.Name] = true end
        wm.ChildAdded:Connect(function(child) weaponNames[child.Name] = true end)
        wm.ChildRemoved:Connect(function(child) weaponNames[child.Name] = nil end)
    end
end)

local lobbyObjects: {Instance} = {}
local function scanLobby()
    table.clear(lobbyObjects)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if string.lower(obj.Name) == "lobby" and (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder")) then
            table.insert(lobbyObjects, obj)
        end
    end
end
scanLobby()

workspace.DescendantAdded:Connect(function(obj)
    if string.lower(obj.Name) == "lobby" and (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder")) then
        table.insert(lobbyObjects, obj)
    end
end)

local lobbyRayParams = RaycastParams.new()
lobbyRayParams.FilterType = Enum.RaycastFilterType.Exclude
lobbyRayParams.IgnoreWater = true

local function isInLobby(player: Player): boolean
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return false end

    for _, lob in ipairs(lobbyObjects) do
        if lob and lob.Parent then
            if char:IsDescendantOf(lob) then return true end
            if lob:IsA("Model") then
                local ok, cf, size = pcall(function() return lob:GetBoundingBox() end)
                if ok and cf and size then
                    local rel = cf:PointToObjectSpace(hrp.Position)
                    local half = (size / 2) + Vector3.new(10, 35, 10)
                    if math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z then
                        return true
                    end
                end
            elseif lob:IsA("BasePart") then
                local rel = lob.CFrame:PointToObjectSpace(hrp.Position)
                local half = (lob.Size / 2) + Vector3.new(10, 45, 10)
                if math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z then
                    return true
                end
            end
        end
    end

    lobbyRayParams.FilterDescendantsInstances = { char }
    local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -120, 0), lobbyRayParams)
    if hit and hit.Instance then
        local curr: Instance? = hit.Instance
        while curr and curr ~= workspace do
            if string.lower(curr.Name) == "lobby" then return true end
            curr = curr.Parent
        end
    end

    return false
end

local function hasGun(player: Player): boolean
    local char = player.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if weaponNames[item.Name] or (item:IsA("Tool") and item:FindFirstChild("Mode")) then
                return true
            end
        end
    end
    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if weaponNames[item.Name] or (item:IsA("Tool") and item:FindFirstChild("Mode")) then
                return true
            end
        end
    end
    return false
end

local function getRoleColor(player: Player): Color3
    if isInLobby(player) then return Color3.fromRGB(160, 160, 160) end
    if hasGun(player) then return Color3.fromRGB(220, 55, 55) end
    return Color3.fromRGB(55, 135, 255)
end

local function registerThemedElement(fn: () -> ())
    table.insert(themeUpdaters, fn)
    fn()
end

local function applyThemeAll()
    for _, fn in ipairs(themeUpdaters) do
        pcall(fn)
    end
end

local AirFlow = {}

function AirFlow:CreateWindow(config)
    local WindowObj = {}
    local guiParent = (gethui and gethui()) or CoreGui

    local old = guiParent:FindFirstChild("AirFlow_TaphHub")
    if old then old:Destroy() end

    local ScreenGui = create("ScreenGui", {
        Name = "AirFlow_TaphHub",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        Parent = guiParent
    })

    function WindowObj:GetScreenGui()
        return ScreenGui
    end

    local NotifyContainer = create("Frame", {
        Name = "Notifications",
        Size = UDim2.new(0, 310, 1, -40),
        Position = UDim2.new(1, -325, 0, 20),
        BackgroundTransparency = 1,
        ZIndex = 300,
        Parent = ScreenGui
    }, {
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 8)
        })
    })

    function WindowObj:Notify(nConfig)
        local isWhite = (currentTheme == "White")
        local nStroke = create("UIStroke", {
            Color = Color3.fromRGB(46, 213, 115),
            Thickness = 1.2,
            Transparency = 0.2
        })
        local nTitle = create("TextLabel", {
            Size = UDim2.new(1, -24, 0, 20),
            Position = UDim2.new(0, 12, 0, 7),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(46, 213, 115),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = nConfig.Title or "Taph Hub",
            ZIndex = 302
        })
        local nDesc = create("TextLabel", {
            Size = UDim2.new(1, -24, 0, 30),
            Position = UDim2.new(0, 12, 0, 27),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextWrapped = true,
            TextColor3 = isWhite and Color3.fromRGB(40, 48, 44) or Color3.fromRGB(220, 230, 225),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = nConfig.Description or "",
            ZIndex = 302
        })
        local nFrame = create("Frame", {
            Size = UDim2.new(1, 0, 0, 64),
            BackgroundColor3 = isWhite and Color3.fromRGB(245, 248, 246) or Color3.fromRGB(16, 22, 18),
            BorderSizePixel = 0,
            ZIndex = 301,
            Parent = NotifyContainer
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 8) }),
            nStroke,
            nTitle,
            nDesc
        })

        task.delay(nConfig.Duration or 2.8, function()
            if nFrame and nFrame.Parent then
                if disableAnimations then
                    nFrame:Destroy()
                else
                    local tw = TweenService:Create(nFrame, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
                    TweenService:Create(nTitle, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
                    TweenService:Create(nDesc, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
                    TweenService:Create(nStroke, TweenInfo.new(0.25), { Transparency = 1 }):Play()
                    tw:Play()
                    tw.Completed:Wait()
                    if nFrame then nFrame:Destroy() end
                end
            end
        end)
    end

    local MainStroke = create("UIStroke", { Color = Color3.fromRGB(28, 38, 32), Thickness = 1.2 })
    local MainFrame = create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 740, 0, 500),
        Position = UDim2.new(0.5, -370, 0.5, -250),
        BackgroundColor3 = Color3.fromRGB(11, 14, 12),
        BorderSizePixel = 0,
        Parent = ScreenGui
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 12) }),
        MainStroke
    })

    local SidebarDivider = create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Color3.fromRGB(26, 36, 30),
        BorderSizePixel = 0
    })
    local HubTitleLbl = create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 48),
        Position = UDim2.new(0, 16, 0, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(240, 245, 242),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = config.Title or "Taph Hub"
    })
    local Sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundColor3 = Color3.fromRGB(14, 18, 15),
        BorderSizePixel = 0,
        Parent = MainFrame
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 12) }),
        SidebarDivider,
        HubTitleLbl
    })

    makeDraggable(MainFrame, Sidebar)

    local TabContainer = create("Frame", {
        Size = UDim2.new(1, -20, 1, -135),
        Position = UDim2.new(0, 10, 0, 56),
        BackgroundTransparency = 1,
        Parent = Sidebar
    }, {
        create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
    })

    local AvatarHead = create("ImageLabel", {
        Size = UDim2.new(0, 42, 0, 42),
        Position = UDim2.new(0, 8, 0.5, -21),
        BackgroundColor3 = Color3.fromRGB(24, 32, 28),
        BorderSizePixel = 0
    }, {
        create("UICorner", { CornerRadius = UDim.new(1, 0) })
    })

    task.spawn(function()
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and content then AvatarHead.Image = content end
    end)

    local BPStroke = create("UIStroke", { Color = Color3.fromRGB(30, 42, 34), Thickness = 1 })
    local BPUserLbl = create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 56, 0, 11),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(230, 238, 232),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "Username: " .. LocalPlayer.Name
    })
    local BPGameLbl = create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 56, 0, 31),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(145, 165, 152),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "Game: " .. placeName
    })
    local BottomProfile = create("Frame", {
        Name = "BottomProfile",
        Size = UDim2.new(1, -16, 0, 62),
        Position = UDim2.new(0, 8, 1, -70),
        BackgroundColor3 = Color3.fromRGB(18, 24, 20),
        BorderSizePixel = 0,
        Parent = Sidebar
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 9) }),
        BPStroke,
        AvatarHead,
        BPUserLbl,
        BPGameLbl
    })

    registerThemedElement(function()
        local w = (currentTheme == "White")
        MainFrame.BackgroundColor3 = w and Color3.fromRGB(242, 246, 243) or Color3.fromRGB(11, 14, 12)
        MainStroke.Color = w and Color3.fromRGB(205, 218, 210) or Color3.fromRGB(28, 38, 32)
        Sidebar.BackgroundColor3 = w and Color3.fromRGB(232, 238, 234) or Color3.fromRGB(14, 18, 15)
        SidebarDivider.BackgroundColor3 = w and Color3.fromRGB(205, 218, 210) or Color3.fromRGB(26, 36, 30)
        HubTitleLbl.TextColor3 = w and Color3.fromRGB(20, 28, 24) or Color3.fromRGB(240, 245, 242)
        BottomProfile.BackgroundColor3 = w and Color3.fromRGB(222, 230, 225) or Color3.fromRGB(18, 24, 20)
        BPStroke.Color = w and Color3.fromRGB(195, 210, 200) or Color3.fromRGB(30, 42, 34)
        BPUserLbl.TextColor3 = w and Color3.fromRGB(22, 30, 25) or Color3.fromRGB(230, 238, 232)
        BPGameLbl.TextColor3 = w and Color3.fromRGB(85, 102, 92) or Color3.fromRGB(145, 165, 152)
    end)

    local PagesHolder = create("Frame", {
        Name = "PagesHolder",
        Size = UDim2.new(1, -216, 1, -24),
        Position = UDim2.new(0, 208, 0, 12),
        BackgroundTransparency = 1,
        Parent = MainFrame
    })

    local toggleKey: Enum.KeyCode = config.ToggleKey or Enum.KeyCode.Y
    local listeningForToggleKey = false

    function WindowObj:SetToggleKey(newKey: Enum.KeyCode)
        toggleKey = newKey
    end
    function WindowObj:GetToggleKey(): Enum.KeyCode
        return toggleKey
    end
    function WindowObj:SetListeningToggleKey(state: boolean)
        listeningForToggleKey = state
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
        if listeningForToggleKey then return end
        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
            MainFrame.Visible = not MainFrame.Visible
            if not MainFrame.Visible then
                WindowObj:Notify({
                    Title = "Taph Hub",
                    Description = "The Interface closed, to open again interface (UI) you can click " .. toggleKey.Name .. ".",
                    Duration = 3.5
                })
            end
        end
    end)

    local tabs = {}
    local firstTab = true

    function WindowObj:AddTab(tConfig)
        local TabObj = {}
        local isSelected = firstTab

        local TB_Icon = create("ImageLabel", {
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 12, 0.5, -9),
            BackgroundTransparency = 1
        })
        applyIcon(TB_Icon, tConfig.Icon or "home")

        local TB_Label = create("TextLabel", {
            Size = UDim2.new(1, -44, 1, 0),
            Position = UDim2.new(0, 38, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tConfig.Name or "Tab"
        })

        local TabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = isSelected and 0 or 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = TabContainer
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 8) }),
            TB_Icon,
            TB_Label
        })

        local Page = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Color3.fromRGB(46, 213, 115),
            Visible = isSelected,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = PagesHolder
        }, {
            create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
            create("UIPadding", {
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 6)
            })
        })

        firstTab = false
        local tabEntry = { Button = TabBtn, Icon = TB_Icon, Label = TB_Label, Page = Page, Selected = isSelected }
        table.insert(tabs, tabEntry)

        local function refreshTabsVisual()
            local w = (currentTheme == "White")
            for _, item in ipairs(tabs) do
                item.Button.BackgroundColor3 = w and Color3.fromRGB(205, 228, 214) or Color3.fromRGB(22, 34, 27)
                item.Button.BackgroundTransparency = item.Selected and 0 or 1
                item.Icon.ImageColor3 = item.Selected and Color3.fromRGB(46, 213, 115) or (w and Color3.fromRGB(90, 105, 95) or Color3.fromRGB(150, 165, 155))
                item.Label.TextColor3 = item.Selected and (w and Color3.fromRGB(18, 26, 22) or Color3.fromRGB(240, 248, 242)) or (w and Color3.fromRGB(90, 105, 95) or Color3.fromRGB(150, 165, 155))
            end
        end
        registerThemedElement(refreshTabsVisual)

        TabBtn.MouseButton1Click:Connect(function()
            for _, item in ipairs(tabs) do
                item.Selected = false
                item.Page.Visible = false
            end
            tabEntry.Selected = true
            Page.Visible = true
            refreshTabsVisual()
        end)

        function TabObj:GetPage() return Page end

        function TabObj:AddCategory(catName)
            local CatObj = {}
            local ItemsContainer = create("Frame", {
                Size = UDim2.new(1, -24, 0, 0),
                Position = UDim2.new(0, 12, 0, 36),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1
            }, {
                create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
            })

            local CatStroke = create("UIStroke", { Color = Color3.fromRGB(26, 38, 30), Thickness = 1 })
            local CatFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromRGB(15, 20, 17),
                BorderSizePixel = 0,
                Parent = Page
            }, {
                create("UICorner", { CornerRadius = UDim.new(0, 10) }),
                CatStroke,
                create("UIPadding", { PaddingBottom = UDim.new(0, 12) }),
                create("TextLabel", {
                    Size = UDim2.new(1, -24, 0, 28),
                    Position = UDim2.new(0, 12, 0, 6),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 13,
                    TextColor3 = Color3.fromRGB(46, 213, 115),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = catName
                }),
                ItemsContainer
            })

            registerThemedElement(function()
                local w = (currentTheme == "White")
                CatFrame.BackgroundColor3 = w and Color3.fromRGB(234, 240, 236) or Color3.fromRGB(15, 20, 17)
                CatStroke.Color = w and Color3.fromRGB(202, 215, 206) or Color3.fromRGB(26, 38, 30)
            end)

            function CatObj:GetContainer()
                return ItemsContainer
            end

            function CatObj:AddLabel(text)
                local Lbl = create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Text = text,
                    Parent = ItemsContainer
                })
                registerThemedElement(function()
                    Lbl.TextColor3 = (currentTheme == "White") and Color3.fromRGB(45, 58, 50) or Color3.fromRGB(190, 202, 195)
                end)
                return Lbl
            end

            function CatObj:AddToggle(tgConfig)
                local state = tgConfig.Default or false
                local configKey = tgConfig.ConfigKey or (catName .. "_" .. tgConfig.Name)
                ConfigValues[configKey] = state

                local activeColor = Color3.fromRGB(46, 213, 115)
                local function getInactiveColor()
                    return (currentTheme == "White") and Color3.fromRGB(185, 198, 190) or Color3.fromRGB(38, 48, 42)
                end

                local Knob = create("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                    BackgroundColor3 = Color3.fromRGB(245, 250, 247),
                    BorderSizePixel = 0
                }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

                local SwitchBg = create("TextButton", {
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -50, 0.5, -10),
                    BackgroundColor3 = state and activeColor or getInactiveColor(),
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false
                }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), Knob })

                local TitleLbl = create("TextLabel", {
                    Size = UDim2.new(1, -110, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = tgConfig.Name
                })

                local Row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BorderSizePixel = 0,
                    Parent = ItemsContainer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 7) }),
                    TitleLbl,
                    SwitchBg
                })

                registerThemedElement(function()
                    local w = (currentTheme == "White")
                    Row.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
                    TitleLbl.TextColor3 = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
                    SwitchBg.BackgroundColor3 = state and activeColor or getInactiveColor()
                end)

                local function setState(newVal: boolean, silent: boolean?)
                    state = (newVal == true)
                    ConfigValues[configKey] = state
                    playTween(SwitchBg, 0.18, { BackgroundColor3 = state and activeColor or getInactiveColor() })
                    playTween(Knob, 0.18, { Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) })
                    if not silent then
                        WindowObj:Notify({
                            Title = tgConfig.Name,
                            Description = tgConfig.Name .. (state and " has been enabled." or " has been disabled."),
                            Duration = 2
                        })
                    end
                    if tgConfig.Callback then tgConfig.Callback(state) end
                    if not silent then triggerAutoSave() end
                end

                ConfigSetters[configKey] = setState

                SwitchBg.MouseButton1Click:Connect(function()
                    setState(not state, false)
                end)

                if tgConfig.Keybind then
                    local boundKey: Enum.KeyCode = tgConfig.Keybind
                    local listeningForKey = false

                    local KeyBtn = create("TextButton", {
                        Size = UDim2.new(0, 24, 0, 20),
                        Position = UDim2.new(0, 62, 0.5, -10),
                        BackgroundColor3 = Color3.fromRGB(6, 8, 7),
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        TextSize = 11,
                        TextColor3 = Color3.fromRGB(240, 245, 242),
                        Text = boundKey.Name,
                        AutoButtonColor = false,
                        Parent = Row
                    }, {
                        create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                        create("UIStroke", { Color = Color3.fromRGB(38, 52, 42), Thickness = 1 })
                    })

                    KeyBtn.MouseButton1Click:Connect(function()
                        listeningForKey = true
                        KeyBtn.Text = "..."
                    end)

                    UserInputService.InputBegan:Connect(function(input, gpe)
                        if listeningForKey then
                            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                                boundKey = input.KeyCode
                                KeyBtn.Text = boundKey.Name
                                listeningForKey = false
                            end
                            return
                        end
                        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == boundKey then
                            setState(not state, false)
                        end
                    end)
                end

                return { Set = function(_, v) setState(v, true) end }
            end

            function CatObj:AddSlider(slConfig)
                local minVal = slConfig.Min or 0
                local maxVal = slConfig.Max or 100
                local curVal = slConfig.Default or minVal
                local enabled = (slConfig.Enabled == nil) and true or slConfig.Enabled
                local suffix = slConfig.Suffix or ""
                local configKey = slConfig.ConfigKey or (catName .. "_Slider_" .. slConfig.Name)
                ConfigValues[configKey] = curVal

                local SLabel = create("TextLabel", {
                    Size = UDim2.new(0.65, 0, 0, 20),
                    Position = UDim2.new(0, 10, 0, 4),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = slConfig.Name
                })
                local SValue = create("TextLabel", {
                    Size = UDim2.new(0.3, -10, 0, 20),
                    Position = UDim2.new(0.7, 0, 0, 4),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextColor3 = Color3.fromRGB(46, 213, 115),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Text = tostring(curVal) .. suffix
                })
                local Fill = create("Frame", {
                    Size = UDim2.new(math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1), 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(46, 213, 115),
                    BorderSizePixel = 0
                }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

                local BarBg = create("Frame", {
                    Size = UDim2.new(1, -20, 0, 6),
                    Position = UDim2.new(0, 10, 0, 30),
                    BorderSizePixel = 0
                }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), Fill })

                local SFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 46),
                    BorderSizePixel = 0,
                    Parent = ItemsContainer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 7) }),
                    SLabel, SValue, BarBg
                })

                local sliding = false
                local function updateVis()
                    local w = (currentTheme == "White")
                    SFrame.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
                    SLabel.TextColor3 = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
                    BarBg.BackgroundColor3 = w and Color3.fromRGB(190, 204, 195) or Color3.fromRGB(34, 44, 38)
                    local t = enabled and 0 or 0.58
                    SFrame.BackgroundTransparency = t
                    SLabel.TextTransparency = t
                    SValue.TextTransparency = t
                    BarBg.BackgroundTransparency = t
                    Fill.BackgroundTransparency = t
                end
                registerThemedElement(updateVis)

                local function applyVal(val: number, silent: boolean?)
                    curVal = math.clamp(math.floor(val + 0.5), minVal, maxVal)
                    ConfigValues[configKey] = curVal
                    local rel = math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1)
                    Fill.Size = UDim2.new(rel, 0, 1, 0)
                    SValue.Text = tostring(curVal) .. suffix
                    if slConfig.Callback then slConfig.Callback(curVal) end
                    if not silent then triggerAutoSave() end
                end

                ConfigSetters[configKey] = function(v, silent)
                    if type(v) == "number" then applyVal(v, silent) end
                end

                local function setFromInput(input)
                    if not enabled then return end
                    local rel = math.clamp((input.Position.X - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X, 0, 1)
                    applyVal(minVal + (maxVal - minVal) * rel, false)
                end

                SFrame.InputBegan:Connect(function(input)
                    if enabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                        setFromInput(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if sliding and enabled and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setFromInput(input)
                    end
                end)

                return {
                    SetEnabled = function(_, bool)
                        enabled = bool
                        if not enabled then sliding = false end
                        updateVis()
                    end,
                    GetValue = function(_) return curVal end
                }
            end

            function CatObj:AddDropdown(ddConfig)
                local options = ddConfig.Options or {}
                local curIdx = 1
                for i, v in ipairs(options) do
                    if v == ddConfig.Default then curIdx = i break end
                end
                local selected = options[curIdx] or ""
                local configKey = ddConfig.ConfigKey or (catName .. "_DD_" .. ddConfig.Name)
                ConfigValues[configKey] = selected

                local ValBtn = create("TextButton", {
                    Size = UDim2.new(0, 145, 0, 24),
                    Position = UDim2.new(1, -155, 0.5, -12),
                    BackgroundColor3 = Color3.fromRGB(26, 38, 30),
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextColor3 = Color3.fromRGB(46, 213, 115),
                    Text = selected
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    create("UIStroke", { Color = Color3.fromRGB(46, 213, 115), Thickness = 1, Transparency = 0.5 })
                })

                local TitleLbl = create("TextLabel", {
                    Size = UDim2.new(1, -165, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = ddConfig.Name
                })

                local Row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BorderSizePixel = 0,
                    Parent = ItemsContainer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 7) }),
                    TitleLbl,
                    ValBtn
                })

                registerThemedElement(function()
                    local w = (currentTheme == "White")
                    Row.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
                    TitleLbl.TextColor3 = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
                    ValBtn.BackgroundColor3 = w and Color3.fromRGB(210, 225, 215) or Color3.fromRGB(26, 38, 30)
                end)

                ConfigSetters[configKey] = function(val, silent)
                    for i, opt in ipairs(options) do
                        if opt == val then
                            curIdx = i
                            selected = opt
                            ValBtn.Text = selected
                            ConfigValues[configKey] = selected
                            if ddConfig.Callback then ddConfig.Callback(selected) end
                            if not silent then triggerAutoSave() end
                            break
                        end
                    end
                end

                ValBtn.MouseButton1Click:Connect(function()
                    if #options == 0 then return end
                    curIdx = (curIdx % #options) + 1
                    selected = options[curIdx]
                    ValBtn.Text = selected
                    ConfigValues[configKey] = selected
                    if ddConfig.Callback then ddConfig.Callback(selected) end
                    triggerAutoSave()
                end)
            end

            function CatObj:AddButton(btnConfig)
                local enabled = (btnConfig.Enabled == nil) and true or btnConfig.Enabled
                local BStroke = create("UIStroke", { Color = Color3.fromRGB(46, 213, 115), Thickness = 1 })
                local Btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    Text = btnConfig.Name,
                    AutoButtonColor = false,
                    Parent = ItemsContainer
                }, { create("UICorner", { CornerRadius = UDim.new(0, 7) }), BStroke })

                local function updateBtn()
                    local w = (currentTheme == "White")
                    Btn.BackgroundColor3 = w and Color3.fromRGB(212, 228, 218) or Color3.fromRGB(26, 40, 32)
                    Btn.TextColor3 = w and Color3.fromRGB(20, 32, 25) or Color3.fromRGB(235, 245, 238)
                    Btn.Active = enabled
                    Btn.BackgroundTransparency = enabled and 0 or 0.65
                    Btn.TextTransparency = enabled and 0 or 0.6
                    BStroke.Transparency = enabled and 0.4 or 0.85
                end
                registerThemedElement(updateBtn)

                Btn.MouseButton1Click:Connect(function()
                    if enabled and btnConfig.Callback then btnConfig.Callback() end
                end)

                return {
                    SetEnabled = function(_, bool)
                        enabled = bool
                        updateBtn()
                    end,
                    SetText = function(_, txt)
                        Btn.Text = txt
                    end
                }
            end

            function CatObj:AddColorPicker(cpConfig)
                local colors = {
                    Color3.fromRGB(46, 213, 115),
                    Color3.fromRGB(55, 135, 255),
                    Color3.fromRGB(220, 55, 55),
                    Color3.fromRGB(255, 195, 45),
                    Color3.fromRGB(175, 85, 255),
                    Color3.fromRGB(245, 245, 245)
                }
                local SwatchList = create("Frame", {
                    Size = UDim2.new(0.55, -10, 1, 0),
                    Position = UDim2.new(0.45, 0, 0, 0),
                    BackgroundTransparency = 1
                }, {
                    create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 6)
                    })
                })

                local TitleLbl = create("TextLabel", {
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = cpConfig.Name
                })

                local Row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BorderSizePixel = 0,
                    Parent = ItemsContainer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 7) }),
                    TitleLbl,
                    SwatchList
                })

                registerThemedElement(function()
                    local w = (currentTheme == "White")
                    Row.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
                    TitleLbl.TextColor3 = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
                end)

                for _, col in ipairs(colors) do
                    local Sw = create("TextButton", {
                        Size = UDim2.new(0, 18, 0, 18),
                        BackgroundColor3 = col,
                        BorderSizePixel = 0,
                        Text = "",
                        Parent = SwatchList
                    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
                    Sw.MouseButton1Click:Connect(function()
                        if cpConfig.Callback then cpConfig.Callback(col) end
                    end)
                end
            end

            return CatObj
        end

        return TabObj
    end

    return WindowObj
end

local Window = AirFlow:CreateWindow({
    Title = "Taph Hub",
    ToggleKey = Enum.KeyCode.Y
})

local HomeTab = Window:AddTab({ Name = "Home", Icon = "home" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local TargetTab = Window:AddTab({ Name = "Target", Icon = "crosshair" })
local GameTab = Window:AddTab({ Name = "Game", Icon = "gamepad-2" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

local followNoclipOverride = false

do
    local HomePage = HomeTab:GetPage()

    local DisplayNameLbl = create("TextLabel", {
        Size = UDim2.new(0.65, 0, 0, 28),
        Position = UDim2.new(0, 16, 0, 34),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = Color3.fromRGB(242, 247, 244),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = LocalPlayer.DisplayName
    })
    local HandleLbl = create("TextLabel", {
        Size = UDim2.new(0.65, 0, 0, 18),
        Position = UDim2.new(0, 16, 0, 62),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(125, 145, 132),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "@" .. LocalPlayer.Name
    })
    local BustImage = create("ImageLabel", {
        Size = UDim2.new(0, 115, 0, 115),
        Position = UDim2.new(1, -130, 1, -115),
        BackgroundTransparency = 1
    })
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size180x180)
        end)
        if ok and img then BustImage.Image = img end
    end)

    local BadgesRow = create("Frame", {
        Size = UDim2.new(0, 230, 0, 26),
        Position = UDim2.new(0, 16, 0, 90),
        BackgroundTransparency = 1
    }, {
        create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) })
    })

    local function makePill(txt, accent)
        return create("TextButton", {
            Size = UDim2.new(0, 68, 1, 0),
            BackgroundColor3 = accent and Color3.fromRGB(20, 42, 30) or Color3.fromRGB(22, 28, 24),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = accent and Color3.fromRGB(46, 213, 115) or Color3.fromRGB(150, 168, 156),
            Text = txt,
            Parent = BadgesRow
        }, { create("UICorner", { CornerRadius = UDim.new(0, 6) }) })
    end

    makePill("Free", true)
    local NameBtn = makePill("Name", false)
    local AvatarBtn = makePill("Avatar", false)

    local nameHidden = false
    NameBtn.MouseButton1Click:Connect(function()
        nameHidden = not nameHidden
        DisplayNameLbl.Text = nameHidden and "Hidden" or LocalPlayer.DisplayName
        HandleLbl.Text = nameHidden and "@hidden" or ("@" .. LocalPlayer.Name)
    end)
    AvatarBtn.MouseButton1Click:Connect(function()
        BustImage.Visible = not BustImage.Visible
    end)

    local WelcomeCardStroke = create("UIStroke", { Color = Color3.fromRGB(26, 38, 30), Thickness = 1 })
    local WelcomeCard = create("Frame", {
        Size = UDim2.new(1, 0, 0, 130),
        BackgroundColor3 = Color3.fromRGB(15, 20, 17),
        BorderSizePixel = 0,
        Parent = HomePage
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        WelcomeCardStroke,
        create("TextLabel", {
            Size = UDim2.new(0.6, 0, 0, 16),
            Position = UDim2.new(0, 16, 0, 16),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = Color3.fromRGB(120, 138, 126),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "WELCOME BACK"
        }),
        DisplayNameLbl, HandleLbl, BustImage, BadgesRow
    })

    local FpsValueLbl = create("TextLabel", {
        Size = UDim2.new(0.4, 0, 0, 28),
        Position = UDim2.new(0, 16, 0, 32),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = Color3.fromRGB(46, 213, 115),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "60"
    })
    local PingValueLbl = create("TextLabel", {
        Size = UDim2.new(0.4, 0, 0, 28),
        Position = UDim2.new(0.52, 0, 0, 32),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = Color3.fromRGB(235, 180, 60),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "50ms"
    })
    local FpsBarsFrame = create("Frame", {
        Size = UDim2.new(0.44, 0, 0, 26),
        Position = UDim2.new(0, 16, 0, 66),
        BackgroundTransparency = 1
    })
    local PingBarsFrame = create("Frame", {
        Size = UDim2.new(0.44, 0, 0, 26),
        Position = UDim2.new(0.52, 0, 0, 66),
        BackgroundTransparency = 1
    })

    local fpsBars, pingBars = {}, {}
    for i = 1, 16 do
        fpsBars[i] = create("Frame", {
            Size = UDim2.new(0, 8, 0.4, 0),
            Position = UDim2.new(0, (i - 1) * 13, 0.6, 0),
            BackgroundColor3 = (i == 16) and Color3.fromRGB(46, 213, 115) or Color3.fromRGB(42, 58, 48),
            BorderSizePixel = 0,
            Parent = FpsBarsFrame
        }, { create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

        pingBars[i] = create("Frame", {
            Size = UDim2.new(0, 8, 0.5, 0),
            Position = UDim2.new(0, (i - 1) * 13, 0.5, 0),
            BackgroundColor3 = (i == 16) and Color3.fromRGB(235, 180, 60) or Color3.fromRGB(52, 56, 48),
            BorderSizePixel = 0,
            Parent = PingBarsFrame
        }, { create("UICorner", { CornerRadius = UDim.new(0, 2) }) })
    end

    local PlayersCountLbl = create("TextLabel", {
        Size = UDim2.new(0.4, 0, 0, 18),
        Position = UDim2.new(0, 16, 0, 100),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(235, 242, 238),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
    })
    local SessionValLbl = create("TextLabel", {
        Size = UDim2.new(0.4, 0, 0, 18),
        Position = UDim2.new(0.52, 0, 0, 100),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(235, 242, 238),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "0m 0s"
    })

    local FpsPingWidget = create("Frame", {
        Name = "FpsPingWidget",
        Size = UDim2.new(0, 195, 0, 66),
        Position = UDim2.new(1, -210, 1, -82),
        BackgroundColor3 = Color3.fromRGB(14, 19, 16),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 250,
        Parent = Window:GetScreenGui()
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        create("UIStroke", { Color = Color3.fromRGB(46, 213, 115), Thickness = 1.2, Transparency = 0.25 }),
        create("TextLabel", {
            Size = UDim2.new(1, -20, 0, 18),
            Position = UDim2.new(0, 12, 0, 6),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(46, 213, 115),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Taph Hub · Performance",
            ZIndex = 251
        })
    })
    makeDraggable(FpsPingWidget)

    local FPW_FpsLbl = create("TextLabel", {
        Size = UDim2.new(0.5, -12, 0, 26),
        Position = UDim2.new(0, 12, 0, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(46, 213, 115),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "FPS: 60",
        ZIndex = 251,
        Parent = FpsPingWidget
    })
    local FPW_PingLbl = create("TextLabel", {
        Size = UDim2.new(0.5, -12, 0, 26),
        Position = UDim2.new(0.5, 0, 0, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(235, 180, 60),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Ping: 50ms",
        ZIndex = 251,
        Parent = FpsPingWidget
    })

    local fpsWidgetState = false
    local FpsWidgetKnob = create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 3, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(245, 250, 247),
        BorderSizePixel = 0
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    local FpsWidgetSwitch = create("TextButton", {
        Size = UDim2.new(0, 34, 0, 18),
        Position = UDim2.new(0, 92, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(38, 48, 42),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), FpsWidgetKnob })

    local AddFpsWidgetHolder = create("Frame", {
        Size = UDim2.new(0, 140, 0, 24),
        Position = UDim2.new(0, 16, 0, 140),
        BackgroundTransparency = 1
    }, {
        create("TextLabel", {
            Size = UDim2.new(0, 85, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(200, 215, 205),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Add Widget"
        }),
        FpsWidgetSwitch
    })

    local function setFpsWidgetState(val: boolean, silent: boolean?)
        fpsWidgetState = (val == true)
        ConfigValues["Home_AddWidget"] = fpsWidgetState
        FpsPingWidget.Visible = fpsWidgetState
        playTween(FpsWidgetSwitch, 0.18, {
            BackgroundColor3 = fpsWidgetState and Color3.fromRGB(46, 213, 115) or Color3.fromRGB(38, 48, 42)
        })
        playTween(FpsWidgetKnob, 0.18, {
            Position = fpsWidgetState and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
        })
        if not silent then
            Window:Notify({
                Title = "Add Widget",
                Description = "FPS & Ping Widget " .. (fpsWidgetState and "has been enabled." or "has been disabled."),
                Duration = 2
            })
            triggerAutoSave()
        end
    end
    ConfigSetters["Home_AddWidget"] = setFpsWidgetState

    FpsWidgetSwitch.MouseButton1Click:Connect(function()
        setFpsWidgetState(not fpsWidgetState, false)
    end)

    local StatsCardStroke = create("UIStroke", { Color = Color3.fromRGB(26, 38, 30), Thickness = 1 })
    local StatsCard = create("Frame", {
        Size = UDim2.new(1, 0, 0, 174),
        BackgroundColor3 = Color3.fromRGB(15, 20, 17),
        BorderSizePixel = 0,
        Parent = HomePage
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        StatsCardStroke,
        create("TextLabel", {
            Size = UDim2.new(0.4, 0, 0, 16), Position = UDim2.new(0, 16, 0, 14), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(125, 142, 130),
            TextXAlignment = Enum.TextXAlignment.Left, Text = "FPS"
        }),
        create("TextLabel", {
            Size = UDim2.new(0.4, 0, 0, 16), Position = UDim2.new(0.52, 0, 0, 14), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(125, 142, 130),
            TextXAlignment = Enum.TextXAlignment.Left, Text = "PING"
        }),
        create("TextLabel", {
            Size = UDim2.new(0.4, 0, 0, 14), Position = UDim2.new(0, 16, 0, 118), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = Color3.fromRGB(115, 132, 120),
            TextXAlignment = Enum.TextXAlignment.Left, Text = "PLAYERS"
        }),
        create("TextLabel", {
            Size = UDim2.new(0.4, 0, 0, 14), Position = UDim2.new(0.52, 0, 0, 118), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = Color3.fromRGB(115, 132, 120),
            TextXAlignment = Enum.TextXAlignment.Left, Text = "SESSION"
        }),
        FpsValueLbl, PingValueLbl, FpsBarsFrame, PingBarsFrame, PlayersCountLbl, SessionValLbl, AddFpsWidgetHolder
    })

    local GameMetaLbl = create("TextLabel", {
        Size = UDim2.new(1, -32, 0, 18),
        Position = UDim2.new(0, 16, 0, 35),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(130, 148, 136),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "by " .. creatorName .. " · " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers) .. " players"
    })

    local ServerBtnsFrame = create("Frame", {
        Size = UDim2.new(1, -32, 0, 48),
        Position = UDim2.new(0, 16, 0, 66),
        BackgroundTransparency = 1
    }, {
        create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) })
    })

    local function createServerButton(label, callback)
        local B = create("TextButton", {
            Size = UDim2.new(0.25, -6, 1, 0),
            BackgroundColor3 = Color3.fromRGB(20, 27, 23),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(195, 210, 200),
            Text = label,
            Parent = ServerBtnsFrame
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 8) }),
            create("UIStroke", { Color = Color3.fromRGB(30, 42, 35), Thickness = 1 })
        })
        B.MouseButton1Click:Connect(callback)
    end

    createServerButton("Rejoin", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    createServerButton("Hop", function()
        pcall(function()
            local raw = game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Desc&limit=100")
            local decoded = HttpService:JSONDecode(raw)
            if decoded and decoded.data then
                for _, srv in ipairs(decoded.data) do
                    if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                        break
                    end
                end
            end
        end)
    end)
    createServerButton("Lowest", function()
        pcall(function()
            local raw = game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100")
            local decoded = HttpService:JSONDecode(raw)
            if decoded and decoded.data then
                for _, srv in ipairs(decoded.data) do
                    if srv.id ~= game.JobId and srv.playing > 0 and srv.playing < srv.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                        break
                    end
                end
            end
        end)
    end)
    createServerButton("Job ID", function()
        if setclipboard then setclipboard(tostring(game.JobId)) end
        Window:Notify({ Title = "Server", Description = "Job ID copied to clipboard.", Duration = 2 })
    end)

    local GameTitleCardLbl = create("TextLabel", {
        Size = UDim2.new(1, -32, 0, 20), Position = UDim2.new(0, 16, 0, 15), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(240, 246, 242),
        TextXAlignment = Enum.TextXAlignment.Left, Text = placeName
    })
    local GameCardStroke = create("UIStroke", { Color = Color3.fromRGB(26, 38, 30), Thickness = 1 })
    local GameCard = create("Frame", {
        Size = UDim2.new(1, 0, 0, 145),
        BackgroundColor3 = Color3.fromRGB(15, 20, 17),
        BorderSizePixel = 0,
        Parent = HomePage
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        GameCardStroke,
        GameTitleCardLbl,
        GameMetaLbl, ServerBtnsFrame,
        create("TextLabel", {
            Size = UDim2.new(1, -32, 0, 18), Position = UDim2.new(0, 16, 0, 120), BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(100, 118, 106),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Job " .. string.sub(tostring(game.JobId), 1, 13) .. " · Place " .. tostring(game.PlaceId)
        })
    })

    registerThemedElement(function()
        local w = (currentTheme == "White")
        WelcomeCard.BackgroundColor3 = w and Color3.fromRGB(234, 240, 236) or Color3.fromRGB(15, 20, 17)
        WelcomeCardStroke.Color = w and Color3.fromRGB(202, 215, 206) or Color3.fromRGB(26, 38, 30)
        DisplayNameLbl.TextColor3 = w and Color3.fromRGB(20, 28, 24) or Color3.fromRGB(242, 247, 244)
        StatsCard.BackgroundColor3 = w and Color3.fromRGB(234, 240, 236) or Color3.fromRGB(15, 20, 17)
        StatsCardStroke.Color = w and Color3.fromRGB(202, 215, 206) or Color3.fromRGB(26, 38, 30)
        PlayersCountLbl.TextColor3 = w and Color3.fromRGB(20, 28, 24) or Color3.fromRGB(235, 242, 238)
        SessionValLbl.TextColor3 = w and Color3.fromRGB(20, 28, 24) or Color3.fromRGB(235, 242, 238)
        GameCard.BackgroundColor3 = w and Color3.fromRGB(234, 240, 236) or Color3.fromRGB(15, 20, 17)
        GameCardStroke.Color = w and Color3.fromRGB(202, 215, 206) or Color3.fromRGB(26, 38, 30)
        GameTitleCardLbl.TextColor3 = w and Color3.fromRGB(20, 28, 24) or Color3.fromRGB(240, 246, 242)
        FpsPingWidget.BackgroundColor3 = w and Color3.fromRGB(240, 245, 242) or Color3.fromRGB(14, 19, 16)
    end)

    local OtherCat = HomeTab:AddCategory("Other")
    OtherCat:AddLabel("if Executor is Xeno, Solara or SirHurt, then executor will garbage.")

    local startTime = os.clock()
    local fpsHistory, pingHistory = {}, {}
    for i = 1, 16 do
        fpsHistory[i] = 60
        pingHistory[i] = 50
    end
    local frameCounter = 0
    local lastTick = os.clock()

    RunService.RenderStepped:Connect(function()
        frameCounter += 1
        local now = os.clock()
        if now - lastTick >= 1 then
            local currentFps = math.clamp(frameCounter, 1, 240)
            frameCounter = 0
            lastTick = now

            local currentPing = 50
            pcall(function()
                currentPing = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)

            FpsValueLbl.Text = tostring(currentFps)
            PingValueLbl.Text = tostring(currentPing) .. "ms"
            FPW_FpsLbl.Text = "FPS: " .. tostring(currentFps)
            FPW_PingLbl.Text = "Ping: " .. tostring(currentPing) .. "ms"

            table.remove(fpsHistory, 1)
            table.insert(fpsHistory, currentFps)
            table.remove(pingHistory, 1)
            table.insert(pingHistory, currentPing)

            for i = 1, 16 do
                local fRatio = math.clamp(fpsHistory[i] / 144, 0.12, 1)
                fpsBars[i].Size = UDim2.new(0, 8, fRatio, 0)
                fpsBars[i].Position = UDim2.new(0, (i - 1) * 13, 1 - fRatio, 0)

                local pRatio = math.clamp(pingHistory[i] / 250, 0.12, 1)
                pingBars[i].Size = UDim2.new(0, 8, pRatio, 0)
                pingBars[i].Position = UDim2.new(0, (i - 1) * 13, 1 - pRatio, 0)
            end

            local elapsed = math.floor(now - startTime)
            SessionValLbl.Text = tostring(math.floor(elapsed / 60)) .. "m " .. tostring(elapsed % 60) .. "s"
            PlayersCountLbl.Text = tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
            GameMetaLbl.Text = "by " .. creatorName .. " · " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers) .. " players"
        end
    end)
end

do
    local wsEnabled, wsValue = false, 32
    local jpEnabled, jpValue = false, 50
    local flyEnabled, flyValue = false, 32
    local infJumpEnabled, noclipEnabled, deleteJumpLimitActive = false, false, false

    local WalkSpeedCat = PlayerTab:AddCategory("WalkSpeed")
    local WalkSpeedSlider
    WalkSpeedCat:AddToggle({
        Name = "WalkSpeed",
        Default = false,
        Callback = function(val)
            wsEnabled = val
            WalkSpeedSlider:SetEnabled(val)
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val and wsValue or 16 end
        end
    })
    WalkSpeedSlider = WalkSpeedCat:AddSlider({
        Name = "Select WalkSpeed",
        Min = 8, Max = 128, Default = 32, Enabled = false,
        Callback = function(val)
            wsValue = val
            if wsEnabled then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = wsValue end
            end
        end
    })

    local JumpPowerCat = PlayerTab:AddCategory("JumpPower")
    local JumpPowerSlider
    JumpPowerCat:AddToggle({
        Name = "JumpPower",
        Default = false,
        Callback = function(val)
            jpEnabled = val
            JumpPowerSlider:SetEnabled(val)
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = val and jpValue or 50
            end
        end
    })
    JumpPowerSlider = JumpPowerCat:AddSlider({
        Name = "Select JumpPower",
        Min = 8, Max = 196, Default = 50, Enabled = false,
        Callback = function(val)
            jpValue = val
            if jpEnabled then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.UseJumpPower = true
                    hum.JumpPower = jpValue
                end
            end
        end
    })

    local FlyCat = PlayerTab:AddCategory("Fly")
    local FlySlider
    local flyBV: BodyVelocity? = nil
    local flyBG: BodyGyro? = nil

    local function stopFly()
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
    end

    local function startFly()
        stopFly()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        flyBV = create("BodyVelocity", {
            MaxForce = Vector3.new(9e9, 9e9, 9e9),
            Velocity = Vector3.zero,
            Parent = hrp
        })
        flyBG = create("BodyGyro", {
            MaxTorque = Vector3.new(9e9, 9e9, 9e9),
            P = 9e4,
            CFrame = Camera.CFrame,
            Parent = hrp
        })
    end

    FlyCat:AddToggle({
        Name = "Fly",
        Default = false,
        Callback = function(val)
            flyEnabled = val
            FlySlider:SetEnabled(val)
            if val then startFly() else stopFly() end
        end
    })
    FlySlider = FlyCat:AddSlider({
        Name = "Speed Fly",
        Min = 16, Max = 128, Default = 32, Enabled = false,
        Callback = function(val) flyValue = val end
    })

    local OtherMoveCat = PlayerTab:AddCategory("Other Movement")
    OtherMoveCat:AddToggle({ Name = "Infinite Jump", Default = false, Callback = function(val) infJumpEnabled = val end })
    OtherMoveCat:AddToggle({ Name = "Noclip", Default = false, Callback = function(val) noclipEnabled = val end })
    OtherMoveCat:AddButton({
        Name = "Delete Limit Jumps",
        Enabled = true,
        Callback = function()
            deleteJumpLimitActive = true
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
                for _, desc in ipairs(char:GetDescendants()) do
                    if string.find(string.lower(desc.Name), "jump") and (desc:IsA("LocalScript") or desc:IsA("NumberValue") or desc:IsA("BoolValue")) then
                        pcall(function() desc:Destroy() end)
                    end
                end
            end
            Window:Notify({ Title = "Delete Limit Jumps", Description = "Jump limit has been removed.", Duration = 2 })
        end
    })

    local function bindCharacterGuard(char: Model)
        local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
        if not hum then return end
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if wsEnabled and hum.WalkSpeed ~= wsValue then hum.WalkSpeed = wsValue end
        end)
        hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
            if jpEnabled and hum.JumpPower ~= jpValue then
                hum.UseJumpPower = true
                hum.JumpPower = jpValue
            end
        end)
    end

    if LocalPlayer.Character then task.spawn(bindCharacterGuard, LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(bindCharacterGuard)

    RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?

        if hum then
            if wsEnabled and hum.WalkSpeed ~= wsValue then hum.WalkSpeed = wsValue end
            if jpEnabled then
                if not hum.UseJumpPower then hum.UseJumpPower = true end
                if hum.JumpPower ~= jpValue then hum.JumpPower = jpValue end
            end
            if deleteJumpLimitActive then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end

        if flyEnabled and hrp then
            if not flyBV or flyBV.Parent ~= hrp then startFly() end
            if FlySlider and FlySlider:GetValue() ~= flyValue then
                flyValue = FlySlider:GetValue()
            end
            local moveDir = Vector3.zero
            local camCF = Camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            if flyBV then flyBV.Velocity = moveDir * flyValue end
            if flyBG then flyBG.CFrame = camCF end
        end
    end)

    RunService.Stepped:Connect(function()
        if (noclipEnabled or followNoclipOverride) and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end
    end)

    UserInputService.JumpRequest:Connect(function()
        if infJumpEnabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end

do
    local espChams, espWeapon, espNickname, espHealth, espStuds = false, false, false, false, false
    local espLines, espSkeleton, espHead = false, false, false

    local ESPCat = VisualsTab:AddCategory("ESP")
    ESPCat:AddToggle({ Name = "ESP Chams", Default = false, Callback = function(v) espChams = v end })
    ESPCat:AddToggle({ Name = "Render Weapon", Default = false, Callback = function(v) espWeapon = v end })
    ESPCat:AddToggle({ Name = "ESP Nickname", Default = false, Callback = function(v) espNickname = v end })
    ESPCat:AddToggle({ Name = "ESP Health", Default = false, Callback = function(v) espHealth = v end })
    ESPCat:AddToggle({ Name = "ESP Studs", Default = false, Callback = function(v) espStuds = v end })

    local ESPPlayerCat = VisualsTab:AddCategory("ESP Player")
    ESPPlayerCat:AddToggle({ Name = "ESP Lines", Default = false, Callback = function(v) espLines = v end })
    ESPPlayerCat:AddToggle({ Name = "Skeleton", Default = false, Callback = function(v) espSkeleton = v end })
    ESPPlayerCat:AddToggle({ Name = "Head", Default = false, Callback = function(v) espHead = v end })

    local WorldCat = VisualsTab:AddCategory("World")
    local origBrightness, origClockTime = Lighting.Brightness, Lighting.ClockTime
    local origShadows, origAmbient = Lighting.GlobalShadows, Lighting.Ambient
    local origFogEnd, origFogStart = Lighting.FogEnd, Lighting.FogStart
    local fbEnabled, fbValue, noFogEnabled, removeKillbricksEnabled = false, 3, false, false
    local transAccessoryEnabled = false
    local transAccessoryPercent = 0
    local savedAccessoryTrans: {[BasePart]: number} = {}
    local FullBrightSlider, TransAccSlider

    WorldCat:AddToggle({
        Name = "FullBright",
        Default = false,
        Callback = function(v)
            fbEnabled = v
            FullBrightSlider:SetEnabled(v)
            if not v then
                Lighting.Brightness = origBrightness
                Lighting.ClockTime = origClockTime
                Lighting.GlobalShadows = origShadows
                Lighting.Ambient = origAmbient
            end
        end
    })
    FullBrightSlider = WorldCat:AddSlider({
        Name = "FullBright Level",
        Min = 1, Max = 10, Default = 3, Enabled = false,
        Callback = function(v) fbValue = v end
    })
    WorldCat:AddToggle({
        Name = "No Fog",
        Default = false,
        Callback = function(v)
            noFogEnabled = v
            if not v then
                Lighting.FogEnd = origFogEnd
                Lighting.FogStart = origFogStart
            end
        end
    })

    local function purgeKillbricks()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if string.lower(obj.Name) == "killbrick" then
                pcall(function() obj:Destroy() end)
            end
        end
    end

    WorldCat:AddToggle({
        Name = "Remove Killbricks",
        Default = false,
        Callback = function(v)
            removeKillbricksEnabled = v
            if v then purgeKillbricks() end
        end
    })

    workspace.DescendantAdded:Connect(function(obj)
        if removeKillbricksEnabled and string.lower(obj.Name) == "killbrick" then
            task.defer(function()
                pcall(function() obj:Destroy() end)
            end)
        end
    end)

    local function applyAccessoriesTransparency()
        local targetTran = math.clamp((100 - transAccessoryPercent) / 100, 0, 1)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Accessory") or obj:IsA("Hat") then
                for _, part in ipairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if savedAccessoryTrans[part] == nil then
                            savedAccessoryTrans[part] = part.Transparency
                        end
                        part.Transparency = targetTran
                    end
                end
            end
        end
    end

    local function restoreAccessoriesTransparency()
        for part, origT in pairs(savedAccessoryTrans) do
            if part and part.Parent then
                part.Transparency = origT
            end
        end
        table.clear(savedAccessoryTrans)
    end

    WorldCat:AddToggle({
        Name = "Transparent Accessory",
        Default = false,
        Callback = function(v)
            transAccessoryEnabled = v
            TransAccSlider:SetEnabled(v)
            if v then
                applyAccessoriesTransparency()
            else
                restoreAccessoriesTransparency()
            end
        end
    })

    TransAccSlider = WorldCat:AddSlider({
        Name = "Accessory Visibility",
        Min = 0, Max = 100, Default = 0, Suffix = "%", Enabled = false,
        Callback = function(v)
            transAccessoryPercent = v
            if transAccessoryEnabled then
                applyAccessoriesTransparency()
            end
        end
    })

    local lastAccTick = 0
    RunService.RenderStepped:Connect(function()
        if fbEnabled then
            Lighting.Brightness = fbValue
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        end
        if noFogEnabled then
            Lighting.FogEnd = 100000
            Lighting.FogStart = 100000
        end
        if transAccessoryEnabled and os.clock() - lastAccTick >= 0.8 then
            lastAccTick = os.clock()
            applyAccessoriesTransparency()
        end
    end)

    local HitboxCat = VisualsTab:AddCategory("Hitbox Expander")
    local hitboxEnabled = false
    local hitboxStuds = 8
    local hitboxOpacityPercent = 40
    local hbIgnoreLobby = false
    local hbIgnoreHiders = false
    local origHitboxes: {[Player]: {size: Vector3, tran: number, col: Color3, mat: Enum.Material}} = {}
    local HitboxStudsSlider, HitboxTransSlider

    local function restorePlayerHitbox(player: Player)
        local saved = origHitboxes[player]
        if not saved then return end
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if hrp then
            hrp.Size = saved.size
            hrp.Transparency = saved.tran
            hrp.Color = saved.col
            hrp.Material = saved.mat
        end
        origHitboxes[player] = nil
    end

    HitboxCat:AddToggle({
        Name = "Hitbox Expander",
        Default = false,
        Callback = function(val)
            hitboxEnabled = val
            HitboxStudsSlider:SetEnabled(val)
            HitboxTransSlider:SetEnabled(val)
            if not val then
                for _, p in ipairs(Players:GetPlayers()) do
                    restorePlayerHitbox(p)
                end
            end
        end
    })

    HitboxStudsSlider = HitboxCat:AddSlider({
        Name = "Studs Long",
        Min = 1, Max = 64, Default = 8, Suffix = " st", Enabled = false,
        Callback = function(val) hitboxStuds = val end
    })

    HitboxTransSlider = HitboxCat:AddSlider({
        Name = "Transparency",
        Min = 1, Max = 100, Default = 40, Suffix = "%", Enabled = false,
        Callback = function(val) hitboxOpacityPercent = val end
    })

    HitboxCat:AddToggle({
        Name = "Ignore Lobby Players",
        Default = false,
        Callback = function(val) hbIgnoreLobby = val end
    })

    HitboxCat:AddToggle({
        Name = "Ignore Hiders",
        Default = false,
        Callback = function(val) hbIgnoreHiders = val end
    })

    RunService.Heartbeat:Connect(function()
        if not hitboxEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
                if char and hum and hum.Health > 0 and hrp then
                    local inLob = isInLobby(player)
                    local isHider = (not inLob) and (not hasGun(player))
                    if (hbIgnoreLobby and inLob) or (hbIgnoreHiders and isHider) then
                        restorePlayerHitbox(player)
                    else
                        if not origHitboxes[player] then
                            origHitboxes[player] = {
                                size = hrp.Size,
                                tran = hrp.Transparency,
                                col = hrp.Color,
                                mat = hrp.Material
                            }
                        end
                        hrp.Size = Vector3.new(hitboxStuds, hitboxStuds, hitboxStuds)
                        hrp.Transparency = math.clamp((100 - hitboxOpacityPercent) / 100, 0, 0.99)
                        hrp.Color = getRoleColor(player)
                        hrp.Material = Enum.Material.Neon
                        hrp.CanCollide = false
                    end
                else
                    restorePlayerHitbox(player)
                end
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        origHitboxes[player] = nil
    end)

    local LadderCat = VisualsTab:AddCategory("Ladder [CLIENT]")
    local clientLadder: TrussPart? = nil
    local ladderSizeY = 24
    local ladderColor = Color3.fromRGB(46, 213, 115)
    local ladderOpacityPercent = 80
    local CreateLadderBtn, DeleteLadderBtn

    CreateLadderBtn = LadderCat:AddButton({
        Name = "Create",
        Enabled = true,
        Callback = function()
            if clientLadder then return end
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            if not hrp then return end
            local spawnPos = hrp.Position + (hrp.CFrame.LookVector * 4) + Vector3.new(0, ladderSizeY / 2 - 2, 0)
            clientLadder = create("TrussPart", {
                Name = "TaphClientLadder",
                Anchored = true,
                CanCollide = true,
                Size = Vector3.new(2, ladderSizeY, 2),
                Color = ladderColor,
                Transparency = math.clamp((100 - ladderOpacityPercent) / 100, 0, 0.99),
                CFrame = CFrame.new(spawnPos),
                Parent = workspace
            })
            CreateLadderBtn:SetEnabled(false)
            DeleteLadderBtn:SetEnabled(true)
            Window:Notify({ Title = "Ladder [CLIENT]", Description = "Ladder has been created.", Duration = 2 })
        end
    })

    DeleteLadderBtn = LadderCat:AddButton({
        Name = "Delete",
        Enabled = false,
        Callback = function()
            if clientLadder then
                clientLadder:Destroy()
                clientLadder = nil
            end
            CreateLadderBtn:SetEnabled(true)
            DeleteLadderBtn:SetEnabled(false)
            Window:Notify({ Title = "Ladder [CLIENT]", Description = "Ladder has been deleted.", Duration = 2 })
        end
    })

    LadderCat:AddSlider({
        Name = "Ladder Size Y",
        Min = 1, Max = 128, Default = 24, Enabled = true,
        Callback = function(v)
            ladderSizeY = v
            if clientLadder then
                local bottom = clientLadder.Position - Vector3.new(0, clientLadder.Size.Y / 2, 0)
                clientLadder.Size = Vector3.new(2, ladderSizeY, 2)
                clientLadder.Position = bottom + Vector3.new(0, ladderSizeY / 2, 0)
            end
        end
    })
    LadderCat:AddColorPicker({
        Name = "Ladder Color",
        Callback = function(col)
            ladderColor = col
            if clientLadder then clientLadder.Color = ladderColor end
        end
    })
    LadderCat:AddSlider({
        Name = "Transparent",
        Min = 1, Max = 100, Default = 80, Suffix = "%", Enabled = true,
        Callback = function(v)
            ladderOpacityPercent = v
            if clientLadder then
                clientLadder.Transparency = math.clamp((100 - ladderOpacityPercent) / 100, 0, 0.99)
            end
        end
    })

    local OverlayGui = create("ScreenGui", {
        Name = "TaphHub_ESPOverlay",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        Parent = (gethui and gethui()) or CoreGui
    })

    local playerVisuals: {[Player]: any} = {}
    local bonePairsR15 = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
    }
    local bonePairsR6 = {
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
    }

    local function createLineFrame()
        return create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BorderSizePixel = 0,
            Visible = false,
            Parent = OverlayGui
        })
    end

    local function draw2DLine(frame: Frame, p1: Vector2, p2: Vector2, color: Color3, thickness: number?)
        local dx, dy = p2.X - p1.X, p2.Y - p1.Y
        local dist = math.sqrt(dx * dx + dy * dy)
        frame.Position = UDim2.new(0, (p1.X + p2.X) / 2, 0, (p1.Y + p2.Y) / 2)
        frame.Size = UDim2.new(0, dist, 0, thickness or 1.5)
        frame.Rotation = math.deg(math.atan2(dy, dx))
        frame.BackgroundColor3 = color
        frame.Visible = true
    end

    local function projectWorldEvenOffscreen(worldPos: Vector3): Vector2
        local vp = Camera.ViewportSize
        local screenPos = Camera:WorldToViewportPoint(worldPos)
        if screenPos.Z < 0 then
            local center = Vector2.new(vp.X / 2, vp.Y / 2)
            local dir = (Vector2.new(vp.X - screenPos.X, vp.Y - screenPos.Y) - center).Unit
            local edge = center + dir * math.max(vp.X, vp.Y)
            return Vector2.new(math.clamp(edge.X, 0, vp.X), math.clamp(edge.Y, 0, vp.Y))
        end
        return Vector2.new(screenPos.X, screenPos.Y)
    end

    local function cleanupVisuals(player: Player)
        local v = playerVisuals[player]
        if not v then return end
        if v.Chams then v.Chams:Destroy() end
        if v.WeaponHL then v.WeaponHL:Destroy() end
        if v.Billboard then v.Billboard:Destroy() end
        if v.Tracer then v.Tracer:Destroy() end
        if v.HeadCircle then v.HeadCircle:Destroy() end
        if v.Bones then
            for _, b in ipairs(v.Bones) do b:Destroy() end
        end
        playerVisuals[player] = nil
    end

    Players.PlayerRemoving:Connect(cleanupVisuals)

    RunService.RenderStepped:Connect(function()
        local vp = Camera.ViewportSize
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
                local head = char and char:FindFirstChild("Head") :: BasePart?

                if char and hum and hum.Health > 0 and hrp then
                    local vis = playerVisuals[player]
                    if not vis then
                        vis = { Tracer = createLineFrame(), Bones = {} }
                        for i = 1, 14 do vis.Bones[i] = createLineFrame() end

                        local hcs = create("UIStroke", { Thickness = 1.6 })
                        vis.HeadStroke = hcs
                        vis.HeadCircle = create("Frame", {
                            BackgroundTransparency = 1, Visible = false, Parent = OverlayGui
                        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), hcs })

                        local bbl = create("TextLabel", {
                            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold, TextSize = 12, TextStrokeTransparency = 0.2,
                            TextColor3 = Color3.fromRGB(255, 255, 255)
                        })
                        vis.BillboardText = bbl
                        vis.Billboard = create("BillboardGui", {
                            Size = UDim2.new(0, 200, 0, 50), StudsOffset = Vector3.new(0, 3.2, 0),
                            AlwaysOnTop = true, Parent = OverlayGui
                        }, { bbl })

                        playerVisuals[player] = vis
                    end

                    local roleCol = getRoleColor(player)

                    if espChams then
                        if not vis.Chams or vis.Chams.Parent ~= char then
                            if vis.Chams then vis.Chams:Destroy() end
                            vis.Chams = create("Highlight", {
                                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                                FillTransparency = 0.5, OutlineTransparency = 0,
                                Adornee = char, Parent = char
                            })
                        end
                        vis.Chams.FillColor = roleCol
                        vis.Chams.OutlineColor = roleCol
                        vis.Chams.Enabled = true
                    elseif vis.Chams then
                        vis.Chams.Enabled = false
                    end

                    if espWeapon then
                        local foundWeapon: Instance? = nil
                        for _, child in ipairs(char:GetChildren()) do
                            if weaponNames[child.Name] or child:IsA("Tool") or (child:IsA("Model") and child.Name ~= "Body") then
                                foundWeapon = child
                                break
                            end
                        end
                        if foundWeapon then
                            if not vis.WeaponHL or vis.WeaponHL.Parent ~= foundWeapon then
                                if vis.WeaponHL then vis.WeaponHL:Destroy() end
                                vis.WeaponHL = create("Highlight", {
                                    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                                    FillColor = Color3.fromRGB(255, 215, 60),
                                    OutlineColor = Color3.fromRGB(255, 255, 255),
                                    FillTransparency = 0.25,
                                    Adornee = foundWeapon, Parent = foundWeapon
                                })
                            end
                            vis.WeaponHL.Enabled = true
                        elseif vis.WeaponHL then
                            vis.WeaponHL.Enabled = false
                        end
                    elseif vis.WeaponHL then
                        vis.WeaponHL.Enabled = false
                    end

                    if espNickname or espHealth or espStuds then
                        vis.Billboard.Adornee = head or hrp
                        vis.Billboard.Enabled = true
                        local lines = {}
                        if espNickname then table.insert(lines, player.Name) end
                        if espHealth then table.insert(lines, "HP: " .. tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth))) end
                        if espStuds and myHrp then
                            table.insert(lines, tostring(math.floor((hrp.Position - myHrp.Position).Magnitude)) .. " studs")
                        end
                        vis.BillboardText.TextColor3 = roleCol
                        vis.BillboardText.Text = table.concat(lines, "\n")
                    else
                        vis.Billboard.Enabled = false
                    end

                    if espLines then
                        local origin2D = Vector2.new(vp.X / 2, vp.Y)
                        if myHrp then
                            local myPos2D, myOn = Camera:WorldToViewportPoint(myHrp.Position)
                            if myOn and myPos2D.Z > 0 then origin2D = Vector2.new(myPos2D.X, myPos2D.Y) end
                        end
                        draw2DLine(vis.Tracer, origin2D, projectWorldEvenOffscreen(hrp.Position), roleCol, 1.5)
                    else
                        vis.Tracer.Visible = false
                    end

                    if espHead and head then
                        local hPos, hOn = Camera:WorldToViewportPoint(head.Position)
                        if hOn and hPos.Z > 0 then
                            local topPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y / 2 + 0.3, 0))
                            local rad = math.clamp(math.abs(topPos.Y - hPos.Y), 4, 80)
                            vis.HeadCircle.Size = UDim2.new(0, rad * 2, 0, rad * 2)
                            vis.HeadCircle.Position = UDim2.new(0, hPos.X - rad, 0, hPos.Y - rad)
                            vis.HeadStroke.Color = roleCol
                            vis.HeadCircle.Visible = true
                        else
                            vis.HeadCircle.Visible = false
                        end
                    else
                        vis.HeadCircle.Visible = false
                    end

                    if espSkeleton then
                        local pairsList = (hum.RigType == Enum.HumanoidRigType.R15) and bonePairsR15 or bonePairsR6
                        for idx, bFrame in ipairs(vis.Bones) do
                            local pair = pairsList[idx]
                            local pA = pair and char:FindFirstChild(pair[1]) :: BasePart?
                            local pB = pair and char:FindFirstChild(pair[2]) :: BasePart?
                            if pA and pB then
                                local sA, onA = Camera:WorldToViewportPoint(pA.Position)
                                local sB, onB = Camera:WorldToViewportPoint(pB.Position)
                                if onA and onB and sA.Z > 0 and sB.Z > 0 then
                                    draw2DLine(bFrame, Vector2.new(sA.X, sA.Y), Vector2.new(sB.X, sB.Y), roleCol, 1.4)
                                else
                                    bFrame.Visible = false
                                end
                            else
                                bFrame.Visible = false
                            end
                        end
                    else
                        for _, bFrame in ipairs(vis.Bones) do bFrame.Visible = false end
                    end
                else
                    cleanupVisuals(player)
                end
            end
        end
    end)
end

do
    local silentAimEnabled = false
    local showFovCircle = false
    local fovScale = 0.25
    local targetPartName = "HumanoidRootPart"
    local wallCheckPriority = false

    local visRayParams = RaycastParams.new()
    visRayParams.FilterType = Enum.RaycastFilterType.Exclude
    visRayParams.IgnoreWater = true

    local function isTargetVisible(targetPart: BasePart, targetChar: Instance?): boolean
        local filter: {Instance} = {}
        if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
        if targetChar then table.insert(filter, targetChar) end
        visRayParams.FilterDescendantsInstances = filter
        local origin = Camera.CFrame.Position
        local result = workspace:Raycast(origin, targetPart.Position - origin, visRayParams)
        return result == nil
    end

    local fovGui = create("ScreenGui", {
        Name = "TaphHub_FOV",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = (gethui and gethui()) or CoreGui
    })

    local fovFrame = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        Parent = fovGui
    }, {
        create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        create("UIStroke", { Color = Color3.fromRGB(46, 213, 115), Thickness = 1.5 })
    })

    local function getFovRadius(): number
        local vp = Camera.ViewportSize
        return (math.sqrt(vp.X ^ 2 + vp.Y ^ 2) / 2) * fovScale
    end

    RunService.RenderStepped:Connect(function()
        local radius = getFovRadius()
        local vp = Camera.ViewportSize
        fovFrame.Size = UDim2.new(0, radius * 2, 0, radius * 2)
        fovFrame.Position = UDim2.new(0, vp.X / 2 - radius, 0, vp.Y / 2 - radius)
        fovFrame.Visible = silentAimEnabled and showFovCircle
    end)

    local function getClosestTarget(): BasePart?
        local vp = Camera.ViewportSize
        local centerX, centerY = vp.X / 2, vp.Y / 2
        local radius = getFovRadius()
        local candidates: {{part: BasePart, dist: number}} = {}

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if char and hum and hum.Health > 0 then
                    local part = (char:FindFirstChild(targetPartName) or char:FindFirstChild("HumanoidRootPart")) :: BasePart?
                    if part then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen and screenPos.Z > 0 then
                            local dist = math.sqrt((screenPos.X - centerX) ^ 2 + (screenPos.Y - centerY) ^ 2)
                            if dist <= radius then
                                table.insert(candidates, { part = part, dist = dist })
                            end
                        end
                    end
                end
            end
        end

        if #candidates == 0 then return nil end
        table.sort(candidates, function(a, b) return a.dist < b.dist end)

        if wallCheckPriority then
            for _, entry in ipairs(candidates) do
                if isTargetVisible(entry.part, entry.part.Parent) then
                    return entry.part
                end
            end
        end

        return candidates[1].part
    end

    task.defer(function()
        local fastCast: any = nil
        local sph = ReplicatedStorage:WaitForChild("SPH_Assets", 10)
        local mods = sph and sph:WaitForChild("Modules", 10)
        local fcMod = mods and mods:WaitForChild("FastCast", 10)

        if fcMod and fcMod:IsA("ModuleScript") then
            local ok, mod = pcall(require, fcMod)
            if ok and type(mod) == "table" and type(rawget(mod, "Fire")) == "function" then
                fastCast = mod
            end
        end

        if not fastCast then
            for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
                if desc:IsA("ModuleScript") and desc.Name == "FastCast" then
                    local ok, mod = pcall(require, desc)
                    if ok and type(mod) == "table" and type(rawget(mod, "Fire")) == "function" then
                        fastCast = mod
                        break
                    end
                end
            end
        end

        if not fastCast then return end

        local oldFire = fastCast.Fire
        fastCast.Fire = function(...)
            local args = { ... }
            if silentAimEnabled then
                local targetPart = getClosestTarget()
                if targetPart and typeof(args[2]) == "Vector3" then
                    local origin: Vector3 = args[2]
                    local unitDir = (targetPart.Position - origin).Unit
                    local newDir = unitDir * 1000
                    args[3] = newDir
                    args[4] = newDir * 9000000000
                end
            end
            return oldFire(table.unpack(args))
        end
    end)

    local SilentAimCat = TargetTab:AddCategory("Silent Aim")
    local SilentFovSlider

    SilentAimCat:AddToggle({
        Name = "Silent Aim",
        Default = false,
        Callback = function(val)
            silentAimEnabled = val
            SilentFovSlider:SetEnabled(val)
        end
    })

    SilentAimCat:AddToggle({
        Name = "Show FOV Circle",
        Default = false,
        Callback = function(val) showFovCircle = val end
    })

    SilentFovSlider = SilentAimCat:AddSlider({
        Name = "FOV Size",
        Min = 1, Max = 100, Default = 25, Suffix = "%", Enabled = false,
        Callback = function(val) fovScale = val / 100 end
    })

    SilentAimCat:AddDropdown({
        Name = "Target Part",
        Options = { "HumanoidRootPart", "Head" },
        Default = "HumanoidRootPart",
        Callback = function(val) targetPartName = val end
    })

    SilentAimCat:AddToggle({
        Name = "Wall Check Priority",
        Default = false,
        Callback = function(val) wallCheckPriority = val end
    })

    local AimbotCat = TargetTab:AddCategory("Aimbot")
    local aimbotEnabled = false
    local aimbotDistance = 15
    local abIgnoreLobby = false
    local abIgnoreHiders = false
    local AimbotDistSlider

    local isLockedFirstPerson = false
    local transitionStart = 0
    local savedCamMode = LocalPlayer.CameraMode
    local savedMinZoom = LocalPlayer.CameraMinZoomDistance
    local savedMaxZoom = LocalPlayer.CameraMaxZoomDistance

    local function releaseAimbotCamera()
        if isLockedFirstPerson then
            isLockedFirstPerson = false
            LocalPlayer.CameraMode = savedCamMode
            LocalPlayer.CameraMinZoomDistance = savedMinZoom
            LocalPlayer.CameraMaxZoomDistance = savedMaxZoom
        end
    end

    AimbotCat:AddToggle({
        Name = "Aimbot",
        Default = false,
        Keybind = Enum.KeyCode.N,
        Callback = function(val)
            aimbotEnabled = val
            AimbotDistSlider:SetEnabled(val)
            if not val then releaseAimbotCamera() end
        end
    })

    AimbotDistSlider = AimbotCat:AddSlider({
        Name = "Distance",
        Min = 3, Max = 50, Default = 15, Suffix = " st", Enabled = false,
        Callback = function(val) aimbotDistance = val end
    })

    AimbotCat:AddToggle({
        Name = "Ignore Lobby Players",
        Default = false,
        Callback = function(val) abIgnoreLobby = val end
    })

    AimbotCat:AddToggle({
        Name = "Ignore Hiders",
        Default = false,
        Callback = function(val) abIgnoreHiders = val end
    })

    local function findAimbotTarget(): BasePart?
        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not myHrp then return nil end

        local closestHrp: BasePart? = nil
        local shortestDist = aimbotDistance

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
                if char and hum and hum.Health > 0 and hrp then
                    local inLob = isInLobby(player)
                    local isHider = (not inLob) and (not hasGun(player))
                    if not (abIgnoreLobby and inLob) and not (abIgnoreHiders and isHider) then
                        local d = (hrp.Position - myHrp.Position).Magnitude
                        if d <= shortestDist then
                            shortestDist = d
                            closestHrp = hrp
                        end
                    end
                end
            end
        end

        return closestHrp
    end

    RunService.RenderStepped:Connect(function()
        if not aimbotEnabled then return end

        local targetHrp = findAimbotTarget()
        local myChar = LocalPlayer.Character
        local myHead = myChar and myChar:FindFirstChild("Head") :: BasePart?

        if targetHrp and myHead then
            if not isLockedFirstPerson then
                isLockedFirstPerson = true
                transitionStart = os.clock()
                savedCamMode = LocalPlayer.CameraMode
                savedMinZoom = LocalPlayer.CameraMinZoomDistance
                savedMaxZoom = LocalPlayer.CameraMaxZoomDistance
            end

            local elapsed = os.clock() - transitionStart
            local alpha = math.clamp(elapsed / 0.025, 0, 1)

            if alpha < 1 then
                local camPos = Camera.CFrame.Position:Lerp(myHead.Position, alpha)
                Camera.CFrame = CFrame.lookAt(camPos, targetHrp.Position)
            else
                if LocalPlayer.CameraMode ~= Enum.CameraMode.LockFirstPerson then
                    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
                end
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetHrp.Position)
            end
        else
            releaseAimbotCamera()
        end
    end)

    local PlayerTargetCat = TargetTab:AddCategory("Player Target")
    local ptContainer = PlayerTargetCat:GetContainer()
    local selectedTargetPlayer: Player? = nil
    local spectatingTarget = false
    local followingTarget = false
    local savedReturnCFrame: CFrame? = nil

    local TargetAvatarImg = create("ImageLabel", {
        Size = UDim2.new(0, 34, 0, 34),
        Position = UDim2.new(0, 8, 0.5, -17),
        BackgroundColor3 = Color3.fromRGB(26, 36, 30),
        BorderSizePixel = 0,
        Visible = false
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    local SelectDropdownBtn = create("TextButton", {
        Size = UDim2.new(0, 175, 0, 26),
        Position = UDim2.new(1, -185, 0.5, -13),
        BackgroundColor3 = Color3.fromRGB(26, 38, 30),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(46, 213, 115),
        Text = "Select Player"
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        create("UIStroke", { Color = Color3.fromRGB(46, 213, 115), Thickness = 1, Transparency = 0.4 })
    })

    local TargetTitleLbl = create("TextLabel", {
        Size = UDim2.new(1, -200, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(225, 235, 228),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Server Player"
    })

    local TargetTopRow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Color3.fromRGB(20, 26, 22),
        BorderSizePixel = 0,
        Parent = ptContainer
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 7) }),
        TargetAvatarImg,
        TargetTitleLbl,
        SelectDropdownBtn
    })

    registerThemedElement(function()
        local w = (currentTheme == "White")
        TargetTopRow.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
        TargetTitleLbl.TextColor3 = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
        SelectDropdownBtn.BackgroundColor3 = w and Color3.fromRGB(210, 225, 215) or Color3.fromRGB(26, 38, 30)
    end)

    local PlayerListFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(18, 24, 20),
        BorderSizePixel = 0,
        Visible = false,
        Parent = ptContainer
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 7) }),
        create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
        create("UIPadding", {
            PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)
        })
    })

    local GoToBtn, SpectateBtn, FollowBtn

    local function selectPlayer(plr: Player)
        selectedTargetPlayer = plr
        SelectDropdownBtn.Text = plr.Name
        TargetAvatarImg.Visible = true
        TargetTitleLbl.Position = UDim2.new(0, 50, 0, 0)
        TargetTitleLbl.Text = plr.DisplayName
        PlayerListFrame.Visible = false

        task.spawn(function()
            local ok, thumb = pcall(function()
                return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            end)
            if ok and thumb then TargetAvatarImg.Image = thumb end
        end)

        GoToBtn:SetEnabled(true)
        SpectateBtn:SetEnabled(true)
        FollowBtn:SetEnabled(true)
    end

    local function refreshPlayerList()
        for _, child in ipairs(PlayerListFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local PBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = Color3.fromRGB(24, 34, 28),
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 11,
                    TextColor3 = Color3.fromRGB(230, 240, 234),
                    Text = plr.DisplayName .. " (@" .. plr.Name .. ")",
                    Parent = PlayerListFrame
                }, { create("UICorner", { CornerRadius = UDim.new(0, 5) }) })

                PBtn.MouseButton1Click:Connect(function()
                    selectPlayer(plr)
                end)
            end
        end
    end

    SelectDropdownBtn.MouseButton1Click:Connect(function()
        PlayerListFrame.Visible = not PlayerListFrame.Visible
        if PlayerListFrame.Visible then
            refreshPlayerList()
        end
    end)

    local lobbyLockActive = false
    local lastLobbyCFrame: CFrame? = nil

    GoToBtn = PlayerTargetCat:AddButton({
        Name = "Go to Player",
        Enabled = false,
        Callback = function()
            if not selectedTargetPlayer or not selectedTargetPlayer.Character then return end
            local targetHrp = selectedTargetPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            if targetHrp and myHrp then
                lobbyLockActive = false
                lastLobbyCFrame = nil
                myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3.5)
                Window:Notify({ Title = "Player Target", Description = "Teleported behind " .. selectedTargetPlayer.Name, Duration = 2 })
            end
        end
    })

    SpectateBtn = PlayerTargetCat:AddButton({
        Name = "Spectate Player",
        Enabled = false,
        Callback = function()
            spectatingTarget = not spectatingTarget
            if spectatingTarget and selectedTargetPlayer and selectedTargetPlayer.Character then
                local thum = selectedTargetPlayer.Character:FindFirstChildOfClass("Humanoid")
                if thum then
                    Camera.CameraSubject = thum
                    Window:Notify({ Title = "Spectate Player", Description = "Now spectating " .. selectedTargetPlayer.Name, Duration = 2 })
                end
            else
                spectatingTarget = false
                local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if myHum then Camera.CameraSubject = myHum end
                Window:Notify({ Title = "Spectate Player", Description = "Camera returned to you.", Duration = 2 })
            end
        end
    })

    local function stopFollowing()
        if not followingTarget then return end
        followingTarget = false
        followNoclipOverride = false
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if myHrp and savedReturnCFrame then
            myHrp.AssemblyLinearVelocity = Vector3.zero
            myHrp.CFrame = savedReturnCFrame
        end
        savedReturnCFrame = nil
    end

    FollowBtn = PlayerTargetCat:AddButton({
        Name = "Follow Player",
        Enabled = false,
        Callback = function()
            if not followingTarget then
                if not selectedTargetPlayer or not selectedTargetPlayer.Character then return end
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
                if myHrp then
                    lobbyLockActive = false
                    lastLobbyCFrame = nil
                    savedReturnCFrame = myHrp.CFrame
                    followingTarget = true
                    followNoclipOverride = true
                    Window:Notify({ Title = "Follow Player", Description = "Following " .. selectedTargetPlayer.Name, Duration = 2 })
                end
            else
                stopFollowing()
                Window:Notify({ Title = "Follow Player", Description = "Stopped following and returned back.", Duration = 2 })
            end
        end
    })

    RunService.Heartbeat:Connect(function()
        if followingTarget then
            if not selectedTargetPlayer or not selectedTargetPlayer.Parent or not selectedTargetPlayer.Character then
                stopFollowing()
                return
            end
            local targetHrp = selectedTargetPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            if targetHrp and myHrp then
                myHrp.AssemblyLinearVelocity = Vector3.zero
                myHrp.AssemblyAngularVelocity = Vector3.zero
                myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3.5)
            end
        elseif lobbyLockActive and lastLobbyCFrame then
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            if myHrp then
                local distFromLast = (myHrp.Position - lastLobbyCFrame.Position).Magnitude
                local currentlyInLobby = isInLobby(LocalPlayer)
                if currentlyInLobby and distFromLast < 22 then
                    lastLobbyCFrame = myHrp.CFrame
                elseif not currentlyInLobby or distFromLast >= 22 then
                    myHrp.AssemblyLinearVelocity = Vector3.zero
                    myHrp.CFrame = lastLobbyCFrame
                end
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(plr)
        if plr == selectedTargetPlayer then
            if followingTarget then stopFollowing() end
            if spectatingTarget then
                spectatingTarget = false
                local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if myHum then Camera.CameraSubject = myHum end
            end
            selectedTargetPlayer = nil
            TargetAvatarImg.Visible = false
            TargetTitleLbl.Position = UDim2.new(0, 10, 0, 0)
            TargetTitleLbl.Text = "Server Player"
            SelectDropdownBtn.Text = "Select Player"
            GoToBtn:SetEnabled(false)
            SpectateBtn:SetEnabled(false)
            FollowBtn:SetEnabled(false)
        end
    end)

    local TeleportCat = TargetTab:AddCategory("Teleport Buttons")

    TeleportCat:AddButton({
        Name = "Teleport to Lobby",
        Enabled = true,
        Callback = function()
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            if not myHrp then return end
            local targetSpawn: BasePart? = nil

            for _, lob in ipairs(lobbyObjects) do
                if lob and lob.Parent then
                    for _, desc in ipairs(lob:GetDescendants()) do
                        if desc:IsA("SpawnLocation") or (desc:IsA("BasePart") and string.find(string.lower(desc.Name), "spawn")) then
                            targetSpawn = desc :: BasePart
                            break
                        end
                    end
                    if not targetSpawn and lob:IsA("Model") then
                        local destCF = lob:GetPivot() + Vector3.new(0, 5, 0)
                        lastLobbyCFrame = destCF
                        lobbyLockActive = true
                        myHrp.AssemblyLinearVelocity = Vector3.zero
                        myHrp.CFrame = destCF
                        Window:Notify({ Title = "Teleport", Description = "Teleported to Lobby.", Duration = 2 })
                        return
                    end
                end
                if targetSpawn then break end
            end

            if not targetSpawn then
                for _, desc in ipairs(workspace:GetDescendants()) do
                    if desc:IsA("SpawnLocation") then
                        targetSpawn = desc
                        break
                    end
                end
            end

            if targetSpawn then
                local destCF = targetSpawn.CFrame + Vector3.new(0, 4, 0)
                lastLobbyCFrame = destCF
                lobbyLockActive = true
                myHrp.AssemblyLinearVelocity = Vector3.zero
                myHrp.CFrame = destCF
                Window:Notify({ Title = "Teleport", Description = "Teleported to Lobby.", Duration = 2 })
            end
        end
    })

    TeleportCat:AddButton({
        Name = "Teleport to Map",
        Enabled = true,
        Callback = function()
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            if not myHrp then return end

            lobbyLockActive = false
            lastLobbyCFrame = nil

            local mapFolder: Instance? = workspace:FindFirstChild("map")
            if not mapFolder then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj.Name == "map" and (obj:IsA("Folder") or obj:IsA("Model")) then
                        mapFolder = obj
                        break
                    end
                end
            end

            if not mapFolder then
                Window:Notify({ Title = "Teleport to Map", Description = "Folder 'map' not found in Workspace.", Duration = 2 })
                return
            end

            local spawnCandidates: {BasePart} = {}

            for _, mapChild in ipairs(mapFolder:GetChildren()) do
                local spawnsFolder = mapChild:FindFirstChild("spawns")
                if spawnsFolder then
                    local civFolder = spawnsFolder:FindFirstChild("civ")
                    if civFolder then
                        for _, sp in ipairs(civFolder:GetChildren()) do
                            if sp:IsA("BasePart") and string.lower(sp.Name) == "spawn" then
                                table.insert(spawnCandidates, sp)
                            elseif sp:IsA("BasePart") then
                                table.insert(spawnCandidates, sp)
                            end
                        end
                    end
                    if #spawnCandidates == 0 then
                        for _, desc in ipairs(spawnsFolder:GetDescendants()) do
                            if desc:IsA("BasePart") then
                                table.insert(spawnCandidates, desc)
                            end
                        end
                    end
                end
            end

            if #spawnCandidates == 0 then
                for _, desc in ipairs(mapFolder:GetDescendants()) do
                    if desc:IsA("BasePart") and string.lower(desc.Name) == "spawn" then
                        table.insert(spawnCandidates, desc)
                    end
                end
            end

            if #spawnCandidates > 0 then
                local chosenSpawn = spawnCandidates[math.random(1, #spawnCandidates)]
                myHrp.AssemblyLinearVelocity = Vector3.zero
                myHrp.CFrame = chosenSpawn.CFrame + Vector3.new(0, 4, 0)
                Window:Notify({ Title = "Teleport to Map", Description = "Teleported to map spawn.", Duration = 2 })
            else
                Window:Notify({ Title = "Teleport to Map", Description = "No 'spawn' parts found inside map -> spawns -> civ.", Duration = 2 })
            end
        end
    })
end

do
    local OptCat = GameTab:AddCategory("Optimization")
    local autoCleanEnabled = false
    local maxProjectiles = 20
    local maxShells = 15

    local ProjectilesFolder: Instance? = nil
    local ShellsFolder: Instance? = nil

    task.spawn(function()
        local sphWs = workspace:WaitForChild("SPH_Workspace", 10)
        if sphWs then
            ProjectilesFolder = sphWs:WaitForChild("Projectiles", 10)
            ShellsFolder = sphWs:WaitForChild("Shells", 10)
        end
    end)

    local function trimFolder(folder: Instance?, limit: number)
        if not folder then return end
        local items = folder:GetChildren()
        local count = #items
        if count > limit then
            for i = 1, count - limit do
                local obj = items[i]
                pcall(function() obj:Destroy() end)
            end
        end
    end

    RunService.Heartbeat:Connect(function()
        if not autoCleanEnabled then return end
        trimFolder(ProjectilesFolder, maxProjectiles)
        trimFolder(ShellsFolder, maxShells)
    end)

    local function clearAllProjectilesAndShells()
        if ProjectilesFolder then
            for _, child in ipairs(ProjectilesFolder:GetChildren()) do
                pcall(function() child:Destroy() end)
            end
        end
        if ShellsFolder then
            for _, child in ipairs(ShellsFolder:GetChildren()) do
                pcall(function() child:Destroy() end)
            end
        end
    end

    OptCat:AddToggle({
        Name = "Auto-Clean Projectiles & Shells",
        Default = false,
        Callback = function(val) autoCleanEnabled = val end
    })

    OptCat:AddSlider({
        Name = "Max Projectiles",
        Min = 5, Max = 80, Default = 20, Enabled = true,
        Callback = function(val) maxProjectiles = val end
    })

    OptCat:AddSlider({
        Name = "Max Shells",
        Min = 5, Max = 80, Default = 15, Enabled = true,
        Callback = function(val) maxShells = val end
    })

    OptCat:AddButton({
        Name = "Clear Now",
        Enabled = true,
        Callback = function()
            clearAllProjectilesAndShells()
            Window:Notify({
                Title = "Cleared",
                Description = "Projectiles and shells removed.",
                Duration = 2
            })
        end
    })

    local FpsBoostCat = GameTab:AddCategory("FPS Boost")
    local removeTextureEnabled = false
    local deleteDistantEnabled = false
    local renderDistStuds = 64
    local DistantSlider

    local savedMaterials: {[BasePart]: Enum.Material} = {}
    local savedDecals: {[Instance]: number} = {}

    local function stripObjectTexture(obj: Instance)
        if obj:IsA("BasePart") and not obj:IsA("Terrain") then
            if not savedMaterials[obj] then
                savedMaterials[obj] = obj.Material
            end
            obj.Material = Enum.Material.SmoothPlastic
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            local dec = obj :: Decal
            if savedDecals[obj] == nil then
                savedDecals[obj] = dec.Transparency
            end
            dec.Transparency = 1
        end
    end

    local function restoreAllTextures()
        for part, mat in pairs(savedMaterials) do
            if part and part.Parent then
                part.Material = mat
            end
        end
        table.clear(savedMaterials)

        for dec, tran in pairs(savedDecals) do
            if dec and dec.Parent then
                (dec :: Decal).Transparency = tran
            end
        end
        table.clear(savedDecals)
    end

    FpsBoostCat:AddToggle({
        Name = "Remove Texture",
        Default = false,
        Callback = function(val)
            removeTextureEnabled = val
            if val then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    stripObjectTexture(obj)
                end
            else
                restoreAllTextures()
            end
        end
    })

    workspace.DescendantAdded:Connect(function(obj)
        if removeTextureEnabled then
            task.defer(function()
                stripObjectTexture(obj)
            end)
        end
    end)

    local hiddenDistantParts: {[BasePart]: {tran: number, shadow: boolean}} = {}

    local function isCharacterPart(part: BasePart): boolean
        if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then
            return true
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and part:IsDescendantOf(p.Character) then
                return true
            end
        end
        return false
    end

    local function restoreAllHiddenParts()
        for part, info in pairs(hiddenDistantParts) do
            if part and part.Parent then
                part.Transparency = info.tran
                part.CastShadow = info.shadow
            end
            hiddenDistantParts[part] = nil
        end
    end

    FpsBoostCat:AddToggle({
        Name = "Delete Distant Parts",
        Default = false,
        Callback = function(val)
            deleteDistantEnabled = val
            DistantSlider:SetEnabled(val)
            if not val then
                restoreAllHiddenParts()
            end
        end
    })

    DistantSlider = FpsBoostCat:AddSlider({
        Name = "Distance",
        Min = 8, Max = 256, Default = 64, Suffix = " st", Enabled = false,
        Callback = function(val)
            renderDistStuds = val
        end
    })

    local lastCullTick = 0
    RunService.Heartbeat:Connect(function()
        if not deleteDistantEnabled then return end
        local now = os.clock()
        if now - lastCullTick < 0.15 then return end
        lastCullTick = now

        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not myHrp then return end
        local myPos = myHrp.Position

        for part, info in pairs(hiddenDistantParts) do
            if not part or not part.Parent then
                hiddenDistantParts[part] = nil
            elseif (part.Position - myPos).Magnitude <= renderDistStuds then
                part.Transparency = info.tran
                part.CastShadow = info.shadow
                hiddenDistantParts[part] = nil
            end
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsA("Terrain") and obj.Name ~= "TaphClientLadder" and not isCharacterPart(obj) then
                if (obj.Position - myPos).Magnitude > renderDistStuds then
                    if not hiddenDistantParts[obj] then
                        hiddenDistantParts[obj] = {
                            tran = obj.Transparency,
                            shadow = obj.CastShadow
                        }
                        obj.Transparency = 1
                        obj.CastShadow = false
                    end
                end
            end
        end
    end)

    local MapInfoCat = GameTab:AddCategory("Map Information")
    local CurrentMapLbl = MapInfoCat:AddLabel("Current Map: None")
    local PlayersRoundLbl = MapInfoCat:AddLabel("Players on Round: 0")
    local PlayersAliveLbl = MapInfoCat:AddLabel("Players Alive: 0")
    local SeekerDistLbl = MapInfoCat:AddLabel("How Close is Seeker: 0 Studs")

    local WidgetFrame = create("Frame", {
        Name = "MapInfoWidget",
        Size = UDim2.new(0, 225, 0, 118),
        Position = UDim2.new(1, -240, 0, 16),
        BackgroundColor3 = Color3.fromRGB(14, 19, 16),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 250,
        Parent = Window:GetScreenGui()
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        create("UIStroke", { Color = Color3.fromRGB(46, 213, 115), Thickness = 1.2, Transparency = 0.25 }),
        create("TextLabel", {
            Size = UDim2.new(1, -20, 0, 22),
            Position = UDim2.new(0, 12, 0, 6),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(46, 213, 115),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Map Information",
            ZIndex = 251
        })
    })
    makeDraggable(WidgetFrame)

    local W_CurrentMap = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 12, 0, 30),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(225, 235, 228),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Current Map: None",
        ZIndex = 251,
        Parent = WidgetFrame
    })

    local W_PlayersRound = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 12, 0, 50),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(225, 235, 228),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Players on Round: 0",
        ZIndex = 251,
        Parent = WidgetFrame
    })

    local W_PlayersAlive = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 12, 0, 70),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(225, 235, 228),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Players Alive: 0",
        ZIndex = 251,
        Parent = WidgetFrame
    })

    local W_SeekerDist = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 12, 0, 90),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(225, 235, 228),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "How Close is Seeker: 0 Studs",
        ZIndex = 251,
        Parent = WidgetFrame
    })

    registerThemedElement(function()
        local w = (currentTheme == "White")
        WidgetFrame.BackgroundColor3 = w and Color3.fromRGB(240, 245, 242) or Color3.fromRGB(14, 19, 16)
        local tc = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
        W_CurrentMap.TextColor3 = tc
        W_PlayersRound.TextColor3 = tc
        W_PlayersAlive.TextColor3 = tc
        W_SeekerDist.TextColor3 = tc
    end)

    MapInfoCat:AddToggle({
        Name = "Add Widget Map Information",
        Default = false,
        Callback = function(val)
            WidgetFrame.Visible = val
        end
    })

    local trackedMapInstance: Instance? = nil
    local lockedRoundCount = 0
    local roundCountLocked = false
    local firstTeleportTimestamp = 0

    RunService.Heartbeat:Connect(function()
        local mapFolder = workspace:FindFirstChild("map")
        local activeMapModel: Instance? = nil
        if mapFolder then
            for _, child in ipairs(mapFolder:GetChildren()) do
                if child:IsA("Model") or child:IsA("Folder") then
                    activeMapModel = child
                    break
                end
            end
        end

        if activeMapModel ~= trackedMapInstance then
            trackedMapInstance = activeMapModel
            lockedRoundCount = 0
            roundCountLocked = false
            firstTeleportTimestamp = 0
        end

        local mapNameStr = activeMapModel and activeMapModel.Name or "None"

        local aliveOnMap = 0
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        local closestSeekerStuds: number? = nil

        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
            if char and hum and hum.Health > 0 and hrp then
                if not isInLobby(plr) then
                    aliveOnMap += 1
                    if plr ~= LocalPlayer and hasGun(plr) and myHrp then
                        local dist = math.floor((hrp.Position - myHrp.Position).Magnitude)
                        if closestSeekerStuds == nil or dist < closestSeekerStuds then
                            closestSeekerStuds = dist
                        end
                    end
                end
            end
        end

        if activeMapModel then
            if not roundCountLocked then
                if aliveOnMap > 0 then
                    if firstTeleportTimestamp == 0 then
                        firstTeleportTimestamp = os.clock()
                    end
                    if aliveOnMap > lockedRoundCount then
                        lockedRoundCount = aliveOnMap
                    end
                    if os.clock() - firstTeleportTimestamp >= 4 then
                        roundCountLocked = true
                    end
                end
            end
        else
            lockedRoundCount = 0
            roundCountLocked = false
            firstTeleportTimestamp = 0
        end

        local seekerText = closestSeekerStuds and (tostring(closestSeekerStuds) .. " Studs") or "0 Studs"

        local t1 = "Current Map: " .. mapNameStr
        local t2 = "Players on Round: " .. tostring(lockedRoundCount)
        local t3 = "Players Alive: " .. tostring(aliveOnMap)
        local t4 = "How Close is Seeker: " .. seekerText

        CurrentMapLbl.Text = t1
        PlayersRoundLbl.Text = t2
        PlayersAliveLbl.Text = t3
        SeekerDistLbl.Text = t4

        W_CurrentMap.Text = t1
        W_PlayersRound.Text = t2
        W_PlayersAlive.Text = t3
        W_SeekerDist.Text = t4
    end)
end

do
    local SaveFuncCat = SettingsTab:AddCategory("Save Functions")
    SaveFuncCat:AddToggle({
        Name = "Save Functions",
        Default = false,
        ConfigKey = "Settings_SaveFunctions",
        Callback = function(val)
            saveFunctionsEnabled = val
            if val then
                writeTextFile(AutoSaveFile, serializeCurrentConfig())
            else
                removeTextFile(AutoSaveFile)
            end
        end
    })

    local JsonCat = SettingsTab:AddCategory("JSON Config")
    local jsonContainer = JsonCat:GetContainer()
    local selectedConfigName = "Select Config"

    local ConfigInputBox = create("TextBox", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Color3.fromRGB(20, 26, 22),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(235, 245, 238),
        PlaceholderText = "Enter config name...",
        PlaceholderColor3 = Color3.fromRGB(115, 130, 120),
        Text = "",
        ClearTextOnFocus = false,
        Parent = jsonContainer
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 7) }),
        create("UIStroke", { Color = Color3.fromRGB(36, 52, 42), Thickness = 1 }),
        create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
    })

    local ConfigDropdownBtn = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Color3.fromRGB(22, 32, 26),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(46, 213, 115),
        Text = "Select Config",
        Parent = jsonContainer
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 7) }),
        create("UIStroke", { Color = Color3.fromRGB(46, 213, 115), Thickness = 1, Transparency = 0.45 })
    })

    local ConfigListFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(18, 24, 20),
        BorderSizePixel = 0,
        Visible = false,
        Parent = jsonContainer
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 7) }),
        create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
        create("UIPadding", {
            PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)
        })
    })

    registerThemedElement(function()
        local w = (currentTheme == "White")
        ConfigInputBox.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
        ConfigInputBox.TextColor3 = w and Color3.fromRGB(20, 30, 25) or Color3.fromRGB(235, 245, 238)
        ConfigDropdownBtn.BackgroundColor3 = w and Color3.fromRGB(214, 228, 218) or Color3.fromRGB(22, 32, 26)
        ConfigListFrame.BackgroundColor3 = w and Color3.fromRGB(220, 228, 223) or Color3.fromRGB(18, 24, 20)
    end)

    local AddCfgBtn, DeleteCfgBtn, RenameCfgBtn, AutoLoadCfgBtn

    local function updateConfigButtonsState()
        local valid = (selectedConfigName ~= "Select Config" and selectedConfigName ~= "")
        DeleteCfgBtn:SetEnabled(valid)
        RenameCfgBtn:SetEnabled(valid)
        AutoLoadCfgBtn:SetEnabled(valid)
        AddCfgBtn:SetEnabled(true)
    end

    local function setSelectedConfig(name: string)
        selectedConfigName = name
        ConfigDropdownBtn.Text = name
        ConfigListFrame.Visible = false
        updateConfigButtonsState()
        if name ~= "Select Config" then
            local raw = readTextFile(FolderName .. "/" .. name .. ".json")
            if raw then
                applyConfigJson(raw)
                Window:Notify({ Title = "JSON Config", Description = "Loaded config '" .. name .. "'.", Duration = 2 })
            end
        end
    end

    local function rebuildConfigList()
        for _, child in ipairs(ConfigListFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        local defaultOpt = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = Color3.fromRGB(26, 34, 29),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(180, 195, 185),
            Text = "Select Config",
            Parent = ConfigListFrame
        }, { create("UICorner", { CornerRadius = UDim.new(0, 5) }) })

        defaultOpt.MouseButton1Click:Connect(function()
            setSelectedConfig("Select Config")
        end)

        for _, cfgName in ipairs(listConfigNames()) do
            local CBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = Color3.fromRGB(24, 38, 30),
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = Color3.fromRGB(46, 213, 115),
                Text = cfgName .. ".json",
                Parent = ConfigListFrame
            }, { create("UICorner", { CornerRadius = UDim.new(0, 5) }) })

            CBtn.MouseButton1Click:Connect(function()
                setSelectedConfig(cfgName)
            end)
        end
    end

    ConfigDropdownBtn.MouseButton1Click:Connect(function()
        ConfigListFrame.Visible = not ConfigListFrame.Visible
        if ConfigListFrame.Visible then
            rebuildConfigList()
        end
    end)

    AddCfgBtn = JsonCat:AddButton({
        Name = "Add",
        Enabled = true,
        Callback = function()
            local rawName = string.gsub(ConfigInputBox.Text, "[^%w_%-]", "")
            if #rawName == 0 then
                Window:Notify({ Title = "JSON Config", Description = "Enter a valid config name in the text box first.", Duration = 2 })
                return
            end
            writeTextFile(FolderName .. "/" .. rawName .. ".json", serializeCurrentConfig())
            ConfigInputBox.Text = ""
            setSelectedConfig(rawName)
            Window:Notify({ Title = "JSON Config", Description = "Created config '" .. rawName .. ".json'.", Duration = 2 })
        end
    })

    DeleteCfgBtn = JsonCat:AddButton({
        Name = "Delete",
        Enabled = false,
        Callback = function()
            if selectedConfigName == "Select Config" then return end
            local target = selectedConfigName
            removeTextFile(FolderName .. "/" .. target .. ".json")
            local autoLoaded = readTextFile(AutoLoadMetaFile)
            if autoLoaded == target then
                removeTextFile(AutoLoadMetaFile)
            end
            setSelectedConfig("Select Config")
            Window:Notify({ Title = "JSON Config", Description = "Deleted config '" .. target .. ".json'.", Duration = 2 })
        end
    })

    RenameCfgBtn = JsonCat:AddButton({
        Name = "Rename",
        Enabled = false,
        Callback = function()
            if selectedConfigName == "Select Config" then return end
            local newName = string.gsub(ConfigInputBox.Text, "[^%w_%-]", "")
            if #newName == 0 then
                Window:Notify({ Title = "JSON Config", Description = "Enter the new name in the text box first.", Duration = 2 })
                return
            end
            local oldPath = FolderName .. "/" .. selectedConfigName .. ".json"
            local newPath = FolderName .. "/" .. newName .. ".json"
            local existingData = readTextFile(oldPath) or serializeCurrentConfig()
            writeTextFile(newPath, existingData)
            removeTextFile(oldPath)

            local autoLoaded = readTextFile(AutoLoadMetaFile)
            if autoLoaded == selectedConfigName then
                writeTextFile(AutoLoadMetaFile, newName)
            end

            ConfigInputBox.Text = ""
            setSelectedConfig(newName)
            Window:Notify({ Title = "JSON Config", Description = "Renamed config to '" .. newName .. ".json'.", Duration = 2 })
        end
    })

    AutoLoadCfgBtn = JsonCat:AddButton({
        Name = "Set as AutoLoad",
        Enabled = false,
        Callback = function()
            if selectedConfigName == "Select Config" then return end
            writeTextFile(AutoLoadMetaFile, selectedConfigName)
            writeTextFile(FolderName .. "/" .. selectedConfigName .. ".json", serializeCurrentConfig())
            Window:Notify({ Title = "JSON Config", Description = "'" .. selectedConfigName .. ".json' set as AutoLoad.", Duration = 2 })
        end
    })

    local UISettingsCat = SettingsTab:AddCategory("UI Settings")
    local uiContainer = UISettingsCat:GetContainer()

    local KeybindBtn = create("TextButton", {
        Size = UDim2.new(0, 56, 0, 22),
        Position = UDim2.new(1, -66, 0.5, -11),
        BackgroundColor3 = Color3.fromRGB(10, 14, 12),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(46, 213, 115),
        Text = Window:GetToggleKey().Name,
        AutoButtonColor = false
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 5) }),
        create("UIStroke", { Color = Color3.fromRGB(46, 213, 115), Thickness = 1, Transparency = 0.4 })
    })

    local KeybindRowLbl = create("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Set keybind to open/close UI"
    })

    local KeybindRow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BorderSizePixel = 0,
        Parent = uiContainer
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 7) }),
        KeybindRowLbl,
        KeybindBtn
    })

    registerThemedElement(function()
        local w = (currentTheme == "White")
        KeybindRow.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
        KeybindRowLbl.TextColor3 = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
        KeybindBtn.BackgroundColor3 = w and Color3.fromRGB(210, 224, 215) or Color3.fromRGB(10, 14, 12)
    end)

    local waitingForUiKey = false
    KeybindBtn.MouseButton1Click:Connect(function()
        waitingForUiKey = true
        Window:SetListeningToggleKey(true)
        KeybindBtn.Text = "..."
    end)

    UserInputService.InputBegan:Connect(function(input)
        if waitingForUiKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            waitingForUiKey = false
            Window:SetToggleKey(input.KeyCode)
            KeybindBtn.Text = input.KeyCode.Name
            ConfigValues["UI_ToggleKey"] = input.KeyCode.Name
            triggerAutoSave()
            task.defer(function()
                Window:SetListeningToggleKey(false)
            end)
        end
    end)

    ConfigSetters["UI_ToggleKey"] = function(val)
        if type(val) == "string" and (Enum.KeyCode :: any)[val] then
            local kc = (Enum.KeyCode :: any)[val]
            Window:SetToggleKey(kc)
            KeybindBtn.Text = kc.Name
        end
    end

    UISettingsCat:AddToggle({
        Name = "Disable Animations",
        Default = false,
        ConfigKey = "UI_DisableAnimations",
        Callback = function(val)
            disableAnimations = val
        end
    })

    UISettingsCat:AddDropdown({
        Name = "Theme",
        Options = { "Black", "White" },
        Default = "Black",
        ConfigKey = "UI_Theme",
        Callback = function(val)
            currentTheme = val
            applyThemeAll()
        end
    })

    local CreditsCat = SettingsTab:AddCategory("Credits")
    CreditsCat:AddLabel("Made by Lunex Softworks LLC.")

    task.defer(function()
        local autoLoadName = readTextFile(AutoLoadMetaFile)
        if autoLoadName and #autoLoadName > 0 then
            local raw = readTextFile(FolderName .. "/" .. autoLoadName .. ".json")
            if raw then
                selectedConfigName = autoLoadName
                ConfigDropdownBtn.Text = autoLoadName
                updateConfigButtonsState()
                applyConfigJson(raw)
                Window:Notify({
                    Title = "AutoLoad Config",
                    Description = "Loaded '" .. autoLoadName .. ".json' automatically.",
                    Duration = 3
                })
                return
            end
        end

        local autoSaveRaw = readTextFile(AutoSaveFile)
        if autoSaveRaw then
            applyConfigJson(autoSaveRaw)
        end
    end)
end

Window:Notify({
    Title = "Taph Hub",
    Description = "Loaded successfully (Press " .. Window:GetToggleKey().Name .. " to toggle UI)",
    Duration = 4
})
