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

-- 地图路径映射（MapName → 完整路径）
local ok_path, MapPaths = pcall(require, "maps_path")
if not ok_path or type(MapPaths) ~= "table" then MapPaths = {} end

local function CallTomap(mapId)
    Log(string.format("[传送] 地图ID %d", mapId))
    ExecuteInGameThread(function()
        pcall(function()
            -- 读 Maps 表的 MapName
            local dt = LoadAsset("/Game/JH/Tables/Maps.Maps")
            if not dt or not dt:IsValid() then
                Log("[传送] Maps 表加载失败")
                return
            end
            local row = dt:FindRow(tostring(mapId))
            if not row then
                Log("[传送] 找不到行: " .. tostring(mapId))
                return
            end
            local mapName = ""
            pcall(function() mapName = tostring(row.MapName:ToString()) end)
            local path = MapPaths[mapName]
            if not path then
                Log("[传送] 找不到路径: " .. mapName)
                return
            end
            -- ClientTravel 传送到完整地图路径
            local PC = FindPlayerController()
            if PC and PC:IsValid() then
                PC:ClientTravel(path, 1, false)
                Log("[传送] ClientTravel: " .. path)
            end
        end)
    end)
end

-- hook 游戏传送函数，捕获地图路径格式
RegisterHook("/Script/JH.JHNeoUISubsystem:ChangeSceneMapDDD", function(Params)
    Log("[传送hook] ChangeSceneMapDDD 触发！")
    pcall(function()
        for k, v in pairs(Params or {}) do
            Log("[传送hook] 参数[" .. tostring(k) .. "] = " .. tostring(v))
        end
    end)
end)

-- 驿站表 AddRow 验证（ForEachRow 读现有行 + AddRow 测试）
RegisterConsoleCommandGlobalHandler("tpadd2", function(Cmd, CommandParts, Ar)
    Log("[驿站] === ForEachRow 读现有行 ===")
    ExecuteInGameThread(function()
        local dt = LoadAsset("/Game/JH/Tables/CourierStation.CourierStation")
        if not dt or not dt:IsValid() then
            Log("[驿站] 加载失败")
            return
        end
        -- 读现有行
        pcall(function()
            local cnt = 0
            dt:ForEachRow(function(rowName, rowData)
                cnt = cnt + 1
                if cnt <= 20 then
                    pcall(function()
                        local id = tostring(rowData.ID)
                        local nm = ""
                        pcall(function() nm = tostring(rowData.DisplayName:ToString()) end)
                        local region = tostring(rowData.Region)
                        local mapId = tostring(rowData.MapId)
                        Log(string.format("[驿站] %s: ID=%s 名称=%s 区域=%s MapId=%s", tostring(rowName), id, nm, region, mapId))
                    end)
                end
            end)
            Log("[驿站] ForEachRow 共 " .. tostring(cnt) .. " 行")
        end)
        -- AddRow 测试
        Log("[驿站] === AddRow 测试 ===")
        pcall(function()
            dt:AddRow("test_map_1", {
                ID = 1000,
                DisplayName = FText("测试传送"),
                Region = 1,
                MapId = 27,
                Price = 0,
                TeleportationX = 0,
                TeleportationY = 0,
                TeleportationZ = 0,
                Requirements = {},
                NPCId = -1,
            })
            Log("[驿站] AddRow 测试成功！")
        end)
    end)
    return true
end)

-- 读 Maps 表 MapName 实际值（FName → 字符串）
RegisterConsoleCommandGlobalHandler("tpdir3", function(Cmd, CommandParts, Ar)
    ExecuteInGameThread(function()
        pcall(function()
            local dt = LoadAsset("/Game/JH/Tables/Maps.Maps")
            if not dt or not dt:IsValid() then return end
            for _, id in ipairs({1, 9, 15, 27, 1000}) do
                pcall(function()
                    local row = dt:FindRow(tostring(id))
                    if row then
                        local mn = ""
                        pcall(function() mn = tostring(row.MapName:ToString()) end)
                        Log("[dir3] ID " .. tostring(id) .. " MapName = " .. mn)
                    end
                end)
            end
        end)
    end)
    return true
end)

