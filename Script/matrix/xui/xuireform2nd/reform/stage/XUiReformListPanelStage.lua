local XUiReformListPanelStageGrid = require("XUi/XUiReform2nd/Reform/Stage/XUiReformListPanelStageGrid")

---@class XUiReformListPanelStage
local XUiReformListPanelStage = XClass(nil, "XUiReformListPanelStage")

function XUiReformListPanelStage:Ctor(ui, viewModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    ---@type XViewModelReform2ndList
    self._ViewModel = viewModel
    XTool.InitUiObject(self)

    ---@type XUiReformListPanelStageGrid[]
    self._GridCharacter = {}
    self.GridCommon.gameObject:SetActiveEx(false)
    if self.PanelFubenReformEffect then
        self.PanelFubenReformEffect.gameObject:SetActive(true)
    end
    self.Text2 = self.Text2 or XUiHelper.TryGetComponent(self.Transform, "PanelDetail/PanelDetail2/Text2", "Text")
    self.TextTitle2 = self.TextTitle2 or XUiHelper.TryGetComponent(self.Transform, "PanelDetail/PanelDesc/Txt/TxtTitle", "Text")
    self.Text3 = self.Text3 or XUiHelper.TryGetComponent(self.Transform, "PanelDetail/PanelDetail2/Text3", "Text")
end

function XUiReformListPanelStage:Update()
    self._ViewModel:UpdateStage()
    local data = self._ViewModel.DataStage
    local iconList = data.IconList
    for i = 1, #iconList do
        local icon = iconList[i]
        local grid = self._GridCharacter[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.GridCommon.transform.parent)
            grid = XUiReformListPanelStageGrid.New(ui)
            self._GridCharacter[i] = grid
        end
        grid:Update(icon)
        grid.GameObject:SetActiveEx(true)
    end
    for i = #iconList + 1, #self._GridCharacter do
        local grid = self._GridCharacter[i]
        grid.GameObject:SetActiveEx(false)
    end

    --self.PanelDetail
    --self.PanelDesc
    --self.TxtTitle
    --self.PanelDropList
    --self.PanelDrop
    --self.TxtFirstDrop
    --self.PanelDropContent
    --self.GridCommon
    self.TxtTitle.text = data.Number
    if self.Text2 then
        self.Text2.text = data.Desc
    end
    if self.TextTitle2 then
        self.TextTitle2.text = data.Name
    end
    if self.Text3 then
        self.Text3.text = data.DescTarget
    end
end

function XUiReformListPanelStage:Show()
    self.GameObject:SetActiveEx(true)
    self:Update()
end

function XUiReformListPanelStage:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiReformListPanelStage
