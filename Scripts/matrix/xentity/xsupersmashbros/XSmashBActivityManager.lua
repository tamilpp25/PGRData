--===========================
--超限乱斗活动管理器
--模块负责：吕天元
--===========================
---@
local XSmashBActivityManager = {}
local Config
--总已获取的能量
local CurrentEnergy
--用过的能量
local UsedEnergy
--剩余可获得的能量
local LeftEnergy
-- 队伍等级
local TeamLevel
-- 队伍升级持有道具
local TeamItem = 0
-- 队伍等级数据
local TeamLevelConfig
-- 每日奖励是否领取
local IsReceiveDailyReward = false
--===============
--设置活动配置
--===============
function XSmashBActivityManager.SetConfig(config)
    Config = config
    CurrentEnergy = 0
    UsedEnergy = 0
    LeftEnergy = 0
    TeamLevelConfig = XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.TeamLevel)
end
--===============
--获取给定配置的活动Id(XSuperSmashBrosActivity的Id)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetActivityId()
    return Config and Config.Id or 0
end
--===============
--获取给定配置的活动OpenTimeId(XSuperSmashBrosActivity的OpenTimeId)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetOpenTimeId()
    return Config and Config.OpenTimeId or 0
end
--===============
--获取当前配置的活动名称(XSuperSmashBrosActivity的Name)
--若配置为空，则返回字符串"UnNamed"
--===============
function XSmashBActivityManager.GetName()
    return Config and Config.Name or "UnNamed"
end
--===============
--获取当前配置的活动积分道具Id(XSuperSmashBrosActivity的PointItemId)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetPointItemId()
    return Config and Config.PointItemId or 0
end
--===============
--获取当前配置的活动能量道具Id(XSuperSmashBrosActivity的PointItemId)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetEnergyItemId()
    return Config and Config.EnergyItemId or 0
end
--===============
--获取当前配置的队伍等级道具Id
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetLevelItem()
    return Config and Config.LevelItem or 0
end
function XSmashBActivityManager.GetLevelItemIcon()
    local id = XSmashBActivityManager.GetLevelItem()
    return XDataCenter.ItemManager.GetItemIcon(id)
end
--===============
--获取当前配置的活动能量道具图标
--===============
function XSmashBActivityManager.GetEnergyItemIcon()
    local id = XSmashBActivityManager.GetEnergyItemId()
    return XDataCenter.ItemManager.GetItemIcon(id)
end
--===============
--获取当前配置的每日恢复能量数量(XSuperSmashBrosActivity的EnergyGainByDay)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetEnergyGainByDay()
    return Config and Config.EnergyGainByDay or 0
end
--===============
--获取当前配置的能量上限(XSuperSmashBrosActivity的MaxEnergy)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetMaxEnergy()
    return Config and Config.MaxEnergy or 0
end
--===============
--获取当前配置的核心起始星级(XSuperSmashBrosActivity的CoreStartLevel)
--若配置为空，则返回1
--===============
function XSmashBActivityManager.GetCoreStartLevel()
    return Config and Config.CoreStartLevel or 1
end
--===============
--获取当前配置的增幅核心所需能量(XSuperSmashBrosActivity的EnergyCostOnUpgrade)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetEnergyCostOnUpgrade()
    return Config and Config.EnergyCostOnUpgrade or 0
end
--===============
--获取当前配置的核心攻击每级提升数值(XSuperSmashBrosActivity的AtkUpNumByLevel)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetAtkUpNumByLevel()
    return Config and Config.AtkUpNumByLevel or 0
end
--===============
--获取当前配置的核心攻击每级提升战力(XSuperSmashBrosActivity的AtkUpAbilityByLevel)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetAtkUpAbilityByLevel()
    return Config and Config.AtkUpAbilityByLevel or 0
end
--===============
--获取当前配置的核心生命每级提升数值(XSuperSmashBrosActivity的LifeUpNumByLevel)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetLifeUpNumByLevel()
    return Config and Config.LifeUpNumByLevel or 0
end
--===============
--获取当前配置的核心生命每级提升数值(XSuperSmashBrosActivity的LifeUpAbilityByLevel)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetLifeUpAbilityByLevel()
    return Config and Config.LifeUpAbilityByLevel or 0
end
--===============
--获取当前配置的入口配图(XSuperSmashBrosActivity的EntryImage)
--若配置为空，则返回0
--===============
function XSmashBActivityManager.GetEntryImage()
    return Config and Config.EntryImage or ""
end
--===============
--获取排位特殊图标(XSuperSmashBrosActivity的RankingIcons)
--若配置为空，则返回空Table
--===============
function XSmashBActivityManager.GetRankingIcons()
    return Config and Config.RankingIcons or {}
end
--===============
--获取已获得的能量总数(后端数据)
--===============
function XSmashBActivityManager.GetCurrentEnergy()
    return CurrentEnergy or 0
end
--===============
--获取剩余可获得的能量总数(后端数据)
--===============
function XSmashBActivityManager.GetLeftEnergy()
    return LeftEnergy or 0
