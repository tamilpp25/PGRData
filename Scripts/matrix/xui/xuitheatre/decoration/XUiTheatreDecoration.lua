local XUiDecorationGroup = require("XUi/XUiTheatre/Decoration/XUiDecorationGroup")

local MAX_GROUP_COUNT = 3
local TWEE_DURATION

--肉鸽玩法装修改造界面
local XUiTheatreDecoration = XLuaUiManager.Register(XLuaUi, "UiTheatreDecoration")

function XUiTheatreDecoration:OnAwake()
    local viewPortWidth = self.Content.rect.width
    self.MarkX = viewPortWidth * 0.1
    self.InitPos = self.Content.localPosition
    TWEE_DURATION = XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration
    XUiHelper.NewPanelActivityAsset(XDataCenter.TheatreManager.GetAssetItemIds(), self.PanelSpecialTool)
    self:InitGroup()
    self:InitButtonCallBack()
end

function XUiTheatreDecoration:OnEnable()
    self:Refresh()
end

function XUiTheatreDecoration:InitGroup()
    self.DecorationGroup = {}
    self.TheatreGroupIndexToDecorationIds = XTheatreConfigs.GetTheatreGroupIndexToDecorationIds()
    for groupIndex, decorationIdList in ipairs(self.TheatreGroupIndexToDecorationIds) do
        local panelStageContent = self["PanelStageContent" .. groupIndex]
        if panelStageContent then
            panelStageContent.gameObject:SetActiveEx(true)
            table.insert(self.DecorationGroup, XUiDecorationGroup.New(panelStageContent, decorationIdList, handler(self, self.ClickGridCallback)))
        end
    end

    for i = #self.DecorationGroup + 1, MAX_GROUP_COUNT do
        if self["PanelStageContent" .. i] then
            self["PanelStageContent" .. i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiTheatreDecoration:ClickGridCallback(grid)
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelectActive(false)
    end

    grid:SetSelectActive(true)
    self.CurSelectGrid = grid
    self:PlayScrollViewMove(grid)
end

function XUiTheatreDecoration:Refresh()
    for _, v in ipairs(self.DecorationGroup) do
        v:Refresh()
    end
end

function XUiTheatreDecoration:InitButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiTheatreDecoration:OnBtnBackClick()
    self:Close()
end

function XUiTheatreDecoration:PlayScrollViewMove(grid)
    local decorationId = grid:GetDecorationId()
    local skillPointBtn = grid:GetGuildSkillPointBtn()
    local gridTransform = self.Content.transform:InverseTransformPoint(CS.UnityEngine.Vector3(skillPointBtn.transform.position.x, skillPointBtn.transform.position.y, 0))

    local gridX = gridTransform.x
    local markX = self.MarkX
    local diffX = gridX + markX
    local targetPosX = self.InitPos.x - diffX

    local gridY = gridTransform.y
    local targetPosY = self.InitPos.y - gridY

    local contentPos = self.Content.localPosition
    local tarPos = contentPos
    tarPos.x = targetPosX
    tarPos.y = targetPosY

    XLuaUiManager.SetMask(true)
    XLuaUiManager.Open("UiTheatreDetail", decorationId, handler(self, self.CancalSelectLastGrid))
    XUiHelper.DoMove(self.Content, tarPos, TWEE_DURATION, XUiHelper.EaseType.Sin, function()
        XLuaUiManager.SetMask(false)
    end)
end

function XUiTheatreDecoration:CancalSelectLastGrid()
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelectActive(false)
    end

    XLuaUiManager.SetMask(true)
    XUiHelper.DoMove(self.Content, self.InitPos, TWEE_DURATION, XUiHelper.EaseType.Sin, function()
        XLuaUiManager.SetMask(false)
    end)
end

function XUiTheatreDecoration:OnGetEvents()
    return { XEventId.EVENT_THEATRE_DECORATION_UPGRADE }
end

function XUiTheatreDecoration:OnNotify(evt, ...)
    if evt == XEventId.EVENT_THEATRE_DECORATION_UPGRADE then
        self:Refresh()
    end
end