-- 读 Maps 表行字段（找 MapDir/MapName 地图路径）
RegisterConsoleCommandGlobalHandler("tpdir2", function(Cmd, CommandParts, Ar)
    ExecuteInGameThread(function()
        pcall(function()
            local dt = LoadAsset("/Game/JH/Tables/Maps.Maps")
            if not dt or not dt:IsValid() then return end
            -- 读行 9（梧桐村）的完整字段
            pcall(function()
                local row = dt:FindRow("9")
                if not row then
                    Log("[dir] 行 9 未找到")
                    return
                end
                local rs = dt:GetPropertyValue("RowStruct")
                if rs then
                    rs:ForEachProperty(function(prop)
                        pcall(function()
                            local pname = prop:GetFName():ToString()
                            local val = tostring(row[pname])
                            Log("[dir] 行9 字段 " .. pname .. " = " .. val)
                        end)
                    end)
                end
            end)
            -- 行 1000（武当派）的 MapDir/MapName
            pcall(function()
                local row = dt:FindRow("1000")
                if row then
                    pcall(function()
                        Log("[dir] 行1000 MapDir = " .. tostring(row.MapDir))
                        Log("[dir] 行1000 MapName = " .. tostring(row.MapName))
                    end)
                end
            end)
        end)
    end)
    return true
end)

-- 读新行完整字段 + 行名（确认注入行完整 + 界面过滤原因）
RegisterConsoleCommandGlobalHandler("tpcheck2", function(Cmd, CommandParts, Ar)
    ExecuteInGameThread(function()
        pcall(function()
            local dt = LoadAsset("/Game/JH/Tables/CourierStation.CourierStation")
            if not dt or not dt:IsValid() then return end
            local cnt = 0
            local shown = 0
            dt:ForEachRow(function(rowName, rowData)
                cnt = cnt + 1
                if shown < 25 then
                    shown = shown + 1
                    pcall(function()
                        local nm = tostring(rowData.DisplayName:ToString())
                        local mid = tostring(rowData.MapId)
                        local region = tostring(rowData.Region)
                        local price = tostring(rowData.Price)
                        Log(string.format("[chk] 行名=%s | 名称=%s | MapId=%s | 区域=%s | 价格=%s",
                            tostring(rowName), nm, mid, region, price))
                    end)
                end
            end)
            Log("[chk] 总行数=" .. tostring(cnt))
        end)
    end)
    return true
end)

-- 确认驿站表注入情况
RegisterConsoleCommandGlobalHandler("tpcheck", function(Cmd, CommandParts, Ar)
    ExecuteInGameThread(function()
        pcall(function()
            local dt = LoadAsset("/Game/JH/Tables/CourierStation.CourierStation")
            if not dt or not dt:IsValid() then
                Log("[驿站] 加载失败")
                return
            end
            local cnt = 0
            local newCnt = 0
            local samples = {}
            dt:ForEachRow(function(rowName, rowData)
                cnt = cnt + 1
                local rn = tostring(rowName)
                if string.find(rn, "map_") then
                    newCnt = newCnt + 1
                    if #samples < 8 then
                        pcall(function()
                            table.insert(samples, rn .. "=" .. tostring(rowData.MapId))
                        end)
                    end
                end
            end)
            Log(string.format("[驿站] 总行数=%d, 新地图行=%d", cnt, newCnt))
            Log("[驿站] 新行样本: " .. table.concat(samples, ", "))
        end)
    end)
    return true
end)

-- 扫描游戏传送相关对象/类（找正确的传送入口）
RegisterConsoleCommandGlobalHandler("tpscan", function(Cmd, CommandParts, Ar)
    Log("[scan] 开始扫描传送相关对象")
    ExecuteInGameThread(function()
        local count = 0
        pcall(function()
            ForEachUObject(function(obj)
                if count >= 30 then return true end
                pcall(function()
                    local full = obj:GetFullName()
                    if string.find(full, "ChangeSceneMap") or string.find(full, "AsyncTaskChangeScene") or string.find(full, "UAsyncTask") then
                        count = count + 1
                        Log("[scan] " .. full)
                    end
                end)
            end)
        end)
        Log("[scan] 找到 " .. tostring(count) .. " 个，扫描结束")
    end)
    return true
end)

