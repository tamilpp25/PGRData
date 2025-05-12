---@class XUiPanelRogueSimLandBubble : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimBattle
local XUiPanelRogueSimLandBubble = XClass(XUiNode, "XUiPanelRogueSimLandBubble")

function XUiPanelRogueSimLandBubble:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnSure, self.OnBtnSureClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick, nil, true)
    if not self.ImgBg then
        self.ImgBg = XUiHelper.TryGetComponent(self.Transform, "ImgBg", "RawImage")
    end
end

function XUiPanelRogueSimLandBubble:OnEnable()
    self:PlayAnimationWithMask("LandBubbleEnable")
end

function XUiPanelRogueSimLandBubble:OnDisable()
    self._Control:ClearGridSelectEffect()
end

---@param grid XRogueSimGrid
function XUiPanelRogueSimLandBubble:Refresh(grid)
    self.Grid = grid
    local landformId = grid:GetLandformId()
    local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(landformId)
    -- 先隐藏相关ui
    self:Hide()
    self:Show()
    if not self.Grid:GetIsExplored() then
        self:RefreshCommon(landformCfg)
        if self.Grid:GetCanExplore() then
            self:RefreshBtn(1)
        elseif self.Grid.IsPreview then
            self:RefreshTips()
        end
        return
    end
    local LandformType = XEnumConst.RogueSim.LandformType
    if landformCfg.LandType == LandformType.Resource then
        XLog.Error("格子已探索，不应触发格子点击，格子Id:" .. self.Grid:GetId())
    elseif landformCfg.LandType == LandformType.Prop then
        local isHaveReward = self:CheckRewardAndRefreshUi(landformCfg)
        if not isHaveReward then
            XLog.Error("格子道具已领取，不应触发格子点击，格子Id:" .. self.Grid:GetId())
        end
    elseif landformCfg.LandType == LandformType.Event then
        local isHaveEvent = self:CheckEventAndRefreshUi(landformCfg)
        if not isHaveEvent then
            XLog.Error("格子事件已完成，不应触发格子点击，格子Id:" .. self.Grid:GetId())
        end
    elseif landformCfg.LandType == LandformType.Building then --  建筑类型格子 会有建筑和事件 优先显示事件
        local isHaveEvent = self:CheckEventAndRefreshUi(landformCfg)
        if isHaveEvent then
            return
        end
        local isHaveBuilding = self:CheckBuildingAndRefreshUi()
        if not isHaveBuilding then
            XLog.Error("建筑格子数据有问题，格子Id:" .. self.Grid:GetId())
        end
    end
end

-- 检查是否有奖励信息并刷新Ui
function XUiPanelRogueSimLandBubble:CheckRewardAndRefreshUi(landformCfg)
    local rewardData = self._Control:GetRewardDataByGridId(self.Grid:GetId())
    if rewardData and not rewardData:GetPick() then
        self:RefreshCommon(landformCfg)
        self:RefreshBtn(4)
        return true
    end
    return false
end

-- 检查是否有事件信息并刷新Ui
function XUiPanelRogueSimLandBubble:CheckEventAndRefreshUi(landformCfg)
    local eventData = self._Control.MapSubControl:GetEventDataByGridId(self.Grid:GetId())
    if eventData then
        self:RefreshEvent(landformCfg, eventData:GetConfigId())
        self:RefreshBtn(4)
        return true
    end
    return false
end

-- 检查是否有建筑信息并刷新Ui
function XUiPanelRogueSimLandBubble:CheckBuildingAndRefreshUi()
    local buildData = self._Control.MapSubControl:GetBuildingDataByGridId(self.Grid:GetId())
    if buildData then
        self:RefreshBuilding(buildData:GetConfigId())
        local eventGambleData = self._Control.MapSubControl:GetCanGetEventGambleDataByGridId(self.Grid:GetId())
        if eventGambleData then
            self:RefreshBtn(4)
        end
        return true
    end
    return false
end

-- 隐藏ui
function XUiPanelRogueSimLandBubble:Hide()
    self.PanelConsume.gameObject:SetActiveEx(false)
    self.PanelExp.gameObject:SetActiveEx(false)
    self.BtnSure.gameObject:SetActiveEx(false)
    self.TxtTips.gameObject:SetActiveEx(false)
    self.ImgCityTag.gameObject:SetActiveEx(false)
    self.ImgBuidingTag.gameObject:SetActiveEx(false)
end

-- 显示通用Ui
function XUiPanelRogueSimLandBubble:Show()
    self.TxtDetail1.gameObject:SetActiveEx(true)
end

-- 刷新通用Ui
function XUiPanelRogueSimLandBubble:RefreshCommon(landformCfg)
    if self.ImgBg then
        self.ImgBg:SetRawImage(self._Control:GetClientConfig("LandBubbleCommonBgIcon"))
    end
    self.RImgLand:SetRawImage(landformCfg.Icon)
    self.TxtName.text = landformCfg.Name
    self.TxtDetail1.text = landformCfg.BriefDesc
    self.TxtDetail2.text = XUiHelper.ReplaceTextNewLine(landformCfg.Description)
end

