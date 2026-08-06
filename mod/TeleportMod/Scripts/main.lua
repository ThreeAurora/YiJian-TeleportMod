--[[
    逸剑风云决 · 全地图传送 mod (TeleportMod)
    基于 UE4SS 实验版 + UE4.26

    用法（按 `~` 或 F10 打开 UE 控制台）：
      tpm <关键词>       搜索地图并传送（唯一匹配直接传，多匹配列出）
      tplist [关键词]    列出全部/匹配的地图
      tphelp             显示帮助
    快捷键：
      F6                 直接传送到测试地图（Map65 修罗道）
]]

-- ============ 工具函数 ============

local function Log(msg)
    print(msg .. "\n")
end

-- 找到玩家控制器
local function FindPlayerController()
    local PCs = FindAllOf("PlayerController")
    if not PCs then
        PCs = FindAllOf("Controller")
    end
    if not PCs then
        return nil
    end
    for _, PC in pairs(PCs) do
        if PC:IsValid() then
            return PC
        end
    end
    return nil
end

-- 获取 UGameplayStatics 默认对象
local function GetGameplayStatics()
    return StaticFindObject("/Script/Engine.Default__GameplayStatics")
end

-- 尝试在游戏屏幕显示消息
local function ScreenMsg(msg)
    local PC = FindPlayerController()
    if PC and PC:IsValid() then
        pcall(function()
            PC:ClientMessage(msg, FName("None"), 5.0)
        end)
    end
end

-- ============ 地图数据 ============

local ok_maps, Maps = pcall(require, "maps")
if not ok_maps or type(Maps) ~= "table" then
    Log("[传送] 警告：maps.lua 加载失败")
    Maps = {}
