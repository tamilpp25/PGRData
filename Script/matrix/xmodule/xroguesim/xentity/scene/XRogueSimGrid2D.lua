-- 肉鸽模拟经营场景2D节点
---@class XRogueSimGrid2D
---@field _Control XRogueSimControl
local XRogueSimGrid2D = XClass(nil, "XRogueSimGrid2D")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

---@param scene XRogueSimScene
---@param grid XRogueSimGrid
function XRogueSimGrid2D:Ctor(scene, grid)
    self.Scene = scene
    self.Grid = grid
    self._Control = self.Scene._MainControl
    self.IsLoaded = false -- 是否已加载
end

-- 加载
function XRogueSimGrid2D:Load()
    local gridGo = CSInstantiate(self.Scene.UiGrid, self.Scene.UiGridList)
    self.Transform = gridGo.transform
    self.GameObject = gridGo.gameObject
    self.GameObject:SetActiveEx(true)
    self.Transform.name = tostring(self.Grid.Id)
    local worldPos = self.Scene:GetGridChildsCenterWorldPos(self.Grid.Id)
    local height = self.Grid.TerrainHeightWan and (self.Grid.TerrainHeightWan / 10000) or 1
    local posZ = -height * self.Scene.TERRAIN_HEIGHT
    self.Transform.localPosition = CS.UnityEngine.Vector3(worldPos.x, worldPos.z, posZ)
    XTool.InitUiObject(self)
    self.IsLoaded = true
    self:OnLoaded()
end

function XRogueSimGrid2D:OnLoaded()
    self:RegisterUiEvents()
    self:Refresh()
end

function XRogueSimGrid2D:Release()
    XTool.ReleaseUiObjectIndex(self)
    self.Scene = nil
    self.Grid = nil
    self._Control = nil
    self.Transform = nil
    self.GameObject = nil
end

function XRogueSimGrid2D:RegisterUiEvents()
    self.BtnLevelUp.CallBack = function()
        self:OnBtnLevelUpClick()
    end
    self.BtnBuild.CallBack = function()
        self:OnBtnBuildClick()
    end
    self.BtnEvent.CallBack = function()
        self:OnBtnEventClick()
    end
    self.BtnItem.CallBack = function()
        self:OnBtnItemClick()
    end
    self.PanelTask:GetObject("BtnClick").CallBack = function()
        self:OnPanelTaskClick()
    end
    self.PanelUnlock:GetObject("BtnBuy").CallBack = function()
        self:OnPanelUnlockBtnBuyClick()
    end
end

-- 点击升级按钮
function XRogueSimGrid2D:OnBtnLevelUpClick()
    self.Grid:OnGridClick()
end

-- 点击建造按钮
function XRogueSimGrid2D:OnBtnBuildClick()
    XLog.Error("未实现建造按钮点击")
end

-- 点击事件按钮
function XRogueSimGrid2D:OnBtnEventClick()
    -- 优先处理事件投机
    local eventGambleData = self._Control.MapSubControl:GetCanGetEventGambleDataByGridId(self.Grid:GetId())
    if eventGambleData then
        self._Control.MapSubControl:EventGambleGridClick(eventGambleData:GetId())
        return
    end
    local eventData = self._Control.MapSubControl:GetEventDataByGridId(self.Grid:GetId())
    if eventData then
        self._Control.MapSubControl:ExploreEventGrid(eventData:GetId())
        return
    end
end

-- 点击选择道具按钮
function XRogueSimGrid2D:OnBtnItemClick()
    local rewardData = self._Control:GetRewardDataByGridId(self.Grid:GetId())
    if rewardData and not rewardData:GetPick() then
        self._Control.MapSubControl:ExplorePropGrid(rewardData:GetId())
    end
end

-- 点击任务面板
function XRogueSimGrid2D:OnPanelTaskClick()
    self.Grid:OnGridClick()
end

-- 点击解锁面板的购买按钮
function XRogueSimGrid2D:OnPanelUnlockBtnBuyClick()
    local cost = self._Control.MapSubControl:GetBuyAreaCostGoldCount(self.Grid.AreaId)
    local own = self._Control.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Gold)
    if own < cost then
        XUiManager.TipMsg(self._Control:GetClientConfig("BuildingGoldNotEnough"))
        return
    end

    -- 请求解锁区域
    self._Control:RogueSimUnlockAreaRequest(self.Grid.AreaId, function()
        self.Grid.Scene:PlayAreaUnlock()
    end)
end

function XRogueSimGrid2D:Show(isShow)
    if not self.IsLoaded or not self:IsNeedShow() then
        return
    end

    self.GameObject:SetActiveEx(isShow)
end

