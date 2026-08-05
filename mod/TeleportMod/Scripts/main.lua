--[[
    逸剑风云决 · 全地图传送 mod (TeleportMod)
    基于 UE4SS 3.x + UE4.26

    用法（游戏内按 `~` 打开控制台）：
      tpm <关键词>       搜索地图并传送（唯一匹配直接传，多匹配列出）
      tplist [关键词]    列出全部/匹配的地图
      tphelp             显示帮助
    快捷键：
      F6                 屏幕提示帮助（无控制台时）

    传送实现：UGameplayStatics::OpenLevel，跨地图加载。
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

-- 获取 UGameplayStatics 默认对象（静态类方法容器）
local function GetGameplayStatics()
    return StaticFindObject("/Script/Engine.Default__GameplayStatics")
end

-- 尝试在游戏屏幕显示消息（若游戏启用了 HUD 消息则可见）
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
    Log("[传送] 警告：maps.lua 加载失败，请检查 Mods/TeleportMod/Scripts/maps.lua")
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

-- ============ 传送 ============

local function Teleport(mapPath)
    Log("[传送] 开始传送: " .. mapPath)
    ExecuteInGameThread(function()
        local PC = FindPlayerController()
        if not PC or not PC:IsValid() then
            Log("[传送] 错误：找不到 PlayerController")
            return
        end
        local GS = GetGameplayStatics()
        if not GS or not GS:IsValid() then
            Log("[传送] 错误：无法访问 UGameplayStatics")
            return
        end
        local ok, err = pcall(function()
            GS:OpenLevel(PC, FName(mapPath), true, "")
        end)
        if ok then
            Log("[传送] 正在传送到: " .. mapPath)
            ScreenMsg("[传送] 正在传送到: " .. mapPath)
        else
            Log("[传送] 调用 OpenLevel 失败: " .. tostring(err))
        end
    end)
end

-- ============ 命令处理 ============

local function PrintHelp()
    Log("========================================")
    Log(" 逸剑风云决 全地图传送 mod")
    Log(" tpm <关键词>    搜索并传送地图")
    Log(" tplist [关键词]  列出地图")
    Log(" tphelp          帮助")
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
end

-- 处理 tpm 命令
local function HandleTpm(CommandParts)
    local kw = CommandParts and CommandParts[2]
    if not kw or kw == "" then
        PrintHelp()
        return
    end
    local matches = SearchMaps(kw)
    if #matches == 0 then
        Log("[传送] 未找到匹配「" .. kw .. "」的地图")
        return
    elseif #matches == 1 then
        Teleport(matches[1].path)
        return
    else
        ListMaps(matches, string.format("[传送] 匹配「%s」%d 个，请细化关键词：", kw, #matches))
    end
end

-- 处理 tplist 命令
local function HandleTplist(CommandParts)
    local kw = CommandParts and CommandParts[2]
    if not kw or kw == "" then
        ListMaps(Maps, "[传送] 全部地图列表")
        return
    end
    local matches = SearchMaps(kw)
    ListMaps(matches, string.format("[传送] 匹配「%s」的地图", kw))
end

-- ============ 注册命令 ============

RegisterConsoleCommandGlobalHandler("tpm", function(Cmd, CommandParts, Ar)
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

-- ============ 快捷键 ============

if not IsKeyBindRegistered(Key.F6) then
    RegisterKeyBind(Key.F6, function()
        PrintHelp()
        ScreenMsg("传送 mod 已就绪：控制台输入 tpm <地图名> 传送")
    end)
end

Log("[传送] 传送 mod 加载完成！控制台输入 tphelp 查看帮助")
