--===========================
--超级爬塔 关卡 管理器
--模块负责：吕天元
--===========================
local XSuperTowerStageManager = XClass(nil, "XSuperTowerStageManager")

function XSuperTowerStageManager:Ctor(rootManager)
    self.ActivityManager = rootManager
    self:Init()
end
--=================
--初始化
--=================
function XSuperTowerStageManager:Init()
    self:InitThemes()
    -- self:InitRpc()
end
--=================
--初始化主题
--=================
function XSuperTowerStageManager:InitThemes()
    self.MaxStageCount = 0
    self.Themes = {}
    self.ThemesOrderByIndex ={}
    local themeIds = self.ActivityManager.GetThemeIds()
    local themeScript = require("XEntity/XSuperTower/Stages/XSuperTowerTheme")
    for index, id in pairs(themeIds) do
        local theme = themeScript.New(self, id, index)
        self.ThemesOrderByIndex[index] = theme --以排序做的字典
        self.Themes[id] = theme --以主题Id做的字典
        if theme:GetMaxStageCount() > self.MaxStageCount then
            self.MaxStageCount = theme:GetMaxStageCount()
        end
    end
end

-- function XSuperTowerStageManager:InitRpc()
--     XRpc.NotifyStMapTierData = function(data)
--         self:RefreshStMapTierData(data)
--     end
--     XRpc.NotifyStMapTargetData = function(data)
--         self:RefreshStMapTargetData(data)
--     end
--     XRpc.NotifyTargetStageFightResult = function(data)
--         self:SetTempProgress(data)
--     end
-- end
--// 更新爬塔数据
--    // 地图id
--    public int Id;
--    // 改变类型，1更新，2结束重置
--    public int ChangeType;
--    // 爬塔数据
--    public StTierInfo TierInfo;
--}
function XSuperTowerStageManager:RefreshStMapTierData(data)
    --XLog.Debug("================更新爬塔关卡数据:Data:", data)
    if not data then return end
    local theme = self.Themes[data.Id]
    if theme then
        theme:RefreshNotifyTierInfo(data.TierInfo, data.ChangeType == 2)
    end
end

function XSuperTowerStageManager:RefreshStMapTargetData(data)
    local targetInfo = data.TargetInfo
    for _, theme in pairs(self.Themes) do
        if theme:CheckStStageIdIsInTheme(targetInfo.Id) then
            return theme:GetTargetStageByStStageId(targetInfo.Id):RefreshProgress(targetInfo.Progress, true)
        end
    end
end

function XSuperTowerStageManager:InitStageInfo()
    for _, theme in pairs(self.Themes) do
        theme:InitStageInfo()
    end
end
--=================
--设置本次通关后的临时进度（如果取消则不会被正式记录）
--@param data
--data:{
--目标关卡ID int TargetId,
--临时进度 int Progress,
--}
--=================
function XSuperTowerStageManager:SetTempProgress(data)
    if not data then return end
    self.TargetStageTempProgress = {}
    self.TargetStageTempProgress[data.TargetId] = data.Progress
    self.TempProgressMark = true
end
--=================
--获取临时进度
--@param 临时进度 int targetId
--=================
function XSuperTowerStageManager:GetTempProgressByTargetId(targetId)
    return self.TargetStageTempProgress and self.TargetStageTempProgress[targetId] or 0
end
--=================
--判断临时进度是否已设置
--=================
function XSuperTowerStageManager:IsSetTempProgress()
    return self.TempProgressMark
end
--=================
--重置临时进度已设置标记
--=================
function XSuperTowerStageManager:ClearTempProgressMark()
    self.TempProgressMark = nil
end
--=================
--重置临时进度
--=================
function XSuperTowerStageManager:ResetTempProgress()
    self.TargetStageTempProgress = nil
end
--=================
--刷新推送数据
--@param data(List<StMapInfo>)
--StMapInfo:{
--地图id int Id,
--爬塔数据 StTierInfo TierInfo,
--目标信息列表 List<StMapTargetInfo> TargetInfos
--}
--=================
function XSuperTowerStageManager:RefreshNotifyMapInfo(data)
    for _, mapInfo in pairs(data or {}) do
        if self.Themes[mapInfo.Id] then
            self.Themes[mapInfo.Id]:RefreshNotifyInfo(mapInfo)
        end
    end
