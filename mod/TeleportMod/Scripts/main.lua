--[[
    逸剑风云决 · 世界地图传送面板 (TeleportMod) 最终版
    基于 UE4SS 实验版 + UE4.26

    功能：
      F2        呼出/关闭传送面板（世界地图大位置，鼠标点选或键盘选择）
      传送      tomap <ID>（游戏官方传送）
    兜底：
      F10 控制台输入地名/拼音/缩写 直接传送（601 个命令已注册）
]]

-- ============ 数据 ============

local ok_big, BigMaps = pcall(require, "bigmap_data")
if not ok_big or type(BigMaps) ~= "table" then
    BigMaps = {}
end

-- ============ 工具 ============

local function Log(msg)
    print(msg .. "\n")
end

local function FindPlayerController()
    local PCs = FindAllOf("PlayerController")
    if not PCs then
        PCs = FindAllOf("Controller")
    end
    if not PCs then return nil end
    for _, PC in pairs(PCs) do
        if PC and PC:IsValid() then
            return PC
        end
    end
    return nil
end

local function CallTomap(mapId)
    Log(string.format("[传送] tomap %d", mapId))
    ExecuteInGameThread(function()
        local PC = FindPlayerController()
        if not PC or not PC:IsValid() then
            Log("[传送] 错误：找不到 PlayerController")
            return
        end
        pcall(function()
            PC:ProcessConsoleExec("tomap " .. tostring(mapId), nil, PC)
            Log("[传送] tomap 已发送: " .. tostring(mapId))
        end)
    end)
end

-- ============ 面板状态 ============

local panel = nil
local menuOpen = false
local selectedIdx = 1
local itemTexts = {}
local textFont = nil
local pageIndex = 1
local PAGE_SIZE = 12

-- 从游戏已有 TextBlock 复制中文字体
local function GetChineseFont()
    local font = nil
    pcall(function()
        local texts = FindAllOf("TextBlock")
        if texts then
            for _, t in ipairs(texts) do
                if t and t:IsValid() then
                    font = t.Font
                    if font then break end
                end
            end
        end
    end)
    if font then
        Log("[面板] 已获取中文字体")
    end
    return font
end

-- 找一个可实例化的 UserWidget 容器类（优先稳定的面板/菜单类）
local function GetContainerClass()
    local widgets = FindAllOf("UserWidget")
    if widgets then
        -- 第一优先：面板/视图/菜单类
        for _, w in ipairs(widgets) do
            if w and w:IsValid() then
                local ok, cls = pcall(function() return w:GetClass() end)
                if ok and cls and cls:IsValid() then
                    local clsName = tostring(cls:GetFName():ToString())
                    if string.find(clsName, "Panel") or string.find(clsName, "View") or string.find(clsName, "Menu") then
                        Log("[面板] 容器类(面板类): " .. clsName)
                        return cls
                    end
                end
            end
        end
        -- 第二优先：跳过小组件（Element/Item/Cell），取第一个普通类
        for _, w in ipairs(widgets) do
            if w and w:IsValid() then
                local ok, cls = pcall(function() return w:GetClass() end)
                if ok and cls and cls:IsValid() then
                    local clsName = tostring(cls:GetFName():ToString())
                    if not string.find(clsName, "Element") and not string.find(clsName, "Item") and not string.find(clsName, "Cell") then
                        Log("[面板] 容器类(普通): " .. clsName)
                        return cls
                    end
                end
            end
        end
        -- 兜底：取第一个
        for _, w in ipairs(widgets) do
            if w and w:IsValid() then
                local ok, cls = pcall(function() return w:GetClass() end)
                if ok and cls and cls:IsValid() then
                    Log("[面板] 容器类(兜底): " .. tostring(cls:GetFName():ToString()))
                    return cls
                end
            end
        end
    end
    return nil
end

local function ConstructWidget(classPath, outer)
    local cls = StaticFindObject(classPath)
    if not cls then return nil end
    local ok, w = pcall(function()
        return StaticConstructObject(cls, outer, 0, 0, 0, nil, false, false, nil)
    end)
    if ok and w then return w end
    return nil