end
--===============
--获取已用过的能量总数(后端数据)
--===============
function XSmashBActivityManager.GetUsedEnergy()
    return UsedEnergy or 0
end
--===============
--获取未使用的能量总数
--===============
function XSmashBActivityManager.GetNotUsedEnergy()
    return XSmashBActivityManager.GetCurrentEnergy() - XSmashBActivityManager.GetUsedEnergy()
end
--===============
--设置已获得的能量总数(后端数据)
--===============
function XSmashBActivityManager.SetTotalEnergy(value)
    CurrentEnergy = value
end
--===============
--设置剩余可获得的能量总数(后端数据)
--===============
function XSmashBActivityManager.SetLeftEnergy(value)
    LeftEnergy = value
end
--===============
--设置已用过的能量总数(后端数据)
--===============
function XSmashBActivityManager.SetUsedEnergy(value)
    UsedEnergy = value
end
--===============
--获取当前队伍等级
--===============
function XSmashBActivityManager.GetTeamLevel()
    return TeamLevel or 1
end
--===============
--获取当前队伍升级道具数量
--===============
function XSmashBActivityManager.GetTeamItem()
    return TeamItem or 0
end
--===============
--获取当前队伍等级数据
--===============
function XSmashBActivityManager.GetNowTeamLevelConfig()
    local lv = XSmashBActivityManager.GetTeamLevel()
    return TeamLevelConfig[lv]
end
--===============
--获取当前队伍等级是否已经是最大
--===============
function XSmashBActivityManager.GetIsTeamLvMax()
    local teamLevelConfig = XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.TeamLevel)
    if TeamLevel == #teamLevelConfig then
        return true
    end

    return false
end
--=================================入口，跳转相关=============================
--===================
--获取活动配置简表
--===================
function XSmashBActivityManager.GetActivityChapters()
    --只有活动开启期间显示入口
    local isEnd = XDataCenter.SuperSmashBrosManager.CheckIsEnd()
    if isEnd then return {} end
    local chapters = {}
    local tempChapter = {}
    tempChapter.Type = XDataCenter.FubenManager.ChapterType.SuperSmashBros
    tempChapter.Id = XSmashBActivityManager.GetActivityId()
    table.insert(chapters, tempChapter)
    return chapters
end
--================
--跳转到活动主界面
--================
function XSmashBActivityManager.JumpTo()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SuperSmashBros) then
        local canGoTo, notStart = XDataCenter.SuperSmashBrosManager.CheckCanGoTo()
        if canGoTo then
            XLuaUiManager.Open("UiSuperSmashBrosMain")
        elseif notStart then
            XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityNotStart"))
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
        end
    end
end
--================
--玩法关闭时弹出主界面
--================
function XSmashBActivityManager.OnActivityEndHandler()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
end
--================
--刷新后台推送活动数据
--================
function XSmashBActivityManager.RefreshNotifyActivityData(data)
    -- cxldV2 超限乱斗2期屏蔽能量数据
    -- XSmashBActivityManager.RefreshNotifyEnergyData(data.EnergyDb)
    XSmashBActivityManager.RefreshNotifyTeamLevelData(data)
    XSmashBActivityManager.RefreshNotifyDailyReward(data)
end
--================
--刷新能量数据
--================
function XSmashBActivityManager.RefreshNotifyEnergyData(energyDb)
    -- XSmashBActivityManager.SetTotalEnergy(energyDb.MaxValue or 0)
    -- XSmashBActivityManager.SetUsedEnergy((energyDb.MaxValue or 0) - (energyDb.CurValue or 0))
    -- XSmashBActivityManager.SetLeftEnergy((energyDb.DailyMaxValue or 0) - (energyDb.DailyAddValue or 0))
    --XLog.Debug("EnergyDb : ", energyDb)
end
--================
--刷新队伍等级数据
--================
function XSmashBActivityManager.RefreshNotifyTeamLevelData(data)
    TeamLevel = data.TeamLevel
    TeamItem = data.TeamItem
end
--================
--每日奖励
--================
function XSmashBActivityManager.RefreshNotifyDailyReward(data)
    IsReceiveDailyReward = data.GotDailyReward
end
--================
--每日奖励是否领取
--================
function XSmashBActivityManager.IsReceiveDailyReward()
    return IsReceiveDailyReward
end
--================
--每日奖励领取
--================
function XSmashBActivityManager.ReceiveDailyReward(cb)
    XNetwork.Call("SuperSmashBrosGetDailyRewardRequest", {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local teamLevel = res.TeamLevel
        if teamLevel then
            TeamLevel = teamLevel
        end
        
        IsReceiveDailyReward = true
        if cb then
            cb()
        end
        local rewardGoodList = res.RewardList
        if not rewardGoodList then
            rewardGoodList = {
                {
                    TemplateId = XSuperSmashBrosConfig.GetDailyRewardItemId(),
                    Type = XRewardManager.XRewardType.Item,
                    Count = XSuperSmashBrosConfig.GetDailyRewardItemCount(),
                }
            }
        end
        XUiManager.OpenUiObtain(rewardGoodList)
    end)
end

return XSmashBActivityManager