end
Log(string.format("[传送] 已加载 %d 张地图", #Maps))

-- ============ 搜索 ============

local function SearchMaps(kw)
    local k = string.lower(kw or "")
    local out = {}
    for _, m in ipairs(Maps) do
        if string.find(string.lower(m.name), k, 1, true) or
           string.find(string.lower(m.path), k, 1, true) then
            table.insert(out, m)
        end
    end
    return out
end

-- ============ 传送（多路尝试） ============

local function Teleport(mapPath)
    Log("[传送] 开始传送: " .. tostring(mapPath))
    ExecuteInGameThread(function()
        local PC = FindPlayerController()
        if not PC or not PC:IsValid() then
            Log("[传送] 错误：找不到 PlayerController")
            return
        end
        Log("[传送] 找到 PlayerController")

        -- 方法 1: UGameplayStatics::OpenLevel
        local GS = GetGameplayStatics()
        if GS and GS:IsValid() then
            local ok, err = pcall(function()
                GS:OpenLevel(PC, FName(mapPath), true, "")
            end)
            if ok then
                Log("[传送] OpenLevel 已调用: " .. mapPath)
                ScreenMsg("[传送] 正在传送到: " .. mapPath)
                return
            else
                Log("[传送] OpenLevel 失败: " .. tostring(err))
            end
        else
            Log("[传送] 无法访问 UGameplayStatics")
        end

        -- 方法 2: 控制台 open 命令
        local ok2, err2 = pcall(function()
            PC:ProcessConsoleExec("open " .. mapPath, nil, PC)
        end)
        if ok2 then
            Log("[传送] 控制台 open 已执行: " .. mapPath)
            return
        else
            Log("[传送] ProcessConsoleExec 失败: " .. tostring(err2))
        end

        -- 方法 3: ClientTravel
        local ok3, err3 = pcall(function()
            PC:ClientTravel(mapPath, 1, false)
        end)
        if ok3 then
            Log("[传送] ClientTravel 已调用: " .. mapPath)
            return
        else
            Log("[传送] ClientTravel 失败: " .. tostring(err3))
        end

        Log("[传送] 所有传送方法均失败")
    end)
end

-- ============ 命令处理 ============

local function PrintHelp()
    Log("========================================")
    Log(" 逸剑风云决 全地图传送 mod")
    Log(" tpm <关键词>    搜索并传送地图")
    Log(" tplist [关键词]  列出地图")
    Log(" tphelp          帮助")
    Log(" F6              直接传送到 Map65 (测试)")
    Log(" 例: tpm 神龙岛 | tpm Map65 | tplist 洛阳")
    Log("========================================")
end

local function ListMaps(list, title)
    Log("----------------------------------------")
    Log(title)
    for i, m in ipairs(list) do
        Log(string.format(" %d. %s", i, m.name))
    end
    Log(string.format("共 %d 项。输入 tpm <名称> 直接传送", #list))
    Log("----------------------------------------")
    -- 屏幕显示前几个（游戏画面可见）
    local screen = title .. "  " .. #list .. "项"
    for i = 1, math.min(5, #list) do
        screen = screen .. " | " .. i .. "." .. list[i].name
    end
    ScreenMsg(screen)
end

-- 提取关键词（兼容 0/1 索引）
local function ExtractKw(CommandParts)
    if not CommandParts then return nil end
    -- 打印调试信息
    local desc = ""
    for i, p in pairs(CommandParts) do
        desc = desc .. string.format("[%s]=%s ", tostring(i), tostring(p))
    end
    Log("[传送调试] CommandParts: " .. desc)
    -- 常见结构: [1]=命令名, [2]=参数
    for _, idx in ipairs({2, 1, 0}) do
        local v = CommandParts[idx]
        if v and tostring(v) ~= "tpm" and tostring(v) ~= "" then
            return tostring(v)
        end
    end
    return nil
end

local function HandleTpm(CommandParts)
    local kw = ExtractKw(CommandParts)
    if not kw then
        Log("[传送] 未提供关键词，用法: tpm <地图名>")
        PrintHelp()
        return
    end
    local matches = SearchMaps(kw)
    if #matches == 0 then
        Log("[传送] 未找到匹配「" .. kw .. "」的地图")
        return
    elseif #matches == 1 then
        Log("[传送] 匹配唯一: " .. matches[1].name .. " -> " .. matches[1].path)
        Teleport(matches[1].path)
        return
    else
        ListMaps(matches, string.format("[传送] 匹配「%s」%d 个，请细化：", kw, #matches))
    end
end

local function HandleTplist(CommandParts)
    local kw = ExtractKw(CommandParts)
    if not kw then
        ListMaps(Maps, "[传送] 全部地图列表")
        return
    end
    local matches = SearchMaps(kw)
    ListMaps(matches, string.format("[传送] 匹配「%s」的地图", kw))
end

-- ============ 注册命令 ============

RegisterConsoleCommandGlobalHandler("tpm", function(Cmd, CommandParts, Ar)
    Log("[传送调试] tpm 命令触发, Cmd=" .. tostring(Cmd))
    HandleTpm(CommandParts)
    return true
end)

RegisterConsoleCommandGlobalHandler("tplist", function(Cmd, CommandParts, Ar)
    Log("[传送调试] tplist 命令触发, Cmd=" .. tostring(Cmd))
    HandleTplist(CommandParts)
    return true
end)

RegisterConsoleCommandGlobalHandler("tphelp", function(Cmd, CommandParts, Ar)
    Log("[传送调试] tphelp 命令触发")
    PrintHelp()
    return true
end)

-- tpmaps: 运行时读取游戏 Maps 数据表，列出全部地图 ID
RegisterConsoleCommandGlobalHandler("tpmaps", function(Cmd, CommandParts, Ar)
    Log("[传送调试] tpmaps 命令触发，读取 Maps 表")
    ExecuteInGameThread(function()
        -- 诊断: 游戏已加载的 DataTable
        pcall(function()
            local dts = FindAllOf("DataTable")
            Log("[传送] 已加载 DataTable 数量: " .. tostring(dts and #dts or 0))
            if dts then
                for _, dt in pairs(dts) do
                    if dt:IsValid() then
                        Log("[传送] DataTable: " .. dt:GetFullName())
                    end
                end
            end
        end)

        -- Maps 表
        local dt = LoadAsset("/Game/JH/Tables/Maps.Maps")
        if not dt or not dt:IsValid() then
            Log("[传送] 无法加载 Maps 表")
            return
        end
        Log("[传送] Maps 表: " .. dt:GetFullName())

        -- 延迟后读（确保数据加载）
        ExecuteWithDelay(1000, function()
            -- 方法 1: GetRowNames + ForEach
            pcall(function()
                local names = dt:GetRowNames()
                Log("[传送] GetRowNames 返回: " .. tostring(names))
                if names then
                    Log("[传送] 类型: " .. tostring(names:type()))
                end
                if names and names:type() == "TArray" then
                    local cnt = 0
                    names:ForEach(function(idx, elem)
                        cnt = cnt + 1
                        local nm = ""
                        pcall(function() nm = tostring(elem:get():ToString()) end)
                        if cnt <= 30 then
                            Log(string.format("[传送] Row[%d]=%s", idx, nm))
                        end
                    end)
                    Log("[传送] ForEach 遍历到 " .. tostring(cnt) .. " 项")
                end
            end)

            -- 方法 2: 反射读 RowMap
            pcall(function()
                local rm = dt:GetPropertyValue("RowMap")
                Log("[传送] RowMap 值: " .. tostring(rm) .. " 类型: " .. tostring(rm and rm:type() or "nil"))
                if rm and rm:type() == "TArray" then
                    Log("[传送] RowMap 大小: " .. tostring(rm:GetArrayNum()))
                end
            end)
        end)
    end)
    return true
end)

-- ============ 快捷键 ============

-- F6: 直接传送到神龙岛主场景（测试）
if not IsKeyBindRegistered(Key.F6) then
    RegisterKeyBind(Key.F6, function()
        Log("[传送] F6 按下，传送到神龙岛")
        Teleport("/Game/JH/Maps/JiangNan/Map65_ShenLouDao/LV_ShenLouDao_S")
    end)
end

Log("[传送] 传送 mod 加载完成！控制台输入 tphelp 查看帮助")