end

-- 创建面板
local function CreatePanel()
    ExecuteInGameThread(function()
        if panel and panel:IsValid() then return end

        local library = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
        if not library or not library:IsValid() then
            Log("[面板] WidgetBlueprintLibrary 不可用")
            return
        end

        local containerCls = GetContainerClass()
        if not containerCls then
            Log("[面板] 找不到容器类")
            return
        end

        local PC = FindPlayerController()
        local world = PC and PC:GetWorld()

        -- 用 UWidgetBlueprintLibrary:Create 创建（传具体类，不崩）
        local widget = library:Create(world, containerCls, PC)
        if not widget or not widget:IsValid() then
            Log("[面板] Create 失败")
            return
        end
        panel = widget

        -- 字体：暂不用复制的字体（可能无效导致渲染崩溃），先测稳定性
        textFont = nil

        -- 构建控件树
        pcall(function()
            local tree = widget.WidgetTree

            -- CanvasPanel 根
            local canvas = ConstructWidget("/Script/UMG.CanvasPanel", tree)
            if not canvas then
                Log("[面板] CanvasPanel 创建失败")
                return
            end
            tree.RootWidget = canvas

            -- 背景 Border（半透明黑）
            local border = ConstructWidget("/Script/UMG.Border", tree)
            local bs = canvas:AddChildToCanvas(border)
            bs:SetAnchors({ Minimum = { X = 0, Y = 0 }, Maximum = { X = 0, Y = 0 } })
            bs:SetPosition({ X = 30, Y = 30 })
            bs:SetSize({ X = 420, Y = 40 + PAGE_SIZE * 26 + 40 })
            pcall(function()
                border:SetBrushColor({ R = 0.1, G = 0.1, B = 0.1, A = 0.9 })
            end)

            -- VerticalBox
            local vbox = ConstructWidget("/Script/UMG.VerticalBox", tree)
            border:SetContent(vbox)

            -- 设置中文字体（楷体）的辅助函数
            local function SetCNFont(txt)
                pcall(function()
                    local f = LoadAsset("/Game/JH/JHNeoUI/UIAssets/Font/simkai")
                    if f and f:IsValid() then
                        local fi = txt.Font
                        fi.FontObject = f
                        txt:SetFont(fi)
                    end
                end)
            end

            -- 标题
            local title = ConstructWidget("/Script/UMG.TextBlock", tree)
            title:SetText(FText("世 界 地 图 传 送"))
            SetCNFont(title)
            vbox:AddChildToVerticalBox(title)

            -- 地图列表（固定 12 个槽位，分页填充）
            itemTexts = {}
            for i = 1, PAGE_SIZE do
                local txt = ConstructWidget("/Script/UMG.TextBlock", tree)
                SetCNFont(txt)
                vbox:AddChildToVerticalBox(txt)
                itemTexts[i] = txt
            end

            -- 提示行
            local hint = ConstructWidget("/Script/UMG.TextBlock", tree)
            hint:SetText(FText("UP/DOWN select  PGUP/PGDN page  ENTER go  ESC close"))
            SetCNFont(hint)
            vbox:AddChildToVerticalBox(hint)

            Log("[面板] 构建完成，准备 AddToViewport")
            widget:AddToViewport(10000)
            Log("[面板] AddToViewport 完成，共 " .. tostring(#BigMaps) .. " 个大位置")
        end)
    end)
end

local function UpdateSelection()
    -- 暂不用 SetColorAndOpacity（结构体参数可能崩溃），仅记录
    Log("[面板] UpdateSelection: 选中 " .. tostring(selectedIdx))
end

local function TotalPages()
    return math.ceil(#BigMaps / PAGE_SIZE)
end

local function UpdateList()
    Log("[面板] UpdateList: 槽位数=" .. tostring(#itemTexts))
    pcall(function()
        local pageStart = (pageIndex - 1) * PAGE_SIZE + 1
        for i = 1, PAGE_SIZE do
            local idx = pageStart + i - 1
            local m = BigMaps[idx]
            if m and itemTexts[i] then
                pcall(function()
                    itemTexts[i]:SetText(FText(string.format("%d. %s", idx, m.name)))
                end)
            elseif itemTexts[i] then
                pcall(function()
                    itemTexts[i]:SetText(FText(""))
                end)
            end
        end
    end)
    Log("[面板] UpdateList 完成")
    UpdateSelection()
end

local function ShowPanel()
    if not panel then
        CreatePanel()
    end
    menuOpen = true
    selectedIdx = 1
    pageIndex = 1
    Log("[面板] ShowPanel: 开始")
    pcall(function()
        if panel and panel:IsValid() then
            Log("[面板] ShowPanel: SetVisibility")
            panel:SetVisibility(0)  -- Visible
            local PC = FindPlayerController()
            local library = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
            if PC then
                Log("[面板] ShowPanel: SetInputMode_UIOnly")
                pcall(function() library:SetInputMode_UIOnly(PC, nil, 0, false) end)
                Log("[面板] ShowPanel: SetShowMouseCursor")
                pcall(function() PC:SetShowMouseCursor(true) end)
            end
        end
    end)
    Log("[面板] ShowPanel: UpdateList")
    UpdateList()
    Log("[面板] 面板已打开")
end

local function HidePanel()
    menuOpen = false
    pcall(function()
        if panel then
            -- 彻底移除面板（防止地图切换时崩溃）
            pcall(function() panel:RemoveFromParent() end)
            panel = nil
            local PC = FindPlayerController()
            local library = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
            if PC then
                pcall(function() library:SetInputMode_GameOnly(PC) end)
                pcall(function() PC:SetShowMouseCursor(false) end)
            end
        end
    end)
    Log("[面板] 面板已关闭")
end

-- 地图切换前自动清理面板（防止引用失效崩溃）
RegisterLoadMapPreHook(function()
    if panel then
        Log("[面板] 地图切换，清理面板")
        pcall(function() panel:RemoveFromParent() end)
        panel = nil
    end
    menuOpen = false
end)

-- ============ 键盘导航 ============

if not IsKeyBindRegistered(Key.UP_ARROW) then
    RegisterKeyBind(Key.UP_ARROW, function()
        if menuOpen and #BigMaps > 0 then
            local pageStart = (pageIndex - 1) * PAGE_SIZE + 1
            selectedIdx = selectedIdx - 1
            if selectedIdx < pageStart then
                pageIndex = pageIndex - 1
                if pageIndex < 1 then pageIndex = TotalPages() end
                selectedIdx = math.min(pageIndex * PAGE_SIZE, #BigMaps)
                UpdateList()
            else
                UpdateSelection()
            end
        end
    end)
end

if not IsKeyBindRegistered(Key.DOWN_ARROW) then
    RegisterKeyBind(Key.DOWN_ARROW, function()
        if menuOpen and #BigMaps > 0 then
            local pageEnd = math.min(pageIndex * PAGE_SIZE, #BigMaps)
            selectedIdx = selectedIdx + 1
            if selectedIdx > pageEnd then
                pageIndex = pageIndex + 1
                if pageIndex > TotalPages() then pageIndex = 1 end
                selectedIdx = (pageIndex - 1) * PAGE_SIZE + 1
                UpdateList()
            else
                UpdateSelection()
            end
        end
    end)
end

if not IsKeyBindRegistered(Key.PAGE_UP) then
    RegisterKeyBind(Key.PAGE_UP, function()
        if menuOpen then
            pageIndex = pageIndex - 1
            if pageIndex < 1 then pageIndex = TotalPages() end
            selectedIdx = (pageIndex - 1) * PAGE_SIZE + 1
            UpdateList()
        end
    end)
end

if not IsKeyBindRegistered(Key.PAGE_DOWN) then
    RegisterKeyBind(Key.PAGE_DOWN, function()
        if menuOpen then
            pageIndex = pageIndex + 1
            if pageIndex > TotalPages() then pageIndex = 1 end
            selectedIdx = (pageIndex - 1) * PAGE_SIZE + 1
            UpdateList()
        end
    end)
end

if not IsKeyBindRegistered(Key.RETURN) then
    RegisterKeyBind(Key.RETURN, function()
        if menuOpen then
            local m = BigMaps[selectedIdx]
            if m then
                Log("[传送] 面板选择: " .. m.name .. " (ID " .. tostring(m.id) .. ")")
                -- 先移除面板（防止地图切换时 widget 失效崩溃），再传送
                HidePanel()
                CallTomap(m.id)
            end
        end
    end)
end

if not IsKeyBindRegistered(Key.ESCAPE) then
    RegisterKeyBind(Key.ESCAPE, function()
        if menuOpen then HidePanel() end
    end)
end

-- ============ F2 呼出/关闭 ============

if not IsKeyBindRegistered(Key.F2) then
    RegisterKeyBind(Key.F2, function()
        Log("[面板] F2 按下")
        if menuOpen then
            HidePanel()
        else
            ShowPanel()
        end
    end)
end

-- ============ 兜底：F10 控制台地名传送 ============

-- 加载全部地图拼音数据（F10 控制台输入地名/拼音/缩写传送）
local ok_maps, AllMaps = pcall(require, "maps_pinyin")
if not ok_maps or type(AllMaps) ~= "table" then AllMaps = {} end

local function SearchMapsAll(kw)
    local k = string.lower(kw or "")
    local out = {}
    for _, m in ipairs(AllMaps) do
        local n = string.lower(m.name or "")
        local p = string.lower(m.pinyin or "")
        local a = string.lower(m.abbr or "")
        if string.find(n, k, 1, true) or string.find(p, k, 1, true) or string.find(a, k, 1, true) then
            table.insert(out, m)
        end
    end
    return out
end

-- 注册每个地名/拼音/唯一缩写为直接传送命令
local byName = {}
local order = {}
for _, m in ipairs(AllMaps) do
    if m.name and not byName[m.name] then
        byName[m.name] = m
        table.insert(order, m.name)
    end
end
local abbrCount = {}
for _, m in pairs(byName) do
    if m.abbr then abbrCount[m.abbr] = (abbrCount[m.abbr] or 0) + 1 end
end
local registered = {}
local regCount = 0
local function RegCmd(cmdname, m)
    if cmdname and cmdname ~= "" and not registered[cmdname] then
        pcall(function()
            RegisterConsoleCommandGlobalHandler(cmdname, function()
                Log(string.format("[传送] 「%s」-> %s (tomap %d)", cmdname, m.name, m.id))
                CallTomap(m.id)
            end)
        end)
        registered[cmdname] = true
        regCount = regCount + 1
    end
end
for _, name in ipairs(order) do
    local m = byName[name]
    RegCmd(m.name, m)
    RegCmd(m.pinyin, m)
    if abbrCount[m.abbr] == 1 then RegCmd(m.abbr, m) end
end

-- 保留 tpm 搜索命令
RegisterConsoleCommandGlobalHandler("tpm", function(Cmd, CommandParts, Ar)
    local kw = CommandParts and (CommandParts[2] or CommandParts[1])
    if not kw or kw == "tpm" then
        Log("[传送] 用法: tpm <地名>（如 tpm 姑苏城）")
        return true
    end
    local matches = SearchMapsAll(tostring(kw))
    if #matches == 1 then
        CallTomap(matches[1].id)
    elseif #matches == 0 then
        Log("[传送] 未找到「" .. tostring(kw) .. "」")
    else
        Log("[传送] 匹配多个：")
        for _, m in ipairs(matches) do
            Log("  " .. m.name)
        end
    end
    return true
end)

Log("[传送] 世界地图传送面板已就绪：F2 打开面板 / F10 控制台输入地名传送")
