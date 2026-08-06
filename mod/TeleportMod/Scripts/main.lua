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

local ok_maps, Maps = pcall(require, "maps_pinyin")
if not ok_maps or type(Maps) ~= "table" then
    Log("[传送] 警告：maps_pinyin.lua 加载失败")
    Maps = {}
end
Log(string.format("[传送] 已加载 %d 个地图（ID→地名→拼音）", #Maps))

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

-- ============ 自动注册直接传送命令 ============
-- 输入地名/拼音/唯一缩写即可直接传送，无需 tpm 前缀

-- 归并同名（同一地名的多个入口，取第一个 ID）
local byName = {}
local order = {}
for _, m in ipairs(Maps) do
    if m.name and not byName[m.name] then
        byName[m.name] = m
        table.insert(order, m.name)
    end
end

-- 检查首字母缩写冲突（不同地名同缩写）
local abbrCount = {}
for _, m in pairs(byName) do
    if m.abbr then
        abbrCount[m.abbr] = (abbrCount[m.abbr] or 0) + 1
    end
end

local registered = {}
local regCount = 0
local function RegCmd(cmdname, m)
    if cmdname and cmdname ~= "" and not registered[cmdname] then
        local ok = pcall(function()
            RegisterConsoleCommandGlobalHandler(cmdname, function()
                Log(string.format("[传送] 「%s」-> 传送到 %s (tomap %d)", cmdname, m.name, m.id))
                CallTomap(m.id)
            end)
        end)
        if ok then
            registered[cmdname] = true
            regCount = regCount + 1
        end
    end
end

for _, name in ipairs(order) do
    local m = byName[name]
    RegCmd(m.name, m)      -- 中文名
    RegCmd(m.pinyin, m)    -- 拼音全拼
    if abbrCount[m.abbr] == 1 then  -- 唯一缩写
        RegCmd(m.abbr, m)
    end
end

Log(string.format("[传送] 已注册 %d 个直接传送命令（输入地名/拼音/唯一缩写即可传送）", regCount))

-- ============ F1 GM 命令拦截（hook exec 通道） ============

local function SearchMapsAll(kw)
    local k = string.lower(kw or "")
    local out = {}
    for _, m in ipairs(Maps) do
        local n = string.lower(m.name or "")
        local p = string.lower(m.pinyin or "")
        local a = string.lower(m.abbr or "")
        if string.find(n, k, 1, true) or string.find(p, k, 1, true) or string.find(a, k, 1, true) then
            table.insert(out, m)
        end
    end
    return out
end

-- 尝试处理地图命令：输入匹配唯一地图则传送
local function TryHandleMapCmd(cmd)
    if not cmd then return false end
    local kw = tostring(cmd):gsub("^%s+", ""):gsub("%s+$", "")
    if kw == "" then return false end
    -- 忽略游戏自身命令（含空格参数的一般是游戏命令）
    if string.find(kw, " ") then return false end
    local matches = SearchMapsAll(kw)
    if #matches == 1 then
        Log("[传送] 拦截「" .. kw .. "」-> 传送到 " .. matches[1].name .. " (ID " .. tostring(matches[1].id) .. ")")
        CallTomap(matches[1].id)
        return true
    end
    return false
end

-- 1) ULocalPlayer::Exec hook
RegisterULocalPlayerExecPreHook(function(Context, InWorld, Cmd, Ar)
    if TryHandleMapCmd(Cmd) then
        Log("[传送] 通过 ULocalPlayer::Exec 拦截")
        return true, false  -- 处理完成，阻止原始执行
    end
end)

-- 2) ProcessConsoleExec hook
RegisterProcessConsoleExecPreHook(function(Context, Cmd, CommandParts, Ar, Executor)
    if TryHandleMapCmd(Cmd) then
        Log("[传送] 通过 ProcessConsoleExec 拦截")
        return true
    end
end)

-- 3) CallFunctionByNameWithArguments hook
RegisterCallFunctionByNameWithArgumentsPreHook(function(Context, Str, Ar, Executor, bForce)
    if TryHandleMapCmd(Str) then
        Log("[传送] 通过 CallFunctionByName 拦截")
        return true
    end
end)