-- 刷新事件Ui
function XUiPanelRogueSimLandBubble:RefreshEvent(landformCfg, eventId)
    if self.ImgBg then
        self.ImgBg:SetRawImage(self._Control:GetClientConfig("LandBubbleCommonBgIcon"))
    end
    self.RImgLand:SetRawImage(landformCfg.Icon)
    self.TxtName.text = self._Control.MapSubControl:GetEventName(eventId)
    self.TxtDetail1.gameObject:SetActiveEx(false)
    self.TxtDetail2.text = self._Control.MapSubControl:GetEventSuspendDesc(eventId)
end

-- 刷新建筑ui
function XUiPanelRogueSimLandBubble:RefreshBuilding(buildId)
    if self.ImgBg then
        self.ImgBg:SetRawImage(self._Control.MapSubControl:GetBuildingQualityIcon(buildId))
    end
    self.RImgLand:SetRawImage(self._Control.MapSubControl:GetBuildingIcon(buildId))
    self.TxtName.text = self._Control.MapSubControl:GetBuildingName(buildId)
    self.TxtDetail1.gameObject:SetActiveEx(false)
    self.TxtDetail2.text = self._Control.MapSubControl:GetBuildingDesc(buildId)
    -- 建筑标签
    local tagIcon = self._Control.MapSubControl:GetBuildingTag(buildId)
    local isShowTag = not string.IsNilOrEmpty(tagIcon)
    self.ImgBuidingTag.gameObject:SetActiveEx(isShowTag)
    if isShowTag then
        self.ImgBuidingTag:SetSprite(tagIcon)
    end
end

-- 刷新Tips
function XUiPanelRogueSimLandBubble:RefreshTips()
    self.TxtTips.gameObject:SetActiveEx(true)
    self.TxtTips.text = self._Control:GetClientConfig("LandNotExplorableTips")
end

-- 刷新按钮
function XUiPanelRogueSimLandBubble:RefreshBtn(index)
    self.BtnSure.gameObject:SetActiveEx(true)
    local btnName = self._Control:GetClientConfig("LandBubbleBtnName", index)
    self.BtnSure:SetName(btnName)
end

function XUiPanelRogueSimLandBubble:OnBtnSureClick()
    local landformId = self.Grid:GetLandformId()
    local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(landformId)
    local LandformType = XEnumConst.RogueSim.LandformType
    if not self.Grid:GetIsExplored() then
        self:OnBtnExploreClick()
        return
    end
    self:OnBtnCloseClick()
    if landformCfg.LandType == LandformType.Prop then
        local rewardId = self:GetRewardIdByGridId(self.Grid:GetId())
        if XTool.IsNumberValid(rewardId) then
            self._Control.MapSubControl:ExplorePropGrid(rewardId)
        else
            XLog.Error("没有奖励信息，格子Id:" .. self.Grid:GetId())
        end
    elseif landformCfg.LandType == LandformType.Event then
        local eventId = self:GetEventIdByGridId(self.Grid:GetId())
        if XTool.IsNumberValid(eventId) then
            self._Control.MapSubControl:ExploreEventGrid(eventId)
        else
            XLog.Error("没有事件信息，格子Id:" .. self.Grid:GetId())
        end
    elseif landformCfg.LandType == LandformType.Building then
        local eventGambleId = self:GetEventGambleIdByGridId(self.Grid:GetId())
        if XTool.IsNumberValid(eventGambleId) then
            self._Control.MapSubControl:EventGambleGridClick(eventGambleId)
            return
        end
        local eventId = self:GetEventIdByGridId(self.Grid:GetId())
        if XTool.IsNumberValid(eventId) then
            self._Control.MapSubControl:ExploreEventGrid(eventId)
            return
        end
    end
end

function XUiPanelRogueSimLandBubble:OnBtnExploreClick()
    if not self.Grid:GetCanExplore() then
        XUiManager.TipMsg(self._Control:GetClientConfig("StoryLockText"))
        return
    end
    self.Parent:ExploreGridConfirm(self.Grid, function()
        self:OnBtnCloseClick()
    end)
end

-- 获取奖励信息自增Id通过格子Id
function XUiPanelRogueSimLandBubble:GetRewardIdByGridId(gridId)
    local rewardData = self._Control:GetRewardDataByGridId(gridId)
    if rewardData and not rewardData:GetPick() then
        return rewardData:GetId()
    end
    return 0
end

-- 获取事件信息自增Id通过格子Id
function XUiPanelRogueSimLandBubble:GetEventIdByGridId(gridId)
    local eventData = self._Control.MapSubControl:GetEventDataByGridId(gridId)
    if eventData then
        return eventData:GetId()
    end
    return 0
end

-- 获取事件投机自增Id通过格子Id
function XUiPanelRogueSimLandBubble:GetEventGambleIdByGridId(gridId)
    local eventGambleData = self._Control.MapSubControl:GetCanGetEventGambleDataByGridId(gridId)
    if eventGambleData then
        return eventGambleData:GetId()
    end
    return 0
end

function XUiPanelRogueSimLandBubble:OnBtnCloseClick()
    self:PlayAnimationWithMask("LandBubbleDisable", function()
        self:Close()
    end)
end

return XUiPanelRogueSimLandBubble
