local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiArenaChapterDetailGridBuff = require("XUi/XUiArenaNew/XUiArenaChapter/XUiArenaChapterDetailGridBuff")

---@class XUiArenaChapterDetail : XLuaUi
---@field PanelAsset UnityEngine.RectTransform
---@field BtnFight XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field TxtTips UnityEngine.UI.Text
---@field PanelBuff UnityEngine.RectTransform
---@field GridBuff UnityEngine.RectTransform
---@field ListTitle XUiButtonGroup
---@field GridTitle XUiComponent.XUiButton
---@field TxtTitle UnityEngine.UI.Text
---@field TxtEnvironment UnityEngine.UI.Text
---@field PanelTitle UnityEngine.RectTransform
---@field _Control XArenaControl
local XUiArenaChapterDetail = XLuaUiManager.Register(XLuaUi, "UiArenaChapterDetail")

-- region 生命周期

function XUiArenaChapterDetail:OnAwake()
    ---@type XUiArenaChapterDetailGridBuff[]
    self._BuffGridList = {}
    ---@type XUiComponent.XUiButton[]
    self._BtnListTitleList = {}
    ---@type XArenaAreaData
    self._AreaData = nil
    ---@type XUiArenaScene
    self._Scene = nil
    self._CurrentSelectBuffIndex = 1
    self._CurrentSelectZoneIndex = 1
    self._IsReOpen = false

    self:_InitUi()
    self:_RegisterButtonClicks()
end

---@param areaData XArenaAreaData
function XUiArenaChapterDetail:OnStart(areaData, selectIndex, scene)
    self._AreaData = areaData
    self._CurrentSelectZoneIndex = selectIndex
    self._Scene = scene

    self._Scene:SetZonesSelectEvent(Handler(self, self.OnZoneSelectClick))
    self._Scene:RefreshPlayerGrid(selectIndex, self:_GetCurrentAreaShowData())
    self._Control:RestoreSelectBuffIndex()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint)
end

function XUiArenaChapterDetail:OnEnable()
    self:_RefreshBuffList()
    self:_RefreshStageDatail()
    if self._IsReOpen then
        self._Scene:PlayRankAnimation()
    end
    self._IsReOpen = true
end

-- endregion

function XUiArenaChapterDetail:Close()
    self.Super.Close(self)
    XEventManager.DispatchEvent(XEventId.EVENT_ARENA_RESHOW_MAIN_UI)
end

-- region 按钮事件

function XUiArenaChapterDetail:OnBtnFightClick()
    local areaId = self:_GetCurrentAreaId()

    self._Control:SetCurrentEnterAreaId(areaId)
    self._Control:ChangeCurrentSelectBuffIndex(self._CurrentSelectBuffIndex)

    local stageId = self._Control:GetAreaStageLastStageIdById(areaId)
    self._Control:OpenBattleRoleRoom(stageId)
end

function XUiArenaChapterDetail:OnListTitleClick(index)
    local areaId = self:_GetCurrentAreaId()

    self._CurrentSelectBuffIndex = index
    self._Control:SetLocalSelectBuffIndex(areaId, index)
end

function XUiArenaChapterDetail:OnZoneSelectClick(index)
    self._CurrentSelectZoneIndex = index
    self._CurrentSelectBuffIndex = 1
    self:_RefreshBuffList()
    self:_RefreshStageDatail()
    self:PlayAnimation("AnimSwitch")
    self._Scene:RefreshPlayerGrid(index, self:_GetCurrentAreaShowData())
end

-- endregion

-- region 私有方法

function XUiArenaChapterDetail:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnFight, self.OnBtnFightClick, true)
    if self.BtnBack and self.BtnMainUi then
        self:BindExitBtns(self.BtnBack, self.BtnMainUi)
        self.BtnClose.gameObject:SetActiveEx(false) 
        self.BtnCloseTarget.gameObject:SetActiveEx(false) 
    else
        self.BtnClose.gameObject:SetActiveEx(true) 
        self.BtnCloseTarget.gameObject:SetActiveEx(true) 
        self:RegisterClickEvent(self.BtnClose, self.Close, true)
        XUiHelper.RegisterPassClickEvent(self, self.BtnCloseTarget, self.BtnClose)
    end
end

function XUiArenaChapterDetail:_RefreshBuffList()
    local groupEventId = self._AreaData:GetGroupFightEventIdByAreaId(self:_GetCurrentAreaId())
    local groupEvents = self._Control:GetFightEventsByGroupId(groupEventId)

    if not XTool.IsTableEmpty(groupEvents) then
        self.PanelBuff.gameObject:SetActiveEx(true)
        for i, eventId in pairs(groupEvents) do
            local grid = self._BuffGridList[i]

            if not grid then
                local gridObject = XUiHelper.Instantiate(self.GridBuff, self.PanelBuff)

                grid = XUiArenaChapterDetailGridBuff.New(gridObject, self)
                self._BuffGridList[i] = grid
            end

            grid:Open()
            grid:Refresh(eventId)
        end
        for i = #groupEvents + 1, #self._BuffGridList do
            self._BuffGridList[i]:Close()
        end
    else
        self.PanelBuff.gameObject:SetActiveEx(false)
    end
end

function XUiArenaChapterDetail:_RefreshStageDatail()
    local areaId = self:_GetCurrentAreaId()
    local stageBuffNameList = self._Control:GetAreaStageBuffNameListByAreaId(areaId)

    self.TxtTips.text = self._Control:GetAreaStageDescByAreaId(areaId)
    if #stageBuffNameList == 1 then
        self.PanelTitle.gameObject:SetActiveEx(true)
        self.ListTitle.gameObject:SetActiveEx(false)

        self.TxtTitle.text = stageBuffNameList[1]
        self.TxtEnvironment.text = self._Control:GetAreaStageBuffDescByAreaIdAndIndex(areaId, 1) or ""
    else
        self.PanelTitle.gameObject:SetActiveEx(false)
        self.ListTitle.gameObject:SetActiveEx(true)

        for i, name in pairs(stageBuffNameList) do
            local button = self._BtnListTitleList[i]

            if not button then
                local gridObject = XUiHelper.Instantiate(self.GridTitle.gameObject, self.ListTitle.transform)

                button = gridObject.transform:GetComponent(typeof(CS.XUiComponent.XUiButton))
                self._BtnListTitleList[i] = button
            end

            local buffDesc = self._Control:GetAreaStageBuffDescByAreaIdAndIndex(areaId, i) or ""

            button:SetNameByGroup(0, name)
            button:SetNameByGroup(1, buffDesc)
        end

        self.GridTitle.gameObject:SetActiveEx(false)
        self.ListTitle:Init(self._BtnListTitleList, Handler(self, self.OnListTitleClick))
        self.ListTitle:SelectIndex(self._Control:GetLocalSelectBuffIndex(areaId))
    end
end

function XUiArenaChapterDetail:_InitUi()
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiArenaChapterDetail:_GetCurrentAreaId()
    local areaData = self:_GetCurrentAreaShowData()

    return areaData and areaData:GetAreaId() or 0
end

function XUiArenaChapterDetail:_GetCurrentAreaShowData()
    local index = self._CurrentSelectZoneIndex

    return self._AreaData:GetAreaShowDataByIndex(index)
end

-- endregion

return XUiArenaChapterDetail