Log("[传送] 已安装 F1 命令拦截钩子（输入地图名/拼音直接传送）")

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

        -- 3. dump 关键函数参数签名（ChangeSceneMapDDD / OpenCourierStation / OpenWorldMap）
        Log("[诊断] === 关键函数参数 dump ===")
        pcall(function()
            local JH = StaticFindObject("/Script/JH.Default__JHNeoUISubsystem")
            if JH and JH:IsValid() then
                local cls = JH:GetClass()
                local targets = { "ChangeSceneMapDDD", "OpenCourierStation", "OpenWorldMap", "OpenCourierStationByNPC", "BPSimpleAlert" }
                for _, tname in ipairs(targets) do
                    cls:ForEachFunction(function(fn)
                        local fname = fn:GetFName():ToString()
                        if fname == tname then
                            Log("[诊断] === 函数: " .. fname .. " ===")
                            fn:ForEachProperty(function(prop)
                                Log(string.format("[诊断]   参数/属性: %s (%s)", prop:GetFName():ToString(), prop:GetClass():GetFName():ToString()))
                            end)
                        end
                    end)
                end
            end
        end)
        Log("[诊断] === 参数 dump 结束 ===")
    end)
    return true
end)

-- ============ 驿站表读写测试 ============

RegisterConsoleCommandGlobalHandler("tpcourier", function(Cmd, CommandParts, Ar)
    Log("[驿站] === 读取驿站表 ===")
    ExecuteInGameThread(function()
        local dt = LoadAsset("/Game/JH/Tables/CourierStation.CourierStation")
        if not dt or not dt:IsValid() then
            Log("[驿站] 加载失败")
            return
        end
        Log("[驿站] 表: " .. dt:GetFullName())

        -- RowStruct（行结构字段）
        pcall(function()
            local rs = dt:GetPropertyValue("RowStruct")
            Log("[驿站] RowStruct: " .. tostring(rs))
            if rs and rs:IsValid() then
                local cnt = 0
                rs:ForEachProperty(function(prop)
                    cnt = cnt + 1
                    Log(string.format("[驿站]   字段: %s (%s)", prop:GetFName():ToString(), prop:GetClass():GetFName():ToString()))
                end)
                Log("[驿站] RowStruct 字段数: " .. tostring(cnt))
            end
        end)

        -- GetRowNames
        pcall(function()
            local names = dt:GetRowNames()
            Log("[驿站] GetRowNames 类型: " .. tostring(names and names:type() or "nil"))
            if names then
                local cnt = 0
                names:ForEach(function(idx, elem)
                    cnt = cnt + 1
                    local nm = ""
                    pcall(function() nm = tostring(elem:get():ToString()) end)
                    Log(string.format("[驿站] Row[%d] = %s", idx, nm))
                end)
                Log("[驿站] 遍历到 " .. tostring(cnt) .. " 行")
            end
        end)
        Log("[驿站] === 读取结束 ===")
    end)
    return true
end)

-- ============ 快捷键 ============

-- 打开游戏驿站面板（文字列表传送）的函数
local function OpenCourierPanel()
    Log("[传送] 打开驿站面板")
    ExecuteInGameThread(function()
        pcall(function()
            local JH = StaticFindObject("/Script/JH.Default__JHNeoUISubsystem")
            if JH and JH:IsValid() then
                JH:OpenCourierStation(0)
                Log("[传送] 已调用 OpenCourierStation(0)")
            else
                Log("[传送] JHNeoUISubsystem 未找到")
            end
        end)
    end)
end

-- F2: 打开驿站面板（测试文字列表 UI）
if not IsKeyBindRegistered(Key.F2) then
    RegisterKeyBind(Key.F2, function()
        Log("[传送] F2 按下")
        OpenCourierPanel()
    end)
end

-- F8: 传送到姑苏城 (ID 27)
if not IsKeyBindRegistered(Key.F8) then
    RegisterKeyBind(Key.F8, function()
        Log("[传送] F8 按下，传送到姑苏城")
        CallTomap(27)
    end)
end

Log("[传送] 传送 mod 加载完成！F2=驿站面板 / tpinfo=诊断 / tpm 姑苏城=传送")
