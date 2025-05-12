-- 机体专精的天赋界面，点击多人或单人按钮后进到这
local XUiRpgTowerRoleListAdaptPanel = XClass(nil, "XUiRpgTowerRoleListAdaptPanel")

function XUiRpgTowerRoleListAdaptPanel:Ctor(uiGameObject, page, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.Page = page
    self.RootUi = rootUi
    self.BtnExchange.CallBack = function() self:OnClickChangeMember() end
    self.GridSingular.gameObject:SetActiveEx(false)
    self.GridDual.gameObject:SetActiveEx(false)
    local iconScript = require("XUi/XUiRpgTower/Common/XUiRpgTowerItemIcon")
    self.TalentItemIcon = iconScript.New(self.RImgTalentPointsIcon)
    self.BtnSummary.CallBack = function() self:OnClickTalentTotal() end
    self.BtnReset.CallBack = function() self:OnClickReset() end
    self.BtnUse.CallBack = function() self:OnClickUse() end
    self:CreateLayers()
end

function XUiRpgTowerRoleListAdaptPanel:CreateLayers()
    self.Layers = {}
    local LayerScript = require("XUi/XUiRpgTower/CharacterPage/AdaptPage/XUiRpgTowerRoleListTalentLevel")
    local cfgs = XRpgTowerConfig.GetAllTalentLayerCfgs()
    local isOdd = true
    for layerId, cfg in pairs(cfgs) do
        local grid = isOdd and self.GridSingular or self.GridDual
        local layerObj = CS.UnityEngine.GameObject.Instantiate(grid)
        layerObj.transform:SetParent(self.PanelCirculation.transform, false)
        table.insert(self.Layers, LayerScript.New(layerObj, self.RootUi, cfg))
        layerObj.gameObject:SetActiveEx(true)
        layerObj.gameObject.name = "Setting" .. layerId
        isOdd = not isOdd
    end
end
--================
--刷新数据
--================
function XUiRpgTowerRoleListAdaptPanel:RefreshData(rChara)
    self.RCharacter = rChara
    self.TxtTalentPieces.text = rChara:GetTalentPoints(self.Type)
    self.TalentItemIcon:InitIcon(rChara:GetTalentItem(self.Type))
    self.TxtTitle.text = XRpgTowerConfig.GetTalentTypeConfigByCharacterId(rChara:GetId(), self.Type).Name
    if self.ImgTalent then
        -- self.ImgTalent:SetSprite(XRpgTowerConfig.GetTalentTypeIconById(self.Type))
        self.ImgTalent:SetSprite(XRpgTowerConfig.GetTalentTypeConfigByCharacterId(rChara:GetId(), self.Type).Icon)
    end
    for _, layer in pairs(self.Layers) do
        layer:RefreshData(rChara, self.Type)
    end
    if self.RCharacter:GetCharaTalentType() == self.Type then
        self.BtnUse:SetButtonState(CS.UiButtonState.Disable)
        self.BtnUse:SetName(XUiHelper.GetText("RpgTowerTalentAlreadySet"))
    else
        self.BtnUse:SetButtonState(CS.UiButtonState.Normal)
        self.BtnUse:SetName(XUiHelper.GetText("RpgTowerTalentSet"))
    end
end
--================
--点击更换队员按钮
--================
function XUiRpgTowerRoleListAdaptPanel:OnClickChangeMember()
    self.RootUi:OpenChildPage(XDataCenter.RpgTowerManager.PARENT_PAGE.CHANGEMEMBER)
end

function XUiRpgTowerRoleListAdaptPanel:ShowPanel(...)
    local params = {...}
    self.Type = params and params[1] or self.Type or XDataCenter.RpgTowerManager.TALENT_TYPE.SINGLE
    self.GameObject:SetActiveEx(true)
end

function XUiRpgTowerRoleListAdaptPanel:HidePanel()
    self.GameObject:SetActiveEx(false)
end
--================
--点击天赋汇总
--================
function XUiRpgTowerRoleListAdaptPanel:OnClickTalentTotal()
    if not self.RCharacter then return end
    XLuaUiManager.Open("UiRpgTowerCollect", self.RCharacter, self.Type)
end
--================
--点击天赋重置
--================
function XUiRpgTowerRoleListAdaptPanel:OnClickReset()
    if self.RCharacter:GetCharaTalentType() ~= self.Type then
        XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerTalentCompatibilityTips"))
        return
    end
    XDataCenter.RpgTowerManager.CharacterReset(self.RCharacter:GetCharacterId(), self.Type)
end
--================
--点击使用天赋
--================
function XUiRpgTowerRoleListAdaptPanel:OnClickUse()
    if self.RCharacter:GetCharaTalentType() == self.Type then
        return
    end
    XDataCenter.RpgTowerManager.SetTalentType(self.RCharacter, self.Type, function()
            self:RefreshData(self.RCharacter)
        end)
end
return XUiRpgTowerRoleListAdaptPanel