-- 是否需要Ui显示，需要显示Ui内容才加载
function XRogueSimGrid2D:IsNeedShow()
    -- 需要显示解锁UI
    if self:CheckShowPanelUnlock() then
        return true
    end

    if self.Grid.LandformId == 0 or not self.Grid:GetCanBeSeen() then
        return false
    end

    -- 配置Ui图标
    local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(self.Grid.LandformId)
    if landformCfg.ModelCenterIcon or landformCfg.ModelSideIcon then
        return true
    end

    -- 地貌类型
    local landType = self.Grid:GetLandType()
    if landType == XEnumConst.RogueSim.LandformType.Main then
        return true
    elseif landType == XEnumConst.RogueSim.LandformType.City then
        return true
    elseif landType == XEnumConst.RogueSim.LandformType.Building then
        return true
    elseif landType == XEnumConst.RogueSim.LandformType.Event then
        local eventData = self._Control.MapSubControl:GetEventDataByGridId(self.Grid:GetId())
        if eventData then -- 有未处理事件
            return true
        end
    elseif landType == XEnumConst.RogueSim.LandformType.Prop then
        local rewardData = self._Control:GetRewardDataByGridId(self.Grid:GetId())
        if rewardData and not rewardData:GetPick() then -- 有未选择的道具
            return true
        end
    elseif landType == XEnumConst.RogueSim.LandformType.Resource then

    end

    return false
end

-- 刷新
function XRogueSimGrid2D:Refresh()
    local needShow = self:IsNeedShow()
    if not needShow then
        if self.IsLoaded then
            self.GameObject.gameObject:SetActiveEx(false)
        end
        return
    end

    if not self.IsLoaded then
        self:Load()
    end
    self.GameObject.gameObject:SetActiveEx(true)

    -- Ui默认隐藏
    self.RImgCenter.gameObject:SetActiveEx(false)
    self.PanelMainName.gameObject:SetActiveEx(false)
    self.PanelCityName.gameObject:SetActiveEx(false)
    self.PanelBuidingName.gameObject:SetActiveEx(false)
    self.BtnLevelUp.gameObject:SetActiveEx(false)
    self.BtnBuild.gameObject:SetActiveEx(false)
    self.BtnEvent.gameObject:SetActiveEx(false)
    self.BtnItem.gameObject:SetActiveEx(false)
    self.PanelTask.gameObject:SetActiveEx(false)
    self.PanelUnlock.gameObject:SetActiveEx(false)

    -- Ui图标
    self:RefreshIcon()
    -- 区域解锁Ui
    self:RefreshPanelUnlock()

    -- 根据建筑类型刷新UI
    if self.Grid.LandformId ~= 0 then
        local landType = self.Grid:GetLandType()
        if landType == XEnumConst.RogueSim.LandformType.Main then
            self:RefreshMain()
        elseif landType == XEnumConst.RogueSim.LandformType.City then
            self:RefreshCity()
        elseif landType == XEnumConst.RogueSim.LandformType.Building then
            self:RefreshEvent()
            self:RefreshBuilding()
        elseif landType == XEnumConst.RogueSim.LandformType.Event then
            self:RefreshEvent()
        elseif landType == XEnumConst.RogueSim.LandformType.Prop then
            self:RefreshProp()
        elseif landType == XEnumConst.RogueSim.LandformType.Resource then
            self:RefreshResource()
        end
    end
end

-- 刷新图标
function XRogueSimGrid2D:RefreshIcon()
    if self.Grid.LandformId == 0 then return end
    if self:CheckShowPanelUnlock() then return end

    local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(self.Grid.LandformId)
    if landformCfg.ModelCenterIcon ~= nil then
        self.RImgCenter.gameObject:SetActiveEx(true)
        self.RImgCenter:SetRawImage(landformCfg.ModelCenterIcon)
    end
end

-- 刷新主城类型
function XRogueSimGrid2D:RefreshMain()
    -- 名称
    self.PanelMainName.gameObject:SetActiveEx(true)
    self.TxtMainName.text = self.Grid:GetName()
    self.TxtMainLevel.text = self._Control:GetCurMainLevel()

    -- 可升级按钮
    local isCanLevelUp = self._Control:CheckMainLevelCanLevelUp()
    if isCanLevelUp then
        self.BtnLevelUp.gameObject:SetActiveEx(true)
    end
end

-- 刷新城邦类型
function XRogueSimGrid2D:RefreshCity()
    -- 名称
    self.PanelCityName.gameObject:SetActiveEx(true)
    self.TxtCityName.text = self.Grid:GetName()

    -- 标志
    local tagIcon = self._Control.MapSubControl:GetLandformSideIcon(self.Grid.LandformId)
    self.RImgCityIcon:SetSprite(tagIcon)

    -- 不与区域解锁同时显示
    local isShowPanelUnlock = self:CheckShowPanelUnlock()
    self.PanelName.gameObject:SetActiveEx(not isShowPanelUnlock)

    -- 城邦任务
    if self.Grid:GetIsExplored() then
        local cityData = self._Control.MapSubControl:GetCityDataByGridId(self.Grid:GetId())
        if cityData then
            -- 可升级按钮
            local isCanLevelUp = self._Control.MapSubControl:CheckCityCanLevelUp(cityData:GetId())
            if isCanLevelUp then
                self.BtnLevelUp.gameObject:SetActiveEx(true)
            end
            -- 城邦任务
            local taskIds = self._Control.MapSubControl:GetCityUnfinishedTaskIds(cityData:GetId())
            local taskId = taskIds and taskIds[1] or 0
            if taskId and taskId ~= 0 then
                local configId = self._Control:GetTaskConfigIdById(taskId)
                local isFinish = self._Control:CheckTaskIsFinished(taskId)
                if not isFinish then
                    self.PanelTask.gameObject:SetActiveEx(true)
                    local schedule, totalNum = self._Control:GetTaskScheduleAndTotalNum(taskId, configId)
                    self.PanelTask:GetObject("TxtDetail").text = self._Control:GetTaskDesc(configId)
                    self.PanelTask:GetObject("ImgBar").fillAmount = XTool.IsNumberValid(totalNum) and schedule / totalNum or 1
                end
            end
        end
    end
