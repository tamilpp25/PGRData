---@class XUiArenaNewRight : XUiNode
---@field BtnArenaTask XUiComponent.XUiButton
---@field BtnShop XUiComponent.XUiButton
---@field BtnZone XUiComponent.XUiButton
---@field Zone1 UnityEngine.RectTransform
---@field Zone2 UnityEngine.RectTransform
---@field Zone3 UnityEngine.RectTransform
---@field Zone4 UnityEngine.RectTransform
---@field Zone5 UnityEngine.RectTransform
---@field _Control XArenaControl
local XUiArenaNewRight = XClass(XUiNode, "XUiArenaNewRight")

-- region 生命周期

function XUiArenaNewRight:OnStart(uiScene)
    self._TaskRedDotEvent = nil
    ---@type XArenaAreaData
    self._AreaData = nil
    ---@type XUiArenaScene
    self._Scene = uiScene
    self._IsPlayed = false

    self:_RegisterButtonClicks()
end

function XUiArenaNewRight:OnEnable()
    self:_Refresh()
    self:_RegisterRedPointEvents()
end

-- endregion

function XUiArenaNewRight:CheckTaskRedDot()
    if self._TaskRedDotEvent then
        XRedPointManager.Check(self._TaskRedDotEvent)
    end
end

-- region 按钮事件

function XUiArenaNewRight:OnBtnArenaTaskClick()
    XLuaUiManager.Open("UiArenaTask")
end

function XUiArenaNewRight:OnBtnShopClick()
    XLuaUiManager.Open("UiShop", XShopManager.ShopType.Arena)
end

function XUiArenaNewRight:OnCheckTaskRedDots(count)
    self.BtnArenaTask:ShowReddot(count >= 0)
end

---@param areaData XArenaAreaData
function XUiArenaNewRight:Refresh(areaData)
    self._AreaData = areaData
    self:_Refresh()
end

-- endregion

-- region 私有方法

function XUiArenaNewRight:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnArenaTask, self.OnBtnArenaTaskClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, self.OnBtnShopClick, true)
end

function XUiArenaNewRight:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    self._TaskRedDotEvent = self:AddRedPointEvent(self.BtnArenaTask, self.OnCheckTaskRedDots, self, {
        XRedPointConditions.Types.CONDITION_ARENA_MAIN_TASK,
    })
end

function XUiArenaNewRight:_Refresh()
    if not self._AreaData then
        return
    end

    local arenaShowDataList = self._AreaData:GetArenaShowList()
    local infoList = {}
    local startIndex = 0

    if not XTool.IsTableEmpty(arenaShowDataList) then
        for _, showData in pairs(arenaShowDataList) do
            local areaId = showData:GetAreaId()
            local stageData = showData:GetStageInfo()
            local info = {
                Region = self._Control:GetAreaStageRegionById(areaId),
                StageName = self._Control:GetAreaStageNameByAreaId(areaId),
                HasPoint = showData:CheckHasStagePoint(),
                Point = stageData and stageData:GetPoint() or 0,
            }

            table.insert(infoList, info)
        end
        if #infoList <= 2 then
            startIndex = 3
        end
    end
    for index, info in pairs(infoList) do
        self._Scene:SetZoneByIndex(index, startIndex, info)
        self._Scene:SetZoneClickEvent(index, function()
            XLuaUiManager.Open("UiArenaChapterDetail", self._AreaData, index, self._Scene)
            self.Parent:OnShowChapter(index + startIndex)
            self._Scene:SelectZone(index)
        end)
    end
    if not self._IsPlayed then
        self._IsPlayed = true
        self._Scene:PlayZoneStartAnimation()
    end
end

-- endregion

return XUiArenaNewRight
