---@class XUiPanelRogueSimLandBubble : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimLandBubble = XClass(XUiNode, "XUiPanelRogueSimLandBubble")

function XUiPanelRogueSimLandBubble:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnDetermine, self.OnBtnDetermineClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiPanelRogueSimLandBubble:OnDisable()
    self._Control.RogueSimScene:ClearGridSelectEffect()
end

---@param grid XRogueSimGrid
function XUiPanelRogueSimLandBubble:Refresh(grid)
    self.Grid = grid
    local landformId = grid:GetLandformId()
    local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(landformId)
    -- 先隐藏相关ui
    self:Hide()
    -- 根据类型刷新
    local LandformType = XEnumConst.RogueSim.LandformType
    if landformCfg.LandType == LandformType.Main then
        self:RefreshMainCity()
        self:RefreshExp()
        self:RefreshBtn(3)
        return
    end
    if not self.Grid.IsExplored then
        -- 未探索时城邦点位详情特殊处理
        if landformCfg.LandType == LandformType.City then
            local cityData = self._Control.MapSubControl:GetCityDataByGridId(self.Grid:GetId())
            if cityData then
                self:RefreshCity(cityData:GetConfigId())
            else
                XLog.Error("城邦格子数据有问题，格子Id:" .. self.Grid:GetId())
            end
        else
            self:RefreshCommon(landformCfg)
        end
        if self.Grid:GetCanExplore() then
            self:RefreshConsume()
            self:RefreshBtn(1)
        elseif self.Grid.IsPreview then
            self:RefreshTips()
        end
        return
    end
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
    elseif landformCfg.LandType == LandformType.City then --城邦类型格子 会有城邦和道具 优先显示道具
        local isHaveReward = self:CheckRewardAndRefreshUi(landformCfg)
        if isHaveReward then
            return
        end
        local isHaveCity = self:CheckCityAndRefreshUi()
        if not isHaveCity then
            XLog.Error("城邦格子数据有问题，格子Id:" .. self.Grid:GetId())
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
        if not buildData:CheckIsBuy() then
            self:RefreshBtn(5)
        end
        return true
    end
    return false
end

-- 检查是否有城邦信息并刷新Ui
function XUiPanelRogueSimLandBubble:CheckCityAndRefreshUi()
    local cityData = self._Control.MapSubControl:GetCityDataByGridId(self.Grid:GetId())
    if cityData then
        self:RefreshCity(cityData:GetConfigId())
        self:RefreshBtn(2)
        return true
    end
    return false
end

-- 隐藏ui
function XUiPanelRogueSimLandBubble:Hide()
    self.PanelConsume.gameObject:SetActiveEx(false)
    self.PanelExp.gameObject:SetActiveEx(false)
    self.BtnDetermine.gameObject:SetActiveEx(false)
    self.TxtTips.gameObject:SetActiveEx(false)
    self.ImgCityTag.gameObject:SetActiveEx(false)
    self.ImgBuidingTag.gameObject:SetActiveEx(false)
end

-- 刷新通用Ui
function XUiPanelRogueSimLandBubble:RefreshCommon(landformCfg)
    self.RImgLand:SetRawImage(landformCfg.Icon)
    self.TxtName.text = landformCfg.Name
    self.TxtDetail1.text = landformCfg.BriefDesc
    self.TxtDetail2.text = landformCfg.Description
end

-- 刷新主城Ui
function XUiPanelRogueSimLandBubble:RefreshMainCity()
    local curLevel = self._Control:GetCurMainLevel()
    local id = self._Control:GetMainLevelConfigId(curLevel)
    self.RImgLand:SetRawImage(self._Control:GetMainLevelIcon(id))
    self.TxtName.text = self._Control:GetMainLevelName(id)
    self.TxtDetail1.text = self._Control:GetMainLevelBriefDesc(id)
    self.TxtDetail2.text = self._Control:GetMainLevelDesc(id)
end

-- 刷新事件Ui
function XUiPanelRogueSimLandBubble:RefreshEvent(landformCfg, eventId)
    self.RImgLand:SetRawImage(landformCfg.Icon)
    self.TxtName.text = self._Control.MapSubControl:GetEventName(eventId)
    self.TxtDetail1.gameObject:SetActiveEx(false)
    self.TxtDetail2.text = self._Control.MapSubControl:GetEventSuspendDesc(eventId)
end

-- 刷新建筑ui
function XUiPanelRogueSimLandBubble:RefreshBuilding(buildId)
    self.RImgLand:SetRawImage(self._Control.MapSubControl:GetBuildingIcon(buildId))
    self.TxtName.text = self._Control.MapSubControl:GetBuildingName(buildId)
    self.TxtDetail1.gameObject:SetActiveEx(false)
    self.TxtDetail2.text = self._Control.MapSubControl:GetBuildingDesc(buildId)

    self.ImgBuidingTag.gameObject:SetActiveEx(true)
    local tagIcon = self._Control.MapSubControl:GetBuildingTag(buildId)
    self.ImgBuidingTag:SetSprite(tagIcon)
end

-- 刷新城邦Ui
function XUiPanelRogueSimLandBubble:RefreshCity(cityId)
    self.RImgLand:SetRawImage(self._Control.MapSubControl:GetCityIcon(cityId))
    self.TxtName.text = self._Control.MapSubControl:GetCityName(cityId)
    self.TxtDetail1.text = self._Control.MapSubControl:GetCityBriefDesc(cityId)
    self.TxtDetail2.text = self._Control.MapSubControl:GetCityDesc(cityId)

    self.ImgCityTag.gameObject:SetActiveEx(true)
    local tagIcon = self._Control.MapSubControl:GetCityTag(cityId)
    self.ImgCityTag:SetSprite(tagIcon)
