--
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
    self.BtnTalentTotal.CallBack = function() self:OnClickTalentTotal() end
    self.BtnReset.CallBack = function() self:OnClickReset() end
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
    self.TxtTalentPieces.text = rChara:GetTalentPoints()
    self.TalentItemIcon:InitIcon(rChara:GetTalentItem())
    for _, layer in pairs(self.Layers) do
        layer:RefreshData(rChara)
    end
end
--================
--点击更换队员按钮
--================
function XUiRpgTowerRoleListAdaptPanel:OnClickChangeMember()
    self.RootUi:OpenChildPage(XDataCenter.RpgTowerManager.PARENT_PAGE.CHANGEMEMBER)
end

function XUiRpgTowerRoleListAdaptPanel:ShowPanel()
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
    XLuaUiManager.Open("UiRpgTowerCollect", self.RCharacter)
end
--================
--点击天赋重置
--================
function XUiRpgTowerRoleListAdaptPanel:OnClickReset()
    XDataCenter.RpgTowerManager.CharacterReset(self.RCharacter:GetCharacterId())
end
return XUiRpgTowerRoleListAdaptPanel