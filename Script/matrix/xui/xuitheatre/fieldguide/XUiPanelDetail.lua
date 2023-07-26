local XUiPanelDetailNature = require("XUi/XUiTheatre/FieldGuide/XUiPanelDetailNature")
local XUiPanelDetailProp = require("XUi/XUiTheatre/FieldGuide/XUiPanelDetailProp")
local XUiTheatreSkillGrid = require("XUi/XUiTheatre/XUiTheatreSkillGrid")
local XUiDetailPropGrid = require("XUi/XUiTheatre/FieldGuide/XUiDetailPropGrid")

--道具或增益详情的布局
local XUiPanelDetail = XClass(nil, "XUiPanelDetail")

function XUiPanelDetail:Ctor(ui, isShowUseBtn, selectTokenCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.UpGrids = {}
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()

    self.DetailNaturePanel = XUiPanelDetailNature.New(self.PanelNature)
    self.DetailPropPanel = XUiPanelDetailProp.New(self.PanelProp, isShowUseBtn, selectTokenCb)
    self.TheatreSkillGrid = XUiTheatreSkillGrid.New(self.GridBuff)
    self.DetailPropGrid = XUiDetailPropGrid.New(self.GridIcon)
end

--skill：XAdventureSkill
function XUiPanelDetail:ShowSkillDetail(skill)
    self.TxtName.text = skill:GetName()
    local lv = skill:GetCurrentLevel()
    self.Txtlv.text = XTool.IsNumberValid(lv) and XUiHelper.GetText("TheatreDecorationTipsLevel", lv) or ""
    self.TheatreSkillGrid:SetData(skill, true)
    self.DetailNaturePanel:Show(skill)
    self.GridBuff.gameObject:SetActiveEx(true)
    self.GridIcon.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(true)
end

--token：XTheatreToken
function XUiPanelDetail:ShowItemDetail(token)
    self.TxtName.text = token:GetName()

    local id = token:GetId()
    local lv = XTheatreConfigs.GetTheatreItemLv(id)
    self.Txtlv.text = XTool.IsNumberValid(lv) and XUiHelper.GetText("TheatreDecorationTipsLevel", lv) or ""
    
    self.DetailPropGrid:SetData(token)
    self.DetailPropPanel:Show(token)
    self.DetailPropPanel.GameObject:SetActiveEx(true)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridIcon.gameObject:SetActiveEx(true)
    self.GameObject:SetActiveEx(true)
end

function XUiPanelDetail:HideAllDetail()
    self.GameObject:SetActiveEx(false)
    self.DetailNaturePanel.GameObject:SetActiveEx(false)
    self.DetailPropPanel.GameObject:SetActiveEx(false)
end

return XUiPanelDetail