end

-- 刷新消耗
function XUiPanelRogueSimLandBubble:RefreshConsume()
    self.PanelConsume.gameObject:SetActiveEx(true)
    local ownCnt = self._Control:GetCurActionPoint()
    local needCnt = XEnumConst.RogueSim.MapExploredConst
    local isEnough = ownCnt >= needCnt
    self.PanelConsumeOn.gameObject:SetActiveEx(isEnough)
    self.PanelConsumeOff.gameObject:SetActiveEx(not isEnough)
    local panel = isEnough and self.PanelConsumeOn or self.PanelConsumeOff
    local icon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.ActionPoint)
    panel:GetObject("Icon"):SetRawImage(icon)
    panel:GetObject("TxtCosumeNumber").text = tostring(needCnt)
end

-- 刷新Exp
function XUiPanelRogueSimLandBubble:RefreshExp()
    self.PanelExp.gameObject:SetActiveEx(true)
    local expId = XEnumConst.RogueSim.ResourceId.Exp
    -- 当前等级
    local curLevel = self._Control:GetCurMainLevel()
    self.TxtLv.text = curLevel
    -- 资源图标
    self.ImgExp:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(expId))
    -- 经验
    if self._Control:CheckIsMaxLevel(curLevel) then
        self.TxtNum.text = self._Control:GetClientConfig("MainMaxLevelDesc")
        self.ImgBar.fillAmount = 1
    else
        local curExp, upExp = self._Control:GetCurExpAndLevelUpExp(curLevel)
        self.TxtNum.text = string.format("%d/%d", curExp, upExp)
        -- 进度条
        self.ImgBar.fillAmount = XTool.IsNumberValid(upExp) and curExp / upExp or 1
    end
end

-- 刷新Tips
function XUiPanelRogueSimLandBubble:RefreshTips()
    self.TxtTips.gameObject:SetActiveEx(true)
    self.TxtTips.text = self._Control:GetClientConfig("LandNotExplorableTips")
end

-- 刷新按钮
function XUiPanelRogueSimLandBubble:RefreshBtn(index)
    self.BtnDetermine.gameObject:SetActiveEx(true)
    local btnName = self._Control:GetClientConfig("LandBubbleBtnName", index)
    self.BtnDetermine:SetName(btnName)
end

function XUiPanelRogueSimLandBubble:OnBtnDetermineClick()
    local landformId = self.Grid:GetLandformId()
    local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(landformId)
    local LandformType = XEnumConst.RogueSim.LandformType
    if landformCfg.LandType == LandformType.Main then
        XLuaUiManager.Open("UiRogueSimLv")
        self:Close()
        return
    end
    if not self.Grid.IsExplored then
        self:OnBtnExploreClick()
        return
    end
    self:Close()
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
        local eventId = self:GetEventIdByGridId(self.Grid:GetId())
        if XTool.IsNumberValid(eventId) then
            self._Control.MapSubControl:ExploreEventGrid(eventId)
            return
        end
        local buildId = self:GetBuildingIdByGridId(self.Grid:GetId())
        if XTool.IsNumberValid(buildId) then
            self._Control.MapSubControl:ExploreBuildingGrid(buildId)
        else
            XLog.Error("没有建筑信息，格子Id:" .. self.Grid:GetId())
        end
    elseif landformCfg.LandType == LandformType.City then
        local rewardId = self:GetRewardIdByGridId(self.Grid:GetId())
        if XTool.IsNumberValid(rewardId) then
            self._Control.MapSubControl:ExplorePropGrid(rewardId)
            return
        end
        local cityId = self:GetCityIdByGridId(self.Grid:GetId())
        if XTool.IsNumberValid(cityId) then
            self._Control.MapSubControl:ExploreCityGrid(cityId)
        else
            XLog.Error("没有城邦信息，格子Id:" .. self.Grid:GetId())
        end
    end
end

function XUiPanelRogueSimLandBubble:OnBtnExploreClick()
    local ownCnt = self._Control:GetCurActionPoint()
    local needCnt = XEnumConst.RogueSim.MapExploredConst
    local isEnough = ownCnt >= needCnt
    if not isEnough then
        XUiManager.TipMsg(self._Control:GetClientConfig("ActionPointNoEnoughTips"))
        return
    end
    self._Control:RogueSimExploreGridRequest(self.Grid:GetId(), function()
        self:Close()
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

-- 获取建筑信息自增Id通过格子Id
function XUiPanelRogueSimLandBubble:GetBuildingIdByGridId(gridId)
    local buildData = self._Control.MapSubControl:GetBuildingDataByGridId(gridId)
    if buildData then
        return buildData:GetId()
    end
    return 0
end

-- 获取城邦信息自增Id通过格子Id
function XUiPanelRogueSimLandBubble:GetCityIdByGridId(gridId)
    local cityData = self._Control.MapSubControl:GetCityDataByGridId(gridId)
    if cityData then
        return cityData:GetId()
    end
    return 0
end

function XUiPanelRogueSimLandBubble:OnBtnCloseClick()
    self:Close()
end

return XUiPanelRogueSimLandBubble