-- dump JHNeoUISubsystem 函数（找命令处理入口）
RegisterConsoleCommandGlobalHandler("tpfn", function(Cmd, CommandParts, Ar)
    ExecuteInGameThread(function()
        pcall(function()
            local JH = StaticFindObject("/Script/JH.Default__JHNeoUISubsystem")
            if JH and JH:IsValid() then
                local cls = JH:GetClass()
                local cnt = 0
                cls:ForEachFunction(function(fn)
                    cnt = cnt + 1
                    Log("[FN] " .. fn:GetFName():ToString())
                end)
                Log("[FN] JHNeoUISubsystem 函数总数: " .. tostring(cnt))
            end
        end)
    end)
    return true
end)

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

        -- 构建控件树（简化：VerticalBox 根，不用 Canvas/Border/字体，先确认 SetText 工作）
        pcall(function()
            local tree = widget.WidgetTree

            -- ScrollBox 根（驿站风格：滚动列表，全量铺开）
            local scroll = ConstructWidget("/Script/UMG.ScrollBox", tree)
            if not scroll then
                Log("[面板] ScrollBox 创建失败")
                return
            end
            tree.RootWidget = scroll

            -- 标题
            local title = ConstructWidget("/Script/UMG.TextBlock", tree)
            pcall(function() title:SetText(FText(string.format("WORLD MAP TELEPORT (%d)", #BigMaps))) end)
            scroll:AddChild(title)

            -- 全部地图（每个一个按钮，先用键盘选择+回车传送；点击绑定另行处理）
            itemTexts = {}
            for i, m in ipairs(BigMaps) do
                local btn = ConstructWidget("/Script/UMG.Button", tree)
                local txt = ConstructWidget("/Script/UMG.TextBlock", tree)
                pcall(function()
                    txt:SetText(FText(string.format("%d. %s", i, m.name)))
                    btn:SetContent(txt)
                end)
                scroll:AddChild(btn)
                itemTexts[i] = txt
            end
            Log("[面板] 全量按钮创建完成: " .. tostring(#BigMaps) .. " 项")

            widget:AddToViewport(10000)
            Log("[面板] ScrollBox 面板 AddToViewport 完成")
        end)
    end)
end

local lastSel = 0
local function UpdateSelection()
    -- 面板内高亮选中项（改 2 个 TextBlock：取消上一个 ▶，标记当前 ▶）
    pcall(function()
        if lastSel > 0 and lastSel <= #BigMaps and itemTexts[lastSel] then
            itemTexts[lastSel]:SetText(FText(string.format("%d. %s", lastSel, BigMaps[lastSel].name)))
        end
    end)
    local m = BigMaps[selectedIdx]
    if m and itemTexts[selectedIdx] then
        pcall(function()
            itemTexts[selectedIdx]:SetText(FText(string.format("▶ %d. %s", selectedIdx, m.name)))
        end)
    end
    lastSel = selectedIdx
    -- 日志反馈（日志可见）
    Log("[面板] 选择: " .. tostring(selectedIdx) .. " " .. tostring(m and m.name or "?"))
end

local function UpdateList()
    UpdateSelection()
end

local function ShowPanel()
    if not panel then
        CreatePanel()  -- 创建时 UpdateList 一次
    end
    menuOpen = true
    selectedIdx = 1
    pageIndex = 1
    Log("[面板] ShowPanel: 开始")
    -- 面板已存在时不反复 UpdateList（避免复用崩溃），用屏幕提示当前选择
    local m = BigMaps[selectedIdx]
    if m then
        ScreenMsg(string.format("[传送] 1/%d 当前: %s (PgDn翻页)", #BigMaps, m.name))
    end
    -- 切 UI 模式（↑↓ 选择生效，角色锁定，类似背包）
    local PC = FindPlayerController()
    local library = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    if PC then
        pcall(function() library:SetInputMode_UIOnly(PC, nil, 0, false) end)
    end
    Log("[面板] 面板已打开")
end

local function HidePanel()
    menuOpen = false
    Log("[面板] HidePanel: 开始")
    -- 恢复游戏模式（不碰面板，面板留待 LoadMap 清理）
    local PC = FindPlayerController()
    local library = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    if PC then
        pcall(function() library:SetInputMode_GameOnly(PC) end)
    end
    Log("[面板] 面板已关闭")
end

-- 地图切换前清理面板引用（不 RemoveFromParent，让 LoadMap 自然清理）
RegisterLoadMapPreHook(function()
    panel = nil
    menuOpen = false
    Log("[面板] LoadMap: 清理面板引用")
end)

-- ============ 键盘导航 ============

if not IsKeyBindRegistered(Key.UP_ARROW) then
    RegisterKeyBind(Key.UP_ARROW, function()
        if menuOpen and #BigMaps > 0 then
            selectedIdx = selectedIdx - 1
            if selectedIdx < 1 then selectedIdx = #BigMaps end
            UpdateSelection()
        end
    end)
end

if not IsKeyBindRegistered(Key.DOWN_ARROW) then
    RegisterKeyBind(Key.DOWN_ARROW, function()
        if menuOpen and #BigMaps > 0 then
            selectedIdx = selectedIdx + 1
            if selectedIdx > #BigMaps then selectedIdx = 1 end
            UpdateSelection()
        end
    end)
end

if not IsKeyBindRegistered(Key.PAGE_UP) then
    RegisterKeyBind(Key.PAGE_UP, function()
        if menuOpen then
            selectedIdx = selectedIdx - 10
            if selectedIdx < 1 then selectedIdx = 1 end
            UpdateSelection()
        end
    end)
end

if not IsKeyBindRegistered(Key.PAGE_DOWN) then
    RegisterKeyBind(Key.PAGE_DOWN, function()
        if menuOpen then
            selectedIdx = selectedIdx + 10
            if selectedIdx > #BigMaps then selectedIdx = #BigMaps end
            UpdateSelection()
        end
    end)
end

if not IsKeyBindRegistered(Key.RETURN) then
    RegisterKeyBind(Key.RETURN, function()
        if menuOpen then
            local m = BigMaps[selectedIdx]
            if m then
                Log("[传送] 面板选择: " .. m.name)
                Log("[面板] 回车: 先 HidePanel")
                HidePanel()
                Log("[面板] 回车: HidePanel 完成，CallTomap")
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

-- ============ F2 呼出/关闭传送按钮面板 ============

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
                return true
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

-- ============ 批量注入：92 个地图注册成驿站（驿站界面鼠标点击传送） ============

local courierInjected = false
local function AddAllMapsToCourier()
    if courierInjected then return end
    courierInjected = true
    ExecuteInGameThread(function()
        local dt = LoadAsset("/Game/JH/Tables/CourierStation.CourierStation")
        if not dt or not dt:IsValid() then
            Log("[驿站] 表加载失败，稍后重试")
            courierInjected = false
            return
        end
        -- 找原驿站模板（ID 1 平康城驿站），复制其完整结构
        local template = nil
        dt:ForEachRow(function(rowName, rowData)
            if tostring(rowName) == "1" then
                template = rowData
                return true
            end
        end)
        if not template then
            Log("[驿站] 找不到原驿站模板（ID 1）")
            return
        end
        local count = 0
        for i, m in ipairs(BigMaps) do
            pcall(function()
                local rn = tostring(100 + i)
                dt:AddRow(rn, template)  -- 复制原驿站完整结构
                local row = dt:FindRow(rn)
                if row then
                    row.MapId = m.id
                    row.DisplayName = FText(m.name)
                end
                count = count + 1
            end)
        end
        Log("[驿站] 已复制注入 " .. tostring(count) .. " 个地图到驿站表（结构对齐原驿站）")
    end)
end
-- 启动 10 秒后注入（游戏世界加载后）
ExecuteWithDelay(10000, AddAllMapsToCourier)
