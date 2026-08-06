--[[
    逸剑风云决 · 传送 mod (TeleportMod) 最终版
    基于 UE4SS 实验版 + UE4.26

    功能：
      F1        黑色控制台输入拼音传送（完整拼音 / 前两字前缀，大小写不敏感）
      F2        打开游戏驿站界面
      tpm       搜索地名命令
]]

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
        local ok, err = pcall(function()
            local PC = FindPlayerController()
            if not PC then
                Log("[传送] 无 PlayerController")
                return
            end
            -- 优先用场景中的 AsyncTaskChangeSceneMap 实例（游戏 tomap 用同一对象）
            local task = FindFirstOf("AsyncTaskChangeSceneMap")
            local src = "场景实例"
            if not task or not task:IsValid() then
                -- 切图后场景实例常被销毁，改用类创建新实例（模拟游戏 tomap 逻辑）
                local cls = StaticFindObject("/Script/JH.AsyncTaskChangeSceneMap")
                if cls then
                    local okCreate = pcall(function()
                        task = StaticConstructObject(cls, PC)
                    end)
                    if okCreate then src = "新建实例" end
                end
            end
            if not task or not task:IsValid() then
                Log("[传送] 实例不可用（场景无实例 + 创建失败），传送中止")
                return
            end
            -- 完整参数：WorldContext, MapId, TargetLocation, TargetFaceDirect, 传送动画开启
            Log("[传送] 实例来源: " .. src .. "，ChangeSceneMapWithId(" .. tostring(mapId) .. ")")
            task:ChangeSceneMapWithId(PC, mapId, nil, 0, true, true, true, true)
            Log("[传送] 调用完成: " .. tostring(mapId))
        end)
        if not ok then
            Log("[传送] 传送错误: " .. tostring(err))
        end
    end)
end

-- ============ F2 打开游戏驿站界面 ============

if not IsKeyBindRegistered(Key.F2) then
    RegisterKeyBind(Key.F2, function()
        Log("[面板] F2 按下：打开驿站界面")
        ExecuteInGameThread(function()
            pcall(function()
                local JH = StaticFindObject("/Script/JH.Default__JHNeoUISubsystem")
                if JH and JH:IsValid() then
                    JH:OpenCourierStation(0)
                    Log("[面板] OpenCourierStation 已调用")
                else
                    Log("[面板] JHNeoUISubsystem 未找到")
                end
            end)
        end)
    end)
end

-- ============ F8 呼出游戏 GM 命令界面（好感度等 GM 命令专用） ============

if not IsKeyBindRegistered(Key.F8) then
    RegisterKeyBind(Key.F8, function()
        Log("[传送] F8 按下：呼出 GM 命令界面")
        ExecuteInGameThread(function()
            pcall(function()
                local subs = FindAllOf("JHNeoUISubsystem")
                Log("[传送] JHNeoUISubsystem 实例数: " .. tostring(#(subs or {})))
                local tried = 0
                for _, s in ipairs(subs or {}) do
                    pcall(function()
                        Log("[传送] 调用实例: " .. tostring(s:GetFullName()))
                        s:ShowGMCommandLine()
                        tried = tried + 1
                    end)
                end
                if tried == 0 then
                    Log("[传送] 未找到 JHNeoUISubsystem 实例，尝试 Default 对象")
                    local JH = StaticFindObject("/Script/JH.Default__JHNeoUISubsystem")
                    if JH and JH:IsValid() then
                        JH:ShowGMCommandLine()
                        Log("[传送] Default ShowGMCommandLine 已调用")
                    end
                end
            end)
        end)
    end)
end

-- ============ 全地图命令（中文名/全拼/首字母缩写） ============

-- 加载全部地图拼音数据（258 个地图，注册中文名/全拼/缩写命令 + tpm 搜索）
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

Log("[传送] TeleportMod 就绪：F1 控制台输入拼音传送 / F2 驿站界面 / tpm 搜索")

-- ============ 拼音命令（完整拼音 + 前两字前缀，大小写不敏感） ============

local ok_cmd, MapCmds = pcall(require, "maps_cmd")
if not ok_cmd or type(MapCmds) ~= "table" then MapCmds = {} end
local function CountMapCmds()
    local n = 0
    for _ in pairs(MapCmds) do n = n + 1 end
    return n
end
Log("[传送] 已加载 " .. tostring(CountMapCmds()) .. " 个拼音命令键")

-- 为 maps_cmd 每个唯一键注册命令：小写 + 大写变体
-- （RegisterConsoleCommandGlobalHandler 大小写敏感，双注册覆盖；RegCmd 内部去重）
local mapCmdCount = 0
for cmdname, m in pairs(MapCmds) do
    if type(m) == "table" and m.id then
        RegCmd(cmdname, m)               -- 小写：wutong / wutongcun
        RegCmd(string.upper(cmdname), m) -- 大写：WUTONG / WUTONGCUN
        mapCmdCount = mapCmdCount + 1
    end
end
Log("[传送] maps_cmd 命令键 " .. tostring(mapCmdCount) .. " 个（含大小写变体）")

--（已移除 RegisterULocalPlayerExecPreHook：实测黑色控制台不走 ULocalPlayer::Exec）

-- ============ 调试：探测好感度数据结构（tpfav 轻量版，只读属性名） ============
local function DumpAllProps(tag, obj)
    if not obj or not obj:IsValid() then
        Log("[fav] " .. tag .. " 无效"); return
    end
    Log("[fav] === " .. tag .. ": " .. tostring(obj:GetFullName()) .. " ===")
    local n = 0
    obj:ForEachProperty(function(p)
        pcall(function()
            n = n + 1
            if n > 300 then return true end
            Log("[fav]   " .. tostring(p:GetFName():ToString()))
        end)
    end)
    Log("[fav] --- " .. tag .. " 属性数(前300): " .. tostring(n))
end

RegisterConsoleCommandGlobalHandler("tpfav", function(Cmd, CommandParts, Ar)
    ExecuteInGameThread(function()
        pcall(function()
            Log("[fav] ===== 探测开始 =====")
            -- PlayerController / Pawn / Character 属性
            local PCs = FindAllOf("PlayerController")
            Log("[fav] PlayerController 数量: " .. tostring(#(PCs or {})))
            for i, pc in ipairs(PCs or {}) do
                Log("[fav] PC[" .. i .. "]: " .. tostring(pc:GetFullName()))
                DumpAllProps("PC" .. i, pc)
            end
            local pwns = FindAllOf("Pawn")
            Log("[fav] Pawn 数量: " .. tostring(#(pwns or {})))
            for _, pw in ipairs(pwns or {}) do
                pcall(function()
                    Log("[fav] Pawn: " .. tostring(pw:GetFullName()))
                    DumpAllProps("Pawn", pw)
                end)
            end
            -- 司马铃角色
            local chars = FindAllOf("Character")
            Log("[fav] Character 数量: " .. tostring(#(chars or {})))
            for _, c in ipairs(chars or {}) do
                pcall(function()
                    local full = tostring(c:GetFullName())
                    if string.find(string.lower(full), "simaling") then
                        Log("[fav] 找到司马铃: " .. full)
                        DumpAllProps("司马铃", c)
                    end
                end)
            end
            Log("[fav] ===== 探测完成 =====")
        end)
    end)
    return true
end)
