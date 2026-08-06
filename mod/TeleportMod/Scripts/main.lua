--[[
    逸剑风云决 · 全地图传送 mod (TeleportMod)
    基于 UE4SS 实验版 + UE4.26

    原理：游戏自带 GM 命令 tomap <地图ID> 是官方传送功能。
    本 mod 把 Maps 表解析出的 地图ID→中文地名 集成进来，
    让你用中文地名搜索，自动调用 tomap 传送。

    用法（按 `~` 或 F10 打开 UE 控制台）：
      tpm <地名关键词>    搜索地图并传送（如: tpm 姑苏城 / tpm 天剑宗）
      tplist [关键词]     列出全部/匹配的地图
      tphelp              帮助
    快捷键：
      F8                  传送到姑苏城（测试）
]]

-- ============ 工具函数 ============

local function Log(msg)
    print(msg .. "\n")
end

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

local function ScreenMsg(msg)
    local PC = FindPlayerController()
    if PC and PC:IsValid() then
        pcall(function()
            PC:ClientMessage(msg, FName("None"), 5.0)
        end)
    end
end

-- ============ 地图数据（ID → 地名） ============

local ok_maps, Maps = pcall(require, "maps_names")
if not ok_maps or type(Maps) ~= "table" then
    Log("[传送] 警告：maps_names.lua 加载失败")
    Maps = {}
end
Log(string.format("[传送] 已加载 %d 个地图（ID→地名）", #Maps))

-- ============ 调用游戏 tomap 命令 ============

local function CallTomap(mapId)
    Log(string.format("[传送] 调用 tomap %d", mapId))
    ExecuteInGameThread(function()
        local PC = FindPlayerController()
        if not PC or not PC:IsValid() then
            Log("[传送] 错误：找不到 PlayerController")
            return
        end
        -- 方式1: ProcessConsoleExec 执行 tomap
        local ok = pcall(function()
            PC:ProcessConsoleExec("tomap " .. tostring(mapId), nil, PC)
        end)
        if ok then
            Log("[传送] tomap 命令已发送: " .. tostring(mapId))
        else
            Log("[传送] ProcessConsoleExec 调用失败")
            -- 方式2: JHNeoUISubsystem 命令分发
            pcall(function()
                local JH = StaticFindObject("/Script/JH.Default__JHNeoUISubsystem")
                if JH and JH:IsValid() then
                    JH:ProcessConsoleExec("tomap " .. tostring(mapId), nil, PC)
                end
            end)
        end
    end)
end

-- ============ 搜索 ============

local function SearchMaps(kw)
    local k = string.lower(kw or "")
    local out = {}
    for _, m in ipairs(Maps) do
        if string.find(string.lower(m.name), k, 1, true) then
            table.insert(out, m)
        end
    end
    return out
end

-- ============ 命令处理 ============

local function PrintHelp()
    Log("========================================")
    Log(" 逸剑风云决 全地图传送 mod")
    Log(" 原理：调用游戏官方 tomap <ID> 命令")
    Log(" tpm <地名>     搜索并传送（如 tpm 姑苏城）")
    Log(" tplist [关键词] 列出地图")
    Log(" tphelp         帮助")
    Log(" F8             传送到姑苏城(测试)")
    Log("========================================")
end

local function ListMaps(list, title)
    Log("----------------------------------------")
    Log(title)
    for i, m in ipairs(list) do
        Log(string.format(" %d. [%s] %s", i, tostring(m.id), m.name))
    end
    Log(string.format("共 %d 项。输入 tpm <名称> 传送", #list))
    Log("----------------------------------------")
end

local function HandleTpm(CommandParts)
    local kw = CommandParts and (CommandParts[2] or CommandParts[1])
    if not kw or kw == "" or kw == "tpm" then
        Log("[传送] 用法: tpm <地名>  （如 tpm 姑苏城）")
        return
    end
    local matches = SearchMaps(tostring(kw))
    if #matches == 0 then
        Log("[传送] 未找到匹配「" .. kw .. "」的地图")
        ScreenMsg("[传送] 未找到地图: " .. kw)
        return
    elseif #matches == 1 then
        Log(string.format("[传送] 匹配: [%d] %s", matches[1].id, matches[1].name))
        CallTomap(matches[1].id)
        return
    else
        ListMaps(matches, string.format("[传送] 匹配「%s」%d 个，请细化：", kw, #matches))
    end
end

local function HandleTplist(CommandParts)
    local kw = CommandParts and (CommandParts[2] or CommandParts[1])
    if not kw or kw == "" or kw == "tplist" then
        ListMaps(Maps, "[传送] 全部地图列表")
        return
    end
    local matches = SearchMaps(tostring(kw))
    ListMaps(matches, string.format("[传送] 匹配「%s」的地图", kw))
end

-- ============ 注册命令 ============

RegisterConsoleCommandGlobalHandler("tpm", function(Cmd, CommandParts, Ar)
    Log("[传送调试] tpm 触发: " .. tostring(Cmd))
    HandleTpm(CommandParts)
    return true
end)

RegisterConsoleCommandGlobalHandler("tplist", function(Cmd, CommandParts, Ar)
    HandleTplist(CommandParts)
    return true
end)

RegisterConsoleCommandGlobalHandler("tphelp", function(Cmd, CommandParts, Ar)
    PrintHelp()
    return true
end)

-- ============ 诊断命令 ============

-- tpinfo: dump JHNeoUISubsystem 方法 + 测试 tomap 调用
RegisterConsoleCommandGlobalHandler("tpinfo", function(Cmd, CommandParts, Ar)
    Log("[诊断] tpinfo 开始")
    ExecuteInGameThread(function()
        -- 1. dump JHNeoUISubsystem 的所有 UFunction
        pcall(function()
            local JH = StaticFindObject("/Script/JH.Default__JHNeoUISubsystem")
            if JH and JH:IsValid() then
                local cls = JH:GetClass()
                Log("[诊断] JHNeoUISubsystem 类: " .. tostring(cls and cls:GetFName():ToString() or "?"))
                local cnt = 0
                if cls then
                    cls:ForEachFunction(function(fn)
                        cnt = cnt + 1
                        Log(string.format("[诊断]   [FN] %s", fn:GetFName():ToString()))
                    end)
                end
                Log("[诊断] JHNeoUISubsystem 函数数: " .. tostring(cnt))
            else
                Log("[诊断] JHNeoUISubsystem 未找到")
            end
        end)

        -- 2. 测试 tomap 调用（ProcessConsoleExec）
        pcall(function()
            local PC = FindPlayerController()
            if PC and PC:IsValid() then
                Log("[诊断] 发送 tomap 27 (姑苏城)...")
                PC:ProcessConsoleExec("tomap 27", nil, PC)
                Log("[诊断] tomap 27 已发送")
            else
                Log("[诊断] 无 PlayerController")
            end
        end)
    end)
    return true
end)

-- ============ 快捷键 ============

-- F8: 传送到姑苏城 (ID 27)
if not IsKeyBindRegistered(Key.F8) then
    RegisterKeyBind(Key.F8, function()
        Log("[传送] F8 按下，传送到姑苏城")
        CallTomap(27)
    end)
end

Log("[传送] 传送 mod 加载完成！控制台输入 tpinfo 诊断 / tpm 姑苏城 传送")