end

-- 刷新建筑类型
function XRogueSimGrid2D:RefreshBuilding()
    local buildData = self._Control.MapSubControl:GetBuildingDataByGridId(self.Grid:GetId())
    if buildData then
        -- 名称
        self.PanelBuidingName.gameObject:SetActiveEx(true)
        self.TxtBuidingName.text = self.Grid:GetName()
        -- 标志
        local tagIcon = self._Control.MapSubControl:GetLandformSideIcon(self.Grid.LandformId)
        self.RImgBuidingIcon:SetSprite(tagIcon)
    end
end

-- 刷新事件类型
function XRogueSimGrid2D:RefreshEvent()
    local eventData = self._Control.MapSubControl:GetEventDataByGridId(self.Grid:GetId())
    local eventGambleData = self._Control.MapSubControl:GetCanGetEventGambleDataByGridId(self.Grid:GetId())
    if eventData ~= nil or eventGambleData ~= nil then -- 有未处理事件或者有未处理的事件投机
        self.BtnEvent.gameObject:SetActiveEx(true)
    end
end

-- 刷新道具类型
function XRogueSimGrid2D:RefreshProp()
    local rewardData = self._Control:GetRewardDataByGridId(self.Grid:GetId())
    if rewardData and not rewardData:GetPick() then -- 有未选择的道具
        self.BtnItem.gameObject:SetActiveEx(true)
    end
end

-- 刷新资源类型
function XRogueSimGrid2D:RefreshResource()

end

-- 是否显示购买面板
function XRogueSimGrid2D:CheckShowPanelUnlock()
    -- 区域未解锁 且 可解锁
    if not self.Grid.AreaIsUnlock and self.Grid.AreaCanUnlock then
        local cost = self._Control.MapSubControl:GetBuyAreaCostGoldCount(self.Grid.AreaId)
        local gridId = self._Control.MapSubControl:GetRogueSimAreaUnlockUiGridId(self.Grid.AreaId)
        -- 通过金币解锁 且 在此格子上显示
        if cost >= 0 and gridId == self.Grid.Id then
            return true
        end
    end
    return false
end

-- 刷新购买面板
function XRogueSimGrid2D:RefreshPanelUnlock()
    local isShow = self:CheckShowPanelUnlock()
    self.PanelUnlock.gameObject:SetActiveEx(isShow)
    if not isShow then return end

    -- 刷新面板位置
    local pos = self._Control.MapSubControl:GetRogueSimAreaUnlockUiPos(self.Grid.AreaId)
    if pos and pos ~= "" then
        local values = string.Split(pos, "|")
        local posX = tonumber(values[1])
        local posY = tonumber(values[2])
        local posZ = tonumber(values[3])
        self.PanelUnlock.transform.localPosition = CS.UnityEngine.Vector3(posX, posY, posZ)
    end

    -- 购买按钮
    local cost = self._Control.MapSubControl:GetBuyAreaCostGoldCount(self.Grid.AreaId)
    local icon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold)
    local btnBuy = self.PanelUnlock:GetObject("BtnBuy")
    btnBuy:SetNameByGroup(0, tostring(cost))
    btnBuy:SetRawImage(icon)

    -- 奖励经验
    local exp = self._Control.MapSubControl:GetRogueSimAreaUnlockExpReward(self.Grid.AreaId)
    local expIcon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Exp)
    self.PanelUnlock:GetObject("ImgIcon"):SetSprite(expIcon)
    self.PanelUnlock:GetObject("TxtNum").text = "+" .. tostring(exp)

    -- 区域名称
    local area = self.Scene:GetArea(self.Grid.AreaId)
    self.PanelUnlock:GetObject("TxtCityName").text = area:GetName()

    -- 地貌标签
    local rImgCityIcon = self.PanelUnlock:GetObject("RImgCityIcon")
    if self.Grid.LandformId == 0 then
        rImgCityIcon.gameObject:SetActiveEx(false)
    else
        local sideIcon = self._Control.MapSubControl:GetLandformSideIcon(self.Grid.LandformId)
        if not sideIcon or sideIcon == "" then 
            rImgCityIcon.gameObject:SetActiveEx(false)
        else
            rImgCityIcon.gameObject:SetActiveEx(true)
            rImgCityIcon:SetSprite(sideIcon)
        end
    end
end

return XRogueSimGrid2D