end
--=================
--获取所有主题
--=================
function XSuperTowerStageManager:GetAllThemes()
    return self.Themes
end
--=================
--获取所有主题列表
--=================
function XSuperTowerStageManager:GetAllThemeList()
    return self.ThemesOrderByIndex
end
--=================
--根据ID获取主题
--@param id:主题ID
--=================
function XSuperTowerStageManager:GetThemeById(id)
    return self.Themes[id]
end
--=================
--根据序号获取主题
--@param themeIndex:主题序号
--=================
function XSuperTowerStageManager:GetThemeByIndex(themeIndex)
    return self.ThemesOrderByIndex[themeIndex]
end
--=================
--根据关卡Id获取所属主题对象
--@param stageId:Stage表Id
--=================
function XSuperTowerStageManager:GetThemeByStageId(stageId)
    for _, theme in pairs(self.Themes) do
        if theme:CheckStageIdIsInTheme(stageId) then
            return theme
        end
    end
end
--=================
--获取所有章节中的最大子关卡数
--=================
function XSuperTowerStageManager:GetMaxStageCount()
    return self.MaxStageCount
end
--=================
--根据关卡Id获取目标关卡Id
--@param stageId:Stage表Id
--=================
function XSuperTowerStageManager:GetTargetStageIdByStageId(stageId)
    for _, theme in pairs(self.Themes) do
        if theme:CheckStageIdIsInTheme(stageId) then
            return theme:GetTargetStageIdByStageId(stageId)
        end
    end
end
--=================
--根据完成进度获取当前正在进行的主题对象
--=================
function XSuperTowerStageManager:GetThemeByClearProgress()
    local curIndex = 1
    --按顺序检测主题
    for index, theme in pairs(self.ThemesOrderByIndex) do
        --若主题未开放，跳出循环
        if not theme:CheckIsOpen() then
            break
        end
        --如果已经检测到最后一个主题，返回该主题
        if index == #self.ThemesOrderByIndex then
            return theme
        end
        curIndex = index
        --若主题未全部通关，则为当前进度的主题
        if not theme:CheckIsAllClear() then           
            break
        end

    end
    return self.ThemesOrderByIndex[curIndex]
end
--=================
--根据关卡Id获取目标关卡
--@param stageId:Stage表Id
--=================
function XSuperTowerStageManager:GetTargetStageByStageId(stageId)
    for _, theme in pairs(self.Themes) do
        if theme:CheckStageIdIsInTheme(stageId) then
            return theme:GetTargetStageByStageId(stageId)
        end
    end
end
--=================
--根据关卡Id获取关卡类型
--@param stageId:Stage表Id
--=================
function XSuperTowerStageManager:GetStageTypeByStageId(stageId)
    for _, theme in pairs(self.Themes) do
        if theme:CheckStageIdIsInTheme(stageId) then
            return theme:GetStageTypeByStageId(stageId)
        end
    end
    return XDataCenter.SuperTowerManager.StageType.None
end
--=================
--根据目标关卡Id获取目标关卡对象
--@param stStageId:TargetStage表Id
--=================
function XSuperTowerStageManager:GetTargetStageByStStageId(stStageId)
    for _, theme in pairs(self.Themes) do
        if theme:CheckStStageIdIsInTheme(stStageId) then
            return theme:GetTargetStageByStStageId(stStageId)
        end
    end
end
--=================
--根据关卡Id获取目标关卡中该关卡的Index
--@param stageId:Stage表Id
--=================
function XSuperTowerStageManager:GetStageIndexByStageId(stageId)
    for _, theme in pairs(self.Themes) do
        if theme:CheckStageIdIsInTheme(stageId) then
            return theme:GetStageIndexByStageId(stageId)
        end
    end
    return 0
end
--=================
--检查所有主题的重置标记
--=================
function XSuperTowerStageManager:CheckReset()
    for _, theme in pairs(self.Themes) do
        theme:CheckReset()
    end
end
--=================
--获取正在进行的爬塔主题ID，若都没有在进行，返回0
--=================
function XSuperTowerStageManager:GetPlayingTierId()
    for index, theme in pairs(self.Themes) do
        if theme:CheckTierIsPlaying() then
            return index
        end
    end
    return 0
end

return XSuperTowerStageManager