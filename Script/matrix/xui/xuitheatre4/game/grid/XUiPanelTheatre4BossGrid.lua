-- boss格子
local XUiPanelTheatre4BaseGrid = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4BaseGrid")
---@class XUiPanelTheatre4BossGrid : XUiPanelTheatre4BaseGrid
local XUiPanelTheatre4BossGrid = XClass(XUiPanelTheatre4BaseGrid, "XUiPanelTheatre4BossGrid")

function XUiPanelTheatre4BossGrid:OnStart()
    self:InitUi()
    self:RegisterClick(handler(self, self.OnBtnGridClick))
    ---@type UiObject[]
    self.GridStarList = {}
end

function XUiPanelTheatre4BossGrid:InitUi()
    if self.EffectBoss then
        self.EffectBoss.gameObject:SetActiveEx(false)
    end
    if self.TagOccupy then
        self.TagOccupy.gameObject:SetActiveEx(false)
    end
    if self.TagAchievement then
        self.TagAchievement.gameObject:SetActiveEx(false)
        self.GridStar.gameObject:SetActiveEx(false)
    end
end

function XUiPanelTheatre4BossGrid:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA,
    }
end

function XUiPanelTheatre4BossGrid:OnNotify(event, ...)
    if event == XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA then
        self:RefreshOther()
    end
end

function XUiPanelTheatre4BossGrid:OnDisable()
    if self.EffectBoss then
        self.EffectBoss.gameObject:SetActiveEx(false)
    end
end

function XUiPanelTheatre4BossGrid:Refresh()
    XUiPanelTheatre4BaseGrid.Refresh(self)
    -- Boss图标
    local bossIcon = self:GetGridIcon()
    if bossIcon then
        self.RImgTypeIcon:SetRawImage(bossIcon)
    end
    -- 是否已处理
    local isProcessed = self.GridData:IsGridStateProcessed()
    self.PanelVisible.gameObject:SetActiveEx(not isProcessed)
    self.PanelProcessed.gameObject:SetActiveEx(isProcessed)
    -- 惩罚倒计时
    local punishCountdown = self:GetPunishCountdown()
    local isShowTime = not isProcessed and punishCountdown > 0
    self.PanelTime.gameObject:SetActiveEx(isShowTime)
    if isShowTime then
        -- 倒计时图片
        local countDownIcon = self._Control:GetClientConfig("CountDownIcon")
        if countDownIcon then
            self.ImgTime:SetSprite(countDownIcon)
        end
        -- 惩罚倒计时
        if punishCountdown == 1 then
            self.TxtNum.text = self._Control:GetClientConfig("CountDownDesc", 2)
        else
            local countDownDesc = self._Control:GetClientConfig("CountDownDesc", 1)
            self.TxtNum.text = XUiHelper.FormatText(countDownDesc, punishCountdown)
        end
    end
    -- 刷新boss血量
    local hpPercent = self.GridData:GetGridHpPercent()
    local isShowHp = not isProcessed and hpPercent > 0
    self.PanelHp.gameObject:SetActiveEx(isShowHp)
    if isShowHp then
        -- 血量进度条
        self.ImgHp.fillAmount = hpPercent / 100
    end
    self:RefreshOther()
end

-- 刷新其它ui
function XUiPanelTheatre4BossGrid:RefreshOther()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    -- 战斗数据是否为空
    local isFightEmpty = self.GridData:IsGridFightEmpty()
    if self.TagOccupy then
        self.TagOccupy.gameObject:SetActiveEx(not isFightEmpty)
    end
    if self.TagAchievement then
        self.TagAchievement.gameObject:SetActiveEx(not isFightEmpty)
    end
    if isFightEmpty then
        return
    end
    self:RefreshTagOccupy()
    self:RefreshStar()
end

-- 刷新是否满足占领条件
function XUiPanelTheatre4BossGrid:RefreshTagOccupy()
    if self.TagOccupy then
        local fightGroupId = self.GridData:GetGridFightGroupId()
        local prosperityLimit = self._Control:GetFightGroupProsperityLimit(fightGroupId)
        local currentProsperity = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Prosperity)
        self.PanelOn.gameObject:SetActiveEx(currentProsperity >= prosperityLimit)
        self.PanelOff.gameObject:SetActiveEx(currentProsperity < prosperityLimit)
    end
end

-- 刷新星级
function XUiPanelTheatre4BossGrid:RefreshStar()
    if not self.TagAchievement then
        return
    end
    local starIds = self._Control:GetDifficultyStarIds(self.MapId)
    if XTool.IsTableEmpty(starIds) then
        self.TagAchievement.gameObject:SetActiveEx(false)
        return
    end
    self.TagAchievement.gameObject:SetActiveEx(true)
    for index, starId in pairs(starIds) do
        local grid = self.GridStarList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridStar, self.TagAchievement)
            self.GridStarList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local isMeet = self._Control:CheckCurDifficultyStarIsMeet(starId, self.MapId)
        grid:GetObject("ImgAchievement01").gameObject:SetActiveEx(isMeet)
        grid:GetObject("ImgAchievement02").gameObject:SetActiveEx(not isMeet)
    end
    for i = #starIds + 1, #self.GridStarList do
        self.GridStarList[i].gameObject:SetActiveEx(false)
    end
end

-- 获取惩罚倒计时 0时显示1
function XUiPanelTheatre4BossGrid:GetPunishCountdown()
    local punishCountdown = self.GridData:GetGridPunishCountdown()
    return punishCountdown == 0 and 1 or punishCountdown
end

-- 播放格子特效
function XUiPanelTheatre4BossGrid:PlayGridEffect()
    -- 1层不播放特效
    if self.CurrentFloor <= 1 then
        return
    end
    if self.EffectBoss then
        self.EffectBoss.gameObject:SetActiveEx(false)
        self.EffectBoss.gameObject:SetActiveEx(true)
    end
end

-- 隐藏格子特效
function XUiPanelTheatre4BossGrid:HideGridEffect()
    if self.EffectBoss then
        self.EffectBoss.gameObject:SetActiveEx(false)
    end
end

function XUiPanelTheatre4BossGrid:OnBtnGridClick()
    self:InternalFocusToGrid()
    self.CurGridExploreStep = XEnumConst.Theatre4.GridExploreStep.None
    self:DoGridExploreStep()
end

-- 获取格子动画名
function XUiPanelTheatre4BossGrid:GetGridAnimName()
    return "PanelBossGridEnable"
end

return XUiPanelTheatre4BossGrid
