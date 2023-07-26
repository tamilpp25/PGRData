local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")
--三期双子节点
---@class XUiGridStageSecret
local XUiGridStageSecret = XClass(XUiGridStage, "XUiGridStageSecret")
local CSTextManagerGetText = CS.XTextManager.GetText


function XUiGridStageSecret:Ctor(ui, base)
    --XUiGridStageSecret.Super:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Damage = 0
    self.IsSelect = false
    self:InitUI()
    self:SetButtonCallBack()
    self:DoSelect(false)
end

function XUiGridStageSecret:InitUI()
    XTool.InitUiObject(self)
end

function XUiGridStageSecret:SetButtonCallBack()
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
end

function XUiGridStageSecret:UpdateGrid(nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver)
    XUiGridStageSecret.Super.UpdateGrid(self,nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver)
    self.PanelBlood.gameObject:SetActiveEx(false)
    --self.PanelRevive.gameObject:SetActiveEx(false)
end

function XUiGridStageSecret:OnBtnStageClick(selectedNodeId)
    if self.IsPathEdit then
        return
    else
        XLuaUiManager.Open("UiGuildWarConcealStageDetail", self.StageNode, false)
    end
end

return XUiGridStageSecret